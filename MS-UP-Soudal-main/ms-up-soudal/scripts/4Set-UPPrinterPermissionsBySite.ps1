# ============================================================
# Set Universal Print printer share permissions by site
#
# CSV:
# C:\Temp\up-printer-properties.csv
#
# Matching:
# Printer share name: BETUSO5_PRO_AE511
# Site code:          BETUSO5
# CSV Site:           Turnhout
# Group:              UP-Office-Turnhout-Users
#
# Action:
# Grants the matching group access to the printer share.
#
# Optional:
# Can remove other UP-Office-* groups from the same printer share.
# ============================================================

# -------------------------------
# Configuration
# -------------------------------

$CsvPath = "$PSScriptRoot\up-printer-properties.csv"
$LogPath = "$PSScriptRoot\up-printer-permission-results.csv"
$TranscriptPath = "$PSScriptRoot\up-printer-permission-transcript.txt"

$GroupPrefix = "UP-Office"
$GroupSuffix = "Users"

# Start safe.
# Set to $false after reviewing the log.
$WhatIfMode = $true

# If true, removes other UP-Office-* groups from a printer share
# so only the correct location group remains.
# Recommended first run: $false
$RemoveOtherUPOfficeGroups = $false

# If true, skips grant when target group already has access.
$SkipIfAlreadyAssigned = $true


# -------------------------------
# Start transcript
# -------------------------------

Start-Transcript -Path $TranscriptPath -Force


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

    if ($Object.PSObject.Properties.Name -contains "AdditionalProperties") {
        foreach ($Name in $Names) {
            if ($Object.AdditionalProperties -and $Object.AdditionalProperties.ContainsKey($Name)) {
                return [string]$Object.AdditionalProperties[$Name]
            }
        }
    }

    return ""
}

function Get-UPResults {
    param (
        [AllowNull()]
        $Object
    )

    if ($null -eq $Object) {
        return @()
    }

    if ($Object.PSObject.Properties.Name -contains "Results") {
        return @($Object.Results)
    }

    return @($Object)
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

function Get-SafeGroupNamePart {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $Clean = $Text.Trim()
    $Clean = $Clean -replace '[\\/]', '-'
    $Clean = $Clean -replace '\s+', ' '

    return $Clean
}

function Escape-ODataString {
    param (
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return $Value -replace "'", "''"
}

function Get-UPAllowedMembersSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PrinterShareId
    )

    $Command = Get-Command Get-UPAllowedMember -ErrorAction Stop
    $Params = $Command.Parameters.Keys

    $Splat = @{}

    if ($Params -contains "PrinterShareId") {
        $Splat["PrinterShareId"] = $PrinterShareId
    }
    elseif ($Params -contains "ShareId") {
        $Splat["ShareId"] = $PrinterShareId
    }
    else {
        throw "Get-UPAllowedMember does not expose PrinterShareId or ShareId. Run: Get-Command Get-UPAllowedMember -Syntax"
    }

    $Raw = Get-UPAllowedMember @Splat -ErrorAction Stop
    return Get-UPResults -Object $Raw
}

function Grant-UPGroupAccessSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PrinterShareId,

        [Parameter(Mandatory = $true)]
        [string]$GroupId
    )

    $Command = Get-Command Grant-UPAccess -ErrorAction Stop
    $Params = $Command.Parameters.Keys

    $Splat = @{}

    if ($Params -contains "PrinterShareId") {
        $Splat["PrinterShareId"] = $PrinterShareId
    }
    elseif ($Params -contains "ShareId") {
        $Splat["ShareId"] = $PrinterShareId
    }
    else {
        throw "Grant-UPAccess does not expose PrinterShareId or ShareId. Run: Get-Command Grant-UPAccess -Syntax"
    }

    if ($Params -contains "GroupId") {
        $Splat["GroupId"] = $GroupId
    }
    elseif ($Params -contains "MemberId") {
        $Splat["MemberId"] = $GroupId
    }
    elseif ($Params -contains "AllowedMemberId") {
        $Splat["AllowedMemberId"] = $GroupId
    }
    elseif ($Params -contains "ObjectId") {
        $Splat["ObjectId"] = $GroupId
    }
    else {
        throw "Grant-UPAccess does not expose GroupId, MemberId, AllowedMemberId, or ObjectId. Run: Get-Command Grant-UPAccess -Syntax"
    }

    Grant-UPAccess @Splat -ErrorAction Stop
}

function Revoke-UPGroupAccessSafe {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PrinterShareId,

        [Parameter(Mandatory = $true)]
        [string]$MemberId
    )

    $Command = Get-Command Revoke-UPAccess -ErrorAction Stop
    $Params = $Command.Parameters.Keys

    $Splat = @{}

    if ($Params -contains "PrinterShareId") {
        $Splat["PrinterShareId"] = $PrinterShareId
    }
    elseif ($Params -contains "ShareId") {
        $Splat["ShareId"] = $PrinterShareId
    }
    else {
        throw "Revoke-UPAccess does not expose PrinterShareId or ShareId. Run: Get-Command Revoke-UPAccess -Syntax"
    }

    if ($Params -contains "MemberId") {
        $Splat["MemberId"] = $MemberId
    }
    elseif ($Params -contains "AllowedMemberId") {
        $Splat["AllowedMemberId"] = $MemberId
    }
    elseif ($Params -contains "GroupId") {
        $Splat["GroupId"] = $MemberId
    }
    elseif ($Params -contains "ObjectId") {
        $Splat["ObjectId"] = $MemberId
    }
    else {
        throw "Revoke-UPAccess does not expose MemberId, AllowedMemberId, GroupId, or ObjectId. Run: Get-Command Revoke-UPAccess -Syntax"
    }

    Revoke-UPAccess @Splat -ErrorAction Stop
}

function Test-AllowedMemberIsTargetGroup {
    param (
        [Parameter(Mandatory = $true)]
        $Member,

        [Parameter(Mandatory = $true)]
        [string]$TargetGroupId,

        [Parameter(Mandatory = $true)]
        [string]$TargetGroupName
    )

    $MemberId = Get-ObjectValue -Object $Member -Names @(
        "Id",
        "ObjectId",
        "MemberId",
        "GroupId",
        "UserId"
    )

    $MemberName = Get-ObjectValue -Object $Member -Names @(
        "DisplayName",
        "Name",
        "UserPrincipalName"
    )

    if (-not (Test-IsBlank -Value $MemberId) -and $MemberId -eq $TargetGroupId) {
        return $true
    }

    if (-not (Test-IsBlank -Value $MemberName) -and $MemberName -eq $TargetGroupName) {
        return $true
    }

    return $false
}

function Test-AllowedMemberIsUPOfficeGroup {
    param (
        [Parameter(Mandatory = $true)]
        $Member
    )

    $MemberName = Get-ObjectValue -Object $Member -Names @(
        "DisplayName",
        "Name",
        "UserPrincipalName"
    )

    if ($MemberName -like "$GroupPrefix-*-${GroupSuffix}") {
        return $true
    }

    return $false
}


# -------------------------------
# Validate CSV
# -------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
    Stop-Transcript
    exit 1
}

try {
    $Rows = Import-Csv -Path $CsvPath -ErrorAction Stop
}
catch {
    Write-Host "Failed to import CSV." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}

if (-not $Rows -or $Rows.Count -eq 0) {
    Write-Host "CSV contains no rows." -ForegroundColor Red
    Stop-Transcript
    exit 1
}

$FirstRow = $Rows | Select-Object -First 1

foreach ($RequiredColumn in @("Site code", "Site")) {
    if (-not ($FirstRow.PSObject.Properties.Name -contains $RequiredColumn)) {
        Write-Host "CSV is missing required column: $RequiredColumn" -ForegroundColor Red
        Stop-Transcript
        exit 1
    }
}


# -------------------------------
# Build SiteCode -> Site lookup
# -------------------------------

$SiteCodeToSite = @{}

foreach ($Row in $Rows) {
    $SiteCode = [string]$Row.'Site code'
    $Site = [string]$Row.Site

    if (Test-IsBlank -Value $SiteCode) {
        continue
    }

    if (Test-IsBlank -Value $Site) {
        continue
    }

    $SiteCodeToSite[$SiteCode.Trim().ToUpper()] = $Site.Trim()
}

Write-Host "Loaded $($SiteCodeToSite.Count) site-code mappings from CSV." -ForegroundColor Green


# -------------------------------
# Load modules
# -------------------------------

try {
    Import-Module UniversalPrintManagement -ErrorAction Stop
}
catch {
    Write-Host "Failed to import UniversalPrintManagement." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}

try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) {
        Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
        Install-Module Microsoft.Graph -Scope CurrentUser -Force
    }

    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
}
catch {
    Write-Host "Failed to import Microsoft.Graph.Groups." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}


# -------------------------------
# Connect services
# -------------------------------

try {
    Write-Host "Connecting to Universal Print..." -ForegroundColor Cyan
    Connect-UPService
}
catch {
    Write-Host "Failed to connect to Universal Print." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}

try {
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    Connect-MgGraph -Scopes @(
        "Group.Read.All",
        "Directory.Read.All"
    ) -ErrorAction Stop
}
catch {
    Write-Host "Failed to connect to Microsoft Graph." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}


# -------------------------------
# Get Universal Print shares
# -------------------------------

try {
    Write-Host "Retrieving Universal Print printer shares..." -ForegroundColor Cyan
    $SharesRaw = Get-UPPrinterShare -ErrorAction Stop
    $Shares = Get-UPResults -Object $SharesRaw
}
catch {
    Write-Host "Failed to retrieve printer shares." -ForegroundColor Red
    Write-Host $_.Exception.Message
    Stop-Transcript
    exit 1
}

Write-Host "Printer shares found: $($Shares.Count)" -ForegroundColor Green

if ($Shares.Count -eq 0) {
    Write-Host "No printer shares found. Printers must be shared before access can be granted." -ForegroundColor Red
    Stop-Transcript
    exit 1
}


# -------------------------------
# Process shares
# -------------------------------

$Results = @()

foreach ($Share in $Shares) {

    $ShareName = Get-ObjectValue -Object $Share -Names @(
        "DisplayName",
        "Name",
        "PrinterShareName",
        "ShareName"
    )

    $ShareId = Get-ObjectValue -Object $Share -Names @(
        "Id",
        "PrinterShareId",
        "ShareId"
    )

    if (Test-IsBlank -Value $ShareName) {
        $Results += [PSCustomObject]@{
            ShareName = ""
            ShareId   = $ShareId
            SiteCode  = ""
            Site      = ""
            GroupName = ""
            GroupId   = ""
            Action    = "ReadShare"
            Status    = "Skipped"
            Message   = "Share has no readable name"
        }
        continue
    }

    if (Test-IsBlank -Value $ShareId) {
        $Results += [PSCustomObject]@{
            ShareName = $ShareName
            ShareId   = ""
            SiteCode  = ""
            Site      = ""
            GroupName = ""
            GroupId   = ""
            Action    = "ReadShare"
            Status    = "Skipped"
            Message   = "Share has no readable ID"
        }
        continue
    }

    $SiteCode = Get-SiteCodeFromPrinterName -PrinterName $ShareName

    if (-not $SiteCodeToSite.ContainsKey($SiteCode)) {
        Write-Host "No CSV mapping for share '$ShareName' using site code '$SiteCode'." -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            ShareName = $ShareName
            ShareId   = $ShareId
            SiteCode  = $SiteCode
            Site      = ""
            GroupName = ""
            GroupId   = ""
            Action    = "MapSite"
            Status    = "Skipped"
            Message   = "No Site code mapping found in CSV"
        }
        continue
    }

    $Site = $SiteCodeToSite[$SiteCode]
    $SafeSiteName = Get-SafeGroupNamePart -Text $Site
    $GroupName = "$GroupPrefix-$SafeSiteName-$GroupSuffix"

    Write-Host ""
    Write-Host "Printer share: $ShareName" -ForegroundColor Cyan
    Write-Host "Site code: $SiteCode"
    Write-Host "Site: $Site"
    Write-Host "Target group: $GroupName"

    # Find group
    $EscapedGroupName = Escape-ODataString -Value $GroupName
    $GroupFilter = "displayName eq '$EscapedGroupName'"

    try {
        $Group = Get-MgGroup `
            -Filter $GroupFilter `
            -Property Id,DisplayName `
            -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        Write-Host "Failed to query group '$GroupName'." -ForegroundColor Red
        Write-Host $_.Exception.Message

        $Results += [PSCustomObject]@{
            ShareName = $ShareName
            ShareId   = $ShareId
            SiteCode  = $SiteCode
            Site      = $Site
            GroupName = $GroupName
            GroupId   = ""
            Action    = "FindGroup"
            Status    = "Failed"
            Message   = $_.Exception.Message
        }
        continue
    }

    if (-not $Group) {
        Write-Host "Group not found: $GroupName" -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            ShareName = $ShareName
            ShareId   = $ShareId
            SiteCode  = $SiteCode
            Site      = $Site
            GroupName = $GroupName
            GroupId   = ""
            Action    = "FindGroup"
            Status    = "Skipped"
            Message   = "Target group not found"
        }
        continue
    }

    $GroupId = $Group.Id

    # Get existing allowed members
    $AllowedMembers = @()

    try {
        $AllowedMembers = @(Get-UPAllowedMembersSafe -PrinterShareId $ShareId)
    }
    catch {
        Write-Host "Could not read allowed members for '$ShareName'. Will still try to grant access." -ForegroundColor Yellow
        Write-Host $_.Exception.Message
        $AllowedMembers = @()
    }

    $AlreadyAssigned = $false

    foreach ($Member in $AllowedMembers) {
        if (Test-AllowedMemberIsTargetGroup -Member $Member -TargetGroupId $GroupId -TargetGroupName $GroupName) {
            $AlreadyAssigned = $true
            break
        }
    }

    if ($AlreadyAssigned -and $SkipIfAlreadyAssigned) {
        Write-Host "Target group already has access." -ForegroundColor Green

        $Results += [PSCustomObject]@{
            ShareName = $ShareName
            ShareId   = $ShareId
            SiteCode  = $SiteCode
            Site      = $Site
            GroupName = $GroupName
            GroupId   = $GroupId
            Action    = "GrantAccess"
            Status    = "Skipped"
            Message   = "Target group already has access"
        }
    }
    else {
        if ($WhatIfMode) {
            Write-Host "WHATIF: Would grant access to $GroupName." -ForegroundColor Yellow

            $Results += [PSCustomObject]@{
                ShareName = $ShareName
                ShareId   = $ShareId
                SiteCode  = $SiteCode
                Site      = $Site
                GroupName = $GroupName
                GroupId   = $GroupId
                Action    = "GrantAccess"
                Status    = "WhatIf"
                Message   = "Would grant target group access"
            }
        }
        else {
            try {
                Grant-UPGroupAccessSafe -PrinterShareId $ShareId -GroupId $GroupId

                Write-Host "Granted access to $GroupName." -ForegroundColor Green

                $Results += [PSCustomObject]@{
                    ShareName = $ShareName
                    ShareId   = $ShareId
                    SiteCode  = $SiteCode
                    Site      = $Site
                    GroupName = $GroupName
                    GroupId   = $GroupId
                    Action    = "GrantAccess"
                    Status    = "Granted"
                    Message   = "Granted target group access"
                }
            }
            catch {
                Write-Host "Failed to grant access to $GroupName." -ForegroundColor Red
                Write-Host $_.Exception.Message

                $Results += [PSCustomObject]@{
                    ShareName = $ShareName
                    ShareId   = $ShareId
                    SiteCode  = $SiteCode
                    Site      = $Site
                    GroupName = $GroupName
                    GroupId   = $GroupId
                    Action    = "GrantAccess"
                    Status    = "Failed"
                    Message   = $_.Exception.Message
                }

                continue
            }
        }
    }

    # Optional cleanup: remove other UP-Office-* groups
    if ($RemoveOtherUPOfficeGroups -and $AllowedMembers.Count -gt 0) {

        foreach ($Member in $AllowedMembers) {

            $MemberId = Get-ObjectValue -Object $Member -Names @(
                "Id",
                "ObjectId",
                "MemberId",
                "GroupId"
            )

            $MemberName = Get-ObjectValue -Object $Member -Names @(
                "DisplayName",
                "Name",
                "UserPrincipalName"
            )

            if (Test-IsBlank -Value $MemberId) {
                continue
            }

            $IsTarget = Test-AllowedMemberIsTargetGroup `
                -Member $Member `
                -TargetGroupId $GroupId `
                -TargetGroupName $GroupName

            $IsUPOfficeGroup = Test-AllowedMemberIsUPOfficeGroup -Member $Member

            if ($IsUPOfficeGroup -and -not $IsTarget) {

                if ($WhatIfMode) {
                    Write-Host "WHATIF: Would remove old office group access: $MemberName" -ForegroundColor Yellow

                    $Results += [PSCustomObject]@{
                        ShareName = $ShareName
                        ShareId   = $ShareId
                        SiteCode  = $SiteCode
                        Site      = $Site
                        GroupName = $MemberName
                        GroupId   = $MemberId
                        Action    = "RevokeAccess"
                        Status    = "WhatIf"
                        Message   = "Would remove old UP-Office group access"
                    }
                }
                else {
                    try {
                        Revoke-UPGroupAccessSafe -PrinterShareId $ShareId -MemberId $MemberId

                        Write-Host "Removed old office group access: $MemberName" -ForegroundColor Green

                        $Results += [PSCustomObject]@{
                            ShareName = $ShareName
                            ShareId   = $ShareId
                            SiteCode  = $SiteCode
                            Site      = $Site
                            GroupName = $MemberName
                            GroupId   = $MemberId
                            Action    = "RevokeAccess"
                            Status    = "Revoked"
                            Message   = "Removed old UP-Office group access"
                        }
                    }
                    catch {
                        Write-Host "Failed to remove old office group access: $MemberName" -ForegroundColor Red
                        Write-Host $_.Exception.Message

                        $Results += [PSCustomObject]@{
                            ShareName = $ShareName
                            ShareId   = $ShareId
                            SiteCode  = $SiteCode
                            Site      = $Site
                            GroupName = $MemberName
                            GroupId   = $MemberId
                            Action    = "RevokeAccess"
                            Status    = "Failed"
                            Message   = $_.Exception.Message
                        }
                    }
                }
            }
        }
    }
}


# -------------------------------
# Export log
# -------------------------------

$Results | Export-Csv -Path $LogPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Log exported to: $LogPath" -ForegroundColor Cyan
Write-Host "Transcript exported to: $TranscriptPath" -ForegroundColor Cyan

if ($WhatIfMode) {
    Write-Host ""
    Write-Host "WHATIF mode enabled. No printer permissions were changed." -ForegroundColor Yellow
    Write-Host "Check the log, then set `$WhatIfMode = `$false and rerun." -ForegroundColor Yellow
}

Stop-Transcript