[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$WorkingDirectory = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [string]$NodeScript = "run-mscc-auto.cjs"
)

$ErrorActionPreference = "Stop"

Set-Location -LiteralPath $WorkingDirectory

function Assert-CommandExists {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

Assert-CommandExists -Name "node"
Assert-CommandExists -Name "npm"

if (-not (Test-Path -LiteralPath "package.json")) {
    throw "package.json not found in $WorkingDirectory"
}

if (-not (Test-Path -LiteralPath $NodeScript)) {
    throw "Node script not found: $NodeScript"
}

Write-Host "Installing npm dependencies for MSCC..." -ForegroundColor Cyan
npm install

if ($LASTEXITCODE -ne 0) {
    throw "npm install failed with exit code $LASTEXITCODE"
}

Write-Host "Installing Playwright browsers (if needed)..." -ForegroundColor Cyan
npx playwright install chromium

Write-Host "Running Node automation for MSCC ($NodeScript)..." -ForegroundColor Cyan
node $NodeScript

if ($LASTEXITCODE -ne 0) {
    throw "Node script failed with exit code $LASTEXITCODE"
}

Write-Host "Done." -ForegroundColor Green