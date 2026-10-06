# Vergelijking: Printix vs Microsoft Universal Print 
## Soudal Group — Beslissingsrapport voor Management
### Opgesteld door: Rayan (Stagiair Infrastructuur) | Mei 2026

---

## 1. Inleiding

Dit document presenteert een volledige, eerlijke vergelijking tussen **Printix (Tungsten Automation)** en **Microsoft Universal Print (MUP)** als cloudprintoplossing voor Soudal Group. Het is opgesteld als beslissingsondersteuning voor het management en de IT-afdeling.

Beide oplossingen zijn onderzocht in de context van Soudal's specifieke situatie:
- 600+ printers van gemengde merken (Ricoh, HP, Brother)
- 30+ vestigingen wereldwijd
- ~2.500 actieve gebruikers
- Actieve migratie naar Microsoft Entra ID en Intune
- Bestaande M365 E5-licenties

Voor Printix werd een volledige **Proof of Concept** uitgevoerd op Soudal Turnhout. Voor MUP werd een theoretisch en praktisch onderzoek uitgevoerd, aangevuld met definitieve praktijktesten in Week 5 (Cloud Index, offline spooling, driver-validatie). Bepaalde beheertests bleven beperkt door rechtenrestricties van het stagiair-account — dit is geen verwacht probleem voor een volwaardige IT-admin.

---

## 2. Samenvatting — De Kern van de Beslissing

| | Printix | Microsoft Universal Print |
|:---|:---:|:---:|
| **Jaarkosten 2.500 gebruikers** | ~€30.000/jaar (€12 PUPY) | €0 extra |
| **Aanbevolen als primaire oplossing** | ✅ | ❌ |
| **Aanbevolen als aanvulling** | ✅ | ✅ |

**Kortste conclusie:** Printix is de sterkste keuze als primaire printoplossing voor Soudal. MUP is waardevol als gratis aanvulling via de ingebouwde integratie, maar onvoldoende als standalone vervanging.

---

## 3. Volledige Vergelijkingstabel

### 3.1 Kosten

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Basisprijs** | €12 Per User Per Year (PUPY) | €0 extra (inbegrepen in M365 E5) | MUP |
| **Jaarkosten 2.500 gebruikers** | ~€30.000/jaar | €0 | MUP |
| **Printvolume limiet** | Onbeperkt | Pool: 100 jobs/E5-licentie/maand = 250.000 jobs/maand voor Soudal | Printix |
| **Printer licenties** | Geen | Geen | Gelijk |
| **Verborgen kosten** | Geen (alles inbegrepen) | Connector-machines (alleen voor legacy-printers, minderheid bij Soudal), stroom, onderhoud | Printix |
| **Extra volume bijkopen** | N.v.t. — onbeperkt | $25/500 jobs of $300/10.000 jobs | Printix |
| **Totale werkelijke kost** | ~€30.000/jaar (transparant) | €0 + beperkte indirecte kosten (minder Connectors nodig door UP-ready vloot) | Afhankelijk |

> **Noot over de pool voor Soudal:** Met 2.500 E5-licenties heeft Soudal 250.000 jobs/maand. Bij gemiddeld 50 prints/medewerker/maand = 125.000 jobs. De pool is waarschijnlijk voldoende, maar vereist monitoring. **Let op:** F3-licenties leveren slechts 5 jobs/maand bij in plaats van 100 — inventariseer hoeveel F3-gebruikers Soudal heeft.

### 3.2 Installatie & Beheer

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Printserver nodig** | Nee — serverless | Nee — serverless | Gelijk |
| **Connector voor oudere printers** | Niet nodig — werkt via SNMP/IP | Alleen nodig voor legacy-printers (minderheid bij Soudal) — meeste printers zijn UP-ready | Printix |
| **Agent/client op laptop** | Ja — MSI via Intune (eenmalig) | Nee — native in Windows | MUP |
| **Beheerconsole** | Eigen Printix portal (nieuwe tool leren) | Azure Portal (vertrouwde omgeving) | MUP |
| **Intune integratie** | Via MSI Win32 App deployment | Native ingebouwd | MUP |
| **Leercurve IT** | Hoog — eigen architectuur en logica | Laag — vertrouwde Microsoft-omgeving | MUP |
| **PIM-vereiste** | Nee — eenmalige Global Admin consent | Ja — rol tijdelijk activeren voor elke beheersessie. De RBAC-blokkades tijdens de PoC waren specifiek voor het stagiair-account. | Printix |
| **High Availability** | Ingebouwd in cloud-architectuur | Geen HA voor Connector — single point of failure | Printix |
| **Schaalbaarheid nieuwe locaties** | Automatisch via netwerk + Intune | Per locatie: Connector installeren + groep aanmaken | Printix |

### 3.3 Printer Ontdekking & Hardware

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Automatische printer discovery** | Ja — SNMP-scan via netwerk | Nee — handmatige registratie per printer | Printix |
| **Bulk import (429 printers tegelijk)** | Ja — via CSV + Configurator | Nee — één per één via Connector | Printix |
| **Toner & status monitoring** | Ja — realtime via SNMP | Nee — niet beschikbaar | Printix |
| **Papier monitoring** | Ja | Nee | Printix |
| **Locatiebepaling** | Automatisch via gateway MAC-adres | Handmatig via Azure AD-groepen | Printix |
| **Driver-beheer** | Centraal, vergrendelbaar, bulk-distribueerbaar | Driverless IPP — geen centrale controle | Printix |
| **Geavanceerde driver-functies** | ✅ Volledige OEM-drivers (nieting, finisher, papierlade, kleurprofielen) | 🔴 **Niet beschikbaar** — Universal Print Class Driver biedt enkel basisinstellingen | **Printix** |
| **Wereldwijde driver updates** | Ja — één klik voor alle printers van hetzelfde model | Niet beschikbaar | Printix |
| **Hardware-onafhankelijk** | Ja — alle merken via SNMP | Ja — alle merken (via Connector) | Gelijk |
| **Toekomst: driver uitfasering** | Geen impact — drivers centraal beheerd | Voordeel — IPP is de toekomst | MUP |

### 3.4 Beveiliging & Gebruikerservaring

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Secure Print / Pull Print** | Ja — Printix Anywhere (gevalideerd) | Ja — UP Anywhere (GA aug. 2025) | Gelijk |
| **Vrijgave methode** | Smartphone app of webApp | QR-code, PIN, of badge (bij ondersteunde printers) | Gelijk |
| **Badge-authenticatie** | Ja — Printix GO (werkt op alle printers via embedded software) | Beschikbaar op native UP-ready printers met OEM-integratie — het merendeel van de Soudal-vloot is UP-ready | Printix |
| **Badge op Connector-printers** | Ja via Printix GO | Nee — niet ondersteund | Printix |
| **Printer toevoegen (UX)** | Via Printix Client — automatisch op basis van locatie | Via Cloud Index (Share Name zoeken, bijv. `\\laserprinters`) — vlot, IP verborgen | Gelijk — beide goed |
| **Self-service voor gebruikers** | Ja — intuïtieve Printix Client | Beperkt — via Windows Instellingen (minder intuïtief) | Printix |
| **Mobiel printen** | Ja — iOS en Android app | Beperkt — QR-code via Microsoft 365 app | Printix |
| **Scan naar OneDrive/SharePoint** | Ja | Ja | Gelijk |
| **Gast-printen** | Ja — via Cloud Relay | Beperkt | Printix |
| **BYOD (eigen toestellen)** | Ja — via Printix App | Beperkt | Printix |
| **Offline spooling / printen zonder internet** | ✅ Lokale spooling — opdrachten gebufferd bij connectiviteitsverlies | 🔴 **Niet beschikbaar** — directe foutmelding bij Wi-Fi uit, geen enkele offline fallback | **Printix** |
| **GDPR-compliance** | Ja — EU-servers, aparte DPA vereist | Ja — onder bestaande Microsoft DPA van Soudal | MUP |

### 3.5 Rapportages & Analytics

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Printvolume per gebruiker** | Ja | Ja (basis) | Printix |
| **Printvolume per afdeling/locatie** | Ja — uitgebreid | Beperkt | Printix |
| **Kleur vs. zwart-wit analyse** | Ja | Nee | Printix |
| **Kostenanalyse per afdeling** | Ja | Nee | Printix |
| **CO2 / milieu-impact** | Ja — Tree-O-Meter | Nee | Printix |
| **Power BI integratie** | Ja — kant-en-klaar template + Azure SQL | Niet standaard beschikbaar | Printix |
| **Real-time dashboard** | Ja | Basis | Printix |
| **Historische data export** | Ja | Beperkt | Printix |

### 3.6 Toekomst & Strategie

| Criterium | Printix | Microsoft Universal Print | Winnaar |
|:---|:---|:---|:---:|
| **Vendor lock-in** | Printix/Tungsten — apart ecosysteem | Microsoft — al binnen M365 | MUP |
| **Exitstrategie** | Herconfiguratie vereist bij overstap | Makkelijker — al in Microsoft-ecosysteem | MUP |
| **Actieve ontwikkeling** | Ja | Ja — snel groeiend | Gelijk |
| **Roadmap badge-auth** | Nu beschikbaar (Printix GO) | In ontwikkeling — beperkt beschikbaar | Printix |
| **Toekomst driver standaard** | Ondersteunt IPP + legacy | Volledig IPP — toekomstbestendig | MUP |
| **Volwassenheid** | Bewezen enterprise-oplossing | Groeiend — nog niet feature-parity | Printix |

---

## 4. Wanneer Gebruik je Welke Oplossing?

### Kies Printix als primaire oplossing wanneer:
- Je een gemengde vloot van 100+ printers hebt over meerdere locaties
- Toner-monitoring en proactief onderhoud vereist zijn
- Gecentraliseerd driver-beheer noodzakelijk is (bijv. papierformaat China, kleurbeleid)
- Badge-authenticatie vereist is op productie- of R&D-locaties
- Diepgaande kostrapportages nodig zijn voor management
- Automatische locatiedetectie bij roaming medewerkers gewenst is

### Kies MUP als primaire oplossing wanneer:
- Soudal een strikte kostenbesparingsdoelstelling heeft
- De printerfloot overwegend UP-ready is (zoals bij Soudal het geval is)
- Eenvoudig beheer vanuit Azure prioriteit heeft boven geavanceerde functies
- Toner-monitoring niet vereist is (bijv. leverancier beheert supplies zelf)
- De organisatie bereid is Connector-machines te beheren voor de resterende legacy-printers

### Kies de Hybride aanpak (aanbevolen voor Soudal):
Printix als volledige beheerlaag + MUP als aanvullende vanglaag via de ingebouwde Printix-integratie.

**Wat dit concreet betekent:**
- Printix beheert alle printers centraal (discovery, drivers, toner, rapportages)
- Vanuit Printix portal: "Publish to Universal Print" per queue activeren (één klik)
- Printer verschijnt automatisch ook als native Windows-printer in Azure
- Thin clients, bezoekers en kiosk-apparaten zonder Printix Client printen via MUP
- Geen aparte Connector-machines nodig — Printix handelt dit af
- Geen extra kosten voor de MUP-laag

---

## 5. Risico-analyse

### 5.1 Risico's Printix

| Risico | Kans | Impact | Maatregel |
|:---|:---:|:---:|:---|
| Prijsverhoging door Tungsten Automation | Middel | Hoog | Jaarcontract met prijsgarantie onderhandelen |
| Afhankelijkheid van Printix-cloud (uitval) | Laag | Hoog | SLA-garanties controleren |
| Leercurve nieuw IT-personeel | Zeker | Middel | Documentatie en training |
| Firewall blokkade API-calls | Laag | Middel | Uitzondering aanvragen bij security |
| Tenant-URL fout bij deployment | Laag | Middel | Intune deployment verzekert correcte URL |

### 5.2 Risico's Microsoft Universal Print

| Risico | Kans | Impact | Maatregel |
|:---|:---:|:---:|:---|
| Connector-machine uitval (geen HA) | Middel | Hoog | Redundante Connector-machine per locatie |
| Print job pool uitputting | Laag | Hoog | Monitoring instellen in Azure Portal + alerting |
| F3-licenties met slechts 5 jobs/maand | Middel | Middel | Inventariseer F3-gebruikers, overweeg upgrade |
| Beheer-overhead locatiewijzigingen | Hoog | Middel | Automatiseren via Entra ID dynamic groups |
| Licentie niet toegewezen per gebruiker | Middel | Hoog | Intune policy voor automatische toewijzing |
| PIM-activatie vergeten | Middel | Middel | Documentatie + training IT-team. RBAC-beperkingen tijdens PoC waren stagiair-account-specifiek. |

### 5.3 Gedeelde Risico's (beide oplossingen)

| Risico | Impact | Maatregel |
|:---|:---:|:---|
| Internetuitval — geen print mogelijk | Hoog | Backup-scenario bespreken met business (lokale fallback?) |
| GDPR — printdata in cloud | Middel | DPA tekenen (Printix) / bestaande Microsoft DPA gebruiken (MUP) |
| Vendor lock-in | Middel | Exitstrategie documenteren, data-export mogelijkheden verifiëren |

---

## 6. Kostencomparatie — Volledig Beeld

### Scenario A: Alleen Printix
| Post | Jaar 1 | Structureel/jaar |
|:---|:---:|:---:|
| Printix licenties (2.500 gebruikers) | €30.000 | €30.000 |
| Intune MSI deployment (eenmalig IT-uren) | €0 | €0 |
| Training IT-team | €2.000-5.000 | €0 |
| **Totaal** | **~€32.000-35.000** | **~€30.000** |

### Scenario B: Alleen MUP
| Post | Jaar 1 | Structureel/jaar |
|:---|:---:|:---:|
| MUP licenties | €0 | €0 |
| Connector-machines (beperkt aantal locaties × €600 gem.) | Beperkt | €0 |
| Stroom + onderhoud Connectors | Beperkt | Beperkt |
| IT-uren initiële setup (geschat) | €10.000-20.000 | €0 |
| IT-uren doorlopend groepsbeheer | €0 | €3.000-8.000 |
| Extra print jobs (indien nodig) | €0-3.600 | €0-3.600 |
| **Totaal** | **~€30.000-45.000** | **~€5.000-12.000** |

### Scenario C: Hybride (Aanbevolen)
| Post | Jaar 1 | Structureel/jaar |
|:---|:---:|:---:|
| Printix licenties (2.500 gebruikers) | €30.000 | €30.000 |
| MUP activatie via Printix (geen Connector nodig) | €0 | €0 |
| Geen extra hardware vereist | €0 | €0 |
| **Totaal** | **~€30.000** | **~€30.000** |

> **Noot:** Scenario B (alleen MUP) is goedkoper maar mist cruciale functionaliteiten. Scenario C (hybride) heeft dezelfde kost als alleen Printix maar biedt meer dekking. De hybride aanpak is dus de meest waardevolle optie voor hetzelfde budget.

---

## 7. Definitieve Aanbeveling

### Voor het Management van Soudal Group

**Aanbeveling: Printix als primaire oplossing, gecombineerd met MUP als gratis vanglaag (Hybride Scenario C)**

**Onderbouwing in 5 punten:**

**1. Printix is bewezen via de PoC**
In twee weken zijn 429 printers ontdekt, geïmporteerd en getest. Alle 13 kritieke functionaliteiten zijn succesvol gevalideerd. MUP is theoretisch én praktisch onderzocht; de praktijktesten bevestigen twee kritieke beperkingen: geen offline spooling en geen geavanceerde driver-functies. De RBAC-beperkingen tijdens het testen waren specifiek voor het stagiair-account en vormen geen verwacht probleem voor een volwaardige admin.

**2. Toner-monitoring is een harde vereiste voor Soudal**
Met 600+ printers wereldwijd is het onmogelijk om zonder monitoring proactief te beheren. MUP biedt dit niet. Printix biedt realtime toner%, papier en printerstatus via SNMP voor elke printer wereldwijd.

**3. De €30.000/jaar is gerechtvaardigd**
Verdeeld over 2.500 gebruikers en 30+ locaties is dit €8/locatie/dag. Dit elimineert lokale printservers op alle vestigingen, handmatig printerbeheer, helpdesk-calls voor printerinstallaties en blinde verspilling door gebrek aan printdata.

**4. MUP is gratis toegevoegd via de Printix-integratie**
Door de ingebouwde Universal Print-integratie in Printix te activeren, krijg je de voordelen van beide systemen zonder extra kosten of extra beheerlast. Dit is geen compromis — het is het beste van twee werelden.

**5. Uitrol is eenvoudiger dan verwacht**
Één Intune Win32 App policy voor de Printix MSI. Daarna doet Printix alles automatisch: netwerk herkennen, printers discoveren, juiste printers installeren per locatie. Geen reizen, geen lokale IT-interventie, geen handmatige configuratie per vestiging.


*Opgesteld mei 2026 — Soudal Group, Turnhout*
*Auteur: Rayan (Stagiair Infrastructuur)*
*Contactpersonen: Dries Wuyts / Bart De Cuyper / Niels Gevers*
