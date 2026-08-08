param(
    [Parameter(Mandatory=$true)]
    [string]$Message,

    [Parameter(Mandatory=$false)]
    [string]$Issue
)

$ErrorActionPreference = "Stop"

Write-Host "======================================="
Write-Host " BobHub Git Helper"
Write-Host "======================================="

git status

Write-Host ""
Write-Host "[1/3] Adding changes..."
git add -A

Write-Host ""
Write-Host "[2/3] Creating commit..."

if ($Issue) {

    $Issue = $Issue.TrimStart("#")

    git commit -m "$Message`n`nIssue: #$Issue"

}
else {

    git commit -m "$Message"

}

Write-Host ""
Write-Host "[3/3] Pushing to GitHub..."

git push

Write-Host ""
Write-Host "Push completed."

if ($Issue) {
    Write-Host "Issue #$Issue will be processed by GitHub Actions."
}