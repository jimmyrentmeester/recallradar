// B4 — Land-lookup. Safety Gate levert volledige landnamen (live geverifieerd);
// schema wil ISO-2 (meldend land). Raw blijft behouden voor weergave.

const NAME_TO_ISO2 = {
  'austria': 'AT', 'belgium': 'BE', 'bulgaria': 'BG', 'croatia': 'HR',
  'cyprus': 'CY', 'czechia': 'CZ', 'czech republic': 'CZ', 'denmark': 'DK',
  'estonia': 'EE', 'finland': 'FI', 'france': 'FR', 'germany': 'DE',
  'greece': 'GR', 'hungary': 'HU', 'iceland': 'IS', 'ireland': 'IE',
  'italy': 'IT', 'latvia': 'LV', 'lithuania': 'LT', 'luxembourg': 'LU',
  'malta': 'MT', 'netherlands': 'NL', 'the netherlands': 'NL', 'norway': 'NO',
  'poland': 'PL', 'portugal': 'PT', 'romania': 'RO', 'slovakia': 'SK',
  'slovenia': 'SI', 'spain': 'ES', 'sweden': 'SE',
  'united kingdom': 'GB',
  // Live geverifieerde bijzondere waarde in de RAPEX-data:
  'united kingdom in respect of northern ireland': 'GB',
};

export function mapCountry(name) {
  if (!name) return null;
  const key = String(name).toLowerCase().trim();
  return NAME_TO_ISO2[key] ?? (key.length === 2 ? key.toUpperCase() : null);
}
