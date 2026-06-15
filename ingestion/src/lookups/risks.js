// B4 — Risico-lookup. Safety Gate alert_type -> interne risico-enum (Fase 2 tabblad Risico-waarden).
// Bronwaarden live geverifieerd uit de facets op 2026-06-15 (24-maands venster).

// interne code -> { label_nl, sources: [exacte alert_type-strings] }
export const RISK_GROUPS = {
  letsel: { label: 'Letsel', sources: ['Injuries', 'Abrasion'] },
  verstikking: { label: 'Verstikking', sources: ['Choking', 'Suffocation', 'Asphyxiation'] },
  chemisch: { label: 'Chemisch risico', sources: ['Chemical'] },
  brand_hitte: { label: 'Brand / hitte', sources: ['Fire', 'Burns', 'Smoke inhalation', 'Explosion'] },
  elektrisch: { label: 'Elektrische schok', sources: ['Electric shock', 'Electromagnetic disturbance'] },
  verdrinking: { label: 'Verdrinking', sources: ['Drowning'] },
  geluid: { label: 'Gehoorschade', sources: ['Hearing damage', 'Damage to hearing'] },
  microbiologisch: { label: 'Microbiologisch', sources: ['Microbiological'] },
  milieu: { label: 'Milieu', sources: ['Environment'] },
  beknelling: { label: 'Beknelling', sources: ['Strangulation', 'Entrapment'] },
  overig_risico: {
    label: 'Overig risico',
    sources: ['Other', 'Cuts', 'Damage to sight', 'Health risk / other', 'Health risk', 'Security'],
  },
};

// Genormaliseerde (lowercase) bronstring -> interne code.
const RISK_INDEX = (() => {
  const idx = new Map();
  for (const [code, { sources }] of Object.entries(RISK_GROUPS)) {
    for (const s of sources) idx.set(s.toLowerCase().trim(), code);
  }
  return idx;
})();

// alert_type kan een array zijn (live geverifieerd). Neem het eerste herkende risico.
export function mapRisk(alertType) {
  const arr = Array.isArray(alertType) ? alertType : [alertType];
  for (const raw of arr) {
    if (!raw) continue;
    const code = RISK_INDEX.get(String(raw).toLowerCase().trim());
    if (code) return code;
  }
  return 'overig_risico';
}

export function riskLabel(code) {
  return RISK_GROUPS[code]?.label ?? RISK_GROUPS.overig_risico.label;
}
