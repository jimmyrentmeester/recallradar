// B5 — Dedup. Twee niveaus (Fase 1 §9 / Fase 2):
//   1. source + alert_number (exacte dubbels, via id).
//   2. genormaliseerd (merk + model + risico + datum) om dezelfde recall die via
//      Safety Gate én NVWA binnenkomt samen te voegen.
// Bij een botsing houden we het meest complete record (barcode/foto/batch/tekst).

function completeness(a) {
  let s = 0;
  if (a.barcode) s += 4;
  if (a.batch_lot) s += 2;
  if (a.image_url) s += 1;
  if (a.model) s += 1;
  if (a.brand) s += 1;
  s += Math.min((a.measure?.length ?? 0) / 100, 2);
  return s;
}

function normKey(a) {
  if (!a.brand || !a.model) return null; // te schaars om veilig te mergen
  return `${a.brand}|${a.model}|${a.risk_type}|${a.published_at ?? ''}`;
}

export function dedup(alerts, log = null) {
  // Niveau 1: op id.
  const byId = new Map();
  for (const a of alerts) {
    const prev = byId.get(a.id);
    if (!prev || completeness(a) > completeness(prev)) byId.set(a.id, a);
  }

  // Niveau 2: op genormaliseerde sleutel.
  const byKey = new Map();
  const passthrough = [];
  for (const a of byId.values()) {
    const k = normKey(a);
    if (!k) { passthrough.push(a); continue; }
    const prev = byKey.get(k);
    if (!prev) { byKey.set(k, a); continue; }
    // Merge: houd het meest complete record, onthoud de tweede bron-URL.
    const [keep, drop] = completeness(a) >= completeness(prev) ? [a, prev] : [prev, a];
    if (drop.source !== keep.source) {
      keep.merged_sources = Array.from(
        new Set([...(keep.merged_sources ?? [keep.source]), drop.source]),
      );
      keep.merged_source_urls = Array.from(
        new Set([...(keep.merged_source_urls ?? [keep.source_url]), drop.source_url]),
      );
    }
    byKey.set(k, keep);
  }

  const result = [...passthrough, ...byKey.values()];
  log?.(`  Dedup: ${alerts.length} -> ${result.length} (${alerts.length - result.length} samengevoegd/verwijderd)`);
  return result;
}
