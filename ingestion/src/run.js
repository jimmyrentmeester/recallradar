// Orkestrator (Blok B): ophalen -> normaliseren -> dedup -> index schrijven -> publiceren.
// Fallback (B6): faalt een bron, behoud de vorige gepubliceerde index en log.
//
// Gebruik:
//   node src/run.js            incrementeel als er een vorige index is, anders volledig
//   node src/run.js --full     forceer volledige venster-rebuild

import { windowFloorDate } from './config.js';
import { fetchSafetyGate } from './sources/safetyGate.js';
import { fetchNvwa } from './sources/nvwa.js';
import { normalizeSafetyGate, normalizeNvwa } from './normalize.js';
import { dedup } from './dedup.js';
import { buildIndex } from './buildIndex.js';
import { publish, readPublishedMeta, readPublishedIndex } from './publish.js';

const log = (...m) => console.log(...m);

async function main() {
  const full = process.argv.includes('--full');
  const now = new Date();
  const generatedAt = now.toISOString();
  const windowFloor = windowFloorDate(now);

  const prevIndex = await readPublishedIndex();
  const prevMeta = await readPublishedMeta();
  const incremental = !full && prevIndex && prevMeta;
  const since = incremental ? prevMeta.generated_at : null;

  log(`Recall Radar ingestion — ${generatedAt}`);
  log(`  Modus: ${incremental ? `incrementeel (sinds ${since})` : 'volledig'} · venster vanaf ${windowFloor}`);

  // --- Safety Gate (primair). Fout hier is fataal: behoud vorige index. ---
  let sgRaw;
  try {
    sgRaw = await fetchSafetyGate({ windowFloor, sinceModification: since, log });
  } catch (err) {
    console.error('  FOUT Safety Gate:', err.message);
    return abortKeepPrevious(prevIndex);
  }

  // --- NVWA (primair NL). Fout hier is niet-fataal: ga door met Safety Gate. ---
  let nvwaRaw = [];
  try {
    nvwaRaw = await fetchNvwa({ windowFloor, log });
  } catch (err) {
    console.error('  WAARSCHUWING NVWA faalde, ga door zonder NVWA:', err.message);
  }

  // --- Normaliseren ---
  const fresh = [
    ...sgRaw.map((r) => normalizeSafetyGate(r, generatedAt)),
    ...nvwaRaw.map((r) => normalizeNvwa(r, generatedAt)).filter(Boolean), // food eruit
  ];
  log(`  Genormaliseerd: ${fresh.length} alerts (${sgRaw.length} SG raw, ${nvwaRaw.length} NVWA raw)`);

  // --- Bij incrementeel: merge met de vorige alerts ---
  let combined = fresh;
  if (incremental) {
    const freshIds = new Set(fresh.map((a) => a.id));
    const carried = (prevIndex.alerts ?? []).filter((a) => !freshIds.has(a.id));
    combined = [...fresh, ...carried];
    log(`  Incrementeel: ${fresh.length} nieuw/gewijzigd + ${carried.length} behouden`);
  }

  // --- Dedup + index ---
  const deduped = dedup(combined, log);
  const { index, meta } = buildIndex(deduped, { generatedAt, windowFloor });

  if (index.count === 0) {
    console.error('  FOUT: 0 alerts na verwerking — niet publiceren, behoud vorige index.');
    return abortKeepPrevious(prevIndex);
  }

  const { dir } = await publish({ index, meta });
  log(`  Gepubliceerd: ${index.count} alerts -> ${dir} (etag ${meta.etag})`);
}

function abortKeepPrevious(prevIndex) {
  if (prevIndex) {
    log('  Vorige index behouden (geen overschrijving).');
    process.exitCode = 0;
  } else {
    console.error('  Geen vorige index om op terug te vallen.');
    process.exitCode = 1;
  }
}

main().catch((err) => {
  console.error('Onverwachte fout:', err);
  process.exitCode = 1;
});
