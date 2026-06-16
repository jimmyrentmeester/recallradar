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
