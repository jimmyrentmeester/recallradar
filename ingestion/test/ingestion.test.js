import { test } from 'node:test';
import assert from 'node:assert/strict';

import { normalizeText, normalizeModel, normalizeBarcode, toArray } from '../src/util.js';
import { mapSafetyGateCategory, classifyNvwaCategory, isFood } from '../src/lookups/categories.js';
import { mapRisk } from '../src/lookups/risks.js';
import { mapCountry } from '../src/lookups/countries.js';
import { normalizeSafetyGate, normalizeNvwa } from '../src/normalize.js';
import { translateMeasure, consumerAction } from '../src/lookups/measures.js';
import { dedup } from '../src/dedup.js';

const NOW = '2026-06-15T10:00:00Z';

test('normalizeText: lowercase, diacritics, juridische suffixen', () => {
  assert.equal(normalizeText('Philips B.V.'), 'philips');
  assert.equal(normalizeText('VTECH GmbH'), 'vtech');
  assert.equal(normalizeText('Krëfel  N.V.'), 'krefel');
});

test('normalizeModel: scheidingstekens uniform', () => {
  assert.equal(normalizeModel('HX-200'), 'hx200');
  assert.equal(normalizeModel('HR 2520'), 'hr2520');
});

test('normalizeBarcode: EAN-13/UPC checkdigit', () => {
  assert.equal(normalizeBarcode('8710103997078'), '8710103997078'); // geldige EAN-13
  assert.equal(normalizeBarcode('036000291452'), '0036000291452'); // UPC-12 -> EAN-13
  assert.equal(normalizeBarcode('1234567890123'), null); // foute checkdigit
  assert.equal(normalizeBarcode(null), null);
});

test('toArray normaliseert scalar/array/null', () => {
  assert.deepEqual(toArray(['a', 'b']), ['a', 'b']);
  assert.deepEqual(toArray('a'), ['a']);
  assert.deepEqual(toArray(null), []);
});

test('mapSafetyGateCategory: exact + Other-staart + fallback', () => {
  assert.equal(mapSafetyGateCategory('Toys'), 'kinderen_speelgoed');
  assert.equal(mapSafetyGateCategory("Childcare articles and children's equipment"), 'kinderen_speelgoed');
  assert.equal(mapSafetyGateCategory('Cosmetics'), 'verzorging_mode');
  assert.equal(mapSafetyGateCategory('Other - Telescopic Ladder'), 'hobby_sport_tuin'); // trefwoord
  assert.equal(mapSafetyGateCategory('Other - Esoteric product'), 'verzorging_mode');
  assert.equal(mapSafetyGateCategory('Wholly unknown thing'), 'overig');
});

test('classifyNvwaCategory op vrije tekst', () => {
  assert.equal(classifyNvwaCategory('Veiligheidswaarschuwing knuffelkonijn van Flying Tiger'), 'kinderen_speelgoed');
  assert.equal(classifyNvwaCategory('contactgrill van ZWILLING'), 'witgoed_keuken');
});

test('isFood houdt food uit de non-food-index', () => {
  assert.equal(isFood('BBQ worsten pittig (allergenen)'), true);
  assert.equal(isFood('Bevroren oesters van Surasang'), true);
  assert.equal(isFood('Vivera Plantaardige Groenteburger 2 stuks'), true);
  assert.equal(isFood('knuffelkonijn van Flying Tiger'), false);
  // Geen valse positieven door substring-matching:
  assert.equal(isFood('Televisie van merk X'), false); // 'vis' niet in 'televisie'
  assert.equal(isFood('Viscose trui'), false);          // 'vis' niet in 'viscose'
  assert.equal(isFood('Kleine onderdelen, kind kan erin stikken'), false); // 'ei' niet in 'kleine'
});

test('mapRisk: array-input en aliasing', () => {
  assert.equal(mapRisk(['Injuries']), 'letsel');
  assert.equal(mapRisk(['Choking']), 'verstikking');
  assert.equal(mapRisk(['Chemical']), 'chemisch');
  assert.equal(mapRisk('Fire'), 'brand_hitte');
  assert.equal(mapRisk(['Totally new risk']), 'overig_risico');
});

test('mapCountry: volledige naam -> ISO-2', () => {
  assert.equal(mapCountry('Germany'), 'DE');
  assert.equal(mapCountry('The Netherlands'), 'NL');
  assert.equal(mapCountry('United Kingdom in respect of Northern Ireland'), 'GB');
});

test('normalizeSafetyGate: echte record-vorm -> schema', () => {
  const rec = {
    alert_number: 'SR/01725/26',
    product_brand: 'Alpina',
    product_model_type: 'e1*KS07/46*0005*',
    product_category: 'Motor vehicles',
    alert_type: ['Injuries'],
    alert_description: 'Airbag may burst.',
    measures_country: ['Recall of the product from end users'],
    alert_country: 'Germany',
    product_image: 'https://img/1.jpg',
    product_other_images: ['https://img/2.jpg'],
    product_recall_url: null,
    rapex_url: 'https://ec.europa.eu/safety-gate-alerts/x',
    product_barcode: null,
    product_batch_number: null,
    product_recall_code: '0032730300',
    alert_date: '2026-06-12',
    modification_date: '2026-06-15T08:05:02+00:00',
  };
  const a = normalizeSafetyGate(rec, NOW);
  assert.equal(a.id, 'sg-sr-01725-26');
  assert.equal(a.source, 'safety_gate');
  assert.equal(a.brand, 'alpina');
  assert.equal(a.category, 'auto_vervoer');
  assert.equal(a.risk_type, 'letsel');
  assert.equal(a.country, 'DE');
  assert.equal(a.batch_lot, '0032730300'); // valt terug op recall_code
  assert.equal(a.source_url, 'https://ec.europa.eu/safety-gate-alerts/x'); // valt terug op rapex_url
  assert.equal(a.published_at, '2026-06-12');
  assert.deepEqual(a.image_urls, ['https://img/2.jpg']);
});

test('normalizeNvwa: titel-parsing + food-filter', () => {
  const food = normalizeNvwa({
    title: 'Veiligheidswaarschuwing BBQ worsten (allergenen)',
    summary: 'Verkeerd etiket.', url: 'https://www.nvwa.nl/x/1', date: '2026-06-12',
  }, NOW);
  assert.equal(food, null); // food eruit

  const a = normalizeNvwa({
    title: 'Veiligheidswaarschuwing ENFINIGY contactgrill van ZWILLING',
    summary: 'ZWILLING waarschuwt voor brandgevaar door oververhitting.',
    url: 'https://www.nvwa.nl/documenten/2026/06/15/x', date: '2026-06-15T14:38:00+00:00',
  }, NOW);
  assert.equal(a.source, 'nvwa');
  assert.equal(a.brand, 'zwilling');
  assert.equal(a.model_raw, 'ENFINIGY contactgrill');
  assert.equal(a.category, 'witgoed_keuken');
  assert.equal(a.risk_type, 'brand_hitte');
  assert.equal(a.country, 'NL');
});

test('translateMeasure: getemplate measure → NL', () => {
  assert.equal(
    translateMeasure('Measures ordered by economic operators (to: Manufacturer) Recall of the product from end users'),
    'Teruggeroepen — breng het product terug of stop met gebruik. (Maatregel door de marktdeelnemer, richting fabrikant.)'
  );
  assert.match(
    translateMeasure('Measures ordered by public authorities (to: Distributor) Withdrawal of the product from market'),
    /^Uit de handel genomen\. \(Maatregel door de autoriteiten, richting distributeur\.\)$/
  );
  // "Other:"-vrije tekst → verkoper-variant herkend
  assert.match(
    translateMeasure('Measures ordered by economic operators (to: Other) Other:  Warn the seller of the risks'),
    /Verkoper gewaarschuwd/
  );
  // Geen patroon → ongewijzigd
  assert.equal(translateMeasure('iets heel anders'), 'iets heel anders');
});

test('consumerAction: maatregel → bezitter-actie (sterkste wint)', () => {
  assert.match(
    consumerAction(['Measures ordered by economic operators (to: Manufacturer) Recall of the product from end users'], 'Letsel'),
    /breng het product terug/i
  );
  // Recall wint van warning bij meerdere maatregelen.
  assert.match(
    consumerAction([
      'Measures ordered by public authorities (to: Other) Warning consumers of the risks',
      'Measures ordered by economic operators (to: Distributor) Recall of the product from end users',
    ], 'Brand / hitte'),
    /terug/i
  );
  // Alleen waarschuwing → voorzichtig, met risico.
  assert.match(
    consumerAction(['Measures ordered by public authorities (to: Retailer) Warning consumers of the risks'], 'Brand / hitte'),
    /voorzichtig.*brand/i
  );
  // NVWA vrije tekst met "teruggeroepen" → recall-actie.
  assert.match(consumerAction(['Het product wordt teruggeroepen.'], 'Letsel'), /terug/i);
});

test('dedup: id-niveau houdt het meest complete record', () => {
  const base = {
    id: 'sg-1', source: 'safety_gate', alert_number: '1', brand: 'philips', model: 'hr2520',
    risk_type: 'brand_hitte', published_at: '2026-06-01', measure: 'x', country: 'NL', source_url: 'u',
  };
  const sparse = { ...base, barcode: null, image_url: null };
  const rich = { ...base, barcode: '8710103997078', image_url: 'i' };
  const out = dedup([sparse, rich]);
  assert.equal(out.length, 1);
  assert.equal(out[0].barcode, '8710103997078');
});

test('dedup: cross-source merge op genormaliseerde sleutel', () => {
  const sg = {
    id: 'sg-1', source: 'safety_gate', alert_number: '1', brand: 'flying tiger', model: 'knuffelkonijn',
    risk_type: 'verstikking', published_at: '2026-06-15', measure: 'recall', country: 'NL',
    source_url: 'https://ec.europa.eu/x', barcode: '8710103997078',
  };
  const nvwa = {
    id: 'nvwa-1', source: 'nvwa', alert_number: 'x', brand: 'flying tiger', model: 'knuffelkonijn',
    risk_type: 'verstikking', published_at: '2026-06-15', measure: 'stop gebruik', country: 'NL',
    source_url: 'https://www.nvwa.nl/x',
  };
  const out = dedup([sg, nvwa]);
  assert.equal(out.length, 1);
  assert.ok(out[0].merged_sources.includes('nvwa'));
  assert.ok(out[0].merged_sources.includes('safety_gate'));
});
