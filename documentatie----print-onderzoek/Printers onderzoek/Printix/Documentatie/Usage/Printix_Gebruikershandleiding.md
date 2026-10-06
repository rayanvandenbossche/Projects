# Printix Gebruikershandleiding 
## Soudal Group — Voor Admins & Eindgebruikers

---

# DEEL 1: Handleiding voor de IT-Beheerder (Admin)

## 1.1 Inloggen op de Admin Portal

1. Open een browser en ga naar: `https://soudal.printix.net/admin`
2. Log in met je Microsoft Soudal-account (Entra ID / Azure AD).
3. Je komt nu op het **Dashboard** terecht met een overzicht van printers, gebruikers en recente activiteit.

**Navigatie:** Alle menu-opties bereik je via het **hoofdmenu** (de drie streepjes rechtsboven). Van hieruit kun je navigeren naar Printers, Networks, Groups, Users, Computers, Settings, etc.

---

## 1.2 Printers Beheren

### Een nieuwe printer toevoegen (Automatisch via Discovery)
1. Ga via het hoofdmenu naar **Printers**.
2. Klik op **Discover printers** (bovenaan).
3. Printix stuurt een scan-opdracht naar de Printix Client die op een computer in het lokale netwerk draait. Deze scant het netwerk via SNMP en rapporteert alle gevonden printers terug naar de cloud.
4. Na enkele minuten verschijnen de gevonden printers in de lijst.

### Een printer beschikbaar maken voor gebruikers (Print Queue aanmaken, automatisch en anders op deze manier)
Alleen printers met een **Print Queue** zijn zichtbaar voor werknemers.
1. Ga naar **Printers** in het hoofdmenu.
2. Selecteer één printer via de vinkjes, geef een naam.
3. Klik op **Add print queue** (bovenaan de lijst).
4. De printers zijn nu beschikbaar voor gebruikers in de Printix Client.

### Printers toewijzen aan een netwerk (Locatie, automatisch en anders op deze manier)
Printers moeten aan het juiste netwerk gekoppeld zijn zodat gebruikers op die locatie ze automatisch zien.
1. Ga naar **Printers** in het hoofdmenu.
2. Filter op IP-bereik (bijv. `10.0.10.`) om alle printers van één locatie te selecteren.
3. Vink de gewenste printers aan.
4. Klik op **Modify** (onderaan de lijst).
5. Wijzig het **Network** veld naar het juiste netwerk (bijv. "Turnhout").
6. Klik op **Save**.

> **Let op:** Wijzig netwerken altijd via het menu **Printers** (fysieke hardware), NIET via Print Queues. Dit is een veelgemaakte fout.

---

## 1.3 Netwerken Configureren

### Een nieuw netwerk aanmaken
1. Ga via het hoofdmenu naar **Networks**.
2. Klik op **Add network**.
3. Vul de naam in (bijv. "Soudal Turnhout").
4. Voeg het **Gateway & MAC-adres** toe van de router op die locatie.

### Meerdere VLANs koppelen aan één netwerk
Als een locatie meerdere VLANs heeft (bijv. een server-VLAN en een gebruikers-VLAN), moeten alle gateways worden toegevoegd:
1. Open het bestaande netwerk.
2. Voeg extra **Subnets** toe met de gateway MAC-adressen van elk VLAN.
3. Hierdoor herkent Printix laptops in álle VLANs als behorend tot dezelfde locatie.

> **Belangrijk:** Als je een gateway vergeet toe te voegen, worden laptops in dat VLAN niet herkend door Printix en krijgen ze geen printers te zien.

---

## 1.4 Groepen & Automatische Toewijzing

### Azure AD Groepen synchroniseren
1. Ga via het hoofdmenu naar **Groups**.
2. Klik op **Synchronize** (linksboven).
3. Alle Azure AD groepen worden nu geladen in Printix.

### Printers automatisch toewijzen aan een groep
1. Ga naar **Groups** en selecteer de gewenste groep (bijv. `soudal_turnhout_print`).
2. Klik op het tabblad **Print queues**.
3. Klik op **Modify** of **Add**.
4. Selecteer de printers die je wilt toewijzen.
5. Vink aan: **"Add print queue automatically"** — Hierdoor wordt de printer automatisch geïnstalleerd op de laptops van alle groepsleden.
6. Optioneel: Vink aan **"Set as default printer"** voor de belangrijkste printer.
7. Optioneel: Vink aan **"Remove print queue automatically"** — Hierdoor wordt de printer verwijderd als de gebruiker het netwerk verlaat.
8. Klik op **Save**.

### Aanbevolen strategie (Hybride Deployment)
- **Core printers** (2–3 per locatie): Automatisch pushen via groepen of netwerken.
- **Overige printers**: Niet automatisch pushen; werknemers voegen ze zelf toe via de Client als dat nodig is.

---

## 1.5 Gebruikers & Rollen Beheren

### Rollen in Printix
| Rol | Rechten |
|:---|:---|
| **User** | Standaardgebruiker. Kan printers toevoegen en afdrukken. |
| **Site Manager** | Kan printers en instellingen beheren voor een specifieke locatie. |
| **System Manager** | Volledige admin-rechten over de gehele Printix-omgeving. |

### Een gebruiker bekijken of aanpassen
1. Ga via het hoofdmenu naar **Users**.
2. Zoek de gebruiker op naam of e-mailadres.
3. Klik op de gebruiker om de **User Properties** te openen.
4. Hier kun je de rol wijzigen, de gekoppelde groepen bekijken, en de loginhistorie inzien.

### Computers controleren
1. Ga via het hoofdmenu naar **Computers**.
2. Hier zie je alle apparaten waarop de Printix Client is geïnstalleerd.
3. Check bij elke computer welk **Network** eraan is gekoppeld — dit bepaalt welke printers de gebruiker ziet.

> **Troubleshooting:** Als een gebruiker geen printers ziet, controleer eerst of zijn computer in deze lijst staat. Staat hij er niet? Dan is de client niet correct geïnstalleerd of is de verkeerde tenant-URL gebruikt.

---

## 1.6 Secure Print (Print Anywhere) Configureren

### Wat is het?
Secure Print zorgt ervoor dat documenten pas worden afgedrukt wanneer de gebruiker zich fysiek bij de printer identificeert. Dit voorkomt dat vertrouwelijke documenten onbeheerd op de printer liggen.

### Hoe werkt het?
1. De gebruiker print naar de wachtrij **"Printix Anywhere"** (standaard geïnstalleerd).
2. Het document wordt versleuteld opgeslagen in de Printix Cloud.
3. De gebruiker gaat naar de fysieke printer en opent de Printix App op zijn smartphone (of de webApp op `/app`).
4. De gebruiker klikt op **Release** bij het gewenste document.
5. Het document wordt nu pas fysiek afgedrukt.

### Instelling controleren
- Ga naar een **Print Queue** en controleer dat **"Exempt from secure print"** NIET is aangevinkt. Als dit wel aanstaat, omzeilt die specifieke printer de beveiligde wachtrij.

---

## 1.7 Rapportages & Analytics

### Dashboard bekijken
1. Ga via het hoofdmenu naar **Home** of **Dashboard**.
2. Hier zie je een overzicht van recente printopdrachten, actieve printers en gebruikersactiviteit.

### Power BI Integratie
Printix biedt een standaard Power BI-template (`.pbit`) waarmee je diepgaande rapportages kunt maken:
- Printvolume per afdeling of vestiging
- Kleur vs. zwart-wit verhouding
- Kosten per gebruiker
- Milieu-impact (papierverbruik, CO2-voetafdruk)

De data wordt ontsloten via een cloud-gebaseerde SQL-database die je kunt koppelen aan een eigen Azure SQL-instantie voor langdurige opslag.

---

## 1.8 Veelvoorkomende Admin-Problemen

| Probleem | Oorzaak | Oplossing |
|:---|:---|:---|
| Gebruiker ziet geen printers | Computer staat niet onder "Computers" | Client opnieuw installeren via `soudal-test.printix.net/download` |
| Gebruiker ziet verkeerde printers (andere locatie) | Verkeerde tenant-URL gebruikt bij installatie | Client verwijderen en via de juiste URL opnieuw downloaden |
| Laptop wordt niet herkend als "Turnhout" | Gateway van het gebruikers-VLAN ontbreekt in het netwerkprofiel | Gateway toevoegen aan het netwerk in de portal |
| Print-job blijft "Pending" | Printer niet bereikbaar vanuit het VLAN van de gebruiker | "Via the cloud" aanzetten in de Print Queue instellingen |
| Gebruiker behoudt "Site Manager" rol na verwijderen van een Site | Orphaned Role bug in Printix | Tijdelijke Site aanmaken, groep opnieuw koppelen, expliciet verwijderen, Site wissen |

---

## 1.9 Geavanceerd Driver- en Configuratiebeheer

Voor een wereldwijde vloot zoals die van Soudal is het cruciaal dat printerinstellingen (zoals papierformaat, kleurinstellingen en lades) consistent zijn.

### Drivers & Configuraties instellen (Vergrendelen)
Dit is de basis voor regio-specifieke instellingen (bijv. papierformaat Letter voor China).

1.  **Lokaal voorbereiden:** Op een computer met de Printix Client installeer je de betreffende printer. Ga naar de **Afdrukvoorkeuren** in Windows en stel alles exact in zoals gewenst (bijv. Papier: Letter, Kleur: Uit).
2.  **Uploaden:**
    *   Ga in de portal naar **Printers** > [Kies printer] > **Print queues** > [Kies wachtrij] > Tabblad **Drivers**.
    *   Klik op het plusje (+) bij **Add a new configuration**.
    *   Kies **Upload from computer** en selecteer de computer die je zojuist hebt ingesteld.
3.  **Vergrendelen:** Zodra de configuratie is geüpload, wordt deze geselecteerd. De driver-status staat nu op **Locked**. Gebruikers kunnen deze instellingen nu niet meer per ongeluk overschrijven.

### Bulk-actie: "Distribute print queue configuration"
Gebruik dit om een perfecte instelling van één "Master" printer te kopiëren naar alle andere printers van hetzelfde model.

1.  Open de "Master" printer in de portal.
2.  Klik bovenaan op de knop **Distribute print queue configuration**.
3.  **Doelwachtrijen selecteren:** Vink in de lijst alle andere printers/wachtrijen aan die dezelfde instellingen moeten krijgen.
4.  **Distribute:** Klik op de bevestigingsknop. Alle geselecteerde printers krijgen nu exact dezelfde driver en configuratie gepusht.

> **Let op:** Gebruik dit bij voorkeur enkel voor printers van hetzelfde merk/model om compatibiliteitsproblemen te voorkomen.

### Drivers in bulk updaten
Als er een nieuwe driver-versie beschikbaar is voor een specifiek printermodel (bijv. HP LaserJet E50145):

1.  Ga naar het tabblad **Drivers** bij één willekeurige printer van dat model.
2.  Klik op de naam van de huidige driver onder **Print driver**.
3.  Zoek de nieuwe driver in de lijst (of upload een nieuwe .inf).
4.  Bij het opslaan vraagt Printix: *"Do you want to update all print queues using this model?"*.
5.  Kies **Yes**. Printix werkt nu wereldwijd alle wachtrijen bij die dat specifieke model gebruiken.

## 1.10 Microsoft Integraties Activeren

### Universal Print Koppeling
1. Ga naar **Settings** > **Integrations** > **Microsoft Universal Print**.
2. Klik op **Accept** om de koppeling met de Azure tenant te bevestigen.
3. Je kunt nu bij de instellingen van een specifieke **Print Queue** kiezen voor "Publish to Universal Print".

#### Belangrijk: Sharenames en Universal Print
In de standaard Printix-omgeving werk je **niet** met Sharenames (`\\printer`). De printers worden direct beheerd door de Client. 

Alleen wanneer je de **Universal Print Koppeling** gebruikt, maakt Microsoft in de Azure Portal een "Printer Share" aan. Dit is de enige plek waar je de term "Share Name" nog zult tegenkomen (bijv. voor specifieke Microsoft Cloud rapportages).

### Scan to OneDrive/SharePoint
1. Ga naar **Settings** > **Integrations** > **Cloud Storage**.
2. Klik op **Grant access** bij Microsoft OneDrive of SharePoint.
3. Gebruikers kunnen nu via de Printix App op de printer direct scannen naar hun cloud-opslag.

## 1.11 names Printix

#### Technische Specificaties voor de CSV
De CSV moet de volgende kolommen bevatten (hoofdlettergevoelig):

| Kolomnaam | Uitleg | Voorbeeld |
|:---|:---|:---|
| **Printer ID** | De unieke 3-letterige code van de printer (ankerpunt). | `ASD` |
| **Printer name** | De naam van de fysieke printer in het dashboard. | `HP LaserJet E50145` |
| **Print queue name** | **BELANGRIJK:** Vul hier de oude sharename in. | `CN_PRT_01` |
| **Print driver** | Exacte naam van de driver in Printix. | `HP Universal Printing PCL 6` |
| **Comment** | Optioneel veld voor extra migratie-info. | `Migratie vanaf Server01` |

**Belangrijke regels voor het invullen:**
1.  **Printer ID:** Zonder dit ID kan Printix de printer niet hernoemen. Gebruik de ID's uit je initiële export.
2.  **Geen spaties in headers:** De eerste regel moet exact overeenkomen met bovenstaande namen.
3.  **Scheidingsteken:** Gebruik een **komma (,)**. Let op bij Excel (Nederlands) dat je opslaat als "CSV (door komma's gescheiden)" en niet als puntkomma-gescheiden.
4.  **Driver Match:** De driver-naam moet exact overeenkomen met de naam in het dashboard.

#### Import-stappen in de Configurator:
1. Open de **Printix Configurator**.
2. Ga naar het tabblad **print queueu - Import**.
3. Selecteer het CSV-bestand.
4. Kies actie: **Update existing printers/queues**.
5. Klik op **Start**.
6. Gebruik daarna de knop **Update print queue on computers** (zie sectie 1.11) om de namen direct op de PC's van de gebruikers te corrigeren naar de oude vertrouwde namen.

> *Tip: Maak altijd een backup-export van je huidige instellingen vóórdat je een bulk-import start.*

## 1.12
 Printix GO Configuratie & Installatie (Stap-voor-stap)

Printix GO is de "beveiligingsschil" op de printer zelf. Omdat de software direct communiceert met de hardware van de printer, moet de activatie per apparaat gebeuren.

### Stap 1: Het "Sign in profile" aanmaken
Dit bepaalt **HOE** de gebruiker zich identificeert bij de machine.
1. Ga naar **Settings** > **Printix GO**.
2. Klik op het plusje (+) bij **Sign in profiles**.
3. Vul een naam in (bijv. `Soudal_Badge_Pincode`) en een technisch wachtwoord.
4. **Belangrijk:** Klik na het opslaan op het tandwiel-icoontje bij dit profiel en vink **Card (badge)** en/of **ID code (pincode)** aan. Zet *Card registration* op **Enable**.

### Waarom Card Registration activeren? (Admin info)
Door **Card registration** op *Enable* te zetten, hoeft IT geen badge-nummers handmatig in te voeren. Het systeem "leert" de pas zodra de gebruiker deze de eerste keer scant. Dit is veilig (cryptografische hash) en werkt direct samen met de accountstatus in Azure AD.

> **Soudal Context:** Hoewel badge-authenticatie technisch is ingericht, is de beslissing genomen om dit voor de algemene kantooromgeving **niet te activeren**. Gebruikers loggen standaard in met hun persoonlijke pincode.

### Stap 2: De "Go configuration" aanmaken
Dit bepaalt **WAT** de gebruiker mag doen op het touchscreen.
1. Klik op het plusje (+) bij **Go configurations**.
2. Geef het een naam (bijv. `Standaard_MFP_Functies`).
3. Selecteer de functies die je wilt toestaan (meestal staat *Print* op Yes).
4. Gebruik de **slot-icoontjes** onder *Access control* om functies zoals kopiëren of scannen te vergrendelen achter de inlog.

### Stap 3: Activatie op de fysieke printer
Nu koppelen we de bouwstenen uit stap 1 en 2 aan de printer.
1. Ga naar het menu **Printers** en selecteer de gewenste printer.
2. Open het tabblad **Printix Go**.
3. Koppel de profielen:
   - Kies bij **Go configuration** het profiel uit Stap 2.
   - Kies bij **Sign in profile** het profiel uit Stap 1.
4. Voer het **Administrator password** van de fysieke printer in (web-interface wachtwoord).
5. Klik op **Install**. De printer downloadt de software en herstart met de nieuwe beveiligde interface.

**Controle:** Zodra de installatie voltooid is, verschijnt er een groen 'GO' icoontje bij de printer in het dashboard. De machine is nu beveiligd en klaar voor gebruik.

---
---

# DEEL 2: Handleiding voor de Eindgebruiker (Werknemer)

## 2.1 Wat is Printix?

Printix is de nieuwe cloud-printoplossing van Soudal. Het vervangt de oude manier van printen (via lokale printservers) door een moderne, eenvoudige aanpak. Je hoeft geen drivers te installeren of de helpdesk te bellen — alles werkt automatisch via je Soudal Microsoft-account.

---

## 2.2 De Printix Client Installeren (Of zie apart document Company Portal)

> In de meeste gevallen wordt de Printix Client automatisch op je laptop geïnstalleerd via Intune. Als dat niet het geval is:

1. Open een browser en ga naar: `https://soudal.printix.net/download`
2. Download het bestand `PrintixClient.msi`.
3. Dubbelklik op het bestand en volg de installatie-wizard.
4. Na de installatie verschijnt er een **blauw printericoontje** in je taakbalk (rechtsonder).
5. Klik op het icoontje en log in met je **Soudal Microsoft-account** (dezelfde als voor Outlook/Teams).

---

## 2.3 Printen — De Basis

### Stap 1: Een document printen
1. Open het document dat je wilt afdrukken (Word, PDF, Excel, etc.).
2. Druk op **CTRL + P** (of ga naar Bestand → Afdrukken).
3. Kies een printer uit de lijst. Je ziet automatisch de printers van jouw kantoorlocatie.
4. Klik op **Afdrukken**. Klaar!

### Welke printers zie ik?
- **Automatisch geïnstalleerde printers:** De 2–3 belangrijkste printers van jouw kantoor worden misschien automatisch op je laptop gezet. Je hoeft niets te doen.
- **Printix Anywhere:** Een speciale "wachtrij" voor beveiligd printen (zie sectie 2.5).

---

## 2.4 Extra Printers Toevoegen (Self-Service)

Heb je een specifieke printer nodig die niet standaard op je laptop staat? Je kunt deze zelf toevoegen:

1. Klik op het **blauwe Printix-icoontje** in je taakbalk (rechtsonder).
2. Klik op **Printers** of **Add printer**.
3. Je ziet een overzicht van alle beschikbare printers op jouw locatie.
4. Klik op de printer die je nodig hebt.
5. De printer wordt direct geïnstalleerd. Je kunt er nu naar printen via CTRL + P.

---

## 2.5 Beveiligd Printen (Print Anywhere / Secure Print)

Wil je een vertrouwelijk document afdrukken zonder dat het zomaar op de printer blijft liggen? Gebruik dan **beveiligd printen**:

### Versturen
1. Open je document en druk op **CTRL + P**.
2. Kies de printer **"Printix Anywhere"** uit de lijst.
3. Klik op **Afdrukken**. Het document wordt nu veilig opgeslagen in de cloud — er rolt nog niets uit de printer!

### Vrijgeven (bij de printer)
1. Loop naar de printer waar je wilt afdrukken.
2. Open de **Printix App** op je smartphone (beschikbaar in de App Store / Google Play).
   - Of ga op je telefoon naar: `https://soudal.printix.net/app`
3. Log in met je Soudal-account.
4. Je ziet je wachtende document(en) in de lijst.
5. Selecteer de printer waar je naast staat.
6. Tik op **Print** of **Release**.
7. Het document wordt nu pas afgedrukt. Niemand anders heeft het kunnen zien!

---

## 2.6 Printen vanaf je Smartphone (Doe momenteel alleen via de browser, de app werkt niet goed)

1. Download de **Printix App** uit de App Store (iOS) of Google Play Store (Android).
2. Log in met je Soudal Microsoft-account.
3. Open een document, foto of e-mailbijlage op je telefoon.
4. Tik op **Delen** → kies **Printix**.
5. Selecteer de printer en tik op **Print**.

---

## 2.7 Veelgestelde Vragen (FAQ)

### Ik zie geen printers in mijn lijst?
- Controleer of je bent ingelogd in de Printix Client (klik op het blauwe icoontje rechtsonder).
- Controleer of je verbonden bent met het kantoornetwerk (Wi-Fi of kabel).
- Als je op afstand werkt (VPN): sommige printers zijn alleen beschikbaar op kantoor.

### Mijn print-opdracht komt niet aan bij de printer?
- Controleer of je de juiste printer hebt geselecteerd.
- Als je **Printix Anywhere** hebt gebruikt, moet je het document nog **vrijgeven** bij de printer (zie sectie 2.5).
- Probeer opnieuw te printen. Lukt het nog niet? Neem contact op met de IT-helpdesk.

### Hoe verwijder ik een printer die ik niet meer nodig heb?
1. Ga naar **Windows Instellingen** → **Bluetooth en apparaten** → **Printers en scanners**.
2. Klik op de printer die je wilt verwijderen.
3. Klik op **Verwijderen**.

### Ik heb de verkeerde Printix Client geïnstalleerd (ik zie printers uit een ander land)?
1. Verwijder de huidige Printix Client via **Windows Instellingen** → **Apps** → zoek "Printix" → **Verwijderen**.
2. Download de juiste client opnieuw via: `https://soudal-test.printix.net/download`
3. Installeer en log opnieuw in met je Soudal-account.

### Kan ik dubbelzijdig of in zwart-wit printen?
Ja! Bij het afdrukken via CTRL + P kun je in de printerinstellingen kiezen voor:
- **Dubbelzijdig (Duplex):** Bespaart papier.
- **Zwart-wit (Grijswaarden):** Bespaart dure kleurentoner.

---

## 2.8 Je Soudal-badge koppelen (Eénmalig & Printix GO)

Je kunt je personeelspas gebruiken om in te loggen op de printer. De eerste keer moet je deze koppelen aan je account:

1. **Scannen:** Houd je badge tegen de kaartlezer van de printer.
2. **Melding:** Het scherm toont "Unknown card. Do you want to register?". Tik op **Register**.
3. **Identificeren:** Log eenmalig in op het scherm met je Soudal e-mail en wachtwoord (of je persoonlijke pincode uit de Printix portal).
4. **Koppeling voltooid:** Printix koppelt nu je badge aan je account. Vanaf nu hoef je alleen nog maar je pas te scannen om direct je documenten te zien en vrij te geven.

---

*Handleiding opgesteld op 23 april 2026 — Soudal Group*
*Voor vragen: neem contact op met de IT-helpdesk.*
