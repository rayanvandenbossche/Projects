# Wekelijks Logboek: Microsoft Universal Print PoC — Week 5 
**Project:** Soudal MUP PoC  
**Auteur:** Rayan  
**Periode:** Week 5 — Mei 2026 — Soudal Turnhout

---

## Dinsdag — Dag 2 (12 mei 2026)
*Focus: Connector-registratie, printerregistratie & rechtenanalyse.*

### Acties Uitgevoerd
- [x] **PIM-rol opnieuw geactiveerd:** De Universal Print Administrator-rol was verlopen en moest opnieuw worden geactiveerd via PIM. Dit bevestigt het operationele nadeel t.o.v. Printix (waar eenmalige consent permanent is).
- [x] **Connector-registratie onderzocht:** De Connector-service draaide lokaal op de machine ("Running" status in Windows Services), maar was **niet geregistreerd** in de Azure tenant. Dit zijn twee afzonderlijke statussen.
- [x] **Printer-registratie via Connector:** Ontdekt dat de knop "Add Printer" niet bestaat — de beschikbare printers verschijnen automatisch in de "Available Printers" lijst (vooraf geconfigureerd door collega/coach). De juiste actie is: aanvinken → **"Register"**.
- [x] **Volgorde-afhankelijkheid geïdentificeerd:** Printers kunnen pas geregistreerd worden nádat de Connector zelf is geregistreerd in Azure. Foutieve volgorde leidt tot mislukte registratie.
- [x] **Rechtenbeperking geconstateerd:** Het tabblad **Connectors** en andere beheertabbladen in de Universal Print-sectie van Azure Portal zijn **niet toegankelijk** met de huidige Print Administrator-rol. Mogelijk is een hogere rol of specifieke machtiging vereist.
- [x] **Printer toevoegen via Cloud Index:** Gevalideerd dat gebruikers printers toevoegen door in de Cloud Index te zoeken op Share Names (bijv. `\\laserprinters`). Het proces verloopt vlot en intuïtief. De onderliggende IP-architectuur is volledig verborgen voor de eindgebruiker — dit is een positief UX-aspect van MUP.
- [x] **Offline spooling test uitgevoerd:** Bij het uitschakelen van Wi-Fi verschijnt een **directe foutmelding** — printen is volledig onmogelijk zonder actieve internetverbinding. Er is geen enkele vorm van offline spooling of lokale wachtrij beschikbaar. Dit is een **kritiek nadeel** t.o.v. de Printix-client, die wél lokale spooling ondersteunt en opdrachten buffert bij tijdelijk connectiviteitsverlies.
- [x] **Driver-beperking gevalideerd (screenshot bevestigd):** MUP dwingt de **Universal Print Class Driver (IPP)** af. Gebruikers hebben uitsluitend toegang tot basisinstellingen: papierformaat, oriëntatie, duplex en aantal kopieën. Merkspecifieke interface-opties van Ricoh — waaronder geavanceerde nieting, boekjesvouw, perforatie, specifieke papierlade-selectie en kleurprofielbeheer — zijn **niet beschikbaar**. Dit beperkt de functionaliteit significant t.o.v. Printix, dat volledige OEM-drivers centraal distribueert.
- [x] **RBAC/PIM-blokkade verder onderzocht:** Zelfs na heractivatie van de Print Administrator-rol via PIM bleven essentiële tabbladen (met name **Connectors**) in de Azure Portal grijs en ontoegankelijk. Dit bewijst dat de RBAC-configuratie bij Soudal strenger is dan de Microsoft-documentatie suggereert, en resulteert in een aanzienlijk tragere "time-to-admin" dan bij Printix.

### Technische Uitdagingen & Oplossingen

| # | Probleem | Oorzaak | Oplossing |
|:---:|:---|:---|:---|
| 4 | **Connector niet zichtbaar in Azure Portal** ondanks "Running" status lokaal | De Connector-service draait lokaal als Windows-service, maar was niet geregistreerd in de Azure tenant. "Running" = lokale service actief ≠ Azure-registratie. | Registratie uitvoeren via de Connector-applicatie → knop "Register" of "Sign in to register" → aanmelden met Soudal-beheerdersaccount met actieve PIM-rol → verificatie in Azure Portal → Connectors. |
| 5 | **Geen "Add Printer" knop** zichtbaar in Connector | De printers stonden al in de "Available Printers" lijst omdat de Connector-machine vooraf was geconfigureerd door de collega/coach met lokaal geïnstalleerde printers. De knop heet "Register", niet "Add Printer". | Printer aanvinken in "Available Printers" → knop **"Register"** rechtsonder → status volgen in "Operation list". Eerst Connector registreren in Azure, daarna pas printers registreren. |
| 6 | **Volgorde-probleem:** Printerregistratie mislukt | Printers kunnen niet worden gepubliceerd naar Universal Print als de Connector zelf nog niet gekoppeld is aan de Azure tenant. | Correcte volgorde: 1) Connector registreren in Azure tenant → 2) Printers registreren via Connector → 3) Printer Shares aanmaken in Azure Portal → 4) Groepen koppelen aan Shares. |
| 7 | **PIM-sessie verlopen** — toegang geweigerd bij hervatting | PIM-rollen zijn tijdelijk (1-8 uur). Na enkele dagen inactiviteit was de sessie verlopen. | PIM opnieuw activeren via Azure Portal → Entra ID → PIM → Mijn rollen → Universal Print Administrator → Activeren. **Dit is een doorlopend operationeel nadeel t.o.v. Printix.** |
| 8 | **Printen mislukt bij internetuitval** | MUP heeft geen offline spooling-mechanisme. Alle printverkeer loopt via de Microsoft-cloud; zonder connectiviteit is geen spooling of caching mogelijk. | Geen oplossing beschikbaar binnen MUP. Aanbeveling: Printix-client als primaire laag behouden — deze biedt lokale spooling bij connectiviteitsverlies. |
| 9 | **Merkspecifieke printopties ontbreken** | MUP gebruikt de Universal Print Class Driver (IPP) en ondersteunt geen OEM-specifieke drivers of geavanceerde printerfuncties. | Geen oplossing binnen MUP. Voor gebruikers die geavanceerde functies nodig hebben: Printix als primaire printlaag met volledige OEM-driver distributie. |
| 10 | **Connectors-tabblad grijs/ontoegankelijk ondanks actieve PIM** | RBAC bij Soudal is strenger geconfigureerd dan standaard. De Print Administrator-rol is mogelijk onvoldoende of de PIM-scope beperkt schrijfrechten op bepaalde UP-secties. | Escalatie naar Soudal IT-beheer voor rolanalyse. Mogelijk is Global Administrator of een aangepaste Entra ID-rol vereist. **Dit is op zichzelf een bevinding die de beheercomplexiteit bevestigt.** |

### Praktijktest-samenvatting Dag 2

| Test | Resultaat | Beoordeling |
|:---|:---|:---:|
| Printer toevoegen via Cloud Index (Share Name) | Succesvol — vlotte gebruikerservaring | ✅ |
| Printen met actieve internetverbinding | Succesvol — document correct afgedrukt | ✅ |
| Printen zonder internetverbinding (Wi-Fi uit) | **Mislukt** — directe foutmelding, geen offline spooling | 🔴 |
| Geavanceerde printopties (nieting, finisher, papierlade) | **Niet beschikbaar** — enkel basisinstellingen via IPP Class Driver | 🔴 |
| Connectors-tabblad openen met Print Administrator + PIM | **Mislukt** — tabblad grijs/ontoegankelijk | 🔴 |
| PIM-rolactivatie na verloop | Succesvol — heractivatie werkt correct | ✅ |

### Architecturele Observatie: Connector vs. Printix Discovery

> **Belangrijk vergelijkingspunt:** Bij Printix werden 429 printers wereldwijd automatisch gevonden via SNMP-scan zonder lokale installatie per printer. Bij MUP moet elke printer **eerst lokaal worden geïnstalleerd** op de Connector-machine voordat hij kan worden gepubliceerd naar de cloud. Voor de Soudal-schaal (600+ printers, 30+ locaties) is dit een significante initiële tijdsinvestering.

### Nieuwe Architecturele Observatie: Offline Veerkracht

> **Kritiek verschil met Printix:** De Printix-client op de laptop van de gebruiker bevat een lokale spooling-laag. Bij tijdelijk verlies van internetconnectiviteit worden printopdrachten lokaal gebufferd en automatisch verzonden zodra de verbinding hersteld is. MUP biedt deze veerkracht **niet** — het systeem faalt direct en onherstelbaar bij connectiviteitsverlies. Voor productieomgevingen, magazijnen en vestigingen met instabiele WAN-verbindingen is dit een significant operationeel risico.

---

## Kritieke Bevinding: Rechtenbeperking & Impact op PoC-scope

### Wat is het probleem?
Met de huidige **Universal Print Administrator**-rol via PIM zijn de volgende tabbladen/functies in de Azure Portal **niet toegankelijk**:
- **Connectors** (overzicht van alle Connectors in de tenant)
- Mogelijk ook: **Printers**, **Printer Shares**, **Usage** (rapportages)

Dit betekent dat de volledige beheercyclus (Connector monitoren → Printers beheren → Shares aanmaken → Rapportages bekijken) **niet volledig getest kan worden** vanuit het huidige account.

### Mogelijke oorzaken
1. **De Print Administrator-rol is onvoldoende** — mogelijk is een **Global Administrator**- of **Printer Administrator**-rol (specifiek voor Azure) vereist voor volledige Connector-beheertoegang.
2. **RBAC (Role-Based Access Control)** in Azure is strenger geconfigureerd bij Soudal dan de standaard Microsoft-documentatie suggereert.
3. **PIM-scope is beperkt:** De PIM-rol geeft mogelijk alleen lees-rechten op bepaalde Universal Print-secties, geen schrijf/beheer-rechten.

### Impact op Testmogelijkheden

Hieronder een eerlijke analyse van wat wél en wat **niet** getest kan worden met de huidige rechten:

#### ✅ Wat WEL getest kan worden (zonder extra rechten)

| Test | Hoe | Status |
|:---|:---|:---:|
| **Printer toevoegen als gebruiker** | Windows Instellingen → Printers → Add device | Testbaar |
| **Printen via Universal Print** | CTRL+P → printer selecteren → afdrukken | Testbaar |
| **Locatie-groep validatie** | Testen of een gebruiker buiten de AD-groep de printer NIET ziet | Testbaar |
| **Driverless (IPP) functietest** | Controleren welke printopties beschikbaar zijn (nieten, duplex, kleur) | Testbaar |
| **Pull Print / Anywhere (QR)** | Document sturen → QR-code scannen met M365 app | Testbaar (indien Share correct geconfigureerd) |
| **PIM time-out ervaring** | Hoe snel verliest de admin toegang na PIM-verloop? | Reeds ondervonden ✅ |

#### ❌ Wat NIET getest kan worden (rechten ontbreken)

| Test | Waarom niet | Alternatief |
|:---|:---|:---|
| **Connector-status monitoren** | Connectors-tabblad niet toegankelijk | Documenteer als beperking |
| **Printer Share aanmaken/wijzigen** | Mogelijk geblokkeerd door RBAC | Vraag collega/coach om dit te doen |
| **Nieuwe printer registreren in Azure** | Vereist Connector-beheertoegang | Coach heeft dit voorbereid |
| **Usage/rapportages bekijken** | Mogelijk geblokkeerd | Documenteer als beperking |
| **Connector HA-test (uitval)** | Geen beheertoegang tot Connector | Theoretisch documenteren |
| **Print job pool monitoren** | Vereist admin-toegang tot Usage | Documenteer als beperking |

### Conclusie voor het Eindverslag

> **Deze rechtenbeperking is op zichzelf een bevinding.** Het feit dat een Print Administrator-rol onvoldoende is voor volledige MUP-beheertoegang bij Soudal, bevestigt dat de RBAC-configuratie van Soudal strenger is dan standaard. Dit versterkt het argument dat MUP meer beheercomplexiteit met zich meebrengt dan Printix, waar na eenmalige Global Admin consent de volledige Printix-portal zonder verdere rolactivatie beschikbaar is.

---

## Planning Rest van de Week

Gegeven de rechtenbeperking, focus op wat wél testbaar is:

- [x] **Test 1:** Printer toevoegen als eindgebruiker via Cloud Index (Share Name zoekfunctie) ✅
- [x] **Test 2:** Document printen via CTRL+P ✅
- [x] **Test 3:** Offline spooling test — Wi-Fi uitschakelen en printpoging 🔴 Mislukt
- [x] **Test 4:** Driverless functietest — geavanceerde opties (nieten, duplex, papierlade) 🔴 Beperkt tot basisinstellingen
- [ ] **Test 5:** Locatie-groep test (gebruiker zonder groep → geen printer zichtbaar?)
- [ ] **Test 6:** Pull Print via QR-code (indien Anywhere geconfigureerd)
- [x] **Test 7:** RBAC/PIM-rechtenvalidatie — Connectors-tabblad testen met actieve PIM 🔴 Ontoegankelijk
- [x] Resultaten documenteren in dit logboek ✅

---

*Gedocumenteerd door Rayan voor Soudal Group.*
