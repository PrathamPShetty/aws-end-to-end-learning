# Amazon Cognito Identity Pools (Federated Identities)

## What is it?
Amazon Cognito Identity Pools (also called Federated Identities) bridge the gap between authenticated or anonymous app users and AWS services. While Cognito User Pools handle who you are (authentication), Identity Pools handle what you can do in AWS (authorization) — they exchange an identity token (from a User Pool, Google, Facebook, or any OIDC provider) for short-lived AWS credentials via STS. Your mobile or web application calls `GetCredentialsForIdentity` and receives a temporary access key, secret, and session token scoped to an IAM role. The main benefit is that your app can directly call AWS APIs (upload to S3, write to DynamoDB) without routing every request through a backend server.

## Key Concepts
- **Identity Pool** — The core resource; maps federated identity providers and authenticated/unauthenticated states to IAM roles.
- **Federated Identity** — An end-user identity that comes from an external provider (Cognito User Pool, Google, Facebook, SAML, developer-authenticated).
- **Identity ID** — A unique, stable identifier assigned by Cognito to each end-user across sessions (format: `us-east-1:uuid`).
- **Authenticated Role** — The IAM role assumed when a user provides a valid identity token from a configured provider.
- **Unauthenticated (Guest) Role** — The IAM role assumed when no login token is provided; typically grants minimal read-only permissions for guest users.
- **Token Exchange** — The process where Cognito validates the identity provider token and calls STS `AssumeRoleWithWebIdentity` on your behalf, returning temporary AWS credentials.

## When to Use
- Allowing a mobile app's logged-in users to upload profile photos directly to S3 with credentials scoped only to their own S3 prefix.
- Granting anonymous (guest) users read access to public DynamoDB tables without requiring them to create an account.
- Federating multiple identity providers (Google login, Facebook login, and your own User Pool) into a single set of AWS permissions.
- Issuing per-user temporary credentials so each user's actions in AWS are individually attributable in CloudTrail.

## CLI Quick Reference (awslocal)

| Operation | Command |
|-----------|---------|
| Create identity pool | `awslocal cognito-identity create-identity-pool --identity-pool-name my-app-identities --allow-unauthenticated-identities` |
| Describe identity pool | `awslocal cognito-identity describe-identity-pool --identity-pool-id <pool-id>` |
| List identity pools | `awslocal cognito-identity list-identity-pools --max-results 20` |
| Update identity pool | `awslocal cognito-identity update-identity-pool --identity-pool-id <pool-id> --identity-pool-name my-app-identities --no-allow-unauthenticated-identities` |
| Get an identity ID | `awslocal cognito-identity get-id --account-id 000000000000 --identity-pool-id <pool-id>` |
| Get credentials | `awslocal cognito-identity get-credentials-for-identity --identity-id <identity-id>` |
| Set IAM roles | `awslocal cognito-identity set-identity-pool-roles --identity-pool-id <pool-id> --roles authenticated=<auth-role-arn>,unauthenticated=<unauth-role-arn>` |
| Delete identity pool | `awslocal cognito-identity delete-identity-pool --identity-pool-id <pool-id>` |

## Example Walkthrough

1. **Create an identity pool that allows both guest and authenticated users**
   ```bash
   IDENTITY_POOL_ID=$(awslocal cognito-identity create-identity-pool \
     --identity-pool-name my-app-identities \
     --allow-unauthenticated-identities \
     --query 'IdentityPoolId' \
     --output text)
   echo "Identity Pool ID: $IDENTITY_POOL_ID"
   ```
   Creates the pool with guest (unauthenticated) access enabled — useful for apps with a "browse without login" mode.

2. **Describe the pool to confirm its configuration**
   ```bash
   awslocal cognito-identity describe-identity-pool \
     --identity-pool-id "$IDENTITY_POOL_ID" \
     --query '{Name:IdentityPoolName,AllowUnauth:AllowUnauthenticatedIdentities}'
   ```
   Verifies the pool name and whether guest access is on or off.

3. **Get an identity ID for a guest (unauthenticated) user**
   ```bash
   IDENTITY_ID=$(awslocal cognito-identity get-id \
     --account-id 000000000000 \
     --identity-pool-id "$IDENTITY_POOL_ID" \
     --query 'IdentityId' \
     --output text)
   echo "Identity ID: $IDENTITY_ID"
   ```
   Returns a stable `us-east-1:uuid` identity ID for this device/session; on real AWS this persists across app launches.

4. **Exchange the identity ID for temporary AWS credentials**
   ```bash
   awslocal cognito-identity get-credentials-for-identity \
     --identity-id "$IDENTITY_ID" \
     --query 'Credentials.{AccessKeyId:AccessKeyId,Expiration:Expiration}'
   ```
   Returns a short-lived `AccessKeyId`, `SecretKey`, and `SessionToken` scoped to the unauthenticated IAM role.

5. **Attach IAM roles to control what authenticated and guest users can do**
   ```bash
   awslocal cognito-identity set-identity-pool-roles \
     --identity-pool-id "$IDENTITY_POOL_ID" \
     --roles authenticated=arn:aws:iam::000000000000:role/CognitoAuthRole,unauthenticated=arn:aws:iam::000000000000:role/CognitoUnauthRole
   ```
   Maps the two IAM roles to the pool; Cognito will assume the correct one depending on whether the user is logged in.

6. **Disable guest access by updating the pool**
   ```bash
   awslocal cognito-identity update-identity-pool \
     --identity-pool-id "$IDENTITY_POOL_ID" \
     --identity-pool-name my-app-identities \
     --no-allow-unauthenticated-identities \
     --query '{Name:IdentityPoolName,AllowUnauth:AllowUnauthenticatedIdentities}'
   ```
   Forces all users to be authenticated before they receive AWS credentials.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--identity-pool-name` | Human-readable name for the pool (spaces are not allowed) |
| `--identity-pool-id` | ID of the existing identity pool (format: `us-east-1:uuid`) |
| `--allow-unauthenticated-identities` | Enable guest/anonymous credential issuance |
| `--no-allow-unauthenticated-identities` | Require authentication before issuing credentials |
| `--account-id` | Your 12-digit AWS account ID (required in `get-id`) |
| `--identity-id` | The stable identity ID returned from `get-id` |
| `--logins` | Map of provider name to token for authenticated calls (e.g., `cognito-idp.us-east-1.amazonaws.com/us-east-1_xxx=<jwt>`) |
| `--roles` | `authenticated=<arn>,unauthenticated=<arn>` for `set-identity-pool-roles` |
| `--max-results` | Maximum items returned by `list-identity-pools` |

## How to Run the Demo
```bash
cd services/06-security/cognito-identity
bash demo.sh
```
