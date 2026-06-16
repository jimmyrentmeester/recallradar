# TestFlight-walkthrough — Recall Radar (interne test)

> Doel: de app naar TestFlight voor jezelf/je team (interne testers). **Geen** beta-review,
> **geen** privacy-URL nodig. Bouwzijde is al klaar (icoon, export-compliance, schone Release-archive).
>
> Vaste waarden:
> - **App-naam:** Recall Radar
> - **Bundle ID:** `jire.RecallRadar`
> - **Team:** A652HSR4S9
> - **Versie / build:** 1.0 (1)
> - **SKU (verzin 1×):** `recallradar`
> - **Taal:** Nederlands

## Wat al gedaan is (door mij, in de repo)
- ✅ App-icoon 1024×1024 (opaque) gegenereerd + gekoppeld.
- ✅ `ITSAppUsesNonExemptEncryption = NO` (export-compliance vraag wordt niet meer gesteld — alleen HTTPS).
- ✅ Schone `Release`-archive geverifieerd (`xcodebuild … archive` → ARCHIVE SUCCEEDED).
- ✅ iCloud/CloudKit, BackgroundTasks, camera-entitlements + privacy-manifest staan.

---

## Stap 0 — Agreements (eenmalig) 👤
1. Ga naar **appstoreconnect.apple.com** → log in.
2. Verschijnt er een melding over **Agreements**? → **Business → Agreements** → accepteer de **Free Apps Agreement** (gratis app = genoeg voor TestFlight).

## Stap 1 — App-record aanmaken 👤
1. App Store Connect → **Apps → ➕ → New App**.
2. Platform **iOS**; Name **Recall Radar**; Primary Language **Nederlands**;
   Bundle ID **jire.RecallRadar**; SKU **recallradar**. → **Create**.
   *(Verschijnt de bundle ID niet? Open Xcode → target → Signing & Capabilities → selecteer Team
   A652HSR4S9 met "Automatically manage signing"; dat registreert de App ID + de
   `iCloud.jire.RecallRadar`-container. Ververs daarna de pagina.)*

## Stap 2 — Signing checken in Xcode 👤
1. Open `RecallRadar.xcodeproj` → selecteer de **RecallRadar**-target → tab **Signing & Capabilities**.
2. **Automatically manage signing** aan, **Team = A652HSR4S9**.
3. Geen rode fouten. Capabilities iCloud (CloudKit + container `iCloud.jire.RecallRadar`),
   Background Modes en Push (aps) horen er te staan.

## Stap 3 — Archiveren 👤
1. Bovenin de device-kiezer: kies **Any iOS Device (arm64)** (Archive is grijs bij een simulator).
2. **Product → Archive**. Wacht tot de **Organizer** opent met je archive.

## Stap 4 — Uploaden naar App Store Connect 👤
1. In de Organizer: selecteer de archive → **Distribute App**.
2. Kies **App Store Connect** → **Upload** → **Automatically manage signing** → **Upload**.
3. Wacht op **"Upload successful"**.

## Stap 5 — Wachten op verwerking ⏳
- De build verschijnt na **±5–60 min** in App Store Connect → tab **TestFlight**.
  (Tijdens verwerking is hij nog niet selecteerbaar — even geduld.)

## Stap 6 — Interne test starten 👤
1. App Store Connect → je app → **TestFlight**.
2. Bij **Internal Testing**: maak/gebruik een groep → voeg jezelf toe (je staat al als gebruiker op het team).
3. De build wordt voor interne testers **direct** beschikbaar (geen review). Door de
   `ITSAppUsesNonExemptEncryption = NO` wordt de export-vraag niet gesteld.

## Stap 7 — Installeren op je iPhone 👤
1. Installeer **TestFlight** uit de App Store op je iPhone.
2. Log in met hetzelfde Apple-account → **Recall Radar** verschijnt → **Install** → openen en testen.

---

## Veelvoorkomende hobbels
- **"Archive" grijs** → device staat op een simulator; zet op *Any iOS Device (arm64)*.
- **Provisioning/CloudKit-fout bij archiveren** → in Signing & Capabilities één keer de iCloud-container
  laten registreren (Team geselecteerd, automatic signing); Xcode maakt dan het profiel.
- **Build verschijnt niet** → verwerking nog bezig, of de upload faalde stil — check je mail van Apple.
- **Volgende build** → verhoog het buildnummer (`CURRENT_PROJECT_VERSION`) vóór elke nieuwe upload.

## Daarna (later, niet nodig voor interne test)
- Externe testers → lichte **beta-review** + **privacy-policy-URL** (ik genereer die pagina).
- Volledige App Store-release (F3) → screenshots, listing, leeftijdsclassificatie, review — met de `app-store-release`-skill.
