// B3 — Normalisatie naar het genormaliseerde RecallAlert-schema (Fase 2 Alert-schema
// + Bron-mapping). Eén record per recall/alert; de app kent alleen dit schema.

import {
  normalizeText, normalizeModel, normalizeBarcode,
  toISODate, toISODateTime, toArray, firstNonEmpty,
} from './util.js';
import { mapSafetyGateCategory, classifyNvwaCategory, isFood } from './lookups/categories.js';
import { mapRisk, riskLabel } from './lookups/risks.js';
import { mapCountry } from './lookups/countries.js';
import { translateMeasure, consumerAction } from './lookups/measures.js';

const slug = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

// Stabiele korte hash (FNV-1a) voor NVWA-id's wanneer er geen alertnummer is.
function hash(s) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i += 1) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return (h >>> 0).toString(36);
}

// ---------- Safety Gate ----------
export function normalizeSafetyGate(rec, ingestedAt) {
  const alertNumber = rec.alert_number ?? '';
  const brandRaw = firstNonEmpty(rec.product_brand);
  const modelRaw = firstNonEmpty(rec.product_model_type);
  const measure = toArray(rec.measures_country).map(translateMeasure).filter(Boolean).join(' ')
    || 'Zie de officiële bron voor het handelingsadvies.';
  const riskCode = mapRisk(rec.alert_type);
  const action = consumerAction(toArray(rec.measures_country), riskLabel(riskCode));
  const sourceUrl = firstNonEmpty(rec.product_recall_url, rec.rapex_url, 'https://ec.europa.eu/safety-gate-alerts/');

  return {
    id: `sg-${slug(alertNumber) || hash(JSON.stringify(rec).slice(0, 200))}`,
    source: 'safety_gate',
    alert_number: alertNumber,
    brand: brandRaw ? normalizeText(brandRaw) : null,
    brand_raw: brandRaw,
    model: modelRaw ? normalizeModel(modelRaw) : null,
    model_raw: modelRaw,
    category: mapSafetyGateCategory(rec.product_category),
    source_category: firstNonEmpty(rec.product_category),
    barcode: normalizeBarcode(rec.product_barcode),
    batch_lot: firstNonEmpty(rec.product_batch_number, rec.product_recall_code),
    risk_type: riskCode,
    risk_desc: firstNonEmpty(rec.alert_description),
    measure,
    action,
    country: mapCountry(rec.alert_country) ?? 'EU',
    image_url: firstNonEmpty(rec.product_image),
    image_urls: toArray(rec.product_other_images),
    source_url: sourceUrl,
    published_at: toISODate(rec.alert_date),
    updated_at: toISODateTime(rec.modification_date) ?? toISODateTime(rec.alert_date),
    ingested_at: ingestedAt,
  };
}

// ---------- NVWA ----------
// Titelpatroon (live geverifieerd): "Veiligheidswaarschuwing <product> van <merk>".
// Omschrijving: "<merk> waarschuwt voor <product>. <risico/advies>".
const NVWA_RISK_KEYWORDS = [
  ['verstikking', ['verstik', 'verslik', 'inslikken', 'kleine onderdelen', 'magneet']],
  ['brand_hitte', ['brand', 'oververhit', 'verbrand', 'hitte', 'vlam']],
  ['elektrisch', ['elektrische schok', 'stroomschok', 'elektrocut', 'kortsluiting']],
  ['chemisch', ['chemisch', 'stof', 'allergisch', 'huidirritatie', 'gif']],
  ['letsel', ['letsel', 'snijwond', 'verwond', 'vallen', 'breuk', 'scherp']],
  ['beknelling', ['beknel', 'verstrik', 'wurg']],
];

function parseNvwaRisk(text) {
  const t = text.toLowerCase();
  for (const [code, words] of NVWA_RISK_KEYWORDS) {
    if (words.some((w) => t.includes(w))) return code;
  }
  return 'overig_risico';
}

function parseNvwaBrandModel(title) {
  // "Veiligheidswaarschuwing X van MERK (extra)" -> product=X, brand=MERK
  let t = title.replace(/^veiligheidswaarschuwing\s*/i, '').trim();
  // haakjes-toevoegingen (bv. "(roze en blauw)" / "(allergenen)") apart houden
  const parenStripped = t.replace(/\s*\([^)]*\)\s*$/g, '').trim();
  const m = parenStripped.match(/^(.*)\s+van\s+(.+)$/i);
  if (m) return { product: m[1].trim(), brand: m[2].trim() };
  return { product: parenStripped, brand: null };
}

// Retourneert null als het item food is (hoort niet in de non-food-index, v1).
export function normalizeNvwa(item, ingestedAt) {
  const haystack = `${item.title} ${item.summary}`;
  if (isFood(haystack)) return null;

  const { product, brand } = parseNvwaBrandModel(item.title);
  const brandRaw = brand;
  const id = `nvwa-${hash(item.url)}`;
  const riskCode = parseNvwaRisk(haystack);

  return {
    id,
    source: 'nvwa',
    alert_number: item.url.split('/').filter(Boolean).pop() ?? id,
    brand: brandRaw ? normalizeText(brandRaw) : null,
    brand_raw: brandRaw,
    model: product ? normalizeModel(product) : null,
    model_raw: product || null,
    category: classifyNvwaCategory(haystack),
    source_category: null,
    barcode: extractBarcode(item.summary),
    batch_lot: extractBatch(item.summary),
    risk_type: riskCode,
    risk_desc: item.summary || null,
    measure: item.summary || 'Zie de officiële NVWA-waarschuwing voor het handelingsadvies.',
    action: consumerAction([haystack], riskLabel(riskCode)),
    country: 'NL',
    image_url: item.imageUrl ?? null,
    image_urls: [],
    source_url: item.url,
    published_at: toISODate(item.date),
    updated_at: toISODateTime(item.date),
    ingested_at: ingestedAt,
  };
}

function extractBarcode(text) {
  if (!text) return null;
  const m = text.match(/\b\d{8}(\d{5})?\b/g); // 8 of 13 cijfers
  if (!m) return null;
  for (const cand of m) {
    const bc = normalizeBarcode(cand);
    if (bc) return bc;
  }
  return null;
}

function extractBatch(text) {
  if (!text) return null;
  const m = text.match(/\b(lot|batch|charge|productiedatum)\s*[:#]?\s*([A-Za-z0-9./-]{3,})/i);
  return m ? `${m[1].toUpperCase()} ${m[2]}` : null;
}
