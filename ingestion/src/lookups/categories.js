// B4 — Categorie-lookup (de bron van waarheid, Fase 2 tabblad Categorie-taxonomie).
// ~130 ruwe Safety Gate-categorieën -> 11 NL-groepen. Exacte bronstrings live
// geverifieerd uit de facets op 2026-06-15 (24-maands venster).
//
// Drie mechanismen:
//   1. EXACT_MAP   - exacte Safety Gate product_category-string -> interne code.
//   2. KEYWORD_MAP - trefwoord -> code, voor de 'Other - …'-staart én voor NVWA
//                    (NVWA levert vrije tekst; classificeren op titel/omschrijving).
//   3. FOOD_KEYWORDS - om NVWA-food uit de non-food-index te filteren (v1 = non-food).

export const CATEGORY_GROUPS = {
  kinderen_speelgoed: { label: 'Kinderen & speelgoed', youngFamily: true },
  verzorging_mode: { label: 'Verzorging & mode', youngFamily: false },
  auto_vervoer: { label: 'Auto & vervoer', youngFamily: false },
  elektronica_smarthome: { label: 'Elektronica & smart home', youngFamily: false },
  wonen_interieur: { label: 'Wonen & interieur', youngFamily: false },
  chemie: { label: 'Chemie & gevaarlijke stoffen', youngFamily: false },
  hobby_sport_tuin: { label: 'Hobby, sport & tuin', youngFamily: false },
  veiligheid_bescherming: { label: 'Veiligheid & bescherming', youngFamily: false },
  vuurwerk_brand: { label: 'Vuurwerk & brandrisico', youngFamily: false },
  witgoed_keuken: { label: 'Witgoed & keuken', youngFamily: false },
  overig: { label: 'Overig', youngFamily: false },
};

// 1. Exacte Safety Gate-categorieën -> interne code.
const EXACT_MAP = {
  // kinderen_speelgoed (de jonge-gezin-spits; autostoelen vallen onder childcare)
  'toys': 'kinderen_speelgoed',
  "childcare articles and children's equipment": 'kinderen_speelgoed',
  'tableware for children': 'kinderen_speelgoed',
  "children's accessories": 'kinderen_speelgoed',
  // verzorging_mode
  'cosmetics': 'verzorging_mode',
  'clothing, textiles and fashion items': 'verzorging_mode',
  'jewellery': 'verzorging_mode',
  'personal care': 'verzorging_mode',
  'personal accessories': 'verzorging_mode',
  // auto_vervoer
  'motor vehicles': 'auto_vervoer',
  'car accessories': 'auto_vervoer',
  'recreational crafts': 'auto_vervoer',
  'tyres': 'auto_vervoer',
  // elektronica_smarthome
  'electrical appliances and equipment': 'elektronica_smarthome',
  'communication and media equipment': 'elektronica_smarthome',
  'lighting equipment': 'elektronica_smarthome',
  'gadgets': 'elektronica_smarthome',
  'phone accessories': 'elektronica_smarthome',
  'measuring instruments': 'elektronica_smarthome',
  // wonen_interieur
  'furniture': 'wonen_interieur',
  'decorative articles': 'wonen_interieur',
  'lighting chains': 'wonen_interieur',
  // chemie
  'chemical products': 'chemie',
  // hobby_sport_tuin
  'hobby/sports equipment': 'hobby_sport_tuin',
  'machinery': 'hobby_sport_tuin',
  'hand tools': 'hobby_sport_tuin',
  'ladders/step stools': 'hobby_sport_tuin',
  'garden products': 'hobby_sport_tuin',
  'construction products': 'hobby_sport_tuin',
  // veiligheid_bescherming
  'protective equipment': 'veiligheid_bescherming',
  'explosive atmospheres equipment': 'veiligheid_bescherming',
  // vuurwerk_brand
  'pyrotechnic articles': 'vuurwerk_brand',
  'lighters': 'vuurwerk_brand',
  'laser pointers': 'vuurwerk_brand',
  'sky lantern': 'vuurwerk_brand',
  // witgoed_keuken
  'kitchen/cooking accessories': 'witgoed_keuken',
  'gas appliances and components': 'witgoed_keuken',
  'barbecue': 'witgoed_keuken',
  'pressure equipment/vessels': 'witgoed_keuken',
  'pressure equipment': 'witgoed_keuken',
  // overig
  'stationery': 'overig',
  'other': 'overig',
  '-': 'overig',
};

// 2. Trefwoord -> code. Volgorde = prioriteit (eerste match wint).
// Gebruikt voor de 'Other - …'-staart (Safety Gate) én voor NVWA-classificatie
// (NVWA-trefwoorden uit Fase 2). Trefwoorden zijn NL + EN.
const KEYWORD_MAP = [
  ['kinderen_speelgoed', ['speelgoed', 'toy', 'kinderwagen', 'autostoel', 'kinderzitje', 'box', 'fopspeen', 'speen', 'babyfoon', 'kinder', 'baby', 'knuffel', 'pet led collar', 'kind']],
  ['vuurwerk_brand', ['vuurwerk', 'aansteker', 'lighter', 'laser', 'wensballon', 'sky lantern', 'pyrotech']],
  ['auto_vervoer', ['auto', 'voertuig', 'car', 'vehicle', 'band', 'tyre', 'tire', 'motor', 'fiets', 'e-bike', 'ebike', 'floor mat', 'watercraft', 'luggage']],
  ['veiligheid_bescherming', ['beschermingsmiddel', 'helm', 'rookmelder', 'co-melder', 'co melder', 'mondkapje', 'protective', 'smoke detector', 'gas detector', 'heat detector', 'safety']],
  ['witgoed_keuken', ['keuken', 'mixer', 'pan', 'gastoestel', 'barbecue', 'bbq', 'snelkookpan', 'kitchen', 'cooking', 'grill']],
  ['elektronica_smarthome', ['lader', 'charger', 'adapter', 'telefoon', 'phone', 'lamp', 'led', 'smart', 'snoer', 'accu', 'batterij', 'battery', 'e-cigarette', 'e cigarette', 'electronic cigarette', 'powerbank']],
  ['hobby_sport_tuin', ['sport', 'fitness', 'ladder', 'gereedschap', 'tool', 'tuin', 'garden', 'machine', 'hammam', 'recovery tape']],
  ['chemie', ['chemisch', 'chemical', 'reiniger', 'lijm', 'oplosmiddel', 'spray', 'cockpit spray', 'cleaner']],
  ['veiligheid_bescherming', ['detector']],
  ['wonen_interieur', ['meubel', 'kast', 'lampjes', 'lichtsnoer', 'decoratie', 'furniture', 'decorative', 'bathroom']],
  ['verzorging_mode', ['cosmetica', 'creme', 'crème', 'kleding', 'textiel', 'sieraad', 'parfum', 'cosmetic', 'clothing', 'jewellery', 'hygiene', 'personal accessor', 'esoteric', 'books', 'book']],
];

// 3. NVWA-food-indicatoren: deze warnings horen niet in de non-food-index (v1).
// RASFF/food komt later als aparte module.
const FOOD_KEYWORDS = [
  'allergen', 'levensmiddel', 'voedsel', 'food', 'eten', 'oester', 'vlees',
  'worst', 'snack', 'soep', 'croissant', 'kaas', 'vis', 'salade', 'saus',
  'chocola', 'koek', 'noten', 'pinda', 'melk', 'zuivel', 'gluten', 'ei ',
  'eieren', 'kruiden', 'thee', 'koffie', 'drank', 'sap', 'salmonella',
  'listeria', 'e. coli', 'bacterie', 'schimmel', 'bedorven', 'houdbaarheid',
  'supplement', 'voedingssupplement', 'babyvoeding', 'flesvoeding',
];

const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '');

// Safety Gate: exacte map, anders trefwoord (voor 'Other - …'), anders 'overig'.
export function mapSafetyGateCategory(rawCategory) {
  const key = norm(rawCategory).trim();
  if (!key) return 'overig';
  if (EXACT_MAP[key]) return EXACT_MAP[key];
  return keywordCategory(key) ?? 'overig';
}

// NVWA: classificeer op vrije tekst (titel + omschrijving). 'overig' als niets matcht.
export function classifyNvwaCategory(text) {
  return keywordCategory(norm(text)) ?? 'overig';
}

// Is deze NVWA-tekst (titel + omschrijving) food? -> uit de non-food-index houden.
export function isFood(text) {
  const t = norm(text);
  return FOOD_KEYWORDS.some((kw) => t.includes(kw));
}

function keywordCategory(text) {
  for (const [code, words] of KEYWORD_MAP) {
    if (words.some((w) => text.includes(w))) return code;
  }
  return null;
}

export function categoryLabel(code) {
  return CATEGORY_GROUPS[code]?.label ?? CATEGORY_GROUPS.overig.label;
}
