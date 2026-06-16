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

  // Verrijk elk item met de detailpagina: de volledige waarschuwingstekst bevat
  // het echte advies ("Gebruik … niet", "teruggeroepen", "breng terug") + soms een
  // fabrikant-link. Veel rijker dan de zoek-snippet → betere actie/risico-classificatie.
  await enrichWithDetails(out, log);
  return out;
}

// Detailpagina ophalen en de rich-text body + externe link extraheren.
async function fetchDetail(url) {
  try {
    const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT } });
    if (!res.ok) return null;
    const htmlText = await res.text();
    const i = htmlText.search(/class="rich-text[^"]*">/);
    if (i === -1) return null;
    const block = htmlText.slice(i, i + 6000);
    const paras = [...block.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/g)]
      .map((m) => stripTags(m[1]))
      .filter((t) => t.length > 0);
    const fullText = paras.join(' ').replace(/\s+/g, ' ').trim();
    const linkMatch = block.match(/href="(https?:\/\/[^"]+)"[^>]*rel="external"/)
      || block.match(/rel="external"[^>]*href="(https?:\/\/[^"]+)"/);
    return { fullText: fullText || null, officialLink: linkMatch ? linkMatch[1] : null };
  } catch {
    return null;
  }
}

function stripTags(s) {
  return s
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .trim();
}

// Concurrency-begrensde verrijking (resilient: faalt er één, dan blijft de snippet).
async function enrichWithDetails(items, log, concurrency = 8) {
  let idx = 0;
  let enriched = 0;
  async function worker() {
    while (idx < items.length) {
      const item = items[idx++];
      const detail = await fetchDetail(item.url);
      if (detail?.fullText) { item.fullText = detail.fullText; enriched += 1; }
      if (detail?.officialLink) item.officialLink = detail.officialLink;
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, items.length) }, worker));
  log?.(`  NVWA: ${enriched}/${items.length} detailpagina's verrijkt`);
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
