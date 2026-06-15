# CLAUDE.md — Recall Radar

> Concept-versie, gegenereerd in Fase 3. Plaats dit in de root van de code-repo. Werk bij naarmate de bouw vordert.

## Wat dit is
iOS-app (SwiftUI, iOS 17+) die de gebruiker **alleen** waarschuwt als een product dat híj bezit (of een merk/categorie die hij volgt) wordt teruggeroepen. Solo-project, gebouwd met Claude Code/Xcode. Geen team, geen zware backend.

Beachhead v1: **non-food** consumentenproducten (EU Safety Gate + NVWA), NL-markt, met de **jonge-gezin**-categorie (speelgoed, kinderartikelen, autostoelen) als marketing-spits. Later: voedsel (RASFF).

## Architectuur
- **Ingestion** (`/ingestion`): GitHub Actions cron (1×/dag), Node 20. Haalt Safety Gate (OpenDataSoft, JSON, CC0) + NVWA (RSS, CC0) op, normaliseert naar één schema, publiceert een statische `index.json` op GitHub Pages. Geen server.
- **App** (`/RecallRadar`): downloadt de index, **matcht on-device**, plant lokale notificaties via BackgroundTasks. Producten in SwiftData (+ CloudKit voor delen, P1).

## Niet-onderhandelbare regels (guardrails)
- **Privacy-first:** de productlijst verlaat het toestel nooit (behalve de eigen iCloud van de gebruiker). Geen account voor de kern. Geen netwerkverzoek mag de productlijst bevatten.
- **On-device matching.** Geen server-side matching, geen bezit-upload.
- **Geen scrapen** van Productwaarschuwing.nl of andere aggregators; alleen primaire bronnen (Safety Gate, NVWA).
- **Informatief, niet uitputtend:** altijd disclaimer + doorverwijzing naar de officiële bron/fabrikant. Toon bronvermelding per recall.
- **Lean:** statische JSON + cron boven een echte server; heuristieken boven ML; APNs pas later (lokale notificaties volstaan voor v1).
- **Verifieer endpoints/feiten live**; ga niet uit van aannames.

## Belangrijke beslissingen (uit de Cowork-fasen)
- Primaire databron = **OpenDataSoft-mirror** (CC0, dagelijks vers, alle velden incl. barcode); officiële EC-XML = fallback.
- NVWA via **RSS** (CC0), niet scrapen.
- Matching-grondhouding = **gebalanceerd**: HOOG (≥75) → push, MIDDEL (45–74) → "is dit van jou?", LAAG (20–44) → alleen feed.
- Monetisatie = **eenmalige Pro-unlock** (P1), geen subscription in v1.
- Maandelijkse geruststelling-digest is **P0** (retentie-hook).

## Schema & taxonomie
Het genormaliseerde `RecallAlert`-schema, de bron-mapping en de 11-groepen categorie-taxonomie staan in `Fase2_…xlsx` + `Fase2_Schema-document`. De categorie-/risico-lookups zijn de bron van waarheid in `/ingestion`.

## Bouwvolgorde
Eerst `/ingestion` (tot een geldige gepubliceerde index), dan de app. Zie de v1-takenlijst in `Build-handoff_Recall-Radar.md`. Houd `docs/PROGRESS.md` bij voor continuïteit tussen sessies.

## PROGRESS bijhouden (verplicht)
- Werk `docs/PROGRESS.md` bij na elk afgerond takenblok én aan het einde van elke sessie (niet na elke reactie).
- Snelste manier: typ `/progress` (.claude/commands/progress.md).
- Stel dit ook ongevraagd voor zodra een blok af is of de sessie eindigt.

## Conventies
- Swift: SwiftUI + SwiftData, async/await, geen externe dependencies tenzij nodig.
- `MatchingService` is pure & unit-getest; UI hangt eraan, niet andersom.
- Datums in ISO-8601 (UTC) in de index.
- Commit-stijl: kort, imperatief; verwijs naar het takenblok (bv. "B5: dedup + index schrijven").
