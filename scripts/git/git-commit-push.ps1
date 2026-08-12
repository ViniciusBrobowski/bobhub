param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter(Mandatory = $false)]
    [string]$Issue
)

$ErrorActionPreference = "Stop"

function Stop-OnError {
    param([string]$Message)

    if ($LASTEXITCODE -ne 0) {
        throw $Message
    }
}

Write-Host "======================================="
Write-Host " BobHub Git Helper"
Write-Host "======================================="
Write-Host ""

$repoRoot = git rev-parse --show-toplevel
Stop-OnError "Not inside a Git repository."

Set-Location $repoRoot

$branch = git branch --show-current
Stop-OnError "Unable to determine current branch."

Write-Host "Branch: $branch"
Write-Host ""

git status

$changes = git status --porcelain

if (-not $changes) {
    throw "There are no changes to commit."
}

Write-Host ""
Write-Host "[1/3] Adding changes..."

git add -A
Stop-OnError "Unable to stage changes."

Write-Host ""
Write-Host "[2/3] Creating commit..."

if ($Issue) {

    $Issue = $Issue.TrimStart("#")

    git commit -m "$Message`n`nIssue: #$Issue"
}
else {

    git commit -m "$Message"
}

Stop-OnError "Unable to create commit."

Write-Host ""
Write-Host "[3/3] Pushing to GitHub..."

$upstream = git for-each-ref `
    --format="%(upstream:short)" `
    "refs/heads/$branch"

Stop-OnError "Unable to determine branch upstream."

if ([string]::IsNullOrWhiteSpace($upstream)) {

    Write-Host "No upstream configured."
    Write-Host "Publishing branch $branch..."

    git push -u origin $branch
}
else {

    git push
}

Stop-OnError "Unable to push changes."

Write-Host ""
Write-Host "======================================="
Write-Host " Commit and push completed"
Write-Host "======================================="

if ($Issue) {

    if ($branch -eq "main") {
        Write-Host "Issue #$Issue will be processed by BobHub CI."
    }
    else {
        Write-Host "Issue #$Issue is associated with this feature branch."
        Write-Host "Open a PR to complete the workflow."
    }
}