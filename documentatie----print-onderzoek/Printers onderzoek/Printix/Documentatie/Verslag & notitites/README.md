# Project Documentatie: Nieuwe Printinfrastructuur Soudal Group 

## 1. Projectcontext & Doelstellingen
Soudal Group maakt de overgang van een lokale Active Directory-omgeving naar **Microsoft Entra ID (Azure AD)** met **Intune**-beheer. De huidige printopstelling (600+ printers) is gedecentraliseerd en onoverzichtelijk. 

**De belangrijkste pijnpunten zijn:**
*   **Inventaris:** Geen realtime overzicht van actieve printers.
*   **Contracten:** Onduidelijkheid over servicecontracten en SLA-status.
*   **Verbruiksartikelen:** Onbetrouwbare geautomatiseerde tonerleveringstracking.
*   **Implementatie:** Behoefte aan een moderne vervanging voor handmatig beheer van printservers nu endpoints via Intune worden beheerd.

## 2. Praktische Gegevens (Stage / Projectaanvraag)
*   **Klant:** Soudal Group (Soudal NV, Everdongenlaan 18-20, 2300 Turnhout)
*   **Periode:** April – Juni 2026 (Academiejaar 2025–2026)
*   **Contactpersonen:** Dries Wuyts / Bart De Cuyper / Niels Gevers
*   **Technologie:** Infrastructuur (Entra ID, Intune, Print Oplossingen)

---

## 3. Voorbereidend Onderzoek: Migratie & Oplossingen

Er zijn verschillende pistes om de traditionele printservers te vervangen. Hieronder een beknopt overzicht van de opties uit je documentatie:

### A. Microsoft Universal Print (UP) - Focusgebied
De native "Cloud Print"-oplossing van Microsoft, perfect geïntegreerd in M365 en Intune.
*   **Sterktes:** Native integratie in Azure/Entra portal, geen third-party agents nodig, inbegrepen in bestaande M365 licenties, geen lokale printservers nodig.
*   **Zwaktes:** Vereist een 'Connector' voor oudere (niet UP-ready) printers. Basis beheer (geen native inzicht in toner of papier), licenties gebaseerd op job-volumes.

### B. Alternatieven COTS/SaaS
*   **Printix:** Vendor-agnostic SaaS, zeer geschikt voor Direct-IP (lokaal) netwerkverkeer, sterke SNMP discovery en tonermonitoring. Vereist een eigen agent in Intune plus abonnementskosten per maand.
*   **PrinterLogic:** Marktleider voor serverloos printen in enterprises. Sterke self-service floorplans en top-tier monitoring.
*   **PaperCut Hive:** Edge mesh technologie (zeer hoge betrouwbaarheid) met focus op "Find-Me" veilige release en duurzaamheid.

### C. Open Source / Gratis Tools
*   **SavaPage:** Uitgebreide suite voor pull-printing (AGPL), kan integreren met Entra ID via OAuth2, maar vergt hoge setup en onderhoud resources.
*   **Printune:** Puur een tool om snel Win32 Intune packages te maken van drivers (handig voor implementatie, maar geen beheer).
*   **Vendor software (HP Web Jetadmin / Canon iW):** Gratis, perfect voor hardware en toner monitoring voor hun eigen vloten, maar werkt niet voor Entra ID deployment.

---

## 4. Stappenplan: Printix PoC —  VOLTOOID

De Printix Proof of Concept is succesvol afgerond. Hieronder een overzicht van de uitgevoerde fases:

### Fase 1: Printix Trial & Netwerk Ontdekking (SNMP) -  VOLTOOID
We hebben de printers via SNMP bereikbaar gemaakt en hun data succesvol ingelezen via een custom PowerShell script.
1.  **SNMP Scanner:** We hebben `snmp_scanner.ps1` ontwikkeld die 31.000+ IP's heeft gescand.
2.  **Resultaat:** **429 unieke printers** gevonden en succesvol geüpload naar de Printix Cloud.

### Fase 2: Entra ID Integratie & User Testing -  VOLTOOID
1.  **Admin Consent:** Global Admin permissies verleend, Azure AD groepen gesynchroniseerd.
2.  **User Acceptance Tests:** Succesvol gevalideerd met 2 testgebruikers (automatische deployment, secure print, rapportages).

### Fase 3: Intune Deployment -  OVERDRACHT AAN SOUDAL IT
De uitrol van de `.msi` client naar alle werkstations is gedocumenteerd en overgedragen aan het Soudal IT-team.

---

## 5. Technische Log & Troubleshooting (Geleerde Lessen)

Tijdens de Proof of Concept zijn we een aantal kritieke punten tegengekomen die cruciaal zijn voor een enterprise-omgeving:

*   **CSV Validatie:** Printix is extreem streng op de lay-out. Alle 7 kolommen moeten exact kloppen en mogen niet leeg zijn voor essentiële data.
*   **Netwerk Namen:** De portal weigert imports van onbekende netwerken. De veilige route is om ze eerst naar een generiek netwerk (zoals `Network2`) te importeren en daarna te segmenteren.
*   **MAC Formattering:** Verwijder altijd dubbele punten (`:`) uit SNMP data voor de soepelste import.
*   **Vendor Logica:** Gebruik Regex-matching op de modelnaam om automatisch de Vendor kolom te voeden.
*   **Software Identifier:** De Printix Client is uniek gebonden aan de tenant-URL. Download altijd via `soudal-test.printix.net/download`.
*   **Gateway Routing:** Alle VLAN-gateways moeten worden toegevoegd aan het netwerkprofiel in de portal, anders worden laptops in dat VLAN niet herkend.

---

## 6. Verdere Documentatie
Voor het volledige eindverslag en gedetailleerde bevindingen, zie:
 **[Printix_PoC_Eindverslag.md](Printix_PoC_Eindverslag.md)**
 **[FINALISATIE_CHECKLIST_STAP_VOOR_STAP.md](FINALISATIE_CHECKLIST_STAP_VOOR_STAP.md)**
 **[Printix_Wereldwijd_Deployment_Stappenplan.md](Printix_Wereldwijd_Deployment_Stappenplan.md)**


