# Recall Radar — Ingestion (Blok B)

Node 20-pipeline die EU **Safety Gate** (via OpenDataSoft) + **NVWA** ophaalt,
normaliseert naar het `RecallAlert`-schema (Fase 2), dedupliceert en een statische
`index.json` + `meta.json` publiceert. Geen server, geen dependencies — alleen Node 20.

## Draaien

```bash
cd ingestion
node src/run.js          # incrementeel als er een vorige index is, anders volledig
node src/run.js --full   # forceer volledige 24-maands rebuild
node src/sanity.js       # B7: controleer de gepubliceerde index
node --test              # unit-tests
```

Output komt in `ingestion/public/` (`index.json`, `meta.json`). Die map wordt door
de GitHub Action (`.github/workflows/ingest.yml`) dagelijks naar de **`gh-pages`**
branch gepusht en door GitHub Pages geserveerd.

> Zet GitHub Pages aan op de `gh-pages` branch zodra de repo op GitHub staat. De
> app leest dan `https://<user>.github.io/<repo>/index.json` (+ `meta.json` voor
> goedkope `If-None-Match`-checks via de meegeleverde `etag`).

## Bronnen (live geverifieerd 2026-06-15)

| Bron | Toegang | Status |
|------|---------|--------|
| **Safety Gate** (primair, non-food) | OpenDataSoft Explore API v2.1, `healthref-europe-rapex-en` | ✅ JSON, CC0. `limit`≤100, `offset+limit`≤10.000 → automatische fallback naar `exports/json` bij grote vensters. Incrementeel op `modification_date`. |
| **NVWA** (primair NL, non-food) | JSON-zoek-API `POST /api/search` | ✅ Werkt. **Afwijking van Fase 2:** de RSS-feed bestaat niet meer (site is Next.js-SPA). We gebruiken NVWA's eigen zoek-API (`topic=Veiligheidswaarschuwingen`) — primaire bron, geen scrape. |

### NVWA-bijzonderheden
- De API levert **food + non-food** door elkaar; food wordt eruit gefilterd via
  trefwoorden (`lookups/categories.js → FOOD_KEYWORDS`). v1 = non-food; food (RASFF)
  is een latere module.
- Er zijn **geen gestructureerde** merk/model/batch-velden; die worden uit titel +
  omschrijving geparsed (`normalize.js`). Titelpatroon: *"Veiligheidswaarschuwing
  &lt;product&gt; van &lt;merk&gt;"*. Verwacht hier de meeste parsing-onzekerheid →
  de app vangt dat op met de gebalanceerde matching ("is dit van jou?").

## Structuur

```
src/
  config.js          endpoints, venster (24 mnd), paden, matching-config (reist mee in de index)
  util.js            tekst/model/barcode/datum-normalisatie (gedeeld met app-matching)
  lookups/
    categories.js    B4: Safety Gate-categorie → 11 NL-groepen + NVWA-trefwoorden + food-filter
    risks.js         B4: alert_type → risico-enum
    countries.js     landnaam → ISO-2
  sources/
    safetyGate.js    B1: paginatie + incrementeel + export-fallback
    nvwa.js          B2: JSON-zoek-API, paginatie tot venster-ondergrens
  normalize.js       B3: beide bronnen → RecallAlert-schema
  dedup.js           B5: dedup op id + op genormaliseerd (merk+model+risico+datum)
  buildIndex.js      B5: index.json + meta.json (getrimd, ETag)
  publish.js         B6: geabstraheerde publish-stap (→ public/)
  run.js             orkestrator + fallback-logica
  sanity.js          B7: verificatie
```

## Guardrails
Privacy-first (de index bevat alleen publieke recall-data — nooit gebruikersbezit),
on-device matching (de app matcht zelf), alleen primaire bronnen, bronvermelding +
disclaimer reizen mee in de index. Zie `CLAUDE.md`.
