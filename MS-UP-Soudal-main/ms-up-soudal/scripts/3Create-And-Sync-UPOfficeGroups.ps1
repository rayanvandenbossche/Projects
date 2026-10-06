# ============================================================
# Create Universal Print office groups and add users by OfficeLocation
#
# CSV:
# C:\Temp\up-printer-properties.csv
#
# Uses CSV column:
# Site
#
# Creates static security groups:
# UP-Office-<Site>-Users
#
# Adds users where:
# User.OfficeLocation equals CSV Site
#
# Example:
# CSV Site           = Turnhout
# User OfficeLocation = Turnhout
# Group              = UP-Office-Turnhout-Users
# ============================================================

# -------------------------------
# Configuration
# -------------------------------

$CsvPath = "$PSScriptRoot\up-printer-properties.csv"
$LogPath = "$PSScriptRoot\up-office-group-create-and-sync-results.csv"

$GroupPrefix = "UP-Office"
$GroupSuffix = "Users"

# Start in test mode.
# Set to $false when the output/log looks correct.
$WhatIfMode = $true

# Matching mode:
# Exact    = OfficeLocation must equal Site
# Contains = OfficeLocation must contain Site
$MatchMode = "Exact"

# If true, update description of existing static groups.
$UpdateExistingGroupDescription = $true

# Safety:
# If an existing group is dynamic, the script will skip it.
# Dynamic groups cannot be manually managed.
$SkipDynamicGroups = $true


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

function Get-SafeMailNickname {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $Clean = [regex]::Replace($Text, '[^a-zA-Z0-9]', '')

    if ([string]::IsNullOrWhiteSpace($Clean)) {
        $Clean = "Location"
    }

    if ($Clean.Length -gt 40) {
        $Clean = $Clean.Substring(0, 40)
    }

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

function Get-UserOfficeLocation {
    param (
        [Parameter(Mandatory = $true)]
        $User
    )

    if (-not [string]::IsNullOrWhiteSpace($User.OfficeLocation)) {
        return [string]$User.OfficeLocation
    }

    if ($User.AdditionalProperties -and $User.AdditionalProperties.ContainsKey("officeLocation")) {
        return [string]$User.AdditionalProperties["officeLocation"]
    }

    return ""
}

function Test-OfficeLocationMatch {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OfficeLocation,

        [Parameter(Mandatory = $true)]
        [string]$Site,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    if ($Mode -eq "Contains") {
        return ($OfficeLocation -like "*$Site*")
    }

    return ($OfficeLocation -eq $Site)
}


# -------------------------------
# Validate CSV
# -------------------------------

if (-not (Test-Path $CsvPath)) {
    Write-Host "CSV not found: $CsvPath" -ForegroundColor Red
    exit 1
}

try {
    $Rows = Import-Csv -Path $CsvPath -ErrorAction Stop
}
catch {
    Write-Host "Failed to import CSV: $CsvPath" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

if (-not $Rows -or $Rows.Count -eq 0) {
    Write-Host "CSV contains no rows." -ForegroundColor Red
    exit 1
}

$FirstRow = $Rows | Select-Object -First 1

if (-not ($FirstRow.PSObject.Properties.Name -contains "Site")) {
    Write-Host "CSV is missing required column: Site" -ForegroundColor Red
    exit 1
}


# -------------------------------
# Get unique sites from CSV
# -------------------------------

$Sites = $Rows |
    ForEach-Object { [string]$_.Site } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { $_.Trim() } |
    Sort-Object -Unique

if (-not $Sites -or $Sites.Count -eq 0) {
    Write-Host "No non-empty Site values found in CSV." -ForegroundColor Red
    exit 1
}

Write-Host "Unique sites found in CSV: $($Sites.Count)" -ForegroundColor Green


# -------------------------------
# Load Microsoft Graph modules
# -------------------------------

if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Users)) {
    Write-Host "Microsoft.Graph module not found. Installing..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Users -ErrorAction Stop
Import-Module Microsoft.Graph.Groups -ErrorAction Stop


# -------------------------------
# Connect to Microsoft Graph
# -------------------------------

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan

Connect-MgGraph -Scopes @(
    "User.Read.All",
    "Group.ReadWrite.All",
    "GroupMember.ReadWrite.All",
    "Directory.Read.All"
)

$Context = Get-MgContext

if (-not $Context) {
    Write-Host "Microsoft Graph connection failed." -ForegroundColor Red
    exit 1
}

Write-Host "Connected to tenant: $($Context.TenantId)" -ForegroundColor Green


# -------------------------------
# Retrieve users with OfficeLocation
# -------------------------------

Write-Host "Retrieving users with OfficeLocation..." -ForegroundColor Cyan

try {
    $Users = Get-MgUser -All -Property "id,displayName,userPrincipalName,mail,officeLocation" -ErrorAction Stop
}
catch {
    Write-Host "Failed to retrieve users." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

$UsersWithOffice = foreach ($User in $Users) {
    $OfficeLocation = Get-UserOfficeLocation -User $User

    if (-not [string]::IsNullOrWhiteSpace($OfficeLocation)) {
        [PSCustomObject]@{
            Id                = $User.Id
            DisplayName       = $User.DisplayName
            UserPrincipalName = $User.UserPrincipalName
            Mail              = $User.Mail
            OfficeLocation    = $OfficeLocation.Trim()
        }
    }
}

$UsersWithOffice = @($UsersWithOffice)

Write-Host "Users with OfficeLocation: $($UsersWithOffice.Count)" -ForegroundColor Green


# -------------------------------
# Create groups and add users
# -------------------------------

$Results = @()

foreach ($Site in $Sites) {

    $SafeSiteName = Get-SafeGroupNamePart -Text $Site

    $GroupName = "$GroupPrefix-$SafeSiteName-$GroupSuffix"

    $MailNicknameSite = Get-SafeMailNickname -Text $SafeSiteName
    $MailNickname = "UPOffice$MailNicknameSite$GroupSuffix"

    if ($MailNickname.Length -gt 64) {
        $MailNickname = $MailNickname.Substring(0, 64)
    }

    $Description = "Universal Print office group for '$Site'. Created/synced from $CsvPath. Members are matched by user OfficeLocation."

    Write-Host ""
    Write-Host "Processing site: $Site" -ForegroundColor Cyan
    Write-Host "Target group: $GroupName"
    Write-Host "MailNickname: $MailNickname"

    # Find matching users
    $MatchingUsers = $UsersWithOffice | Where-Object {
        Test-OfficeLocationMatch `
            -OfficeLocation $_.OfficeLocation `
            -Site $Site `
            -Mode $MatchMode
    }

    $MatchingUsers = @($MatchingUsers)

    Write-Host "Matching users: $($MatchingUsers.Count)"

    # Find existing group
    $EscapedGroupName = Escape-ODataString -Value $GroupName
    $GroupFilter = "displayName eq '$EscapedGroupName'"

    try {
        $Group = Get-MgGroup `
            -Filter $GroupFilter `
            -Property Id,DisplayName,GroupTypes,Description `
            -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
        Write-Host "Failed to query group: $GroupName" -ForegroundColor Red
        Write-Host $_.Exception.Message

        $Results += [PSCustomObject]@{
            Site              = $Site
            GroupName         = $GroupName
            GroupId           = ""
            UserPrincipalName = ""
            OfficeLocation    = ""
            Action            = "QueryGroup"
            Status            = "Failed"
            Message           = $_.Exception.Message
        }

        continue
    }

    # Create group if missing
    if (-not $Group) {

        try {
            if ($WhatIfMode) {
                Write-Host "WHATIF: Would create group: $GroupName" -ForegroundColor Yellow

                $Results += [PSCustomObject]@{
                    Site              = $Site
                    GroupName         = $GroupName
                    GroupId           = ""
                    UserPrincipalName = ""
                    OfficeLocation    = ""
                    Action            = "CreateGroup"
                    Status            = "WhatIf"
                    Message           = "Would create static security group"
                }

                # Cannot add users to a group that does not exist in WhatIf mode.
                continue
            }
            else {
                $Group = New-MgGroup `
                    -DisplayName $GroupName `
                    -MailEnabled:$false `
                    -MailNickname $MailNickname `
                    -SecurityEnabled:$true `
                    -Description $Description `
                    -ErrorAction Stop

                Write-Host "Created group: $GroupName" -ForegroundColor Green

                $Results += [PSCustomObject]@{
                    Site              = $Site
                    GroupName         = $GroupName
                    GroupId           = $Group.Id
                    UserPrincipalName = ""
                    OfficeLocation    = ""
                    Action            = "CreateGroup"
                    Status            = "Created"
                    Message           = "Created static security group"
                }
            }
        }
        catch {
            Write-Host "Failed to create group: $GroupName" -ForegroundColor Red
            Write-Host $_.Exception.Message

            $Results += [PSCustomObject]@{
                Site              = $Site
                GroupName         = $GroupName
                GroupId           = ""
                UserPrincipalName = ""
                OfficeLocation    = ""
                Action            = "CreateGroup"
                Status            = "Failed"
                Message           = $_.Exception.Message
            }

            continue
        }
    }
    else {
        Write-Host "Group exists: $GroupName" -ForegroundColor Green

        $Results += [PSCustomObject]@{
            Site              = $Site
            GroupName         = $GroupName
            GroupId           = $Group.Id
            UserPrincipalName = ""
            OfficeLocation    = ""
            Action            = "CheckGroup"
            Status            = "Exists"
            Message           = "Group already exists"
        }

        # Skip existing dynamic groups
        if ($Group.GroupTypes -contains "DynamicMembership") {
            Write-Host "Existing group is dynamic. Cannot manually add members: $GroupName" -ForegroundColor Yellow

            $Results += [PSCustomObject]@{
                Site              = $Site
                GroupName         = $GroupName
                GroupId           = $Group.Id
                UserPrincipalName = ""
                OfficeLocation    = ""
                Action            = "SyncMembers"
                Status            = "Skipped"
                Message           = "Group is dynamic; manual member sync not allowed"
            }

            if ($SkipDynamicGroups) {
                continue
            }
        }

        # Optional description update
        if ($UpdateExistingGroupDescription -and -not $WhatIfMode) {
            try {
                Update-MgGroup `
                    -GroupId $Group.Id `
                    -Description $Description `
                    -ErrorAction Stop
            }
            catch {
                Write-Host "Warning: failed to update group description." -ForegroundColor Yellow
                Write-Host $_.Exception.Message
            }
        }
    }

    # If no matching users, log and continue
    if ($MatchingUsers.Count -eq 0) {
        Write-Host "No users matched site '$Site'." -ForegroundColor Yellow

        $Results += [PSCustomObject]@{
            Site              = $Site
            GroupName         = $GroupName
            GroupId           = $Group.Id
            UserPrincipalName = ""
            OfficeLocation    = ""
            Action            = "SyncMembers"
            Status            = "Skipped"
            Message           = "No users matched OfficeLocation"
        }

        continue
    }

    # Get existing members
    try {
        $ExistingMembers = Get-MgGroupMember `
            -GroupId $Group.Id `
            -All `
            -ErrorAction Stop

        $ExistingMemberIds = @($ExistingMembers | Select-Object -ExpandProperty Id)
    }
    catch {
        Write-Host "Failed to retrieve members for group: $GroupName" -ForegroundColor Red
        Write-Host $_.Exception.Message

        $Results += [PSCustomObject]@{
            Site              = $Site
            GroupName         = $GroupName
            GroupId           = $Group.Id
            UserPrincipalName = ""
            OfficeLocation    = ""
            Action            = "GetMembers"
            Status            = "Failed"
            Message           = $_.Exception.Message
        }

        continue
    }

    # Add matching users
    foreach ($User in $MatchingUsers) {

        if ($ExistingMemberIds -contains $User.Id) {
            Write-Host "Already member: $($User.UserPrincipalName)" -ForegroundColor Green

            $Results += [PSCustomObject]@{
                Site              = $Site
                GroupName         = $GroupName
                GroupId           = $Group.Id
                UserPrincipalName = $User.UserPrincipalName
                OfficeLocation    = $User.OfficeLocation
                Action            = "AddMember"
                Status            = "Skipped"
                Message           = "Already member"
            }

            continue
        }

        try {
            if ($WhatIfMode) {
                Write-Host "WHATIF: Would add user: $($User.UserPrincipalName)" -ForegroundColor Yellow

                $Results += [PSCustomObject]@{
                    Site              = $Site
                    GroupName         = $GroupName
                    GroupId           = $Group.Id
                    UserPrincipalName = $User.UserPrincipalName
                    OfficeLocation    = $User.OfficeLocation
                    Action            = "AddMember"
                    Status            = "WhatIf"
                    Message           = "Would add user to group"
                }
            }
            else {
                $Body = @{
                    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($User.Id)"
                }

                New-MgGroupMemberByRef `
                    -GroupId $Group.Id `
                    -BodyParameter $Body `
                    -ErrorAction Stop

                Write-Host "Added user: $($User.UserPrincipalName)" -ForegroundColor Green

                $Results += [PSCustomObject]@{
                    Site              = $Site
                    GroupName         = $GroupName
                    GroupId           = $Group.Id
                    UserPrincipalName = $User.UserPrincipalName
                    OfficeLocation    = $User.OfficeLocation
                    Action            = "AddMember"
                    Status            = "Added"
                    Message           = "User added to group"
                }
            }
        }
        catch {
            Write-Host "Failed to add user: $($User.UserPrincipalName)" -ForegroundColor Red
            Write-Host $_.Exception.Message

            $Results += [PSCustomObject]@{
                Site              = $Site
                GroupName         = $GroupName
                GroupId           = $Group.Id
                UserPrincipalName = $User.UserPrincipalName
                OfficeLocation    = $User.OfficeLocation
                Action            = "AddMember"
                Status            = "Failed"
                Message           = $_.Exception.Message
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

if ($WhatIfMode) {
    Write-Host ""
    Write-Host "WHATIF mode enabled. No groups or memberships were changed." -ForegroundColor Yellow
    Write-Host "Check the log, then set `$WhatIfMode = `$false and rerun." -ForegroundColor Yellow
}
``