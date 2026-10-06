[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string[]]$PrinterIpAddress,
    [string]$PrinterListPath,
    [string]$FirmwareSourceUrl,
    [string]$FirmwareDownloadUrl,
    [string]$FirmwareFilePath,
    [int]$Port = 9100,
    [int]$ConnectTimeoutMs = 5000,
    [int]$WriteTimeoutMs = 30000,
    [string]$WorkingDirectory = (Join-Path $PSScriptRoot 'firmware-cache'),
    [switch]$KeepDownloadedFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$HpDriverDetailsUrl = 'https://support.hp.com/wcc-services/swd-v2/driverDetails?authState=anonymous&template=SWDSeriesDownload'
$HpDefaults = @{
    productLineCode = 'PQ'
    cc = 'be'
    lc = 'nl'
    osName = 'Platformonafhankelijk'
    osTMSId = '235165858596549875999935869912922'
    platformId = '327532471036162590669513151962475'
}

function Get-PrinterTargets {
    $targets = New-Object System.Collections.Generic.List[string]

    if ($PrinterIpAddress) {
        foreach ($item in $PrinterIpAddress) {
            if (-not [string]::IsNullOrWhiteSpace($item)) {
                $targets.Add($item.Trim())
            }
        }
    }

    if ($PrinterListPath) {
        if (-not (Test-Path -LiteralPath $PrinterListPath)) {
            throw "Printer list file not found: $PrinterListPath"
        }

        foreach ($line in Get-Content -LiteralPath $PrinterListPath) {
            $trimmed = $line.Trim()
            if ($trimmed.Length -gt 0 -and -not $trimmed.StartsWith('#')) {
                $targets.Add($trimmed)
            }
        }
    }

    $uniqueTargets = $targets | Sort-Object -Unique
    if (-not $uniqueTargets -or $uniqueTargets.Count -eq 0) {
        throw 'Provide at least one printer IP address via -PrinterIpAddress or -PrinterListPath.'
    }

    return $uniqueTargets
}

function Get-ProductSeriesOidFromUrl {
    param([string]$SourceUrl)

    if ([string]::IsNullOrWhiteSpace($SourceUrl)) {
        return $null
    }

    try {
        $uri = [Uri]$SourceUrl
        foreach ($segment in ($uri.AbsolutePath -split '/' | Where-Object { $_ })) {
            if ($segment -match '^\d+$') {
                return [int]$segment
            }
        }
    } catch {
    }

    if ($SourceUrl -match '/(\d+)(?:[/?#]|$)') {
        return [int]$Matches[1]
    }

    return $null
}

function Resolve-HpFirmwareDownload {
    param([string]$SourceUrl)

    $productSeriesOid = Get-ProductSeriesOidFromUrl -SourceUrl $SourceUrl
    if (-not $productSeriesOid) {
        throw "Could not derive the HP product series id from source URL: $SourceUrl"
    }

    $payload = @{
        productLineCode = $HpDefaults.productLineCode
        lc = $HpDefaults.lc
        cc = $HpDefaults.cc
        osTMSId = $HpDefaults.osTMSId
        osName = $HpDefaults.osName
        productSeriesOid = $productSeriesOid
        platformId = $HpDefaults.platformId
    }

    $headers = @{
        accept = 'application/json, text/plain, */*'
        'content-type' = 'application/json'
        'accept-language' = "$($HpDefaults.lc)-$($HpDefaults.cc.ToUpper()),$($HpDefaults.lc);q=0.9,en-US;q=0.8,en;q=0.7"
        'user-agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
        referer = $SourceUrl
    }

    $response = Invoke-RestMethod -Method Post -Uri $HpDriverDetailsUrl -Headers $headers -Body ($payload | ConvertTo-Json -Compress)

    $candidates = New-Object System.Collections.Generic.List[object]
    foreach ($softwareType in @($response.data.softwareTypes)) {
        foreach ($driverEntry in @($softwareType.softwareDriversList)) {
            $latest = $driverEntry.latestVersionDriver
            if (-not $latest) {
                continue
            }

            $title = [string]$latest.title
            if ([string]::IsNullOrWhiteSpace($title)) {
                continue
            }

            $fileFromList = $latest.productSoftwareFileList | Select-Object -First 1
            $fileName = $fileFromList.fileName
            if ([string]::IsNullOrWhiteSpace($fileName)) {
                $fileName = $latest.fileName
            }

            $downloadUrl = $fileFromList.fileUrl
            if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
                $downloadUrl = $latest.fileUrl
            }

            if ([string]::IsNullOrWhiteSpace($downloadUrl)) {
                continue
            }

            $candidates.Add([pscustomobject]@{
                Title = $title
                Version = [string]$latest.version
                DownloadUrl = [string]$downloadUrl
                FileName = [string]$fileName
                FileSize = [string]$latest.fileSize
            })
        }
    }

    if ($candidates.Count -eq 0) {
        throw "No downloadable firmware candidates were found for source URL: $SourceUrl"
    }

    $preferred = $candidates | Where-Object { $_.FileName -match '\.bdl$' } | Select-Object -First 1
    if (-not $preferred) {
        $preferred = $candidates | Where-Object { $_.FileName -match '\.zip$' } | Select-Object -First 1
    }
    if (-not $preferred) {
        $preferred = $candidates | Select-Object -First 1
    }

    return [pscustomobject]@{
        SourceUrl = $SourceUrl
        Title = $preferred.Title
        Version = $preferred.Version
        DownloadUrl = $preferred.DownloadUrl
        FileName = $preferred.FileName
        FileSize = $preferred.FileSize
    }
}

function Get-DownloadFileName {
    param(
        [string]$DownloadUrl,
        [string]$FallbackName
    )

    if (-not [string]::IsNullOrWhiteSpace($FallbackName)) {
        return $FallbackName
    }

    try {
        $uri = [Uri]$DownloadUrl
        $name = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        if (-not [string]::IsNullOrWhiteSpace($name)) {
            return $name
        }
    } catch {
    }

    return ([guid]::NewGuid().ToString('N') + '.bin')
}

function Get-BdlFilePath {
    param(
        [string]$SourceUrl,
        [string]$DownloadUrl,
        [string]$LocalFilePath
    )

    New-Item -ItemType Directory -Force -Path $WorkingDirectory | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($LocalFilePath)) {
        $resolved = Resolve-Path -LiteralPath $LocalFilePath
        if ($resolved.Path -notmatch '\.bdl$') {
            throw "The local firmware file must be a .bdl file: $($resolved.Path)"
        }

        return $resolved.Path
    }

    if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
        if ([string]::IsNullOrWhiteSpace($SourceUrl)) {
            throw 'Provide either -FirmwareFilePath, -FirmwareDownloadUrl, or -FirmwareSourceUrl.'
        }

        $resolvedSource = Resolve-HpFirmwareDownload -SourceUrl $SourceUrl
        $DownloadUrl = $resolvedSource.DownloadUrl
        if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
            throw "HP source did not resolve to a download URL: $SourceUrl"
        }

        if ([string]::IsNullOrWhiteSpace($resolvedSource.FileName)) {
            $resolvedSource = [pscustomobject]@{
                FileName = Get-DownloadFileName -DownloadUrl $DownloadUrl -FallbackName $null
            }
        }
    }

    $resolvedDownloadName = $null
    if (-not [string]::IsNullOrWhiteSpace($SourceUrl)) {
        $resolvedSource = Resolve-HpFirmwareDownload -SourceUrl $SourceUrl
        $resolvedDownloadName = $resolvedSource.FileName
    }

    $downloadFileName = Get-DownloadFileName -DownloadUrl $DownloadUrl -FallbackName $resolvedDownloadName
    $downloadPath = Join-Path $WorkingDirectory $downloadFileName

    Invoke-WebRequest -Uri $DownloadUrl -OutFile $downloadPath

    if ($downloadPath -match '\.zip$') {
        $extractPath = Join-Path $WorkingDirectory ("extract-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
        Expand-Archive -LiteralPath $downloadPath -DestinationPath $extractPath -Force

        $bdlFile = Get-ChildItem -LiteralPath $extractPath -Recurse -File -Filter '*.bdl' | Sort-Object Length -Descending | Select-Object -First 1
        if (-not $bdlFile) {
            throw "Downloaded archive did not contain a .bdl file: $DownloadUrl"
        }

        if (-not $KeepDownloadedFiles) {
            Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue
        }

        return $bdlFile.FullName
    }

    if ($downloadPath -notmatch '\.bdl$') {
        throw "Expected a .bdl firmware file, but downloaded: $downloadPath"
    }

    return $downloadPath
}

function Test-PrinterReachable {
    param(
        [string]$IpAddress,
        [int]$Port,
        [int]$TimeoutMs
    )

    if (Get-Command Test-NetConnection -ErrorAction SilentlyContinue) {
        try {
            return [bool](Test-NetConnection -ComputerName $IpAddress -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue)
        } catch {
        }
    }

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($IpAddress, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs)) {
            return $false
        }

        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
        $client.Dispose()
    }
}

function Send-FirmwareToPrinter {
    param(
        [string]$IpAddress,
        [string]$FirmwarePath,
        [int]$Port,
        [int]$ConnectTimeoutMs,
        [int]$WriteTimeoutMs
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    $networkStream = $null
    $fileStream = $null
    $buffer = New-Object byte[] 65536
    $bytesSent = 0L

    try {
        $async = $client.BeginConnect($IpAddress, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($ConnectTimeoutMs)) {
            throw "Connection timed out while connecting to ${IpAddress}:$Port"
        }

        $client.EndConnect($async)
        $client.SendTimeout = $WriteTimeoutMs
        $client.ReceiveTimeout = $WriteTimeoutMs

        $networkStream = $client.GetStream()
        $fileStream = [System.IO.File]::OpenRead($FirmwarePath)

        while (($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $networkStream.Write($buffer, 0, $bytesRead)
            $bytesSent += $bytesRead
        }

        $networkStream.Flush()

        return $bytesSent
    } finally {
        if ($fileStream) {
            $fileStream.Dispose()
        }

        if ($networkStream) {
            $networkStream.Dispose()
        }

        $client.Close()
        $client.Dispose()
    }
}

$printerTargets = Get-PrinterTargets
$firmwarePath = Get-BdlFilePath -SourceUrl $FirmwareSourceUrl -DownloadUrl $FirmwareDownloadUrl -LocalFilePath $FirmwareFilePath

$results = foreach ($printer in $printerTargets) {
    $reachable = $false
    $status = 'Skipped'
    $message = $null
    $bytesSent = 0L

    try {
        $reachable = Test-PrinterReachable -IpAddress $printer -Port $Port -TimeoutMs $ConnectTimeoutMs
        if (-not $reachable) {
            $status = 'Unreachable'
            $message = "Printer did not respond on TCP $Port."
            continue
        }

        if ($PSCmdlet.ShouldProcess($printer, "Push firmware file $firmwarePath")) {
            $bytesSent = Send-FirmwareToPrinter -IpAddress $printer -FirmwarePath $firmwarePath -Port $Port -ConnectTimeoutMs $ConnectTimeoutMs -WriteTimeoutMs $WriteTimeoutMs
            $status = 'Sent'
            $message = 'Firmware sent successfully.'
        } else {
            $status = 'WhatIf'
            $message = 'Dry-run requested.'
        }
    } catch {
        $status = 'Error'
        $message = $_.Exception.Message
    }

    [pscustomobject]@{
        PrinterIp = $printer
        Port = $Port
        Reachable = $reachable
        FirmwarePath = $firmwarePath
        Status = $status
        Message = $message
        BytesSent = $bytesSent
    }
}

$results