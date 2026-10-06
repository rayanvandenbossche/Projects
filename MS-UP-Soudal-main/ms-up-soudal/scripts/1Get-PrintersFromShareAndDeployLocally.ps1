# ============================================================
# Universal Print Connector Printer Migration Script
#
# Removes shared printer connections from \\laserprinters
# Recreates them as local TCP/IP printers
# Uses original printer/share name only
# Sets printer location based on site-codes.csv
# Adds printers in parallel, 4 at a time
# Skips printers already correctly added
# ============================================================

# -------------------------------
# Configuration
# -------------------------------

$PrintServer = "laserprinters"
$PrintServerUNC = "\\$PrintServer"

# Change this path if needed
$SiteCsvPath = "$PSScriptRoot\site-codes.csv"

# Number of printers to process at the same time
$ThrottleLimit = 4

Write-Host "Starting printer migration from $PrintServerUNC to local queues..." -ForegroundColor Cyan
Write-Host "Parallel throttle limit: $ThrottleLimit" -ForegroundColor Cyan


# -------------------------------
# Step 0: Import site-code CSV
# -------------------------------

if (-not (Test-Path $SiteCsvPath)) {
    Write-Host "CSV file not found: $SiteCsvPath" -ForegroundColor Red
    Write-Host "Place site-codes.csv in this location or update `$SiteCsvPath." -ForegroundColor Yellow
    exit 1
}

try {
    $SiteCodes = Import-Csv -Path $SiteCsvPath -Delimiter "|" -ErrorAction Stop
}
catch {
    Write-Host "Failed to import CSV file: $SiteCsvPath" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

$FirstRow = $SiteCodes | Select-Object -First 1

if (-not $FirstRow) {
    Write-Host "CSV file is empty: $SiteCsvPath" -ForegroundColor Red
    exit 1
}

if (-not ($FirstRow.PSObject.Properties.Name -contains "Location")) {
    Write-Host "CSV is missing required column: Location" -ForegroundColor Red
    exit 1
}

if (-not ($FirstRow.PSObject.Properties.Name -contains "Site Code")) {
    Write-Host "CSV is missing required column: Site Code" -ForegroundColor Red
    exit 1
}

# Build lookup table: Site Code -> Location
$SiteLookup = @{}

foreach ($Row in $SiteCodes) {
    $Code = $Row.'Site Code'
    $Location = $Row.Location

    if (-not [string]::IsNullOrWhiteSpace($Code) -and -not [string]::IsNullOrWhiteSpace($Location)) {
        $SiteLookup[$Code.Trim().ToUpper()] = $Location.Trim()
    }
}

Write-Host "Loaded $($SiteLookup.Count) site-code mappings from CSV." -ForegroundColor Green


# -------------------------------
# Step 1: Remove old network/shared printer connections from laserprinters
# -------------------------------

Write-Host "`nChecking for existing printer connections from $PrintServerUNC..." -ForegroundColor Cyan

try {
    $NetworkPrinters = Get-CimInstance Win32_Printer | Where-Object {
        $_.Network -eq $true -and (
            $_.ServerName -ieq $PrintServerUNC -or
            $_.Name -like "$PrintServerUNC*"
        )
    }

    if ($NetworkPrinters) {
        foreach ($Conn in $NetworkPrinters) {
            try {
                Write-Host "Removing network connection: $($Conn.Name)" -ForegroundColor Yellow
                Remove-Printer -Name $Conn.Name -ErrorAction Stop
                Write-Host "Removed: $($Conn.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove connection: $($Conn.Name)" -ForegroundColor Red
                Write-Host $_.Exception.Message
            }
        }
    }
    else {
        Write-Host "No existing network printer connections found from $PrintServerUNC." -ForegroundColor Green
    }
}
catch {
    Write-Host "Failed while checking/removing network printer connections." -ForegroundColor Red
    Write-Host $_.Exception.Message
}


# -------------------------------
# Step 2: Read printers and ports from print server
# -------------------------------

Write-Host "`nReading printers and ports from $PrintServer..." -ForegroundColor Cyan

try {
    $RemotePrinters = Get-Printer -ComputerName $PrintServer -ErrorAction Stop
    $RemotePorts = Get-PrinterPort -ComputerName $PrintServer -ErrorAction Stop
}
catch {
    Write-Host "Failed to read printers or ports from $PrintServer." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}

Write-Host "Found $($RemotePrinters.Count) printers on $PrintServer." -ForegroundColor Green


# -------------------------------
# Step 3: Build printer task list
# -------------------------------

$PrinterTasks = @()

foreach ($Printer in $RemotePrinters) {

    $RemotePort = $RemotePorts | Where-Object {
        $_.Name -eq $Printer.PortName
    } | Select-Object -First 1

    if (-not $RemotePort) {
        Write-Host "Skipping $($Printer.Name): remote port '$($Printer.PortName)' not found." -ForegroundColor Yellow
        continue
    }

    if ([string]::IsNullOrWhiteSpace($RemotePort.PrinterHostAddress)) {
        Write-Host "Skipping $($Printer.Name): port '$($Printer.PortName)' has no PrinterHostAddress." -ForegroundColor Yellow
        continue
    }

    $PrinterTasks += [PSCustomObject]@{
        Name        = $Printer.Name
        DriverName  = $Printer.DriverName
        RemotePort  = $Printer.PortName
        IPAddress   = $RemotePort.PrinterHostAddress
        LocalPort   = "IP_$($RemotePort.PrinterHostAddress)"
    }
}

Write-Host "Prepared $($PrinterTasks.Count) printer tasks." -ForegroundColor Green


# -------------------------------
# Step 4: Process printers in parallel
# -------------------------------

$Jobs = @()

foreach ($Task in $PrinterTasks) {

    while (($Jobs | Where-Object { $_.State -eq "Running" }).Count -ge $ThrottleLimit) {
        $FinishedJob = Wait-Job -Job $Jobs -Any -Timeout 5

        if ($FinishedJob) {
            Receive-Job -Job $FinishedJob
            Remove-Job -Job $FinishedJob
            $Jobs = $Jobs | Where-Object { $_.Id -ne $FinishedJob.Id }
        }
    }

    $Jobs += Start-Job -ArgumentList $Task, $SiteLookup -ScriptBlock {

        param (
            $Task,
            $SiteLookup
        )

        $LocalPrinterName = $Task.Name
        $DriverName = $Task.DriverName
        $LocalPortName = $Task.LocalPort
        $IPAddress = $Task.IPAddress

        Write-Output "`nProcessing printer: $LocalPrinterName"

        # Determine site code from printer name
        # Example: BETUSO5_PRO_AE511 -> BETUSO5
        if ($LocalPrinterName -like "*_*") {
            $SiteCode = ($LocalPrinterName.Split("_")[0]).Trim().ToUpper()
        }
        else {
            $SiteCode = $LocalPrinterName.Trim().ToUpper()
        }

        if ($SiteLookup.ContainsKey($SiteCode)) {
            $PrinterLocation = $SiteLookup[$SiteCode]
            Write-Output "Detected site code: $SiteCode -> $PrinterLocation"
        }
        else {
            $PrinterLocation = ""
            Write-Output "No CSV location found for site code: $SiteCode. Leaving location empty."
        }

        # Check if required driver exists locally
        $LocalDriver = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue

        if (-not $LocalDriver) {
            Write-Output "SKIPPED: $LocalPrinterName - driver not installed locally: $DriverName"
            return
        }

        # Check if printer already exists
        $ExistingPrinter = Get-Printer -Name $LocalPrinterName -ErrorAction SilentlyContinue

        if ($ExistingPrinter) {

            $AlreadyCorrect =
                $ExistingPrinter.Type -ne "Connection" -and
                $ExistingPrinter.PortName -eq $LocalPortName -and
                $ExistingPrinter.DriverName -eq $DriverName

            if ($AlreadyCorrect) {
                try {
                    Set-Printer `
                        -Name $LocalPrinterName `
                        -Location $PrinterLocation `
                        -Comment "Site code: $SiteCode" `
                        -ErrorAction Stop

                    Write-Output "SKIPPED: $LocalPrinterName already exists with correct driver and port. Location updated."
                }
                catch {
                    Write-Output "WARNING: $LocalPrinterName already exists correctly, but location update failed: $($_.Exception.Message)"
                }

                return
            }
            else {
                try {
                    Write-Output "Existing printer found but not correct. Removing: $LocalPrinterName"
                    Write-Output "Current driver: $($ExistingPrinter.DriverName)"
                    Write-Output "Current port: $($ExistingPrinter.PortName)"
                    Write-Output "Expected driver: $DriverName"
                    Write-Output "Expected port: $LocalPortName"

                    Remove-Printer -Name $LocalPrinterName -ErrorAction Stop
                    Start-Sleep -Seconds 2
                }
                catch {
                    Write-Output "FAILED: Could not remove existing printer $LocalPrinterName - $($_.Exception.Message)"
                    return
                }
            }
        }

        # Create local TCP/IP port if missing
        if (-not (Get-PrinterPort -Name $LocalPortName -ErrorAction SilentlyContinue)) {
            try {
                Write-Output "Creating TCP/IP port: $LocalPortName -> $IPAddress"

                Add-PrinterPort `
                    -Name $LocalPortName `
                    -PrinterHostAddress $IPAddress `
                    -ErrorAction Stop

                Write-Output "Created port: $LocalPortName"
            }
            catch {
                # Another parallel job may have created the same port at the same time
                if (Get-PrinterPort -Name $LocalPortName -ErrorAction SilentlyContinue) {
                    Write-Output "Port already exists after retry/check: $LocalPortName"
                }
                else {
                    Write-Output "FAILED: Could not create port $LocalPortName - $($_.Exception.Message)"
                    return
                }
            }
        }
        else {
            Write-Output "Port already exists: $LocalPortName"
        }

        # Create local printer queue
        try {
            Write-Output "Creating local printer: $LocalPrinterName"

            Add-Printer `
                -Name $LocalPrinterName `
                -DriverName $DriverName `
                -PortName $LocalPortName `
                -ErrorAction Stop

            Set-Printer `
                -Name $LocalPrinterName `
                -Location $PrinterLocation `
                -Comment "Site code: $SiteCode" `
                -ErrorAction Stop

            if ([string]::IsNullOrWhiteSpace($PrinterLocation)) {
                Write-Output "SUCCESS: Created $LocalPrinterName. Location left empty."
            }
            else {
                Write-Output "SUCCESS: Created $LocalPrinterName. Location set to: $PrinterLocation"
            }
        }
        catch {
            Write-Output "FAILED: Could not create local printer $LocalPrinterName - $($_.Exception.Message)"
        }
    }
}

# Wait for remaining jobs
Write-Host "`nWaiting for remaining printer jobs to finish..." -ForegroundColor Cyan

while ($Jobs.Count -gt 0) {
    $FinishedJob = Wait-Job -Job $Jobs -Any

    if ($FinishedJob) {
        Receive-Job -Job $FinishedJob
        Remove-Job -Job $FinishedJob
        $Jobs = $Jobs | Where-Object { $_.Id -ne $FinishedJob.Id }
    }
}


# -------------------------------
# Step 5: Restart services
# -------------------------------

Write-Host "`nRestarting Print Spooler..." -ForegroundColor Cyan

try {
    Restart-Service Spooler -Force -ErrorAction Stop
    Write-Host "Print Spooler restarted." -ForegroundColor Green
}
catch {
    Write-Host "Failed to restart Print Spooler." -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "Restarting Universal Print Connector service..." -ForegroundColor Cyan

try {
    Restart-Service PrintConnectorSvc -ErrorAction Stop
    Write-Host "Universal Print Connector service restarted." -ForegroundColor Green
}
catch {
    Write-Host "Could not restart PrintConnectorSvc. It may not exist or may have another service name." -ForegroundColor Yellow
}


# -------------------------------
# Step 6: Verification
# -------------------------------

Write-Host "`nMigration complete." -ForegroundColor Green
Write-Host "Printer verification:" -ForegroundColor Cyan

$TaskNames = $PrinterTasks.Name

Get-Printer |
    Where-Object {
        $_.Name -in $TaskNames
    } |
    Select-Object Name, Type, PortName, DriverName, Location, Comment |
    Format-Table -AutoSize

Write-Host "`nOpen the Universal Print Connector app and check if the local printers are visible." -ForegroundColor Green