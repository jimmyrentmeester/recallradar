# DESIGN.md — Recall Radar

> UI/UX-designdocument + SwiftUI-designrichtlijnen. Plaats dit in `docs/reference/` van de code-repo en laat Claude Code dit lezen vóór het bouwen van de views. Dit document vult het visuele/interactie-gat in het Fase 0–3-handoffpakket: het bepaalt *hoe* de app eruitziet en aanvoelt, terwijl `Build-handoff` en `Fase2_Schema-document` bepalen *wat* hij doet en *hoe* de data stroomt.
>
> **Bindend met:** `CLAUDE.md` (guardrails), `Fase1_PRD`, `Fase1_Matching-logica` (tredes HOOG/MIDDEL/LAAG), `Fase2_Schema-document` (RecallAlert-schema, 11 categorieën, risico-enum). Waar dit document een trede, categorie of veld noemt, is het schema uit Fase 2 leidend.
>
> Versie 1 · 16 juni 2026 · grondhouding: **rustig & geruststellend**.

---

## 0. Hoe Claude Code dit document gebruikt

1. Lees eerst §1 (principes) en §2 (designsysteem/tokens). Maak de tokens uit §2.6 één-op-één aan als een `DesignSystem`-enum in Swift vóór je een view bouwt. Geen hardcoded kleuren, fonts of spacing in views — alles verwijst naar tokens.
2. Bouw componenten (§3) als herbruikbare SwiftUI-views vóór schermen. Elk scherm (§4) is samengesteld uit deze componenten.
3. Houd je aan de toegankelijkheids- en microcopy-regels (§5, §6) bij elk scherm; dat zijn acceptatiecriteria, geen suggesties.
4. Volg de SwiftUI-conventies (§7) voor structuur en state.
5. Twijfel je over een visuele keuze? Kies de rustigste, meest standaard-iOS-optie en noteer de keuze in `docs/PROGRESS.md`. Stel mij een concrete keuze voor in plaats van een open vraag.

---

## 1. Designprincipes

Recall Radar is een veiligheidsapp die **bijna altijd stil is**. Dat is geen bug maar het kernkenmerk: de meeste dagen raakt geen enkele recall jouw spullen. Het hele ontwerp volgt daaruit.

**1. Rustig als standaard, alarm als uitzondering.**
De dagelijkse staat van de app is geruststellend, kalm en neutraal. Alarmkleur (rood/oranje) verschijnt **uitsluitend** bij een echte HOOG-match of een open recall-detail — nooit als decoratie, nooit in de navigatie, nooit in lege staten. Een gebruiker die de app opent zonder relevante recall moet zich gerustgesteld voelen, niet bang. Dit voorkomt "alarmmoeheid" en vals-paniekgevoel bij een product dat over veiligheid gaat.

**2. Vertrouwen verdien je met terughoudendheid.**
Eén onterechte paniek-push is een vertrouwensbreuk. De UI communiceert daarom altijd *zekerheid* (waarom denkt de app dat dit jouw product is?) en biedt altijd een uitweg ("Nee, niet van mij"). Confidence is zichtbaar, geen black box.

**3. Privacy is voelbaar, niet alleen waar.**
De belofte "jouw productlijst verlaat het toestel nooit" wordt actief getoond (privacy-uitleg bij onboarding, slotsymbool bij de productlijst, geen verplichte login). De gebruiker moet de privacy *zien*, niet alleen in de App Store-tekst lezen.

**4. Informatief, niet uitputtend.**
Elke recall toont bron + "laatst bijgewerkt" + disclaimer + een knop naar de officiële bron. De app presenteert zichzelf nooit als de absolute waarheid; ze verwijst door. Dit is een juridische én een vertrouwensregel.

**5. Nederlands, menselijk, niet bureaucratisch.**
Microcopy is warm en helder Nederlands (zie §6). Geen ambtelijke RAPEX-jargon in de UI; broncategorieën worden vertaald naar de 11 gebruiksvriendelijke groepen.

**6. Lean en native.**
Standaard-iOS-patronen (SF Symbols, systeemnavigatie, Dynamic Type) boven custom UI. Minder te bouwen, minder te onderhouden, beter toegankelijk, en het voelt direct vertrouwd. Custom design beperkt zich tot het merk-accent, de risk-pills en de cards.

**Anti-principes (expliciet niet doen):**
- Geen rode badges/teller op het app-icoon of de tabbar als er niets relevants is.
- Geen "engagement-tricks": geen streaks, geen nudges om vaker te openen, geen kunstmatige urgentie.
- Geen volledige RAPEX-historie of -ruis tonen; alleen wat relevant of browsebaar is.
- Geen donkere-patronen rond de Pro-unlock.

---

## 2. Designsysteem

### 2.1 Merkidentiteit

**Naam in UI:** "Recall Radar". **Toon:** kalme waakzaamheid — een radar die rustig draait, niet een alarm dat afgaat.

**Primaire merkkleur — Radar-blauw/teal.** Een rustig, vertrouwenwekkend blauw-groen (geen rood). Rood is gereserveerd voor risico; de merkkleur mág daarom nooit rood zijn. Blauw-teal straalt betrouwbaarheid en kalmte uit en laat de risicokleuren maximaal contrasteren wanneer ze wél verschijnen.

### 2.2 Kleurpalet

Alle kleuren als semantische tokens; concrete hex zijn de light-mode-basis. Definieer ze als **Color Assets** in de asset-catalog met een light- én dark-variant (§2.5), zodat de Swift-code alleen de tokennaam kent.

**Merk & neutraal (light mode):**

| Token | Hex (light) | Gebruik |
|---|---|---|
| `brandPrimary` | `#0E7C7B` | Radar-teal: accenten, primaire knoppen, actieve tab, links |
| `brandPrimaryMuted` | `#D7ECEC` | Zachte teal-achtergrond (geselecteerde chips, info-banner) |
| `bgPrimary` | `#FFFFFF` | Scherm-achtergrond |
| `bgSecondary` | `#F4F6F7` | Card-achtergrond, gegroepeerde lijst-achtergrond |
| `bgElevated` | `#FFFFFF` | Sheets, kaarten boven secundaire achtergrond |
| `separator` | `#E2E6E8` | Scheidingslijnen, card-randen |
| `textPrimary` | `#15201F` | Koppen, hoofdtekst |
| `textSecondary` | `#5B6B6A` | Bijschriften, metadata, "laatst bijgewerkt" |
| `textTertiary` | `#8A9897` | Placeholder, uitgeschakelde tekst |

**Risico-/statuskleuren (kleurenblind-veilig, zie §2.3):**

| Token | Hex (light) | Betekenis | Trede-koppeling |
|---|---|---|---|
| `riskHigh` | `#C2341D` | Ernstig risico / HOOG-match | HOOG (≥75) |
| `riskHighBg` | `#FBE7E2` | Achtergrond achter `riskHigh` |  |
| `riskMedium` | `#B8690A` | Verhoogd risico / "is dit van jou?" | MIDDEL (45–74) |
| `riskMediumBg` | `#FBEFD9` | Achtergrond achter `riskMedium` |  |
| `riskLow` | `#5B6B6A` | Laag / informatief / alleen-feed | LAAG (20–44) |
| `riskLowBg` | `#EDF0F1` | Achtergrond achter `riskLow` |  |
| `reassureGreen` | `#2E7D52` | Geruststelling: "niets geraakt" | digest, lege staat |
| `reassureGreenBg` | `#E2F1E8` | Achtergrond geruststelling |  |

> **Belangrijk:** `riskHigh` (rood) is een *terracotta*-rood, geen schreeuwend signaalrood — het past bij de rustige grondhouding en blijft toegankelijk op wit. `riskMedium` is een amber/oker, géén feloranje. Gebruik risicokleuren alleen voor de risk-pill, de detailheader-accentband en de bijbehorende HOOG-notificatie. **Nooit** voor randen van de hele card of voor de tabbar.

### 2.3 Kleurenblind-veiligheid & dubbele codering

Risico mag **nooit alleen via kleur** worden gecommuniceerd. Elke risk-pill combineert altijd drie signalen: **kleur + SF Symbol + tekstlabel**. Zo blijft de betekenis leesbaar voor kleurenblinde gebruikers en in grijswaarden.

| Trede | Kleur | Symbool (SF Symbol) | Label (NL) |
|---|---|---|---|
| HOOG | `riskHigh` | `exclamationmark.octagon.fill` | "Ernstig risico" |
| MIDDEL | `riskMedium` | `exclamationmark.triangle.fill` | "Mogelijk van jou" |
| LAAG | `riskLow` | `info.circle.fill` | "Ter info" |
| Geruststelling | `reassureGreen` | `checkmark.shield.fill` | "Niets geraakt" |

De gekozen hex-paren zijn getest op onderscheidbaarheid bij deuteranopie/protanopie (rood-terracotta vs. amber-oker vs. neutraal grijs verschillen in helderheid én vorm-symbool). Contrast: alle tekst-op-achtergrond-paren halen ≥ 4.5:1 (zie §5.3).

### 2.4 Typografie

**Lettertype: het systeemlettertype (SF Pro) via Dynamic Type.** Geen custom font — het schaalt automatisch mee met de toegankelijkheidsinstellingen van de gebruiker en is gratis, vertrouwd en perfect leesbaar in het Nederlands.

Gebruik de semantische `Font.TextStyle`-tokens, nooit vaste pt-groottes:

| Rol | TextStyle | Gewicht | Gebruik |
|---|---|---|---|
| Schermtitel | `.largeTitle` | `.bold` | Navigatie-grote titel (feed: "Meldingen") |
| Sectiekop | `.title2` | `.semibold` | Sectiekoppen in detail/instellingen |
| Card-titel | `.headline` | `.semibold` | Merk + product op een recall-card |
| Body | `.body` | `.regular` | Beschrijvingen, handelingsadvies |
| Bijschrift / meta | `.subheadline` / `.footnote` | `.regular` | "Laatst bijgewerkt", bron, datum |
| Pill-label | `.caption` | `.semibold` | Tekst in de risk-pill |
| Knoptekst | `.headline` | `.semibold` | Primaire knoppen |

**Regels:** ondersteun Dynamic Type tot en met de toegankelijkheids-XXXL-groottes (geen layout mag breken — gebruik `ViewThatFits`/wrapping i.p.v. afkappen op kritieke tekst). Beperk regellengte in body-tekst niet kunstmatig. Gebruik nooit meer dan twee gewichten op één scherm.

### 2.5 Dark mode

Volwaardig ondersteund vanaf v1 (verplicht). Definieer elke kleur als asset met een dark-variant. Uitgangspunten:

| Token | Hex (dark) |
|---|---|
| `bgPrimary` | `#0F1413` |
| `bgSecondary` | `#1A211F` |
| `bgElevated` | `#222A28` |
| `separator` | `#2C3633` |
| `textPrimary` | `#ECF1EF` |
| `textSecondary` | `#9FB0AE` |
| `brandPrimary` | `#3FB6B2` (iets opgehelderd voor contrast op donker) |
| `riskHigh` | `#F1715C` |
| `riskMedium` | `#E0A04A` |
| `reassureGreen` | `#5FBF8A` |
| risico-/reassure-`*Bg` | donkere, gedempte varianten (~12–16% opacity van de voorgrondkleur op `bgSecondary`) |

Risicokleuren worden in dark mode iets *lichter en minder verzadigd* zodat ze niet gloeien. Test elke risk-pill in beide modi op ≥ 4.5:1.

### 2.6 Spacing, radius, elevatie — designtokens

Een 4-punts grid. Definieer als Swift-constanten (zie §7.2).

| Token | Waarde | Gebruik |
|---|---|---|
| `space.xs` | 4 | Pill-padding, icoon-tekst-afstand |
| `space.sm` | 8 | Binnen-card-elementen |
| `space.md` | 12 | Standaard tussenruimte |
| `space.lg` | 16 | Scherm-marges (horizontaal), card-padding |
| `space.xl` | 24 | Sectie-afstand |
| `space.xxl` | 32 | Boven/onder grote koppen, lege-staat-spacing |
| `radius.sm` | 8 | Pills, kleine knoppen |
| `radius.md` | 12 | Cards, inputs |
| `radius.lg` | 20 | Sheets, grote panelen |
| `radius.full` | capsule | Risk-pills (gebruik `Capsule()`) |
| `elevation.card` | shadow y=1, blur=3, 6% zwart | Cards op `bgSecondary` (subtiel; in dark mode i.p.v. shadow een 1px `separator`-rand) |

**Iconografie:** uitsluitend **SF Symbols**, gewicht `.regular`/`.semibold`, gerenderd in `textSecondary` (neutraal) of de relevante semantische kleur. Geen custom icon-set in v1, behalve het app-icoon.

### 2.7 App-icoon (richting, niet definitief)

Een gestileerde **radarboog/-veeg** in `brandPrimary`-teal op een lichte achtergrond, met één klein accent-stipje (de "detectie") in `riskMedium`-amber — geen rood, geen uitroeptekens. Het icoon straalt "rustig bewaken" uit, niet "alarm". Lever later een 1024×1024 master; dark/tinted-varianten voor iOS 18 meenemen.

---

## 3. Componentenbibliotheek

Bouw elk component als zelfstandige, preview-bare SwiftUI-view die alleen tokens uit §2 gebruikt. Volgorde van bouwen: eerst deze, dan de schermen.

### 3.1 RiskPill

De belangrijkste merk-component. Combineert kleur + symbool + label (§2.3).

- Vorm: `Capsule()`, achtergrond `risk*Bg`, voorgrond `risk*`.
- Inhoud: SF Symbol + label-tekst (`.caption`, `.semibold`), padding `xs`/`sm`.
- Varianten: `.high`, `.medium`, `.low`, `.reassure`.
- Toegankelijkheid: `accessibilityLabel` = volledige zin ("Ernstig risico"), niet alleen de kleur.

### 3.2 RecallCard

De rij in de feed en in matchlijsten. Rustig, neutrale card — **geen** gekleurde rand om de hele card.

Layout (horizontaal): productfoto-thumbnail (links, `radius.md`, fallback = categorie-SF-Symbol op `bgSecondary`) · tekstkolom (merk + model als `.headline`; categorie + datum als `.footnote`/`textSecondary`) · rechts de `RiskPill` boven elkaar met een chevron. Card-achtergrond `bgSecondary`/`bgElevated`, `radius.md`, `elevation.card`.

Tik = open detail. Hele card is één `accessibilityElement` met samengestelde label.

### 3.3 Knoppen

| Variant | Stijl |
|---|---|
| Primair | Gevulde capsule, `brandPrimary`-achtergrond, witte tekst `.headline`. Eén per scherm. |
| Secundair | Omlijnd, `brandPrimary`-tekst + 1px `brandPrimary`-rand, transparante vulling. |
| Tertiair / tekst | Alleen tekst in `brandPrimary`. |
| Destructief | Tekst in `riskHigh` (bijv. "Verwijder product"). |
| Bron-knop | Secundair met `arrow.up.right.square`-symbool → opent officiële bron in Safari. |

Minimale raakdoel: 44×44 pt. Gebruik `.buttonStyle`-wrappers zodat stijl centraal zit.

### 3.4 Statusbanners

Smalle, niet-modale banner bovenaan een scherm. Varianten:
- **Info** (`brandPrimaryMuted`-bg): bijv. "Laatst bijgewerkt vandaag 06:00".
- **Offline/verouderd** (`riskLowBg`): "Geen verbinding — je ziet de laatst bekende lijst van [datum]." Nooit als alarm vormgeven.
- **Geruststelling** (`reassureGreenBg`): zie §4.7.

### 3.5 Lege, laad- en foutstaten

Drie expliciete, ontworpen staten per datascherm (verplicht acceptatiecriterium):

- **Leeg (geen producten):** vriendelijke illustratie/SF-Symbol, kop "Nog niets om te bewaken", body in rustige toon, primaire knop "Voeg je eerste product toe". Voelt uitnodigend, niet kaal.
- **Leeg-maar-goed (producten, geen matches):** dit is een *geruststellende* staat, niet een lege staat — gebruik `reassureGreen` + `checkmark.shield.fill` + "Geen van je 12 producten is teruggeroepen." Zie §4.7.
- **Laden:** skeleton-placeholders in `bgSecondary` (geen spinner-only als het even kan); `redacted(reason: .placeholder)`.
- **Fout/offline:** rustige melding + "Opnieuw proberen"-knop + toon de laatst gecachte data eronder. **Nooit** een fetch-fout als "geen recalls" presenteren (guardrail uit CLAUDE.md).

### 3.6 Confidence-uitleg ("Waarom zie ik dit?")

Klein, uitklapbaar blok in de recall-detail bij een match: toont in mensentaal welke signalen matchten ("Barcode komt overeen", "Merk komt overeen, model lijkt erop"). Maakt de matching-score transparant zonder het getal zelf te tonen. Essentieel voor principe 2.

### 3.7 Categorie-chip & filter

Horizontale, scrollbare rij capsule-chips met de 11 categorieën (Fase 2). Geselecteerd = `brandPrimaryMuted`-vulling + `brandPrimary`-tekst; niet-geselecteerd = omlijnd neutraal. Elk met een eigen SF Symbol (zie §4.2-tabel).

---

## 4. Schermen & navigatie

### 4.1 Navigatiestructuur

**TabView met drie tabs** (rustig, voorspelbaar, native):

1. **Meldingen** (`bell` / actief: gevuld) — de feed van relevante + browsebare recalls. Startscherm.
2. **Mijn spullen** (`shippingbox`) — productlijst + abonnementen + toevoegen.
3. **Instellingen** (`gearshape`) — notificaties, privacy, bron & disclaimer, Pro, over.

Geen badge-teller op tabs tenzij er een **onbevestigde HOOG/MIDDEL-match** wacht — dan een kleine punt (geen rood getal) op "Meldingen". Geruststellings-digests geven géén badge.

### 4.2 Onboarding (hoofdpad = abonneren, 0 friction)

Korte flow, max 3–4 schermen, overslaan-knop altijd zichtbaar:

1. **Welkom + privacybelofte.** Eén zin waarde ("Wij waarschuwen je alleen als jóuw spullen worden teruggeroepen") + zichtbare privacyregel ("Je productlijst blijft op je toestel"). Slot-symbool.
2. **Kies categorieën om te volgen.** Grid van de 11 categorie-chips met iconen. Spits visueel "Kinderen & speelgoed" bovenaan (primaire persona). Dit is het hoofdpad: geen product nodig, direct waarde.
3. **Notificatie-permissie — in context, met uitleg** ("Zo kunnen we je waarschuwen, ook als de app dicht is"). Vraag de systeempermissie pas ná deze uitleg.
4. **Klaar.** "Je radar staat aan." Verwijs subtiel naar "Voeg later je eigen producten toe voor preciezere waarschuwingen."

Categorie → SF Symbol mapping (richtlijn; 11 groepen uit Fase 2):

| Categorie | Symbool |
|---|---|
| Kinderen & speelgoed | `teddybear.fill` |
| Auto & vervoer | `car.fill` |
| Elektronica | `bolt.fill` |
| Huishoudelijke apparaten | `washer.fill` |
| Verlichting & elektra | `lightbulb.fill` |
| Cosmetica & verzorging | `drop.fill` |
| Kleding & textiel | `tshirt.fill` |
| Sport & vrije tijd | `figure.outdoor.cycle` |
| Gereedschap & doe-het-zelf | `wrench.and.screwdriver.fill` |
| Wonen & meubels | `sofa.fill` |
| Overig | `shippingbox.fill` |

> Stem de exacte labels af op de definitieve 11 groepen in `Fase2_…xlsx`; pas symbolen daarop aan.

### 4.3 Feed — "Meldingen"

Grote titel "Meldingen". Bovenaan een subtiele "laatst bijgewerkt"-info-banner (§3.4). Daaronder de categorie-filterrij (§3.7). Daarna een lijst van `RecallCard`s.

Volgorde/secties:
- **Bovenaan, indien aanwezig: "Voor jou".** Recalls die matchen met jouw producten/abonnementen, gesorteerd op trede (HOOG eerst) en datum. Onbevestigde MIDDEL-matches tonen een "Is dit van jou?"-actie inline.
- **Daaronder: "Bladeren".** Recente recalls binnen je gevolgde categorieën (browsebaar, niet gematcht), neutraal weergegeven.

Als er geen "Voor jou"-items zijn: toon de geruststellingsbanner (§4.7) bovenaan, niet een lege staat. Pull-to-refresh = handmatige index-check (toont nieuwe "laatst bijgewerkt").

### 4.4 Recall-detail

Het enige scherm waar risicokleur prominent mag zijn — en alleen in een **accentband bovenaan**, niet over het hele scherm.

Van boven naar beneden:
1. **Accent-header:** dunne gekleurde band/achtergrond in `risk*Bg` met de `RiskPill` en de risico-omschrijving (`riskDesc`) in mensentaal.
2. **Productfoto('s):** `imageURL`/`imageURLs`, swipebaar; fallback = categorie-symbool.
3. **Kerngegevens:** merk (`brandRaw`), model (`modelRaw`), categorie (NL-groep), batch/lot indien aanwezig, barcode indien aanwezig.
4. **Wat moet je doen:** `measure` (genomen maatregel) vertaald naar helder handelingsadvies ("Stop met gebruiken en breng terug naar de winkel").
5. **Confidence-uitleg** (§3.6) — alleen bij een match.
6. **"Is dit van jou?"-bevestiging** (bij MIDDEL/onbevestigd) — twee knoppen: "Ja, dit is van mij" / "Nee, niet van mij". Slaat op in `confirmedMatches`/`suppressedMatches`.
7. **Bron & disclaimer (verplicht):** "Bron: EU Safety Gate / NVWA" + `generated_at` + knop "Bekijk officiële melding" (`sourceURL`, opent in Safari) + de vaste disclaimer (§6.4).

### 4.5 Mijn spullen + product toevoegen

**Mijn spullen:** twee secties — "Producten" (concrete items) en "Gevolgde categorieën/merken" (abonnementen). Slot-symbool + één regel "Deze lijst blijft op je toestel" bovenaan (privacy voelbaar). Lege staat zie §3.5. Per item: swipe-to-delete, tik = bewerken.

**Toevoegen (`+`):** action sheet met drie paden, in volgorde van drempel:
1. **Scan barcode** — VisionKit `DataScannerViewController` in een sheet. Live camera, vang EAN-13/UPC, valideer checkdigit, en als de index de barcode kent: vul merk/categorie voor en toon meteen of er een recall op staat. Camera-permissie met uitleg vóór de systeemvraag.
2. **Handmatig** — merk + model + categorie, met autocomplete uit de merk-/categorielijsten in de index.
3. **Categorie/merk volgen** — terug naar de chip-keuze uit onboarding.

Scan-scherm-UX: rustige overlay, duidelijk richtkader, haptische tik bij succesvolle scan, directe terugkoppeling ("Gevonden: [merk] — geen recall bekend" of een match-card).

### 4.6 Instellingen

Gegroepeerde lijst (`InsetGroupedListStyle`):
- **Notificaties:** per trede aan/uit (HOOG altijd aan, niet uitschakelbaar; MIDDEL aan/uit; "Bladeren"-meldingen uit als standaard), rustige uren, maandelijkse digest aan/uit.
- **Privacy:** uitleg + link naar privacy-tekst; "Je gegevens verlaten je toestel niet".
- **Bronnen & disclaimer:** uitleg over Safety Gate + NVWA, CC0-bronvermelding, volledige disclaimer.
- **Recall Radar Pro** (P1): eenmalige unlock; nette uitleg van wat het toevoegt (instant-alerts, OCR, gezin-delen). Geen donkere patronen.
- **Over / versie / "laatst bijgewerkt".**

### 4.7 Maandelijkse geruststelling-digest (P0 — retentie-hook)

De belangrijkste "stille" interactie. Twee vormen:

1. **Lokale notificatie** (maandelijks, ook bij nul matches): rustige toon, `reassureGreen`-gevoel, bijv. "Deze maand raakte geen enkele recall jouw 12 producten." Bij wél matches: samenvatting i.p.v. geruststelling.
2. **In-app geruststellingsbanner/-staat:** wanneer de feed geen "Voor jou"-items heeft, toont "Meldingen" bovenaan een `reassureGreen`-banner met `checkmark.shield.fill`: "Je 12 producten en 4 gevolgde categorieën: niets teruggeroepen. Laatst gecontroleerd: [datum]." Dit maakt de stilte tot een positief signaal in plaats van een leeg scherm.

Toon nooit een nep-getal; tel echte producten + abonnementen. Bij 0 producten: "Voeg je spullen toe zodat we ze kunnen bewaken" (zachte nudge, geen alarm).

---

## 5. Toegankelijkheid (acceptatiecriteria, niet optioneel)

### 5.1 Dynamic Type
Alle tekst via `Font.TextStyle`. Layouts moeten werken t/m AX5 (XXXL). Test elk scherm op de grootste stap: niets mag afkappen of overlappen op kritieke informatie (merk, risico, handelingsadvies). Gebruik `ScrollView`/`ViewThatFits` waar nodig.

### 5.2 VoiceOver
- Elke `RecallCard` is één element met samengestelde label: "[merk] [model], [categorie], [risico-trede], [datum]".
- `RiskPill` heeft een tekst-`accessibilityLabel` (de volledige zin), niet "rood".
- Knoppen hebben duidelijke labels + `accessibilityHint` waar de actie niet vanzelfsprekend is ("Opent de officiële melding in Safari").
- Bevestigingsknoppen ("Ja, van mij"/"Nee") expliciet gelabeld.

### 5.3 Contrast & kleur
- Alle tekst/achtergrond ≥ 4.5:1 (normale tekst), ≥ 3:1 (grote tekst), in light én dark. De §2-paren zijn hierop gekozen; verifieer na implementatie.
- **Nooit kleur als enige informatiedrager** — altijd symbool + tekst erbij (§2.3).
- Respecteer "Verminder beweging" (geen niet-essentiële animaties) en "Verhoog contrast".

### 5.4 Raakdoelen & haptiek
Minimaal 44×44 pt. Haptische feedback alleen functioneel (scan-succes, bevestiging), nooit decoratief.

---

## 6. Tone-of-voice & microcopy (Nederlands)

### 6.1 Grondtoon
Warm, helder, geruststellend, volwassen. Je-vorm. Korte zinnen. Nooit bang makend, nooit ambtelijk, nooit jolig. De app is een kalme conciërge, geen alarmbel.

### 6.2 Do / don't
- **Wel:** "Geen van je producten is teruggeroepen." · "Dit lijkt op een product van jou — klopt dat?" · "Stop met gebruiken en breng terug naar de winkel."
- **Niet:** "GEVAAR!", "Waarschuwing!!!", "RAPEX-melding nr. A12/0345/26", "U dient onverwijld...".

### 6.3 Risico-/trede-copy (vast)
| Trede | Pill-label | Push-opening |
|---|---|---|
| HOOG | "Ernstig risico" | "Een product dat je volgt is teruggeroepen" |
| MIDDEL | "Mogelijk van jou" | "Een recall lijkt op een van je producten" |
| LAAG | "Ter info" | (geen push; alleen feed) |
| Digest | "Niets geraakt" | "Deze maand raakte geen recall jouw spullen" |

### 6.4 Vaste disclaimer (verplicht, overal waar recalls getoond worden)
> "Deze informatie is afkomstig van EU Safety Gate en de NVWA en wordt dagelijks bijgewerkt. Recall Radar is informatief en niet uitputtend — raadpleeg altijd de officiële melding en de fabrikant voordat je handelt."

Toon bron + "laatst bijgewerkt: [datum/tijd]" bij elke recall en in instellingen.

### 6.5 Lege/fout-copy
- Geen producten: "Nog niets om te bewaken. Voeg een product of categorie toe en wij houden het voor je in de gaten."
- Offline: "Geen verbinding. Je ziet de laatst bekende lijst van [datum]." (nooit "geen recalls")
- Fout bij verversen: "Verversen lukte even niet. Probeer het zo opnieuw."

---

## 7. SwiftUI-implementatierichtlijnen

> Vult `CLAUDE.md` §Conventies aan met design-specifieke regels. Geen externe UI-dependencies.

### 7.1 Mappenstructuur (binnen `RecallRadar/`)
```
RecallRadar/
  App/                  # App-entry, TabView-root
  DesignSystem/         # Color-/Font-/Spacing-tokens, ViewModifiers
  Components/           # RiskPill, RecallCard, knoppen, banners, states
  Features/
    Feed/               # Meldingen-tab (views + viewmodel)
    Detail/             # RecallDetail
    MyStuff/            # Mijn spullen, toevoegen, scan
    Onboarding/
    Settings/
  Models/               # Codable RecallAlert, SwiftData TrackedProduct/Subscription
  Services/             # IndexService (download/cache), MatchingService, NotificationService
  Resources/            # Assets.xcassets (kleur-assets, app-icoon)
```

### 7.2 Designtokens in code
Centraliseer alles. Voorbeeld-skelet (Claude Code werkt dit uit):
```swift
enum DS {
    enum Color {
        static let brandPrimary = SwiftUI.Color("brandPrimary")   // uit asset-catalog (light+dark)
        static let bgSecondary  = SwiftUI.Color("bgSecondary")
        static let riskHigh     = SwiftUI.Color("riskHigh")
        // ... alle tokens uit §2.2 / §2.5
    }
    enum Space { static let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 12,
                        lg: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32 }
    enum Radius { static let sm: CGFloat = 8, md: CGFloat = 12, lg: CGFloat = 20 }
}
```
Kleuren **altijd** als named Color-assets met light/dark-variant — nooit `Color(red:green:blue:)` in een view. Spacing/radius via `DS.Space`/`DS.Radius`. Tekst via `.font(.headline)` enz., nooit `.system(size:)`.

### 7.3 Risk-mapping op één plek
De koppeling trede → kleur/symbool/label staat in één `RiskPresentation`-enum (afgeleid van de matching-trede uit Fase 1), zodat UI en notificaties dezelfde bron gebruiken. `MatchingService` levert de trede; de UI-laag mapt naar presentatie. Houd matching pure/getest (CLAUDE.md), presentatie apart.

### 7.4 Componenten eerst, previews verplicht
Elk component in `Components/` krijgt een `#Preview` met alle varianten (alle tredes, light+dark, en een grote Dynamic-Type-stap). Dat is je visuele regressietest zonder backend.

### 7.5 State & data
- Feed/detail via `@Observable` viewmodels (iOS 17). Geen netwerk in views.
- `IndexService` doet download (If-None-Match/ETag), cache in `Caches/`, en levert `[RecallAlert]`. Views kennen de bron niet.
- SwiftData voor `TrackedProduct`/`Subscription` (CloudKit-mirroring aan). De index nooit in de SwiftData-store of iCloud (publieke, herbruikbare data → `Caches/`).
- Respecteer de privacy-guardrail in de UI-laag: geen view of analytics-call mag productdata naar buiten sturen.

### 7.6 Notificatie-presentatie
`NotificationService` bouwt `UNNotificationContent` met de copy uit §6.3 en de trede-mapping uit §7.3. Bundel meerdere matches; geen nacht-pushes (rustige uren, instelbaar); HOOG = niet onderdrukbaar. Maandelijkse digest als geplande lokale notificatie (ook bij nul matches).

### 7.7 Don'ts (hard)
- Geen hardcoded hex/pt/fontgrootte in views.
- Geen risicokleur als card-rand of in tabbar/navigatie.
- Geen rood badge-getal op app-icoon/tabs.
- Geen blokkerende spinner-only schermen — gebruik skeletons + gecachte data.
- Geen tekst die alleen via kleur betekenis draagt.

---

## 8. Definition of Done per scherm

Een scherm is "af" als: het uitsluitend tokens uit §2 gebruikt; het de drie states (leeg/laden/fout) heeft; het werkt in light + dark; het leesbaar is t/m Dynamic Type AX5; VoiceOver de kerninfo correct voorleest; risico nooit alleen via kleur wordt getoond; en — waar recalls verschijnen — bron, "laatst bijgewerkt" en disclaimer aanwezig zijn. Noteer afwijkingen in `docs/PROGRESS.md`.

---

## Bronnen / samenhang
- Guardrails & beslissingen: `CLAUDE.md`
- Tredes & confidence: `Fase1_Matching-logica_Recall-Radar.docx`
- Scope, persona, prioriteiten: `Fase1_PRD_Recall-Radar.docx`
- Schema, 11 categorieën, risico-enum, bron-mapping: `Fase2_Schema-document_Recall-Radar.md` + `Fase2_Databron-matrix_alert-schema_taxonomie.xlsx`
- Architectuur, takenlijst A–F: `Build-handoff_Recall-Radar.md`
