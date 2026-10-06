param(
  [string]$ServiceName = "SoudalPrintPortal2",
  [string]$NssmPath = "nssm.exe"
)

function Test-RunningAsAdministrator {
  $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
  return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-RunningAsAdministrator)) {
  $arguments = @(
    '-NoProfile'
    '-ExecutionPolicy'
    'Bypass'
    '-File'
    $PSCommandPath
    '-ServiceName'
    $ServiceName
    '-NssmPath'
    $NssmPath
  )

  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments | Out-Null
  exit 0
}

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$LogFile = Join-Path $ProjectRoot "update.log"
$WasRunning = $false
$ServiceExists = $false

function Resolve-Executable {
  param([string]$Name)

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }

  $nodeJsDir = Join-Path ${env:ProgramFiles} "nodejs"
  $candidate = Join-Path $nodeJsDir $Name
  if (Test-Path -LiteralPath $candidate) {
    return $candidate
  }

  throw "Could not resolve executable '$Name'."
}

$GitPath = Resolve-Executable -Name "git"
$NpmPath = Resolve-Executable -Name "npm.cmd"
$NpxPath = Resolve-Executable -Name "npx.cmd"

function Write-Log {
  param([string]$Message)

  $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$timestamp] $Message"
  Write-Host $line
  Add-Content -Path $LogFile -Value $line -Encoding UTF8
}

function Invoke-ExternalCommand {
  param(
    [string]$FilePath,
    [string[]]$Arguments,
    [string]$StepName
  )

  & $FilePath @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "$StepName failed with exit code $LASTEXITCODE."
  }
}

function Invoke-NssmCommand {
  param(
    [string[]]$Arguments,
    [string]$StepName
  )

  Invoke-ExternalCommand -FilePath $NssmPath -Arguments $Arguments -StepName $StepName
}

function Start-PortalService {
  param([string]$Name)

  $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
  if ($service -and $service.Status.ToString() -eq "Running") {
    Write-Log "Service '$Name' is already running, restarting it instead of starting again."
    Invoke-NssmCommand -Arguments @("restart", $Name) -StepName "nssm restart"
    Wait-ForServiceStatus -Name $Name -DesiredStatus "Running" -TimeoutSeconds 60
    return
  }

  try {
    Invoke-NssmCommand -Arguments @("start", $Name) -StepName "nssm start"
  } catch {
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($service -and $service.Status.ToString() -eq "Running") {
      Write-Log "nssm start reported that '$Name' was already running, restarting it."
      Invoke-NssmCommand -Arguments @("restart", $Name) -StepName "nssm restart after already-running"
    } else {
      Write-Log "nssm start failed, trying Start-Service for '$Name': $($_.Exception.Message)"
      Start-Service -Name $Name -ErrorAction Stop
    }
  }

  Wait-ForServiceStatus -Name $Name -DesiredStatus "Running" -TimeoutSeconds 60
}

function Wait-ForServiceStatus {
  param(
    [string]$Name,
    [string]$DesiredStatus,
    [int]$TimeoutSeconds = 30
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

  while ((Get-Date) -lt $deadline) {
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($service -and $service.Status.ToString() -eq $DesiredStatus) {
      return
    }

    Start-Sleep -Milliseconds 500
  }

  throw "Service '$Name' did not reach status '$DesiredStatus' within $TimeoutSeconds seconds."
}

try {
  Set-Location $ProjectRoot
  Write-Log "Starting portal update in $ProjectRoot"

  $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
  if ($service) {
    $ServiceExists = $true
    $WasRunning = $service.Status.ToString() -eq "Running"

    if ($WasRunning) {
      Write-Log "Stopping service '$ServiceName'..."
      Invoke-NssmCommand -Arguments @("stop", $ServiceName) -StepName "nssm stop"
      Wait-ForServiceStatus -Name $ServiceName -DesiredStatus "Stopped"
    } else {
      Write-Log "Service '$ServiceName' is already stopped."
    }
  } else {
    Write-Log "Service '$ServiceName' was not found. Continuing without service control."
  }

  Write-Log "Pulling latest changes from git..."
  Invoke-ExternalCommand -FilePath $GitPath -Arguments @("pull", "--ff-only") -StepName "git pull"

  Write-Log "Installing dependencies with npm i..."
  Invoke-ExternalCommand -FilePath $NpmPath -Arguments @("i", "--no-audit", "--no-fund") -StepName "npm i"

  Write-Log "Running database generations..."
  Invoke-ExternalCommand -FilePath $NpxPath -Arguments @("prisma", "generate") -StepName "prisma generate"

  Write-Log "Running database push..."
  Invoke-ExternalCommand -FilePath $NpxPath -Arguments @("prisma", "db", "push") -StepName "prisma db push"

  Write-Log "Building production assets..."
  Invoke-ExternalCommand -FilePath $NpmPath -Arguments @("run", "build") -StepName "npm run build"

  if ($ServiceExists) {
    Write-Log "Starting service '$ServiceName'..."
    Start-PortalService -Name $ServiceName
  }

  Write-Log "Update completed successfully."
}
catch {
  Write-Log "Update failed: $($_.Exception.Message)"

  if ($ServiceExists) {
    try {
      Write-Log "Attempting to restart service '$ServiceName' after failure..."
      Start-PortalService -Name $ServiceName
      Write-Log "Service '$ServiceName' restarted after failure."
    } catch {
      Write-Log "Failed to restart service '$ServiceName' after failure: $($_.Exception.Message)"
    }
  }

  exit 1
}