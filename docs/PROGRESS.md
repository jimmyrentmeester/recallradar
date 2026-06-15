# PROGRESS — Recall Radar

> Houd dit bij aan het einde van elke Claude Code-sessie, zodat de volgende sessie (of een verse context) direct verder kan. Zelfde workflow als je toddler-games.

## Status (samenvatting)
- **Fase:** Bouw deel 1 — **Blok B (ingestion) afgerond**. Geldige index lokaal gegenereerd + geverifieerd. PROGRESS-workflow ingericht.
- **Laatst gewerkt aan:** PROGRESS-workflow (`/progress`-command + CLAUDE.md-sectie) na Blok B1–B7.
- **Volgende stap:** Eerste commit + GitHub-repo pushen + Pages aanzetten op `gh-pages` (B6 live), dan **Blok C** (app-kern: Codable-modellen + index-download/cache). Blok A (Xcode-project) maakt de eigenaar zelf aan.

## Huidige sprint / focus
- [x] Blok B — ingestion tot geldige gepubliceerde index ✅
- [ ] Blok A — Xcode-project + capabilities (door eigenaar in Xcode)
- [ ] Blok C — app-kern (Codable + download/cache)

## Logboek (nieuwste boven)
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
