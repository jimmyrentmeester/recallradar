# Fase 2 — Schema-document — Recall Radar

*Datum: 15 juni 2026 · Begeleidend bij `Fase2_Databron-matrix_alert-schema_taxonomie.xlsx` · voedt de ingestion-job en on-device matching (Fase 3)*

---

## Doel

Eén genormaliseerd model waar alle bronnen naartoe mappen, zodat de app maar met één vorm hoeft te werken — onafhankelijk van welke bron (Safety Gate, NVWA, later RASFF) de data leverde. De spreadsheet bevat de volledige tabellen; dit document legt de keuzes en het hoe uit.

## De pijplijn in één beeld

```
Bronnen ──(ingestion-job, 1×/dag)──► normaliseren ──► JSON-index (statisch) ──► app downloadt ──► on-device matching
  • OpenDataSoft (Safety Gate, JSON, CC0)
  • NVWA non-food (RSS, CC0)
  • [later] RASFF (food)
```

De ingestion-job (GitHub Action of Cloudflare Worker, Fase 3) is de enige plek die de bronformaten kent. Hij schrijft uitsluitend het genormaliseerde schema weg. De app kent de bronnen niet — alleen het schema.

## Het genormaliseerde alert-schema

Zie tabblad **Alert-schema**. Kernpunten:

- **`source` als enum** (`safety_gate` | `nvwa`, food-ready voor `rasff`) houdt het model uitbreidbaar zonder herbouw — dit is de food-ready-belofte uit Fase 0/1 concreet gemaakt.
- **`brand`/`model` dubbel opgeslagen** (genormaliseerd + `_raw`): genormaliseerd voor matchen, raw voor nette weergave.
- **`barcode`** is genormaliseerd (alleen cijfers, checkdigit-valide). De RAPEX-data bevat dit veld; lang niet elke alert vult het, dus het is een sterk signaal als het er is, geen vereiste.
- **`category`** is altijd een interne taxonomie-code (nooit de ruwe broncategorie); `source_category` bewaart het origineel voor traceerbaarheid.
- **`updated_at`** is de spil voor dedup en refresh: de app verwerkt bij een index-refresh alleen records die nieuwer zijn dan de laatst verwerkte.

## Bron-mapping

Zie tabblad **Bron-mapping**. Aandachtspunten per bron:

- **Safety Gate (OpenDataSoft):** schoonste bron — bijna 1-op-1 veldmapping (`product_brand`, `product_model_type`, `product_barcode`, `product_batch_number`, `alert_type`, `measures_country`, `product_image`, `product_recall_url`, `alert_date`, `modification_date`). Velden live geverifieerd op 15-06-2026.
- **NVWA (RSS):** levert semi-gestructureerde tekst (titel, omschrijving, datum, link). Merk/model/batch worden **uit de tekst geparsed**; `country` is constant `NL`; `category` via trefwoord-mapping. Verwacht hier de meeste parsing-onzekerheid — daarom de gebalanceerde matching (twijfel → "is dit van jou?").
- **RASFF:** kolom opgenomen maar leeg gelaten; invullen bij de food-module.

## Categorie-taxonomie

Zie tabblad **Categorie-taxonomie**. De ~130 ruwe Safety Gate-categoriewaarden (met een lange staart aan "Other - …") zijn teruggebracht tot **11 gebruikersvriendelijke NL-groepen**. Beslissingen:

- **`kinderen_speelgoed` is de spits (jonge-gezin):** bundelt Toys (6.990) + Childcare articles (1.051) + kinder-subcategorieën — samen veruit de grootste, relevante groep voor de primaire persona. Autostoelen vallen onder Childcare articles.
- **Lange staart → `overig`:** de honderden unieke "Other - X"-waarden gaan naar `overig`, tenzij een trefwoord een betere groep aanwijst. Dit voorkomt een onbruikbaar lange categorielijst in de UI.
- **Volumes zijn indicatief** (RAPEX-historie vanaf 2015). Het echte mapping-bestand in de ingestion-job (een lookup van broncategorie → interne code) is de bron van waarheid; de spreadsheet is de leesbare specificatie ervan.

Risico-typen zijn op dezelfde manier genormaliseerd (tabblad **Risico-waarden**) voor filtering en weergave.

## Wat dit betekent voor Fase 3

De ingestion-job implementeert: ophalen → normaliseren volgens Bron-mapping → categorie/risico mappen via de lookups → dedup op genormaliseerd (merk+model+risico+datum) en op `source`+`alert_number` → statische JSON-index publiceren. De app downloadt die index en matcht on-device volgens het matching-logica-document (Fase 1).

**Te bevestigen bij de bouw:** de officiële EC-XML als fallback live uitlezen, de NVWA-RSS-parsing op echte items kalibreren, en de categorie-lookup vullen met de exacte broncategorie-strings (de spreadsheet geeft de groepen; de exacte string-lijst rolt uit de eerste ingestion-run).
