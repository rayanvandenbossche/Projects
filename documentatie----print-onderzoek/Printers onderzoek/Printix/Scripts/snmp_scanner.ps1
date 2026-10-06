# =============================================================
# Printix SNMP Printer Scanner - Soudal Global
# Scant alle wereldwijde IP-ranges parallel via SNMP
# Exporteert naar Printix Configurator CSV-formaat
# Gebruik: Powershell als Administrator > .\snmp_scanner.ps1
# =============================================================

# ---- INSTELLINGEN ----
$SnmpCommunity = "public"
$TimeoutMs = 800        # ms per IP (verhoog naar 1500 voor trage WAN-links)
$MaxThreads = 75         # Parallelle threads (verlaag naar 30 bij hoge CPU)
$OutputCsv = "$PSScriptRoot\printix_printers_import.csv"
$DefaultNetwork = "Network2" # Gebruikt voor ranges zonder naam

# ---- IP RANGES (worden ingeladen uit extern bestand) ----
$IPRangesPath = "$PSScriptRoot\ip_ranges.txt"

if (Test-Path $IPRangesPath) {
    Write-Host "Inladen van IP-ranges uit: $IPRangesPath" -ForegroundColor Cyan
    $RawRanges = Get-Content -Path $IPRangesPath
} else {
    Write-Error "FOUT: Kan $IPRangesPath niet vinden. Zorg dat dit bestand in dezelfde map staat als het script."
    exit
}

# ---- Hulpfuncties: IP <-> Integer ----
function ConvertTo-IpInt([string]$ip) {
    $parts = $ip.Split('.')
    return ([int]$parts[0] -shl 24) + ([int]$parts[1] -shl 16) + ([int]$parts[2] -shl 8) + [int]$parts[3]
}
function ConvertFrom-IpInt([int64]$n) {
    return "{0}.{1}.{2}.{3}" -f (($n -shr 24) -band 255), (($n -shr 16) -band 255), (($n -shr 8) -band 255), ($n -band 255)
}

# ---- Parseer alle ranges naar een lijst van {IP, Network} ----
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Printix SNMP Scanner - Soudal Global" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Ranges parseren..." -ForegroundColor Yellow

$ScanList = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($line in ($RawRanges -split "`n")) {
    $line = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    $networkName = $DefaultNetwork
    if ($line -match "=(.+)$") {
        $networkName = $matches[1].Trim()
        $line = $line -replace "=.+$", ""
    }

    $parts = $line.Split('-')
    $startIp = $parts[0].Trim()
    $endIp = $parts[1].Trim()

    $startInt = ConvertTo-IpInt $startIp
    $endInt = ConvertTo-IpInt $endIp

    for ($i = $startInt; $i -le $endInt; $i++) {
        $ScanList.Add([PSCustomObject]@{
                IP      = ConvertFrom-IpInt $i
                Network = $networkName
            })
    }
}

$total = $ScanList.Count
Write-Host "Totaal te scannen IPs: $total" -ForegroundColor Green
$estMin = [Math]::Round(($total / $MaxThreads * $TimeoutMs / 1000) / 60, 1)
Write-Host "Geschatte scantijd:    ~$estMin minuten ($MaxThreads threads)" -ForegroundColor Green
Write-Host ""
Write-Host "Scan gestart... (dit kan even duren)" -ForegroundColor Yellow
Write-Host ""

# ---- SNMP Scanner als ScriptBlock (draait in elke thread) ----
$ScanScript = {
    param($IP, $Community, $Timeout)

    function Get-SnmpString {
        param($IpAddress, $Community, $TimeoutMs)
        try {
            # Minimaal SNMPv1 GET voor sysDescr (OID 1.3.6.1.2.1.1.1.0)
            $pkt = [byte[]](
                0x30, 0x29, 0x02, 0x01, 0x00,
                0x04, 0x06, 0x70, 0x75, 0x62, 0x6c, 0x69, 0x63,  # community "public"
                0xa0, 0x1c, 0x02, 0x04, 0x00, 0x00, 0x00, 0x01,
                0x02, 0x01, 0x00, 0x02, 0x01, 0x00,
                0x30, 0x0e, 0x30, 0x0c, 0x06, 0x08,
                0x2b, 0x06, 0x01, 0x02, 0x01, 0x01, 0x01, 0x00,   # sysDescr OID
                0x05, 0x00
            )
            # Vervang community indien niet "public"
            if ($Community -ne "public") {
                $cb = [System.Text.Encoding]::ASCII.GetBytes($Community)
                $newPkt = [byte[]](0x30, 0x00, 0x02, 0x01, 0x00, 0x04, $cb.Length) + $cb + $pkt[13..$pkt.Length]
                $newPkt[1] = [byte]($newPkt.Length - 2)
                $pkt = $newPkt
            }

            $udp = New-Object System.Net.Sockets.UdpClient
            $udp.Client.ReceiveTimeout = $TimeoutMs
            $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($IpAddress), 161)
            $udp.Send($pkt, $pkt.Length, $ep) | Out-Null
            $resp = $udp.Receive([ref]$ep)
            $udp.Close()

            if ($resp -and $resp.Length -gt 20) {
                # Extraheer printbare ASCII uit het antwoord
                $str = [System.Text.Encoding]::ASCII.GetString($resp)
                $str = ($str -replace '[^\x20-\x7E]', '|').Split('|') |
                Where-Object { $_.Length -gt 3 } |
                Select-Object -Last 1
                return $str.Trim()
            }
        }
        catch { }
        return $null
    }

    function Get-SnmpMacAddress {
        param($IpAddress, $Community, $TimeoutMs)
        $udp = New-Object System.Net.Sockets.UdpClient
        $udp.Client.ReceiveTimeout = $TimeoutMs
        $ep  = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Parse($IpAddress), 161)
        
        for ($ifIndex = 1; $ifIndex -le 3; $ifIndex++) {
            try {
                $pkt = [byte[]](
                    0x30,0x2b,0x02,0x01,0x00,
                    0x04,0x06,0x70,0x75,0x62,0x6c,0x69,0x63,
                    0xa0,0x1e,0x02,0x04,0x00,0x00,0x00,0x02,
                    0x02,0x01,0x00,0x02,0x01,0x00,
                    0x30,0x10,0x30,0x0e,0x06,0x0a,
                    0x2b,0x06,0x01,0x02,0x01,0x02,0x02,0x01,0x06,[byte]$ifIndex,
                    0x05,0x00
                )
                if ($Community -ne "public") {
                    $cb = [System.Text.Encoding]::ASCII.GetBytes($Community)
                    $newPkt = [byte[]](0x30,0x00,0x02,0x01,0x00,0x04,$cb.Length) + $cb + $pkt[13..($pkt.Length-1)]
                    $newPkt[1] = [byte]($newPkt.Length - 2)
                    $pkt = $newPkt
                }
                $udp.Send($pkt, $pkt.Length, $ep) | Out-Null
                $resp = $udp.Receive([ref]$ep)

                if ($resp -and $resp.Length -ge 20) {
                    for ($j = $resp.Length - 8; $j -ge 20; $j--) {
                        if ($resp[$j] -eq 0x04 -and $resp[$j+1] -eq 0x06) {
                            $macBytes = $resp[($j+2)..($j+7)]
                            $macStr = ($macBytes | ForEach-Object { '{0:X2}' -f $_ }) -join ':'
                            if ($macStr -ne "00:00:00:00:00:00") {
                                $udp.Close()
                                return $macStr
                            }
                        }
                    }
                }
            } catch { }
        }
        $udp.Close()
        return $null
    }

    $desc = Get-SnmpString -IpAddress $IP -Community $Community -TimeoutMs $Timeout
    if ($desc) { 
        $mac = Get-SnmpMacAddress -IpAddress $IP -Community $Community -TimeoutMs $Timeout
        return [PSCustomObject]@{
            Model = $desc
            MAC   = $mac
        }
    } else { 
        return $null 
    }
}

# ---- Parallelle scanning via Runspaces ----
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()

$Jobs = [System.Collections.Generic.List[hashtable]]::new()
$Results = [System.Collections.Concurrent.ConcurrentBag[PSCustomObject]]::new()

$counter = 0
foreach ($entry in $ScanList) {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $RunspacePool
    $ps.AddScript($ScanScript).AddArgument($entry.IP).AddArgument($SnmpCommunity).AddArgument($TimeoutMs) | Out-Null

    $Jobs.Add(@{
            PS      = $ps
            Handle  = $ps.BeginInvoke()
            IP      = $entry.IP
            Network = $entry.Network
        })

    $counter++
    if ($counter % 500 -eq 0) {
        $pct = [int](($counter / $total) * 100)
        Write-Progress -Activity "SNMP Scan" -Status "Jobs aangemaakt: $countaer/$total ($pct%)" -PercentComplete $pct
    }
}

Write-Host "Alle $total scan-jobs gestart. Wachten op resultaten..." -ForegroundColor Yellow

# ---- Resultaten verzamelen ----
$done = 0
$found = 0
foreach ($job in $Jobs) {
    $rawResult = $job.PS.EndInvoke($job.Handle)
    $obj = if ($rawResult -and $rawResult.Count -gt 0) { $rawResult[0] } else { $null }
    $job.PS.Dispose()
    $done++

    if ($obj -and $obj.Model) {
        if ([string]::IsNullOrWhiteSpace($obj.MAC)) {
            Write-Host "  ⚠️ $($job.IP) [$($job.Network)] - HEEFT GEEN MAC (wordt overgeslagen)" -ForegroundColor Yellow
        } else {
            $found++
            $cleanModel = $obj.Model -replace '[^a-zA-Z0-9\- ]', ''
            
            # Printix controleert streng op lege velden; Vendor zelf invullen op basis van Model
            $vendorName = "Unknown"
            if ($cleanModel -match "(?i)HP|Hewlett") { $vendorName = "HP" }
            elseif ($cleanModel -match "(?i)RICOH") { $vendorName = "Ricoh" }
            elseif ($cleanModel -match "(?i)Zebra") { $vendorName = "Zebra" }
            elseif ($cleanModel -match "(?i)Canon") { $vendorName = "Canon" }
            elseif ($cleanModel -match "(?i)Brother") { $vendorName = "Brother" }
            elseif ($cleanModel -match "(?i)Lexmark") { $vendorName = "Lexmark" }
            elseif ($cleanModel -match "(?i)Konica") { $vendorName = "Konica Minolta" }
            elseif ($cleanModel -match "(?i)Epson") { $vendorName = "Epson" }
            elseif ($cleanModel -match "(?i)Xerox") { $vendorName = "Xerox" }
            elseif ($cleanModel -match "(?i)Siemens") { $vendorName = "Siemens" }
            elseif ($cleanModel -match "(?i)SATO") { $vendorName = "SATO" }
            
            # Printix configurator accepteert MAC adressen ook beter zonder dubbele punten
            $cleanMac = $obj.MAC -replace ':', ''
            
            # BYPASS VOOR PRINTIX CONFIGURATOR:
            # Omdat Printix de CSV weigert als een netwerknaam nog niet bestaat in de cloud portal,
            # dwingen we tijdelijk alles naar "Network2" (het enige bekende netwerk van de testserver).
            $netName = "Network2"

            $Results.Add([PSCustomObject]@{
                PrinterName  = "Printer-$($job.IP)"
                Vendor       = $vendorName
                Model        = $cleanModel
                Address      = $job.IP
                Network      = $netName
                MAC          = $cleanMac
                SerialNumber = ""
                PDL          = "PCL6"
            })
            Write-Host "  ✅ $($job.IP) [$($job.Network)] - MAC: $($obj.MAC) - $($obj.Model)" -ForegroundColor Green
        }
    }

    if ($done % 200 -eq 0) {
        $pct = [int](($done / $total) * 100)
        Write-Progress -Activity "Resultaten verwerken" `
            -Status "$done/$total verwerkt | $found printers gevonden ($pct%)" `
            -PercentComplete $pct
    }
}

$RunspacePool.Close()
$RunspacePool.Dispose()
Write-Progress -Activity "SNMP Scan" -Completed

# ---- Exporteer naar Printix CSV ----
Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Scan voltooid!" -ForegroundColor Cyan
Write-Host "   Gevonden printers: $found / $total IPs gescand" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

if ($Results.Count -gt 0) {
    $Results | Sort-Object Address -Unique |
    Select-Object PrinterName, Vendor, Model, Address, Network, MAC, SerialNumber, PDL |
    ConvertTo-Csv -Delimiter ";" -NoTypeInformation |
    ForEach-Object { $_ -replace '"', '' } |   # Printix wil geen aanhalingstekens
    Set-Content -Path $OutputCsv -Encoding UTF8

    Write-Host ""
    Write-Host "✅ CSV aangemaakt: $OutputCsv" -ForegroundColor Green
    Write-Host ""
    Write-Host "Volgende stap - Printix Configurator:" -ForegroundColor Yellow
    Write-Host "  1. Download 'Printix Configurator' via Admin-portal > Software" -ForegroundColor White
    Write-Host "  2. Log in als System Manager" -ForegroundColor White
    Write-Host "  3. Printers > Import > selecteer: $OutputCsv" -ForegroundColor White
    Write-Host "  4. Map kolommen > Upload to Printix Server" -ForegroundColor White
}
else {
    Write-Host ""
    Write-Host "⚠️  Geen printers gevonden. Mogelijke oorzaken:" -ForegroundColor Yellow
    Write-Host "  - Firewall blokkeert UDP poort 161 (SNMP) over WAN/VPN" -ForegroundColor White
    Write-Host "  - SNMP community is niet 'public' op de printers" -ForegroundColor White
    Write-Host "  - Verhoog TimeoutMs naar 1500 voor trage WAN-verbindingen" -ForegroundColor White
}
  