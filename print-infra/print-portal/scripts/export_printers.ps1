$ErrorActionPreference = "SilentlyContinue"
$Servers = @("printers", "laserprinters")
$PortalRoot = Split-Path $PSScriptRoot -Parent
$OutputPath = Join-Path $PortalRoot "tmp\all_printers_consolidated.csv"

$results = New-Object System.Collections.Generic.List[PSCustomObject]

foreach ($Server in $Servers) {
    Write-Host "Fetching data from $Server..."
    
    $ports = Get-PrinterPort -ComputerName $Server | Select-Object Name, PrinterHostAddress
    $printers = Get-Printer -ComputerName $Server | Select-Object Name, ShareName, PortName, DriverName

    foreach ($printer in $printers) {
        $portName = $printer.PortName
        $port = $ports | Where-Object { $_.Name -eq $portName } | Select-Object -First 1
        
        $rawIp = ""
        if ($port -and $port.PrinterHostAddress) {
            $rawIp = $port.PrinterHostAddress
        } else {
            $rawIp = $portName
        }
        
        # Prettify IP: Remove leading zeros from octets
        $prettyIp = $rawIp
        if ($rawIp -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})') {
            $foundIp = $matches[1]
            try {
                $cleanedIp = ($foundIp -split '\.' | ForEach-Object { [int]$_ }) -join '.'
                $prettyIp = $rawIp -replace [regex]::Escape($foundIp), $cleanedIp
            } catch {
                $prettyIp = $rawIp
            }
        }

        $obj = [PSCustomObject]@{
            Server     = $Server
            ShareName  = if ($printer.ShareName) { $printer.ShareName } else { $printer.Name }
            IPAddress  = $prettyIp
        }
        $results.Add($obj)
    }
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation
$results | Select-Object -First 50 | Format-Table
Write-Host "Done. Exported $($results.Count) printers to $OutputPath"
