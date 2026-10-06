# ============================================================
# Update Universal Print printer properties from CSV
#
# CSV path:
# C:\Temp\up-printer-properties.csv
#
# Matches printer DisplayName:
# AEDUAM1_OFF_001 -> AEDUAM1
# BETUSO5_PRO_AE511 -> BETUSO5
# ============================================================

$CsvPath = "$PSScriptRoot\up-printer-properties.csv"
$LogPath = "$PSScriptRoot\up-printer-properties-log.csv"

# Set to $true for testing.
# Set to $false to actually update printers.
$WhatIfMode = $false

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

function Get-CsvValue {
    param (
        [Parameter(Mandatory = $true)]
        $Row,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($Name in $Names) {
        $Property = $Row.PSObject.Properties | Where-Object {
            $_.Name -ieq $Name
        } | Select-Object -First 1

        if ($Property) {
            return [string]$Property.Value
        }
    }

    return ""
}

function Get-ObjectValue {
    param (
        [Parameter(Mandatory = $true)]
        $Object,

        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($Name in $Names) {
        $Property = $Object.PSObject.Properties | Where-Object {
            $_.Name -ieq $Name
        } | Select-Object -First 1

        if ($Property) {
            return [string]$Property.Value
        }
    }

    return ""
}

function Get-SiteCodeFromPrinterName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PrinterName
    )

    if ($PrinterName -like "*_*") {
        return ($PrinterName.Split("_")[0]).Trim().ToUpper()
    }

    return $PrinterName.Trim().ToUpper()
}

function Add-ParameterIfSupported {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Splat,

        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$SupportedParams,

        [Parameter(Mandatory = $true)]
        [string[]]$PossibleParameterNames,

        [AllowNull()]
        [string]$Value
    )

    if (Test-IsBlank -Value $Value) {
        return
    }

    foreach ($ParameterName in $PossibleParameterNames) {
        if ($SupportedParams.ContainsKey($ParameterName)) {
            $Splat[$ParameterName] = $Value.Trim()
            return
        }
    }
}

# -------------------------------
# Validate CSV
# -------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
    exit 1
}

# -------------------------------
# Load Universal Print module
# -------------------------------

try {
    Import-Module UniversalPrintManagement -ErrorAction Stop
}
catch {
    Write-Host "Failed to import UniversalPrintManagement module." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host "Connecting to Universal Print..." -ForegroundColor Cyan
#Connect-UPService

# -------------------------------
# Import CSV
# -------------------------------

Write-Host "Reading CSV: $CsvPath" -ForegroundColor Cyan

try {
    $Rows = Import-Csv -Path $CsvPath -ErrorAction Stop
}
catch {
    Write-Host "Failed to import CSV." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

if (-not $Rows -or $Rows.Count -eq 0) {
    Write-Host "CSV has no rows." -ForegroundColor Red
    exit 1
}

$SiteLookup = @{}

foreach ($Row in $Rows) {

    $SiteCode = Get-CsvValue -Row $Row -Names @(
        "Site code",
        "Site Code",
        "site code"
    )

    if (Test-IsBlank -Value $SiteCode) {
        continue
    }

    $SiteCode = $SiteCode.Trim().ToUpper()

    $SiteLookup[$SiteCode] = [PSCustomObject]@{
        SiteCode          = $SiteCode
        Latitude          = Get-CsvValue -Row $Row -Names @("Latitude")
        Longitude         = Get-CsvValue -Row $Row -Names @("Longitude")
        Altitude          = Get-CsvValue -Row $Row -Names @("Altitude")
        Organization      = Get-CsvValue -Row $Row -Names @("Organization")
        Subdivision       = Get-CsvValue -Row $Row -Names @("Subdivision")
        Site              = Get-CsvValue -Row $Row -Names @("Site")
        Subunit           = Get-CsvValue -Row $Row -Names @("Subunit")
        Building          = Get-CsvValue -Row $Row -Names @("Building")
        FloorNumber       = Get-CsvValue -Row $Row -Names @("Floor Number", "FloorNumber")
        FloorDescription  = Get-CsvValue -Row $Row -Names @("Floor description", "FloorDescription")
        RoomNumber        = Get-CsvValue -Row $Row -Names @("Room Number", "RoomNumber")
        RoomDescription   = Get-CsvValue -Row $Row -Names @("Room description", "RoomDescription")
        StreetAddress     = Get-CsvValue -Row $Row -Names @("Street address", "StreetAddress")
        City              = Get-CsvValue -Row $Row -Names @("City")
        StateOrProvince   = Get-CsvValue -Row $Row -Names @("State or province", "StateOrProvince")
        PostalCode        = Get-CsvValue -Row $Row -Names @("Postal code", "PostalCode")
        CountryOrRegion   = Get-CsvValue -Row $Row -Names @("Country or region", "CountryOrRegion")
    }
}

Write-Host "Loaded $($SiteLookup.Count) site mappings from CSV." -ForegroundColor Green

# -------------------------------
# Get Universal Print printers
# -------------------------------

Write-Host "Retrieving Universal Print printers..." -ForegroundColor Cyan

try {
    $UPResponse = Get-UPPrinter -ErrorAction Stop
}
catch {
    Write-Host "Failed to retrieve Universal Print printers." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

if ($UPResponse.PSObject.Properties.Name -contains "Results") {
    $UPPrinters = @($UPResponse.Results)
}
else {
    $UPPrinters = @($UPResponse)
}

Write-Host "Universal Print printers found: $($UPPrinters.Count)" -ForegroundColor Green

if ($UPPrinters.Count -eq 0) {
    Write-Host "No printers found. Check account permissions and Universal Print registration." -ForegroundColor Red

    [PSCustomObject]@{
        PrinterName = ""
        PrinterId   = ""
        SiteCode    = ""
        Status      = "Failed"
        Message     = "Get-UPPrinter returned zero printers"
    } | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8

    exit 1
}

# -------------------------------
# Detect supported Set-UPPrinterProperty parameters
# -------------------------------

try {
    $SetCommand = Get-Command Set-UPPrinterProperty -ErrorAction Stop
}
catch {
    Write-Host "Set-UPPrinterProperty command not found." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

$SupportedParams = $SetCommand.Parameters

Write-Host "Set-UPPrinterProperty supports these parameters:" -ForegroundColor Cyan
$SupportedParams.Keys | Sort-Object | ForEach-Object {
    Write-Host " - $_"
}

# -------------------------------
# Update printers
# -------------------------------

$Results = @()

foreach ($Printer in $UPPrinters) {

    # Your Get-UPPrinter output uses DisplayName
    $PrinterName = Get-ObjectValue -Object $Printer -Names @(
        "DisplayName",
        "Name",
        "PrinterName"
    )

    $PrinterId = Get-ObjectValue -Object $Printer -Names @(
        "Id",
        "PrinterId"
    )

    if (Test-IsBlank -Value $PrinterName) {
        $Results += [PSCustomObject]@{
            PrinterName = ""
            PrinterId   = $PrinterId
            SiteCode    = ""
            Status      = "Skipped"
            Message     = "Printer has no DisplayName, Name, or PrinterName property"
        }
        continue
    }

    if (Test-IsBlank -Value $PrinterId) {
        $Results += [PSCustomObject]@{
            PrinterName = $PrinterName
            PrinterId   = ""
            SiteCode    = ""
            Status      = "Skipped"
            Message     = "Printer has no Id or PrinterId property"
        }
        continue
    }

    $DetectedSiteCode = Get-SiteCodeFromPrinterName -PrinterName $PrinterName

    if (-not $SiteLookup.ContainsKey($DetectedSiteCode)) {
        Write-Host "No CSV match for '$PrinterName' using site code '$DetectedSiteCode'." -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            PrinterName = $PrinterName
            PrinterId   = $PrinterId
            SiteCode    = $DetectedSiteCode
            Status      = "Skipped"
            Message     = "No CSV match"
        }
        continue
    }

    $Data = $SiteLookup[$DetectedSiteCode]

    $Splat = @{
        PrinterId = $PrinterId
    }

    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Latitude") -Value $Data.Latitude
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Longitude") -Value $Data.Longitude
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Altitude") -Value $Data.Altitude

    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Organization") -Value $Data.Organization
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Subdivision") -Value $Data.Subdivision
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Site") -Value $Data.Site
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Subunit") -Value $Data.Subunit
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("Building") -Value $Data.Building

    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("FloorNumber", "Floor") -Value $Data.FloorNumber
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("FloorDescription") -Value $Data.FloorDescription
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("RoomNumber") -Value $Data.RoomNumber
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("RoomDescription") -Value $Data.RoomDescription

    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("StreetAddress", "Street") -Value $Data.StreetAddress
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("City") -Value $Data.City
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("StateOrProvince") -Value $Data.StateOrProvince
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("PostalCode") -Value $Data.PostalCode
    Add-ParameterIfSupported -Splat $Splat -SupportedParams $SupportedParams -PossibleParameterNames @("CountryOrRegion", "Country") -Value $Data.CountryOrRegion

    if ($Splat.Keys.Count -le 1) {
        Write-Host "No non-empty supported properties for '$PrinterName'." -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            PrinterName = $PrinterName
            PrinterId   = $PrinterId
            SiteCode    = $DetectedSiteCode
            Status      = "Skipped"
            Message     = "No non-empty supported properties"
        }
        continue
    }

    Write-Host ""
    Write-Host "Printer: $PrinterName" -ForegroundColor Cyan
    Write-Host "Detected site code: $DetectedSiteCode"
    Write-Host "CSV site: $($Data.Site)"
    Write-Host "CSV organization: $($Data.Organization)"
    Write-Host "CSV city: $($Data.City)"
    Write-Host "CSV country: $($Data.CountryOrRegion)"

    try {
        if ($WhatIfMode) {
            Write-Host "WHATIF: Would update with:" -ForegroundColor Yellow

            $Splat.GetEnumerator() |
                Sort-Object Name |
                ForEach-Object {
                    Write-Host "  $($_.Name): $($_.Value)"
                }

            $Results += [PSCustomObject]@{
                PrinterName = $PrinterName
                PrinterId   = $PrinterId
                SiteCode    = $DetectedSiteCode
                Status      = "WhatIf"
                Message     = "Would update"
            }
        }
        else {
            Set-UPPrinterProperty @Splat -ErrorAction Stop

            Write-Host "Updated '$PrinterName'." -ForegroundColor Green

            $Results += [PSCustomObject]@{
                PrinterName = $PrinterName
                PrinterId   = $PrinterId
                SiteCode    = $DetectedSiteCode
                Status      = "Updated"
                Message     = "Success"
            }
        }
    }
    catch {
        Write-Host "Failed to update '$PrinterName': $($_.Exception.Message)" -ForegroundColor Red

        $Results += [PSCustomObject]@{
            PrinterName = $PrinterName
            PrinterId   = $PrinterId
            SiteCode    = $DetectedSiteCode
            Status      = "Failed"
            Message     = $_.Exception.Message
        }
    }
}

# -------------------------------
# Export log
# -------------------------------

if (-not $Results -or $Results.Count -eq 0) {
    $Results = @(
        [PSCustomObject]@{
            PrinterName = ""
            PrinterId   = ""
            SiteCode    = ""
            Status      = "NoResults"
            Message     = "No result objects were generated"
        }
    )
}

$Results | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Log exported to: $LogPath" -ForegroundColor Cyan

if ($WhatIfMode) {
    Write-Host ""
    Write-Host "WHATIF mode was enabled. No printers were changed." -ForegroundColor Yellow
    Write-Host "If the log looks correct, set `$WhatIfMode = `$false and rerun." -ForegroundColor Yellow
}