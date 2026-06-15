# Fase 3 — Build-handoff voor Claude Code — Recall Radar

*Datum: 15 juni 2026 · Neem dit pakket mee naar Claude Code / Xcode. Bouw eerst de ingestion-pipeline, dan de app.*

Begeleidende stukken (Cowork): `Fase0_Validatie-memo`, `Fase1_PRD`, `Fase1_Matching-logica`, `Fase2_Databron-matrix_alert-schema_taxonomie.xlsx`, `Fase2_Schema-document`.

---

## 1. Architectuur in één beeld

```
┌─────────────────────────────────────────────┐        ┌──────────────────────────────┐
│ INGESTION (GitHub Actions cron, 1×/dag)       │        │ iOS-APP (SwiftUI)             │
│  fetch OpenDataSoft (Safety Gate, JSON, CC0)  │        │  • download index (ETag)      │
│  fetch NVWA non-food (RSS, CC0)               │ ─JSON─►│  • cache lokaal (Caches/)     │
│  normaliseer → categorie/risico mappen        │  over  │  • on-device matching         │
│  dedup → schrijf statische JSON-index         │  HTTPS │  • lokale notificaties (BG)   │
│  publiceer op GitHub Pages (gratis)           │        │  • producten in SwiftData     │
└─────────────────────────────────────────────┘        │    (+ CloudKit voor delen, P1)│
                                                          └──────────────────────────────┘
```

**Kernprincipes (niet-onderhandelbaar):** matching gebeurt **on-device**; de productlijst verlaat het toestel nooit (behalve de eigen iCloud van de gebruiker); geen account voor de kern; **geen eigen server** (statische JSON + cron); informatief, niet uitputtend, met disclaimer + bronvermelding.

**Repo-opzet (aanbevolen monorepo):**
```
recallradar/
  ingestion/            # Node 20 script + GitHub Action
  RecallRadar/          # Xcode SwiftUI-project
  docs/PROGRESS.md
  CLAUDE.md
```

---

## 2. Ingestion-pipeline (bouw dit eerst)

### 2.1 Tech-keuze
**GitHub Actions (cron) + Node 20, publiceren naar GitHub Pages.** Geen account-/key-budget nodig, geen server. Cloudflare Workers/R2 is een alternatief als je later van GitHub Pages af wilt — abstraheer de "publish"-stap zodat omschakelen triviaal is.

### 2.2 Stappen (per run)
1. **Ophalen Safety Gate (primair):** OpenDataSoft Explore API v2.1, gepagineerd. Filter incrementeel op `modification_date` > laatste run.
   `GET https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/healthref-europe-rapex-en/records?limit=100&offset=…&order_by=modification_date%20desc`
2. **Ophalen NVWA (primair NL):** non-food RSS-feed parsen (titel, omschrijving, datum, link).
3. **Normaliseren** volgens tabblad *Bron-mapping* → het schema uit tabblad *Alert-schema*.
4. **Categorie & risico mappen** via lookups (tabbladen *Categorie-taxonomie* en *Risico-waarden*). Vul de exacte broncategorie-strings uit de eerste volledige run.
5. **Dedup** op `source`+`alert_number` én op genormaliseerd (merk+model+risico+datum) om dubbele Safety Gate/NVWA-meldingen samen te voegen.
6. **Index schrijven** (zie 2.3) en **publiceren** naar GitHub Pages.
7. **Fallback:** faalt OpenDataSoft, val terug op de officiële EC weekrapport-XML; faalt NVWA-RSS, parse de overzichtspagina (respecteer robots.txt). Faalt alles, publiceer **niet** (behoud de vorige index) en log.

### 2.3 Index-formaat (publicatie)
Ship **niet** de volledige historie (≈32k records). Twee bestanden:

- `index.json` — rollend venster (**laatste 24 maanden**, non-food), getrimde velden, voor feed + matching. Indicatief enkele honderden KB–enkele MB.
- `meta.json` — `{ "generated_at", "schema_version", "count", "etag" }` voor goedkope versie-checks.

```jsonc
// index.json
{
  "schema_version": 1,
  "generated_at": "2026-06-15T04:00:00Z",
  "window_months": 24,
  "alerts": [ { /* exact het Alert-schema uit Fase 2 */ } ]
}
```

Serveer met caching-headers (ETag / Last-Modified) zodat de app `If-None-Match` kan sturen.

### 2.4 Licentie/compliance in de output
Neem per alert `source` + `source_url` op; toon in de app bronvermelding + disclaimer. Bronnen zijn CC0 (OpenDataSoft, NVWA) resp. EC-hergebruik met bronvermelding — zie databron-matrix.

---

## 3. iOS-app (SwiftUI)

### 3.1 Datamodellen (Swift, Codable — spiegelt het schema)
```swift
enum AlertSource: String, Codable { case safetyGate = "safety_gate", nvwa, rasff }

struct RecallAlert: Codable, Identifiable, Hashable {
    let id: String
    let source: AlertSource
    let alertNumber: String
    let brand: String?          // genormaliseerd
    let brandRaw: String?
    let model: String?          // genormaliseerd
    let modelRaw: String?
    let category: String        // interne taxonomie-code
    let sourceCategory: String?
    let barcode: String?
    let batchLot: String?
    let riskType: String        // interne risico-enum
    let riskDesc: String?
    let measure: String
    let country: String
    let imageURL: URL?
    let imageURLs: [URL]?
    let sourceURL: URL
    let publishedAt: Date
    let updatedAt: Date
}
```

### 3.2 Opslag
- **Gebruikersproducten & abonnementen:** **SwiftData** (iOS 17+). Zet CloudKit-mirroring aan → gratis iCloud-back-up nu, basis voor gezin-delen (P1). Dit blijft privé in de iCloud van de gebruiker.
- **Alert-index:** als bestand in `Caches/` (niet in de user-store, niet in iCloud). Het is herbruikbare publieke data.

```swift
@Model final class TrackedProduct {
    var id: UUID
    var brand: String?; var model: String?
    var category: String
    var barcode: String?
    var addedAt: Date
    var confirmedMatches: [String]   // alert-ids door gebruiker bevestigd
    var suppressedMatches: [String]  // 'nee, niet van mij'
}
@Model final class Subscription { var kind: String /* brand|category */; var value: String; var pushEnabled: Bool }
```

### 3.3 Matching-engine
Implementeer als **pure, geteste Swift-service** (`MatchingService`) volgens het *Matching-logica*-document: scoring (barcode +70, merk +30, model +40 / fuzzy +20, categorie +15, batch +25, tegensignalen) → tredes HOOG ≥75 / MIDDEL 45–74 / LAAG 20–44 / GEEN <20. Drempels en gewichten uit een config (meegeleverd in de index) zodat bijstellen geen app-update vergt. **Unit-tests verplicht** met echte voorbeeld-alerts (happy path, vals-positief, vals-negatief, alleen-categorie).

### 3.4 Notificaties (geen server-push nodig in v1)
- **BackgroundTasks** (`BGAppRefreshTask`): plan ~1×/dag → download index (If-None-Match) → match alleen nieuwe/gewijzigde alerts → plan lokale notificaties (`UNUserNotificationCenter`).
- **Tredes:** HOOG → alarmerende notificatie; MIDDEL → zachte "is dit van jou?"; LAAG → alleen feed.
- **Bundelen** bij meerdere matches; **geen nacht-pushes** (bundel tot ochtend) tenzij instant-alerts (Pro).
- **Maandelijkse digest (P0):** geplande lokale notificatie, ook bij nul matches.
- APNs is **niet** nodig voor v1 (scheelt server + kosten); houd het als optie voor near-real-time later.

### 3.5 Producten toevoegen
- **Barcode/EAN:** VisionKit `DataScannerViewController` (of AVFoundation). Valideer EAN-13/UPC-checkdigit; vul merk/categorie voor indien de index de barcode kent.
- **Handmatig:** merk + model + categorie met autocomplete uit de in de index aanwezige merk-/categorielijsten.
- **Merk/categorie-abonnement:** onboarding-hoofdpad (0 friction).
- **OCR typeplaatje/bon (P1):** VisionKit text recognition; later.

### 3.6 Caching & fallback (app)
- Fetch met `If-None-Match`; bij 304 → cache gebruiken; bij netwerkfout → laatst bekende cache; **nooit** een "geen recalls"-conclusie pushen op basis van een mislukte fetch.
- Toon `generated_at` ("laatst bijgewerkt …") voor transparantie.

### 3.7 Privacy & App Store
- Geen netwerkverzoek bevat de productlijst. Camera-permissie met uitleg. Privacy-nutritielabel correct (geen tracking). Geen verplichte login. Altijd bereikbare disclaimer + bron-links.

---

## 4. Geprioriteerde v1-takenlijst (werk 1-op-1 af in Claude Code)

### Blok A — Setup
- [ ] A1. Monorepo + Xcode-project (SwiftUI, iOS 17+), bundle-id, capabilities (BackgroundTasks, iCloud/CloudKit, Camera).
- [ ] A2. `CLAUDE.md` + `docs/PROGRESS.md` in de repo plaatsen.

### Blok B — Ingestion (eerst af, vóór de app-data-laag)
- [ ] B1. Node-script: OpenDataSoft ophalen (paginatie + incrementeel op `modification_date`).
- [ ] B2. NVWA-RSS ophalen + parsen.
- [ ] B3. Normalisatie naar het Alert-schema (Bron-mapping).
- [ ] B4. Categorie- en risico-lookups vullen met echte broncategorie-strings (eerste volledige run).
- [ ] B5. Dedup + `index.json`/`meta.json` schrijven (24-maands venster).
- [ ] B6. GitHub Action (cron) + publiceren naar GitHub Pages; fallback-logica + logging.
- [ ] B7. Sanity-check: handmatig een bekende recall terugvinden in de gepubliceerde index.

### Blok C — App-kern
- [ ] C1. Codable-modellen + index-download/-cache (ETag, fallback).
- [ ] C2. SwiftData-modellen (TrackedProduct, Subscription) + CloudKit-mirroring.
- [ ] C3. Browsebare feed met categoriefilter (P0-3).
- [ ] C4. Recall-detail met handelingsadvies, foto, batch/lot, bron-knop, disclaimer (P0-4).

### Blok D — Toevoegen & matching
- [ ] D1. Onboarding: merk/categorie-abonnement (hoofdpad).
- [ ] D2. Handmatig toevoegen + barcode-scan (VisionKit).
- [ ] D3. `MatchingService` + unit-tests (alle tredes + edge cases).
- [ ] D4. "Is dit van jou?"-bevestiging + suppress/confirm-opslag (feedback-loop).

### Blok E — Notificaties & retentie
- [ ] E1. BGAppRefreshTask: dagelijkse refresh + match-only-nieuwe.
- [ ] E2. Lokale notificaties per trede + bundeling + rustige uren.
- [ ] E3. Maandelijkse geruststelling-digest (P0-6).

### Blok F — Afronding
- [ ] F1. Privacy-labels, camera-uitleg, disclaimer-scherm.
- [ ] F2. Lege staten, foutstaten, "laatst bijgewerkt".
- [ ] F3. TestFlight + App Store-listing (Fase 4-output inhaken).

**P1 (na launch):** widget, gezin-delen (CloudKit-share), OCR typeplaatje/bon, Pro-unlock (StoreKit 2).

---

## 5. Open punten om bij de bouw te bevestigen
- Officiële EC weekrapport-XML als fallback live uitlezen en parsen (in Fase 0 niet via tool te lezen).
- NVWA-RSS-parsing kalibreren op echte items (merk/model/batch uit vrije tekst).
- Exacte indexgrootte meten bij het 24-maands venster; venster bijstellen indien nodig.
- Drempelwaarden van de matching afstellen op echte data + bevestigings-feedback.
