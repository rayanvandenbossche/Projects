# Eindrapport / Logboek Week 1: Printix Proof of Concept & SNMP Scan 

Dit document bevat het stage-logboek van Week 1, inclusief de succesvolle Printix-implementatie en de initiële SNMP-netwerkscan uitgevoerd voor de Soudal-infrastructuur.

---

## 1. Projectoverzicht & Doelstelling
Het doel van deze PoC was om de huidige, lokale printserver-gebaseerde printomgeving te moderniseren naar een cloud-oplossing via **Printix**. Dit biedt realtime zichtbaarheid in printerstatus, tonerlevels en maakt zelfbediening voor medewerkers mogelijk.

---

## 2. De SNMP Netwerkscan
Omdat de standaard scanmethodes traag zijn voor een netwerk van deze omvang (31.000+ IP-adressen), hebben we een op maat gemaakt PowerShell-script ontwikkeld: `snmp_scanner.ps1`.

*   **Bereik:** 31.231 IP-adressen (over meerdere wereldwijde subnets).
*   **Techniek:** Parallelle verwerking via PowerShell Runspaces (multithreading).
*   **Resultaat:** **444 apparaten** reageerden; na ontdubbeling zijn er **429 unieke printers** succesvol voorbereid voor de cloud.

---

## 3. Technische Uitdagingen & Oplossingen
Tijdens de import in de *Tungsten Printix Configurator* zijn we een aantal kritieke validatiefouten tegengekomen. Deze zijn structureel opgelost in het script:

| Probleem | Oorzaak | Oplossing in Script |
| :--- | :--- | :--- |
| **Ongeldige CSV & Rode Validatievelden** | Printix valideerde mapping van 'Network' en 'Vendor' onjuist als de waarden niet in de cloud bestonden. | Script exporteert nu exact de verwachte 7 kolommen, maar laat `Network`, `Vendor`, en `SerialNumber` bewust **leeg**. Hierdoor negeert Printix validatie en uploadt hij zonder fouten. |
| **Volledige Crash CSV Parser (#7 printer)** | De parser van de Printix Configurator struikelde over vreemde (binaire) leestekens van SNMP zoals `[` of `,` in specifieke HP-modellen. | Een strenge RegEx filter toegevoegd (`[^a-zA-Z0-9\- ]`) die alle speciale leestekens uit de **Model** namen sloopt vóór export. |
| **Dubbele Printers (Duplicaten)** | Omdat bepaalde IP-ranges / subnets deels overlapten, kwamen sommige printers dubbel in de CSV, wat validatiefouten gaf. | De output wordt via `Sort-Object Address -Unique` verplicht ontdubbeld op IP-adres voór de CSV wordt weggeschreven. |

### Belangrijke opmerking over Netwerken
Tijdens deze fase zijn de printers via de lege CSV-velden succesvol als "Unmapped Network" / default netwerk geüpload. Hierdoor is de strakke netwerkvalidatie-blokkade omzeild. Zodra de PoC is geslaagd en de IP-netwerken in Printix goed zijn geverifieerd, kunnen de printers in de Printix web-portal achteraf eenvoudig in bulk worden gekoppeld aan de juiste, specifieke locaties (Turnhout, Heist, etc.).

---

## 4. Validatie & Test Resultaat 
Onze test op **2 april 2026** was een succes:
1.  **Import:** 429 printers succesvol geüpload naar `soudal.printix.net`.
2.  **Configuratie:** Printer `10.0.10.125` geactiveerd en op "All networks" gezet.
3.  **Installatie:** De Printix Client op een test-laptop vond de printer direct via de cloud.
4.  **Afdruk:** Een fysieke testpagina is succesvol geprint vanaf de laptop via de Printix-cloud.

---

## 5. Architectuur & Werkwijze: De Nieuwe Aanpak 
Tijdens de verdere uitwerking van de PoC zijn er cruciale architecturale keuzes gemaakt over hoe Printix wordt ingericht ten opzichte van traditionele Print Servers.

### A. Geen AD Groepen voor Locaties
In de oude omgeving konden gebruikers printers zelf toevoegen via de lokale printserver-shares.
*   **De Printix Aanpak:** Printix maakt dit volledig overbodig. Printers worden in the cloud puur gekoppeld aan hun fysieke `Network` (geïdentificeerd door het Gateway MAC-adres). Zodra een medewerker (met de Printix Client) inplugt in kantoor Turnhout, detecteert de Client dit lokale netwerk en presenteert **automatisch** alleen de Turnhout printers in de self-service portal. Entra ID groepen zijn dus uitsluitend nog nodig voor beheerdersrechten of "Print Anywhere" policies.

### B. Cloud Discovery vs. CSV Import
De Printix Cloud staat buiten het bedrijfsnetwerk en kan op zichzelf **niet** door de Soudal firewalls heen scannen. 
*   **De Printix Aanpak:** Scan-opdrachten (Discovery) werken uitsluitend wanneer er ten minste één computer/server mét de Printix Client aanstaat op de betreffende fysieke locatie. De Cloud stuurt simpelweg een "scan commando" naar die specifieke lokale laptop.
*   **Waarom wij een CSV gebruikten:** Omdat we de Printix Client niet op 15 wereldwijde filialen tegelijk konden of mochten uitrollen ter voorbereiding, hebben we de *Cloud Discovery* doelbewust overgeslagen. We hebben centraal alle SNMP-data opgehaald via ons PowerShell-script en direct in de Cloud geïmporteerd.

### C. Handmatige Netwerk Mapping (Printers vs Queues)
Omdat de CSV printers veilig als "Unmapped" zijn geüpload, moeten deze achteraf aan de correcte vestiging gekoppeld worden.
*   **De Valstrik:** Navigeer **niet** naar de *Print Queues* pagina voor locatiewijzigingen (zoals de helpdesk suggereert). Deze menu-optie bepaalt alleen routering en cloud-rechten.
*   **De Precieze Werkwijze:** Netwerk-mapping gebeurt via het hoofdmenu (drie streepjes rechtsboven) → **Printers**. Door te filteren op IP-reeksen (bijv. `10.0.10.`) kun je in de hoofdtabel moeiteloos 30 fysieke apparaten aanvinken en via **Modify** in bulk toewijzen aan het betreffende netwerk.

---

## 6. Projectstatus na Week 1: Admin Consent 
De Global Administrator heeft de benodigde permissies verleend (einde Week 1).

### Uitgevoerde acties:
*   **"Accept for all users"** — Admin Consent verleend. SSO werkt voor alle werknemers.
*   **"Synchronize groups"** — Azure AD groepen succesvol gesynchroniseerd naar Printix.
*   *Details:* Zie het document **[Azure_AD_Permissies_Verzoek.md](../Verslag%20%26%20notitites/Azure_AD_Permissies_Verzoek.md)**.

---

## 7. Roadmap naar Productie 
Nu de PoC technisch is geslaagd, zijn dit de stappen om de volledige organisatie over te zetten:

1.  **Netwerk Segmentatie (Bulk-Aanpassing):** 
    De printers die via de CSV veilig als "Unmapped" zijn geüpload, moeten worden gekoppeld aan fysieke kantoorlocaties (Turnhout, Heist, etc.). 
    *   **⚠️ Belangrijke Valstrik (Print Queues vs. Printers):** De Printix Helpdesk gaf initieel aan dat bulk-wijzigingen via de API lastig zijn. Veel beheerders navigeren per ongeluk naar de *Print Queues* pagina en proberen daar het netwerk in bulk aan te passen. Dit is technisch onmogelijk. 
    *   **De Oplossing:** Om 30 printers tegelijk naar een filiaal te verplaatsen, navigeer in het linkermenu naar **Printers** (de fysieke hardware, niet de software wachtrijen). Selecteer via een IP-filter alle printers van een filiaal in the hoofdtabel, klik op *Modify*, en wijs ze in één klap toe aan het gewenste Network. Er wordt geen Cloud Discovery voor gebruikt.
2.  **Driver Optimalisatie:** Voor printers met specifieke afwerkingsopties (zoals plotters of finishers) de officiële merk-drivers uploaden in de portal.
3.  **Intune Deployment:** De Printix Client (.msi) inpakken als Win32-app. **Let op:** De configuratie en uitrol van dit pakket binnen de Soudal Intune-omgeving is de verantwoordelijkheid van de lokale beheerder.

---

## 8. Geavanceerde Mogelijkheden (Toekomst) 
Printix biedt functies die de print-ervaring bij Soudal verder kunnen verbeteren:

*   **Print Anywhere (Pull Printing):** Werknemers printen naar één globale wachtrij en 'vrijgeven' hun printje pas bij de printer met hun smartphone of badge.
*   **QR-Code Installatie:** Stickers op printers waarmee nieuwe medewerkers door simpelweg te scannen direct de juiste printer installeren.
*   **Analytics:** Diepgaand inzicht in printvolumes en kosten per afdeling/locatie.
*   **Guest Printing:** Veilig printen voor bezoekers zonder dat zij toegang tot het interne netwerk nodig hebben.

---

## 9. Onderhoud van de SNMP Scanner
Om de scanner flexibel te houden voor de toekomst, is het aanbevolen om de IP-ranges te automatiseren (bijv. via een extern bestand) in plaats van deze hardcoded in het script te laten staan.

---

## 10. Overzicht van Projectbestanden
De volgende bestanden zijn beschikbaar in de werkmap:
*   `Scripts/snmp_scanner.ps1`: Het geoptimaliseerde PowerShell scan-script.
*   `Scripts/Printix-API-Automation.ps1`: Het API-automatiseringsscript (referentie voor toekomstig gebruik).
*   `printix_printers_import.csv`: De laatste, gevalideerde lijst voor import.
*   `README.md`: De algemene projectbeschrijving.
*   `FINALISATIE_CHECKLIST_STAP_VOOR_STAP.md`: Het operationele draaiboek.
*   `Printix_PoC_Eindverslag.md`: Het eindverslag ter presentatie aan coaches.

---
## 11. Evaluatie (Week 1): Is Printix de juiste keuze voor Soudal? 
Op basis van de bevindingen in Week 1 is er een pre-evaluatie gemaakt:

**Voordelen voor het bedrijf (Pros):**
*   **Volledig Serverless:** Het elimineert de noodzaak en het onderhoud voor oude lokale printservers op The Soudal-filialen.
*   **Snel in kaart gebracht:** Ondanks het enorme netwerk (400+ printers), kon via een eigen SNMP PowerShell-script The hele vloot in the Cloud worden voorbereid.
*   **Gestandaardiseerde cloud-omgeving:** Alle apparaten staan in 1 overzichtelijk Cloud-dashboard ongeacht waar ze op de wereld staan.

**Nadelen / Risico's (Cons):**
*   **Gevoelige Cloud Parser (Configurator):** De import-applicatie van Printix crashte volledig op simpele onverwachte symbolen in bepaalde HP/Ricoh printers. Voor een enterprise-omgeving betekent dit dat je data clean-ups moet forceren (via scripts regex) omdat Printix zelf vastloopt op onbekende karakters.
*   **Strenge validatie errors:** Bij duplicaten van printers (overlap in filialen) of onbekende netwerknamen blokkeert Printix onmiddellijk, wat erg veel tijdrooft bij een grote organisatie als "Soudal".

---
**Status: Documentatie week 1** 
*Gedocumenteerd door Rayan voor Soudal Group.*
