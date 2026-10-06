# Discover-PrintixGateways.ps1
#
# This script parses printers_ranges.csv, pings potential default gateways (.254 and .1)
# for each subnet, and generates a new Printix Networks.csv based on the template.

$ScriptFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
$InputCsv = Join-Path $ScriptFolder "printers_ranges.csv"
$OutputCsv = Join-Path $ScriptFolder "Printix Networks.csv"

# Base template networks that must be preserved
$TemplateNetworks = @(
    [PSCustomObject]@{ name = "SDLNZ"; ip = "10.40.64.254"; mac = "00090f090003" },
    [PSCustomObject]@{ name = "SDLNZ"; ip = "10.8.16.1"; mac = "123456789abc" },
    [PSCustomObject]@{ name = "SDLNZ"; ip = "192.168.16.252"; mac = "7c5a1c4a1190" },
    [PSCustomObject]@{ name = "SDLBE"; ip = "10.0.62.254"; mac = "00090f090012" },
    [PSCustomObject]@{ name = "SDLBE"; ip = "10.0.7.254"; mac = "00090f090012" },
    [PSCustomObject]@{ name = "HRDOSO"; ip = "10.23.72.254"; mac = "00090f090003" }
)

# Standard template MAC addresses by prefix/name
$MacTemplates = @{
    "SDLBE" = "00090f090012"
    "SDLNZ" = "00090f090003"
    "HRDOSO" = "00090f090003"
}

# Load existing gateways to cache and speed up rerun
$CachedGateways = @{}
if (Test-Path $OutputCsv) {
    $ExistingNets = Import-Csv $OutputCsv -Delimiter ';'
    foreach ($Net in $ExistingNets) {
        if ($Net.ip -match '^(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}$') {
            $Subnet = $Matches[1]
            $CachedGateways[$Subnet] = $Net.ip
        }
    }
}

# Function to ping an IP
function Test-IpAddress {
    param ([string]$IP)
    Write-Host "Pinging $IP... " -NoNewline
    if (Test-Connection -ComputerName $IP -Count 1 -ErrorAction SilentlyContinue -Quiet) {
        Write-Host "SUCCESS" -ForegroundColor Green
        return $true
    } else {
        Write-Host "FAILED" -ForegroundColor Red
        return $false
    }
}

# Load ranges
if (-not (Test-Path $InputCsv)) {
    Write-Error "Could not find input file printers_ranges.csv at $InputCsv"
    exit
}

$Ranges = Import-Csv $InputCsv

$NewNetworks = [System.Collections.Generic.List[PSCustomObject]]::new()

# Track subnets we've already processed to avoid duplicate pings
$ProcessedSubnets = @{}

foreach ($Range in $Ranges) {
    $StartIP = $Range.start_ip
    $EndIP = $Range.end_ip
    $Description = $Range.description

    # Get the first token, remove any numbers and whitespace
    $Token = $Description.Split(',')[0].Trim()
    $NetworkName = $Token -replace '\d', ''
    
    # If the resulting network name is empty or too short (e.g. less than 3 chars like "P5"), try subsequent tokens
    if ($NetworkName.Length -lt 3) {
        foreach ($item in $Description.Split(',')) {
            $candidate = $item.Trim() -replace '\d', ''
            if ($candidate.Length -ge 3) {
                $NetworkName = $candidate
                break
            }
        }
    }

    # Extract octets of start and end IPs
    if ($StartIP -match '^(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}$') {
        $SubnetPrefixStart = $Matches[1]
    } else {
        continue
    }

    if ($EndIP -match '^(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}$') {
        $SubnetPrefixEnd = $Matches[1]
    } else {
        $SubnetPrefixEnd = $SubnetPrefixStart
    }

    # Get start and end third octets to handle ranges spanning multiple /24s
    $StartOctets = $StartIP.Split('.')
    $EndOctets = $EndIP.Split('.')
    
    $StartThird = [int]$StartOctets[2]
    $EndThird = [int]$EndOctets[2]
    $BasePrefix = "$($StartOctets[0]).$($StartOctets[1])"

    for ($i = $StartThird; $i -le $EndThird; $i++) {
        $CurrentSubnet = "$BasePrefix.$i"
        
        if ($ProcessedSubnets.ContainsKey($CurrentSubnet)) {
            continue
        }
        $ProcessedSubnets[$CurrentSubnet] = $true

        Write-Host "`nProcessing Subnet: $CurrentSubnet.0/24 ($Token)" -ForegroundColor Cyan
        
        # Test candidate gateways
        $Gateway254 = "$CurrentSubnet.254"
        $Gateway1 = "$CurrentSubnet.1"
        $ActiveGateway = ""

        if ($CachedGateways.ContainsKey($CurrentSubnet)) {
            $ActiveGateway = $CachedGateways[$CurrentSubnet]
            Write-Host "Using cached gateway: $ActiveGateway" -ForegroundColor Green
        } elseif (Test-IpAddress $Gateway254) {
            $ActiveGateway = $Gateway254
        } elseif (Test-IpAddress $Gateway1) {
            $ActiveGateway = $Gateway1
        } else {
            # Fallback to .254 as default if neither responds
            Write-Host "No gateway responded. Falling back to default .254" -ForegroundColor Yellow
            $ActiveGateway = $Gateway254
        }

        # Resolve MAC address based on country prefix of the Network Name
        $CountryPrefix = $NetworkName.Substring(0, [System.Math]::Min(2, $NetworkName.Length)).ToUpper()
        $MacAddress = "*"
        if ($CountryPrefix -eq "BE") {
            $MacAddress = "00090f090012"
        } elseif ($CountryPrefix -eq "NZ" -or $CountryPrefix -eq "HR") {
            $MacAddress = "00090f090003"
        }

        # Add to our list
        $NewNetworks.Add([PSCustomObject]@{
            name = $NetworkName
            ip   = $ActiveGateway
            mac  = $MacAddress
        })
    }
}

# Merge with existing template networks, avoiding duplicates on name + ip
$MergedNetworks = [System.Collections.Generic.List[PSCustomObject]]::new()
$UniqueKeys = @{}

# Add template networks first to preserve them
foreach ($Net in $TemplateNetworks) {
    $Key = "$($Net.name)_$($Net.ip)"
    if (-not $UniqueKeys.ContainsKey($Key)) {
        $UniqueKeys[$Key] = $true
        $MergedNetworks.Add($Net)
    }
}

# Add newly discovered networks
foreach ($Net in $NewNetworks) {
    $Key = "$($Net.name)_$($Net.ip)"
    if (-not $UniqueKeys.ContainsKey($Key)) {
        $UniqueKeys[$Key] = $true
        $MergedNetworks.Add($Net)
    }
}

# Write out the results
$MergedNetworks | Export-Csv -Path $OutputCsv -Delimiter ';' -NoTypeInformation -Force

Write-Host "`nFinished! Generated networks written to $OutputCsv" -ForegroundColor Green
Write-Host "Total networks: $($MergedNetworks.Count)" -ForegroundColor Green
