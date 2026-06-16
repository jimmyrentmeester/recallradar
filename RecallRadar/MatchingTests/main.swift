//
//  MatchingTests/main.swift
//  RecallRadar
//
//  D3 — Headless unit-tests voor de pure MatchingService + Normalizer (geen Xcode/
//  simulator nodig). Draaien:
//    swiftc RecallRadar/Models/RecallAlert.swift RecallRadar/Models/RecallIndex.swift \
//           RecallRadar/Services/Normalizer.swift RecallRadar/Services/MatchingService.swift \
//           MatchingTests/main.swift -o /tmp/mtest && /tmp/mtest
//

import Foundation

// MARK: - mini test-harness
var failures = 0
func check(_ cond: Bool, _ name: String) {
    print((cond ? "[ok] " : "[FAIL] ") + name)
    if !cond { failures += 1 }
}
func eq<T: Equatable>(_ a: T, _ b: T, _ name: String) {
    check(a == b, "\(name) (\(a) == \(b))")
}

// MARK: - fixtures
let config = MatchingConfig(
    weights: .init(barcodeExact: 70, brandExact: 30, modelExact: 40, modelFuzzy: 20,
                   categoryEqual: 15, brandFuzzy: 15, batchInRange: 25,
                   penaltyCategoryMismatch: -15, penaltyModelMismatch: -20),
    thresholds: .init(high: 75, medium: 45, low: 20),
    brandAliases: ["v-tech": "vtech"]
)

func alert(brand: String?, model: String?, category: String, barcode: String? = nil, id: String = "a1") -> RecallAlert {
    RecallAlert(
        id: id, source: .safetyGate, alertNumber: id,
        brand: brand, brandRaw: brand, model: model, modelRaw: model,
        category: category, sourceCategory: nil, barcode: barcode, batchLot: nil,
        riskType: "letsel", riskDesc: nil, measure: "Stop gebruik.", country: "NL",
        imageURLString: nil, imageURLStrings: nil, sourceURLString: "https://x",
        publishedAt: Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date(timeIntervalSince1970: 1_700_000_000), ingestedAt: nil,
        mergedSources: nil, mergedSourceURLs: nil
    )
}
func product(brand: String? = nil, model: String? = nil, category: String = "overig", barcode: String? = nil,
             confirmed: Set<String> = [], suppressed: Set<String> = []) -> MatchableProduct {
    MatchableProduct(id: "p1", brand: brand, model: model, category: category, barcode: barcode,
                     confirmedAlertIDs: confirmed, suppressedAlertIDs: suppressed)
}

// MARK: - Normalizer
eq(Normalizer.text("Philips B.V."), "philips", "normalize merk-suffix")
eq(Normalizer.text("VTech GmbH"), "vtech", "normalize GmbH")
eq(Normalizer.model("HX-200"), "hx200", "normalize model scheidingsteken")
eq(Normalizer.barcode("036000291452"), "0036000291452", "UPC-12 → EAN-13")
check(Normalizer.barcode("1234567890123") == nil, "ongeldige checkdigit → nil")
check(Normalizer.jaroWinkler("samsng", "samsung") >= 0.9, "jaro-winkler bijna gelijk")

// MARK: - Scoring & tredes
// barcode exact alléén = 70 → MIDDEL (HOOG-drempel is 75; spec-getrouw).
let mBarcode = MatchingService.evaluate(
    product: product(barcode: "8710103997078"),
    alert: alert(brand: nil, model: nil, category: "witgoed_keuken", barcode: "8710103997078"),
    config: config)
eq(mBarcode.score, 70, "barcode exact = 70")
eq(mBarcode.tier, .medium, "barcode alléén → MIDDEL (70 < drempel 75)")

// realistische scan-flow: barcode + categorie (uit de index) = 85 → HOOG
let mScan = MatchingService.evaluate(
    product: product(category: "witgoed_keuken", barcode: "8710103997078"),
    alert: alert(brand: nil, model: nil, category: "witgoed_keuken", barcode: "8710103997078"),
    config: config)
eq(mScan.score, 85, "barcode + categorie = 85")
eq(mScan.tier, .high, "barcode + categorie → HOOG")

// merk + model exact + categorie gelijk → HOOG (85)
let mFull = MatchingService.evaluate(
    product: product(brand: "Philips", model: "HR-2520", category: "witgoed_keuken"),
    alert: alert(brand: "philips", model: "hr2520", category: "witgoed_keuken"),
    config: config)
eq(mFull.score, 85, "merk+model+cat = 85")
eq(mFull.tier, .high, "merk+model+cat → HOOG")

// merk exact + categorie gelijk, geen model → MIDDEL (45)
let mBrandCat = MatchingService.evaluate(
    product: product(brand: "Philips", category: "witgoed_keuken"),
    alert: alert(brand: "philips", model: "hr2520", category: "witgoed_keuken"),
    config: config)
eq(mBrandCat.score, 45, "merk+cat = 45")
eq(mBrandCat.tier, .medium, "merk+cat → MIDDEL")

// merk-alias (v-tech → vtech) + model fuzzy → telt
let mAlias = MatchingService.evaluate(
    product: product(brand: "V-Tech", model: "Baby Star", category: "kinderen_speelgoed"),
    alert: alert(brand: "vtech", model: "babystart", category: "kinderen_speelgoed"),
    config: config)
check(mAlias.score >= 45, "alias-merk + model fuzzy + cat ≥ 45 (was \(mAlias.score))")

// modelmismatch bij gelijk merk → penalty → LAAG
let mMismatch = MatchingService.evaluate(
    product: product(brand: "Philips", model: "ZZ999", category: "witgoed_keuken"),
    alert: alert(brand: "philips", model: "hr2520", category: "witgoed_keuken"),
    config: config)
eq(mMismatch.score, 25, "merk+cat-penalty: 30+15-20 = 25")
eq(mMismatch.tier, .low, "modelmismatch bij gelijk merk → LAAG")

// alleen categorie → te zwak (GEEN; feed loopt via follow-tak)
let mCatOnly = MatchingService.evaluate(
    product: product(category: "witgoed_keuken"),
    alert: alert(brand: "philips", model: "hr2520", category: "witgoed_keuken"),
    config: config)
eq(mCatOnly.tier, .none, "alleen categorie → GEEN")

// confirmed → HOOG (geforceerd); suppressed → GEEN (geforceerd)
let aConf = alert(brand: "philips", model: "hr2520", category: "witgoed_keuken", id: "ax")
eq(MatchingService.evaluate(product: product(brand: "Philips", confirmed: ["ax"]), alert: aConf, config: config).tier, .high, "confirmed → HOOG")
eq(MatchingService.evaluate(product: product(brand: "Philips", model: "HR-2520", category: "witgoed_keuken", suppressed: ["ax"]), alert: aConf, config: config).tier, .none, "suppressed → GEEN")

// match() filtert GEEN eruit en sorteert
let matches = MatchingService.match(
    products: [product(brand: "Philips", model: "HR-2520", category: "witgoed_keuken")],
    alerts: [alert(brand: "philips", model: "hr2520", category: "witgoed_keuken", id: "hit"),
             alert(brand: "sony", model: "xyz", category: "elektronica_smarthome", id: "miss")],
    config: config)
eq(matches.count, 1, "match() houdt alleen relevante over")
eq(matches.first?.alert.id, "hit", "match() vindt de juiste alert")

// follow-tak
let fBrand = MatchingService.followTier(for: alert(brand: "lego", model: nil, category: "kinderen_speelgoed"),
                                        brandFollows: ["lego"], categoryFollows: [])
eq(fBrand, .medium, "gevolgd merk → MIDDEL")
let fCat = MatchingService.followTier(for: alert(brand: "lego", model: nil, category: "kinderen_speelgoed"),
                                      brandFollows: [], categoryFollows: ["kinderen_speelgoed"])
eq(fCat, .low, "gevolgde categorie → LAAG (feed)")

print("\n\(failures == 0 ? "ALLES GROEN ✓" : "\(failures) FOUT(EN)")")
exit(failures == 0 ? 0 : 1)
