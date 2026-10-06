#  Printix Wereldwijd Deployment — Volledig Stappenplan
## Soudal Group | 2026
### Opgesteld door: Rayan (Stagiair Infrastructuur)

---

> [!IMPORTANT]
> Dit document beschrijft het **volledige, stapsgewijze draaiboek** voor de wereldwijde uitrol van Printix bij Soudal Group. De uitrol start met een **pilot in Turnhout** en wordt vervolgens uitgebreid naar alle 30+ wereldwijde vestigingen. Dit plan is gebaseerd op de succesvolle PoC die in april 2026 is afgerond.

---

##  Inhoudsopgave

1. [Fase 0 — Voorbereiding & Vereisten](#fase-0--voorbereiding--vereisten)
2. [Fase 1 — Productie-Tenant Opzetten](#fase-1--productie-tenant-opzetten)
3. [Fase 2 — Pilot Turnhout (656 gebruikers)](#fase-2--pilot-turnhout-656-gebruikers)
4. [Fase 3 — Evaluatie & Optimalisatie Pilot](#fase-3--evaluatie--optimalisatie-pilot)
5. [Fase 4 — Regionale Uitrol (België + Nederland)](#fase-4--regionale-uitrol-belgi%C3%AB--nederland)
6. [Fase 5 — Wereldwijde Uitrol](#fase-5--wereldwijde-uitrol)
7. [Fase 6 — Geavanceerde Functies](#fase-6--geavanceerde-functies)
8. [Bijlage A — Volledige Sitelijst](#bijlage-a--volledige-sitelijst)
9. [Bijlage B — Troubleshooting Gids](#bijlage-b--troubleshooting-gids)

---
---

# Fase 0 — Voorbereiding & Vereisten

> **Doel:** Alle organisatorische, technische en contractuele randvoorwaarden regelen vóórdat de eerste productie-installatie plaatsvindt.
>
> **Tijdsinschatting:** 1–2 weken
>
> **Verantwoordelijke:** IT-management + Infrastructuurteam

---

## 0.1 Contractueel & Commercieel

### 0.1.1 Licentie-overeenkomst afronden
- [ ] Definitieve offerte van Printix/Tungsten Automation bevestigen.
  - **Prijsmodel:** €12,- Per User Per Year (PUPY) voor 2.500 gebruikers = **€30.000/jaar**.
  - **Inclusief:** Onbeperkt aantal printers, onbeperkt printvolume, Secure Print, Mobile Print, Analytics.
  - **Exclusief:** Optionele Azure SQL-opslag voor Power BI, Printix AI (vereist apart OpenAI/Azure-abonnement).
- [ ] Contractduur bepalen.



### 0.1.2 Interne goedkeuring
- [ ] Business case presenteren aan IT-management / directie.
- [ ] Budget vrijgeven voor het eerste jaar (€30.000 wereldwijd, of €7.872 voor de pilot met 656 gebruikers in Turnhout).
- [ ] Projectverantwoordelijke aanwijzen (intern Soudal IT).

---

## 0.2 Technische Vereisten

### 0.2.1 Microsoft Entra ID (Azure AD) — Rechten
- [ ] **Global Administrator** beschikbaar voor eenmalige "Admin Consent" in de Printix portal.
  - Actie 1: **"Accept for all users"** — Laat werknemers automatisch inloggen zonder individuele toestemming.
  - Actie 2: **"Synchronize groups"** — Geeft Printix leesrechten op Azure AD groepen.
  - Navigatie: `Printix Portal → Settings → Authentication → Microsoft Entra ID → Accept`.
  - Na klikken: inloggen met Global Admin account en "Toestemming geven namens uw organisatie" aanvinken.

> [!NOTE]
> Dit is tijdens de PoC al succesvol uitgevoerd op de **test-tenant** (`soudal-test.printix.net`). Bij de productie-tenant moet dit opnieuw worden gedaan.

### 0.2.2 Netwerkvereisten
- [ ] Alle printers moeten **SNMP** enabled zijn (standaard al het geval bij de meeste enterprise printers).
- [ ] SNMP community strings documenteren per locatie (vaak `public`, maar kan afwijken).
- [ ] Per vestiging: Gateway MAC-adressen verzamelen van **alle VLANs** (server-VLAN, gebruikers-VLAN, Wi-Fi-VLAN, etc.).

> [!WARNING]
> **Kritiek punt uit de PoC:** Als een gateway MAC-adres ontbreekt in het Printix-netwerkprofiel, worden laptops in dat VLAN niet herkend en krijgen werknemers GEEN printers te zien. Verzamel dus **alle** gateways, niet alleen de primaire.

### 0.2.3 Intune infrastructuur
- [ ] Bevestig dat Microsoft Intune operationeel is en alle doelcomputers beheert.
- [ ] Toegang tot het **Intune Admin Center** (`intune.microsoft.com`) controleren.
- [ ] De **Microsoft Win32 Content Prep Tool** downloaden (nodig om de `.msi` te verpakken als Win32 App).


---

## 0.3 Tooling & Scripts Klaar Zetten

### 0.3.1 SNMP Scanner (hoogswaarschijnlijk niet nodig)
- [ ] Het script `snmp_scanner.ps1` is al ontwikkeld en getest tijdens de PoC.
  - **Functie:** Scant IP-ranges via SNMP en exporteert gevonden printers naar een Printix-compatibele CSV.
  - **Prestatie:** 31.231 IP's gescand → 429 printers gevonden.
  - **Vereiste:** PowerShell 7.0+ met Runspaces (multithreading).
- [ ] Controleer dat het script up-to-date is met de laatste IP-ranges.


---

## 0.4 Communicatieplan Opstellen

### 0.4.1 Interne communicatie
- [ ] Stel een **aankondigingsmail** op voor werknemers in Turnhout:
  - Wat verandert er? (Oude printserver verdwijnt, nieuwe cloud-printen komt)
  - Wat moeten ze doen? (Niets — het wordt automatisch geïnstalleerd, óf: ga naar `soudal.printix.net/download`)
  - Waar kunnen ze terecht bij problemen? (Helpdesk + korte FAQ)
- [ ] Stel een **FAQ-document** op voor de helpdesk (gebaseerd op de Gebruikershandleiding).


### 0.4.2 Helpdesk voorbereiding
- [ ] Helpdesk briefen over de meest voorkomende problemen (uit de PoC):
  - **Software Identifier fout** (verkeerde tenant-URL bij download).
  - **Gateway ontbreekt** (laptop ziet geen printers).
  - **Orphaned Roles bug** (Site Manager rechten blijven hangen).


---
---

# Fase 1 — Productie-Tenant Opzetten

> **Doel:** De definitieve Printix-productieomgeving inrichten, losgekoppeld van de test-tenant.
>
> **Tijdsinschatting:** 1 dag
>
> **Verantwoordelijke:** Infrastructuurteam + Printix account manager

---

## 1.1 Productie-tenant aanmaken

- [ ] Neem contact op met Printix/Tungsten Automation om de **productie-tenant** te activeren.
  - **Test-tenant:** `soudal-test.printix.net` (blijft beschikbaar voor toekomstige tests).
  - **Productie-tenant:** Bijvoorbeeld `soudal.printix.net` (of een andere naam naar keuze).
- [ ] Noteer de nieuwe tenant-URL. **Dit is de URL die alle werknemers gaan gebruiken.**

> [!CAUTION]
> **Kritiek uit de PoC:** De Printix Client is **uniek gebonden aan de tenant-URL**. Als een werknemer de client downloadt via de verkeerde URL (bijv. de test-tenant), verschijnt hij in de verkeerde omgeving en ziet hij verkeerde printers. Zorg dat ALLE communicatie de **juiste productie-URL** bevat.

## 1.2 Admin Consent verlenen 

- [ ] Log in op de nieuwe productie-portal als Global Administrator.
- [ ] Ga naar **Settings → Authentication → Microsoft Entra ID**.
- [ ] Klik op **"Accept for all users"** → Log in met Global Admin → Vink "namens uw organisatie" aan.
- [ ] Klik op **"Synchronize groups"** → Bevestig met Global Admin.
- [ ] En eventueel andere interessante opties.
- [ ] **Verificatie:** Controleer dat alle Azure AD groepen verschijnen onder **Groups** in de portal.

## 1.4 Basis instellingen configureren
(meeste zou automatisch zijn)
- [ ] **Secure Print standaard:** Activeer "Printix Anywhere" als standaard print queue.
- [ ] **Print Policies instellen:**
  - Standaard duplex (dubbelzijdig) printen: **Aan**
  - Standaard zwart-wit printen: **Aan** (of "Aanbevolen")
  - Automatische verwijdering van niet-opgehaalde Secure Print jobs na: **24 uur**
- [ ] **Universal Print integratie:** Activeer onder **Settings → Integrations → Microsoft Universal Print** (optioneel, zie Fase 6).

---
---

# Fase 2 — Pilot Turnhout (656 gebruikers)

> **Doel:** Printix uitrollen naar 656 werknemers op de vestiging Turnhout (alle gebruikers van deze locatie) om de productieomgeving te valideren vóór de brede uitrol.
>
> **Tijdsinschatting:** 1–2 weken
>
> **Verantwoordelijke:** Infrastructuurteam + Lokaal IT Turnhout + (site admins)

---

## 2.1 Printers ontdekken en importeren

### Optie A: Via SNMP Scanner 
1. [ ] Open PowerShell 7 op een machine met netwerktoegang tot het Turnhout printer-VLAN.
2. [ ] Pas het script `snmp_scanner.ps1` aan zodat het **alleen** de Turnhout IP-ranges scant:
   - `10.0.10.0 - 10.0.10.255` (Soudal Turnhout Print)
   - `192.1.10.1 - 192.1.10.255` (Soudal Turnhout)
   - `10.0.13.0 - 10.0.13.255` (indien van toepassing)
3. [ ] Voer het script uit:
   ```powershell
   .\snmp_scanner.ps1
   ```
4. [ ] Controleer de gegenereerde CSV:
   - Juist aantal kolommen (7 verplicht: Name, Address, Vendor, Model, MACAddress, Network, Description)
   - Geen speciale tekens in modelnamen (RegEx-filter in het script handelt dit af)
   - Geen dubbele printers (`Sort-Object Address -Unique`)
5. [ ] Upload de CSV via de **Tungsten Printix Configurator**:
   - Open de Configurator (desktop-applicatie of via de portal).
   - Ga naar **Import → Printers**.
   - Selecteer het CSV-bestand.
   - Klik op **Start**.
6. [ ] **Verificatie:** Ga in de portal naar **Printers** en controleer dat alle Turnhout-printers zichtbaar zijn.

### Optie B: Via Cloud Discovery (Alternatief)
1. [ ] Installeer de Printix Client op één machine in het Turnhout-netwerk.
2. [ ] Ga in de portal naar **Printers → Discover printers**.
3. [ ] Wacht tot de scan voltooid is (enkele minuten).
4. [ ] Controleer de resultaten.

> [!TIP]
> **Aanbeveling uit de PoC:** Optie A (SNMP Scanner + CSV) is betrouwbaarder en sneller voor de initiële import. Cloud Discovery werkt beter als aanvulling nadat er al een client op de locatie draait.

---

## 2.2 Print Queues aanmaken

Alleen printers met een Print Queue zijn zichtbaar voor werknemers.

1. [ ] Ga in de portal naar **Printers**.
2. [ ] Selecteer alle Turnhout-printers via de vinkjes (filter op IP-range `10.0.10.`).
3. [ ] Klik bovenaan op **"Add print queue"**.
4. [ ] **Verificatie:** Alle geselecteerde printers hebben nu een Print Queue-icoon.

> [!NOTE]
> Dit proces gebeurt normaal gesproken automatisch wanneer printers via Discovery worden gevonden. Bij CSV-import moet het handmatig worden geactiveerd.

---

## 2.3 Netwerk aanmaken voor Turnhout
##### je kan de namen van de netwerken ook gewoon aanpassen als deze wordene gediscovered en anders doe je het volgende:
1. [ ] Ga in de portal naar **Networks**.
2. [ ] Klik op **"Add Network"**.
3. [ ] Vul in:
   - **Network Name:** `Soudal Turnhout` (of `BETUSO`)
   - **Description:** `België: Turnhout — Everdongenlaan 18-20, 2300 Turnhout`
4. [ ] **KRITIEK — Gateway MAC-adressen toevoegen:**
   - Voeg het Gateway MAC-adres toe van het **printer-VLAN** (bijv. `10.0.10.x`).
   - Voeg het Gateway MAC-adres toe van het **gebruikers-VLAN** (bijv. `10.0.65.x`).
   - Voeg het Gateway MAC-adres toe van het **Wi-Fi VLAN** (indien van toepassing).
   - Voeg het Gateway MAC-adres toe van **elk ander VLAN** op de Turnhout-locatie waar werknemerslaptops op draaien.
5. [ ] Klik op **Save**.

> [!WARNING]
> **Herhaling van het belangrijkste punt uit de PoC:** Vergeet je een gateway, dan worden laptops in dat VLAN niet herkend en zien werknemers **geen** printers. Test dit grondig door een laptop in elk VLAN aan te sluiten (zie stap 2.9).

---

## 2.4 Printers verplaatsen naar het juiste netwerk

Na de import staan alle printers waarschijnlijk in het standaardnetwerk ("Network2" of "Unmapped"). Ze moeten naar `Soudal Turnhout` verplaatst worden.

1. [ ] Ga naar **Printers** in de portal.
2. [ ] Filter op het huidige netwerk (bijv. "Network2").
3. [ ] Sorteer op **Address** (IP-adres).
4. [ ] Selecteer alle printers met IP-range `10.0.10.x` (Turnhout printers).
5. [ ] Klik op **Modify** (of Bulk Edit).
6. [ ] Wijzig het **Network** veld naar `Soudal Turnhout`.
7. [ ] Klik op **Save**.
8. [ ] **Verificatie:** Filter nu op netwerk `Soudal Turnhout` — alle Turnhout-printers moeten hier staan.

---

## 2.5 Azure AD Groepen synchroniseren

1. [ ] Ga naar **Groups** in de portal.
2. [ ] Klik op **"Synchronize"**.
3. [ ] Wacht tot alle Azure AD groepen zijn geladen (kan enkele minuten duren).
4. [ ] **Verificatie:** Zoek naar de groep die de Turnhout-werknemers bevat (bijv. `Soudal_Turnhout` of een locatie-specifieke groep).

---

## 2.6 Printers toewijzen aan groepen (Hybride Deployment)

### Core Printers — Automatisch pushen
Dit zijn de 2–3 meest gebruikte printers op de Turnhout-locatie (bijv. de grote Ricoh copier in de gang, de HP LaserJet bij de receptie).

1. [ ] Ga naar **Groups** in de portal.
2. [ ] Selecteer de Turnhout-groep (bijv. `Soudal_Turnhout`).
3. [ ] Klik op het tabblad **Print queues** → **Add**.
4. [ ] Selecteer de 2–3 core printers.
5. [ ] Vink aan: **"Add print queue automatically"** ✅
6. [ ] Vink aan: **"Remove print queue automatically"** ✅ (zodat printers worden verwijderd als iemand het netwerk verlaat)
7. [ ] Optioneel: Vink aan **"Set as default printer"** voor de belangrijkste printer.
8. [ ] Klik op **Save**.

### Overige Printers — Self-service
Alle andere printers worden NIET automatisch gepusht. Werknemers voegen ze zelf toe via de Printix Client als dat nodig is.

- [ ] Controleer dat de overige printers WEL een Print Queue hebben (stap 2.2), maar dat ze NIET zijn gekoppeld aan een groep met "auto-add".

> [!NOTE]
> **Verduidelijking uit de PoC:** De automatische push is **dynamisch op basis van locatie (netwerk)**. Als een werknemer van Turnhout naar een andere vestiging reist, worden de Turnhout-printers automatisch verwijderd en de printers van de nieuwe locatie automatisch toegevoegd.

---

## 2.8 Printix Client uitrollen naar de pilotgroep

### Methode A: Via Microsoft Intune (Aanbevolen)
1. [ ] Download de `.msi` installer via: `https://soudal.printix.net/download` (productie-URL!).
2. [ ] Verpak de `.msi` als een **Win32 App** met de Microsoft Win32 Content Prep Tool:
   ```powershell
   IntuneWinAppUtil.exe -c <bronmap> -s PrintixClient.msi -o <uitvoermap>
   ```
3. [ ] Ga naar het **Intune Admin Center** (`intune.microsoft.com`).
4. [ ] Navigeer naar **Apps → Windows → Add → Windows app (Win32)**.
5. [ ] Upload het `.intunewin` pakket.
6. [ ] Configureer:
   - **Naam:** Printix Client
   - **Publisher:** Tungsten Automation
   - **Install command:** `msiexec /i "PrintixClient.msi" /quiet /norestart`
   - **Uninstall command:** `msiexec /x "PrintixClient.msi" /quiet /norestart`
   - **Detection rule:** Bestandsregel → `C:\Program Files\Printix\PrintixClient.exe` bestaat.
   - **Requirements:** Windows 10/11, 64-bit.
7. [ ] **Toewijzing:** Wijs de app toe aan een **Azure AD apparaatgroep** die alleen de Turnhout-pilot-laptops bevat.
   -  Wijs NIET toe aan "All Devices" — dit is de pilot!
8. [ ] Wacht op de Intune sync-cyclus (standaard elke 8 uur, of forceer sync op een testlaptop).

### Methode B: Handmatig (Alleen voor snelle tests)
1. [ ] Stuur de downloadlink naar de testgebruikers: `https://soudal.printix.net/download`.
2. [ ] Gebruiker downloadt `PrintixClient.msi`.
3. [ ] Dubbelklik → Installatie-wizard → Log in met Soudal Microsoft-account.

---

## 2.9 Verificatie & Testing

### 2.9.1 Individuele test (Eerste laptop)
- [ ] Installeer de Printix Client op een **standaard werknemer-laptop** (niet een server of admin-machine).
- [ ] Log in met een Azure AD account dat lid is van de Turnhout-groep.
- [ ] **Controleer in de portal:**
  - Verschijnt de computer onder **Computers**?
  - Is het juiste netwerk (`Soudal Turnhout`) gekoppeld?
- [ ] **Controleer op de laptop:**
  - Verschijnen de core printers automatisch in het Windows printermenu?
  - Verschijnt de printer "Printix Anywhere"?
- [ ] **Test afdrukken:**
  - Open Kladblok → Type "Test" → CTRL+P → Selecteer een Turnhout-printer → Print.
  - Controleer dat het papier fysiek aankomt.
- [ ] **Test Secure Print:**
  - Print een document naar "Printix Anywhere".
  - Ga naar `https://soudal.printix.net/app` op je telefoon.
  - Log in → Selecteer printer → Klik "Release".
  - Controleer dat het document nu pas fysiek wordt geprint.

### 2.9.2 VLAN-test (Kritiek)
- [ ] Sluit een laptop aan op het **gebruikers-VLAN** → Controle: printers zichtbaar? 
- [ ] Sluit een laptop aan op het **Wi-Fi VLAN** → Controle: printers zichtbaar? 
- [ ] Sluit een laptop aan op het **server-VLAN** → Controle: printers zichtbaar? 
- [ ] Als een VLAN niet werkt → Voeg de ontbrekende gateway toe aan het netwerkprofiel (stap 2.3).

### 2.9.3 Multi-user test
- [ ] Laat minimaal **3 verschillende werknemers** (niet-IT) de volgende acties uitvoeren:
  1. Inloggen in de Printix Client.
  2. Controleer of de juiste printers automatisch verschijnen.
  3. Een document afdrukken.
  4. Een extra printer toevoegen via self-service.
  5. Beveiligd printen via Printix Anywhere.
- [ ] Noteer alle vragen, problemen en feedback.

### 2.9.4 Driver-verificatie
- [ ] Controleer per printermodel of de juiste driver is geselecteerd.
- [ ] Controleer of de afdrukvoorkeuren correct zijn (papierformaat A4, kleur/zwart-wit).
- [ ] Als instellingen afwijken:
  1. Stel de voorkeuren correct in op een "master" laptop.
  2. Upload de configuratie naar de portal (**Printers → [printer] → Print queues → Drivers → Upload from computer**).
  3. Vergrendel de configuratie (**Locked**).
  4. Distribueer naar alle printers van hetzelfde model (**Distribute print queue configuration**).

---

## 2.10 Oude printserver(s) afschakelen (Turnhout)

> [!CAUTION]
> Doe dit **pas** nadat alle 656 gebruikers van Turnhout succesvol via Printix printen en er minimaal 1 week zonder problemen is verstreken.

1. [ ] Communiceer naar de pilotgroep dat de oude printserver wordt afgeschakeld op datum X.
3. [ ] Schakel de printserver-shares uit (niet de hele server — andere diensten draaien er mogelijk op).
4. [ ] Monitor de helpdesk gedurende 1 week voor onverwachte problemen.

---
---

# Fase 3 — Evaluatie & Optimalisatie Pilot

> **Doel:** De resultaten van de pilot in Turnhout evalueren, problemen oplossen en het proces optimaliseren voor de bredere uitrol.
>
> **Tijdsinschatting:** 1 week
>
> **Verantwoordelijke:** Infrastructuurteam

---

## 3.1 Feedback verzamelen

- [ ] Stuur een kort feedbackformulier naar de 656 Turnhout-gebruikers:
  - Werkte de installatie soepel?
  - Verschenen de juiste printers?
  - Zijn er printers die ontbreken?
  - Was het beveiligd printen begrijpelijk?
  - Algemene ervaring (1–5 score)?
- [ ] Verzamel alle helpdesktickets gerelateerd aan de pilot.
- [ ] Identificeer de top 3 problemen.

## 3.2 Rapportages controleren

- [ ] Ga naar het **Dashboard** in de portal.
- [ ] Controleer:
  - Worden alle printopdrachten correct geregistreerd?
  - Is de data per gebruiker en per printer inzichtelijk?
  - Zijn er "ghost" print-jobs (opdrachten die niet aankomen)?

## 3.3 Optimalisaties doorvoeren

- [ ] **Driver-issues:** Als bepaalde printermodellen problemen geven (bijv. verkeerd papierformaat, ontbrekende lades), pas de configuratie aan en distribueer opnieuw.
- [ ] **Ontbrekende printers:** Als werknemers printers melden die niet in de lijst staan, voeg ze handmatig toe of voer een nieuwe Discovery uit.


## 3.4 Go/No-Go beslissing

- [ ] Presenteer de pilotresultaten aan IT-management.
- [ ] **Go-criteria:**
  - ≥90% van de 656 Turnhout-gebruikers kan probleemloos printen.
  - Helpdesk-volume is beheersbaar (<5 tickets/week na de eerste week).
  - Geen kritieke bugs of beveiligingsproblemen.
- [ ] Bij **Go:** Ga verder naar Fase 4 (Regionale uitrol).
- [ ] Bij **No-Go:** Documenteer de blokkeringsproblemen en plan een verbeterde pilot of maak gebruik van MUP.

---
---

# Fase 4 — Regionale Uitrol

> **Doel:** Printix uitrollen naar alle Europese vestigingen.
>
> **Tijdsinschatting:** (afhankelijk van het aantal sites)
>
> **Verantwoordelijke:** Infrastructuurteam + Lokale IT-teams per site

---

## 4.2 Per-site uitrolprocedure (herhaal voor elke locatie)

### Stap 1: Netwerk voorbereiden ( of automatisch + naam veranderen)
- [ ] Verzamel de **Gateway MAC-adressen** van alle VLANs op de site (contacteer lokale IT).
- [ ] Maak het netwerk aan in de Printix portal (**Networks → Add Network**).
- [ ] Voeg **alle** gateways toe als subnets.

### Stap 2: Printers importeren
- [ ] **Optie A (Nieuw):** Installeer de Printix Client op één lokale machine → Gebruik **Cloud Discovery** → Printers worden automatisch gevonden.
- [ ] **Optie B (Bulk):** Voer de SNMP Scanner uit op de IP-range van deze site → Importeer de CSV.

 ### Stap 3: Print Queues aanmaken (Of automatisch)
- [ ] Selecteer alle nieuwe printers → **Add print queue**.

### Stap 4: Printers naar juist netwerk verplaatsen
- [ ] Verplaats printers van "Unmapped"/"Network2" naar het zojuist aangemaakte netwerk.
- [ ] Dit kan handmatig (Bulk Edit) of via het API-script.

### Stap 5: Groep koppelen
- [ ] Koppel de site-specifieke Azure AD groep aan de core printers (2–3 stuks auto-push).

### Stap 6: Client uitrollen
- [ ] Breid de **Intune-toewijzing** uit naar de apparaatgroep van deze site.

### Stap 7: Testen
- [ ] Laat minimaal 1 lokale gebruiker testen (inloggen, printers zien, afdrukken).
- [ ] Controleer VLAN-herkenning.

### Stap 8: Oude printserver deactiveren
- [ ] Na 1 week zonder problemen: schakel de lokale printserver-shares uit.

---


---

# Fase 5 — Wereldwijde Uitrol

> **Doel:** Printix uitrollen naar alle overige 30+ wereldwijde vestigingen.
>
> **Tijdsinschatting:**  gefaseerd per regio
>
> **Verantwoordelijke:** Infrastructuurteam + Regionale IT-contactpersonen

---

## 5.1 Uitrolstrategie: Per regio

De wereldwijde uitrol wordt opgesplitst in regionale golven. Elke golf volgt dezelfde per-site procedure als beschreven in Fase 4, stap 4.2.

### Golf 1: West-Europa 
| Site Code | Locatie |
|:---|:---|
| DELESO1 | Soudal, Leverkusen (Duitsland) |
| DKALLJ1 | Ljungdahl, Allerød (Denemarken) |
| DKVESO1 | Soudal, Vejle (Denemarken) |
| FIVASO | Vantaa, Soudal/Joints (Finland) |
| FRIBLAY | Ayrton, Blyes (Frankrijk) |
| HROOTR | Tramico, Gournay-en-Bray (Frankrijk) |
| NOTRSO1 | Soudal, Tranby (Noorwegen) |
| UKTASO1 | Soudal, Tamworth (VK) |
| UKTAWH | Soudal Warehouse, Tamworth (VK) |
| IEDUSO1 / IEDUSE | Dublin, Soudal/Seal Systems (Ierland) |

### Golf 2: Zuid-Europa 
| Site Code | Locatie |
|:---|:---|
| ESALSO1 | Soudal, Alovera / Madrid (Spanje) |
| ESAZSO | Soudal, Azuqueca de Henares (Spanje) |
| ITMISO | Soudal, Milan (Italië) |
| ITMIWH | Warehouse Mazzuocco, Milan (Italië) |
| PTLISO | Lisboa, Soudal (Portugal) |
| GRATIK | Athens, TKK (Griekenland) |

### Golf 3: Centraal- & Oost-Europa 
| Site Code | Locatie |
|:---|:---|
| ATSVSO1 | Soudal, Sankt-Valentin (Oostenrijk) |
| PLCZSO1 | Soudal, Czosnow (Polen) |
| PLPIOSO1 | Soudal, Pionki (Polen) |
| PLPIBO | Bochem, Pionki (Polen) |
| PLSUBO | Bochem Production, Suskowola (Polen) |
| HUBUSO1 | Budakalász, Soudal (Hongarije) |
| HUSZTK | Székesfehérvár, TKK (Hongarije) |
| ROCRSO | Crevedia, Soudal (Roemenië) |
| BGSOSO | Sofia, Soudal (Bulgarije) |
| BOSOTK | Sofia, TKK (Bulgarije) |
| HRDOSO | Donja Zelina, Soudal (Kroatië) |
| HRZATK | Zagreb, TKK (Kroatië) |
| BABATK / BASATK | TKK, Bosnië |
| RSBETK | Beograd, TKK (Servië) |
| SILJTK / SIMOTK / SISEMI / SISOTK / SISRTK / SISTTK | TKK, Slovenië (meerdere sites) |
| LVDOTE / LVJETE | Tenachem, Letland |
| BYMISO | Minskij, Soudal (Belarus) |

### Golf 4: Rusland, Turkije & Midden-Oosten 
| Site Code | Locatie |
|:---|:---|
| RUNOSO / RUNOWH | Noginsk, Soudal (Rusland) |
| TRADSO | Adana, Soudal (Turkije) |
| TRISSO1 / TRISWH | Istanbul, Soudal (Turkije) |
| AEDUAM / AESHAM / AEUMAM / AEUMWA / AEUMWH | Al Muqarram, VAE (meerdere sites) |
| KZASSO | Astana, Soudal (Kazachstan) |

### Golf 5: Azië & Oceanië 
| Site Code | Locatie |
|:---|:---|
| CNSHSO | Shanghai Office, Soudal (China) |
| CNTASO | Taixing Plant, Soudal (China) |
| INBASO / INCOSO / INCPSO / INDESO | Soudal India (meerdere sites) |
| KRJISH | Jincheon, Seunghyun (Zuid-Korea) |
| THBASO | Soudal, Bangkok (Thailand) |
| AUGLSO | Glendenning, Soudal (Australië) |
| NZHASO | Hamilton, Soudal (Nieuw-Zeeland) |

### Golf 6: Amerika & Afrika 
| Site Code | Locatie |
|:---|:---|
| CADOSO | Dorval, Soudal (Canada) |
| USETAM | Accumetric, Elizabethtown (VS) |
| BRSASO | São Paulo, Soudal (Brazilië) |
| CLSASO | Santiago, Soudal (Chili) |
| COBOSO | Bogota, Soudal (Colombia) |
| PELISO | Lima, Soudal (Peru) |
| MXTLSO | Tlalnepantla de Baz, Soudal (Mexico) |
| MACASO1 | Casablanca, Soudal (Marokko) |
| ZAJBSO | Johannesburg, Soudal (Zuid-Afrika) |


---

## 5.2 Aandachtspunten bij wereldwijde uitrol

### Regio-specifieke driver-instellingen

### Onderhoud

### Lokale IT-ondersteuning

### Connectivity

---
---

# Fase 6 — Geavanceerde Functies

> **Doel:** Na de basisuitrol, optionele geavanceerde functies activeren.
>
> **Tijdsinschatting:** Doorlopend / naar behoefte
>
> **Verantwoordelijke:** Infrastructuurteam

---

## 6.1 Printix GO (Secure Print op het apparaat)

Printix GO installeert beveiligingssoftware op de fysieke printer (MFP). Hiermee kunnen werknemers zich identificeren via pincode of badge vóórdat ze documenten ophalen.

### Wanneer activeren?
- **High-security zones:** R&D labs, HR-afdelingen, directiekantoren.
- **Grote MFP's:** Waar veel werknemers documenten achterlaten.

### Installatieprocedure per printer:
1. [ ] **Sign in profile aanmaken:**
   - Portal → **Settings → Printix GO → Sign in profiles → (+)**
   - Naam: bijv. `Soudal_Pincode`
   - Methode: **ID code (pincode)** en/of **Card (badge)**
   - Card registration: **Enable** (badges worden automatisch gekoppeld bij eerste scan)
2. [ ] **Go configuration aanmaken:**
   - Portal → **Settings → Printix GO → Go configurations → (+)**
   - Naam: bijv. `Standaard_MFP`
   - Functies: Print , Copy  (achter login), Scan  (achter login)
3. [ ] **Activatie op de printer:**
   - Portal → **Printers → [kies printer] → tabblad Printix GO**
   - Koppel het Go configuration profiel
   - Koppel het Sign in profiel
   - Voer het **administrator-wachtwoord** van de printer in (web-interface wachtwoord)
   - Klik op **Install**
4. [ ] **Verificatie:** Een groen 'GO' icoontje verschijnt bij de printer in het dashboard.

> [!NOTE]
> **Soudal-beslissing uit de PoC:** Badge-authenticatie is technisch ingericht maar wordt voor de algemene kantooromgeving **niet geactiveerd**. Werknemers gebruiken standaard hun pincode.

---

## 6.2 Scan to Cloud (OneDrive & SharePoint)

### Activatie:
1. [ ] Portal → **Settings → Integrations → Cloud Storage**.
2. [ ] Klik op **"Grant access"** bij Microsoft OneDrive.
3. [ ] Klik op **"Grant access"** bij Microsoft SharePoint (optioneel).
4. [ ] Bevestig met een Global Admin account.

### Resultaat:
- Werknemers kunnen documenten scannen bij de MFP en direct opslaan in hun persoonlijke OneDrive of een gedeelde SharePoint-map.
- Geen "Scan to Email" of onveilige netwerkshares meer nodig.

---

## 6.3 Microsoft Universal Print Integratie

### Wanneer gebruiken?
- Voor apparaten waarop **geen** Printix Client geïnstalleerd mag worden (bijv. BYOD-apparaten, kiosk-PC's).
- Als aanvulling op de standaard Printix-deployment.

### Activatie:
1. [ ] Portal → **Settings → Integrations → Microsoft Universal Print → Accept**.
2. [ ] Per Print Queue: open de instellingen → vink **"Publish to Universal Print"** aan.
3. [ ] De printer verschijnt nu als native cloud-printer in Windows Instellingen.

> [!WARNING]
> **Licentie-impact:** Universal Print heeft een limiet op het aantal print-jobs per maand (afhankelijk van de Microsoft-licentie). Printen via de Printix Client zelf blijft onbeperkt. Gebruik UP alleen als aanvulling, niet als primaire methode.

---

## 6.4 Power BI Dashboard

### Opzet:
1. [ ] Download de standaard Printix Power BI template (`.pbit`) via de Printix portal of documentatie.
2. [ ] Open het bestand in Power BI Desktop.
3. [ ] Verbind het template met de Printix SQL-database (credentials via de portal).
4. [ ] Publiceer het rapport naar de Power BI-service voor management-toegang.

### Beschikbare rapportages:
- Printvolume per afdeling, vestiging en gebruiker.
- Kleur vs. zwart-wit verhouding.
- Kosten per gebruiker / per afdeling.
- Milieu-impact (papierverbruik, CO2-voetafdruk).
- Trends over tijd.

---

## 6.5 QR-Code Self-Service Stickers

### Concept:
Plak een **QR-code sticker** op elke printer. Werknemers scannen de code met hun telefoon om de printer direct toe te voegen aan hun Printix Client.

### Implementatie:
1. [ ] Genereer per printer een QR-code die linkt naar de Printix self-service pagina.
2. [ ] Print de QR-codes op stickervellen.
3. [ ] Plak de stickers op de behuizing van elke printer.

---
---

## 6.6 Doorlopende taken

| Taak | Frequentie | Beschrijving |
|:---|:---|:---|
| Azure AD groepen synchroniseren | Maandelijks | Nieuwe groepen/afdelingen laden in Printix |
| Printer-inventory controleren | Maandelijks | Zijn alle printers nog online? Zijn er nieuwe printers toegevoegd op locaties? |
| Driver-updates controleren | Kwartaal | Zijn er nieuwe drivers beschikbaar voor printermodellen? |
| Rapportages reviewen | Maandelijks | Printvolume, kosten, trends analyseren |
| Licentie-audit | Jaarlijks | Klopt het aantal gelicentieerde gebruikers nog? |
| Printix Client-versie updaten | Bij release | Nieuwe MSI-versie uitrollen via Intune |
| Helpdesk-feedback evalueren | Maandelijks | Top-problemen identificeren en structureel oplossen |

---
---

# Bijlage A — Volledige Sitelijst

Alle actuele Soudal-vestigingen die in Printix moeten worden opgenomen:

<details>
<summary><strong>Klik om de volledige lijst te openen (100+ sites)</strong></summary>

```
Dubai, Al Muqarram Office (AEDUAM)
Sharjah, Al Muqarram HQ (AESHAM)
Umm al-Quwain, Al Muqarram Office (AEUMAM)
Sharjah, Al Muqarram Warehouse 2 (AEUMWA)
Sharjah, Al Muqarram Warehouse (AEUMWH)
Soudal, Sankt-Valentin (ATSVSO1)
Glendenning, Soudal (AUGLSO)
Banja Luka, TKK (BABATK)
Sarajevo, TKK (BASATK)
De Neef Heist (BEHEDN)
De Neef Kallo (BEKADN)
Rectavit, Lochristi (BELORE1)
Sapac, Nazareth (BENASA1)
Aerotrim, Pelt (BEOVAE1)
Warehouse Dilissen, Pelt (Aerotrim) (BEPEWH)
Soudal Plant 1, Turnhout (Legacy) (BETUR1)
Soudal Plant 2, Turnhout (Legacy) (BETUR2)
Soudal Plant 3, Turnhout (Legacy) (BETUR3)
Soudal Plant 5, Turnhout (Legacy) (BETUR5)
Soudal, Turnhout (BETUSO)
Soudal Plant 1, Turnhout (BETUSO1)
Soudal Plant 2, Turnhout (BETUSO2)
Soudal Plant 3, Turnhout (BETUSO3)
Soudal Plant 5, Turnhout (BETUSO5)
Magazijn Schietstandlaan, Turnhout (BETUWA)
Wouwer, Turnhout (BETUWO)
Sofia, Soudal (BGSOSO)
Sofia, TKK (BOSOTK)
Sao Paulo, Soudal (BRSASO)
Minskij, Soudal (BYMISO)
Dorval, Soudal (CADOSO)
Santiago, Soudal (CLSASO)
Shanghai Office, Soudal (CNSHSO)
Taixing Plant, Soudal (CNTASO)
Bogota, Soudal (COBOSO)
Soudal, Leverkusen (DELESO1)
Ljungdahl, Allerød (DKALLJ1)
Soudal, Vejle (DKVESO1)
Soudal, Alovera (Madrid) (ESALSO1)
Soudal, Azuqueca de Henares (Madrid) (ESAZSO)
Vantaa, Soudal/Joints (FIVASO)
Ayrton, Blyes (FRIBLAY)
Tramico, Gournay-en-Bray (HROOTR)
Athens, TKK (GRATIK)
Donja Zelina, Soudal (HRDOSO)
Zagreb, TKK (HRZATK)
Budakalász, Soudal Magyarország Kft. (HUBUSO1)
Székesfehérvár, TKK (HUSZTK)
Dublin, Soudal (Legacy) (IEDUB1)
Dublin, Seal Systems (IEDUSE)
Dublin, Soudal (IEDUSO1)
Bawal, Soudal (INBASO)
Chennai Office, Soudal (INCOSO)
Chennai Production, Soudal (INCPSO)
Delhi Office, Soudal (INDESO)
Soudal, Milan (ITMISO)
Warehouse Mazzuocco, Milan (ITMIWH)
Jincheon, Seunghyun (KRJISH)
Astana, Soudal (KZASSO)
Dobele, Tenachem (LVDOTE)
Jelgava, Tenachem (LVJETE)
Casablanca, Soudal (MACASO1)
Tlalnepantla de Baz, Soudal (MXTLSO)
Soudal Manufacturing BV, Bergen op Zoom (NLBZSO)
Frencken, Weert (NLWEFR1)
Soudal, Tranby (NOTRSO1)
Hamilton, Soudal (NZHASO)
Lima, Soudal (PELISO)
Soudal, Czosnow (PLCZSO1)
Bochem, Pionki (PLPIBO)
Soudal, Pionki (PLPIOSO1)
Bochem Production, Suskowola (PLSUBO)
Lisboa, Soudal - New Office (PTLISO)
Crevedia, Soudal (ROCRSO)
Beograd, TKK (RSBETK)
Noginsk, Soudal (RUNOSO)
Soudal Noginsk Warehouse (RUNOWH)
TKK, Ljubljana (SILJTK)
TKK, Most na Soci (SIMOTK)
Mitol, Sezana - MITOL (SISEMI)
TKK, Soci (SISOTK)
TKK, Srpenica - NEW (SISRTK)
TKK, Store (SISTTK)
Labo, Spare, Turnhout (SPARE)
Soudal Ltd.Bangkok (THBASO)
Adana, Soudal (TRADSO)
Istanbul, Soudal (TRISSO1)
Istanbul, Warehouse, Soudal (TRISWH)
Soudal, Tamworth (Centurion Road) (UKTASO1)
Soudal, Tamworth (Centurion Road) (UKTAWH)
Accumetric Elizabethtown (KY) (USETAM)
Johannesburg (ZAJBSO)
```

</details>

---
---

# Bijlage B — Troubleshooting Gids

## B.1 Werknemers zien geen printers

| Mogelijke oorzaak | Diagnose | Oplossing |
|:---|:---|:---|
| Printix Client niet geïnstalleerd | Computer verschijnt niet onder "Computers" in de portal | Client installeren via Intune of `soudal.printix.net/download` |
| Verkeerde tenant-URL gebruikt | Computer verschijnt in de test-tenant i.p.v. productie | Client verwijderen → opnieuw downloaden via de juiste productie-URL |
| Gateway ontbreekt in netwerkprofiel | Computer staat onder "Computers" maar met verkeerd/geen netwerk | Gateway MAC-adres toevoegen aan het netwerk in de portal |
| Groepskoppeling ontbreekt | Computer in juist netwerk, maar geen printers toegewezen | Groep koppelen aan core printers met "auto-add" |
| Geen Print Queue aangemaakt | Printer verschijnt als "Device" maar niet als "Print Queue" | Selecteer de printer → "Add print queue" |

## B.2 Print-job komt niet aan

| Mogelijke oorzaak | Diagnose | Oplossing |
|:---|:---|:---|
| Printer offline | Status = "Offline" in de portal | Controleer de fysieke printer (papier, toner, stroom) |
| Cross-VLAN blokkade | Laptop en printer zitten in verschillende VLANs zonder routing | Zet "Via the cloud" AAN in de Print Queue-instellingen |
| Driver-mismatch | Print-job blijft "Pending" | Configuratie opnieuw uploaden en vergrendelen |
| Printix Anywhere niet vrijgegeven | Document verstuurd naar secure print maar niet opgehaald | Gebruiker moet het document vrijgeven via de app of webportal |

## B.3 Software Identifier Fout

**Symptoom:** Werknemer ziet printers uit een ander land of een andere omgeving.

**Oorzaak:** De Printix Client is gedownload via de verkeerde tenant-URL.

**Oplossing:**
1. Verwijder de client: Windows Instellingen → Apps → "Printix" → Verwijderen.
2. Download opnieuw via de juiste URL: `https://soudal.printix.net/download`
3. Installeer en log opnieuw in.

## B.4 Orphaned Roles Bug

**Symptoom:** Gebruiker behoudt "Site Manager" rechten na het verwijderen van een site.

**Oplossing:**
1. Maak een nieuwe tijdelijke Site aan.
2. Koppel de betreffende groep opnieuw als Site Manager.
3. Verwijder de groep handmatig uit de Site-instellingen.
4. Verwijder daarna de tijdelijke Site.

## B.5 Printers met sterretje (★) en MUP-naam

**Symptoom:** Printers verschijnen in de Printix Client met een ★ en een Universal Print share-naam.

**Oorzaak:** De Printix Client toont standaard alle lokaal geïnstalleerde Windows-printers. Als er eerder Universal Print-printers handmatig waren geïnstalleerd, pikt de Client deze op.

**Oplossing:** Verwijder de betreffende printers via *Windows Instellingen → Bluetooth en apparaten → Printers en scanners*.

---
---

#  Samenvatting Tijdlijn

| Fase | Duur | Beschrijving |
|:---|:---|:---|
| **Fase 0** | 1–2 weken | Voorbereiding, contracten, technische vereisten |
| **Fase 1** | 1 dag | Productie-tenant opzetten |
| **Fase 2** | 1–2 weken | Pilot Turnhout (656 gebruikers) |
| **Fase 3** | 1 week | Evaluatie & optimalisatie pilot |
| **Fase 4** | Doorlopend | Regionale uitrol |
| **Fase 5** | Doorlopend | Wereldwijde uitrol (~2.500 gebruikers) |
| **Fase 6** | Doorlopend | Geavanceerde functies (GO, Scan-to-Cloud, Power BI) |
| **Fase 7** | Doorlopend | Overdracht & beheer |
| **TOTAAL** | **~1-5 jaar** | Van pilot tot volledige wereldwijde uitrol |

---

*Opgesteld op 26 mei 2026 — Soudal Group, Turnhout*
*Auteur: Rayan (Stagiair Infrastructuur)*
*Gebaseerd op: Printix PoC Eindverslag (April 2026)*
