# BobHub Git Workflow

## Objective

This document describes the Git and GitHub workflow used by BobHub for issue-based development.

The goal is to provide a simple and repeatable process for:

* starting work from a GitHub issue
* creating standardized feature branches
* committing and publishing changes
* opening pull requests
* associating commits and pull requests with issues
* merging changes safely
* synchronizing the local `main` branch
* cleaning feature branches after merge

The workflow is supported by PowerShell helper scripts stored in:

```text
scripts/git/
```

Current PowerShell helpers:

```text
scripts/git/start-issue.ps1
scripts/git/git-commit-push.ps1
scripts/git/open-pr.ps1
scripts/git/finish-pr.ps1
```

---

## Workflow Overview

The standard BobHub development workflow is:

```text
GitHub Issue
     ↓
start-issue.ps1
     ↓
Feature Branch
     ↓
Development
     ↓
git-commit-push.ps1
     ↓
Remote Feature Branch
     ↓
open-pr.ps1
     ↓
Pull Request
     ↓
GitHub Actions / CI
     ↓
Self-review
     ↓
Squash and Merge
     ↓
Issue Closed
     ↓
finish-pr.ps1
     ↓
main synchronized
     ↓
Feature branch cleaned
```

This workflow keeps development associated with GitHub issues while reducing repetitive Git commands.

---

## Prerequisites

The Git helpers require:

* Git
* PowerShell
* GitHub CLI
* access to the BobHub repository
* an authenticated GitHub CLI session

Validate Git:

```powershell
git --version
```

Validate PowerShell:

```powershell
$PSVersionTable.PSVersion
```

Validate GitHub CLI:

```powershell
gh --version
```

---

## GitHub CLI Authentication

Authenticate GitHub CLI:

```powershell
gh auth login
```

Follow the interactive authentication process.

Validate authentication:

```powershell
gh auth status
```

The BobHub helpers that interact with GitHub validate the `gh` authentication state before continuing.

If authentication is missing, the scripts will stop and request:

```text
gh auth login
```

---

## Repository Location

Run the helpers from inside the BobHub Git repository.

Example:

```powershell
cd C:\path\to\bobhub
```

The scripts automatically discover the repository root using Git.

You can validate the repository with:

```powershell
git status
```

---

## Helper: start-issue.ps1

### Purpose

`start-issue.ps1` prepares the repository for development of a GitHub issue.

It performs the following flow:

```text
Validate Git repository
        ↓
Validate GitHub CLI
        ↓
Validate GitHub authentication
        ↓
Require clean working tree
        ↓
Read GitHub issue
        ↓
Verify issue is open
        ↓
Discover default branch
        ↓
Fetch origin
        ↓
Switch to default branch
        ↓
Update default branch
        ↓
Create standardized feature branch
```

---

## start-issue.ps1 Parameters

### `-Issue`

Required.

The GitHub issue number.

Example:

```powershell
.\scripts\git\start-issue.ps1 -Issue 30
```

### `-Name`

Optional.

Overrides the issue title when generating the feature branch slug.

Example:

```powershell
.\scripts\git\start-issue.ps1 `
  -Issue 30 `
  -Name "Document Git helpers"
```

---

## Branch Naming

Without `-Name`, the script uses the GitHub issue title.

Example issue:

```text
#30 — Document BobHub Git workflow helpers
```

Generated branch:

```text
feat/30-document-bobhub-git-workflow-helpers
```

The standard format is:

```text
feat/<issue-number>-<slug>
```

This makes the relationship between branches and issues immediately visible.

---

## Clean Working Tree Requirement

`start-issue.ps1` requires a clean working tree.

Validate:

```powershell
git status
```

If changes already exist, the helper will stop.

Before starting another issue, choose one of the following:

### Commit the current work

```powershell
git commit
```

### Temporarily stash the current work

```powershell
git stash push -u -m "WIP current work"
```

After creating the new issue branch:

```powershell
git stash pop
```

### Discard unwanted changes

Only when the changes are intentionally no longer needed.

---

## start-issue.ps1 Example

Start issue #30:

```powershell
.\scripts\git\start-issue.ps1 -Issue 30
```

Expected result:

```text
Issue   : #30
Base    : main
Branch  : feat/30-document-bobhub-git-workflow-helpers
```

Validate:

```powershell
git branch --show-current
git status
```

---

## Helper: git-commit-push.ps1

### Purpose

`git-commit-push.ps1` standardizes staging, commit creation and remote publishing.

The helper performs:

```text
Detect current branch
        ↓
Display git status
        ↓
Validate that changes exist
        ↓
git add -A
        ↓
Create commit
        ↓
Associate commit with issue
        ↓
Detect upstream
        ↓
Push branch
```

If the branch has never been published, the helper automatically configures the upstream.

Conceptually:

```text
git push -u origin <branch>
```

For later commits it uses the existing upstream.

---

## git-commit-push.ps1 Parameters

### `-Message`

Required.

Defines the Git commit message.

Example:

```powershell
-Message "Document BobHub Git workflow helpers"
```

### `-Issue`

Required.

Defines the GitHub issue associated with the commit.

Example:

```powershell
-Issue 30
```

The helper accepts either:

```text
30
```

or:

```text
#30
```

---

## git-commit-push.ps1 Example

```powershell
.\scripts\git\git-commit-push.ps1 `
  -Message "Document BobHub Git workflow helpers" `
  -Issue 30
```

The generated commit follows this structure:

```text
Document BobHub Git workflow helpers

Issue: #30
```

The helper then pushes the current branch to GitHub.

---

## `Issue: #N` Convention

BobHub commits created through the helper contain:

```text
Issue: #N
```

Example:

```text
Issue: #30
```

This creates a clear relationship between the Git commit and the GitHub issue.

It is used for traceability.

It does not automatically close the issue.

---

## Helper: open-pr.ps1

### Purpose

`open-pr.ps1` creates a GitHub Pull Request associated with an open issue.

The helper:

```text
Validates GitHub CLI
        ↓
Validates authentication
        ↓
Detects current branch
        ↓
Rejects PR from main
        ↓
Requires clean working tree
        ↓
Reads GitHub issue
        ↓
Validates issue is open
        ↓
Publishes or updates feature branch
        ↓
Checks for an existing PR
        ↓
Creates Pull Request
```

---

## open-pr.ps1 Parameters

### `-Issue`

Required.

GitHub issue number.

Example:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30
```

### `-Title`

Optional.

Overrides the GitHub issue title for the Pull Request.

Example:

```powershell
.\scripts\git\open-pr.ps1 `
  -Issue 30 `
  -Title "Document Git workflow helpers"
```

If omitted, the GitHub issue title is used.

### `-Ready`

Optional switch.

Without `-Ready`, the script creates a Draft Pull Request.

Example:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30
```

Result:

```text
Draft Pull Request
```

To create a Pull Request that is immediately ready for review:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30 -Ready
```

---

## Pull Request Body

The helper automatically creates a PR body containing:

```markdown
## Summary

Implements the work defined in #N.

## Validation

- [ ] BobHub CI passes
- [ ] Files changed reviewed
- [ ] No sensitive data committed

Closes #N
```

This provides a minimum validation checklist for every BobHub Pull Request.

---

## `Closes #N` Convention

Pull Requests use:

```text
Closes #N
```

Example:

```text
Closes #30
```

Unlike:

```text
Issue: #30
```

the `Closes` keyword instructs GitHub to close the associated issue when the Pull Request is merged into the default branch.

BobHub therefore uses:

```text
Commit
  ↓
Issue: #30
```

for traceability, and:

```text
Pull Request
  ↓
Closes #30
```

for issue lifecycle automation.

---

## Pull Request Review

Before merging a Pull Request, validate:

* GitHub Actions / CI passed
* changed files were reviewed
* no credentials or secrets were committed
* documentation matches the implementation
* unrelated changes are absent
* the issue acceptance criteria were satisfied

The PR checklist generated by `open-pr.ps1` should be completed before merge.

---

## Squash and Merge

The preferred BobHub merge strategy is:

```text
Squash and Merge
```

This converts the commits from a feature branch into a single commit on `main`.

Conceptually:

```text
Feature branch

commit A
commit B
commit C

        ↓ Squash and Merge

main

single consolidated commit
```

This keeps the `main` branch history concise while allowing incremental work inside feature branches.

---

## Helper: finish-pr.ps1

### Purpose

`finish-pr.ps1` completes the local Git workflow after a Pull Request has been merged.

The helper performs:

```text
Validate clean working tree
        ↓
Discover default branch
        ↓
Detect feature branch
        ↓
Confirm a merged PR exists
        ↓
git fetch --prune
        ↓
Switch to main
        ↓
git pull --ff-only
        ↓
Delete local feature branch
        ↓
Optionally delete remote feature branch
```

This leaves the local repository synchronized with GitHub after merge.

---

## finish-pr.ps1 Parameters

### `-Branch`

Optional.

Defines the feature branch that should be cleaned.

If the script is executed while still on a feature branch, the current branch is detected automatically.

Example:

```powershell
.\scripts\git\finish-pr.ps1 `
  -Branch feat/30-document-bobhub-git-workflow-helpers
```

### `-DeleteRemote`

Optional switch.

Deletes the remote feature branch after confirming that its Pull Request was merged.

Recommended after a successful merge:

```powershell
.\scripts\git\finish-pr.ps1 -DeleteRemote
```

---

## Why finish-pr Uses Forced Local Branch Deletion

BobHub uses Squash Merge.

A squash merge creates a new consolidated commit on `main` instead of preserving the original feature branch commit ancestry.

Because of this, Git may not consider the feature branch traditionally merged.

After GitHub confirms that the Pull Request was successfully merged, `finish-pr.ps1` safely removes the local feature branch using:

```text
git branch -D
```

The script does not perform this cleanup until it confirms that a merged Pull Request exists for the branch.

---

## Complete Pull Request Workflow

Example using issue #30.

### 1. Start the issue

```powershell
.\scripts\git\start-issue.ps1 -Issue 30
```

Expected branch:

```text
feat/30-document-bobhub-git-workflow-helpers
```

### 2. Develop

Edit the required files.

Validate:

```powershell
git status
git diff
```

### 3. Commit and push

```powershell
.\scripts\git\git-commit-push.ps1 `
  -Message "Document BobHub Git workflow helpers" `
  -Issue 30
```

### 4. Open the Pull Request

Draft:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30
```

Or ready for review:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30 -Ready
```

### 5. Validate the Pull Request

Confirm:

```text
CI passes
Files reviewed
No sensitive information
Acceptance criteria satisfied
```

### 6. Squash and Merge

Use:

```text
Squash and Merge
```

on GitHub.

The PR contains:

```text
Closes #30
```

so GitHub closes the issue after merge.

### 7. Finish the workflow

From the local repository:

```powershell
.\scripts\git\finish-pr.ps1 -DeleteRemote
```

Expected final state:

```text
main
  ↓
up to date with origin/main

feature branch
  ↓
removed locally

remote feature branch
  ↓
removed
```

---

## Direct-to-Main Workflow

Not every change necessarily requires a Pull Request.

Very small and low-risk changes may intentionally be committed directly to `main`, depending on the context and repository policy.

Examples may include:

* very small documentation corrections
* typo fixes
* simple metadata updates
* low-risk maintenance changes

The direct-to-main workflow should be used intentionally rather than as the default for feature development.

Typical flow:

```text
main
 ↓
small change
 ↓
review git diff
 ↓
git-commit-push.ps1
 ↓
origin/main
```

Example:

```powershell
git switch main
git pull --ff-only origin main
```

Make the change.

Then:

```powershell
git status
git diff
```

Commit:

```powershell
.\scripts\git\git-commit-push.ps1 `
  -Message "Fix documentation typo" `
  -Issue 30
```

When running on `main`, the helper reports that the issue will be processed by the BobHub CI flow.

---

## When to Use a Pull Request

Prefer the feature branch + PR workflow for:

* new features
* infrastructure changes
* Terraform changes
* Docker changes
* CI/CD changes
* scripts
* automation
* configuration changes
* security-sensitive changes
* changes involving multiple files
* changes that benefit from CI validation
* changes where a clear review checkpoint is useful

Standard workflow:

```text
Issue
↓
Feature branch
↓
Commit
↓
Push
↓
Pull Request
↓
CI
↓
Review
↓
Merge
```

---

## When Direct-to-Main May Be Acceptable

Direct-to-main can be considered for very small changes where creating a PR would add little review value.

Examples:

```text
typo correction
minor documentation adjustment
small metadata correction
```

Before doing so, confirm:

```text
Change is small
Change is understood
No sensitive data is involved
No infrastructure behavior changes
main is up to date
```

When in doubt, use a feature branch and Pull Request.

---

## Working With Existing Changes

`start-issue.ps1` intentionally refuses to run when the working tree contains changes.

If work was accidentally started on `main`, it can be preserved using Git stash.

Example:

```powershell
git stash push -u -m "WIP issue 30"
```

Start the issue:

```powershell
.\scripts\git\start-issue.ps1 -Issue 30
```

Recover the work:

```powershell
git stash pop
```

Validate:

```powershell
git status
```

This allows work to be moved safely from `main` to the correct feature branch.

---

## Multiple Open Feature Branches

Multiple issue branches may exist simultaneously.

Example:

```text
main
feat/30-document-bobhub-git-workflow-helpers
feat/31-install-and-baseline-proxmox-lab-host
```

Switch between them with:

```powershell
git switch feat/30-document-bobhub-git-workflow-helpers
```

or:

```powershell
git switch feat/31-install-and-baseline-proxmox-lab-host
```

Before switching branches, always check:

```powershell
git status
```

Avoid switching branches with unrelated uncommitted changes unless you intentionally understand how those changes will move between branches.

---

## Post-Merge Cleanup

After a PR is merged, use:

```powershell
.\scripts\git\finish-pr.ps1 -DeleteRemote
```

This is preferred over manually running multiple Git commands because the helper:

* validates the repository
* validates GitHub authentication
* requires a clean working tree
* confirms that a merged PR exists
* fetches and prunes remote references
* synchronizes `main`
* deletes the local feature branch
* optionally deletes the remote branch

After cleanup, validate:

```powershell
git status
git branch
git branch -r
```

Expected current branch:

```text
main
```

---

## Common Errors

### Working Tree Is Not Clean

Example:

```text
Working tree is not clean
```

Check:

```powershell
git status
```

Then:

* commit the changes
* stash the changes
* or discard them intentionally

---

### GitHub CLI Is Not Authenticated

Run:

```powershell
gh auth login
```

Validate:

```powershell
gh auth status
```

---

### Issue Is Closed

`start-issue.ps1` and `open-pr.ps1` require the issue to be open.

Check:

```powershell
gh issue view <ISSUE_NUMBER>
```

---

### Feature Branch Already Exists

`start-issue.ps1` prevents duplicate local or remote branches.

Check local branches:

```powershell
git branch
```

Check remote branches:

```powershell
git branch -r
```

If the branch belongs to previous completed work, perform the appropriate cleanup before recreating it.

---

### No Changes to Commit

`git-commit-push.ps1` stops when no working tree changes exist.

Check:

```powershell
git status
```

---

### Cannot Open PR From Main

`open-pr.ps1` does not allow a Pull Request directly from the repository default branch.

A PR workflow requires a feature branch.

Start one with:

```powershell
.\scripts\git\start-issue.ps1 -Issue <ISSUE_NUMBER>
```

---

### Uncommitted Changes Before Opening PR

`open-pr.ps1` requires a clean working tree.

Run:

```powershell
git status
```

Commit and push the changes first:

```powershell
.\scripts\git\git-commit-push.ps1 `
  -Message "<MESSAGE>" `
  -Issue <ISSUE_NUMBER>
```

Then open the PR.

---

### Pull Request Already Exists

`open-pr.ps1` checks for an existing open PR from the current branch.

If one already exists, the helper displays its URL instead of creating a duplicate.

---

### finish-pr Cannot Find a Merged PR

`finish-pr.ps1` verifies that the feature branch belongs to a merged Pull Request.

If the PR has not been merged yet, the script will stop.

Merge the PR first.

Then run:

```powershell
.\scripts\git\finish-pr.ps1 -DeleteRemote
```

---

## Security Notes

Before every commit or Pull Request, review:

```powershell
git status
git diff
```

Do not commit:

* API Tokens
* passwords
* private keys
* `.env` files containing secrets
* sensitive `terraform.tfvars`
* Terraform state files
* credentials
* internal infrastructure details that should remain private

The generated PR checklist explicitly includes:

```text
No sensitive data committed
```

This validation must be performed before merge.

---

## Operational Checklist

Before starting an issue:

* [ ] Current work is committed or safely stashed
* [ ] Working tree is clean
* [ ] GitHub CLI is authenticated
* [ ] GitHub issue exists
* [ ] GitHub issue is open

During development:

* [ ] Correct feature branch is active
* [ ] Changes belong to the current issue
* [ ] No sensitive data is being added
* [ ] Relevant validation has been performed

Before commit:

* [ ] `git status` reviewed
* [ ] `git diff` reviewed
* [ ] Commit message describes the change
* [ ] Correct issue number is used

Before Pull Request:

* [ ] Working tree is clean
* [ ] Feature branch is published
* [ ] CI-relevant validations were performed
* [ ] No unrelated files are included

Before merge:

* [ ] BobHub CI passes
* [ ] Files changed were reviewed
* [ ] No sensitive data is committed
* [ ] Acceptance criteria are satisfied
* [ ] PR contains `Closes #N`

After merge:

* [ ] Issue is closed
* [ ] `finish-pr.ps1` executed
* [ ] Local `main` is synchronized
* [ ] Local feature branch is removed
* [ ] Remote feature branch is removed when appropriate

---

## Quick Reference

Start an issue:

```powershell
.\scripts\git\start-issue.ps1 -Issue 30
```

Commit and push:

```powershell
.\scripts\git\git-commit-push.ps1 `
  -Message "Document BobHub Git workflow helpers" `
  -Issue 30
```

Open Draft PR:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30
```

Open Ready PR:

```powershell
.\scripts\git\open-pr.ps1 -Issue 30 -Ready
```

Finish merged PR:

```powershell
.\scripts\git\finish-pr.ps1 -DeleteRemote
```

---

## Related Scripts

```text
scripts/git/start-issue.ps1
scripts/git/git-commit-push.ps1
scripts/git/open-pr.ps1
scripts/git/finish-pr.ps1
```

Additional Git-related BobHub scripts may exist for release or Linux workflows, but this document focuses on the PowerShell issue and Pull Request workflow.

---

## Recommended BobHub Workflow

For normal development:

```text
Issue
↓
start-issue.ps1
↓
Feature Branch
↓
Development
↓
git-commit-push.ps1
↓
open-pr.ps1
↓
GitHub Actions
↓
Review
↓
Squash and Merge
↓
finish-pr.ps1
```

For intentionally small and low-risk changes:

```text
main
↓
Update main
↓
Small change
↓
Review
↓
git-commit-push.ps1
```

Feature work should prefer the Pull Request workflow.

---

## Version Goal

This document establishes the Git workflow used by BobHub for issue-based development.

The helper scripts reduce repetitive Git operations while preserving:

* issue traceability
* branch consistency
* Pull Request review
* CI validation
* clean Git history
* predictable post-merge cleanup

A contributor should be able to follow this document from an open GitHub issue to a completed and cleaned Pull Request without requiring previous BobHub conversation context.
