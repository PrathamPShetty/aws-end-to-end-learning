# Amazon Cognito User Pools

## What is it?
Amazon Cognito User Pools is a fully managed user directory service that handles all aspects of user authentication for web and mobile applications. It provides sign-up, sign-in, email/phone verification, multi-factor authentication (MFA), and password policies out of the box — without you needing to build or maintain an auth backend. Applications authenticate users through the Cognito hosted UI or directly via the API, receiving JWT tokens (ID token, access token, refresh token) on success. The main benefit is enterprise-grade authentication in minutes, with built-in support for social login (Google, Facebook) and SAML/OIDC federation.

## Key Concepts
- **User Pool** — The user directory itself; holds user accounts, password policies, MFA settings, and attribute schemas.
- **App Client** — A credential-less (or client-secret) entity representing your application; it defines which auth flows and OAuth scopes the app can use.
- **User** — An account inside a User Pool with a username, password, and custom/standard attributes (email, phone, name, etc.).
- **Auth Flow** — The mechanism used to authenticate: `USER_PASSWORD_AUTH`, `USER_SRP_AUTH` (secure remote password), `REFRESH_TOKEN_AUTH`.
- **JWT Tokens** — On successful authentication, Cognito returns an ID token (user claims), access token (API authorization), and refresh token (long-lived session renewal).
- **User Group** — A named group inside a User Pool that users can belong to; groups carry an IAM role used to map users to AWS permissions.

## When to Use
- Building a customer-facing web or mobile app that needs user registration, login, and password reset without writing auth logic from scratch.
- Enforcing password complexity rules and MFA for internal tools accessed by employees.
- Federating corporate users via SAML (e.g., Okta, Azure AD) so they can sign in with their existing company credentials.
- Controlling feature access by placing users into groups (`admin`, `editor`, `viewer`) and reading group claims from the JWT.

## CLI Quick Reference (awslocal)

### Pool Management
| Operation | Command |
|-----------|---------|
| Create user pool | `awslocal cognito-idp create-user-pool --pool-name my-app-users` |
| List user pools | `awslocal cognito-idp list-user-pools --max-results 20` |
| Describe user pool | `awslocal cognito-idp describe-user-pool --user-pool-id <pool-id>` |
| Delete user pool | `awslocal cognito-idp delete-user-pool --user-pool-id <pool-id>` |

### App Clients
| Operation | Command |
|-----------|---------|
| Create app client | `awslocal cognito-idp create-user-pool-client --user-pool-id <pool-id> --client-name my-app --no-generate-secret` |
| List app clients | `awslocal cognito-idp list-user-pool-clients --user-pool-id <pool-id>` |
| Describe app client | `awslocal cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id>` |

### User Management
| Operation | Command |
|-----------|---------|
| Create user (admin) | `awslocal cognito-idp admin-create-user --user-pool-id <pool-id> --username alice@example.com --temporary-password Temp@123` |
| Set permanent password | `awslocal cognito-idp admin-set-user-password --user-pool-id <pool-id> --username alice@example.com --password Perm@456 --permanent` |
| Get user | `awslocal cognito-idp admin-get-user --user-pool-id <pool-id> --username alice@example.com` |
| List users | `awslocal cognito-idp list-users --user-pool-id <pool-id>` |
| Delete user | `awslocal cognito-idp admin-delete-user --user-pool-id <pool-id> --username alice@example.com` |

## Example Walkthrough

1. **Create a User Pool with a password policy**
   ```bash
   POOL_ID=$(awslocal cognito-idp create-user-pool \
     --pool-name my-app-users \
     --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
     --query 'UserPool.Id' \
     --output text)
   echo "Pool ID: $POOL_ID"
   ```
   Creates the user directory with a minimum-8-character mixed-case password requirement.

2. **Create an app client so your application can authenticate users**
   ```bash
   CLIENT_ID=$(awslocal cognito-idp create-user-pool-client \
     --user-pool-id "$POOL_ID" \
     --client-name web-app \
     --no-generate-secret \
     --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
     --query 'UserPoolClient.ClientId' \
     --output text)
   echo "Client ID: $CLIENT_ID"
   ```
   Registers a public client (no secret) that supports username/password login and token refresh.

3. **Create a user via the admin API (no email verification needed)**
   ```bash
   awslocal cognito-idp admin-create-user \
     --user-pool-id "$POOL_ID" \
     --username alice@example.com \
     --temporary-password Temp@123 \
     --message-action SUPPRESS
   ```
   Creates the user with a temporary password; `SUPPRESS` skips the invitation email in local dev.

4. **Set a permanent password to skip the forced-change-password challenge**
   ```bash
   awslocal cognito-idp admin-set-user-password \
     --user-pool-id "$POOL_ID" \
     --username alice@example.com \
     --password MyPerm@456 \
     --permanent
   ```
   Moves the user status from `FORCE_CHANGE_PASSWORD` to `CONFIRMED` so they can log in immediately.

5. **Add the user to an admin group**
   ```bash
   awslocal cognito-idp create-group \
     --user-pool-id "$POOL_ID" \
     --group-name admins \
     --description "Administrator group"

   awslocal cognito-idp admin-add-user-to-group \
     --user-pool-id "$POOL_ID" \
     --username alice@example.com \
     --group-name admins
   ```
   Creates a group and assigns alice to it; her JWT access token will include the `cognito:groups` claim.

6. **List all users in the pool**
   ```bash
   awslocal cognito-idp list-users \
     --user-pool-id "$POOL_ID" \
     --query 'Users[*].{Username:Username,Status:UserStatus,Enabled:Enabled}'
   ```
   Returns a summary of every user and their current status.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--pool-name` | Name for the new user pool |
| `--user-pool-id` | ID of an existing pool (format: `us-east-1_xxxxxxx`) |
| `--client-name` | Name of the app client to create |
| `--no-generate-secret` | Create a public app client with no client secret (for SPAs/mobile apps) |
| `--explicit-auth-flows` | Auth flows to enable: `ALLOW_USER_PASSWORD_AUTH`, `ALLOW_USER_SRP_AUTH`, `ALLOW_REFRESH_TOKEN_AUTH` |
| `--username` | User's username (email, phone, or custom username) |
| `--temporary-password` | Initial temporary password that must be changed on first login |
| `--permanent` | With `admin-set-user-password`; marks the new password as permanent |
| `--message-action` | `SUPPRESS` to skip sending the invite email |
| `--policies` | JSON object setting password complexity rules on pool creation |

## How to Run the Demo
```bash
cd services/06-security/cognito-idp
bash demo.sh
```
