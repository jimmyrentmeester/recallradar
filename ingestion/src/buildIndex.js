// B5 — Index assembleren. Schrijft index.json (rollend 24-maands venster, getrimd)
// + meta.json (goedkope versie-check). ETag-vriendelijk via content-hash.

import { createHash } from 'node:crypto';
import { SCHEMA_VERSION, WINDOW_MONTHS, MATCHING_CONFIG } from './config.js';
import { CATEGORY_GROUPS, categoryLabel } from './lookups/categories.js';
import { RISK_GROUPS } from './lookups/risks.js';

function withinWindow(alert, floorMs) {
  const ts = alert.published_at ? new Date(alert.published_at).getTime() : NaN;
  return Number.isNaN(ts) ? true : ts >= floorMs;
}

export function buildIndex(alerts, { generatedAt, windowFloor }) {
  const floorMs = new Date(windowFloor).getTime();
  const windowed = alerts
    .filter((a) => withinWindow(a, floorMs))
    .sort((a, b) => String(b.published_at).localeCompare(String(a.published_at)));

  const index = {
    schema_version: SCHEMA_VERSION,
    generated_at: generatedAt,
    window_months: WINDOW_MONTHS,
    count: windowed.length,
    // Taxonomie + matching-config reizen mee, zodat de app labels toont en
    // drempels kan bijstellen zonder app-update (Fase 1 §6).
    categories: Object.fromEntries(
      Object.entries(CATEGORY_GROUPS).map(([code, g]) => [code, { label: g.label, young_family: g.youngFamily }]),
    ),
    risks: Object.fromEntries(
      Object.entries(RISK_GROUPS).map(([code, g]) => [code, { label: g.label }]),
    ),
    matching_config: MATCHING_CONFIG,
    disclaimer:
      'Informatief, niet uitputtend. De officiële bron en fabrikant zijn leidend. ' +
      'Controleer altijd de officiële recall-pagina via de bronlink.',
    alerts: windowed,
  };

  const etag = `"${createHash('sha256').update(JSON.stringify(index.alerts)).digest('hex').slice(0, 16)}"`;
  const meta = {
    generated_at: generatedAt,
    schema_version: SCHEMA_VERSION,
    window_months: WINDOW_MONTHS,
    count: windowed.length,
    etag,
  };
  return { index, meta, etag };
}

export { categoryLabel };
