# Microsoft Universal Print — Gebruikershandleiding 
## Soudal Group — Voor Admins & Eindgebruikers

---

# DEEL 1: Handleiding voor de IT-Beheerder (Admin)

## 1.1 Inloggen op de Azure Portal

Microsoft Universal Print wordt volledig beheerd vanuit de **Azure Portal** — er is geen aparte admin-omgeving zoals bij Printix.

1.  Open een browser en ga naar: `https://portal.azure.com`
2.  Log in met je Soudal Microsoft-account (Entra ID / Azure AD) met **Universal Print Administrator**-rechten.
3.  Zoek in de zoekbalk bovenaan naar **"Universal Print"** of ga via: **All Services → Universal Print**.
4.  Je ziet het Universal Print dashboard met een overzicht van Printers, Connectors en Printer Shares.

> **Navigatie-tip:** Bookmark `https://portal.azure.com/#blade/Universal_Print` voor snelle toegang.

---

## 1.2 De Universal Print Connector Beheren

### Een Connector-status controleren
1.  Ga naar **Universal Print** → **Connectors**.
2.  Je ziet een lijst van alle geregistreerde Connectors per locatie.
3.  Controleer de **Status**-kolom:
    *   🟢 **Active:** De Connector werkt correct en heeft contact met de cloud.
    *   🔴 **Inactive:** De Connector-machine staat offline of de service is gestopt.

### Een Connector-service herstarten (bij problemen)
Als een Connector offline is, ga dan fysiek naar de machine of via Remote Desktop:
1.  Druk op `Win + R` → typ `services.msc` → Enter.
2.  Zoek naar **"Universal Print Connector"**.
3.  Klik rechts → **Restart**.

> **Let op:** Als een Connector-machine offline gaat, kunnen alle printers op die locatie **niet meer gebruikt worden** via Universal Print. Plan dus onderhoud van de Connector-machine buiten werkuren.

---

## 1.3 Printers Beheren

### Een nieuwe printer registreren
1.  Open de **Universal Print Connector-software** op de Connector-machine van de locatie.
2.  Zorg dat de printer **lokaal gedeeld** is op die machine (via Print Management → rechts klikken → Share).
3.  In de Connector-software: klik op **Add Printer** → selecteer de gedeelde printer → klik **Publish**.
4.  De printer is nu zichtbaar in **Azure Portal → Universal Print → Printers**.

### Een printer beschikbaar maken voor gebruikers (Printer Share)
Printers zijn **niet** direct zichtbaar voor gebruikers — je moet eerst een **Printer Share** aanmaken:
1.  Ga naar **Universal Print → Printer Shares** → klik **+ Add Printer Share**.
2.  Vul een naam in (bijv. `Ricoh_Turnhout_Gang`).
3.  Selecteer de geregistreerde printer.
4.  Klik **Create**.
5.  Open de Printer Share → tabblad **Members** → klik **Add Members** → voeg de juiste Azure AD-groep toe.

> **Let op:** Dit is het grootste architecturele verschil met Printix. Bij Printix is een printer beschikbaar via netwerk-locatie (gateway). Bij MUP moet een printer expliciet worden gedeeld met de juiste groep.

### Een printer verwijderen of offline halen
1.  Ga naar **Universal Print → Printers** → selecteer de printer.
2.  Klik op **Unregister** of **Delete**.
3.  Verwijder ook de bijbehorende Printer Share(s).

---

## 1.4 Azure AD-groepen & Toegangsbeheer

### Waarom zijn AD-groepen cruciaal in MUP?
In MUP wordt de locatie van een gebruiker **niet** automatisch gedetecteerd via het netwerk (zoals Printix dit doet via gateway MAC-adressen). De enige manier om te bepalen welke printers een gebruiker ziet, is via Azure AD-groepslidmaatschap.

**Aanbevolen groepsstructuur voor Soudal:**

| Groepsnaam | Leden | Printer Shares |
|:---|:---|:---|
| `Print_Turnhout` | Alle medewerkers in Turnhout | Alle printers in Turnhout |
| `Print_Heist` | Alle medewerkers in Heist | Alle printers in Heist |
| `Print_Leverkusen` | Alle medewerkers in Leverkusen | Alle printers in Leverkusen |
| ... | ... | ... |

### Een gebruiker aan een locatiegroep toevoegen
1.  Ga naar `https://entra.microsoft.com` (Entra ID Admin Center).
2.  Navigeer naar **Groups** → zoek de groep (bijv. `Print_Turnhout`).
3.  Ga naar het tabblad **Members** → klik **+ Add members** → zoek de gebruiker → klik **Select**.

> **Beheer-tip:** Als een medewerker van locatie verandert, moet IT:
> 1.  De medewerker **verwijderen** uit de oude locatiegroep (bijv. `Print_Turnhout`).
> 2.  De medewerker **toevoegen** aan de nieuwe locatiegroep (bijv. `Print_Heist`).
> 3.  De Windows-instellingen op het apparaat updaten (oude printers handmatig verwijderen).
>
> **Bij Printix:** Dit alles is automatisch — de gateway van het nieuwe netwerk detecteert de nieuwe locatie.

---

## 1.5 Licenties Controleren & Beheren

### Print Job Pool monitoren
Universal Print werkt met een **print job pool** — elke gebruiker heeft recht op een vast aantal print jobs per maand.

1.  Ga naar `https://admin.microsoft.com` (Microsoft 365 Admin Center).
2.  Navigeer naar **Billing → Your products → Universal Print** (of zoek naar "Universal Print").
3.  Hier zie je het totale verbruik van de tenant en de resterende pool.

### Licenties controleren per gebruiker
1.  Ga naar **Microsoft 365 Admin Center → Users → Active users**.
2.  Klik op een gebruiker → tabblad **Licenses and apps**.
3.  Controleer of **Universal Print** als feature is aangevinkt binnen de licentie.

> **Waarschuwing:** Gebruikers zonder een geschikte licentie (M365 E3, Business Premium, of Universal Print Add-on) kunnen **geen** gebruik maken van Universal Print, ook al zijn printers aan hun groep toegewezen.

---

## 1.6 Rapportages & Analytics

### Basisrapportages in Azure Portal
1.  Ga naar **Universal Print → Usage**.
2.  Hier zie je:
    *   Aantal print jobs per dag, week, maand.
    *   Verbruik per gebruiker.
    *   Verbruik per printer.

> **Vergelijking met Printix:** De rapportages in MUP zijn basisinformatie. Printix biedt uitgebreidere rapportages inclusief Power BI-integratie, kostenanalyse per afdeling, kleur vs. zwart-wit verhouding, en milieu-impact (CO2-voetafdruk). MUP biedt dit niet standaard.

---

## 1.7 Veelvoorkomende Admin-Problemen

| Probleem | Oorzaak | Oplossing |
|:---|:---|:---|
| Gebruiker ziet geen printers | Niet lid van de juiste Azure AD-groep | Gebruiker toevoegen aan de locatiegroep in Entra ID |
| Printer staat "Offline" in Azure Portal | Connector-machine is offline of service gestopt | Herstart "Universal Print Connector" service op de Connector-machine |
| Print-job blijft "Pending" | Connector offline of firewall blokkeert verbinding | Controleer Connector-status en firewall-regels (poort 443) |
| "Printing unavailable" foutmelding | Print job pool is leeg | Wacht tot volgende maand of koop extra jobs bij |
| Gebruiker ziet printers van de verkeerde locatie | Verkeerd groepslidmaatschap | Controleer en corrigeer groepslidmaatschappen in Entra ID |
| Printer Share niet zichtbaar voor gebruiker | Licentie ontbreekt of Share niet correct toegewezen | Controleer licentie en Share-instellingen |

---

## 1.8 Beperkingen van Microsoft Universal Print

> [!WARNING]
> De volgende functionaliteiten die in **Printix** beschikbaar zijn, zijn **NIET** beschikbaar in Microsoft Universal Print:

| Feature | Beschikbaar in MUP? | Alternatief/Opmerking |
|:---|:---:|:---|
| **Geavanceerd driver management** (lock, distribute) | ❌ | Handmatig per PC via Windows |
| **Automatische locatiedetectie via netwerk/gateway** | ❌ | Groepen per locatie aanmaken |
| **Badge-authenticatie op printers** | ❌ | Vereist Printix GO of vergelijkbaar |
| **Power BI / uitgebreide analytics** | ❌ | Basisrapportages beschikbaar |
| **SNMP-gebaseerde printer-inventaris** | ❌ | Niet ingebouwd |
| **Toner-level monitoring** | ❌ | Niet beschikbaar |

---

# DEEL 2: Handleiding voor de Eindgebruiker (Werknemer)

## 2.1 Wat is Microsoft Universal Print?

Microsoft Universal Print is de nieuwe cloudprint-oplossing van Soudal. Het is rechtstreeks geïntegreerd in je bestaande Windows-computer en je Microsoft-account. Je hebt **geen extra software** nodig om te printen — alles werkt via de standaard Windows-instellingen.

---

## 2.2 Een Printer Toevoegen

### Via Windows Instellingen (Aanbevolen)

1.  Klik op het **Start-menu** en open **Instellingen** (het tandwiel-icoontje).
2.  Ga naar **Bluetooth en apparaten** → **Printers en scanners**.
3.  Klik op **"Add a device"** (of "Een apparaat toevoegen").
4.  Windows zoekt automatisch naar beschikbare printers. Je ziet de printers die jouw IT-afdeling voor jou beschikbaar heeft gesteld.
5.  Klik op de gewenste printer en klik **Add device**.
6.  De printer is klaar voor gebruik!

> **Zie je geen printers?** Controleer of je verbonden bent met het Soudal-netwerk (Wi-Fi of kabel). Neem contact op met de IT-helpdesk als er nog steeds geen printers zichtbaar zijn.

---

## 2.3 Printen — De Basis

### Een document afdrukken
1.  Open het document (Word, PDF, Excel, etc.).
2.  Druk op **CTRL + P**.
3.  Selecteer de juiste printer uit de lijst.
4.  Klik op **Afdrukken**.

---

## 2.4 Veelgestelde Vragen (FAQ)

### Ik zie geen printers in de lijst?
*   Controleer of je bent ingelogd met je Soudal Microsoft-account op je laptop.
*   Controleer of je verbonden bent met het kantoornetwerk (Wi-Fi of kabel).
*   Ga naar **Instellingen → Bluetooth en apparaten → Printers en scanners** en klik op **"Add a device"** om te zoeken.
*   Neem contact op met de IT-helpdesk als er geen printers verschijnen.

### Mijn print-opdracht komt niet aan?
*   Controleer of de printer aanstaat en niet in "slaapstand" staat.
*   Controleer of je de juiste printer hebt geselecteerd.
*   Probeer opnieuw te printen. Lukt het niet? Meld het bij de IT-helpdesk.

### Hoe verwijder ik een printer die ik niet meer nodig heb?
1.  Ga naar **Windows Instellingen → Bluetooth en apparaten → Printers en scanners**.
2.  Klik op de printer.
3.  Klik op **Remove**.

### Kan ik dubbelzijdig of in zwart-wit printen?
Ja! Via **CTRL + P** → **Printerinstellingen** kun je kiezen voor:
*   **Dubbelzijdig (Duplex):** Bespaart papier.
*   **Zwart-wit (Grijswaarden):** Bespaart kleurentoner.

### Wat is het verschil met Printix?
Printix had een apart blauw icoontje in de taakbalk. Met Universal Print is alles geïntegreerd in de standaard Windows-instellingen. Je hoeft geen extra software te installeren of te onderhouden.

---

*Handleiding opgesteld op 12 mei 2026 — Soudal Group*
*Voor vragen: neem contact op met de IT-helpdesk.*
