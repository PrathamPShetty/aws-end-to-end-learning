# AWS CodeCommit

## What is it?
AWS CodeCommit is a fully managed, private Git repository hosting service that stores your source code, binaries, and other assets in the AWS cloud. It integrates natively with IAM for access control, meaning you manage who can read or write to a repository using the same policies you already use for every other AWS service. CodeCommit supports the standard Git workflow — clone, commit, branch, merge, pull request — so any existing Git tooling works without modification. It is the right choice when you want source control that stays entirely within your AWS environment and does not require operating your own Git server.

## Key Concepts
- **Repository** — the top-level container for all of a project's files and their full revision history (equivalent to a Git repo).
- **Branch** — a named pointer to a line of development inside a repository (e.g. `main`, `feature/login`).
- **Commit** — a snapshot of the repository at a point in time, identified by a unique commit ID (SHA-1 hash).
- **Pull Request** — a request to merge changes from one branch into another, optionally requiring approval before the merge is permitted.
- **Approval Rule Template** — a reusable policy that automatically requires a minimum number of reviewers before a pull request can be merged.
- **Trigger / Notification** — an event-driven hook that fires an SNS topic or Lambda function when specific repository events occur (e.g. push to `main`).

## When to Use
- **Private source control inside AWS** — store code without exposing it to a third-party SaaS provider; useful for regulated industries that must keep source inside a specific AWS region or account.
- **CI/CD integration** — use CodeCommit as the source stage in a CodePipeline so that every push to `main` automatically kicks off a build and deployment.
- **Cross-account code sharing** — grant another AWS account read access to a repository using IAM cross-account roles, avoiding credential sharing.
- **Audit and compliance** — every commit is durably stored, and IAM CloudTrail logs every API call (clone, push, pull request) for compliance reporting.

## CLI Quick Reference (awslocal)

### Create
```bash
awslocal codecommit create-repository \
  --repository-name my-app \
  --repository-description "Main application repo"
```

### List
```bash
awslocal codecommit list-repositories \
  --query 'repositories[].{Name:repositoryName,ID:repositoryId}' \
  --output table
```

### Get / Describe
```bash
awslocal codecommit get-repository --repository-name my-app
```

### Commit a file
```bash
awslocal codecommit put-file \
  --repository-name my-app \
  --branch-name main \
  --file-path src/app.py \
  --file-content "print('hello')" \
  --commit-message "Add app.py"
```

### List branches
```bash
awslocal codecommit list-branches --repository-name my-app --output table
```

### Get a specific commit
```bash
awslocal codecommit get-commit \
  --repository-name my-app \
  --commit-id <commitId>
```

### Update description
```bash
awslocal codecommit update-repository-description \
  --repository-name my-app \
  --repository-description "Updated description"
```

### Delete
```bash
awslocal codecommit delete-repository --repository-name my-app
```

## Example Walkthrough

1. **Create a repository** — provision a new private Git repository.
   ```bash
   awslocal codecommit create-repository \
     --repository-name hello-app \
     --repository-description "Demo app repo" \
     --query 'repositoryMetadata.{Name:repositoryName,ARN:Arn}' \
     --output table
   ```

2. **Add a README on the main branch** — create the first commit by uploading a file directly via the API.
   ```bash
   awslocal codecommit put-file \
     --repository-name hello-app \
     --branch-name main \
     --file-path README.md \
     --file-content "# Hello App" \
     --commit-message "Initial commit"
   ```

3. **Add application source code** — commit a second file; the parent commit is resolved automatically.
   ```bash
   COMMIT_ID=$(awslocal codecommit put-file \
     --repository-name hello-app \
     --branch-name main \
     --file-path src/main.py \
     --file-content "print('Hello, CodeCommit!')" \
     --commit-message "Add main.py" \
     --query 'commitId' --output text)
   echo "New commit: $COMMIT_ID"
   ```

4. **Inspect the commit** — retrieve the commit message and metadata to confirm the file was stored.
   ```bash
   awslocal codecommit get-commit \
     --repository-name hello-app \
     --commit-id "$COMMIT_ID" \
     --query 'commit.{Message:message,Author:author.name,Date:author.date}' \
     --output table
   ```

5. **List all branches** — verify that `main` exists and check for any other branches.
   ```bash
   awslocal codecommit list-branches \
     --repository-name hello-app \
     --output table
   ```

6. **Get the file content** — retrieve a specific file by its path to confirm it was stored correctly.
   ```bash
   awslocal codecommit get-file \
     --repository-name hello-app \
     --commit-specifier main \
     --file-path src/main.py \
     --query 'fileContent' \
     --output text | base64 --decode
   ```

7. **Delete the repository** — clean up when the demo is finished.
   ```bash
   awslocal codecommit delete-repository --repository-name hello-app
   ```

## Important Flags & Options

| Flag / Option | Description | Example |
|---|---|---|
| `--repository-name` | Name of the repository to operate on | `hello-app` |
| `--branch-name` | Target branch for a put-file or branch operation | `main`, `feature/login` |
| `--file-path` | Path inside the repo where the file will be stored | `src/main.py` |
| `--file-content` | Raw text content of the file to commit | `"print('hello')"` |
| `--commit-message` | Human-readable message attached to the commit | `"Add initial files"` |
| `--commit-id` | SHA-1 identifier of a specific commit | `a1b2c3d4...` |
| `--commit-specifier` | Branch name, tag, or commit ID used as a reference point | `main`, `HEAD` |
| `--repository-description` | Free-text description stored with the repository | `"Payment service repo"` |
| `--order` | Sort order when listing repositories (`ascending` / `descending`) | `ascending` |
| `--sort-by` | Sort field for list-repositories (`repositoryName` / `lastModifiedDate`) | `lastModifiedDate` |

## How to Run the Demo

```bash
cd services/09-devtools/codecommit
bash demo.sh
```
