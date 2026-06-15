// B7 — Sanity-check op de gepubliceerde index. Vindt bekende recalls terug,
// rapporteert verdeling per bron/categorie en controleert schema-volledigheid.

import { readPublishedIndex } from './publish.js';

const REQUIRED = ['id', 'source', 'alert_number', 'category', 'risk_type', 'measure', 'country', 'source_url', 'published_at', 'updated_at'];

function tally(alerts, key) {
  const m = {};
  for (const a of alerts) m[a[key]] = (m[a[key]] ?? 0) + 1;
  return Object.entries(m).sort((x, y) => y[1] - x[1]);
}

async function main() {
  const index = await readPublishedIndex();
  if (!index) {
    console.error('Geen public/index.json. Draai eerst `npm run ingest`.');
    process.exit(1);
  }
  const alerts = index.alerts ?? [];
  console.log(`Index: ${index.count} alerts · gegenereerd ${index.generated_at} · venster ${index.window_months}mnd\n`);

  console.log('Per bron:');
  for (const [k, v] of tally(alerts, 'source')) console.log(`  ${k.padEnd(14)} ${v}`);

  console.log('\nPer categorie:');
  for (const [k, v] of tally(alerts, 'category')) {
    console.log(`  ${k.padEnd(24)} ${v}  ${index.categories?.[k]?.label ?? ''}`);
  }

  console.log('\nPer risico:');
  for (const [k, v] of tally(alerts, 'risk_type')) console.log(`  ${k.padEnd(18)} ${v}`);

  // Schema-volledigheid
  let missing = 0;
  for (const a of alerts) for (const f of REQUIRED) if (a[f] == null || a[f] === '') missing += 1;
  console.log(`\nVerplichte velden ontbrekend: ${missing} (van ${alerts.length * REQUIRED.length} gecontroleerd)`);

  // Signaal-dekking
  const withBarcode = alerts.filter((a) => a.barcode).length;
  const withImage = alerts.filter((a) => a.image_url).length;
  const withBrand = alerts.filter((a) => a.brand).length;
  const merged = alerts.filter((a) => a.merged_sources?.length).length;
  console.log(`\nSignaaldekking: barcode ${withBarcode} · merk ${withBrand} · foto ${withImage} · cross-source merges ${merged}`);

  // Bekende recall terugvinden (jonge-gezin-spits)
  console.log('\nSteekproef "kinderen_speelgoed" (nieuwste 3):');
  alerts.filter((a) => a.category === 'kinderen_speelgoed').slice(0, 3).forEach((a) => {
    console.log(`  [${a.source}] ${a.brand_raw ?? '—'} · ${a.model_raw ?? '—'} · ${a.risk_type} · ${a.published_at}`);
    console.log(`     ${a.source_url}`);
  });

  if (alerts.length === 0 || missing > 0) process.exitCode = 1;
}

main();
