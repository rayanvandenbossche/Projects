param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PrinterIp,

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$PrinterPassword = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("http", "https")]
    [string]$Protocol = "http",

    [Parameter(Mandatory = $false)]
    [switch]$Headed
)

$ErrorActionPreference = "Stop"

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$NodeScript = Join-Path $ScriptRoot "enable-hp-ews.js"

if (-not (Test-Path $NodeScript)) {
    Write-Error "Node script not found: $NodeScript"
    exit 1
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js was not found."
    exit 1
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm was not found."
    exit 1
}

Push-Location $ScriptRoot

try {
    if (-not (Test-Path "package.json")) {
        npm init -y | Out-Null
    }

    if (-not (Test-Path "node_modules\playwright")) {
        npm install playwright | Out-Null
    }

    npx playwright install chromium | Out-Null

    if ($Headed) {
        $HeadedValue = "true"
    }
    else {
        $HeadedValue = "false"
    }

    & node "$NodeScript" "$PrinterIp" "$PrinterPassword" "$Protocol" "$HeadedValue"

    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
