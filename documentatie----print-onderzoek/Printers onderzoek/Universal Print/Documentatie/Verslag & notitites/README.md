# Microsoft Universal Print — Documentatie Overzicht 
## Soudal Group | PoC Fase 2

---

## Over dit Project

Dit is de documentatiemap voor de **Microsoft Universal Print (MUP)** Proof of Concept bij de Soudal Group. Dit onderzoek vormt **Fase 2** van een twee-fasen evaluatie van cloud-printoplossingen, waarbij Fase 1 reeds werd afgerond met **Printix (Tungsten Automation)**.

Het doel is een eerlijke, data-gedreven vergelijking te maken tussen beide oplossingen om de Soudal IT-afdeling in staat te stellen een weloverwogen beslissing te nemen over de toekomstige printinfrastructuur.

---

---

## Status: `Afgerond (Evaluatie voltooid — Mei 2026)`

| Document | Status | Beschrijving |
|:---|:---:|:---|
| MUP_PoC_Eindverslag_DRAFT.md | ✅ Voltooid | Definitief verslag inclusief praktijktestresultaten Week 5 |
| FINALISATIE_CHECKLIST_MUP.md | ✅ Voltooid | Volledige stap-voor-stap handleiding voor Soudal IT |
| Vergelijking_Printix_vs_MUP.md | ✅ Voltooid | Uitgebreide management-vergelijking en advies |
| MUP_Logboek_Week5.md | ✅ Voltooid | Logboek met definitieve praktijktesten (offline, driver, RBAC) |
| MUP_Gebruikershandleiding_DRAFT.md | 📝 Draft | Gebruikershandleiding voor eindgebruikers |

---

## Kernverschillen vs. Printix (Op Voorhand Vastgesteld)

| Aspect | Printix | Microsoft Universal Print |
|:---|:---|:---|
| **Locatiedetectie** | Automatisch via Gateway MAC | Handmatig via Azure AD-groepen |
| **Kosten** | €12 PUPY (Per User Per Year) | Inbegrepen in M365 E5 / Business Premium |
| **Printvolume** | Onbeperkt | 100 jobs/user/maand (pool) |
| **Driver management** | Geavanceerd (lock, distribute) | Niet aanwezig |
| **Secure Print** | Native (Printix Anywhere + GO) | UP Anywhere (GA aug. 2025) |
| **Beheer-interface** | Printix Admin Portal | Azure Portal (Microsoft 365) |
| **Client op laptop** | Vereist (Printix Client) | Niet vereist (native Windows) |
| **Offline Spooling** | ✅ Ja (lokale cache) | 🔴 Nee (geen offline fallback) |

---

## Nuttige Links

*   **Automatisatie Scripts (GitHub):** `https://git.pefki.xyz/pefki/MS-UP-Soudal/src/branch/main/scripts`
*   **Azure Portal — Universal Print:** `https://portal.azure.com/#blade/Universal_Print`
*   **Microsoft Docs — Universal Print:** `https://docs.microsoft.com/en-us/universal-print/`
*   **Connector Download:** `https://aka.ms/UPConnector`
*   **Licentie Informatie:** `https://aka.ms/UPLicensing`
*   **Microsoft 365 Admin Center:** `https://admin.microsoft.com`

---

*Documentatie opgezet als onderdeel van de Soudal Printinfrastructuur Evaluatie 2026.*
*Auteur: Rayan (Stagiair Infrastructuur)*
