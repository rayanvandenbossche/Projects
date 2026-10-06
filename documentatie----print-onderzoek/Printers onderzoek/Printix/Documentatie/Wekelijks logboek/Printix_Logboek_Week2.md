# Printix PoC - Logboek Week 2 

Dit logboek wordt gebruikt om dagelijks de voortgang, configuratiewijzigingen en opgeloste problemen in the Printix-omgeving van Soudal bij te houden.

---

## Maandag 20 April 2026
*Hier noteren we de acties en problemen van vandaag.*

### Acties Uitgevoerd
- [x] **Global Admin Permissies Verkregen:** Permissies voor Entra ID geaccepteerd in the Printix Portal.
- [x] **Groepen Gesynchroniseerd:** Alle Microsoft Entra ID (Azure AD) groepen succesvol in the administratieportal geladen.
- [x] **Printix Client Test:** Client lokaal geïnstalleerd; catalogus met 400+ wereldwijde printers is direct zichtbaar en het installeren werkte perfect.
- [/] **Systeem Reset voor Discovery:** Besloten om de volledige vloot (435 printers) te wissen om een "pure" test van de automatische discovery functie te doen.

### Issues & Oplossingen
- **Issue:** Geen Entra ID groepen per filiaal (bijv. "Afd_Turnhout"), waardoor locatiespecifieke rechten via groepen onmogelijk lijken.
- **Issue:** Ontbrekende of incorrecte netwerkranges voor alle wereldwijde filialen, en dit handmatig invoeren in Printix is te veel werk voor een stagiair. Verder kan de Printix Client niet op elke externe locatie gelijktijdig worden getest, waardoor Automatische Netwerkdetectie momenteel hapert.
- **Issue:** Printix Helpdesk gaf aan dat bulk-aanpassingen voor *Print Queues* naar *Entra ID Groepen* onmogelijk zijn via de API. Ook het bulk-aanpassen van Netwerken leek onmogelijk via het properties-scherm ("Add printer" wizard). Dit kwam door de foutieve aanname dat *Print Queues* het fysieke netwerk bepalen, in plaats van de menuknop *Printers*. Verder wekte de knop "Discover Printers" in the cloud verwarring, omdat the cloud zelf netwerken niet lokaal kan scannen.
- **Oplossing (Netwerken Koppelen):** Navigeer naar het hoofdmenu (via de drie streepjes rechtsboven) **Printers** (fysieke hardware). Vink de te filteren IP-range aan (bijv Turnhout: `10.0.10.`) en druk onderaan op *Modify*. Hier kun je met 2 klikken wél honderden fysieke printers koppelen aan een Network, iets wat via de Queues onmogelijk leek.
- **Issue (API Automation):** Het script `Reset-Printers.ps1` faalde met een SSL EOF fout (`The SSL connection could not be established`). Dit wordt waarschijnlijk veroorzaakt door de Soudal firewall/SSL-inspection die de PowerShell API-calls blokkeert.
- **Oplossing (Manual Pivot):** Overschakelen op handmatige bulk-selectie in het hoofdmenu **Printers** van de Printix Portal om de lijst op te schonen voor de discovery-test.

---

## Architectuur & Werkwijze: Nieuwe Inzichten (Week 2) 
Vandaag zijn er cruciale architecturale keuzes vastgelegd over hoe Printix wordt ingericht ten opzichte van traditionele Print Servers:

### A. Geen AD Groepen voor Locaties Nodig
In de oude omgeving kregen gebruikers printers toegewezen op basis van Microsoft Entra ID (Azure AD) groepen (bijv. "Afd_Turnhout" of "Afd_Heist"). 
*   **De Printix Aanpak:** Printers worden in de cloud puur gekoppeld aan hun fysieke `Network` (Gateway MAC-adres). Zodra een medewerker inplugt in kantoor Turnhout, detecteert de Printix Client dit netwerk en presenteert **automatisch** alleen de Turnhout printers. Entra ID groepen zijn dus uitsluitend nodig voor overkoepelende rechten of "Print Anywhere" policies.

### B. Cloud Discovery vs. CSV Import
De Printix Cloud staat extern en kan **niet** door de Soudal firewalls heen scannen. 
*   **De Printix Werking:** Scan-opdrachten (Discovery) werken uitsluitend wanneer er ten minste één computer/server mét de Printix Client aanstaat op die fysieke locatie om het commando uit te voeren. 
*   **De CSV Validatie:** Dit bevestigt waarom the bulk CSV-import via de PowerShell SNMP scanner nodig was: hiermee konden we alle wereldwijde data importeren vóór de werkelijke Client-uitrol.

### C. Handmatige Netwerk Mapping (Printers vs Queues)
*   **De Valstrik:** Navigeer **niet** naar de *Print Queues* pagina voor locatiewijzigingen, zoals the Helpdesk leek te suggereren. Het wijzigen van "Print Queues" API rechten lost routing op, niet locatie.
*   **De Werkwijze:** Netwerk-mapping gebeurt structureel vanuit het hoofdmenu **Printers**. Door te filteren op IP-reeksen kun je in de hoofdtabel moeiteloos tientallen apparaten aanvinken en via **Modify** in bulk toewijzen aan het betreffende turnhout netwerk.

---

## Dinsdag 21 April 2026
*Focus op Discovery validatie en geavanceerde Printix functies.*

### Acties Uitgevoerd
- [x] **Discovery Flow Verificatie:** Bevestigd dat de Printix Server (`BE-TUR-HPJET-02`) succesvol een scan heeft uitgevoerd en printers heeft ontdekt.
- [x] **Remote Discovery Vastgesteld:** Ontdekt dat de server in Turnhout ook printers in Oostenrijk (`10.6.65.x`) kan zien via SNMP, wat de routering tussen locaties bevestigt.
- [x] **Database Cleanup:** Handmatige opschoning van de printerlijst uitgevoerd om "ruis" (buitenlandse printers) te minimaliseren voor de testfase in Turnhout.
- [x] **Automatische Deployment (UX Test):** Bewezen dat printers foutloos en automatisch (zonder gebruikersinteractie) op de laptop van een werknemer verschijnen zodra deze worden toegewezen aan een Azure AD groep (Getest met groep `soudal_turnhout_print`).
- [/] **Onderzoek Geavanceerde Functies:** Bestuderen van de Printix routeringsmechanismen bij locatiespecifieke gesegmenteerde netwerken.

### Issues & Oplossingen
- **Issue:** Discovery vanaf laptop (`Network1`) vond geen printers, terwijl de server (`Network2`) wél resultaten gaf.
- **Oplossing (Gateway Routing):** Oorzaak gevonden! De server zocht specifiek binnen zijn eigen gedefinieerde netwerk. Omdat de laptop in een ander netwerk zat (met een andere gateway), koppelde Printix deze niet aan elkaar. Door de gateway van de laptop/PC als subnet toe te voegen aan het netwerkprofiel van de server in de portal, herkent Printix nu wél de laptops en kunnen zij de printers in dat netwerk zien.
- **Issue:** Print-opdracht vanaf de PC bleef "Pending". Dit lag bleek aan het feit dat poort-verkeer over de segmenten afgeschermd wordt en "Via the cloud" uitstond.
- **Issue:** Tweede User-Test (Collega) werkte niet zoals verwacht in Turnhout, de queues kwamen niet binnen.
- **Actie (Lopend):** Printix Client van de collega verwijderd en opnieuw geïnstalleerd. We onderzoeken of er nog andere groeps- of netwerkfactoren de push tegenhouden.
- **Oorzaak "Nieuw-Zeeland" Printers:** Ontdekt dat de collega naar de verkeerde tenant URL was genavigeerd (`soudal.printix.net` in plaats van `soudal-test.printix.net`). Hierdoor werden printers uit een oude/andere omgeving getoond en registreerde zijn PC zich niet in onze actieve test-omgeving onder 'Computers'.
- **Bevestiging "Software Identifier" Fout:** Bij Printix blijkt de gedownloade client uniek gebonden aan de tenant. Omdat de collega een generieke/productie client gebruikte installeerde hij eigenlijk voor de verkeerde omgeving. De client werd succesvol verwijderd en hij werd herverwezen naar de `soudal-test.printix.net/download` link.
- **Aangepaste Test-Strategie:** Om variabelen met Azure AD groepen uit te sluiten, gaan we overschakelen op **Netwerk-gebaseerde automatische distributie** (Apparaten krijgen de printer puur op basis van hun IP/Gateway, zonder tussenkomst van groepen).
- **Issue:** Printers die via een PowerShell-script werden geregistreerd in Microsoft Universal Print, verschenen in de Printix client met een sterretje (★) en hun MUP share-naam.
- **Oplossing:** Na onderzoek bleek dit geen bug of integratiefout te zijn. De Printix client was geïnstalleerd op dezelfde machine waarop het script de MUP-printers lokaal had geïnstalleerd via Windows. De Printix client toont standaard alle lokaal geïnstalleerde Windows-printers, ongeacht hun oorsprong. Het sterretje is de manier waarop Printix aangeeft dat een printer niet via zijn eigen systeem werd toegevoegd. Opgelost door de betreffende printers handmatig te verwijderen via *Windows Instellingen → Printers en scanners* op die machine.



---

## Woensdag 22 April 2026
*Succesvolle afronding User Acceptance Testing en bugfixing.*

### Acties Uitgevoerd
- [x] **Herstel "Software Identifier" Fout:** Collega heeft de correcte Printix Client (.exe) gedownload via de specifieke test-tenant (`soudal-test.printix.net/download`).
- [x] **Succesvolle User Test (UAT):** Na installatie van de juiste client was de computer direct zichtbaar en geautoriseerd in de portal.
- [x] **Validatie Auto-Deployment:** De juiste Turnhout printers werden foutloos en automatisch gepusht naar de laptop van de collega.
- [x] **Hybride Deployment Strategie Vastgelegd:** We hebben definitief de werkwijze voor de IT-afdeling bepaald:
  1. *Core Printers:* De 2-3 belangrijkste/meest gebruikte printers per locatie worden volautomatisch naar de gebruikers gepusht via **Azure AD Groepen** (bijv. `soudal_turnhout_print`).
  2. *Self-Service:* Alle overige honderden specifieke printers worden niet onnodig geïnstalleerd, maar blijven in de cloud beschikbaar. Gebruikers kunnen via het Printix-koffertje zelf veilige en lokale printers toevoegen vanuit een overzichtelijke lijst of plattegrond.
- [x] **Validatie Secure Print (Print Anywhere):** Succesvol een Pull-Printing proof-of-concept voltooid. Een document is naar de generieke 'Printix Anywhere' cloud-wachtrij verstuurd en vervolgens veilig handmatig vrijgegeven (release) via de werknemers-webApp (`/app`).
- [x] **Validatie Rapportages & Analytics:** Bevestigd dat alle test-printopdrachten (van laptop en server) correct worden geregistreerd in de Printix Portal. Data over gebruiker, printer en volume is direct inzichtelijk voor IT-beheer.
- [/] **Test Mobile Printing:** Start van de testfase voor afdrukken vanaf smartphones (iOS/Android) via de Printix App.

### Issues & Oplossingen
- **Issue:** Gebruikers bleven onbedoeld de rol "Site Manager" behouden (zoals te zien in de User History), zelfs nadat de betreffende 'Site' al was verwijderd uit de portal.
- **Oorzaak:** Een 'Orphaned Role' probleem. Wanneer een Site wordt verwijderd terwijl er nog een 'Site Manager Group' aan gekoppeld is, blijven de individuele gebruikers in die groep soms hun verhoogde rechten houden in de database van Printix.
- **Oplossing:** Een nieuwe tijdelijke locatie (Site) aangemaakt, de betreffende groep opnieuw als 'Site Manager Group' gekoppeld, deze koppeling vervolgens expliciet verwijderd, en daarna pas de tijdelijke Site weer gewist. Dit forceerde een database-update waardoor de rollen van de gebruikers weer naar "User" werden gereset.
- **Issue:** Gisteren was er verwarring rond onzichtbare printers / falende auto-deployment bij een collega.
- **Oplossing (Bevestigd):** Dit is 100% toe te wijzen aan de "Software Identifier" fout, waarbij hij via de verkeerde tenant (soudal.printix.net in plaats van soudal-test) installeerde. Nu de juiste test-tenant installer is gebruikt, werkt alles zoals het hoort. Geen complexe netwerkfouten, puur een URL-vergissing.

###  Onderzoeksnotitie: Printix Analytics & Rapportage (Power BI)

**1. Systeemarchitectuur**
Printix verzamelt gedetailleerde gegevens van elke printopdracht (gebruiker, printer, aantal pagina's, kleurinstellingen, etc.). Deze data wordt ontsloten via een cloud-gebaseerde SQL-database. Voor dit onderzoek kan gebruik worden gemaakt van de door Printix gehoste database, maar voor een volledige uitrol bij Soudal kan een eigen Azure SQL-instantie gekoppeld worden voor langdurige opslag en compliancy.

**2. Power BI Integratie**
Door gebruik te maken van het standaard Printix Power BI-template (`.pbit`), kan de ruwe data worden omgezet in visuele managementdashboards. Dit biedt de volgende inzichten:
*   **Kostenbesparingen:** Inzicht in 'Paper Save' statistieken (documenten die zijn verstuurd maar nooit fysiek zijn geprint dankzij de Release-functie).
*   **Gebruikersgedrag:** Analyse van printvolume per afdeling of vestiging (bijv. België vs. Frankrijk).
*   **Milieu-impact:** De 'Tree-O-Meter' rapporteert over de CO2-voetafdruk en het aantal verbruikte bomen op basis van het papierverbruik.
*   **Infrastructuur optimalisatie:** Identificatie van onderbenutte printers versus overbelaste apparaten.

**3. Strategische waarde voor Soudal**
De implementatie van Analytics maakt het mogelijk om printkosten wereldwijd te consolideren in één dashboard. Dit ondersteunt IT-management bij het nemen van data-gedreven beslissingen over de vervanging van hardware en het stimuleren van duurzaam printgedrag binnen de organisatie.

---

## Donderdag 23 April 2026
*Laatste testdag: AI-functies evalueren en mass deployment voorbereiden.*

### Acties Uitgevoerd
- [x] **Evaluatie Printix Generative AI:** De ingebouwde AI-assistent van Printix getest. Conclusie: niet bijzonder nuttig voor ons gebruik. De functie biedt basis-suggesties, maar voegt weinig waarde toe aan het dagelijkse printerbeheer.
- [x] **Onderzoek OpenAI / Azure AI Integratie:** Printix biedt een koppeling met OpenAI (GPT) of Azure OpenAI, maar hiervoor is een API-key en URL nodig die gekoppeld zijn aan een betaald abonnement met credits. Soudal beschikt hier momenteel niet over, dus deze functie is voor de PoC niet inzetbaar.
- [x] **MSI Deployment Handleiding Opgesteld:** De Printix Client `.msi` installer gedownload en onderzocht. De daadwerkelijke uitrol naar alle werkstations valt buiten de scope van de stage en is de verantwoordelijkheid van het Soudal IT-team. Een uitgebreide overdracht-handleiding (Intune Win32 App + GPO-methode) is opgenomen in de FINALISATIE_CHECKLIST (Fase 7).
- [x] **Eindverslag Opgesteld:** Een uitgebreid eindverslag (`Printix_PoC_Eindverslag.md`) geschreven ter presentatie aan de coaches. Het verslag omvat: managementsamenvatting, alle uitgevoerde tests, architecturale bevindingen, een voor/tegen-evaluatie, en concrete aanbevelingen voor vervolgstappen.
- [x] **Projectopruiming:** Alle overbodige, verouderde of incorrecte bestanden verwijderd uit de projectmap (oude draft-plannen, gefaalde scripts, dubbele bestanden).

### Issues & Oplossingen
- **Bevinding (AI):** De Printix AI-functie is een "nice-to-have" maar geen must. Zonder een eigen OpenAI/Azure abonnement met API-credits is de geavanceerde AI-integratie niet bruikbaar voor Soudal.

---

## Vrijdag 24 April 2026

### Acties Uitgevoerd
- [x] **Documentatie Afronding:** Alle documenten (Eindverslag, Gebruikershandleiding, Checklist) gefinaliseerd. Specifieke secties toegevoegd over Microsoft-integraties (Universal Print & Cloud Scan).
- [x] **Geavanceerde Beheerfuncties Documenteren:** Gedetailleerde instructies toegevoegd over Driver Locking, Configuratie Distributie en Bulk Updates om een stabiele vloot te garanderen.
- [x] **Projectmap Opschoning:** Alle overbodige testscripts, verouderde blogdrafts en tijdelijke bestanden verwijderd om een schone projectmap op te leveren voor het Soudal IT-team.
- [x] **Kostenmodel Verfijning:** Het licentiemodel gedocumenteerd met focus op de ~5.000 gebruikers van Soudal, inclusief de actieve-gebruiker regels en enterprise-kortingen.
- [x] **Professionalisering:** Alle AI-verwijzingen en "Copilot" sporen verwijderd uit de documentatie voor een professionele uitstraling van het stageproduct.
- [x] **Architecturale Uitdieping:** Secties 4.6 en 4.7 toegevoegd aan het eindverslag. Focus op het verschil tussen centrale configuratie (dashboard) en lokale uitvoering (client) en het verdwijnen van traditionele sharenames.
- [x] **Migratiestrategie Analyse:** Twee methodes (Discovery & Bulk Import) uitgewerkt voor het behoud van bestaande Sharenames tijdens de overstap naar Printix (Sectie 4.8 & 1.12).

### Issues & Oplossingen
- **Bevinding (Universal Print):** Vastgesteld dat Universal Print een waardevolle aanvulling is voor managed laptops of gastgebruikers, maar dat de limieten op Microsoft-printtegoeden nauwlettend gemonitord moeten worden als men dit naast Printix gebruikt.
- **Bevinding (Serverless):** Verduidelijkt dat "Sharenames" in een moderne cloud-printomgeving niet meer bestaan, behalve als technische "wrapper" binnen de Azure Universal Print integratie.
- **Bevinding (Productie):** Bevestigd dat printers in productie-omgevingen buiten de huidige Printix-scope vallen, wat de configuratie-eisen voor die specifieke zones vereenvoudigt.

---

## Evaluatie (Week 2): Is Printix de juiste keuze voor Soudal? 
Aan het einde van Week 2 is er een nieuwe balans opgemaakt over de infrastructuur en werkwijze van Printix voor een grootschalig bedrijf als Soudal.

**Voordelen voor het bedrijf (Pros):**
*   **Geen AD-Groepen Overvoed:** Printix toont aan dat lokaal printen perfect kan werken zónder het onderhouden van honderden locatie-gebaseerde Active Directory groepen. Het netwerk (Gateway MAC) bepaalt de locatie. Dit scheelt in theorie enorm veel beheer-uren.
*   **Decentrale Architectuur:** Printix elimineert de noodzaak om vanaf een centrale locatie alles te scannen. Door op elke vestiging de Client uit te rollen, wordt het systeem organisch opgebouwd.

**Nadelen / Risico's (Cons):**
*   **Steile Leercurve voor IT & Helpdesk:** De architectuur verschilt dermate van oude Printservers dat zelfs de officiële Printix Helpdesk soms verkeerde adviezen geeft (zoals focussen op Print Queues in plaats van physical Printers). Dit vereist een goede, waterdichte training voor the Soudal IT/Helpdesk.
*   **Kip-en-Ei probleem met Discovery:** Automatische discovery is geweldig, maar werkt uitsluitend als the Printix Client pre-installed is ter plaatse. Voor een "big bang" migratie waarbij IT vooraf de portal in the cloud wil voorbereiden (zonder overal clients te installeren), is Printix uiterst inflexibel zonder zwaar scriptwerk (zoals onze CSV-hack uit week 1).

---
*Gedocumenteerd door Rayan voor Soudal Group.*
