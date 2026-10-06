# Wekelijks Logboek: Microsoft Universal Print PoC — Week 4 
**Project:** Soudal MUP PoC  
**Auteur:** Rayan  
**Periode:** Mei 2026 — Soudal Turnhout

---

## Maandag — Dag 1
*Focus: Voorbereiding, Licentie Check & Toegangsrechten.*

### Acties Uitgevoerd
- [x] **Licentie Verificatie:** Nagegaan welke Microsoft 365-licenties de Soudal-medewerkers hebben. Bevestigd: Soudal gebruikt **Microsoft 365 E5** (primair) en **F3**. Universal Print is **inbegrepen** in M365 E5 — geen extra abonnementskosten vereist.
- [x] **Rol Verificatie:** Bevestigd dat het account de rol **Universal Print Administrator** heeft in Entra ID. Global Administrator is **niet** vereist voor de dagelijkse MUP-beheertaken.
- [x] **Azure Portal Verkenning:** De **Universal Print**-sectie in de Azure Portal geopend en verkend (https://portal.azure.com → Universal Print).
- [x] **PIM Activatie:** De Universal Print Administrator-rol expliciet geactiveerd via **Privileged Identity Management (PIM)** vóór het gebruik van de portal. Soudal hanteert PIM als beveiligingslaag voor tijdelijke rolactivatie.

### Technische Uitdagingen & Oplossingen

| # | Probleem | Oorzaak | Oplossing |
|:---:|:---|:---|:---|
| 1 | **Knoppen grayed out in Azure Portal** ondanks aanwezige E5-licentie | Universal Print was niet **toegewezen** aan het gebruikersaccount, ook al was de licentie aanwezig op de tenant. Een aanwezige licentie wordt pas actief na expliciete toewijzing per gebruiker. | Universal Print-licentie toegewezen aan het account via **Microsoft 365 Admin Center → Gebruikers → Licenties**. Na toewijzing waren alle knoppen onmiddellijk actief. |
| 2 | **Verkeerd account gebruikt** bij het aanmelden in de Azure Portal | Aangemeld met een persoonlijk of foutief account in plaats van het Soudal-beheerdersaccount met de Universal Print Administrator-rol. | Uitgelogd en opnieuw aangemeld met het correcte Soudal-beheerdersaccount. Verificatie via het profielicoon rechtsboven in de Azure Portal. |
| 3 | **PIM-rol niet geactiveerd** — toegang geweigerd tot Universal Print-functies ondanks het hebben van de rol | Soudal gebruikt **Privileged Identity Management (PIM)** als beveiligingsmaatregel. Dit betekent dat beheerdersrollen *niet* permanent actief zijn, maar tijdelijk geactiveerd moeten worden vóór gebruik. | Rol geactiveerd via **Azure Portal → Entra ID → Privileged Identity Management → Mijn rollen → Universal Print Administrator → Activeren**. De activatie duurt doorgaans 5–15 minuten en is tijdelijk geldig (bijv. 1–8 uur). |

> **Opmerking:** Alle drie bovenstaande problemen zijn configuratie- en toegangsproblemen die losstaan van de technische werking van Universal Print zelf. Ze zijn opgelost vóór de start van de eigenlijke configuratiefase. Dit is vergelijkbaar met de "Admin Consent" blokkade die we in Week 1 van de Printix PoC tegenkwamen.

### Architecturele Notitie: Twee soorten printers in MUP
Bij de initiële verkenning valt onmiddellijk op dat MUP een onderscheid maakt dat Printix niet maakt:

| Type | Uitleg |
|:---|:---|
| **Native UP Printer** | Printer met ingebouwde Azure-connectiviteit. Geen extra software nodig. |
| **Legacy Printer (via Connector)** | Traditionele printer. Vereist de Universal Print Connector-software op een lokale server. |

Voor Soudal Turnhout zullen **de meeste printers via de Connector** moeten gaan, tenzij er specifieke Ricoh IM-serie of HP Enterprise-modellen zijn met native UP-ondersteuning.

---

## Dinsdag — Dag 2
*Focus: Universal Print Connector installatie & eerste printers registreren.*

### Acties Uitgevoerd
- [ ] **Connector Gedownload:** De Universal Print Connector gedownload via https://aka.ms/UPConnector (of via Microsoft 365 Admin Center → Settings → Org Settings → Universal Print).
- [ ] **Connector Geïnstalleerd:** Geïnstalleerd op `[SERVERNAAM]` in Turnhout. Aanmelding met het Universal Print Administrator-account.
- [ ] **Connector Geregistreerd:** De Connector verschijnt nu in de Azure Portal onder **Universal Print → Connectors**.
- [ ] **Eerste Printer Toegevoegd:** Printer `[PRINTERNAAM/IP]` lokaal gedeeld op de Connector-machine en via de Connector-software geregistreerd.
- [ ] **Azure Portal Verificatie:** Bevestigd dat de printer zichtbaar is in **Universal Print → Printers**.

### Issues & Oplossingen
- **Issue (Verwacht — Firewall):** De Connector vereist HTTPS-verkeer (poort 443) naar `*.print.microsoft.com` en `*.azure.com`. De Soudal firewall blokkeerde dit initieel, waardoor de Connector de status 'Offline' kreeg in de Azure Portal.
- **Oplossing:** Uitgaand verkeer op poort 443 toegestaan voor de Connector-machine naar de Microsoft endpoints. De status in Azure Portal sprong onmiddellijk op **Active**.

- **Issue:** Geen beheerrechten in de Connector-applicatie na de eerste aanmelding.
- **Oplossing:** Geactiveerd via PIM als **Universal Print Administrator**. Na herstart van de Connector-app waren de beheerfuncties (Register Printer) beschikbaar.


---

## Woensdag — Dag 3
*Focus: Printer Shares aanmaken & toewijzen aan Entra ID-groepen.*

### Acties Uitgevoerd
- [ ] **Printer Share Aangemaakt:** In Azure Portal → Universal Print → Printer Shares → **Add Printer Share** voor `[PRINTERNAAM]`.
- [ ] **Groep Aangemaakt in Entra ID:** Azure AD-groep `Print_Turnhout` aangemaakt (of bestaande groep gebruikt).
- [ ] **Printer Share Toegewezen aan Groep:** De Printer Share gekoppeld aan de groep `Print_Turnhout`. Alle leden van deze groep kunnen nu deze printer zien.
- [ ] **Verificatie in Windows Settings:** Op een testlaptop geverifieerd dat de printer verschijnt via **Windows Instellingen → Bluetooth en apparaten → Printers → "Search Universal Print for printers"**.

### Issues & Oplossingen
- **Issue (Verwacht — AD-groepen per locatie):** In tegenstelling tot Printix (gateway-gebaseerd), vereist MUP dat we voor **elke locatie** een aparte Azure AD-groep moeten aanmaken en onderhouden. Voor 30+ Soudal-locaties is dit een significante beheerlast.
  - Printix: Gateway detecteert automatisch locatie → geen groepen nodig.
  - MUP: IT moet manueel groepen beheren per locatie.
- **Oplossing/Workaround:** Groepen per locatie (`Print_Turnhout`, `Print_Heist`, etc.) handmatig aangemaakt in Entra ID. Dit is een noodzakelijke eenmalige setup, maar vereist doorlopend onderhoud bij mutaties van medewerkers.

- **Issue:** Printer Share niet zichtbaar voor de testgebruiker in Windows.
- **Oplossing:** Gebruiker was nog niet lid van de Azure AD-groep die gekoppeld is aan de Share. Na toevoeging aan de groep en een refresh in Windows Instellingen was de printer direct zichtbaar.

### Architecturele Notitie: Printer Share vs. Printer
Vergelijkbaar met de "Printers vs. Print Queues" verwarring in Printix, kent MUP zijn eigen concepten:

| Concept | Beschrijving |
|:---|:---|
| **Printer** (in Azure Portal) | Het fysieke apparaat, geregistreerd via de Connector. Niet direct zichtbaar voor gebruikers. |
| **Printer Share** | De "publicatie" van een printer voor gebruikers. Pas na het aanmaken van een Share kunnen gebruikers de printer vinden. Je wijst rechten toe op de Share, niet op de Printer zelf. |

---

## Donderdag — Dag 4
*Focus: User Acceptance Testing & Pool-monitoring.*

### Acties Uitgevoerd
- [ ] **UAT Eigen PC:** Succesvol geprint via Universal Print vanaf eigen laptop. Printer toegevoegd via Windows Instellingen.
- [x] **UAT Collega:** Een collega laten printen naar de Universal Print share; de job werd correct gerouteerd via de cloud naar de fysieke Ricoh printer in Turnhout.
- [x] **Pool-limiet Analyse:** Geconstateerd dat Soudal met 2.500 E5-licenties beschikt over 250.000 jobs per maand. Voor de huidige testfase is dit ruim voldoende.
- [ ] **Rapportage Bekeken:** De basisrapportages in het Azure Portal bekeken (print jobs per user, per printer, per dag).

### Issues & Oplossingen
- **Issue (Print Job Pool):** Het print job pool-systeem (100 jobs/user/maand) is een fundamentele beperking die bij Printix niet bestaat. In een drukke productieomgeving zoals Soudal kan dit snel opraken.
- **Bevinding:** Bij het bereiken van de limiet kan de IT-admin extra jobs bijkopen in blokken van 500 voor $25. Voor Soudal is dit op dit moment niet kritiek gezien de omvang van de E5-tenant.

- **Issue:** Vertraging tussen het versturen van de printopdracht en de start van de printer.
- **Oplossing:** Dit is inherent aan de cloud-architectuur waarbij de job eerst naar de Microsoft cloud wordt geüpload. De vertraging bedraagt ongeveer 5-10 seconden, wat acceptabel is voor de meeste kantooromgevingen.

### Vergelijkende Notitie: Locatiedetectie MUP vs. Printix

| Aanpak | Printix | Microsoft Universal Print |
|:---|:---|:---|
| Methode | Gateway MAC-adres detectie | Azure AD Groepslidmaatschap |
| Automatisch | ✅ Volledig automatisch | ❌ Handmatig via groepen |
| Beheer bij locatiewijziging | Niets nodig (gateway-based) | IT moet groepslidmaatschap aanpassen |
| Vereiste AD-groepen per locatie | ❌ Niet nodig | ✅ Verplicht |

---

## Vrijdag — Dag 5
*Focus: Evaluatie Week 1 & documentatie.*

### Acties Uitgevoerd
- [ ] **Eindverslag Bijgewerkt:** Testresultaten uit Week 1 ingevoerd in `MUP_PoC_Eindverslag_DRAFT.md`.
- [ ] **Vergelijking Printix vs. MUP Bijgewerkt:** Eerste bevindingen vergeleken met de Printix PoC.
- [x] **Roadmap Week 5 Opgesteld:** Focus op praktijktesten (offline printen, driver-beperkingen en RBAC-rechtenanalyse). 

### Evaluatie Week 1 (Week 4) 

**Eerste indrukken MUP (Voordelen):**
*   **Geen extra kosten:** Volledig gedekt door de bestaande M365 E5-licenties van Soudal.
*   **Native Windows-integratie:** Geen aparte client nodig voor de eindgebruiker; printers worden toegevoegd via de standaard Windows-instellingen.
*   **Beheer in Azure:** Gecentraliseerd beheer in de vertrouwde Azure Portal omgeving.

**Eerste indrukken MUP (Nadelen):**
*   **Beheer-overhead:** Het handmatig moeten aanmaken en beheren van AD-groepen per locatie is een groot nadeel t.o.v. de automatische gateway-detectie van Printix.
*   **Connector-vereiste:** Elke vestiging met legacy-printers heeft een actieve Windows-machine nodig als Connector.
*   **Beperkte rapportage:** De native rapportage in Azure is zeer basis vergeleken met de Power BI templates van Printix.

---

## Eindevaluatie Project 
Het onderzoek naar Microsoft Universal Print (MUP) als Fase 2 van het printers onderzoek is afgerond. Hoewel MUP financieel aantrekkelijk is door de integratie in de E5-licenties, blijft Printix de superieure keuze voor de wereldwijde schaal van Soudal vanwege de superieure locatiedetectie, toner-monitoring en driver-beheer mogelijkheden. MUP wordt aanbevolen als aanvullende laag voor specifieke scenario's (bezoekers, thin clients).

---
*Gedocumenteerd door Rayan voor Soudal Group.*
