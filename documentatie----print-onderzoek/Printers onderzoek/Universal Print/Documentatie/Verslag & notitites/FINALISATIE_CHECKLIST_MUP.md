# MICROSOFT UNIVERSAL PRINT — FINALISATIE CHECKLIST 
**Stap voor Stap Uitrolhandleiding voor de Soudal IT-beheerder**

**Status:** `Afgerond (Evaluatie voltooid)`  
**Datum:** `12/05/2026`  
**Fase:** Finalisatie & Overdracht aan Soudal IT

---

##  VEREISTEN VOOR DE START

Zorg dat het volgende aanwezig is voordat je begint:

| Vereiste |
|:---|
| Microsoft 365-licenties verificatie (M365 E3, Business Premium, of UP Add-on) |
| Azure Portal toegang met **Universal Print Administrator** of **Global Administrator** rol  |
| Een Windows 10/11 of Windows Server 2016+ machine in Turnhout (voor de Connector)  |
| Uitgangsverkeer op poort **443** toegestaan naar `*.print.microsoft.com` en `*.azure.com` ` |
| De te registreren printers zijn **lokaal gedeeld** op de Connector-machine  |

> [!WARNING]
> **PIM-rol Activatie:** Als Soudal Privileged Identity Management (PIM) gebruikt (wat waarschijnlijk is bij Global Admin / Universal Print Admin rechten), moet je de rol **eerst activeren** via het Azure Portal of de PIM-app vóór je begint. De activatie kan 5–15 minuten duren en is tijdelijk (bijv. 1–8 uur actief). **Opmerking:** De RBAC-blokkades die tijdens de PoC werden ervaren, waren specifiek voor het beperkte stagiair-account — een volwaardige IT-admin zou hier geen hinder van moeten ondervinden.

---

##  FASE 1: Universal Print Connector Installeren ( Dit is gedaan voor ons)

### Wat is dit?
De **Universal Print Connector** is een brug tussen de Microsoft Azure-cloud en de fysieke printers in het Soudal-netwerk. Alleen vestigingen met legacy-printers (een minderheid bij Soudal) hebben een Connector nodig — het merendeel van de printerfloot is UP-ready en heeft geen Connector nodig.

### Stap-voor-Stap

1.  **Download de Connector:**
    *   Ga naar `https://aka.ms/UPConnector`
    *   Of via **Microsoft 365 Admin Center** → Settings → Org Settings → Universal Print → Download connector

2.  **Installeer op een geschikte machine in Turnhout:**
    *   Dubbelklik het installatiebestand.
    *   Volg de wizard. Wanneer gevraagd om aan te melden: gebruik het account met **Universal Print Administrator**-rechten.

3.  **Registreer de Connector:**
    *   Na de installatie opent de Connector-software.
    *   Klik **Register** en meld je aan bij je Soudal-tenant.
    *   De Connector krijgt een naam (bijv. `Connector-Turnhout`).

4.  **Verificatie in Azure Portal:**
    *   Ga naar `https://portal.azure.com`
    *   Zoek naar **Universal Print** → **Connectors**
    *    De Connector moet hier zichtbaar zijn met status **Active**.

**Status na Fase 1:** Connector actief en zichtbaar in Azure Portal

---

##  FASE 2: Printers Registreren via de Connector

### Wat is dit?
Elke printer die gebruikers moeten kunnen gebruiken, moet via de Connector worden "gepubliceerd" naar de Universal Print cloud.

### Vereiste voorbereiding
De printer moet **lokaal gedeeld** zijn op de Connector-machine:
```
Win + R → "printmgmt.msc" (Print Management)
Klik rechts op de printer → "Share this printer"
Geef een share-naam (bijv. "Ricoh_Turnhout")
```

### Stap-voor-Stap

1.  **Open de Connector-software** op de Connector-machine.
2.  Klik op het tabblad **Printers** of **Add Printers**.
3.  De lokaal gedeelde printers verschijnen in een lijst.
4.  Vink de gewenste printer(s) aan.
5.  Klik op **Publish** of **Register**.
6.  **Verificatie:** Ga in Azure Portal naar **Universal Print → Printers** → De printer moet hier zichtbaar zijn.

> [!NOTE]
> **Schaalbaarheid-opmerking:** Soudal heeft weinig legacy-modellen — het merendeel van de vloot is UP-ready. De Connector-registratie is dus alleen nodig voor een beperkt aantal printers. UP-ready printers registreren zichzelf direct in de cloud zonder Connector.

**Status na Fase 2:**  Printers zichtbaar in Azure Portal → Universal Print → Printers

---

##  FASE 3: Printer Shares Aanmaken

### Wat is dit?
Een "Printer Share" in MUP is het equivalent van een "Print Queue" in Printix. Pas nadat je een Printer Share aanmaakt en toewijst aan gebruikers, kunnen zij de printer vinden en gebruiken.

> [!IMPORTANT]
> **Kritisch verschil met Printix:** In Printix zijn printers direct beschikbaar na het aanmaken van een Print Queue. In MUP moet je expliciet een **Printer Share** aanmaken als aparte stap.

### Stap-voor-Stap

1.  **Ga naar Azure Portal → Universal Print → Printer Shares**
2.  Klik op **+ Add Printer Share**
3.  Vul in:
    *   **Printer Share Name:** (bijv. `Ricoh_Turnhout_01`) — Dit is de naam die gebruikers zien.
    *   **Printer:** Selecteer de geregistreerde printer uit de lijst.
    *   **Location:** Optioneel — voeg een fysiek adres of GPS-coördinaten toe zodat Windows de printers op afstand kan sorteren.
4.  Klik **Create**.

### Gebruikers toewijzen aan de Printer Share

5.  Open de zojuist aangemaakte Printer Share.
6.  Ga naar het tabblad **Members** of **Access**.
7.  Klik **Add Members** en voeg een **Azure AD-groep** toe (bijv. `Print_Turnhout`).
8.  Alle leden van deze groep kunnen nu deze printer zien en gebruiken.

> [!WARNING]
> **Beheer-overhead:** Voor 30+ Soudal-locaties betekent dit:
> - 30+ Azure AD-groepen aanmaken (bijv. `Print_Turnhout`, `Print_Heist`, `Print_Leverkusen`...)
> - Iedere werknemer handmatig toevoegen aan de juiste locatiegroep
> - Dit bijhouden wanneer werknemers van locatie veranderen
>
> **Bij Printix:** Geen enkel van bovenstaande stappen nodig — de gateway bepaalt automatisch de locatie.

> [!TIP]
> **Automatisering (PowerShell):** Bovenstaande stappen voor het aanmaken van shares, groepen en toewijzingen kunnen volledig geautomatiseerd worden. Zie de [Automatisatie Scripts (GitHub)](https://git.pefki.xyz/pefki/MS-UP-Soudal/src/branch/main/scripts) voor de benodigde PowerShell scripts om dit in bulk uit te voeren.

**Status na Fase 3:** Printer Shares aangemaakt en toegewezen aan de juiste groepen

---

##  FASE 4: Azure AD-groepen Aanmaken per Locatie

### Waarom is dit nodig bij MUP?
MUP heeft **geen netwerkgebaseerde locatiedetectie** (zoals Printix via gateway MAC-adressen). De enige manier om te bepalen welke printers een gebruiker ziet, is via Azure AD-groepslidmaatschap.

> [!NOTE]
> Dit zijn meer AD-groepen dan bij Printix nodig waren. Bij Printix waren groepen **uitsluitend** nodig voor de 2-3 "push"-printers per locatie — de rest was gateway-based. Bij MUP zijn groepen nodig voor **alle** printers op alle locaties.

**Status na Fase 4:**  Alle locatiegroepen aangemaakt in Entra ID

---

##  FASE 5: User Testing

### Hoe voegt een gebruiker een MUP printer toe?

**Methode A: Via Windows Instellingen (Aanbevolen)**
1.  Open **Windows Instellingen** → **Bluetooth en apparaten** → **Printers en scanners**
2.  Klik op **"Add a device"**
3.  Wacht enkele seconden — Windows zoekt automatisch naar Universal Print printers die beschikbaar zijn voor het account.
4.  De printer uit de Printer Share verschijnt in de lijst.
5.  Klik **Add**.
6.  De printer is nu geïnstalleerd en klaar voor gebruik via CTRL+P.

**Methode B: Via het Microsoft 365 Account Center**
1.  Ga naar `https://account.activedirectory.windowsazure.com`
2.  Log in met Soudal-account.
3.  Navigeer naar **Printers**.
4.  Klik op de printer om hem te installeren.


**Status na Fase 5:**  UAT geslaagd

---

##  FASE 6: Mass Deployment via Intune (Verantwoordelijkheid Soudal IT)

> [!IMPORTANT]
> Deze fase valt momenteel buiten de scope van de PoC/stage en is de verantwoordelijkheid van het Soudal IT-team.

### Hoe werkt automatische printer-deployement via Intune bij MUP?

In tegenstelling tot Printix (waar de client op de laptop de printers automatisch installeert), werkt MUP via **Intune Printer Policies**:

1.  Ga naar **Microsoft Intune Admin Center** → **Devices** → **Configuration Profiles**
2.  Maak een nieuw profiel aan: Platform = **Windows 10/11**, Profile type = **Administrative Templates** (of Settings Catalog)
3.  Zoek naar **"Universal Print"** of gebruik het **Printers CSP**
4.  Configureer welke Printer Shares automatisch geïnstalleerd moeten worden op apparaten in de groep.
5.  Wijs het profiel toe aan een **Apparaatgroep** of **Gebruikersgroep** in Intune.

> [!NOTE]
> **Alternatief:** Microsoft heeft ook een **Intune Universal Print app** beschikbaar die het printer-installatie-proces vereenvoudigt voor eindgebruikers die niet via Intune-policy worden bediend.

---

##  TROUBLESHOOTING

### Probleem: Connector is niet zichtbaar in Azure Portal
**Oorzaak:** De Connector-machine heeft geen internetverbinding op poort 443 naar de Microsoft-endpoints.  
**Oplossing:** Controleer de firewall. Voeg een uitzondering toe voor `*.print.microsoft.com`, `*.azure.com` en `login.microsoftonline.com`.

### Probleem: Printer verschijnt niet in Windows Instellingen
**Oorzaak 1:** De Printer Share is niet gekoppeld aan de Azure AD-groep van de gebruiker.  
**Oplossing:** Ga naar Azure Portal → Universal Print → Printer Shares → voeg de juiste groep toe.

**Oorzaak 2:** De gebruiker heeft geen geschikte Universal Print licentie.  
**Oplossing:** Controleer de licentie-toewijzing in het Microsoft 365 Admin Center.

### Probleem: Print-job blijft "Pending" / komt niet aan
**Oorzaak:** De Connector-machine staat offline of de Connector-service is gestopt.  
**Oplossing:** Herstart de "Universal Print Connector" service op de Connector-machine via `services.msc`.

### Probleem: "Printing is unavailable" / Pool leeg
**Oorzaak:** De tenant heeft de maandelijkse print job pool uitgeput (alle 100 jobs/user zijn verbruikt).  
**Oplossing:** Wachten tot de volgende maand (pool wordt automatisch gereset), of extra print jobs bijkopen via de Microsoft 365 Admin Center → Add-ons.

### Probleem: Gebruiker ziet printers van een andere locatie
**Oorzaak:** De gebruiker is lid van meerdere locatiegroepen, of de groepen zijn niet correct geconfigureerd.  
**Oplossing:** Controleer het Azure AD-groepslidmaatschap van de gebruiker via Entra ID Admin Center.

---

##  STATISTIEKEN

**Te registreren printers:** `600+ printers (Ricoh, HP, Brother)`  
**Locaties (Connectors nodig):** `30+ vestigingen wereldwijd`  
**Azure AD-groepen aan te maken:** `30+ groepen (één per locatie)`  
**Licenties geverifieerd:** `Microsoft 365 E5 (100 jobs) & F3 (5 jobs)`  

---

##  NOTITIES

Tijdens de Proof of Concept is gebleken dat Microsoft Universal Print een technisch stabiele oplossing is voor basis-printbehoeften binnen het Microsoft-ecosysteem. Voor een organisatie met de wereldwijde schaal van de Soudal Group ligt de beheerlast echter aanzienlijk hoger dan bij Printix, voornamelijk door het ontbreken van automatische locatiedetectie (gateway-based) en realtime SNMP-monitoring voor supplies en printerstatus.

---

*Bijgewerkt: 12/05/2026*  
*Versie: 1.1 — MUP Finalisatie Checklist*
