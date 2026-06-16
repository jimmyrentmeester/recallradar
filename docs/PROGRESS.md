# PROGRESS — Recall Radar

> Houd dit bij aan het einde van elke Claude Code-sessie, zodat de volgende sessie (of een verse context) direct verder kan. Zelfde workflow als je toddler-games.

## Status (samenvatting)
- **Fase:** Bouw deel 2 — **C1+C2+C3 af, B6 live**. Feed draait in de Simulator op de live cloud-index.
- **Laatst gewerkt aan:** C3 — browsebare feed met categoriefilter + zoeken + detailscherm.
- **Volgende stap:** **C4** (recall-detail afronden: foto-galerij, delen, toegankelijkheid) — kern staat al. Daarna Blok D (toevoegen + matching). Eigenaar: iCloud-capability in Xcode bevestigen + C2/C3-commits pushen.

## Huidige sprint / focus
- [x] Blok B — ingestion tot geldige gepubliceerde index ✅
- [x] Blok A — Xcode-project scaffold (door eigenaar in Xcode) ✅
- [ ] Blok C — app-kern: [x] C1 modellen+download/cache · [x] C2 SwiftData · [x] C3 feed · [~] C4 detail (kern af)

## Logboek (nieuwste boven)
### 2026-06-16 (sessie 2 — Blok C3)
- **C3 feed gebouwd:** `Views/FeedView.swift` (categoriefilter-chips, jonge-gezin-spits vooraan, `.searchable` op merk/model, states), `Views/RecallRow.swift` (thumbnail + categorie/risico/datum/bronbadge), `Views/RecallDetailView.swift` (handelingsadvies, foto, batch/lot, bronknop(pen), disclaimer — C4-kern), `Views/CategoryStyle.swift` (SF Symbols + risicokleur). `ContentView` host de feed in een NavigationStack.
- **Concurrency-fix (belangrijk projectdetail):** project staat op **Swift 6.2 default main-actor isolation** → pure modellen/decoders gemarkeerd `nonisolated` (`RecallAlert`, `RecallIndex`, `MatchingConfig`, `RecallMeta`, `JSONDecoder.recallIndex`, `RecallDateParser`, `RecallIndex.empty`) zodat de `IndexService`-actor ze off-main kan decoderen. `swiftc -typecheck` mist dit; alleen een echte `xcodebuild build` vangt het. Vastgelegd in memory.
- Lege `INFOPLIST_KEY_NSCameraUsageDescription` voorzien van een nette NL-uitleg (privacy-guardrail + prep D2-scanner).
- **Geverifieerd:** `xcodebuild build` SUCCEEDED; app draait in Simulator (iPhone 17 Pro) en toont 8.975 recalls van de live index met werkende filters/zoeken. Screenshot gedeeld.

### 2026-06-16 (sessie 2 — Blok C2)
- **C2 SwiftData-laag gebouwd:**
  - `Models/TrackedProduct.swift` (bezit) + `Models/Subscription.swift` (merk/categorie-follow) — CloudKit-compatibel (defaults overal, geen unique, geen verplichte relaties). `confirmedMatches`/`suppressedMatches` voor de feedback-loop.
  - `Services/Persistence.swift` — `ModelContainer` met CloudKit-mirroring (`.automatic`) + **fallback naar lokaal/in-memory** zodat de app nooit crasht vóór de capability actief is.
  - `Services/UserDataStore.swift` — CRUD + dedup van follows + confirm/suppress + `isMonitoringAnything` (voor de maand-digest).
  - `RecallRadarApp` koppelt de container via `.modelContainer`.
- **Entitlements/Info.plist:** iCloud-container `iCloud.jire.RecallRadar` toegevoegd; `remote-notification` background-mode erbij (CloudKit-sync).
- **Geverifieerd:** hele app type-checkt schoon tegen iOS 26.5 SDK (exit 0).
- **Nog door eigenaar in Xcode:** iCloud-capability bevestigen (CloudKit + container `iCloud.jire.RecallRadar` registreren) voor device-builds; Simulator werkt nu al via de fallback.

### 2026-06-16 (sessie 2 — B6 live op GitHub Pages)
- Repo gepusht → **github.com/jimmyrentmeester/recallradar** (publiek). Git-remote `origin` over HTTPS (token niet opgeslagen).
- GitHub Action handmatig getriggerd → **run 1 geslaagd**: bouwde de index in de cloud en pushte naar `gh-pages` (`.nojekyll`, `index.json`, `meta.json`).
- **GitHub Pages aangezet** op `gh-pages`/root. Live geverifieerd: `https://jimmyrentmeester.github.io/recallradar/index.json` → HTTP 200, `application/json`, ETag aanwezig, 8.975 alerts (beide bronnen). B6 dus **echt live**.
- `IndexService.indexURL` wees al naar deze exacte URL → geen app-wijziging nodig.

### 2026-06-15 (sessie 2 — Blok C1)
- **C1 app-kern gebouwd** in `RecallRadar/RecallRadar/`:
  - `Models/RecallAlert.swift` + `Models/RecallIndex.swift` — Codable, spiegelt exact het gepubliceerde schema; tolerante datum-decoder (date-only én ISO-datetime); URL-velden als String + computed `URL?` (één fout veld breekt nooit de hele decode).
  - `Services/IndexService.swift` — actor: GET met `If-None-Match`/ETag, cache in `Caches/`, fallback-keten netwerk → cache → gebundelde fixture → lege index. Gooit nooit.
  - `Services/RecallStore.swift` — `@Observable` laag (status + "laatst bijgewerkt").
  - `ContentView.swift` — minimale verificatie-feed (volwaardige feed/filter = C3).
  - `Resources/index.sample.json` — 24-alert fixture voor first-run/offline/preview.
- **Geverifieerd:** Swift-modellen decoderen zowel de fixture als de **volledige live index (8.975 alerts)** zonder fouten; hele app type-checkt schoon tegen de iOS 26.5 SDK. Project gebruikt synchronized file groups → nieuwe bestanden zitten automatisch in de build.
- **Index-URL** in `IndexService` staat op `https://jimmyrentmeester.github.io/recallradar/index.json` (placeholder tot Pages live is).

### 2026-06-15 (sessie 2 — PROGRESS-workflow)
- PROGRESS-workflow ingericht: `.claude/commands/progress.md` (`/progress`) + verplichte sectie in `CLAUDE.md`. Vanaf nu PROGRESS bijwerken na elk afgerond blok / einde sessie.

### 2026-06-15 (sessie 2 — Blok B)
- **Endpoints live geverifieerd** vóór code (guardrail):
  - Safety Gate / OpenDataSoft `healthref-europe-rapex-en`: ✅ werkt. `limit`≤100, `offset+limit`≤10.000 (harde caps), incrementeel `where=modification_date>…` werkt, `exports/json?limit=-1` omzeilt de offset-cap. 24-maands venster ≈ 8.810 records. `alert_type`/`measures_country`/`product_other_images` zijn **arrays**; `alert_country` = volledige naam (niet ISO-2).
  - **NVWA: RSS-feed bestaat NIET meer** (site = Next.js-SPA). Reverse-engineered de eigen JSON-zoek-API: `POST /api/search`, `topic=Veiligheidswaarschuwingen`, `content_type=pro:downloadDocument`, sort `sort_date`, gepagineerd. 570 waarschuwingen (food+non-food door elkaar), géén gestructureerde velden → parsen uit titel/omschrijving.
- **Gebouwd** (`/ingestion`, Node 20, 0 dependencies):
  - B1 Safety Gate-fetcher (paginatie + incrementeel + export-fallback).
  - B2 NVWA-fetcher (JSON-API, paginatie tot venster-ondergrens).
  - B3 normalisatie → `RecallAlert`-schema (beide bronnen).
  - B4 lookups gevuld met **echte** bronstrings (categorie/risico/land uit facets).
  - B5 dedup (id + genormaliseerd) + `index.json`/`meta.json` (24-mnd, ETag).
  - B6 publish-stap geabstraheerd + GitHub Action (cron 04:00 UTC → `gh-pages`).
  - B7 sanity-check + 13 unit-tests (alle groen).
- **Resultaat (live run):** 8.975 alerts (8.780 Safety Gate + 195 NVWA non-food), 0 ontbrekende verplichte velden. Index **10 MB raw / 1,18 MB gzipped**. Incrementele modus geverifieerd.

### 2026-06-15 (sessie 1 — Cowork)
- Cowork-fasen 0–3 afgerond: validatie-memo, PRD, matching-logica, databron-matrix/schema/taxonomie, build-handoff, CLAUDE.md.

## Beslissingen (append-only)
- Primaire bron OpenDataSoft (CC0); EC-XML fallback.
- ~~NVWA via RSS~~ → **NVWA via eigen JSON-zoek-API** (RSS bestaat niet meer; eigen primaire bron, geen scrape). Food eruit gefilterd op trefwoorden (v1 = non-food).
- Publicatie = GitHub Action → **`gh-pages`** branch (publish-stap geabstraheerd voor latere R2-switch).
- PROGRESS bijhouden is verplicht en gebeurt via `/progress` (na elk blok / einde sessie).
- App-project staat op **Swift 6.2 default main-actor isolation**: pure modellen/decoders `nonisolated` markeren; valideren met echte `xcodebuild build` (niet alleen `swiftc -typecheck`).
- On-device matching, gebalanceerde grondhouding.
- v1 = non-food; datamodel food-ready. Monetisatie = eenmalige Pro-unlock (P1).

## Bekende risico's / te verifiëren
- [x] Indexgrootte gemeten: 1,18 MB gzipped @ 24 mnd — OK. Optie: feed/detail splitten als het groeit.
- [ ] **EC weekrapport-XML als fallback** nog niet geïmplementeerd (Safety Gate werkte; fallback is nu export-endpoint i.p.v. EC-XML). EC-XML alsnog toevoegen als harde fallback indien gewenst.
- [ ] **NVWA-parsing kalibreren:** merk/model/batch/risico uit vrije tekst is heuristisch; risico valt vaak op `overig_risico` (snippet is kort). Detailpagina's bevatten volledige tekst — overwegen te fetchen voor betere risk/batch-extractie.
- [ ] **Food-filter NVWA** is trefwoord-gebaseerd; steekproefsgewijs controleren op false-positives/negatives.
- [ ] `etag` verandert nu ook bij ongewijzigde inhoud (door `ingested_at`); evt. etag baseren op substantieve velden om onnodige app-downloads te vermijden.
- [ ] Matching-drempels afstellen op echte data (app-zijde, Blok D).

## Openstaande vragen voor mezelf
- GitHub-repo aanmaken + Pages aanzetten op `gh-pages` zodat de app een echte index-URL heeft.
- Push-mechanisme: lokale notificaties (v1) bevestigd; APNs later?
- Gratis-laag-limiet (bv. 10 producten) — definitief maken vóór Pro-werk.
