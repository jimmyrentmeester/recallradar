// B3/feedback — Vertaal de getemplate Safety Gate `measures_country` naar NL.
// Patroon: "Measures ordered by <authority> (to: <role>) <action>".
// Authority/role + de ~dozijn hoofd-acties dekken het leeuwendeel; "Other: <vrije tekst>"
// valt terug op een NL-frame met de bron-actie. Gratis, deterministisch, geen API.

const AUTHORITIES = {
  'public authorities': 'de autoriteiten',
  'economic operators': 'de marktdeelnemer',
};

const ROLES = {
  distributor: 'distributeur',
  manufacturer: 'fabrikant',
  retailer: 'winkelier',
  importer: 'importeur',
  exportator: 'exporteur',
  other: 'betrokkene',
};

// Genormaliseerde (lowercase, getrimde) actie → NL. Consumentgericht waar mogelijk.
const ACTIONS = {
  'recall of the product from end users': 'Teruggeroepen — breng het product terug of stop met gebruik',
  'recall of the product': 'Teruggeroepen — breng het product terug of stop met gebruik',
  'recall of the product from commercial users': 'Teruggeroepen bij zakelijke gebruikers',
  'recall of a product from commercial users': 'Teruggeroepen bij zakelijke gebruikers',
  'recall indicating repair by consumers': 'Teruggeroepen — reparatie door de consument',
  'withdrawal of the product from market': 'Uit de handel genomen',
  'withdrawal of the product from the market': 'Uit de handel genomen',
  'ban on the marketing of the product and any accompanying measures': 'Verkoopverbod',
  'ban on the marketing of the product': 'Verkoopverbod',
  'temporary ban on the supply': 'Tijdelijk leveringsverbod',
  'stop of sales': 'Verkoop gestopt',
  'destruction of the product': 'Product wordt vernietigd',
  'import rejected at border': 'Invoer geweigerd aan de grens',
  'removal of this product listing by the online marketplace': 'Aanbieding verwijderd door het online platform',
  'removal of this product listing by the online marketplace/webshop': 'Aanbieding verwijderd door het online platform/webshop',
  'warning consumers of the risks': 'Waarschuwing aan consumenten voor de risico’s',
  'marking the product with appropriate warnings on the risks': 'Product voorzien van waarschuwingen over de risico’s',
  'making the marketing of the product subject to prior conditions': 'Verkoop alleen onder voorwaarden toegestaan',
  'corrective measures': 'Corrigerende maatregelen',
  'technical measures': 'Technische maatregelen',
  'seizure of goods': 'Goederen in beslag genomen',
  'confiscation': 'In beslag genomen',
  'disposal of products': 'Producten afgevoerd',
  'fine': 'Boete opgelegd',
  'modification of packaging': 'Verpakking aangepast',
  'offer to supply and display of the product': 'Aanbod tot levering en uitstalling van het product',
};

const norm = (s) => String(s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();

function translateAction(action) {
  let a = action.trim();
  // "Other:  <tekst>" → pak de vrije tekst.
  const other = a.match(/^other\s*:\s*(.+)$/i);
  const core = other ? other[1].trim() : a;
  const key = norm(core);
  if (ACTIONS[key]) return ACTIONS[key];
  // Veelvoorkomende variant: verkoper waarschuwen.
  if (/warn(ing)?\b.*\bseller|seller.*\b(risk|danger)/i.test(core)) return 'Verkoper gewaarschuwd voor de risico’s';
  if (/seizure|seized/i.test(core)) return 'Goederen in beslag genomen';
  if (/no answer|does not reply|not yet taken|not yet followed/i.test(core)) return 'Maatregel nog niet (volledig) genomen';
  // Onbekende vrije tekst: geef 'm terug zoals hij is (zeldzaam).
  return core.charAt(0).toUpperCase() + core.slice(1);
}

// --- Consumentenactie ("Wat moet je doen?") ---------------------------------
// Niet de markt-maatregel beschrijven, maar wat de BEZITTER moet doen. We
// classificeren de maatregel-actie (EN of NL) en kiezen de meest beschermende.

// Sterkste/meest-beschermende eerst.
const ACTION_PRIORITY = ['recall', 'repair', 'destruction', 'stop', 'removal', 'warning', 'import', 'admin'];

function classifyAction(text) {
  const t = norm(text);
  if (/recall|terugroep|terugg?eroep|retour|terug te brengen|terugbrengen|breng[^.]{0,30}terug|lever[^.]{0,30}in/.test(t)) return 'recall';
  if (/repair|repareren|reparatie|reparatieset|aanpassing|prior conditions|technical measures|modification|safety upgrade|spare part|installation of safety|safety device/.test(t)) return 'repair';
  if (/destruction|destroy|dispose|asbestos|vernietig|afvoeren|weggooien/.test(t)) return 'destruction';
  if (/withdrawal|withdraw|ban on the marketing|stop of sales|temporary ban|uit de handel|niet meer gebruiken|stop het gebruik|stop[^.]{0,12}gebruik|gebruik[^.]{0,40}niet|niet[^.]{0,15}gebruik|verkoopverbod|leveringsverbod/.test(t)) return 'stop';
  if (/removal of this product listing|aanbieding verwijderd/.test(t)) return 'removal';
  if (/warning|warn|marking the product|waarschuw|wees voorzichtig/.test(t)) return 'warning';
  if (/import rejected|grens geweigerd/.test(t)) return 'import';
  return 'admin';
}

const ACTION_TEXT = {
  recall: 'Stop met gebruik en breng het product terug voor terugbetaling, reparatie of vervanging — neem contact op met de winkel of fabrikant.',
  repair: 'Gebruik het product pas weer na reparatie of aanpassing. Neem contact op met de fabrikant voor de oplossing (bijvoorbeeld een reparatieset).',
  destruction: 'Gebruik het product niet meer en voer het veilig af volgens de instructies.',
  stop: 'Stop met het gebruik van dit product en neem contact op met de winkel of fabrikant over terugbetaling of vervanging.',
  removal: 'Stop met gebruik. Online gekocht? Neem contact op met de verkoper of het platform waar je het kocht.',
  warning: 'Wees voorzichtig bij gebruik en volg de veiligheidsinstructies; stop bij twijfel.',
  import: 'Dit product is aan de grens tegengehouden en hoort niet op de markt. Bezit je het al, stop dan met gebruik.',
  admin: 'Stop bij twijfel met gebruik en raadpleeg de officiële bron voor het juiste advies.',
};

// measures = array ruwe measure-strings (Safety Gate) of [vrije tekst] (NVWA).
export function consumerAction(measures, riskLabelText) {
  const cats = (measures || []).filter(Boolean).map((m) => {
    const am = String(m).match(/\(to:[^)]*\)\s*(.+)$/); // alleen het actie-deel (Safety Gate)
    return classifyAction(am ? am[1] : m);
  });
  let best = 'admin';
  for (const c of ACTION_PRIORITY) { if (cats.includes(c)) { best = c; break; } }
  if (best === 'warning' && riskLabelText) {
    return `Wees voorzichtig bij gebruik (risico: ${riskLabelText.toLowerCase()}). Volg de veiligheidsinstructies en stop bij twijfel.`;
  }
  return ACTION_TEXT[best];
}

// Hoofdfunctie: ruwe measure-string → NL. Valt terug op het origineel bij geen patroon.
export function translateMeasure(raw) {
  if (!raw) return null;
  const m = String(raw).match(/^Measures ordered by (.+?) \(to:\s*(.+?)\)\s*(.+)$/i);
  if (!m) return raw;
  const auth = AUTHORITIES[norm(m[1])] ?? m[1];
  const role = ROLES[norm(m[2])] ?? m[2];
  const action = translateAction(m[3]);
  return `${action}. (Maatregel door ${auth}, richting ${role}.)`;
}
