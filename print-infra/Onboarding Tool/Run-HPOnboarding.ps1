# ============================================================
# HP MPS Printer Onboarding Tool Automation
# Using WinAppDriver
# ============================================================

# ----------------------------
# CONFIG
# ----------------------------

param(
    [string]$PrinterIpListPath = (Join-Path $PSScriptRoot "printer-ips.txt")
)

$WinAppDriverPath = "C:\Program Files (x86)\Windows Application Driver\WinAppDriver.exe"

$AppPath = Join-Path $env:LOCALAPPDATA "Programs\MPSPrinterOnboardingTool\HP MPS Printer Onboarding Tool.exe"

$EnvPath = Join-Path $PSScriptRoot ".env"
$CsvPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "..\print-portal\tmp\hp-printers.csv"))

$CustomerName = "SOUDAL NV-(SOUDAL NV)"

$DriverUrl = "http://127.0.0.1:4723"
$LogPath = "C:\Temp\HP-Onboarding-WinAppDriver.log"

# set to true to stop at final step
$DryRunBeforeStart = $false

# Optional timings
$DefaultTimeoutSeconds = 30
$PageWaitSeconds = 4
$DiscoverWaitSeconds = 10


# ----------------------------
# LOGGING
# ----------------------------

function Write-Log {
    param(
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"

    Write-Host $line
    Add-Content -Path $LogPath -Value $line
}


# ----------------------------
# .ENV LOADER
# ----------------------------

function Read-DotEnv {
    param(
        [string]$Path = (Join-Path $PSScriptRoot ".env")
    )

    if (-not (Test-Path $Path)) {
        throw " .env file not found at path: $Path"
    }

    $content = Get-Content -Path $Path -ErrorAction Stop

    $env = @{}

    foreach ($line in $content) {
        $trim = $line.Trim()
        if ($trim -eq '' -or $trim.StartsWith('#')) { continue }
        if ($trim -notmatch '=') { continue }

        $parts = $trim -split '=',2
        $key = $parts[0].Trim()
        $value = $parts[1].Trim()
        # remove surrounding quotes if present
        if ($value.StartsWith('"') -and $value.EndsWith('"')) {
            $value = $value.Substring(1,$value.Length-2)
        } elseif ($value.StartsWith("'") -and $value.EndsWith("'")) {
            $value = $value.Substring(1,$value.Length-2)
        }

        $env[$key] = $value
        # also set in current process environment for convenience
        [System.Environment]::SetEnvironmentVariable($key, $value)
    }

    return $env
}


# ----------------------------
# CSV GENERATION
# ----------------------------

function New-HpPrinterCsv {
    param(
        [string]$PrinterIpListPath,
        [string]$OutputPath
    )

    if (-not (Test-Path $PrinterIpListPath)) {
        throw "Printer IP list not found: $PrinterIpListPath"
    }

    $printerAddresses = Get-Content $PrinterIpListPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    if (-not $printerAddresses -or $printerAddresses.Count -eq 0) {
        throw "No printer addresses found in: $PrinterIpListPath"
    }

    $folder = Split-Path $OutputPath

    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    # HP template format:
    # Host Name/IP Address
    # 10.0.10.115
    # 10.0.10.43

    $lines = @()
    $lines += "Host Name/IP Address"
    $lines += $printerAddresses

    Set-Content `
        -Path $OutputPath `
        -Value $lines `
        -Encoding UTF8

    Write-Log "Created HP printer CSV: $OutputPath"
}


# ----------------------------
# WINAPPDRIVER FUNCTIONS
# ----------------------------

function Start-WinAppDriver {
    if (-not (Test-Path $WinAppDriverPath)) {
        throw "WinAppDriver not found at: $WinAppDriverPath"
    }

    $existing = Get-Process -Name "WinAppDriver" -ErrorAction SilentlyContinue

    if ($existing) {
        Write-Log "WinAppDriver is already running."
        return
    }

    Write-Log "Starting WinAppDriver..."
    Start-Process -FilePath $WinAppDriverPath -WindowStyle Minimized
    Start-Sleep -Seconds 3
}

function New-WadSession {
    param(
        [hashtable]$Capabilities
    )

    $body = @{
        capabilities = @{
            alwaysMatch = $Capabilities
        }
        desiredCapabilities = $Capabilities
    } | ConvertTo-Json -Depth 20

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$DriverUrl/session" `
        -ContentType "application/json" `
        -Body $body

    if ($response.sessionId) {
        return $response.sessionId
    }

    if ($response.value.sessionId) {
        return $response.value.sessionId
    }

    throw "Could not create WinAppDriver session. Response: $($response | ConvertTo-Json -Depth 20)"
}

function Remove-WadSession {
    param(
        [string]$SessionId
    )

    if ($SessionId) {
        try {
            Invoke-RestMethod `
                -Method Delete `
                -Uri "$DriverUrl/session/$SessionId" | Out-Null
        }
        catch {
            Write-Log "Warning: could not remove session $SessionId"
        }
    }
}

function Get-ElementId {
    param(
        $Element
    )

    $w3cId = "element-6066-11e4-a52e-4f735466cecf"

    if ($Element.ELEMENT) {
        return $Element.ELEMENT
    }

    if ($Element.$w3cId) {
        return $Element.$w3cId
    }

    if ($Element.value.ELEMENT) {
        return $Element.value.ELEMENT
    }

    if ($Element.value.$w3cId) {
        return $Element.value.$w3cId
    }

    throw "Could not extract element ID from: $($Element | ConvertTo-Json -Depth 20)"
}

function Find-Element {
    param(
        [string]$SessionId,
        [string]$Using,
        [string]$Value,
        [int]$TimeoutSeconds = 30
    )

    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $end) {
        try {
            $body = @{
                using = $Using
                value = $Value
            } | ConvertTo-Json

            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$DriverUrl/session/$SessionId/element" `
                -ContentType "application/json" `
                -Body $body

            if ($response.value) {
                return $response.value
            }

            return $response
        }
        catch {
            Start-Sleep -Milliseconds 500
        }
    }

    throw "Element not found. Using=[$Using], Value=[$Value]"
}

function Find-Elements {
    param(
        [string]$SessionId,
        [string]$Using,
        [string]$Value
    )

    $body = @{
        using = $Using
        value = $Value
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "$DriverUrl/session/$SessionId/elements" `
        -ContentType "application/json" `
        -Body $body

    return $response.value
}

function Click-Element {
    param(
        [string]$SessionId,
        $Element
    )

    $elementId = Get-ElementId $Element

    Invoke-RestMethod `
        -Method Post `
        -Uri "$DriverUrl/session/$SessionId/element/$elementId/click" `
        -ContentType "application/json" `
        -Body "{}" | Out-Null
}

function Clear-Element {
    param(
        [string]$SessionId,
        $Element
    )

    $elementId = Get-ElementId $Element

    Invoke-RestMethod `
        -Method Post `
        -Uri "$DriverUrl/session/$SessionId/element/$elementId/clear" `
        -ContentType "application/json" `
        -Body "{}" | Out-Null
}

function Send-Keys {
    param(
        [string]$SessionId,
        $Element,
        [string]$Text
    )

    $elementId = Get-ElementId $Element

    # Workaround for AZERTY/foreign keyboard layouts:
    # Use PowerShell's built-in SendKeys to paste the clipboard text,
    # as WinAppDriver struggles with non-QWERTY layouts and control characters.
    Set-Clipboard -Value $Text
    
    Add-Type -AssemblyName System.Windows.Forms
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait('^v')
    Start-Sleep -Milliseconds 200
}

function Get-ElementAttribute {
    param(
        [string]$SessionId,
        $Element,
        [string]$AttributeName
    )

    $elementId = Get-ElementId $Element

    $response = Invoke-RestMethod `
        -Method Get `
        -Uri "$DriverUrl/session/$SessionId/element/$elementId/attribute/$AttributeName"

    return $response.value
}


# ----------------------------
# HIGH-LEVEL UI HELPERS
# ----------------------------

function Click-ByName {
    param(
        [string]$SessionId,
        [string]$Name,
        [int]$TimeoutSeconds = 30
    )

    Write-Log "Clicking by Name: $Name"

    $element = Find-Element `
        -SessionId $SessionId `
        -Using "name" `
        -Value $Name `
        -TimeoutSeconds $TimeoutSeconds

    Click-Element `
        -SessionId $SessionId `
        -Element $element
}

function Click-ByAccessibilityId {
    param(
        [string]$SessionId,
        [string]$AutomationId,
        [int]$TimeoutSeconds = 30
    )

    Write-Log "Clicking by AutomationId: $AutomationId"

    $element = Find-Element `
        -SessionId $SessionId `
        -Using "accessibility id" `
        -Value $AutomationId `
        -TimeoutSeconds $TimeoutSeconds

    Click-Element `
        -SessionId $SessionId `
        -Element $element
}

function Type-ByAccessibilityId {
    param(
        [string]$SessionId,
        [string]$AutomationId,
        [string]$Text,
        [int]$TimeoutSeconds = 30,
        [switch]$Sensitive
    )

    if ($Sensitive) {
        Write-Log "Typing into AutomationId: $AutomationId [sensitive value hidden]"
    }
    else {
        Write-Log "Typing into AutomationId: $AutomationId"
    }

    $element = Find-Element `
        -SessionId $SessionId `
        -Using "accessibility id" `
        -Value $AutomationId `
        -TimeoutSeconds $TimeoutSeconds

    Write-Log "Clicking field $AutomationId to focus..."
    try {
        Click-Element -SessionId $SessionId -Element $element
        Start-Sleep -Milliseconds 300
    }
    catch {
        Write-Log "Could not click $AutomationId to focus. Continuing."
    }

    try {
        Clear-Element `
            -SessionId $SessionId `
            -Element $element
    }
    catch {
        Write-Log "Could not clear field $AutomationId. Continuing."
    }

    Send-Keys `
        -SessionId $SessionId `
        -Element $element `
        -Text $Text
}

function Type-ByName {
    param(
        [string]$SessionId,
        [string]$Name,
        [string]$Text,
        [int]$TimeoutSeconds = 30,
        [switch]$Sensitive
    )

    if ($Sensitive) {
        Write-Log "Typing into Name: $Name [sensitive value hidden]"
    }
    else {
        Write-Log "Typing into Name: $Name"
    }

    $element = Find-Element `
        -SessionId $SessionId `
        -Using "name" `
        -Value $Name `
        -TimeoutSeconds $TimeoutSeconds

    Write-Log "Clicking field $Name to focus..."
    try {
        Click-Element -SessionId $SessionId -Element $element
        Start-Sleep -Milliseconds 300
    }
    catch {
        Write-Log "Could not click $Name to focus. Continuing."
    }

    try {
        Clear-Element `
            -SessionId $SessionId `
            -Element $element
    }
    catch {
        Write-Log "Could not clear field $Name. Continuing."
    }

    Send-Keys `
        -SessionId $SessionId `
        -Element $element `
        -Text $Text
}

function Click-ByXPath {
    param(
        [string]$SessionId,
        [string]$XPath,
        [int]$TimeoutSeconds = 30
    )

    Write-Log "Clicking by XPath: $XPath"

    $element = Find-Element `
        -SessionId $SessionId `
        -Using "xpath" `
        -Value $XPath `
        -TimeoutSeconds $TimeoutSeconds

    Click-Element `
        -SessionId $SessionId `
        -Element $element
}

function Click-FirstAvailable {
    param(
        [string]$SessionId,
        [array]$Selectors,
        [int]$TimeoutSeconds = 5
    )

    foreach ($selector in $Selectors) {
        try {
            if ($selector.Type -eq "name") {
                Click-ByName `
                    -SessionId $SessionId `
                    -Name $selector.Value `
                    -TimeoutSeconds $TimeoutSeconds

                return $true
            }

            if ($selector.Type -eq "accessibility id") {
                Click-ByAccessibilityId `
                    -SessionId $SessionId `
                    -AutomationId $selector.Value `
                    -TimeoutSeconds $TimeoutSeconds

                return $true
            }

            if ($selector.Type -eq "xpath") {
                Click-ByXPath `
                    -SessionId $SessionId `
                    -XPath $selector.Value `
                    -TimeoutSeconds $TimeoutSeconds

                return $true
            }
        }
        catch {
            Write-Log "Selector failed: $($selector.Type) = $($selector.Value)"
        }
    }

    return $false
}


# ----------------------------
# ATTACH TO HP APP WINDOW
# ----------------------------

function Attach-To-AppWindow {
    param(
        [string]$ProcessName
    )

    Write-Log "Searching for process: $ProcessName"

    $end = (Get-Date).AddSeconds(60)

    while ((Get-Date) -lt $end) {
        $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        
        # Ensure we grab the actual main window by checking the title, 
        # avoiding hidden splash screens that might disappear before WinAppDriver attaches.
        $mainProc = $proc | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -match "HP MPS Printer Onboarding Tool" } | Select-Object -First 1

        if ($mainProc) {
            $hexHandle = "0x{0:x}" -f $mainProc.MainWindowHandle.ToInt64()

            Write-Log "Found process '$ProcessName' window handle: $hexHandle ($($mainProc.MainWindowTitle))"

            return New-WadSession -Capabilities @{
                appTopLevelWindow = $hexHandle
                platformName = "Windows"
                deviceName = "WindowsPC"
            }
        }

        Start-Sleep -Seconds 1
    }

    throw "Could not find window handle for process: $ProcessName"
}


# ----------------------------
# FILE DIALOG HANDLER
# ----------------------------

function Select-File-InOpenDialog {
    param(
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        throw "File does not exist: $FilePath"
    }

    Write-Log "Selecting file in Windows file picker: $FilePath"

    $desktopSession = New-WadSession -Capabilities @{
        app = "Root"
        platformName = "Windows"
        deviceName = "WindowsPC"
    }

    try {
        $dialogNames = @(
            "Open",
            "Choose File to Upload",
            "Choose File",
            "Select file",
            "File Upload"
        )

        $dialogFound = $false

        foreach ($dialogName in $dialogNames) {
            try {
                Find-Element `
                    -SessionId $desktopSession `
                    -Using "name" `
                    -Value $dialogName `
                    -TimeoutSeconds 3 | Out-Null

                Write-Log "File dialog found: $dialogName"
                $dialogFound = $true
                break
            }
            catch {
                # Try next dialog name
            }
        }

        if (-not $dialogFound) {
            Write-Log "Could not confirm file dialog by title. Trying filename field anyway."
        }

        # Ensure absolute path (Windows dialogs prefer absolute paths when typed in File Name box)
        $absolutePath = [System.IO.Path]::GetFullPath($FilePath)

        try {
            Write-Log "Attempting to locate 'File name' input box..."
            # In standard Windows dialogs, the File Name box has AutomationId = "1148"
            $fileNameInput = Find-Element `
                -SessionId $desktopSession `
                -Using "accessibility id" `
                -Value "1148" `
                -TimeoutSeconds 5

            Write-Log "Clicking File name input..."
            Click-Element -SessionId $desktopSession -Element $fileNameInput
            Start-Sleep -Milliseconds 500

            Write-Log "Pasting absolute file path: $absolutePath"
            Set-Clipboard -Value $absolutePath
            [System.Windows.Forms.SendKeys]::SendWait('^v')
            Start-Sleep -Milliseconds 500

            Write-Log "Pressing ENTER to submit..."
            [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
            Start-Sleep -Seconds 1
        }
        catch {
            Write-Log "Could not find 'File name' input box via ID 1148. Falling back to blind keyboard entry."
            Set-Clipboard -Value $absolutePath
            [System.Windows.Forms.SendKeys]::SendWait('^v')
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
            Start-Sleep -Seconds 1
        }

        Write-Log "CSV selected in file dialog."
    }
    finally {
        Remove-WadSession -SessionId $desktopSession
    }
}


# ----------------------------
# MAIN FLOW
# ----------------------------

try {
    New-Item `
        -ItemType Directory `
        -Path (Split-Path $LogPath) `
        -Force | Out-Null

    Write-Log "============================================================"
    Write-Log "Starting HP MPS onboarding automation"
    Write-Log "============================================================"

    if (-not (Test-Path $AppPath)) {
        throw "HP onboarding app not found: $AppPath"
    }

    $envValues = Read-DotEnv -Path $EnvPath

    $Email = $envValues["EMAIL"]
    $Password = $envValues["PASSWORD"]

    if ([string]::IsNullOrWhiteSpace($Email)) {
        throw "EMAIL is missing in .env file."
    }

    if ([string]::IsNullOrWhiteSpace($Password)) {
        throw "PASSWORD is missing in .env file."
    }

    New-HpPrinterCsv `
        -PrinterIpListPath $PrinterIpListPath `
        -OutputPath $CsvPath

    if (-not (Test-Path $CsvPath)) {
        throw "CSV file was not created: $CsvPath"
    }

    Start-WinAppDriver

    Write-Log "Launching HP onboarding tool..."
    Write-Log "App path: $AppPath"

    Start-Process -FilePath $AppPath

    Start-Sleep -Seconds 8

    $session = Attach-To-AppWindow -ProcessName "HP MPS Printer Onboarding Tool"

    try {
        # ----------------------------------------------------
        # Page 1: choose HP Device Control Center
        # ----------------------------------------------------

        Write-Log "Step 1: Selecting HP Device Control Center"

        Click-ByName `
            -SessionId $session `
            -Name "HP Device Control Center" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds $PageWaitSeconds


        # ----------------------------------------------------
        # Login page: username
        # ----------------------------------------------------

        Write-Log "Step 2: Entering email"

        # You said the edit field is 'username'.
        # This is probably AutomationId.
        try {
            Type-ByAccessibilityId `
                -SessionId $session `
                -AutomationId "username" `
                -Text $Email `
                -TimeoutSeconds $DefaultTimeoutSeconds
        }
        catch {
            Write-Log "Could not type username by AutomationId. Trying by Name."
            Type-ByName `
                -SessionId $session `
                -Name "username" `
                -Text $Email `
                -TimeoutSeconds $DefaultTimeoutSeconds
        }

        Write-Log "Step 3: Clicking Use password"

        Click-ByName `
            -SessionId $session `
            -Name "Use password" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds $PageWaitSeconds


        # ----------------------------------------------------
        # Login page: password
        # ----------------------------------------------------

        Write-Log "Step 4: Entering password"

        try {
            Type-ByAccessibilityId `
                -SessionId $session `
                -AutomationId "password" `
                -Text $Password `
                -TimeoutSeconds $DefaultTimeoutSeconds `
                -Sensitive
        }
        catch {
            Write-Log "Could not type password by AutomationId. Trying by Name."
            Type-ByName `
                -SessionId $session `
                -Name "password" `
                -Text $Password `
                -TimeoutSeconds $DefaultTimeoutSeconds `
                -Sensitive
        }

        Write-Log "Step 5: Clicking submit-button"

        $submitClicked = Click-FirstAvailable `
            -SessionId $session `
            -Selectors @(
                @{ Type = "accessibility id"; Value = "submit-button" },
                @{ Type = "name"; Value = "submit-button" },
                @{ Type = "xpath"; Value = "//Button[@Name='submit-button']" }
            ) `
            -TimeoutSeconds 5

        if (-not $submitClicked) {
            throw "Could not find the submit button."
        }

        Start-Sleep -Seconds 7


        # ----------------------------------------------------
        # Customer/tenant selection page
        # ----------------------------------------------------

        Write-Log "Step 6: Opening customer combo-box"

        $comboClicked = Click-FirstAvailable `
            -SessionId $session `
            -Selectors @(
                @{ Type = "xpath"; Value = "//ComboBox" }
            ) `
            -TimeoutSeconds 10

        if (-not $comboClicked) {
            throw "Could not click customer combo-box."
        }

        Start-Sleep -Seconds 1

        Write-Log "Step 7: Selecting customer: $CustomerName"

        Click-ByName `
            -SessionId $session `
            -Name $CustomerName `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds 1

        Write-Log "Step 8: Clicking Next after customer selection"

        Click-ByName `
            -SessionId $session `
            -Name "Next" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds 6

        # ----------------------------------------------------
        # Device page: Bulk Upload Devices
        # ----------------------------------------------------

        Write-Log "Step 8.a: Selecting Bulk Upload Devices"

        Click-ByName `
            -SessionId $session `
            -Name "Bulk Upload Devices" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds 2
        
        # ----------------------------------------------------
        # Device page: upload CSV
        # ----------------------------------------------------

        Write-Log "Step 9: Uploading CSV"

        $chooseFileClicked = Click-FirstAvailable `
            -SessionId $session `
            -Selectors @(
                @{ Type = "name"; Value = "Choose File: No file chosen" },
                @{ Type = "name"; Value = "Choose File" },
                @{ Type = "name"; Value = "Browse" },
                @{ Type = "xpath"; Value = "//*[contains(@Name,'Choose File')]" },
                @{ Type = "xpath"; Value = "//*[contains(@Name,'No file chosen')]" }
            ) `
            -TimeoutSeconds 10

        if (-not $chooseFileClicked) {
            throw "Could not find the Choose File button."
        }

        Start-Sleep -Seconds 2

        Select-File-InOpenDialog -FilePath $CsvPath

        Start-Sleep -Seconds 3


        # ----------------------------------------------------
        # Discover devices
        # ----------------------------------------------------

        Write-Log "Step 10: Clicking Discover"

        Click-ByName `
            -SessionId $session `
            -Name "Discover" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Write-Log "Waiting $DiscoverWaitSeconds seconds for discovery..."
        Start-Sleep -Seconds $DiscoverWaitSeconds


        # ----------------------------------------------------
        # Select all discovered rows
        # ----------------------------------------------------

        Write-Log "Step 11: Selecting all discovered devices"

        $selectAllClicked = Click-FirstAvailable `
            -SessionId $session `
            -Selectors @(
                @{ Type = "name"; Value = "Press Space to toggle all rows selection (unchecked)" },
                @{ Type = "name"; Value = "Press Space to toggle all rows selection" },
                @{ Type = "xpath"; Value = "//*[contains(@Name,'toggle all rows selection')]" },
                @{ Type = "xpath"; Value = "//*[@ControlType='ControlType.CheckBox']" },
                @{ Type = "xpath"; Value = "//*[@ControlType='CheckBox']" }
            ) `
            -TimeoutSeconds 15

        if (-not $selectAllClicked) {
            throw "Could not click select-all checkbox."
        }

        Start-Sleep -Seconds 1

        Write-Log "Step 12: Clicking Next after device selection"

        Click-ByName `
            -SessionId $session `
            -Name "Next" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds 6


        # ----------------------------------------------------
        # Next page: click Next
        # ----------------------------------------------------

        Write-Log "Step 13: Clicking Next on next page"

        Click-ByName `
            -SessionId $session `
            -Name "Next" `
            -TimeoutSeconds $DefaultTimeoutSeconds

        Start-Sleep -Seconds 6


        # ----------------------------------------------------
        # Final page: Start
        # ----------------------------------------------------

        Write-Log "Step 14: Final Start page"

        if ($DryRunBeforeStart) {
            Write-Log "Dry run enabled. Stopping before clicking Start."

            Write-Host ""
            Write-Host "DryRunBeforeStart is enabled." -ForegroundColor Yellow
            Write-Host "The script stopped before clicking Start." -ForegroundColor Yellow
            Write-Host "Check the HP tool manually." -ForegroundColor Yellow
            Write-Host "If everything is correct, set:" -ForegroundColor Yellow
            Write-Host '$DryRunBeforeStart = $false' -ForegroundColor Cyan
            Write-Host ""
        }
        else {
            Write-Log "Clicking Start"

            Click-ByName `
                -SessionId $session `
                -Name "Start" `
                -TimeoutSeconds $DefaultTimeoutSeconds

            Write-Log "Clicked Start."
        }

        Write-Log "Automation completed."
    }
    finally {
        Remove-WadSession -SessionId $session
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}