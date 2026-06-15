// B2 — NVWA ophalen (PRIMAIR NL, non-food).
//
// LET OP — afwijking van Fase 2: de RSS-feed bestaat niet meer. NVWA's site is
// een Next.js-SPA. Live geverifieerd alternatief (2026-06-15): de eigen JSON-
// zoek-API (@elastic/search-ui connector) die de overzichtspagina
// 'Veiligheidswaarschuwingen' voedt. Dit is NVWA's eigen primaire bron — geen
// aggregator, geen HTML-scrape — dus binnen de guardrails.
//
// De API levert food + non-food door elkaar en geen gestructureerde merk/categorie-
// velden; dat wordt in normalize.js uit titel/omschrijving geparsed (Fase 2:
// 'NVWA levert vrije tekst -> parsen'). Food wordt eruit gefilterd (v1 = non-food).

import { NVWA, USER_AGENT } from '../config.js';

const RESULT_FIELDS = {
  url: { raw: {} },
  page_title: { raw: {} },
  sort_date: { raw: {} },
  image_url: { raw: {} },
  meta_description: { raw: {}, snippet: { size: 300, fallback: true } },
};

function baseFilters() {
  return [
    { field: 'topic', values: [NVWA.topic], type: 'all' },
    { field: 'content_type', values: [NVWA.contentType], type: 'any' },
  ];
}

function buildPayload(page) {
  const filters = baseFilters();
  return {
    requestState: {
      current: page,
      filters,
      resultsPerPage: NVWA.pageSize,
      searchTerm: '',
      sortDirection: '',
      sortField: '',
      sortList: [{ field: 'sort_date', direction: 'desc' }],
    },
    queryConfig: {
      filters,
      result_fields: RESULT_FIELDS,
      disjunctiveFacets: [],
      facets: {},
    },
  };
}

async function postSearch(page) {
  const res = await fetch(NVWA.searchApi, {
    method: 'POST',
    headers: {
      'User-Agent': USER_AGENT,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify(buildPayload(page)),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`NVWA ${res.status} ${res.statusText}\n${body.slice(0, 300)}`);
  }
  return res.json();
}

const raw = (item, key) => (item?.[key]?.raw ?? null);

// Haalt alle veiligheidswaarschuwingen op tot de venster-ondergrens (sort_date).
// windowFloor = YYYY-MM-DD. Retourneert genormaliseerd-ruwe items
// { title, summary, url, date, imageUrl } — food blijft erin; eruit gefilterd in normalize.
export async function fetchNvwa({ windowFloor, log = null } = {}) {
  const floor = new Date(windowFloor).getTime();
  const out = [];
  const first = await postSearch(1);
  const totalPages = Math.min(first.totalPages ?? 1, 200);
  let stop = collectPage(first, floor, out);
  log?.(`  NVWA: ${first.totalResults} waarschuwingen totaal (food+non-food)`);

  for (let page = 2; page <= totalPages && !stop; page += 1) {
    const data = await postSearch(page);
    stop = collectPage(data, floor, out);
    log?.(`  NVWA: ${out.length} binnen venster (pagina ${page}/${totalPages})`);
  }
  return out;
}

// Voegt items van één pagina toe; retourneert true zodra we onder het venster zakken
// (resultaten zijn sort_date desc, dus daarna kunnen we stoppen).
function collectPage(data, floorMs, out) {
  for (const item of data.results ?? []) {
    const dateStr = raw(item, 'sort_date');
    const ts = dateStr ? new Date(dateStr).getTime() : NaN;
    if (!Number.isNaN(ts) && ts < floorMs) return true; // ouder dan venster -> klaar
    const url = raw(item, 'url');
    out.push({
      title: raw(item, 'page_title') ?? '',
      summary: raw(item, 'meta_description') ?? '',
      url: url ? new URL(url, NVWA.site).toString() : NVWA.site,
      date: dateStr,
      imageUrl: raw(item, 'image_url'),
    });
  }
  return false;
}
