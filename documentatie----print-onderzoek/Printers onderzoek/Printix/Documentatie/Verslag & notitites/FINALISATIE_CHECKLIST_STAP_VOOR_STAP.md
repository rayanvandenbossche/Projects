# PRINTIX FINALISATIE CHECKLIST - Stap voor Stap 

**Status:** Admin-rechten ontvangen   
**Datum:** 3 April 2026  
**Fase:** Finalisatie & Netwerk Mapping

---
---

##  FASE 1: Add Print Queues (ONMIDDELLIJK) 

### Wat moet gedaan worden?
De 435 printers moeten geconverteerd worden van "Devices" naar "Print Queues" zodat werknemers ze kunnen installeren. Dit gebeurd helemaal automatisch normaal gezien. *(Opmerking: Het totaal aantal printers fluctueert doorlopend omdat dit afhangt van de actieve netwerkscans. Soms staan er ~400 actief en ingeschakeld, op andere momenten meer dan 600. In het eindverslag spreken we van 429 printers, terwijl de netwerkscan tijdens het opstellen van deze checklist er 435 vond).*


**Status na stap 1:**  Alle gedetecteerde printers zijn nu zichtbaar voor werknemers

---

##  FASE 2: Networks Aanmaken in Printix

### Waarom?
De 435 printers zitten nu allemaal in **"Network2"** (de standaard uit de scan die het script heeft gemaakt). Ze moeten naar hun juiste geografische netwerken verplaatst worden. Printix moet deze netwerken eerst kennen. Bij de normale SNMP scan wordt alles per netwerk gescanned, ook automatisch, je kan deze later aanpassen.

### Hoeveel netwerken?
Alle actuele sites

### Hoe je netwerken aanmaakt:

1. **Ga naar Networks tab:**
   - rechtermenu → "**Networks**"

2. **Voor elk netwerk uit de tabel hieronder:**

   **Klik "Add Network"** en vul in:
   - **Network Name:** (Exacte naam uit de tabel! bijv. "Soudal Turnhout Print")
   - **Subnet**
   - **Description:** (Optioneel - gebruik "Land: Locatie" bijv. "België: Turnhout")
   - Klik **"Save"**

3. **Herhaal voor alle netwerken**

### FASE 2B: Netwerk Tabel - Kopieer & Plak

De actuele lijst van netwerken (sites) binnen Soudal die in Printix moeten staan, gebaseerd op de officiële Site Codes:

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
MS Azure - Datawarehouse (MSAZDW)
Ms Azure - SAP PCE - DR (MSAZSD)
Ms Azure - SAP PCE (MSAZSP)
Azure, Soudal (MSAZWE)
Tlalnepantla de Baz, Soudal (MXTLSO)
Soudal Manufacturing BV, Bergen op Zoom (NLBZSO)
Frencken, Weert (Legacy) (NLWEE1)
Frencken, Weert (NLWEFR1)
Soudal, Tranby (NOTRSO1)
Hamilton, Soudal (NZHASO)
Lima, Soudal (PELISO)
Soudal, Czosnow (PLCZSO1)
Bochem, Pionki (PLPIBO)
Soudal, Pionki (Legacy) (PLPIO1)
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
Istanbul, Soudal (Legacy) (TRIS1)
Istanbul, Soudal (Legacy 2) (TRIS2)
Istanbul, Soudal (TRISSO1)
Istanbul, Warehouse, Soudal (TRISWH)
Soudal, Tamworth (Centurion Road) (UKTASO1)
Soudal, Tamworth (Centurion Road) (UKTAWH)
Accumetric Elizabethtown (KY) (USETAM)
Johannesburg (ZAJBSO)
```

*(Opmerking: Netwerken zoals "7. Onbekend-Network", "32. Template Range 3" en "33. Template Range 4" in eerdere lijsten kunnen automatisch gegenereerd zijn tijdens netwerkscans of dit kunnen test-ranges (templates) zijn geweest waarmee tijdens de set-up werd geëxperimenteerd. Deze kunnen worden genegeerd of opgeschoond.)*

**TIP:** Als sommige networks al bestaan, kun je die overslaan. Printix zal zeggen "Network already exists".

**Status na stap 2:**  Alle actuele sites zijn aangemaakt in Printix

---

##  FASE 3: Printers Verplaatsen van Network2 naar Juiste Netwerk (niet nodig voor IT team)

Dit is het tijdintensieve deel.

### De Strategie:

Omdat alle printers nu in **Network2** zitten voor het testen, en we ze op basis van **IP-adres** naar het juiste netwerk moeten verplaatsen, gaan we dit doorgaan per netwerk-groep. Dir kan je ook laten doen door het script zelf, als je de netwerken op voorhand weet en hebt aangemaakt in Printix.


### Stap-voor-Stap Instructie:

#### VOOR ELKE NETWERK-GROEP (herhaal dit 33x):

1. **Open het Printers scherm:**
   - Logisch: https://soudal.printix.net/admin → "Printers" tab

2. **Filter op Current Network = "Network2":**
   - Zet een filter aan met: Network = Network2
   - (Kijk voor een filter-icoon in het kopje)

3. **Zoek alle printers voor deze netwerk-groep:**
   - Open de CSV `printer-network-migrations-needed.csv` naast je browser
   - Filter op "CorrectNetwork" = (bijv. "Soudal Turnhout Print")
   - Noteer welke IP-ranges het zijn (bijv. 10.0.10.0 - 10.0.10.255)

4. **In Printix - Selecteer alle printers van die groep:**
   - Klik handmatig op de checkbox van elke printer, OF
   - Selecteer alle checkboxes van printers met die IP-range

   **TIPS VOOR SNELLER SELECTEREN:**
   - Sorteer op "Address"
   - Alle 10.0.10.xxx zullen nu bij elkaar staan
   - Klik alle checkboxes van die groep

5. **Bulk Edit - Verplaats naar juiste netwerk:**
   - Met de printers geselecteerd → Klik het menu (3 puntjes) of zoek naar "Bulk Edit"
   - Selecteer het netwerk veld
   - Kies het **juiste netwerk** (bijv. "Soudal Turnhout Print")
   - Klik **Save**

6. **Herhaal stap 3-5 voor elk netwerk:**
   - Soudal, Turnhout (BETUSO)
   - Soudal, Czosnow (PLCZSO1)
   - TKK, Srpenica - NEW (SISRTK)
   - etc.

**Timing:** ~3-5 minuten per netwerk-groep = **enkele uren werk** afhankelijk van het aantal actieve sites met printers.

---

## 👥 FASE 4: Groepen Synchroniseren (Azure AD)

### Wat gaat dit doen?
Dit laadt alle Azure AD groepen (afdelingen) in Printix, zodat je later automatisch printers toe kan wijzen aan groepen gebruikers.

### Hoe je dit doet:

1. **Ga naar het Groups scherm:**
   - rechter → "**Groups**"

2. **Klik "Synchronize groups":**
   - Er verschijnt een blauwe knop
   - Klik erop
   - Het systeem zal alle Azure AD groepen inladen (duurt enkele minuten)

3. **Verificatie:**
   - Nadat het klaar is, zie je alle azure groepen van soudal.

**Status na stap 4:**  Azure AD groepen zijn gesynchroniseerd

---

##  FASE 5: Auto-Toewijzing van Printers aan Gebruikersgroepen

### Wat gaat dit doen?
Werknemers (bijv. in Azure AD groep "Turnhout") krijgen AUTOMATISCH alle printers van hun filiaal geïnstalleerd op hun laptop. 

### Hoe je dit doet (Handmatige UI Methode):

> [!WARNING]
> **Belangrijke UI Beperking:** Hoewel je in het 'Printers' menu printers in bulk aan een netwerk kunt toewijzen, kun je daar **geen** groepen koppelen. Dat moet je doen via het 'Groups' menu. Het vervelende van de UI is dat je in het 'Add print queue' scherm **niet** kunt filteren op Netwerk, alleen op naam of IP (Address).

1. **Ga naar het Groups scherm:**
   - Hoofdmenu (drie streepjes rechtsboven) → "**Groups**"

2. **Selecteer de doelgroep:**
   - Klik op de groep waaraan je printers wilt toewijzen (bijv. `soudal_turnhout_print` of `Turnhout`).

3. **Automatisch toevoegen activeren:**
   - Zodra de printers geselecteerd zijn, vink je aan de rechterkant de optie **Add print queue automatically** aan.
   - Klik op **Save** (of Confirm).



**Status na stap 5:**  Printers zijn automatisch beschikbaar voor gebruikers per locatie

---

##  FASE 6: User Testing (Is normaal al in orde)

### Waarom?
Voordat je 1000+ werknemers gaat bereiken, moet je zorgen dat alles werkend is.

### Hoe je test:

1. **Pak een STANDAARD werknemer-laptop** (niet jouw server!)

2. **Download Printix Client:**
   - Ga naar: https://soudal.printix.net/download (of in de admin portal → Software tab)
   - Download: `PrintixClient.msi`
   OR gewoon dubbelklik en volg de wizard

3. **Log in met Azure AD account:**
   - Gebruik een echte werknemer-account (bijv. j.smith@soudal.com)
   - Printix vraagt om login
   - Accept the permissions

4. **Test printer toevoegen:**
   - Klik op het Printix icoon (rechtsonder in taakbalk)
   - Klik "Add printer"
   - Zoek naar één van de printers die je net hebt verplaatst
   - Voeg toe

5. **Test afdrukken:**
   - Geopend Kladblok → Print
   - Selecteer de Printix printer
   - Klik Print
   - Controleer of het papier aankomt op de echte printer

**Wat moet werken:**
-  Login met Azure AD
-  Automatische printer-suggesties verschijnen
-  Print-job wordt verzonden
-  Printer ontvangt het

---

##  FASE 7: Mass Deployment via Intune 

> [!IMPORTANT]
> Deze fase valt momenteel buiten de scope van de stage en is de verantwoordelijkheid van het Soudal IT-team.

### Wat is het doel?
De Printix Client (`.msi`) automatisch installeren op alle beheerde werkstations van Soudal, zodat werknemers direct kunnen printen zodra ze inloggen.

### Vereisten
- De `.msi` installer, te downloaden via: `https://soudal.printix.net/download`
- Toegang tot **Microsoft Intune** 

### Methode A: Via Microsoft Intune (Aanbevolen)
De `.msi` wordt verpakt als een **Win32 App** (via de Microsoft Win32 Content Prep Tool) en vervolgens in het Intune Admin Center toegevoegd als Windows-app. Na toewijzing aan een Azure AD apparaatgroep wordt de client automatisch op alle laptops geïnstalleerd binnen de volgende sync-cyclus.

Of je download het simpelweg via de company portal.



### Resultaat na uitrol
Zodra de client is geïnstalleerd en de werknemer inlogt met zijn Soudal-account, registreert de computer zich automatisch in de Printix Portal. Op basis van het netwerk (gateway) herkent Printix de locatie en worden de juiste printers automatisch geïnstalleerd. De werknemer kan direct printen via `CTRL+P` zonder verdere configuratie bij de meest gebruikte printers. Voor de andere printers zal hij deze manueel moeten adden via de Client (2 minuten werk).
---

---

##  TROUBLESHOOTING

### Probleem: Network bestaat niet/kan niet toevoegen
**Oplossing:** Zorg dat de netwerknaam exact gelijk is aan die in de mapping CSV

### Probleem: Printers verdwijnen niet uit Network2
**Oplossing:** Refresh de pagina (F5) na Bulk Edit. Soms werkt het in 1-2 minuten

### Probleem: Werknemers kunnen Printix app niet downloaden
**Oplossing:** Controleer dat ze met Azure AD account ingelogd zijn op de laptop

### Probleem: Een geïnstalleerde werknemer-laptop verschijnt niet onder "Computers" / "Software Identifier" Fout
**Oplossing (De Software Identifier Oorzaak):** Bij Printix is de software die je downloadt *uniek* gebonden aan jouw specifieke omgeving (tenant). 
Als een collega de software downloadt via `soudal.printix.net/download` (Productie) in plaats van jouw specifieke test-portaal `soudal-test.printix.net/download`, verschijnt hij nóóit in jouw admin-panel en krijgt hij verkeerde printers (zoals printers uit Nieuw-Zeeland) te zien.
**Actie:** Laat hem de huidige client lokaal verwijderen en opnieuw downloaden via de exacte link in jouw *soudal-test* Printix Administrator-dashboard onder 'Download Printix Client'.

### Probleem: Gebruikers blijven "Site Manager" rechten houden na verwijderen van een locatie
**Oorzaak:** Printix 'onthoudt' soms de rol-toewijzing als een Site wordt gewist zonder eerst de gekoppelde groepen te ontkoppelen.
**Oplossing:** Maak een nieuwe tijdelijke Site aan, koppel de betreffende groep opnieuw als Site Manager, verwijder de groep daarna handmatig uit de Site-instellingen, en verwijder pas dán de Site weer.

### Probleem: Printers verschijnen in de Printix client met een sterretje (★) en een MUP share-naam
**Oorzaak:** Tijdens de Printix PoC werd vastgesteld dat printers die via een PowerShell-script werden geregistreerd in Microsoft Universal Print, zichtbaar verschenen in de Printix client met een sterretje (★) en hun MUP share-naam. Dit is geen bug of integratiefout: de Printix client was geïnstalleerd op dezelfde machine waarop het script de MUP-printers lokaal had geïnstalleerd via Windows. De Printix client toont standaard alle lokaal geïnstalleerde Windows-printers, ongeacht hun oorsprong. Het sterretje is de manier waarop Printix aangeeft dat een printer niet via zijn eigen systeem werd toegevoegd.
**Oplossing:** Verwijder de betreffende printers via *Windows Instellingen → Bluetooth en apparaten → Printers en scanners* op die machine.


### Probleem: Print-job werkt niet
**Oplossing:**
- Controleer dat de printer online staat in Printix portal
- Probeer print-job opnieuw vanuit Printix app

---

##  STATISTIEKEN

**Totaal te verplaatsen:** 435 printers  
**Aangepaste netwerken:** 33  
**Verwachte tijdsinvestering:** 2-3 uur  
**Testing:** 30 minuten  

---

##  NOTITIES

*Bijgewerkt: 3 April 2026*  
*Versie: 1.0 - Finalisatie Checklist*  
