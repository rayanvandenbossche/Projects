# ============================================================================
# PRINTIX API AUTOMATISERING - COMPLETE IMPLEMENTATIE
# ============================================================================
# Doel: OAuth 2.0 authenticatie + Printer management automatisering
# 
# Vereisten:
# - PowerShell 7.0+ (bevat Invoke-RestMethod met -SkipCertificateCheck)
# - Geldige Printix credentials (Tenant ID, Client ID, Client Secret)
# - Netwerktoegang naar https://auth.printix.net en https://api.printix.net
#
# ============================================================================

#region CONFIGURATION
# ============================================================================
# STAP 0: Configuratie
# ============================================================================

# Hier kun je deze variabelen ook uit een config-bestand laden
$Config = @{
    TenantId     = "4b936403-d68c-420f-8746-4e8aa61acd96"
    ClientId     = "c2c22db3-8177-4945-b732-ab0908050a46"
    ClientSecret = "z1Mxt9oMu2ywDQUMDYUjcZlfRz8Zi6iw2Aj0OamvQEu3U9bG"
    AuthUrl      = "https://auth.printix.net/oauth2/token"
    ApiBaseUrl   = "https://api.printix.net/v1"
    LogPath      = "C:\Users\BosscheRy\.gemini\antigravity\scratch\docs-project\Scripts\Printix-API.log"
}

# Logging-functie
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [switch]$NoConsole
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
            default { Write-Host $logMessage }
        }
    }
    
    Add-Content -Path $Config.LogPath -Value $logMessage
}

#endregion

#region AUTHENTICATION
# ============================================================================
# STAP 1: OAuth 2.0 Authenticatie
# ============================================================================

function Get-PrintixAccessToken {
    <#
    .SYNOPSIS
    Haalt een Access Token op van de Printix OAuth Server
    
    .EXAMPLE
    $token = Get-PrintixAccessToken
    #>
    
    Write-Log "━━━ Stap 1: Access Token ophalen ━━━" -Level "INFO"
    
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $Config.ClientId
        client_secret = $Config.ClientSecret
        scope         = "https://api.printix.net/.default"
    }
    
    try {
        $params = @{
            Method               = "Post"
            Uri                  = $Config.AuthUrl
            ContentType          = "application/x-www-form-urlencoded"
            Body                 = $body
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $response = Invoke-RestMethod @params
        
        Write-Log "✓ Token opgehaald! Geldig voor: $($response.expires_in) seconden" -Level "SUCCESS"
        
        return $response.access_token
    }
    catch {
        Write-Log "✗ Fout bij token-aanvraag: $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

#endregion

#region PRINTER OPERATIONS
# ============================================================================
# STAP 2: Printer Operaties
# ============================================================================

function Get-PrintixPrinters {
    <#
    .SYNOPSIS
    Haalt alle printers op via de Printix API
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )
    
    Write-Log "━━━ Stap 2: Printerlijst ophalen ━━━" -Level "INFO"
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    try {
        $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/printers"
        
        $params = @{
            Method               = "Get"
            Uri                  = $uri
            Headers              = $headers
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $printers = Invoke-RestMethod @params
        
        Write-Log "✓ $($printers.Count) printers opgehaald" -Level "SUCCESS"
        
        return $printers
    }
    catch {
        Write-Log "✗ Fout bij het ophalen van printers: $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

function Update-PrinterName {
    <#
    .SYNOPSIS
    Werk de naam van een printer bij
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER PrinterId
    De ID van de printer die geupdate moet worden
    
    .PARAMETER NewName
    De nieuwe naam voor de printer
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string]$PrinterId,
        [Parameter(Mandatory = $true)] [string]$NewName
    )
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    try {
        $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/printers/$PrinterId"
        
        $body = @{
            name = $NewName
        } | ConvertTo-Json
        
        $params = @{
            Method               = "Patch"
            Uri                  = $uri
            Headers              = $headers
            Body                 = $body
            ContentType          = "application/json"
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $result = Invoke-RestMethod @params
        
        Write-Log "✓ Printer hernoemd: $PrinterId → $NewName" -Level "SUCCESS"
        
        return $result
    }
    catch {
        Write-Log "✗ Fout bij hername van printer $PrinterId : $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

function Add-PrinterTag {
    <#
    .SYNOPSIS
    Voeg een tag toe aan een printer
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string]$PrinterId,
        [Parameter(Mandatory = $true)] [string]$Tag
    )
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    try {
        $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/printers/$PrinterId"
        
        $body = @{
            tags = @($Tag)
        } | ConvertTo-Json
        
        $params = @{
            Method               = "Patch"
            Uri                  = $uri
            Headers              = $headers
            Body                 = $body
            ContentType          = "application/json"
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $result = Invoke-RestMethod @params
        
        Write-Log "✓ Tag toegevoegd: $PrinterId → $Tag" -Level "SUCCESS"
        
        return $result
    }
    catch {
        Write-Log "✗ Fout bij toevoegen tag: $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

function Get-PrintixNetworkByName {
    <#
    .SYNOPSIS
    Zoek een netwerk op naam
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER NetworkName
    De naam van het netwerk
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string]$NetworkName
    )
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    try {
        $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/networks"
        
        $params = @{
            Method               = "Get"
            Uri                  = $uri
            Headers              = $headers
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $networks = Invoke-RestMethod @params
        $network = $networks | Where-Object { $_.name -eq $NetworkName }
        
        if ($null -eq $network) {
            Write-Log "⚠ Netwerk '$NetworkName' niet gevonden" -Level "WARNING"
            return $null
        }
        
        Write-Log "✓ Netwerk gevonden: $NetworkName (ID: $($network.id))" -Level "SUCCESS"
        
        return $network
    }
    catch {
        Write-Log "✗ Fout bij zoeken netwerk: $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

function Add-PrintersToGroup {
    <#
    .SYNOPSIS
    Voeg printers toe aan een groep
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER PrinterIds
    Array van printer IDs om toe te voegen
    
    .PARAMETER GroupName
    De naam van de groep
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string[]]$PrinterIds,
        [Parameter(Mandatory = $true)] [string]$GroupName
    )
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    Write-Log "━━━ Printers toevoegen aan groep: $GroupName ━━━" -Level "INFO"
    
    $successCount = 0
    $failCount = 0
    
    foreach ($printerId in $PrinterIds) {
        try {
            $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/printers/$printerId"
            
            $body = @{
                groups = @($GroupName)
            } | ConvertTo-Json
            
            $params = @{
                Method               = "Patch"
                Uri                  = $uri
                Headers              = $headers
                Body                 = $body
                ContentType          = "application/json"
                SkipCertificateCheck = $true
                ErrorAction          = "Stop"
            }
            
            $result = Invoke-RestMethod @params
            
            Write-Log "✓ Printer $printerId toegevoegd aan $GroupName" -Level "SUCCESS"
            $successCount++
        }
        catch {
            Write-Log "✗ Fout: Printer $printerId - $($_.Exception.Message)" -Level "ERROR"
            $failCount++
        }
    }
    
    Write-Log "Totaal: $successCount geslaagd, $failCount mislukt" -Level "INFO"
}

function Remove-PrintixPrinter {
    <#
    .SYNOPSIS
    Verwijder een printer uit Printix
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER PrinterId
    De ID van de printer
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string]$PrinterId
    )
    
    $headers = @{
        Authorization = "Bearer $AccessToken"
    }
    
    try {
        $uri = "$($Config.ApiBaseUrl)/tenants/$($Config.TenantId)/printers/$PrinterId"
        
        $params = @{
            Method               = "Delete"
            Uri                  = $uri
            Headers              = $headers
            SkipCertificateCheck = $true
            ErrorAction          = "Stop"
        }
        
        $result = Invoke-RestMethod @params
        
        Write-Log "✓ Printer verwijderd: $PrinterId" -Level "SUCCESS"
        
        return $result
    }
    catch {
        Write-Log "✗ Fout bij verwijderen printer $PrinterId : $($_.Exception.Message)" -Level "ERROR"
        throw $_
    }
}

function Add-PrintersFromNetworkToGroup {
    <#
    .SYNOPSIS
    Voeg alle printers van een netwerk toe aan een groep
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER NetworkName
    De naam van het netwerk
    
    .PARAMETER GroupName
    De naam van de groep
    
    .PARAMETER DryRun
    Als $true, toon alleen wat zou gebeuren (geen wijzigingen)
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [string]$NetworkName,
        [Parameter(Mandatory = $true)] [string]$GroupName,
        [bool]$DryRun = $false
    )
    
    Write-Log "━━━ Printers van netwerk naar groep ━━━" -Level "INFO"
    
    # Stap 1: Zoek het netwerk
    $network = Get-PrintixNetworkByName -AccessToken $AccessToken -NetworkName $NetworkName
    
    if ($null -eq $network) {
        Write-Log "Operatie geannuleerd: netwerk niet gevonden" -Level "ERROR"
        return
    }
    
    # Stap 2: Haal alle printers op
    Write-Log "Informatie ophalen..." -Level "INFO"
    $printers = Get-PrintixPrinters -AccessToken $AccessToken
    
    # Stap 3: Filter printers op dit netwerk
    $targetPrinters = $printers | Where-Object { $_.networkId -eq $network.id }
    
    if ($targetPrinters.Count -eq 0) {
        Write-Log "Geen printers gevonden voor netwerk: $NetworkName" -Level "WARNING"
        return
    }
    
    Write-Log "Gevonden: $($targetPrinters.Count) printers in netwerk '$NetworkName'" -Level "INFO"
    Write-Host ""
    
    # Toon preview
    Write-Host "📋 PREVIEW - Printers die worden toegevoegd:" -ForegroundColor Yellow
    $targetPrinters | Select-Object -Property @(
        @{ Name = 'Naam'; Expression = { $_.name } },
        @{ Name = 'IP-Adres'; Expression = { $_.ipAddress } },
        @{ Name = 'Model'; Expression = { $_.model } }
    ) | Format-Table -AutoSize
    
    Write-Host ""
    
    if ($DryRun) {
        Write-Log "🔍 DRY-RUN MODE: Geen wijzigingen gemaakt" -Level "WARNING"
        return
    }
    
    # Stap 4: Voeg toe aan groep
    $printerIds = $targetPrinters | Select-Object -ExpandProperty id
    Add-PrintersToGroup -AccessToken $AccessToken -PrinterIds $printerIds -GroupName $GroupName
    
    Write-Log "✓ Operatie voltooid!" -Level "SUCCESS"
}

#endregion

#region DATA ANALYSIS
# ============================================================================
# STAP 3: Data-Analyse & Reporting
# ============================================================================

function Analyze-PrinterData {
    <#
    .SYNOPSIS
    Analyseer en rapporteer printer data
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Printers
    )
    
    Write-Log "━━━ Stap 3: Data-analyse ━━━" -Level "INFO"
    Write-Host ""
    
    # Overzicht
    Write-Host "📊 OVERZICHT" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "Totaal printers: $($Printers.Count)" -ForegroundColor White
    Write-Host "Online: $($Printers | Where-Object { $_.status -eq 'Online' } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Green
    Write-Host "Offline: $($Printers | Where-Object { $_.status -eq 'Offline' } | Measure-Object | Select-Object -ExpandProperty Count)" -ForegroundColor Red
    Write-Host ""
    
    # Details tabel
    Write-Host "📋 PRINTERDETAILS" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    $Printers | Select-Object -Property @(
        'id',
        'name',
        'ipAddress',
        'model',
        'status'
    ) | Format-Table -AutoSize
    
    Write-Host ""
    
    # Export naar CSV
    $csvPath = "$($Config.LogPath -replace '\.log$', '')-Printers-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $Printers | Select-Object id, name, ipAddress, model, status | Export-Csv -Path $csvPath -Encoding UTF8 -NoTypeInformation
    Write-Log "✓ Geëxporteerd naar: $csvPath" -Level "SUCCESS"
}

#endregion

#region AUTOMATION EXAMPLES
# ============================================================================
# STAP 4: Automatiseringsvoorbeelden
# ============================================================================

function Bulk-RenameBySubnet {
    <#
    .SYNOPSIS
    Hernoem alle printers op een specifiek subnet
    
    .PARAMETER AccessToken
    Het OAuth Access Token
    
    .PARAMETER Printers
    Array van printers
    
    .PARAMETER Subnet
    Het subnet om naar te filteren (bijv. "192.168.1")
    
    .PARAMETER Suffix
    Suffix om toe te voegen aan de naam
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [PSObject[]]$Printers,
        [Parameter(Mandatory = $true)] [string]$Subnet,
        [string]$Suffix = "_AutoRenamed"
    )
    
    Write-Log "━━━ Bulk Rename automatisering ━━━" -Level "INFO"
    
    $filteredPrinters = $Printers | Where-Object { $_.ipAddress -like "$Subnet*" }
    
    if ($filteredPrinters.Count -eq 0) {
        Write-Log "⚠ Geen printers gevonden op subnet $Subnet" -Level "WARNING"
        return
    }
    
    Write-Log "Hernoem $($filteredPrinters.Count) printers op subnet $Subnet" -Level "INFO"
    
    $successCount = 0
    $failCount = 0
    
    foreach ($printer in $filteredPrinters) {
        try {
            $newName = "$($printer.name)$Suffix"
            Update-PrinterName -AccessToken $AccessToken -PrinterId $printer.id -NewName $newName
            $successCount++
        }
        catch {
            $failCount++
        }
    }
    
    Write-Log "Bulk rename voltooid: $successCount geslaagd, $failCount mislukt" -Level "INFO"
}

function Bulk-AddTagsBySubnet {
    <#
    .SYNOPSIS
    Voeg tags toe op basis van IP-adres subnet
    #>
    
    param(
        [Parameter(Mandatory = $true)] [string]$AccessToken,
        [Parameter(Mandatory = $true)] [PSObject[]]$Printers
    )
    
    Write-Log "━━━ Bulk Tag automatisering ━━━" -Level "INFO"
    
    # Voorbeeld mappings
    $subnetTagMap = @{
        "192.168.1"   = "Kantoor-1e-etage"
        "192.168.2"   = "Kantoor-2e-etage"
        "192.168.100" = "IT-Ruimte"
        "10.0"        = "Externe-locatie"
    }
    
    $successCount = 0
    $failCount = 0
    
    foreach ($printer in $Printers) {
        foreach ($subnet in $subnetTagMap.Keys) {
            if ($printer.ipAddress -like "$subnet*") {
                try {
                    $tag = $subnetTagMap[$subnet]
                    Add-PrinterTag -AccessToken $AccessToken -PrinterId $printer.id -Tag $tag
                    $successCount++
                    break # Stop na eerste match
                }
                catch {
                    $failCount++
                    break
                }
            }
        }
    }
    
    Write-Log "Bulk tagging voltooid: $successCount geslaagd, $failCount mislukt" -Level "INFO"
}

#endregion

#region MAIN EXECUTION
# ============================================================================
# MAIN: Zet alles samen
# ============================================================================

function Invoke-PrintixAutomation {
    <#
    .SYNOPSIS
    Voer de complete Printix API automatisering uit
    
    .PARAMETER Operation
    Welke operatie uit te voeren: "GetPrinters", "AnalyzeData", "BulkRename", "AddTags", "AddToGroup", "Full"
    
    .PARAMETER NetworkName
    Voor AddToGroup: Naam van het netwerk
    
    .PARAMETER GroupName
    Voor AddToGroup: Naam van de groep
    
    .PARAMETER DryRun
    Voor AddToGroup: Preview zonder wijzigingen
    #>
    
    param(
        [ValidateSet("GetPrinters", "AnalyzeData", "BulkRename", "AddTags", "AddToGroup", "Full")]
        [string]$Operation = "Full",
        [string]$NetworkName,
        [string]$GroupName,
        [bool]$DryRun = $false
    )
    
    Write-Host "`n" + "█" * 70 -ForegroundColor Magenta
    Write-Host "  PRINTIX API AUTOMATION" -ForegroundColor Magenta
    Write-Host "█" * 70 + "`n" -ForegroundColor Magenta
    
    try {
        # Stap 1: Authenticatie
        $accessToken = Get-PrintixAccessToken
        Write-Host ""
        
        # AddToGroup operatie
        if ($Operation -eq "AddToGroup") {
            if ([string]::IsNullOrWhiteSpace($NetworkName) -or [string]::IsNullOrWhiteSpace($GroupName)) {
                Write-Log "Fout: NetworkName en GroupName zijn verplicht voor AddToGroup" -Level "ERROR"
                Write-Host "`nGebruik: Invoke-PrintixAutomation -Operation AddToGroup -NetworkName 'Soudal Turnhout Print' -GroupName 'soudal_turnhout_print'" -ForegroundColor Cyan
                return
            }
            
            Add-PrintersFromNetworkToGroup -AccessToken $accessToken `
                -NetworkName $NetworkName `
                -GroupName $GroupName `
                -DryRun $DryRun
            return
        }
        
        if ($Operation -in "GetPrinters", "AnalyzeData", "BulkRename", "AddTags", "Full") {
            # Stap 2: Printers ophalen
            $printers = Get-PrintixPrinters -AccessToken $accessToken
            Write-Host ""
            
            if ($Operation -in "AnalyzeData", "Full") {
                # Stap 3: Data-analyse
                Analyze-PrinterData -Printers $printers
                Write-Host ""
            }
            
            if ($Operation -in "BulkRename", "Full") {
                # Stap 4a: Bulk rename voorbeeld
                # Uncomment hieronder om uit te voeren (LET OP: Dit wijzigt echte data!)
                # Bulk-RenameBySubnet -AccessToken $accessToken -Printers $printers -Subnet "192.168.1"
                Write-Log "💡 Bulk-RenameBySubnet staat klaar. Uncomment regel above om uit te voeren" -Level "WARNING"
                Write-Host ""
            }
            
            if ($Operation -in "AddTags", "Full") {
                # Stap 4b: Bulk tags voorbeeld
                # Uncomment hieronder om uit te voeren (LET OP: Dit wijzigt echte data!)
                # Bulk-AddTagsBySubnet -AccessToken $accessToken -Printers $printers
                Write-Log "💡 Bulk-AddTagsBySubnet staat klaar. Uncomment regel above om uit te voeren" -Level "WARNING"
                Write-Host ""
            }
        }
        
        Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -Level "INFO"
        Write-Log "✓ AUTOMATION VOLTOOID!" -Level "SUCCESS"
        Write-Log "Logs opgeslagen in: $($Config.LogPath)" -Level "INFO"
    }
    catch {
        Write-Log "✗ AUTOMATION MISLUKT: $($_.Exception.Message)" -Level "ERROR"
        exit 1
    }
}

#endregion

# ============================================================================
# STARTEN
# ============================================================================

# VOORBEELD 1: Basis operaties
# Invoke-PrintixAutomation -Operation "GetPrinters"
# Invoke-PrintixAutomation -Operation "AnalyzeData"

# VOORBEELD 2: Printers van netwerk naar groep (DE HOOFDFUNCTIONALITEIT)
# Stap A: DRY-RUN (bekijk eerst wat zou gebeuren - GEEN WIJZIGINGEN)
# Invoke-PrintixAutomation -Operation AddToGroup `
#     -NetworkName "Soudal Turnhout Print" `
#     -GroupName "soudal_turnhout_print" `
#     -DryRun $true

# Stap B: ECHTE UITVOERING (als je klaar bent)
# Invoke-PrintixAutomation -Operation AddToGroup `
#     -NetworkName "Soudal Turnhout Print" `
#     -GroupName "soudal_turnhout_print" `
#     -DryRun $false

Write-Host "✓ Scriptmodules geladen!" -ForegroundColor Green
Write-Host ""
Write-Host "BESCHIKBARE OPERATIES:" -ForegroundColor Yellow
Write-Host "  • GetPrinters    - Haal alle printers op" -ForegroundColor Cyan
Write-Host "  • AnalyzeData    - Analyseer printerdata" -ForegroundColor Cyan
Write-Host "  • AddToGroup     - Voeg printers van netwerk toe aan groep" -ForegroundColor Cyan
Write-Host "  • BulkRename     - Bulk hernoem printers" -ForegroundColor Cyan
Write-Host "  • AddTags        - Bulk tags toevoegen" -ForegroundColor Cyan
Write-Host "  • Full           - Alle operaties" -ForegroundColor Cyan
Write-Host ""
Write-Host "SNELSTART (Soudal Turnhout Print → soudal_turnhout_print):" -ForegroundColor Magenta
Write-Host "  . .\Printix-API-Automation.ps1" -ForegroundColor White
Write-Host "  Invoke-PrintixAutomation -Operation AddToGroup -NetworkName 'Soudal Turnhout Print' -GroupName 'soudal_turnhout_print' -DryRun `$true" -ForegroundColor White
Write-Host ""
