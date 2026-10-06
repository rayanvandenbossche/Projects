# Aanvraag Azure AD / Microsoft Entra ID Permissies (Printix) 

Om de Printix Proof of Concept (PoC) voor Soudal succesvol af te ronden en de printers beschikbaar te maken voor alle werknemers via hun Office 365 login, is er eenmalig een actie nodig van een **Global Administrator**.

### Wat is er nodig?
In de Printix Administrator portal (`soudal.printix.net/admin`) moeten twee specifieke configuraties door een Global Admin worden bevestigd:

1.  **Accept for all users:** Dit verleent "Admin Consent" namens de hele organisatie. Hierdoor kunnen werknemers op hun laptops automatisch inloggen in de Printix app zonder dat elke individuele gebruiker handmatig toestemming moet geven aan de app.
2.  **Synchronize groups:** Hiermee krijgt Printix de rechten om Azure AD groepen te lezen. Dit is nodig om later printers automatisch toe te wijzen aan specifieke afdelingen of locaties.

### Waarom is de "Global Administrator" rol nodig?
De Microsoft Entra ID beveiliging staat niet toe dat standaardgebruikers of beperkte admins rechten verlenen die invloed hebben op de gehele 'tenant' (zoals het lezen van profielen voor alle gebruikers). Alleen een Global Admin kan deze "Enterprise Application" (Printix) eenmalig autoriseren.

### Hoe voer je dit uit?
1.  Log in op de Printix Portal: [soudal.printix.net/admin](https://soudal.printix.net/admin/#/authentication?authenticationSection=azure)
2.  Ga naar het **hoofdmenu** (drie streepjes rechtsboven) -> **Settings** -> **Authentication**.
3.  Onder de tab **Microsoft Entra ID**, klik op de blauwe **Accept** linkjes naast:
    *   *Accept for all users*
    *   *Synchronize groups*
4.  Log na het klikken in met het **Global Admin** account en vink het vakje "Toestemming geven namens uw organisatie" aan in de Microsoft pop-up.

---
*Status: De 429 printers zijn al succesvol gescand en staan klaar in de cloud. Zodra deze permissies zijn verleend, kunnen we starten met de uitrol naar de eindgebruikers.*
