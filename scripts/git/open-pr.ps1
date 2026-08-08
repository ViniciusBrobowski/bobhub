param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $false)]
    [string]$Title,

    [switch]$Ready
)

$ErrorActionPreference = "Stop"

function Stop-OnError {
    param([string]$Message)

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}

Write-Host "======================================="
Write-Host " BobHub Open PR"
Write-Host "======================================="
Write-Host ""

$repoRoot = git rev-parse --show-toplevel
Stop-OnError "Not inside a Git repository."

Set-Location $repoRoot

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is not installed or not available in PATH."
}

gh auth status 1>$null 2>$null
Stop-OnError "GitHub CLI is not authenticated. Run: gh auth login"

$branch = git branch --show-current
Stop-OnError "Unable to determine current branch."

$repoDataRaw = gh repo view --json defaultBranchRef
Stop-OnError "Unable to determine default branch."

$repoData = $repoDataRaw | ConvertFrom-Json
$defaultBranch = $repoData.defaultBranchRef.name

if ($branch -eq $defaultBranch) {
    throw "Pull requests cannot be opened directly from '$defaultBranch'."
}

# Do not open a PR with uncommitted files
$changes = git status --porcelain

if ($changes) {
    Write-Host "Uncommitted changes found:"
    Write-Host ""
    git status --short
    Write-Host ""
    throw "Commit and push your changes before opening the PR."
}

# Get issue information
$issueDataRaw = gh issue view $Issue --json number,title,state
Stop-OnError "Unable to read issue #$Issue."

$issueData = $issueDataRaw | ConvertFrom-Json

if ($issueData.state -ne "OPEN") {
    throw "Issue #$Issue is not open."
}

if (-not $Title) {
    $Title = $issueData.title
}

# Ensure branch exists remotely
$upstream = git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null

if ($LASTEXITCODE -ne 0 -or -not $upstream) {

    Write-Host "Publishing branch before creating PR..."

    git push -u origin $branch
}
else {

    Write-Host "Updating remote branch..."

    git push
}

Stop-OnError "Unable to push branch."

# Avoid duplicate PRs
$existingPr = gh pr view $branch --json url --jq '.url' 2>$null

if ($LASTEXITCODE -eq 0 -and $existingPr) {
    Write-Host ""
    Write-Host "A pull request already exists:"
    Write-Host $existingPr
    exit 0
}

$body = @"
## Summary

Implements the work defined in #$Issue.

## Validation

- [ ] BobHub CI passes
- [ ] Files changed reviewed
- [ ] No sensitive data committed

Closes #$Issue
"@

Write-Host ""
Write-Host "Creating pull request..."
Write-Host ""
Write-Host "Base   : $defaultBranch"
Write-Host "Head   : $branch"
Write-Host "Issue  : #$Issue"
Write-Host "Title  : $Title"
Write-Host ""

if ($Ready) {

    gh pr create `
        --base $defaultBranch `
        --head $branch `
        --title $Title `
        --body $body
}
else {

    gh pr create `
        --draft `
        --base $defaultBranch `
        --head $branch `
        --title $Title `
        --body $body
}

Stop-OnError "Unable to create pull request."

Write-Host ""
Write-Host "======================================="
Write-Host " Pull request created"
Write-Host "======================================="