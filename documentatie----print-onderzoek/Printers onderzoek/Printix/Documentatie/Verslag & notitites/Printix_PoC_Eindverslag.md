# Printix Proof of Concept — Eindverslag 
## Soudal Group | April 2026
### Opgesteld door: Rayan (Stagiair Infrastructuur)

---

## 1. Managementsamenvatting

Dit verslag presenteert de resultaten van een twee weken durende **Proof of Concept (PoC)** met **Printix** (Tungsten Automation) als cloud-gebaseerde printoplossing voor de Soudal Group. Het doel was om te evalueren of Printix een geschikte vervanging is voor de huidige lokale printserver-gebaseerde printomgeving, in het kader van Soudal's migratie naar **Microsoft Entra ID (Azure AD)** en **Intune**.

### Conclusie
Printix is **geschikt** als cloud-printoplossing voor Soudal. Alle kritieke functionaliteiten — van automatische printerdetectie tot beveiligd printen — zijn succesvol gevalideerd in een productie-achtige omgeving met echte hardware en echte gebruikers. De oplossing biedt significante voordelen ten opzichte van de huidige printserver-gebaseerde aanpak, met name op het gebied van schaalbaarheid, gebruiksgemak en centraal beheer. Er zijn wel aandachtspunten rondom de leercurve voor IT-beheerders en de afhankelijkheid van een correcte netwerkconfiguratie.

---

## 2. Projectcontext

### 2.1 Probleemstelling
Soudal Group beheert **600+ printers** verspreid over meer dan 30 wereldwijde vestigingen. De huidige situatie kent de volgende pijnpunten:
*   **Geen centraal overzicht:** Geen realtime zicht op welke printers actief zijn, wat hun tonerstatus is, of welke servicecontracten lopen.
*   **Verouderde deployment:** Printers worden momenteel aangemaakt op een (lokale) printserver. Gebruikers kunnen de printer zelf toevoegen op hun computer door naar de sharenaam van de printserver te navigeren en daar de gewenste printer te installeren. Met de migratie naar Entra ID en Intune is deze methode niet langer houdbaar.
*   **Handmatig beheer:** Het toevoegen, verwijderen of verplaatsen van printers vereist handmatige interventie door IT op elke locatie. (Opmerking: Eindgebruikers kunnen printers echter wel zelf toevoegen zonder actie van IT, zolang ze al op de server staan).
*   **Geen self-service:** Werknemers kunnen niet zelfstandig een printer toevoegen; ze zijn afhankelijk van de helpdesk.

### 2.2 Doelstelling PoC
Vaststellen of Printix in staat is om:
1.  Alle Soudal-printers wereldwijd te ontdekken en centraal te beheren vanuit één cloud-portaal.
2.  Printers automatisch toe te wijzen aan werknemers op basis van hun fysieke locatie (netwerk/gateway).
3.  Een veilige "Print Anywhere" (pull printing) functionaliteit te bieden.
4.  Rapportages te leveren over printvolume, kosten en duurzaamheid.
5.  Naadloos te integreren met Microsoft Entra ID (Azure AD) voor authenticatie en groepsbeheer.

### 2.3 Testomgeving
*   **Locatie:** Soudal Turnhout (Everdongenlaan 18-20, 2300 Turnhout)
*   **Tenant:** `soudal-test.printix.net` (aparte test-omgeving)
*   **Hardware:** Diverse Ricoh, HP LaserJet, Zebra printers,... op het Turnhout-kantoor
*   **Netwerk:** Gesegmenteerd VLAN-netwerk met aparte subnets voor servers en gebruikers
*   **Gebruikers:** 5 testgebruikers (stagiaires + collega) met Microsoft Entra ID accounts

---

## 3. Uitgevoerde Werkzaamheden

### Week 1: Infrastructuur & Bulk Import

#### A. SNMP Netwerkscan
Omdat Printix's eigen "Cloud Discovery" niet werkt zonder vooraf geïnstalleerde clients op elke locatie, hebben we een **op maat gemaakt PowerShell SNMP-scanscript** (`snmp_scanner.ps1`) ontwikkeld.
*   **Bereik:** 31.231 IP-adressen gescand over alle wereldwijde subnets.
*   **Techniek:** Parallelle verwerking via PowerShell Runspaces (multithreading) voor snelheid.
*   **Resultaat:** **429 unieke printers** geïdentificeerd en geëxporteerd naar een Printix-compatibele CSV.

#### B. CSV Import & Validatie
De gegenereerde CSV is succesvol geüpload via de **Tungsten Printix Configurator**. Hierbij zijn de volgende technische uitdagingen opgelost:

| Probleem | Oplossing |
|:---|:---|
| Ongeldige CSV (verkeerd kolomaantal) | Script aangepast naar exact 7 verplichte kolommen |
| Rode validatievelden (Vendor/Network) | Velden bewust leeg gelaten; Printix accepteert "Unmapped" printers |
| Parser crash op speciale tekens | RegEx-filter toegevoegd voor niet-alfanumerieke karakters in modelnamen |
| Dubbele printers door overlappende subnets | Automatische ontdubbeling via `Sort-Object Address -Unique` |

#### C. Initiële Printix Configuratie
*   Printix Client geïnstalleerd op een testserver in Turnhout.
*   Eerste succesvolle testprint uitgevoerd via de cloud.
*   Architecturale keuzes vastgelegd (zie Sectie 4).

#### D. Blokkade: Admin Consent
De koppeling met Microsoft Entra ID vereiste **Global Administrator**-rechten. Een formeel verzoek is ingediend (zie `Azure_AD_Permissies_Verzoek.md`) en goedgekeurd aan het einde van Week 1.

---

### Week 2: Validatie & User Acceptance Testing

#### A. Entra ID Integratie (Maandag)
*   **Global Admin permissies** succesvol geaccepteerd in de Printix Portal.
*   Alle **Azure AD groepen** gesynchroniseerd naar Printix.
*   Printix Client lokaal getest: catalogus met 400+ wereldwijde printers direct zichtbaar.

#### B. Discovery & Netwerk Configuratie (Dinsdag)
*   **Discovery Flow** gevalideerd: de Printix Server in Turnhout voerde succesvol automatische SNMP-scans uit.
*   **Gateway Routing Probleem ontdekt en opgelost:** Laptops in een ander VLAN (met een andere gateway) werden niet herkend door Printix. Door de gateway van het gebruikers-VLAN toe te voegen aan het netwerkprofiel in de portal, herkent Printix nu ook laptops en kunnen zij de printers zien.
*   **Automatische Deployment getest:** Printers verschijnen foutloos en automatisch op de laptop van een werknemer zodra deze worden toegewezen aan de Client.

#### C. User Acceptance Testing (Woensdag)
*   **Software Identifier Fout ontdekt:** Bij het testen met een tweede gebruiker bleek dat deze de client had gedownload via de verkeerde tenant-URL (`soudal.printix.net` in plaats van `soudal-test.printix.net`). De Printix Client is uniek gebonden aan de tenant; een verkeerde download leidt tot registratie in een andere omgeving. Na herinstallatie met de juiste URL werkte alles vlekkeloos.
*   **Succesvolle UAT met collega:** De collega kon na de correcte installatie direct de Turnhout-printers zien en succesvol een document afdrukken.
*   **Hybride Deployment Strategie vastgelegd:** De optimale werkwijze voor Soudal is bepaald:
    1.  *Core Printers:* De 2–3 meest gebruikte printers per locatie worden automatisch gepusht admin panel.
    2.  *Self-Service:* Alle overige printers blijven in de cloud beschikbaar. Werknemers voegen ze zelf toe via de Printix Client als dat nodig is.
*   **Secure Print (Print Anywhere) gevalideerd:** Een document is verstuurd naar de generieke "Printix Anywhere" wachtrij en vervolgens handmatig vrijgegeven via de werknemers-webApp (`/app`). Het document werd pas fysiek afgedrukt op het moment van vrijgave.
*   **Rapportages & Analytics gevalideerd:** Alle test-printopdrachten worden correct geregistreerd in de portal. Data over gebruiker, printer en volume is direct inzichtelijk.
*   **Orphaned Roles Bug ontdekt:** Bij het verwijderen van een Site in de portal bleven gebruikers onterecht de rol "Site Manager" behouden. Opgelost door een tijdelijke Site aan te maken, de groep opnieuw te koppelen en daarna expliciet te verwijderen.

#### D. Evaluatie & Afronding (Donderdag)
*   **Printix AI-functies geëvalueerd:** De ingebouwde generatieve AI is niet bijzonder nuttig. De geavanceerde OpenAI/Azure-integratie vereist een apart abonnement met API-credits dat Soudal niet heeft.
*   **MSI Deployment onderzocht:** De `.msi` installer is gedownload en de uitrolmethoden (Intune Win32 App + GPO) zijn gedocumenteerd als overdracht voor het Soudal IT-team.
*   **Power BI Integratie onderzocht:** Printix biedt een standaard Power BI-template (`.pbit`) waarmee printdata kan worden gevisualiseerd in managementdashboards (kostenbesparingen, gebruikersgedrag, milieu-impact).

---

## 4. Architecturale Bevindingen

### 4.1 Locatiebepaling via Gateway (Niet via AD Groepen)
De belangrijkste architecturale ontdekking van deze PoC:

> **Printix bepaalt de locatie van een gebruiker niet op basis van Active Directory groepen, maar op basis van het fysieke netwerk (Gateway MAC-adres).**

Dit betekent dat Soudal geen honderden locatie-specifieke AD-groepen hoeft aan te maken of te onderhouden. Zodra een medewerker zijn laptop aansluit op het kantoornetwerk van Turnhout, herkent Printix automatisch via de gateway dat hij zich in Turnhout bevindt en biedt de juiste printers aan.

**Aandachtspunt:** Alle gateways van alle VLANs op een locatie moeten als subnet worden toegevoegd aan het netwerkprofiel in de portal. Als dit niet correct is geconfigureerd, worden laptops in dat VLAN niet herkend.

### 4.2 Cloud Discovery vs. Centrale CSV Import
Printix's "Cloud Discovery" is afhankelijk van lokale clients die de scan uitvoeren. Voor een organisatie als Soudal met 30+ wereldwijde locaties is het onhaalbaar om eerst overal een client te installeren vóór de initiële configuratie.

**Een test oplossing:** Een centraal PowerShell SNMP-script dat alle printers scant en exporteert naar CSV, waarna deze in bulk worden geüpload via de Printix Configurator. Dit omzeilt de Discovery-beperking volledig, maar dit vraagt wel een beetje werk, elke printer moet ana het juiste netwerk toegevoegd worden.

### 4.3 Hybride Deployment Model
De optimale strategie voor Soudal combineert twee methoden:

| Methode | Doel | Voorbeeld |
|:---|:---|:---|
| **Automatische Push (via Netwerk)** | De 2–3 belangrijkste printers per locatie worden **automatisch en dynamisch** gepusht op basis van het fysieke netwerk. Dit gebeurt enkel voor laptops die zich op dat moment in het netwerk van die specifieke locatie bevinden, en niet globaal voor iedereen (bijv. wie naar Frankrijk reist krijgt daar de Franse printers, en de Turnhout printers worden dan verborgen/verwijderd). | De grote Ricoh copier in de gang |
| **Self-Service (via Client)** | Alle overige printers zijn beschikbaar in de cloud; werknemers voegen ze zelf toe als dat nodig is | Een speciale labelprinter op de verzendafdeling |

> **Verduidelijking Automatische Push:** De automatische push gebeurt **dynamisch op basis van locatie (netwerk)**, niet globaal voor iedereen. 
> * Als een gebruiker van Turnhout naar Soudal Frankrijk reist en zijn laptop daar verbindt met het netwerk, detecteert de Printix Client de nieuwe locatie.
> * De 2–3 belangrijkste printers van Frankrijk worden dan automatisch *toegevoegd* aan de laptop.
> * Printix ruimt ook netjes op: de printers van de vorige locatie (Turnhout) die via deze automatische push waren geïnstalleerd, worden in principe *verborgen of verwijderd* zolang de gebruiker zich niet in Turnhout bevindt. Dit voorkomt dat elke laptop na verloop van tijd wordt overladen met tientallen onnodige printers uit verschillende landen.

### 4.4 Geavanceerd Driver- en Configuratiebeheer
Een cruciaal onderdeel voor de stabiliteit van de Soudal printomgeving is het consistent houden van driver-instellingen (zoals papierformaat, lades, en kleurinstellingen).

*   **Configuratie Vergrendeling (Locking):** IT kan specifieke afdrukvoorkeuren (bijv. geforceerd zwart-wit of een specifiek papierformaat) instellen op een computer met de Printix Client en deze vervolgens uploaden als de "Master" configuratie. Door deze te vergrendelen (**Locked**), kunnen gebruikers de instellingen niet per ongeluk overschrijven met lokale, foutieve drivers.
*   **Bulk Distributie:** Met de functie **"Distribute print queue configuration"** kan een geoptimaliseerde configuratie van één "Master printer" in bulk worden gepusht naar alle andere printers van hetzelfde model. Dit bespaart enorm veel tijd bij het uitrollen van nieuwe locaties.
*   **Wereldwijde Driver Updates:** Bij het updaten van een driver voor één printermodel, biedt Printix de optie om dit direct door te voeren voor alle wachtrijen die dat specifieke model gebruiken. Dit garandeert een uniforme driver-versie over de hele wereldvloot van Soudal.

### 4.5 Microsoft Ecosysteem Integraties
Een belangrijk aspect van Printix is de nauwe samenwerking met bestaande Microsoft-diensten binnen Soudal.

#### A. Microsoft Universal Print Integratie
Printix kan fungeren als een bridge/connector voor Microsoft Universal Print. 
*   **Werking:** Printers vanuit Printix worden "gepubliceerd" naar Universal Print. Hierdoor verschijnen ze als native cloud-printers in de Windows-instellingen, zonder dat de Printix Client strikt noodzakelijk is voor de ontdekking.
*   **Voordeel:** Biedt een native Windows-ervaring en ondersteunt apparaten waarop geen software geïnstalleerd mag worden.
*   **Nadeel (Licenties):** Universal Print heeft vaak een limiet op het aantal print-jobs per maand (bijv. een gepoold volume van 5 tot 100 printopdrachten per gebruiker per maand, afhankelijk van de exacte Microsoft-licentie). Printen via de Printix Client zelf blijft echter onbeperkt.

#### B. Scan to Cloud (OneDrive & SharePoint)
Door Printix (via Entra ID) toegang te verlenen tot OneDrive en SharePoint, wordt "Scan to Cloud" geactiveerd.
*   **Workflow:** Gebruikers kunnen documenten scannen bij de fysieke printer, waarna deze direct in hun persoonlijke OneDrive of een gedeelde SharePoint-map van hun afdeling worden geplaatst. Dit elimineert de noodzaak voor onveilige "Scan to Email" of lokale netwerkshares. De koppeling verloopt hierbij via de Printix GO applicatie op de printer en het Printix Cloud portaal; er is geen aparte koppeling nodig op de web-interface van de printer zelf, zolang de IT-administrator de Microsoft Graph API-rechten heeft goedgekeurd.

### 4.6 Centraal Beheer vs. Lokale Uitvoering
Een cruciaal concept binnen Printix is dat het dashboard fungeert als de "blauwdruk", maar de daadwerkelijke uitvoering lokaal op de PC van de gebruiker plaatsvindt.

*   **De PC als uitvoerder:** Wanneer een beheerder in het dashboard een driver-versie aanpast of een configuratie (zoals papierformaat of lades) vergrendelt, voert de Printix Client op de laptop van de gebruiker de wijziging door in de lokale Windows-printinstellingen.
*   **Realtime Synchronisatie:** De laptops van gebruikers "kijken" constant naar het dashboard. Zodra er een wijziging is, wordt deze binnen enkele ogenblikken automatisch toegepast op de lokale PC.
*   **Fysieke Integriteit:** Belangrijk is dat de fysieke printer (het apparaat in de gang) zelf niet verandert. Printix beheert uitsluitend de manier waarop de PC van de medewerker met die printer communiceert. Dit geeft IT volledige controle over de werkomgeving zonder dat ze de hardware hoeven te herconfigureren.

### 4.7 Serverloze Architectuur: Het einde van "Sharenames"
In de traditionele Soudal-omgeving werkte IT met paden als `\\Sharenaam`. In Printix bestaat dit concept niet meer.

*   **Serverloos:** Omdat Printix geen centrale printserver vereist, zijn er geen traditionele "Shares" meer op het netwerk. De communicatie verloopt direct tussen de PC en de printer (via de cloud-blauwdruk).
*   **De uitzondering (Universal Print):** Er is één scenario waarin Sharenames wél terugkeren: de integratie met Microsoft Universal Print. Wanneer een Printix-wachtrij wordt gepubliceerd naar Universal Print, maakt Microsoft in het Azure-portaal een officiële "Printer Share" aan. Deze krijgen meestal de toevoeging **(UP)**. Dit is uitsluitend relevant voor beheerders die printers via de native Microsoft-cloud willen beheren.

### 4.8 Printix GO: Beveiliging op het apparaat
Printix GO is een software-extensie die direct op de fysieke printer (MFP) wordt geïnstalleerd. Waar de Printix Client de communicatie op de computer regelt, verzorgt Printix GO de intelligentie en beveiliging op het bedieningspaneel van de printer zelf.

#### Kernfunctionaliteiten
*   **Secure Print Release (Follow-me Printing):** Documenten worden niet direct geprint, maar vastgehouden in een beveiligde wachtrij. De gebruiker loopt naar een willekeurige printer en geeft de opdracht daar pas vrij na fysieke identificatie.
*   **User Authentication (Badge & Pincode):** Gebruikers identificeren zich via een pincode of een RFID-toegangspas (badge). Dankzij **"Self-Registration"** hoeft IT geen badge-nummers handmatig in te voeren; de gebruiker koppelt zijn pas eenmalig zelf bij de eerste scan door in te loggen met zijn Microsoft-gegevens.
*   **Beveiligd Scannen (Scan-to-Workflow):** Printix GO herkent wie er ingelogd is en biedt gepersonaliseerde scan-opties, zoals Scan to Email of direct naar de eigen OneDrive/SharePoint map.
*   **Copy Control:** Het blokkeren van de kopieerfunctie voor onbevoegden om kosten te besparen en misbruik te voorkomen.

> **Opmerking Soudal Strategie:** Hoewel Printix GO badge-authenticatie volledig ondersteunt, is de huidige inschatting dat Soudal voor de algemene kantooromgeving **geen gebruik zal maken van een fysiek badge-systeem**. De focus ligt op pincode-authenticatie of mobiele release. Printix GO blijft echter een waardevolle optie voor high-security zones (zoals R&D) waar strikte toegangscontrole op MFP's vereist is.

#### Voordelen voor de organisatie
1.  **Privacy & Compliance (GDPR):** Geen gevoelige documenten (zoals contracten of loonstroken) die onbeheerd in de opvangbak blijven liggen.
2.  **Kostenbesparing:** Voorkomt "vergeten" printjes. Volgens algemene marktcijfers uit de industrie wordt ongeveer 20% van alle printopdrachten nooit opgehaald en na een ingestelde tijd (bijv. 24 uur) automatisch door Printix GO verwijderd.
3.  **Gebruiksgemak:** Gebruikers hoeven niet na te denken over naar welke printer ze sturen; ze lopen naar de dichtstbijzijnde machine en halen daar hun werk op.
4.  **Centraal Beheer:** Alle scans en prints worden gelogd, wat inzicht geeft in het verbruik per afdeling of locatie.

#### Technisch verschil: Printix Anywhere vs. Printix GO
*   **Printix Anywhere** is de wachtrij waar de gebruiker naar print op de computer.
*   **Printix GO** is de interface op de printer waarmee die wachtrij wordt geopend.

---

## 5. Testresultaten — Samenvattingstabel

| Testscenario | Status | Toelichting |
|:---|:---:|:---|
| SNMP Bulk Scan (31.000+ IP's) | ✅ | 429 printers succesvol geïdentificeerd |
| CSV Import naar Printix Cloud | ✅ | Na oplossing van parser- en validatiefouten |
| Entra ID (Azure AD) Integratie | ✅ | Groepen gesynchroniseerd, SSO werkt |
| Automatische Printer Discovery | ✅ | Server scant en ontdekt printers via SNMP |
| Gateway / VLAN Routing | ✅ | Opgelost door alle gateways toe te voegen aan het netwerkprofiel |
| Auto-Deployment via Groepen | ✅ | Printers verschijnen automatisch op de laptop |
| Auto-Deployment via Netwerk | ✅ | Printers verschijnen op basis van locatie (gateway) |
| User Acceptance Test (Eigen PC) | ✅ | Afdruk succesvol via CTRL+P |
| User Acceptance Test (Collega) | ✅ | Na correctie van de tenant-URL werkte alles vlekkeloos |
| Secure Print / Print Anywhere | ✅ | Document vrijgegeven via webApp, daarna fysiek geprint |
| Rapportages & Analytics | ✅ | Printdata correct geregistreerd en visueel inzichtelijk |
| Power BI Integratie | ✅ | Template beschikbaar; eigen Azure SQL mogelijk voor langdurige opslag |
| Printix AI-functies | ⚠️ | Basis-AI niet nuttig; geavanceerde AI vereist apart abonnement |
| Mass Deployment (MSI/Intune) | 📋 | Gedocumenteerd als overdracht voor Soudal IT, als er tijd over is helpen wij hier mee |

---

## 6. Evaluatie: Is Printix Geschikt voor Soudal?

### 6.1 Voordelen (Sterktes)

| Voordeel | Toelichting |
|:---|:---|
| **Volledig serverless** | Elimineert de noodzaak voor lokale printservers op alle vestigingen |
| **Locatie-gebaseerd printen** | Werknemers krijgen automatisch de juiste printers op basis van hun fysieke locatie, zonder AD-groepenbeheer |
| **Hybride deployment** | Combinatie van automatische push (core printers) en self-service (overige printers) biedt maximale flexibiliteit |
| **Secure Print (Pull Printing)** | Vertrouwelijke documenten worden pas geprint wanneer de gebruiker ze fysiek vrijgeeft bij de printer |
| **Centraal cloud-dashboard** | Eén overzicht voor alle 600+ printers wereldwijd, inclusief status, toner en rapportages |
| **Entra ID integratie** | Naadloze SSO met bestaande Microsoft-accounts; geen aparte inloggegevens nodig |
| **Kostenrapportages** | Inzicht in printvolume per afdeling, vestiging en gebruiker via het dashboard en Power BI |
| **Vendor-agnostic** | Ondersteunt alle grote merken (HP, Ricoh, Brother, Zebra, Canon) zonder merk-specifieke beperkingen |
| **Schaalbaar** | Nieuwe locaties worden organisch toegevoegd zodra daar een client wordt geïnstalleerd |

### 6.2 Nadelen / Aandachtspunten

| Nadeel | Toelichting |
|:---|:---|
| **Steile leercurve** | De Printix-architectuur wijkt sterk af van traditionele printservers. Zelfs de officiële helpdesk gaf soms incorrect advies (bijv. focussen op Print Queues i.p.v. fysieke Printers). Dit vereist een gerichte training voor het Soudal IT-team. |
| **Kip-en-ei probleem bij discovery** | Automatische discovery werkt alleen als er al een client op de locatie draait. Voor de initiële opzet van 30+ locaties is een workaround nodig (zoals onze CSV-import). |
| **Netwerkconfiguratie kritiek** | Alle VLAN-gateways moeten correct worden toegevoegd aan de Printix-portaal. Een ontbrekende gateway betekent dat laptops in dat VLAN niet worden herkend. |
| **Tenant-specifieke client** | De gedownloade client is uniek gebonden aan de tenant-URL. Een verkeerde download (bijv. `soudal.printix.net` i.p.v. `soudal-test.printix.net`) leidt tot registratie in een verkeerde omgeving. Dit is een veelvoorkomende fout bij de uitrol. |
| **Abonnementskosten** | Printix vereist een maandelijks abonnement per gebruiker, bovenop de bestaande Microsoft-licenties. |
| **AI-functies beperkt** | De ingebouwde AI is niet nuttig zonder een apart OpenAI/Azure-abonnement. |


### 6.3 Kostenanalyse: Printix Licenties

Printix hanteert een transparant **per-gebruiker, per-maand** prijsmodel. In tegenstelling tot veel andere oplossingen, zijn er enkele belangrijke voordelen in de kostenstructuur:

*   **Geen limiet op printers:** Je betaalt niet per printer. Of Soudal nu 5 of 500 printers toevoegt, de prijs blijft uitsluitend gebaseerd op het aantal gebruikers.
*   **Geen limiet op volume:** Je betaalt niet per geprinte pagina. Er is geen limiet op de hoeveelheid documenten die worden verwerkt.
*   **De "PUPY" regel:** De kosten bedragen circa **€ 12,- Per User Per Year (PUPY)**. Dit is een vast bedrag per jaar voor het totale aantal gebruikers.

#### Prijsoverzicht

#### Prijsoverzicht (Soudal Specifiek)

Soudal heeft een vast tarief overeengekomen voor de wereldwijde uitrol:

| Model | Prijs | Toelichting |
|:---|:---|:---|
| **PUPY (Per User Per Year)** | **€12,-** / gebruiker / jaar | Facturatie op jaarbasis voor het totale aantal gelicentieerde gebruikers. |
| **Volume** | Onbeperkt | Geen extra kosten per geprinte pagina of per printer. |

#### Kostenschatting voor Soudal (2.500 gebruikers)

Soudal heeft wereldwijd naar schatting **~2.500 actieve gebruikers**. Op basis van het overeengekomen PUPY-tarief:

| Scenario | Gebruikers | Prijs per jaar | Totaal per jaar |
|:---|:---:|:---:|:---:|
| **Pilot Turnhout** | 50 | €12 | €600 |
| **België + NL** | 500 | €12 | €6.000 |
| **Wereldwijd (Soudal Group)** | 2.500 | €12 | **€30.000** |

> **Let op:** De genoemde bedragen zijn gebaseerd op de definitieve offerte van €12 PUPY voor 2.500 licenties.

#### Wat zit er inbegrepen?
- Onbeperkt aantal printers en printvolume.
- Volledige functionaliteit (Secure Print, Mobile Print, Analytics).
- Geen kosten voor servers, onderhoud of updates.
- Centralisatie van alle wereldwijde locaties in één portaal.

#### Wat kost het NIET gebruiken van Printix?
Ter vergelijking: het beheren van de huidige on-premises printservers brengt ook kosten met zich mee die vaak niet zichtbaar zijn:
- Hardwarekosten voor lokale printservers op elke vestiging
- IT-uren voor handmatig printerbeheer en troubleshooting
- Geen centraal inzicht in printkosten (verborgen verspilling)
- Helpdesk-belasting door handmatige printerinstallaties

### 6.4 Eindoordeel

Op basis van de twee weken durende PoC is het eindoordeel **positief**. Printix biedt een moderne, schaalbare en gebruiksvriendelijke oplossing die past bij Soudal's migratie naar een cloud-first infrastructuur. De voordelen (centraal beheer, automatische locatieherkenning, secure print, rapportages) wegen zwaarder dan de nadelen (leercurve, abonnementskosten).

**Aanbeveling:** Start een **pilot-uitrol** op de vestiging Turnhout met 20–50 gebruikers, waarbij het Soudal IT-team de MSI via Intune uitrolt en de eerste weken de helpdesk monitort voor onverwachte problemen.

---

## 7. Aanbevelingen voor Vervolgstappen

1.  **Power BI Dashboard:** Koppel de Printix SQL-database aan een Power BI-rapport voor managementrapportages.
2.  **Print Policies:** Configureer standaard duplex (dubbelzijdig) en zwart-wit printen om kosten en milieu-impact te reduceren.
3.  **Wereldwijde uitrol:** Alle 30+ vestigingen migreren naar Printix.
4.  **QR-Code Self-Service:** Stickers op printers plaatsen voor eenvoudige self-service installatie door werknemers.
5.  **Contractbeheer integratie:** Printix-rapportages koppelen aan bestaande servicecontracten voor proactief onderhoud.

---

## 8. Bijlagen & Referenties

### Projectbestanden
| Bestand | Beschrijving |
|:---|:---|
| `FINALISATIE_CHECKLIST_STAP_VOOR_STAP.md` | Operationeel draaiboek voor de volledige Printix-configuratie |
| `Wekelijks logboek/Printix_Logboek_Week1.md` | Gedetailleerd dagboek van Week 1 |
| `Wekelijks logboek/Printix_Logboek_Week2.md` | Gedetailleerd dagboek van Week 2 |
| `Azure_AD_Permissies_Verzoek.md` | Formeel verzoek voor Global Admin rechten |
| `Scripts/snmp_scanner.ps1` | Het SNMP-scanscript voor printer-inventarisatie |

### Printix Portal Toegang
*   **Admin Portal:** `https://soudal-test.printix.net/admin`
*   **Werknemers App:** `https://soudal-test.printix.net/app`
*   **Client Download:** `https://soudal-test.printix.net/download`

---

*Opgesteld op 23 april 2026 — Soudal Group, Turnhout*
*Auteur: Rayan (Stagiair Infrastructuur)*
