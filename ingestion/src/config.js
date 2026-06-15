// Centrale configuratie voor de ingestion-job (Blok B).
// Eén plek voor endpoints, venster, paden en de index-config die de app meekrijgt.

import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Output-map die door de publish-stap (Blok B6) naar GitHub Pages wordt gepusht.
export const OUTPUT_DIR = path.resolve(__dirname, '..', 'public');

export const SCHEMA_VERSION = 1;

// Rollend venster (Blok B5). Niet de volledige historie meeshippen.
export const WINDOW_MONTHS = 24;

// --- Safety Gate (EU, via OpenDataSoft-mirror) — PRIMAIR, non-food ---
export const SAFETY_GATE = {
  // Geverifieerd live op 2026-06-15: dataset bestaat, CC0, dagelijks ververst.
  base: 'https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/healthref-europe-rapex-en',
  // Harde limieten van de Explore API v2.1 (live geverifieerd):
  pageLimit: 100, // limit > 100 => InvalidRESTParameterError
  offsetCap: 10000, // offset + limit moet <= 10000 blijven => anders fallback naar export
  publicUrl: 'https://ec.europa.eu/safety-gate-alerts/',
};

// --- NVWA (NL) — PRIMAIR NL, non-food ---
// De RSS-feed uit Fase 2 bestaat niet meer (site is een Next.js-SPA).
// Live geverifieerd alternatief: de eigen JSON-zoek-API achter de site
// (@elastic/search-ui connector). Dit is NVWA's eigen primaire bron, geen aggregator.
export const NVWA = {
  searchApi: 'https://www.nvwa.nl/api/search',
  site: 'https://www.nvwa.nl',
  // Vaste filters die de overzichtspagina 'Veiligheidswaarschuwingen' gebruikt:
  topic: 'Veiligheidswaarschuwingen',
  contentType: 'pro:downloadDocument',
  pageSize: 100,
};

// Index-config die met de app meereist, zodat matching-drempels en alias-tabel
// zonder app-update bijgesteld kunnen worden (Fase 1 matching-logica §6).
export const MATCHING_CONFIG = {
  weights: {
    barcodeExact: 70,
    brandExact: 30,
    modelExact: 40,
    modelFuzzy: 20,
    categoryEqual: 15,
    brandFuzzy: 15,
    batchInRange: 25,
    penaltyCategoryMismatch: -15,
    penaltyModelMismatch: -20,
  },
  thresholds: { high: 75, medium: 45, low: 20 },
  brandAliases: {
    'v-tech': 'vtech',
    'vtech': 'vtech',
  },
};

// User-Agent voor nette identificatie richting de bronnen.
export const USER_AGENT =
  'RecallRadar-Ingestion/1.0 (+https://github.com/recallradar; non-commercial public-safety app)';

// Datumondergrens van het venster (ISO-datum, UTC), afgeleid van nu.
export function windowFloorDate(now = new Date()) {
  const d = new Date(now);
  d.setUTCMonth(d.getUTCMonth() - WINDOW_MONTHS);
  return d.toISOString().slice(0, 10); // YYYY-MM-DD
}
