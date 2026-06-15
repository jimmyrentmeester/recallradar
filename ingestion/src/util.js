// Gedeelde normalisatie-helpers. Dezelfde normalisatie wordt op de app-zijde
// op geregistreerde producten toegepast (Fase 1 matching-logica §4), zodat
// alert-velden en productvelden vergelijkbaar zijn.

const LEGAL_SUFFIXES = [
  'b.v.', 'bv', 'n.v.', 'nv', 'gmbh', 'ltd', 'ltd.', 'llc', 'inc', 'inc.',
  's.r.l.', 'srl', 's.a.', 'sa', 'co.', 'co', 'kg', 'ag', 'oy', 'ab', 'as',
  'sp. z o.o.', 'spa', 's.p.a.',
];

// Lowercase, diacritics strippen, leestekens/dubbele spaties weg, juridische suffixen eraf.
export function normalizeText(input) {
  if (!input) return '';
  let s = String(input)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // diacritics
    .replace(/[^a-z0-9\s.&-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  // juridische suffixen verwijderen (woord-grens)
  for (const suf of LEGAL_SUFFIXES) {
    const re = new RegExp(`(^|\\s)${suf.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(\\s|$)`, 'g');
    s = s.replace(re, ' ');
  }
  return s.replace(/\s+/g, ' ').trim();
}

// Model: alfanumeriek normaliseren, scheidingstekens uniformeren ("HX-200" -> "hx200").
export function normalizeModel(input) {
  if (!input) return '';
  return String(input)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]/g, '')
    .trim();
}

// Barcode: alleen cijfers; EAN-13/UPC-12 valideren (checkdigit). UPC-12 -> EAN-13 (leidende nul).
export function normalizeBarcode(input) {
  if (!input) return null;
  let digits = String(input).replace(/\D/g, '');
  if (digits.length === 12) digits = '0' + digits; // UPC-A -> EAN-13
  if (digits.length === 8) {
    return isValidEan8(digits) ? digits : null;
  }
  if (digits.length !== 13) return null;
  return isValidEan13(digits) ? digits : null;
}

function isValidEan13(code) {
  const d = code.split('').map(Number);
  const sum = d.slice(0, 12).reduce((acc, n, i) => acc + n * (i % 2 === 0 ? 1 : 3), 0);
  const check = (10 - (sum % 10)) % 10;
  return check === d[12];
}

function isValidEan8(code) {
  const d = code.split('').map(Number);
  const sum = d.slice(0, 7).reduce((acc, n, i) => acc + n * (i % 2 === 0 ? 3 : 1), 0);
  const check = (10 - (sum % 10)) % 10;
  return check === d[7];
}

// Datum -> ISO-8601 (UTC). Geeft of een datum (YYYY-MM-DD) of volledige timestamp terug.
export function toISODate(input) {
  if (!input) return null;
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString().slice(0, 10);
}

export function toISODateTime(input) {
  if (!input) return null;
  const d = new Date(input);
  if (Number.isNaN(d.getTime())) return null;
  return d.toISOString();
}

// Veilige array: maakt van scalar/array/null altijd een schone string-array.
export function toArray(input) {
  if (input == null) return [];
  const arr = Array.isArray(input) ? input : [input];
  return arr.map((x) => String(x).trim()).filter(Boolean);
}

export function firstNonEmpty(...vals) {
  for (const v of vals) {
    if (v != null && String(v).trim() !== '') return v;
  }
  return null;
}
