param(
    [Parameter(Mandatory)]
    [ValidatePattern('^v\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$repo = 'miiitch/d2-gen'

Write-Host "Triggering publish workflow for $Version on $repo..."
gh workflow run 'Skill CI' --repo $repo -f version=$Version

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to trigger workflow"
    exit 1
}

# Wait a moment for the run to register
Start-Sleep -Seconds 3

# Find the run
$run = gh run list --repo $repo --workflow 'skill-ci.yml' --limit 1 --json databaseId,status,headBranch | ConvertFrom-Json
$runId = $run[0].databaseId

Write-Host "Watching run $runId..."
gh run watch $runId --repo $repo --exit-status

if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed. Check: https://github.com/$repo/actions/runs/$runId"
    exit 1
}

Write-Host "Published $Version successfully."
