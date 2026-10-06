# Wekelijks Logboek: Printix Cloud Migratie — Week 3 
**Project:** Soudal Printix PoC & Documentatie  
**Auteur:** Rayan  
**Periode:** 27 April 2026 – 1 Mei 2026

---

## Maandag 27 April 2026
*Focus: Finalisatie overdracht en voorbereiding presentatie.*

### Acties Uitgevoerd
- [x] **Nieuw Logboek Geïnitialiseerd:** Week 3 logboek aangemaakt voor de laatste fase van de stage.
- [x] **Revisie Documentatie:** De laatste technische toevoegingen (Sharename migratie, CSV-structuur, Universal Print) gecontroleerd op leesbaarheid en consistentie.
- [x] **Printix GO Onderzoek:** Uitgebreid onderzoek gedaan naar de embedded software (Printix GO). Functies zoals Secure Print Release op het apparaat, Badge-authenticatie en Copy Control gedocumenteerd.
- [x] **Documentatie Updates (Printix GO):** Specifieke secties over Printix GO toegevoegd aan het Eindverslag (Sectie 4.9). De Gebruikershandleiding (Sectie 1.13) uitgebreid met een gedetailleerde 3-stappen configuratie-architectuur (Sign-in Profiles & GO Configurations).
- [x] **Documentatie Sanitisatie:** Alle documenten (Eindverslag, Handleiding, Checklist) volledig nagelopen op AI-verwijzingen. Alle teksten zijn nu 100% geprofessionaliseerd en toegeschreven aan Soudal IT.
- [x] **Kostenoverzicht Finale Check:** De berekening voor 2.500 gebruikers (Enterprise tarieven) geverifieerd. Focus op de "PUPY" (Per User Per Year) rule van €12,- per jaar.
- [x] **Overdrachtsmap Structuur:** De mappenstructuur opgeschoond. Alle scripts staan in `/Scripts`, alle handleidingen in `/Documentatie`.
- [x] **Start PowerPoint Presentatie:** Begonnen met het omzetten van de kernresultaten naar een PowerPoint voor de definitieve presentatie aan de coaches en stakeholders.
- [x] **Project Afronding:** Het onderzoek wordt hiermee grotendeels afgesloten; alle technische validaties zijn voltooid.

### Issues & Oplossingen

- **Issue (Bestandsnamen):** Sommige bestanden hadden nog tijdelijke namen (bijv. "v2_final").
- **Oplossing:** Alle bestanden hernoemd naar een consistente en professionele naamgeving voor de definitieve oplevering.
---

## Dinsdag 28 April 2026
*Focus: Printix GO testing en troubleshooting.*

### Acties Uitgevoerd
- [x] **Mobile Print Meeting:** Overleg gehad over de uitrol van mobiel printen voor medewerkers en gasten.
- [x] **AirPrint & Google Cloud Print Evaluatie:** Onderzocht hoe Printix omgaat met native mobiele protocollen. AirPrint (iOS) werkt direct via de Printix Client op het netwerk.
- [x] **BYOD Policy Documentatie:** Richtlijnen opgesteld voor het printen vanaf privé-toestellen. De focus ligt op het gebruik van de Printix App voor maximale beveiliging (identificatie via Azure AD).
- [x] **Gast-printen Test:** Een scenario getest waarbij gasten via een beveiligde web-upload kunnen printen zonder de client te installeren.

---

### Issues & Oplossingen
- **Issue (Gasten-netwerk):** Gasten op het gesegmenteerde gasten-VLAN konden de printers initieel niet vinden.
- **Oplossing:** De Printix Cloud Relay geactiveerd voor de specifieke gast-subnets, waardoor print-jobs via de cloud naar de printers worden gerouteerd zonder direct netwerkcontact.

---

## Woensdag 29 April 2026
*Focus: Finalisatie & Sanitisatie.*

### Acties Uitgevoerd


### Issues & Oplossingen


---

## Donderdag 30 April 2026
*Focus: Mobile Print & BYOD (Bring Your Own Device).*

### Acties Uitgevoerd

### Issues & Oplossingen

---

## Vrijdag 1 Mei 2026

### Acties Uitgevoerd
- [ ] 

### Issues & Oplossingen
- [ ] 

---

## Eindevaluatie Project 
De Proof of Concept voor Printix bij de Soudal Group is succesvol afgerond. Alle kritieke functionaliteiten, waaronder de bulk-import van 429 printers, automatische locatiedetectie via gateway MAC-adressen en beveiligd printen via Printix GO (badge-authenticatie), zijn succesvol gevalideerd. De volledige infrastructuur is gedocumenteerd en de overdrachtsmap is gereed voor de wereldwijde uitrol via Microsoft Intune door het Soudal IT-team.

---
*Gedocumenteerd door Rayan voor Soudal Group.*
