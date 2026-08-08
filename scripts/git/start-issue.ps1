param(
    [Parameter(Mandatory = $true)]
    [int]$Issue,

    [Parameter(Mandatory = $false)]
    [string]$Name
)

$ErrorActionPreference = "Stop"

function Stop-OnError {
    param([string]$Message)

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}

function Convert-ToSlug {
    param([string]$Text)

    $slug = $Text.ToLowerInvariant()
    $slug = $slug -replace '[^a-z0-9]+', '-'
    $slug = $slug.Trim('-')

    return $slug
}

Write-Host "======================================="
Write-Host " BobHub Start Issue"
Write-Host "======================================="
Write-Host ""

# Ensure we are inside the repository root
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
    throw "Commit, stash or discard the current changes before starting another issue."
}

# Read issue information
$issueDataRaw = gh issue view $Issue --json number,title,state
Stop-OnError "Unable to read issue #$Issue."

$issueData = $issueDataRaw | ConvertFrom-Json

if ($issueData.state -ne "OPEN") {
    throw "Issue #$Issue is not open."
}

# Discover default branch
$repoDataRaw = gh repo view --json defaultBranchRef
Stop-OnError "Unable to determine repository default branch."

$repoData = $repoDataRaw | ConvertFrom-Json
$defaultBranch = $repoData.defaultBranchRef.name

# Create branch name
if ($Name) {
    $slug = Convert-ToSlug $Name
}
else {
    $slug = Convert-ToSlug $issueData.title
}

$branchName = "feat/$Issue-$slug"

Write-Host "Issue   : #$Issue"
Write-Host "Title   : $($issueData.title)"
Write-Host "Base    : $defaultBranch"
Write-Host "Branch  : $branchName"
Write-Host ""

Write-Host "[1/4] Fetching remote..."
git fetch origin
Stop-OnError "Unable to fetch origin."

Write-Host ""
Write-Host "[2/4] Switching to $defaultBranch..."
git switch $defaultBranch
Stop-OnError "Unable to switch to $defaultBranch."

Write-Host ""
Write-Host "[3/4] Updating $defaultBranch..."
git pull --ff-only origin $defaultBranch
Stop-OnError "Unable to update $defaultBranch."

# Protect against accidental duplicate branches
$localBranch = git branch --list $branchName

if ($localBranch) {
    throw "Local branch '$branchName' already exists."
}

git ls-remote --exit-code --heads origin $branchName 1>$null 2>$null

if ($LASTEXITCODE -eq 0) {
    throw "Remote branch '$branchName' already exists."
}

Write-Host ""
Write-Host "[4/4] Creating feature branch..."
git switch -c $branchName
Stop-OnError "Unable to create branch '$branchName'."

Write-Host ""
Write-Host "======================================="
Write-Host " Issue ready for development"
Write-Host "======================================="
Write-Host ""
Write-Host "Issue  : #$Issue"
Write-Host "Branch : $branchName"
Write-Host ""
Write-Host "Start working!"