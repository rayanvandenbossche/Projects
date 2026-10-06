# Microsoft Universal Print — PoC Eindverslag 
## Soudal Group | Mei 2026
### Opgesteld door: Rayan (Stagiair Infrastructuur)

---

## 1. Managementsamenvatting

Dit verslag presenteert de resultaten van het onderzoek naar **Microsoft Universal Print (MUP)** als cloud-gebaseerde printoplossing voor de Soudal Group. Dit onderzoek vormt **Fase 2** van een twee-fasen evaluatie, waarbij Fase 1 reeds werd afgerond met een volledige Proof of Concept voor **Printix (Tungsten Automation)**.

Het doel was om MUP eerlijk te evalueren als mogelijke vervanging of aanvulling op Printix, rekening houdend met de specifieke context van Soudal: 600+ printers, 30+ vestigingen wereldwijd, en een actieve migratie naar Microsoft Entra ID en Intune.

### Conclusie
Microsoft Universal Print is **gedeeltelijk geschikt** voor Soudal als onderdeel van een hybride aanpak. MUP biedt significante kostenvoordelen omdat het inbegrepen is in de bestaande M365 E5-licenties. Een belangrijk pluspunt voor Soudal is dat het merendeel van de printerfloot **UP-ready** is, waardoor de Connector-afhankelijkheid beperkt blijft tot een klein aantal legacy-modellen. De praktijktesten in Week 5 hebben echter twee kritieke beperkingen blootgelegd: (1) **geen offline spooling** — printen is onmogelijk zonder actieve internetverbinding, en (2) **driver-functionaliteit beperkt** tot de generieke Universal Print Class Driver (IPP), waardoor merkspecifieke opties (bijv. Ricoh-finisherinstellingen) niet beschikbaar zijn. Daarnaast werden **RBAC-beperkingen** ervaren tijdens het testen, maar deze waren specifiek gerelateerd aan het beperkte stagiair-account — een volwaardige IT-admin met de juiste rechten zou hier geen hinder van moeten ondervinden. De oplossing mist daarnaast cruciale functionaliteiten voor Soudal's schaal: automatische locatiedetectie, toner-monitoring en diepgaande rapportages. De aanbeveling is Printix als primaire beheerlaag te gebruiken, met MUP als aanvullende vanglaag via de ingebouwde Printix-integratie.

---

## 2. Projectcontext

### 2.1 Probleemstelling
Zie Printix PoC Eindverslag sectie 2.1 — de probleemstelling is identiek. De kernvraag voor dit onderzoek is specifiek: **kan Microsoft Universal Print de functionaliteiten van Printix vervangen of aanvullen, en zo ja, voor welke use cases?**

### 2.2 Doelstelling Onderzoek
Vaststellen of MUP in staat is om:
1.  Printers te registreren en centraal te beheren vanuit Azure Portal.
2.  Printers automatisch toe te wijzen aan werknemers per locatie.
3.  Een veilige "Pull Print" functionaliteit te bieden.
4.  Rapportages te leveren over printvolume en verbruik.
5.  Naadloos te integreren met de bestaande Microsoft Entra ID en Intune-omgeving.
6.  Als kostenbesparende vervanging of aanvulling op Printix te dienen.

### 2.3 Onderzoeksomgeving
*   **Locatie:** Soudal Turnhout (Everdongenlaan 18-20, 2300 Turnhout)
*   **Licenties:** Microsoft 365 E5 (primair) en F3
*   **Beheerplatform:** Azure Portal + Microsoft 365 Admin Center
*   **Beheerderrol:** Universal Print Administrator (via PIM tijdelijk geactiveerd)
*   **Printers getest:** Ricoh MFP's en HP LaserJets op Turnhout-netwerk
*   **Gebruikers:** Zelfde testgebruikers als Printix PoC

---

## 3. Architecturale Bevindingen

### 3.1 Twee Soorten Printers — Een Fundamenteel Onderscheid

Het eerste en meest cruciale architecturale verschil met Printix is dat MUP een hard onderscheid maakt tussen twee categorieën printers:

**Native UP-Ready Printers**
Nieuwere modellen van bepaalde fabrikanten (specifieke Ricoh IM-serie, HP Enterprise, Canon imageRUNNER Advance) hebben ingebouwde Azure-connectiviteit. Deze printers registreren zichzelf direct in Universal Print zonder extra software. **Voor Soudal is het merendeel van de printerfloot UP-ready**, wat betekent dat de meeste printers direct met de cloud kunnen communiceren zonder extra software.

**Legacy Printers via de Connector**
Een beperkt aantal oudere modellen in de Soudal-vloot is niet UP-ready. Voor deze printers is de **Universal Print Connector** verplicht: een Windows-applicatie die op een lokale machine moet draaien en als brug fungeert tussen de printer en de Microsoft-cloud.

> **Implicatie voor Soudal:** Alleen op vestigingen met legacy-printers moet een Windows-machine 24/7 actief zijn als Connector. Doordat Soudal weinig legacy-modellen heeft, is deze operationele last beperkt. Bij Printix is de Connector volledig afwezig, maar het voordeel hiervan is kleiner dan verwacht gezien het hoge aandeel UP-ready printers bij Soudal.

### 3.2 Locatiebepaling — Handmatig vs. Automatisch

Dit is het meest ingrijpende architecturale verschil met Printix:

| Aspect | Printix | Microsoft Universal Print |
|:---|:---|:---|
| Methode | Gateway MAC-adres detectie | Azure AD Groepslidmaatschap |
| Automatisch | ✅ Volledig automatisch | ❌ Handmatig geconfigureerd |
| Beheer bij locatiewijziging | Niets nodig | IT moet groepen aanpassen |
| Vereiste AD-groepen per locatie | Niet nodig voor locatie | Verplicht voor elke locatie |
| Roaming gebruikers | Automatisch correct | Handmatig te corrigeren |

**Concrete impact voor Soudal:**
Voor 30+ vestigingen moeten 30+ Azure AD-groepen worden aangemaakt. Elke medewerker moet aan de juiste groep worden toegevoegd. Wanneer iemand van vestiging wisselt, moet IT de groepslidmaatschappen handmatig aanpassen. Bij Printix is dit alles volledig automatisch via de gateway.

### 3.3 Print Job Pool — Het Licentiemodel

MUP werkt met een **gedeelde print job pool** op tenant-niveau. Dit is fundamenteel anders dan Printix (onbeperkt volume):

*   **M365 E5 en E3:** Elke licentie voegt **100 jobs/maand** toe aan de gedeelde pool.
*   **M365 F3:** Elke licentie voegt slechts **5 jobs/maand** toe.
*   **Pool-berekening Soudal (voorbeeld):** 2.500 E5-gebruikers × 100 jobs = 250.000 jobs/maand beschikbaar.
*   **Ongebruikte jobs** vervallen aan het einde van de maand — geen overdracht naar de volgende maand.
*   **Bij overschrijding:** Gebruikers kunnen blijven printen maar de IT-admin ontvangt een waarschuwing. Extra jobs kunnen worden bijgekocht: 500 jobs voor $25/maand of 10.000 jobs voor $300/maand.

> **Belangrijk:** Een "job" is één printopdracht, ongeacht het aantal pagina's of kopieën. 15 kopieën van een 10-pagina document = 1 job. Dit is gunstiger dan het klinkt, maar vereist monitoring.

### 3.4 Printer Share Architectuur — Extra Stap vs. Printix

In MUP bestaat een verplichte twee-staps architectuur die bij Printix niet bestaat:

**Stap 1 — Printer** (fysiek apparaat, geregistreerd via Connector)
→ Niet direct zichtbaar voor gebruikers

**Stap 2 — Printer Share** (publicatie van de printer)
→ Pas na het aanmaken van een Share kunnen gebruikers de printer vinden
→ Rechten worden toegewezen op Share-niveau, niet op Printer-niveau

Dit is vergelijkbaar met de "Printer vs. Print Queue" concepten in Printix, maar vereist meer expliciete stappen per printer bij de initiële setup.

### 3.5 Secure Print — Universal Print Anywhere (GA augustus 2025)

Microsoft heeft in augustus 2025 "Universal Print Anywhere" algemeen beschikbaar gemaakt. Dit is de equivalent van Printix Anywhere (pull printing):

*   Gebruiker print naar een virtuele "Anywhere"-wachtrij.
*   Document wordt veilig opgeslagen in de Microsoft-cloud.
*   Gebruiker geeft vrij bij een fysieke printer via: **QR-code** (via Microsoft 365 app), **PIN-code**, of **badge-authenticatie** (bij ondersteunde printers).
*   Pas dan wordt het document fysiek afgedrukt.

**Belangrijk aandachtspunt:** Badge-authenticatie via Universal Print Anywhere werkt uitsluitend op **native UP-ready printers** — niet op printers die via de Connector zijn aangesloten. De badge-integratie vereist dat de printerfabrikant een partnerintegratie heeft met Microsoft. Aangezien het merendeel van de Soudal-vloot UP-ready is, zou badge-authenticatie voor het grootste deel van de printers beschikbaar moeten zijn — mits de fabrikant een actieve partnerintegratie met Microsoft heeft.

### 3.6 Driver-beheer — Driverless vs. Gecentraliseerd

MUP werkt op basis van het **IPP (Internet Printing Protocol)** standaard — driverless. Dit betekent:
*   Geen drivers nodig op de laptop van de gebruiker.
*   Toekomstbestendig: Microsoft faast legacy printer drivers uit in 2026-2027.
*   **Nadeel:** Geen mogelijkheid om drivers te vergrendelen, te distribueren of centraal te beheren zoals bij Printix.
*   Specifieke printer-functies (bijv. geniet, papierlade-selectie, finisher-opties) kunnen beperkt beschikbaar zijn afhankelijk van het printermodel.

> **Praktijkvalidatie (Week 5):** Tijdens de tests is bevestigd dat MUP uitsluitend de **Universal Print Class Driver (IPP)** aanbiedt. Gebruikers hebben enkel toegang tot basisinstellingen (papierformaat, duplex, aantal kopieën). Merkspecifieke interface-opties van fabrikanten zoals Ricoh — waaronder geavanceerde nieting, boekjesvouw, perforatie en specifieke papierlade-selectie — zijn **niet beschikbaar**. Voor afdelingen die afhankelijk zijn van deze geavanceerde printfuncties (bijv. R&D, marketing) vormt dit een functionele beperking t.o.v. Printix, dat volledige OEM-drivers centraal kan distribueren.

### 3.7 PIM-vereiste — Beveiligingslaag bij Soudal

Soudal maakt gebruik van **Privileged Identity Management (PIM)** — een beveiligingslaag waarbij beheerdersrollen niet permanent actief zijn maar tijdelijk moeten worden geactiveerd. Dit heeft directe gevolgen voor het gebruik van MUP:

*   Vóór elk beheertaak in de Universal Print portal moet de rol expliciet worden geactiveerd.
*   Activatie duurt 5-15 minuten en is tijdelijk geldig (1-8 uur).
*   Bij Printix was de Global Admin consent **eenmalig en permanent**.
*   Dit is een operationeel verschil dat IT-beheerders moeten kennen en in hun workflow moeten opnemen.

> **Nuance:** Tijdens de PoC werden RBAC-beperkingen ervaren (o.a. ontoegankelijke Connectors-tabbladen), maar deze waren specifiek gerelateerd aan het **beperkte stagiair-account** dat werd gebruikt voor het testen. Een volwaardige IT-admin met de juiste permanente rechten of correct geconfigureerde PIM-rollen zou hier normaal gesproken geen hinder van moeten ondervinden. De PIM-activatiestap zelf blijft wel een operationeel verschil met Printix.

---

## 4. Uitgevoerde Werkzaamheden & Bevindingen

### Week 1: Toegang, Configuratie & Eerste Tests

#### A. Licentie- en Toegangsverificatie (Dag 1)

*   **Licentie bevestigd:** M365 E5 bevat Universal Print met 100 jobs/maand/licentie. M365 F3 bevat Universal Print met slechts 5 jobs/maand/licentie.

Hierbij zijn drie technische blokkades geïdentificeerd en opgelost:

| # | Probleem | Oorzaak | Oplossing |
|:---:|:---|:---|:---|
| 1 | **Knoppen grayed out** in Azure Portal ondanks aanwezige E5-licentie | Universal Print was niet expliciet **toegewezen** aan het gebruikersaccount. Een licentie op de tenant is niet automatisch actief per gebruiker. | Licentie toegewezen via **Microsoft 365 Admin Center → Gebruikers → Licenties & apps**. Na toewijzing waren alle knoppen onmiddellijk actief. |
| 2 | **Verkeerd account** gebruikt bij aanmelding in Azure Portal | Aangemeld met een foutief account zonder de Universal Print Administrator-rol. | Uitgelogd en opnieuw aangemeld met het correcte Soudal-beheerdersaccount. Verificatie via profielicoon rechtsboven. |
| 3 | **PIM-rol niet geactiveerd** — toegang geweigerd | Soudal gebruikt PIM als beveiligingslaag. Rollen zijn niet permanent actief. | Rol geactiveerd via **Entra ID → Privileged Identity Management → Mijn rollen → Universal Print Administrator → Activeren**. Activatie: 5–15 min, geldig 1–8 uur. |

> **Vergelijking met Printix:** Bij Printix volstond eenmalige Global Admin consent. Bij MUP zijn er drie afzonderlijke stappen vereist voordat beheer mogelijk is. Dit heeft directe gevolgen voor de onboarding van nieuwe IT-beheerders.

#### B. Connector Installatie & Printer Registratie

*   Universal Print Connector gedownload via `https://aka.ms/UPConnector`.
*   Geïnstalleerd op een Windows-machine in Turnhout.
*   Connector succesvol geregistreerd in Azure Portal (status: **Active**).
*   Eerste printer lokaal gedeeld via Print Management, daarna gepubliceerd via de Connector.
*   Printer zichtbaar in **Azure Portal → Universal Print → Printers**. ✅

**Tijdsvergelijking met Printix:**
Bij Printix werden 429 printers in bulk geüpload via één CSV-import. Bij MUP moet elke printer individueel lokaal worden gedeeld en via de Connector worden gepubliceerd. Voor de schaal van Soudal (600+ printers, 30+ locaties) is dit significant meer werk zonder een bulk-import equivalent.

#### C. Printer Share & Groepstoewijzing

*   Printer Share aangemaakt in Azure Portal.
*   Azure AD-groep `Print_Turnhout` gekoppeld aan de Share.
*   Testgebruiker kon de printer vinden via **Windows Instellingen → Printers en scanners → Add device**. ✅
*   Print-job succesvol verzonden en fysiek afgedrukt. ✅

#### D. Universal Print Anywhere (Secure Print) Test

*   "Enable holding jobs until secure release" ingeschakeld op de Printer Share.
*   Document verstuurd naar de beveiligde wachtrij.
*   Vrijgave via **QR-code** in de Microsoft 365 app op smartphone. ✅
*   Document succesvol vrijgegeven en afgedrukt. ✅
*   **Aandachtspunt:** Badge-vrijgave niet getest — vereist native UP-ready printer met OEM-partnerintegratie.

#### E. Rapportages Bekeken

*   **Azure Portal → Universal Print → Usage** geraadpleegd.
*   Basisinformatie beschikbaar: jobs per dag, per gebruiker, per printer.
*   Geen kostanalyse, geen kleur/ZW-verhouding, geen CO2-rapportage.
*   Geen Power BI-template beschikbaar zonder extra configuratie.

---

## 5. Testresultaten — Samenvattingstabel

| Testscenario | Status | Toelichting |
|:---|:---:|:---|
| Licentie verificatie (E5) | ✅ | Universal Print inbegrepen — 100 jobs/licentie/maand |
| Licentie verificatie (F3) | ⚠️ | Slechts 5 jobs/licentie/maand — risico bij veel F3-gebruikers |
| PIM-rol activatie | ✅ | Na activatie via Entra ID PIM — duurt 5-15 min |
| Azure Portal toegang | ✅ | Na correcte account + licentietoewijzing |
| Connector installatie Turnhout | ✅ | Succesvol geregistreerd, status Active |
| Printer registratie via Connector | ✅ | Lokaal gedeeld + gepubliceerd via Connector |
| Printer Share aanmaken | ✅ | Share aangemaakt en gekoppeld aan AD-groep |
| Printer zichtbaar voor gebruiker | ✅ | Via Windows Instellingen → Add device |
| **Printer toevoegen via Cloud Index** | ✅ | Gebruikers zoeken op Share Name (bijv. `\\laserprinters`) — vlotte ervaring, IP-architectuur volledig verborgen |
| Basis print (CTRL+P) | ✅ | Document succesvol afgedrukt |
| **Offline spooling / printen zonder internet** | 🔴 | **Printen onmogelijk zonder actieve internetverbinding.** Wi-Fi uitschakelen levert directe foutmelding op. Geen lokale offline spooling naar de cloud — kritiek nadeel t.o.v. de Printix-client. |
| Universal Print Anywhere (QR) | ✅ | Pull print via QR-code succesvol |
| Badge-vrijgave | ⚠️ | Niet getest — vereist native UP-ready printer |
| **Driver geavanceerde functies** | 🔴 | **MUP dwingt de Universal Print Class Driver (IPP).** Enkel basisinstellingen beschikbaar. Merkspecifieke opties (Ricoh-finisher, geavanceerde nieting) niet toegankelijk — functionele beperking t.o.v. Printix. |
| **RBAC/PIM beheertoegang** | ⚠️ | Essentiële tabbladen (Connectors) waren niet toegankelijk met het **stagiair-account** ondanks actieve PIM + Print Admin-rol. Dit was waarschijnlijk een rechtenbeperking specifiek voor het testaccount — een volwaardige IT-admin zou hier geen problemen mee moeten hebben. |
| Intune automatische deployment | 📋 | Gedocumenteerd, overdracht aan Soudal IT |
| Toner monitoring | ❌ | Niet beschikbaar in MUP |
| Driver-beheer (lock/distribute) | ❌ | Niet beschikbaar in MUP |
| Power BI rapportages | ❌ | Niet native beschikbaar |
| Automatische locatiedetectie | ❌ | Werkt via AD-groepen, niet via netwerk |

---

## 6. Evaluatie: Is MUP Geschikt voor Soudal?

### 6.1 Voordelen (Sterktes)

| Voordeel | Toelichting |
|:---|:---|
| **Geen extra kosten** | Inbegrepen in M365 E5 — Soudal betaalt hier al voor |
| **Native Microsoft-integratie** | Beheer vanuit bekende Azure Portal en Intune — geen nieuwe tool |
| **Geen client op laptop nodig** | Native in Windows — geen MSI deployment vereist voor eindgebruikers |
| **Universal Print Anywhere** | Pull printing GA sinds augustus 2025 — goed werkend via QR/PIN |
| **Driverless (IPP)** | Toekomstbestendig — klaar voor Microsoft's driver uitfasering 2026-2027 |
| **macOS ondersteuning** | Native ondersteuning voor Mac-gebruikers |
| **Entra ID & Intune** | Volledig geïntegreerd in bestaand Microsoft-ecosysteem |
| **Scan naar SharePoint/Teams** | Native integratie beschikbaar bij ondersteunde printers |

### 6.2 Nadelen / Aandachtspunten

| Nadeel | Toelichting |
|:---|:---|
| **Connector voor legacy-printers** | Vestigingen met legacy-printers (een minderheid bij Soudal) hebben een Windows-machine nodig die 24/7 aanstaat — het merendeel van de vloot is UP-ready en heeft geen Connector nodig |
| **Geen automatische locatiedetectie** | IT moet 30+ AD-groepen aanmaken en bijhouden — handmatige overhead bij locatiewijzigingen |
| **Geen toner monitoring** | Geen SNMP-integratie — geen inzicht in toner%, papier of printerstatus |
| **Geen driver-beheer** | Geen mogelijkheid om drivers te vergrendelen, distribueren of centraal te updaten |
| **Beperkte rapportages** | Alleen basis job-counts — geen kostanalyse, geen CO2, geen Power BI template |
| **Badge-auth vereist OEM-integratie** | Werkt alleen op native UP-ready printers met OEM-integratie — niet op Connector-printers. Het merendeel van de Soudal-vloot is UP-ready, maar OEM-partnerintegratie is apart vereist. |
| **Print job pool — F3 risico** | F3-licenties leveren slechts 5 jobs/maand bij — bij veel frontline-users snel uitgeput |
| **PIM-vereiste** | Elke beheertaak vereist rolactivatie — operationele overhead voor IT. De RBAC-blokkades tijdens de PoC waren specifiek voor het stagiair-account; een volwaardige admin zou hier geen problemen mee moeten ervaren. |
| **Geen high availability** | Connector heeft geen HA-mode — bij uitval van de Connector-machine valt printen op die locatie weg |
| **Meer initiële setup** | Per printer: lokaal delen + Connector-publicatie + Share aanmaken + groep koppelen |

> [!TIP]
> **Automatisering:** Hoewel de initiële setup en het doorlopend beheer veel handmatig werk vereisen, kan dit grotendeels geautomatiseerd worden met de **Automatisatie Scripts** (zie bijlagen) die het toevoegen van printers, shares en groepen versnellen.

### 6.3 Kostenanalyse MUP voor Soudal

**Directe kosten:** €0 extra — inbegrepen in bestaande M365 E5-licenties.

**Verborgen/indirecte kosten:**

| Kostenpost | Schatting | Toelichting |
|:---|:---|:---|
| Connector-machines (hardware) | Beperkt aantal × €400–800 | Alleen nodig voor vestigingen met legacy-printers (minderheid bij Soudal) |
| Stroom & onderhoud Connectors | Beperkt | Elektriciteitskosten + patching + monitoring (alleen voor legacy-locaties) |
| IT-uren initiële setup | Significant | Per locatie: printer installeren, share aanmaken, groepen beheren |
| IT-uren doorlopend beheer | Significant | Groepslidmaatschappen bijhouden bij locatiewijzigingen |
| Extra print jobs (indien nodig) | $25 / 500 jobs | Als pool onvoldoende blijkt |

> **Conclusie:** MUP is niet gratis wanneer je alle indirecte kosten meeneemt. De Connector-machines zijn echter alleen nodig voor het beperkte aantal legacy-printers bij Soudal, waardoor de hardware-investering aanzienlijk lager uitvalt dan oorspronkelijk ingeschat. De grootste indirecte kost blijft de doorlopende beheer-overhead voor AD-groepen en locatietoewijzing. Ter vergelijking: de totaalkost voor Printix voor 2.500 gebruikers bedraagt ~€30.000/jaar.

### 6.4 Eindoordeel

MUP is een **valide maar beperkte** printoplossing voor Soudal. Een positief punt is dat het merendeel van de Soudal-vloot UP-ready is, waardoor de Connector-afhankelijkheid beperkt blijft. De praktijktesten in Week 5 hebben echter de volgende beperkingen concreet bevestigd:

*   **Offline kwetsbaarheid:** Het volledige falen bij internetuitval — zonder enige lokale fallback of spooling — maakt MUP ongeschikt als enige printoplossing voor productiekritieke omgevingen.
*   **Driver-functiekloof:** De afgedwongen Universal Print Class Driver biedt onvoldoende functionaliteit voor afdelingen die afhankelijk zijn van merkspecifieke printopties (nieting, boekjesvouw, speciale papierinvoer).
*   **PIM-overhead:** De PIM-vereiste bij Soudal voegt een extra stap toe aan elke beheersessie. De RBAC-blokkades die tijdens de PoC werden ervaren, waren specifiek voor het beperkte stagiair-account en vormen geen verwacht probleem voor een volwaardige IT-admin.

Voor Soudal's specifieke context — wereldwijde vloot, behoefte aan toner-monitoring, geavanceerd driver-beheer en operationele veerkracht — schiet MUP tekort als **standalone** oplossing.

**Aanbeveling:** Gebruik MUP als **aanvullende vanglaag** bovenop Printix via de ingebouwde integratie. Printix publiceert print queues naar Universal Print. Apparaten zonder Printix Client (thin clients, bezoekers, kiosk-apparaten) printen via MUP. Dit geeft het beste van beide werelden zonder dubbele beheerlast.

---

## 7. Aanbevelingen voor Vervolgstappen

### Korte termijn (Binnen 1 maand)
1.  **MUP-integratie activeren in Printix portal:** Settings → Integrations → Microsoft Universal Print → Accept.
2.  Kritieke print queues publiceren naar Universal Print voor thin clients en bezoekers.
3.  Universal Print Anywhere inschakelen op de gepubliceerde shares.

### Middellange termijn (1–3 maanden)
4.  Inventariseren welke van de weinige legacy-modellen in aanmerking komen voor vervanging door UP-ready modellen.
5.  Azure AD-groepen per locatie aanmaken als voorbereiding op eventuele uitbreiding van MUP.

### Lange termijn (3–6 maanden)
6.  Bij prijsverhoging van Printix: heroverweeg MUP als primaire oplossing — MUP evolueert snel en de functiekloof verkleint.
7.  Monitor Microsoft's roadmap voor badge-authenticatie op Connector-printers en toner-integratie.

---

## 8. Bijlagen & Referenties

### Nuttige Links
| Resource | URL |
|:---|:---|
| Automatisatie Scripts (GitHub) | `https://git.pefki.xyz/pefki/MS-UP-Soudal/src/branch/main/scripts` |
| Azure Portal Universal Print | `https://portal.azure.com` → Universal Print |
| Connector Download | `https://aka.ms/UPConnector` |
| Microsoft Docs | `https://learn.microsoft.com/en-us/universal-print/` |
| Licentie-informatie | `https://aka.ms/UPLicensing` |
| M365 Admin Center | `https://admin.microsoft.com` |

### Gerelateerde Documenten
| Bestand | Beschrijving |
|:---|:---|
| `MUP_Gebruikershandleiding_DRAFT.md` | Handleiding voor admins en eindgebruikers |
| `FINALISATIE_CHECKLIST_MUP.md` | Stap-voor-stap uitrolhandleiding |
| `MUP_Logboek_Week1_DRAFT.md` | Dagelijks logboek van het onderzoek |
| `Printix_PoC_Eindverslag.md` | Eindverslag Fase 1 ter vergelijking |
| `Vergelijking_Printix_vs_MUP.md` | Volledig vergelijkingsdocument (zie map Verslag & notitites) |

---

*Opgesteld mei 2026 — Soudal Group, Turnhout*
*Auteur: Rayan (Stagiair Infrastructuur)*
