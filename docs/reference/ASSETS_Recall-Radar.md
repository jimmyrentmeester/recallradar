# ASSETS.md — Recall Radar — Icoon- & asset-brief

> Praktische bouwbrief voor het app-icoon en de asset-catalog. Hoort bij `DESIGN_Recall-Radar.md` (de hex-tokens komen uit §2.2/§2.5 daar). Plaats in `docs/reference/`. Doel: Claude Code/Xcode kan hiermee `Assets.xcassets` correct vullen, en jij (of een designer) kan het icoon afmaken zonder raden.
>
> Versie 1 · 16 juni 2026.

---

## Deel A — App-icoon

### A.1 Concept
Een gestileerde **radarveeg** (kwart- of halve boog met een korte "sweep"-staart) in radar-teal op een lichte achtergrond, met één klein detectie-stipje in amber. Rustig bewaken, geen alarm. **Geen rood, geen uitroepteken, geen schild-met-kruis** — dat zou de "alarm als uitzondering"-grondhouding tegenspreken.

### A.2 Vaste regels
- **Vorm:** vul het volledige 1024×1024-vlak; iOS maakt zelf de afgeronde hoeken (lever een vierkant, geen voor-afgeronde of transparante hoeken).
- **Achtergrond:** effen of zeer subtiele verticale gradient van `#0E7C7B` → `#0B6463` (donkerder teal). Geen foto, geen ruis, geen tekst in het icoon.
- **Hoofdmotief:** de radarboog in licht (`#EAF6F5`/wit), gecentreerd, optisch iets naar boven. Eén detectie-stip in amber `#E0A04A`.
- **Geen tekst** in het icoon (naam staat al onder het icoon in iOS).
- **Veilige marge:** houd het motief binnen ~80% van het vlak; iOS-masker en eventuele vergroting knippen de randen.

### A.3 Te leveren varianten (iOS 18 "single size"-flow)
Lever een **1024×1024 master**; Xcode genereert de overige maten. Voor iOS 18 lever je drie appearances in de App Icon-asset:

| Appearance | Achtergrond | Motief | Opmerking |
|---|---|---|---|
| **Any (light)** | teal-gradient | licht motief + amber stip | standaard |
| **Dark** | donkerder teal `#0B3E3D` of near-black `#0F1413` | iets lichter teal-motief, amber stip behouden | mag minder verzadigd |
| **Tinted (mono)** | grijswaarden, systeem tint erover | motief als één-kleurs silhouet, **geen** amber (tinted is monochroom) | zorg dat de radarboog herkenbaar blijft puur op vorm |

### A.4 Bestandsformaat
- Master: 1024×1024 PNG, **geen alpha/transparantie** voor de light/dark-achtergrondvarianten, sRGB.
- Geen afgeronde hoeken, geen schaduw zelf inbakken.
- Voeg toe in Xcode onder `Assets.xcassets/AppIcon` met de drie appearances ingevuld.

### A.5 Snelle weg zonder designer
1. Maak het motief als simpele SVG (boog + stip) — goed te genereren/aan te passen.
2. Exporteer 1024px PNG per appearance.
3. Sleep in Xcode's AppIcon-slot. Dit kan ik desgewenst als kant-en-klare SVG voor je uittekenen — vraag erom.

---

## Deel B — Color-assets (`Assets.xcassets`)

Maak voor **elke** token hieronder een Color Set met een **Any (light)**- en **Dark**-variant. De Swift-code verwijst alleen naar de naam (`Color("brandPrimary")`). Zo hoeft een kleurtweak nooit in code.

### B.1 Merk & neutraal

| Asset-naam | Light hex | Dark hex |
|---|---|---|
| `brandPrimary` | `#0E7C7B` | `#3FB6B2` |
| `brandPrimaryMuted` | `#D7ECEC` | `#16302F` |
| `bgPrimary` | `#FFFFFF` | `#0F1413` |
| `bgSecondary` | `#F4F6F7` | `#1A211F` |
| `bgElevated` | `#FFFFFF` | `#222A28` |
| `separator` | `#E2E6E8` | `#2C3633` |
| `textPrimary` | `#15201F` | `#ECF1EF` |
| `textSecondary` | `#5B6B6A` | `#9FB0AE` |
| `textTertiary` | `#8A9897` | `#6F807E` |

### B.2 Risico & status

| Asset-naam | Light hex | Dark hex |
|---|---|---|
| `riskHigh` | `#C2341D` | `#F1715C` |
| `riskHighBg` | `#FBE7E2` | `#3A1E18` |
| `riskMedium` | `#9E5A08` | `#E0A04A` |
| `riskMediumBg` | `#FBEFD9` | `#332617` |
| `riskLow` | `#5B6B6A` | `#9FB0AE` |
| `riskLowBg` | `#EDF0F1` | `#222A28` |
| `reassureGreen` | `#2C784E` | `#5FBF8A` |
| `reassureGreenBg` | `#E2F1E8` | `#16301F` |

> Zet in elke Color Set "Appearances" op **Any, Dark** en vink **sRGB** aan. De `*Bg`-darkwaarden zijn bewust diep en gedempt zodat ze niet gloeien op `bgPrimary` (`#0F1413`).

---

## Deel C — Contrast-verificatie (verplichte check)

Na het vullen van de assets: controleer elk tekst-op-achtergrond-paar. Drempel: **≥ 4.5:1** voor normale tekst, **≥ 3:1** voor grote tekst (≥ `.title2`). Te checken paren, minimaal:

| Voorgrond | Achtergrond | Verwacht | Modus |
|---|---|---|---|
| `textPrimary` | `bgPrimary` | ~15:1 | light + dark |
| `textSecondary` | `bgPrimary` | ≥ 4.5:1 | light + dark |
| `textSecondary` | `bgSecondary` | ≥ 4.5:1 | light + dark |
| `riskHigh` | `riskHighBg` | ≥ 4.5:1 | light + dark |
| `riskMedium` | `riskMediumBg` | ≥ 4.5:1 | light + dark |
| `riskLow` | `riskLowBg` | ≥ 4.5:1 | light + dark |
| `reassureGreen` | `reassureGreenBg` | ≥ 4.5:1 | light + dark |
| wit | `brandPrimary` (primaire knop) | ≥ 4.5:1 | light + dark |

**Hoe checken (kies één):**
- Xcode/Figma + een WCAG-contrastplugin, of
- de macOS-tool "Color Contrast Calculator" (Accessibility Inspector), of
- een klein script (WCAG-formule). Vraag me gerust om een kort Swift/Python-snippet dat de hele tabel in één keer narekent.

**Als een paar zakt onder de drempel:** maak de voorgrondkleur donkerder (light) of lichter (dark) in stappen van ~5% luminantie tot het haalt — pas alleen de voorgrond aan, niet de semantiek. Noteer de definitieve hex terug in `DESIGN_Recall-Radar.md` §2.2/§2.5 zodat dat de bron van waarheid blijft.

---

## Deel D — SF Symbols (geen asset-import nodig)

Iconen komen uit het systeem (SF Symbols), dus niets te bundelen. Gebruikte symbolen staan in `DESIGN_Recall-Radar.md`: risk-pills (§2.3), categorieën (§4.2), tabs (§4.1). Controleer beschikbaarheid op iOS 17 in de SF Symbols-app; kies bij twijfel een dichtstbijzijnd alternatief en noteer het in `PROGRESS.md`.

---

## Definition of Done (assets)
- [ ] `Assets.xcassets` bevat alle Color Sets uit Deel B, elk met light + dark.
- [ ] App-icoon ingevuld met Any/Dark/Tinted appearances; geen transparante hoeken; vierkante 1024px master.
- [ ] Contrast-tabel (Deel C) volledig ≥ drempel in light én dark; afwijkingen teruggeschreven naar DESIGN §2.
- [ ] Geen hardcoded hex meer in views (alles via `Color("…")`).
