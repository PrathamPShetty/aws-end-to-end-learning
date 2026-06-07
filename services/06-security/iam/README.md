# AWS IAM (Identity and Access Management)

## What is it?
AWS IAM (Identity and Access Management) is the service that controls who can do what inside your AWS account. It lets you create users, groups, and roles, then attach policies that grant or deny specific permissions to specific AWS resources. IAM is the foundation of AWS security — every API call is authenticated and authorized through it. Because IAM is free and global, it should be the first service you master before touching anything else in AWS.

## Key Concepts
- **User** — A permanent identity representing a person or application, with long-lived credentials (access key or password).
- **Group** — A collection of users that share the same set of policies; permissions are managed at the group level.
- **Role** — An identity without permanent credentials, assumed temporarily by AWS services (Lambda, EC2), users, or external accounts.
- **Policy** — A JSON document that lists allowed or denied actions on resources; can be managed (AWS-owned or customer-owned) or inline.
- **Trust Policy** — A special policy on a role that defines *who* is allowed to assume it (e.g., which service or account).
- **ARN (Amazon Resource Name)** — A unique identifier for any AWS resource, used inside policy `Resource` fields (e.g., `arn:aws:s3:::my-bucket`).

## When to Use
- Granting a Lambda function permission to read from DynamoDB by attaching a role with the right policy.
- Creating a CI/CD pipeline user with only the permissions needed to deploy (least-privilege access).
- Allowing developers in a `dev` group to access only dev-environment resources, not production.
- Federating access so users from an external identity provider (Okta, Azure AD) can assume an IAM role.

## CLI Quick Reference (awslocal)

### Users
| Operation | Command |
|-----------|---------|
| Create user | `awslocal iam create-user --user-name alice` |
| List users | `awslocal iam list-users` |
| Get user | `awslocal iam get-user --user-name alice` |
| Delete user | `awslocal iam delete-user --user-name alice` |
| Attach inline policy | `awslocal iam put-user-policy --user-name alice --policy-name MyPolicy --policy-document file://policy.json` |
| List user policies | `awslocal iam list-user-policies --user-name alice` |

### Roles
| Operation | Command |
|-----------|---------|
| Create role | `awslocal iam create-role --role-name MyRole --assume-role-policy-document file://trust.json` |
| List roles | `awslocal iam list-roles` |
| Get role | `awslocal iam get-role --role-name MyRole` |
| Attach managed policy | `awslocal iam attach-role-policy --role-name MyRole --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess` |
| List attached policies | `awslocal iam list-attached-role-policies --role-name MyRole` |
| Delete role | `awslocal iam delete-role --role-name MyRole` |

### Managed Policies
| Operation | Command |
|-----------|---------|
| Create policy | `awslocal iam create-policy --policy-name MyPolicy --policy-document file://policy.json` |
| List policies | `awslocal iam list-policies --scope Local` |
| Get policy | `awslocal iam get-policy --policy-arn arn:aws:iam::000000000000:policy/MyPolicy` |
| Delete policy | `awslocal iam delete-policy --policy-arn arn:aws:iam::000000000000:policy/MyPolicy` |

## Example Walkthrough

1. **Create a user named `alice`**
   ```bash
   awslocal iam create-user --user-name alice
   ```
   Creates a new IAM user with no permissions yet.

2. **Create a custom managed policy that allows S3 read access**
   ```bash
   awslocal iam create-policy \
     --policy-name S3ReadPolicy \
     --policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Action": ["s3:GetObject", "s3:ListBucket"],
         "Resource": "*"
       }]
     }'
   ```
   Defines a reusable policy document and saves it in IAM.

3. **Attach the policy to `alice`**
   ```bash
   awslocal iam attach-user-policy \
     --user-name alice \
     --policy-arn arn:aws:iam::000000000000:policy/S3ReadPolicy
   ```
   Grants alice the ability to list and read S3 objects.

4. **Create a role that Lambda can assume**
   ```bash
   awslocal iam create-role \
     --role-name LambdaExecRole \
     --assume-role-policy-document '{
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {"Service": "lambda.amazonaws.com"},
         "Action": "sts:AssumeRole"
       }]
     }'
   ```
   Creates a role with a trust policy allowing the Lambda service to assume it.

5. **Attach a managed policy to the Lambda role**
   ```bash
   awslocal iam attach-role-policy \
     --role-name LambdaExecRole \
     --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
   ```
   Grants any Lambda function that assumes `LambdaExecRole` full DynamoDB access.

6. **Verify the role's attached policies**
   ```bash
   awslocal iam list-attached-role-policies --role-name LambdaExecRole
   ```
   Lists all managed policies currently attached to the role.

## Important Flags & Options

| Flag / Parameter | Description |
|-----------------|-------------|
| `--user-name` | The name of the IAM user to create or modify |
| `--role-name` | The name of the IAM role |
| `--policy-name` | Name for an inline or managed policy |
| `--policy-arn` | Full ARN of a managed policy to attach or detach |
| `--policy-document` | JSON string or `file://path.json` with the policy body |
| `--assume-role-policy-document` | Trust policy JSON defining who can assume the role |
| `--scope Local` | In `list-policies`, filters to only customer-managed policies |
| `--max-items` | Limits the number of results returned in list commands |
| `--path` | Organizational path prefix for users/roles (default `/`) |

## How to Run the Demo
```bash
cd services/06-security/iam
bash demo.sh
```
