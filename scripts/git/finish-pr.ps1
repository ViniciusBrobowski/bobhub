param(
    [Parameter(Mandatory = $false)]
    [string]$Branch,

    [switch]$DeleteRemote
)

$ErrorActionPreference = "Stop"

function Stop-OnError {
    param([string]$Message)

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}

Write-Host "======================================="
Write-Host " BobHub Finish PR"
Write-Host "======================================="
Write-Host ""

# Ensure we are inside a Git repository
$repoRoot = git rev-parse --show-toplevel
Stop-OnError "Not inside a Git repository."

Set-Location $repoRoot

# Require GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is not installed or not available in PATH."
}

gh auth status 1>$null 2>$null
Stop-OnError "GitHub CLI is not authenticated. Run: gh auth login"

# Working tree must be clean
$changes = git status --porcelain

if ($changes) {
    Write-Host "Working tree is not clean:"
    Write-Host ""
    git status --short
    Write-Host ""

    throw "Commit, stash or discard changes before finishing a PR."
}

# Discover repository default branch
$repoDataRaw = gh repo view --json defaultBranchRef
Stop-OnError "Unable to determine repository default branch."

$repoData = $repoDataRaw | ConvertFrom-Json
$defaultBranch = $repoData.defaultBranchRef.name

# Discover current branch
$currentBranch = git branch --show-current
Stop-OnError "Unable to determine current branch."

# If no branch was provided, use the current feature branch
if (-not $Branch -and $currentBranch -ne $defaultBranch) {
    $Branch = $currentBranch
}

# Never attempt to clean the default branch
if ($Branch -eq $defaultBranch) {
    $Branch = $null
}

Write-Host "Default branch : $defaultBranch"

if ($Branch) {
    Write-Host "Cleanup branch : $Branch"
}
else {
    Write-Host "Cleanup branch : none"
}

Write-Host ""

# Confirm that the feature branch belongs to a merged PR
if ($Branch) {

    $mergedPrRaw = gh pr list `
        --head $Branch `
        --state merged `
        --limit 1 `
        --json number,url,mergedAt

    Stop-OnError "Unable to check merged pull request."

    $mergedPr = $mergedPrRaw | ConvertFrom-Json

    if (-not $mergedPr -or $mergedPr.Count -eq 0) {
        throw "No merged pull request found for branch '$Branch'."
    }

    Write-Host "Merged PR      : #$($mergedPr[0].number)"
    Write-Host ""
}

Write-Host "[1/4] Fetching and pruning remote references..."

git fetch --prune origin
Stop-OnError "Unable to fetch origin."

Write-Host ""
Write-Host "[2/4] Switching to $defaultBranch..."

git switch $defaultBranch
Stop-OnError "Unable to switch to $defaultBranch."

Write-Host ""
Write-Host "[3/4] Updating $defaultBranch..."

git pull --ff-only origin $defaultBranch
Stop-OnError "Unable to update $defaultBranch."

Write-Host ""
Write-Host "[4/4] Cleaning feature branch..."

if ($Branch) {

    $localBranch = git branch --list $Branch

    if ($localBranch) {

        # Squash merges do not preserve feature branch commit ancestry.
        # GitHub already confirmed that the PR was merged.
        git branch -D $Branch
        Stop-OnError "Unable to delete local branch '$Branch'."

        Write-Host "Deleted local branch: $Branch"
    }
    else {
        Write-Host "Local branch does not exist: $Branch"
    }

    $remoteBranch = git ls-remote --heads origin $Branch
    Stop-OnError "Unable to check remote branch '$Branch'."

    if ($remoteBranch) {

        if ($DeleteRemote) {

            git push origin --delete $Branch
            Stop-OnError "Unable to delete remote branch '$Branch'."

            Write-Host "Deleted remote branch: $Branch"
        }
        else {
            Write-Host "Remote branch still exists: origin/$Branch"
            Write-Host "Use -DeleteRemote if you want to remove it."
        }
    }
    else {
        Write-Host "Remote branch already removed."
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host " PR workflow finished"
Write-Host "======================================="
Write-Host ""
Write-Host "$defaultBranch is up to date."