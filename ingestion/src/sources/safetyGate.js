// B1 — Safety Gate ophalen via OpenDataSoft Explore API v2.1 (PRIMAIR, non-food).
// Live geverifieerd 2026-06-15. Ondersteunt paginatie + incrementeel op
// modification_date, met automatische fallback naar het export-endpoint wanneer
// het 24-maands venster de offset-cap (10.000) nadert.

import { SAFETY_GATE, USER_AGENT } from '../config.js';

async function getJson(url) {
  const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' } });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`Safety Gate ${res.status} ${res.statusText} :: ${url}\n${body.slice(0, 300)}`);
  }
  return res.json();
}

// ODSQL where-clause opbouwen. windowFloor = YYYY-MM-DD; since = ISO-timestamp (optioneel).
function buildWhere({ windowFloor, sinceModification }) {
  const clauses = [`alert_date >= '${windowFloor}'`];
  if (sinceModification) clauses.push(`modification_date > '${sinceModification}'`);
  return clauses.join(' AND ');
}

async function fetchTotalCount(where) {
  const url = `${SAFETY_GATE.base}/records?limit=1&where=${encodeURIComponent(where)}`;
  const data = await getJson(url);
  return data.total_count ?? 0;
}

// Paginated records-API (limit 100, offset). Honoreert de 'paginatie'-eis.
async function fetchPaginated(where, log) {
  const out = [];
  let offset = 0;
  const limit = SAFETY_GATE.pageLimit;
  while (offset + limit <= SAFETY_GATE.offsetCap) {
    const url =
      `${SAFETY_GATE.base}/records?limit=${limit}&offset=${offset}` +
      `&order_by=${encodeURIComponent('modification_date desc')}` +
      `&where=${encodeURIComponent(where)}`;
    const data = await getJson(url);
    const results = data.results ?? [];
    out.push(...results);
    log?.(`  Safety Gate: ${out.length}/${data.total_count} opgehaald (offset ${offset})`);
    if (results.length < limit) break;
    offset += limit;
  }
  return out;
}

// Export-endpoint: één call, geen offset-cap. Fallback voor grote vensters.
async function fetchExport(where, log) {
  const url = `${SAFETY_GATE.base}/exports/json?limit=-1&where=${encodeURIComponent(where)}`;
  log?.('  Safety Gate: export-endpoint (venster > offset-cap)');
  const data = await getJson(url);
  return Array.isArray(data) ? data : [];
}

// Hoofdfunctie. Retourneert ruwe Safety Gate-records.
export async function fetchSafetyGate({ windowFloor, sinceModification = null, log = null } = {}) {
  const where = buildWhere({ windowFloor, sinceModification });
  const total = await fetchTotalCount(where);
  log?.(`  Safety Gate: ${total} records matchen (where: ${where})`);
  if (total === 0) return [];
  // Bij incrementeel (klein) of klein venster: paginatie. Anders export.
  if (total + SAFETY_GATE.pageLimit < SAFETY_GATE.offsetCap) {
    return fetchPaginated(where, log);
  }
  return fetchExport(where, log);
}
