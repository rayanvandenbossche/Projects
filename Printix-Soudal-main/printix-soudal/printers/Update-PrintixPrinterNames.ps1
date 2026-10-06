# ============================================================
# Update Printix printer names from print server share names
#
# Input CSV:
#   Printix Printers.csv
#
# The CSV must be in the same folder as this script.
#
# Print servers checked:
#   \\laserprinters
#   \\printers
#
# Match:
#   Printix CSV address column
#   against print server PrinterHostAddress
#
# Output:
#   Updated CSV without double quotes
# ============================================================

# -------------------------------
# Configuration
# -------------------------------

$PrintServers = @(
    "laserprinters",
    "printers"
)

$CsvFileName = "Printix Printers.csv"

# Prefer this print server if the same IP exists on both servers
$PreferredServer = "laserprinters"

# If true, overwrite original after backup.
# If false, only creates an updated copy.
$OverwriteOriginal = $false

# -------------------------------
# Paths
# -------------------------------

$ScriptFolder = if ($PSScriptRoot) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$CsvPath = Join-Path $ScriptFolder $CsvFileName

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupPath = Join-Path $ScriptFolder "Printix Printers.backup-$Timestamp.csv"
$UpdatedPath = Join-Path $ScriptFolder "Printix Printers.updated-$Timestamp.csv"
$LogPath = Join-Path $ScriptFolder "Printix Printers.rename-log-$Timestamp.csv"

# -------------------------------
# Helper functions
# -------------------------------

function Test-IsBlank {
    param (
        [AllowNull()]
        [string]$Value
    )

    return [string]::IsNullOrWhiteSpace($Value)
}

function Normalize-IP {
    param (
        [AllowNull()]
        [string]$IPAddress
    )

    if ([string]::IsNullOrWhiteSpace($IPAddress)) {
        return ""
    }

    return $IPAddress.Trim()
}

function Get-PrinterShareName {
    param (
        [Parameter(Mandatory = $true)]
        $Printer
    )

    # Prefer ShareName if it exists and is filled in.
    if (
        $Printer.PSObject.Properties.Name -contains "ShareName" -and
        -not [string]::IsNullOrWhiteSpace([string]$Printer.ShareName)
    ) {
        return [string]$Printer.ShareName
    }

    # Fallback to queue name.
    return [string]$Printer.Name
}

function Parse-PrintixCsvLine {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    # Expected logical columns:
    # name;vendor;model;address;network;mac;serial;pdl;color;duplex
    #
    # Note:
    # pdl can itself contain semicolons, so we parse:
    # first 7 fields fixed, last 2 fields fixed, everything between = pdl.

    $Parts = $Line -split ';'

    if ($Parts.Count -lt 10) {
        throw "Invalid Printix CSV row. Expected at least 10 fields, got $($Parts.Count). Row: $Line"
    }

    $Name    = $Parts[0]
    $Vendor  = $Parts[1]
    $Model   = $Parts[2]
    $Address = $Parts[3]
    $Network = $Parts[4]
    $Mac     = $Parts[5]
    $Serial  = $Parts[6]

    $Color   = $Parts[$Parts.Count - 2]
    $Duplex  = $Parts[$Parts.Count - 1]

    $PdlParts = @()

    if ($Parts.Count -gt 9) {
        $PdlParts = $Parts[7..($Parts.Count - 3)]
    }

    $Pdl = $PdlParts -join ';'

    return [PSCustomObject]@{
        name    = $Name
        vendor  = $Vendor
        model   = $Model
        address = $Address
        network = $Network
        mac     = $Mac
        serial  = $Serial
        pdl     = $Pdl
        color   = $Color
        duplex  = $Duplex
    }
}

function Convert-PrintixRowToLine {
    param (
        [Parameter(Mandatory = $true)]
        $Row
    )

    # No quotes are added here.
    return @(
        [string]$Row.name
        [string]$Row.vendor
        [string]$Row.model
        [string]$Row.address
        [string]$Row.network
        [string]$Row.mac
        [string]$Row.serial
        [string]$Row.pdl
        [string]$Row.color
        [string]$Row.duplex
    ) -join ';'
}

function Convert-LogRowToLine {
    param (
        [Parameter(Mandatory = $true)]
        $Row
    )

    # Keep log simple and quote-free.
    # Replace semicolons in message fields so the log stays readable.
    return @(
        ([string]$Row.Address)
        ([string]$Row.OldName)
        ([string]$Row.NewName)
        ([string]$Row.MatchedServer)
        ([string]$Row.MatchedShare)
        ([string]$Row.Status)
        (([string]$Row.Message) -replace ';', ',')
    ) -join ';'
}

# -------------------------------
# Validate CSV exists
# -------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
    exit 1
}

Write-Host "CSV found: $CsvPath" -ForegroundColor Green

# -------------------------------
# Read and parse CSV manually
# -------------------------------

try {
    $RawLines = Get-Content -Path $CsvPath -ErrorAction Stop
}
catch {
    Write-Host "Failed to read CSV." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

if (-not $RawLines -or $RawLines.Count -lt 2) {
    Write-Host "CSV is empty or has no data rows." -ForegroundColor Red
    exit 1
}

$HeaderLine = $RawLines[0].Trim()

$ExpectedHeader = "name;vendor;model;address;network;mac;serial;pdl;color;duplex"

if ($HeaderLine -ne $ExpectedHeader) {
    Write-Host "Warning: CSV header is not exactly the expected header." -ForegroundColor Yellow
    Write-Host "Found:    $HeaderLine" -ForegroundColor Yellow
    Write-Host "Expected: $ExpectedHeader" -ForegroundColor Yellow
    Write-Host "Continuing anyway..." -ForegroundColor Yellow
}

$CsvRows = @()

for ($i = 1; $i -lt $RawLines.Count; $i++) {
    $Line = $RawLines[$i]

    if ([string]::IsNullOrWhiteSpace($Line)) {
        continue
    }

    try {
        $CsvRows += Parse-PrintixCsvLine -Line $Line
    }
    catch {
        Write-Host "Failed to parse line $($i + 1)" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}

if (-not $CsvRows -or $CsvRows.Count -eq 0) {
    Write-Host "No valid CSV rows parsed." -ForegroundColor Red
    exit 1
}

Write-Host "CSV rows parsed: $($CsvRows.Count)" -ForegroundColor Green

# -------------------------------
# Backup original CSV
# -------------------------------

Copy-Item -Path $CsvPath -Destination $BackupPath -Force
Write-Host "Backup created: $BackupPath" -ForegroundColor Green

# -------------------------------
# Read printer data from print servers
# -------------------------------

$AllPrintServerPrinters = @()

foreach ($Server in $PrintServers) {

    Write-Host ""
    Write-Host "Reading printers from \\$Server..." -ForegroundColor Cyan

    try {
        $Printers = Get-Printer -ComputerName $Server -ErrorAction Stop
        $Ports = Get-PrinterPort -ComputerName $Server -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to read from \\$Server" -ForegroundColor Red
        Write-Host $_.Exception.Message
        continue
    }

    Write-Host "Printers found on \\${Server}: $($Printers.Count)" -ForegroundColor Green
    Write-Host "Ports found on \\${Server}: $($Ports.Count)" -ForegroundColor Green

    foreach ($Printer in $Printers) {

        $Port = $Ports | Where-Object {
            $_.Name -eq $Printer.PortName
        } | Select-Object -First 1

        if (-not $Port) {
            continue
        }

        if (-not ($Port.PSObject.Properties.Name -contains "PrinterHostAddress")) {
            continue
        }

        $IPAddress = Normalize-IP -IPAddress $Port.PrinterHostAddress

        if ([string]::IsNullOrWhiteSpace($IPAddress)) {
            continue
        }

        $ShareName = Get-PrinterShareName -Printer $Printer

        if ([string]::IsNullOrWhiteSpace($ShareName)) {
            continue
        }

        $AllPrintServerPrinters += [PSCustomObject]@{
            Server      = $Server
            PrinterName = $Printer.Name
            ShareName   = $ShareName
            PortName    = $Printer.PortName
            IPAddress   = $IPAddress
            Shared      = $Printer.Shared
        }
    }
}

if (-not $AllPrintServerPrinters -or $AllPrintServerPrinters.Count -eq 0) {
    Write-Host "No usable print server printers with IP addresses were found." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Total print server printers with IP addresses: $($AllPrintServerPrinters.Count)" -ForegroundColor Green

# -------------------------------
# Build IP lookup
# -------------------------------

$LookupByIP = @{}

foreach ($Item in $AllPrintServerPrinters) {

    $IP = Normalize-IP -IPAddress $Item.IPAddress

    if ([string]::IsNullOrWhiteSpace($IP)) {
        continue
    }

    if (-not $LookupByIP.ContainsKey($IP)) {
        $LookupByIP[$IP] = @()
    }

    $LookupByIP[$IP] += $Item
}

Write-Host "Unique IPs found on print servers: $($LookupByIP.Count)" -ForegroundColor Green

# -------------------------------
# Update CSV names
# -------------------------------

$Results = @()

foreach ($Row in $CsvRows) {

    $OldName = [string]$Row.name
    $Address = Normalize-IP -IPAddress $Row.address

    if ([string]::IsNullOrWhiteSpace($Address)) {
        $Results += [PSCustomObject]@{
            Address       = ""
            OldName       = $OldName
            NewName       = ""
            MatchedServer = ""
            MatchedShare  = ""
            Status        = "Skipped"
            Message       = "CSV address is empty"
        }

        continue
    }

    if (-not $LookupByIP.ContainsKey($Address)) {
        $Results += [PSCustomObject]@{
            Address       = $Address
            OldName       = $OldName
            NewName       = $OldName
            MatchedServer = ""
            MatchedShare  = ""
            Status        = "NoMatch"
            Message       = "No matching print server printer found by IP"
        }

        continue
    }

    $Matches = @($LookupByIP[$Address])

    # Prefer configured server if duplicate IP exists.
    $PreferredMatch = $Matches |
        Where-Object { $_.Server -ieq $PreferredServer } |
        Select-Object -First 1

    if ($PreferredMatch) {
        $SelectedMatch = $PreferredMatch
    }
    else {
        $SelectedMatch = $Matches | Select-Object -First 1
    }

    $NewName = [string]$SelectedMatch.ShareName

    if ([string]::IsNullOrWhiteSpace($NewName)) {
        $Results += [PSCustomObject]@{
            Address       = $Address
            OldName       = $OldName
            NewName       = $OldName
            MatchedServer = $SelectedMatch.Server
            MatchedShare  = ""
            Status        = "Skipped"
            Message       = "Match found but share name was empty"
        }

        continue
    }

    # Update row name.
    $Row.name = $NewName

    $Status = if ($OldName -eq $NewName) {
        "AlreadyCorrect"
    }
    else {
        "Updated"
    }

    $DuplicateMessage = if ($Matches.Count -gt 1) {
        "Multiple matches found for IP. Selected \\$($SelectedMatch.Server)\$($SelectedMatch.ShareName)"
    }
    else {
        "Matched by IP"
    }

    $Results += [PSCustomObject]@{
        Address       = $Address
        OldName       = $OldName
        NewName       = $NewName
        MatchedServer = $SelectedMatch.Server
        MatchedShare  = $SelectedMatch.ShareName
        Status        = $Status
        Message       = $DuplicateMessage
    }
}

# -------------------------------
# Export updated CSV WITHOUT quotes
# -------------------------------

$OutputLines = @()
$OutputLines += $ExpectedHeader

foreach ($Row in $CsvRows) {
    $OutputLines += Convert-PrintixRowToLine -Row $Row
}

try {
    Set-Content -Path $UpdatedPath -Value $OutputLines -Encoding UTF8
    Write-Host "Updated CSV exported without quotes: $UpdatedPath" -ForegroundColor Green
}
catch {
    Write-Host "Failed to write updated CSV." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

# -------------------------------
# Export log WITHOUT quotes
# -------------------------------

$LogLines = @()
$LogLines += "Address;OldName;NewName;MatchedServer;MatchedShare;Status;Message"

foreach ($Result in $Results) {
    $LogLines += Convert-LogRowToLine -Row $Result
}

try {
    Set-Content -Path $LogPath -Value $LogLines -Encoding UTF8
    Write-Host "Log exported without quotes: $LogPath" -ForegroundColor Green
}
catch {
    Write-Host "Failed to write log CSV." -ForegroundColor Yellow
    Write-Host $_.Exception.Message
}

# -------------------------------
# Optional overwrite
# -------------------------------

if ($OverwriteOriginal) {
    try {
        Copy-Item -Path $UpdatedPath -Destination $CsvPath -Force
        Write-Host "Original CSV overwritten: $CsvPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to overwrite original CSV." -ForegroundColor Red
        Write-Host $_.Exception.Message
        exit 1
    }
}
else {
    Write-Host ""
    Write-Host "Original CSV was NOT overwritten." -ForegroundColor Yellow
    Write-Host "Review this updated file first:" -ForegroundColor Yellow
    Write-Host $UpdatedPath -ForegroundColor Yellow
}

# -------------------------------
# Summary
# -------------------------------

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan

$Results |
    Group-Object Status |
    Select-Object Name, Count |
    Format-Table -AutoSize