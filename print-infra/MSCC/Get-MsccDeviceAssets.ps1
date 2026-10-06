[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BearerToken,

    [Parameter(Mandatory = $false)]
    [string]$OutDir = ".\out",

    [Parameter(Mandatory = $false)]
    [int]$InitialDownloadWaitSeconds = 60,

    [Parameter(Mandatory = $false)]
    [int]$PollSeconds = 60,

    [Parameter(Mandatory = $false)]
    [int]$TimeoutMinutes = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Sanitize-FileName {
    param([string]$Name)
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalidChars) {
        $Name = $Name.Replace($char, "_")
    }
    return $Name.Trim()
}

Ensure-Directory -Path $OutDir

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36 Edg/148.0.0.0"

$headers = @{
    "Accept" = "application/json, text/plain, */*"
    "Authorization" = "Bearer $BearerToken"
    "Origin" = "https://mscc.ext.hp.com"
    "Referer" = "https://mscc.ext.hp.com/"
}

$customers = @(
    [pscustomobject]@{ Name = "SOUDAL FRENCKEN BV"; ReportCustomerId = "b45adf1d69b646018dbf928c6e602b2f" },
    [pscustomobject]@{ Name = "SOUDAL NV"; ReportCustomerId = "4b22e24442f24b07afe450cfa8a8cadb" },
    [pscustomobject]@{ Name = "SOUDAL NV (0002102830)"; ReportCustomerId = "243eac80ccb811ee9fecef0d54ff81a0" },
    [pscustomobject]@{ Name = "Soudal Denmark"; ReportCustomerId = "37955fe0b32a11f0b354872f394a909b" },
    [pscustomobject]@{ Name = "Soudal RO"; ReportCustomerId = "4e76659dcfdb4e4b9c76aade2d526a8b" }
)

$results = New-Object System.Collections.Generic.List[object]
$queuedReports = New-Object System.Collections.Generic.List[object]

Write-Host "Starting HP MSCC Device Asset export..." -ForegroundColor Cyan

foreach ($customer in $customers) {
    Write-Host "============================================================" -ForegroundColor DarkGray
    Write-Host "Queueing customer: $($customer.Name) ($($customer.ReportCustomerId))" -ForegroundColor Yellow

    try {
        # Switch context
        $switchUri = "https://print.services.api.hp.com/ms-dcc/svc/ms-dcc/update/msccSession?businessModel=MPS&asset=MSCC"
        $switchBody = @{
            businessModel = "MPS"
            switchCogId = $customer.ReportCustomerId
            type = "switchCustomer"
        } | ConvertTo-Json -Depth 5 -Compress

        Invoke-RestMethod -Uri $switchUri -Method Put -WebSession $session -Headers $headers -ContentType "application/json" -Body $switchBody | Out-Null
        Write-Host "Customer context changed." -ForegroundColor Green
        Start-Sleep -Seconds 5

        # Queue report
        $queueUri = "https://print.services.api.hp.com/ms-dcc/svc/dcc-reports/generateReports?asset=MSCC&businessModel=MPS"
        $queueBody = @{
            requestOrigin = "mscc"
            report_name = "deviceAsset"
            cog_id = $customer.ReportCustomerId
            cog_name = $customer.Name
            locale = "en-US"
            customerSourseSystem = "ITSM"
            partner_id = ""
            partner_name = ""
            is_partner_report = $false
            emailAddresses = ""
            internal_partner_report = $false
            InvoicePeriod = "Invalid date"
            billing_from_date = "Invalid date"
            billing_to_date = "Invalid date"
            isSftpEnabled = $false
            sftpDetails = $null
            reseller_partner_ids = @()
        } | ConvertTo-Json -Depth 5 -Compress

        $queueResponse = Invoke-RestMethod -Uri $queueUri -Method Post -WebSession $session -Headers $headers -ContentType "application/json" -Body $queueBody
        
        $reportId = $queueResponse.reportId
        
        if (-not $reportId -or $queueResponse.success -ne $true) {
            Write-Host "Warning: Could not determine reportId or queue failed (Status: $($queueResponse.Status))." -ForegroundColor Yellow
        } else {
            Write-Host "Report queued successfully ($($queueResponse.Status)). ID: $reportId" -ForegroundColor Green
            $queuedReports.Add([pscustomobject]@{
                CustomerName = $customer.Name
                ReportCustomerId = $customer.ReportCustomerId
                ReportId = $reportId
                ReportName = "$($customer.Name) Device Asset"
                Deadline = (Get-Date).AddMinutes($TimeoutMinutes)
                Attempts = 0
            }) | Out-Null
        }
    } catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($queuedReports.Count -gt 0) {
    Write-Host "Waiting $InitialDownloadWaitSeconds seconds before first polling round..." -ForegroundColor Gray
    Start-Sleep -Seconds $InitialDownloadWaitSeconds

    $pendingReports = @($queuedReports.ToArray())
    
    while ($pendingReports.Count -gt 0) {
        $nextPending = @()

        foreach ($report in $pendingReports) {
            if ((Get-Date) -ge $report.Deadline) {
                Write-Host "Timed out: $($report.CustomerName)" -ForegroundColor Red
                continue
            }

            try {
                $encodedName = [System.Uri]::EscapeDataString($report.ReportName)
                $downloadUri = "https://print.services.api.hp.com/ms-dcc/svc/dcc-notifications/downloadReport?reportId=$($report.ReportId)&reportName=$encodedName"
                
                $downloadResponse = Invoke-RestMethod -Uri $downloadUri -Method Get -WebSession $session -Headers $headers

                if ($downloadResponse.presignedUrl -and $downloadResponse.presignedUrl.downloadUrl) {
                    $downloadUrl = $downloadResponse.presignedUrl.downloadUrl
                    $filePath = Join-Path $OutDir "$(Sanitize-FileName $report.ReportName).xlsx"

                    Write-Host "Downloading: $($report.CustomerName) to $filePath" -ForegroundColor Gray
                    
                    # Direct download from S3 does not need the HP Authorization headers.
                    # We pass a clean session to avoid CORS / 400 Bad Request issues from AWS S3.
                    $cleanSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                    $cleanSession.UserAgent = $session.UserAgent
                    Invoke-WebRequest -Uri $downloadUrl -WebSession $cleanSession -OutFile $filePath -UseBasicParsing | Out-Null
                    Write-Host "Downloaded successfully: $($report.CustomerName)" -ForegroundColor Green
                } else {
                    $nextPending += $report
                }
            } catch {
                Write-Host "Report not ready yet for $($report.CustomerName)." -ForegroundColor DarkGray
                $nextPending += $report
            }
        }

        $pendingReports = @($nextPending)

        if ($pendingReports.Count -gt 0) {
            Start-Sleep -Seconds $PollSeconds
        }
    }
}

Write-Host "Finished downloading MSCC Device Assets." -ForegroundColor Cyan
