# PROGRESS — Recall Radar

> Houd dit bij aan het einde van elke Claude Code-sessie, zodat de volgende sessie (of een verse context) direct verder kan. Zelfde workflow als je toddler-games.

## Status (samenvatting)
- **Fase:** Bouw deel 2 — **Blokken B–E + F1/F2 af**. App is functioneel + App Store-waardig; alleen F3 (release) resteert.
- **Laatst gewerkt aan:** Design-systeem alignment (DESIGN/ASSETS) + restpunten (contrast, onboarding-privacy, AboutView weg).
- **Volgende stap:** Eigenaar uploadt **TestFlight build 2** (Archive → Distribute → Upload) en test op toestel. Daarna volledige App Store-release óf P1.

## Huidige sprint / focus
- [x] Blok B — ingestion tot geldige gepubliceerde index ✅
- [x] Blok A — Xcode-project scaffold (door eigenaar in Xcode) ✅
- [x] Blok C — app-kern: [x] C1 modellen+download/cache · [x] C2 SwiftData · [x] C3 feed · [x] C4 detail
- [x] Blok D — toevoegen & matching: [x] D1 onboarding · [x] D2 toevoegen+scan · [x] D3 MatchingService · [x] D4 "is dit van jou?"
- [x] Blok E — notificaties & retentie: [x] E1 BGAppRefreshTask · [x] E2 lokale notificaties (trede/bundel/rustige uren) · [x] E3 maandelijkse digest
- [ ] Blok F — afronding: [x] F1 disclaimer/privacy · [x] F2 lege/fout/offline-staten · [x] F3 TestFlight — **build live op toestel** · [ ] F3 volledige App Store-release

## Logboek (nieuwste boven)
### 2026-06-16 (sessie 2 — Design-systeem alignment op DESIGN/ASSETS-docs)
- **DESIGN_Recall-Radar.md + ASSETS_Recall-Radar.md gevonden** (zaten niet in de repo, ontbraken in de eerste kopieerlijst) → naar `docs/reference/` gekopieerd en geïnterpreteerd; app erop gealignd (volledige scope).
- **Color Assets:** alle tokens uit ASSETS B (brand-teal, bg/text, risk- + reassure-tokens) als Color Sets met **light+dark**; `AccentColor` = brand-teal → app-breed teal accent. `DesignSystem.swift` mapt tokens + `DS.Space`/`DS.Radius` (4-grid, 8/12/20).
- **RiskPill + RiskPresentation:** drievoudige codering (kleur+symbool+label) per match-trede (Ernstig risico / Mogelijk van jou / Ter info) + reassure. `HazardStyle` voor de detail-accentband.
- **Kleurdiscipline:** risicokleur weg uit de feed (rustig, neutraal); alleen in home-matches (RiskPill) en het recall-detail (accent-header). reassureGreen-hero.
- **3e tab "Instellingen"** (§4.6): notificaties per trede (HOOG altijd aan; MIDDEL/digest/rustige uren instelbaar via `NotifPrefs`, gewired in BackgroundRefresh), privacy, bronnen & disclaimer, over.
- **"Waarom zie ik dit?"** (§3.6): `MatchingService.matchedSignals` → transparante signaal-uitleg in het detail bij een match.
- **App-icoon** hermaakt per ASSETS A: teal-achtergrond, lichte radarveeg, **amber** stip (geen rood), met light/**dark**/**tinted** appearances.
- **Bewuste afwijking (genoteerd per §0.5):** doc schrijft feed=startscherm (3 tabs); eigenaar koos **Thuis (persoonlijk) als opening** → 3 tabs Thuis · Verken · Instellingen. Sterker voor de kernwaarde.
- 38 app- + 16 ingestion-tests groen; build SUCCEEDED; home/Instellingen visueel geverifieerd. Zit in **build 2** (app-code).
- *Rest/later:* AboutView overlapt nu deels met Instellingen; contrast-tabel (ASSETS Deel C) formeel narekenen; onboarding-privacyscherm aanscherpen.

### 2026-06-16 (sessie 2 — Design-restpunten afgehandeld)
- **Contrast geverifieerd** (WCAG, alle paren uit ASSETS Deel C, light+dark). Twee zakten onder 4.5 voor kleine tekst → voorgrond verdonkerd: `riskMedium` `#B8690A`→`#9E5A08` (4.71), `reassureGreen` `#2E7D52`→`#2C784E` (4.61). Definitieve hex teruggeschreven naar DESIGN §2.2 / ASSETS B.2. (`white/brandPrimary` dark is geen issue: primaire knoppen gebruiken systeem-`.borderedProminent` met auto-contrast label.)
- **Onboarding-privacyscherm** (§4.2/principe 3): privacybelofte + slot-symbool ("Je productlijst blijft op je toestel. Geen account nodig.") + de waarde-zin bovenaan.
- **AboutView verwijderd** (overlapte met de Instellingen-tab): info-knoppen uit Thuis + Verken weg; disclaimer blijft bereikbaar via Instellingen én elk recall-detail.
- Build SUCCEEDED. Klaar voor TestFlight build 2.

### 2026-06-16 (sessie 2 — NVWA-classificatie verbeterd)
- **Probleem:** elke NVWA-titel bevat "waarschuwt" → acties classificeerden als zwakke "wees voorzichtig"; risico viel vaak op "overig"; snippet was te kort.
- **Fix — detailpagina-verrijking:** `nvwa.js` haalt nu per item de detailpagina op (concurrency 8, resilient) en extraheert de volledige `rich-text` waarschuwingstekst (+ eventuele fabrikant-link). Die volledige tekst voedt food-detectie, risico- én actie-classificatie.
- **Resultaat:** contactgrill → elektrisch + "stop met gebruik"; knuffelkonijn → verstikking + "breng terug". Zwakke "wees voorzichtig"-actie: ~alle → **35/163**.
- **Food-filter verscherpt:** woord-grens-matching (kort=exact, lang=prefix) → geen valse positieven meer (televisie/viscose/kleine), en food-lek gedicht ('groenteburger' etc.). NVWA non-food 195 → 163 (32 food eruit). +1 test (16 ingestion-tests groen).
- Index live geregenereerd nodig (zie volgende stap).

### 2026-06-16 (sessie 2 — Design-polish (HIG / Liquid Glass))
- Ingelezen op actuele Apple-richtlijnen: klassiek **Clarity/Deference/Depth** + iOS 26 **Hierarchy/Harmony/Consistency** (Liquid Glass). Aanpak: content-first, semantische kleuren, Dynamic Type, consistente concentrische radii/spacing, materials voor diepte, en standaard-componenten laten de glass dragen.
- **`DesignSystem.swift`:** gedeelde radii (`cardRadius`/`thumbRadius`) + `StatusHeroCard`.
- **Home:** grote titel "Recall Radar" + prominente **geruststellings-statuskaart** (groen "Je bent beschermd" / rood "N recalls voor jou" / setup) als emotionele kern; lege groene rij weg; "Voor jou" alleen bij echte matches; schone inset-grouped secties.
- **Feed-rij:** consistente thumbnail-radius + hiërarchische SF Symbols + nette laad-/placeholder-staat.
- **Detail:** consistente card-materials/radii (secondarySystemBackground, `DS.cardRadius`), galerij-achtergrond semantisch.
- Standaard-componenten (insetGrouped List, TabView, NavigationStack, .searchable, ShareLink, ContentUnavailableView) adopteren automatisch Liquid Glass — bewust niet overschreven.
- Build SUCCEEDED; home/detail/feed visueel geverifieerd in Simulator.
- *Follow-up genoteerd:* NVWA-actie classificeert nu vaak als "waarschuwing" omdat elke NVWA-titel "waarschuwt" bevat → onderschat recalls; risico/actie-parsing voor NVWA verbeteren (evt. detailpagina fetchen).

### 2026-06-16 (sessie 2 — "Wat moet je doen?" = consumentenactie)
- Feedback: de sectie beschreef de markt-maatregel i.p.v. wat de bezitter moet doen. Opgelost met **`consumerAction()`** (`measures.js`): classificeert de maatregel-actie (EN+NL: recall/reparatie/vernietiging/uit-de-handel/verwijderd/waarschuwing/import), kiest de **meest beschermende** en mapt naar een korte imperatieve actie (bv. recall → "Stop met gebruik en breng het product terug…").
- Nieuw schema-veld **`action`** (SG + NVWA). Detail toont de actie prominent onder "Wat moet je doen?"; de letterlijke maatregel staat als uitklapbare **"Officiële maatregel"** (transparantie/bron-getrouw).
- 15 ingestion- + 38 app-tests groen; index live geregenereerd (8.780 acties). **Live geverifieerd in de app.**

### 2026-06-16 (sessie 2 — Feedback-ronde 2: Batch A + B)
- **Batch A (toevoeg/bewerk-flow):**
  - Producten **bewerken** — `AddProductView` doet nu add én edit (`editing:`-param, verwijder-knop), tikbare productrijen in de home (`.sheet(item:)`).
  - **Directe recall-check bij toevoegen** (`MatchBridge.bestMatch`, off-main) → alert "Mogelijke recall gevonden" met confidence; surfacet óók LAAG (je voegde het bewust toe).
  - **Naam-prompt** na barcode zonder index-match (focus + oranje hint).
  - **Model-matching bevinding:** model-exact = 40 = LAAG, terwijl home alleen ≥ MIDDEL toont → daarom zag je geen melding bij handmatig model (barcode = 70 = MIDDEL wél). De directe check-bij-toevoegen lost dit op (toont vanaf LAAG). Tip aan gebruiker: kies de juiste categorie (model+categorie = 55 = MIDDEL).
- **Batch B (data/tekst):**
  - **"Wat moet je doen?" in NL** — `ingestion/src/lookups/measures.js` vertaalt de getemplate `measures_country` compositioneel (authority+rol+~dozijn acties, "Other:"-fallback). Index geregenereerd; +1 test (15 ingestion-tests). **Live geverifieerd: 8.780/8.780 measures NL.**
  - **Risico-omschrijving (vrije tekst) → on-device vertaling** met Apple's Translation-framework (`.translationTask`, en→nl), alleen voor Safety Gate (NVWA is al NL), met fallback naar origineel + "Automatisch vertaald"-label. Gratis, privacy-first. Best te verifiëren op een echt toestel (taalpakket-download).
  - **Merk-autocomplete** — `RecallStore.brandNames` (1× uit index) voedt suggesties in `AddProductView` → minder typo's, betere matching.
- Build SUCCEEDED; 38 app-tests + 15 ingestion-tests groen.

### 2026-06-16 (sessie 2 — Feedback-ronde 1: perf + hoofdpagina)
- **Performance-fix:** matching draaide synchroon op de main thread over alle ~9.000 alerts bij elke her-render → trage Bewaar/"Ja, van mij". Nu: `MatchBridge.snapshot` (main, goedkoop) + `MatchBridge.compute` (`nonisolated`, off-main via `Task.detached`), resultaat gecachet in `@State` en herberekend via `.task(id: matchKey)` alleen bij input-wijziging. Modellen `Sendable` gemaakt.
- **Hoofdpagina herinricht:** `ContentView` opent nu op de **persoonlijke home** (tab "Thuis"); de feed is tab "Verken" (zoeken/filter). Home heeft een samenvatting-header (producten · gevolgd · relevant) + "Voor jou". Build SUCCEEDED, 38 tests groen, visueel geverifieerd.
- **Openstaand uit feedback (volgende rondes):** (a) "Wat moet je doen?"/risico-tekst naar NL; (b) merk-autocomplete uit index (typo's); (c) producten bewerken; (d) naam-prompt na barcode zonder index-match; (e) directe "dit is teruggeroepen"-check bij toevoegen; (f) model-matching nakijken (cryptische Safety Gate-codes); (g) pushes vs in-app match-semantiek verduidelijken.

### 2026-06-16 (sessie 2 — TestFlight LIVE)
- Build geüpload, verwerkt en **geïnstalleerd op een echt toestel** via TestFlight (interne test, geen review). Mijlpaal: v1 is live testbaar.
- Te doen door eigenaar: on-device smoke-test — barcode-scanner (alleen op device), notificatie-permissie, CloudKit-sync, algemeen gevoel.

### 2026-06-16 (sessie 2 — TestFlight-prep, F3)
- **App-icoon** 1024×1024 (opaque) gegenereerd via `RecallRadar/Tools/GenerateAppIcon.swift` (radar + blip) → `AppIcon.appiconset` (lege icon was anders een upload-blocker). Contents.json naar single-size.
- **Export-compliance** vooraf gezet: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` (beide configs) — alleen HTTPS, dus de submit-vraag wordt niet meer gesteld.
- **Pre-flight:** `xcodebuild … -configuration Release … archive` (unsigned) → **ARCHIVE SUCCEEDED**.
- **`docs/TestFlight-walkthrough.md`** geschreven: paste-ready stappen voor interne TestFlight (agreements → app-record → signing → archive → upload → interne test → installeren). Vaste waarden incl. SKU `recallradar`.
- Eigenaar bevestigde: betaald lidmaatschap actief, interne testers → geen beta-review/privacy-URL nodig.

### 2026-06-16 (sessie 2 — Blok F1 + F2)
- **F1:** `AboutView` — altijd bereikbaar via info-knop (Feed + Mijn spullen). Disclaimer (P0-7), bronvermelding (Safety Gate + NVWA, CC0, klikbaar), privacy-uitleg (on-device/geen account/geen tracking), gegevens (laatst bijgewerkt, count, versie), GitHub-link. `PrivacyInfo.xcprivacy` toegevoegd (NSPrivacyTracking false, geen verzamelde data, UserDefaults-reason CA92.1). Camera-uitleg stond al.
- **F2:** `RecallStore` onderscheidt nu `loaded` vs `failed` (geen netwerk én geen cache/bundle → nooit als "geen recalls" tonen; fout-staat met **Opnieuw proberen**). Offline-banner als cache/bundle wordt getoond. "Laatst bijgewerkt" + lege zoekstaat al aanwezig.
- Build SUCCEEDED; About-scherm visueel geverifieerd in Simulator.

### 2026-06-16 (sessie 2 — Blok E: notificaties & retentie)
- **E1 `BackgroundRefresh`:** BGAppRefreshTask (`jire.RecallRadar.refresh`, in Info.plist) — registreert bij launch, plant ~1×/dag, ververst de index en matcht **alleen nieuwe/gewijzigde** alerts (watermark op `updatedAt`; eerste run = baseline, geen backlog-spam). Dedup van gepushte alert-ids in `NotifState` (UserDefaults).
- **E2 notificaties:** `NotificationPlanner` (puur, getest) — bundeling per trede (HOOG alarm / MIDDEL zacht) + rustige uren (22–08 → uitstellen tot 08:00). `NotificationService` wrapt UNUserNotificationCenter. Permissie wordt gevraagd na onboarding + via een "Zet meldingen aan"-rij voor wie de onboarding oversloeg. **Permissie-prompt live geverifieerd in Simulator.**
- **E3 digest:** maandelijkse geruststelling-digest in de refresh (≥28 dagen → "deze maand raakte geen enkele recall jouw N items"), ook bij nul matches.
- **Tests:** +14 headless planner-assertions groen (totaal 38). App-build SUCCEEDED.
- Visueel bevestigd: "Voor jou" toont nu correct de groene geruststelling (geen categorie-flood); permissie-prompt verschijnt en de "Zet meldingen aan"-rij verdwijnt na toestaan.

### 2026-06-16 (sessie 2 — Blok D4)
- **"Is dit van jou?"-bevestiging:** nieuwe sectie in `MyStuffView` voor MIDDEL bezit-matches met Ja / Nee / Weet-ik-niet → schrijft naar `confirmedMatches`/`suppressedMatches` (Ja → toekomstig HOOG, Nee → onderdrukt). Logica gedekt door de bestaande matching-unit-tests.
- **"Voor jou" verfijnd:** `MatchBridge.personalMatches` toont nu alleen bezit-matches (≥ MIDDEL) + gevolgde-merk-meldingen; **categorie-follows zijn eruit** (die horen in de feed). Een gebruiker die alleen categorieën volgt ziet de groene geruststelling + verwijzing naar de Feed.
- Build SUCCEEDED. Visuele opname van de bevestig-sectie overgeslagen wegens een simulator-toetsenbordartefact (accent-popup bij synthetische toetsaanslagen) — geen app-probleem; logica is getest.
- **Blok D compleet.**

### 2026-06-16 (sessie 2 — Blok D1 + D2)
- **D1 onboarding/volgen:** `OnboardingView` (first-run categorie-keuze, jonge-gezin-spits met "populair"-badge), `MyStuffView`-tab (categorieën/merken volgen + producten). `ContentView` is nu een TabView (Feed / Mijn spullen).
- **D2 toevoegen:** `AddProductView` (handmatig merk/model/categorie/barcode) + `BarcodeScannerView` (VisionKit DataScanner, EAN/UPC; device-gated, op Simulator verborgen met uitleg). Barcode-prefill van merk/categorie uit de index.
- **MatchBridge:** koppelt SwiftData (TrackedProduct/Subscription) aan de pure MatchingService; "Voor jou" toont relevante recalls met tier-badges.
- **Geverifieerd in Simulator:** onboarding → 2 categorieën gevolgd → "Voor jou · 1.763 relevant" = exact 1.668 (kinderen) + 95 (witgoed). Toevoeg-sheet rendert; scanknop correct verborgen zonder camera. Build SUCCEEDED.
- **D4-verfijning genoteerd:** categorie-follows vullen nu "Voor jou" (1.763, trede LAAG) — die horen eigenlijk in de feed; "Voor jou" moet bezit- + merk-matches benadrukken. Plus de "is dit van jou?"-bevestiging (confirm/suppress schrijft al naar TrackedProduct via UserDataStore).

### 2026-06-16 (sessie 2 — C4-polish afgerond)
- `RecallDetailView` afgewerkt: foto-**galerij** (paged TabView bij meerdere foto's), **deel-knop** (ShareLink in de toolbar), **toegankelijkheidslabels** (risico/categorie + advies gecombineerd). Build SUCCEEDED; visueel geverifieerd in Simulator (detail van een Safety Gate-recall).
- Bekend: vrije tekst (`risk_desc`/`measure`) is Engels (brondata Safety Gate); labels/categorieën/risico's zijn NL. Vertaling = latere optie, geen v1-blocker.

### 2026-06-16 (sessie 2 — Blok D3: MatchingService)
- **`Services/Normalizer.swift`** — Swift-port van `ingestion/src/util.js` (tekst/model/barcode-normalisatie + Jaro-Winkler). MOET identiek aan util.js zijn, want alert-velden zijn al door util.js genormaliseerd.
- **`Services/MatchingService.swift`** — puur & `nonisolated`, werkt op value-types (`MatchableProduct`, geen SwiftData). Scoring + tredes uit de `MatchingConfig` die in de index meereist. Feedback-loop: confirmed → HOOG, suppressed → GEEN. Aparte follow-tak (merk → MIDDEL, categorie → feed/LAAG).
- **`MatchingTests/main.swift`** — 24 headless assertions, allemaal groen (buiten de app-target; draaien via `swiftc`). App-build blijft SUCCEEDED.
- **Tuning-observatie:** barcode-exact = 70 → **MIDDEL** (HOOG-drempel is 75). Een kale barcode-scan vraagt dus "is dit van jou?"; barcode + categorie (uit de index, zoals de scan-flow vult) = 85 → HOOG. Bump `barcodeExact` naar 75 in `ingestion/src/config.js` als je scan-only wél wilt laten pushen.
- GitHub-push gaat nu zonder prompt (token in macOS-keychain via osxkeychain-helper).

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
