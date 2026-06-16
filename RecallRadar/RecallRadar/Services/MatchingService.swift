//
//  MatchingService.swift
//  RecallRadar
//
//  D3 — De moat: bepaalt of een recall een gebruiker raakt en hoe stellig
//  (Fase 1 matching-logica). Volledig puur & nonisolated → headless unit-testbaar;
//  de UI hangt hieraan, niet andersom. Gewichten/drempels komen uit de
//  MatchingConfig die in de index meereist (bijstelbaar zonder app-update).
//

import Foundation

nonisolated enum MatchTier: Int, Comparable, Sendable {
    case none = 0   // < 20  → niet tonen aan deze gebruiker
    case low        // 20–44 → alleen feed ("mogelijk relevant")
    case medium     // 45–74 → zachte "is dit van jou?"
    case high       // ≥ 75  → directe push

    static func < (l: MatchTier, r: MatchTier) -> Bool { l.rawValue < r.rawValue }
}

/// Pure input voor matching (losgekoppeld van SwiftData/TrackedProduct).
nonisolated struct MatchableProduct: Sendable {
    let id: String
    let brand: String?
    let model: String?
    let category: String
    let barcode: String?
    var confirmedAlertIDs: Set<String> = []
    var suppressedAlertIDs: Set<String> = []
}

nonisolated struct ProductMatch: Identifiable, Sendable {
    let productID: String
    let alert: RecallAlert
    let score: Int
    let tier: MatchTier
    let forced: Bool   // tier afgedwongen door eerdere bevestiging
    var id: String { "\(productID)|\(alert.id)" }
}

nonisolated enum MatchingService {

    // MARK: - Score (Fase 1 §5)

    static func score(product: MatchableProduct, alert: RecallAlert, config: MatchingConfig) -> Int {
        let w = config.weights
        var s = 0

        let pBarcode = Normalizer.barcode(product.barcode)
        let pBrand = canonicalBrand(Normalizer.text(product.brand), config: config)
        let aBrand = canonicalBrand(alert.brand ?? "", config: config)
        let pModel = Normalizer.model(product.model)
        let aModel = alert.model ?? ""

        // Barcode — sterkste signaal.
        if let pBarcode, let aBarcode = alert.barcode, pBarcode == aBarcode {
            s += w.barcodeExact
        }

        // Merk (exact of fuzzy/alias).
        var brandMatched = false
        if !pBrand.isEmpty, !aBrand.isEmpty {
            if pBrand == aBrand {
                s += w.brandExact; brandMatched = true
            } else if Normalizer.jaroWinkler(pBrand, aBrand) >= 0.9 {
                s += w.brandFuzzy; brandMatched = true
            }
        }

        // Model (exact of fuzzy).
        var modelMatched = false
        var modelMismatch = false
        if !pModel.isEmpty, !aModel.isEmpty {
            if pModel == aModel {
                s += w.modelExact; modelMatched = true
            } else if Normalizer.jaroWinkler(pModel, aModel) >= 0.85 {
                s += w.modelFuzzy; modelMatched = true
            } else {
                modelMismatch = true
            }
        }

        // Categorie (ondersteunend).
        let categoryEqual = product.category == alert.category
        if categoryEqual { s += w.categoryEqual }

        // Tegensignalen — alleen bij gelijk merk (voorkomt dat "merk klopt" alleen pusht).
        if brandMatched {
            if !categoryEqual { s += w.penaltyCategoryMismatch }
            if modelMismatch && !modelMatched { s += w.penaltyModelMismatch }
        }

        return min(max(s, 0), 100)
    }

    /// Mensentaal-uitleg welke signalen matchten ("Waarom zie ik dit?", §3.6) — transparant
    /// zonder het scoregetal te tonen.
    static func matchedSignals(product: MatchableProduct, alert: RecallAlert, config: MatchingConfig) -> [String] {
        var out: [String] = []
        if let pb = Normalizer.barcode(product.barcode), let ab = alert.barcode, pb == ab {
            out.append("Barcode komt overeen")
        }
        let pBrand = canonicalBrand(Normalizer.text(product.brand), config: config)
        let aBrand = canonicalBrand(alert.brand ?? "", config: config)
        if !pBrand.isEmpty, !aBrand.isEmpty {
            if pBrand == aBrand { out.append("Merk komt overeen") }
            else if Normalizer.jaroWinkler(pBrand, aBrand) >= 0.9 { out.append("Merk lijkt erop") }
        }
        let pModel = Normalizer.model(product.model)
        let aModel = alert.model ?? ""
        if !pModel.isEmpty, !aModel.isEmpty {
            if pModel == aModel { out.append("Model komt overeen") }
            else if Normalizer.jaroWinkler(pModel, aModel) >= 0.85 { out.append("Model lijkt erop") }
        }
        if product.category == alert.category { out.append("Categorie komt overeen") }
        return out
    }

    // MARK: - Trede (Fase 1 §6)

    static func tier(for score: Int, thresholds: MatchingConfig.Thresholds) -> MatchTier {
        if score >= thresholds.high { return .high }
        if score >= thresholds.medium { return .medium }
        if score >= thresholds.low { return .low }
        return .none
    }

    /// Score + trede met feedback-loop: bevestigd → HOOG, onderdrukt → GEEN (§7).
    static func evaluate(product: MatchableProduct, alert: RecallAlert, config: MatchingConfig) -> ProductMatch {
        if product.suppressedAlertIDs.contains(alert.id) {
            return ProductMatch(productID: product.id, alert: alert, score: 0, tier: .none, forced: true)
        }
        if product.confirmedAlertIDs.contains(alert.id) {
            return ProductMatch(productID: product.id, alert: alert, score: 100, tier: .high, forced: true)
        }
        let sc = score(product: product, alert: alert, config: config)
        return ProductMatch(productID: product.id, alert: alert, score: sc, tier: tier(for: sc, thresholds: config.thresholds), forced: false)
    }

    /// Matcht een set (nieuwe) alerts tegen het bezit. Retourneert relevante matches
    /// (trede ≥ LAAG), nieuwste eerst.
    static func match(products: [MatchableProduct], alerts: [RecallAlert], config: MatchingConfig) -> [ProductMatch] {
        var out: [ProductMatch] = []
        for product in products {
            for alert in alerts {
                let m = evaluate(product: product, alert: alert, config: config)
                if m.tier > .none { out.append(m) }
            }
        }
        return out.sorted {
            if $0.tier != $1.tier { return $0.tier > $1.tier }
            return $0.alert.publishedAt > $1.alert.publishedAt
        }
    }

    /// Ernstig gevaar? (voor "alleen ernstige"-pushes en de globale opt-in.)
    static let seriousRisks: Set<String> = ["verstikking", "brand_hitte", "elektrisch", "beknelling", "verdrinking", "chemisch"]
    static func isSerious(_ alert: RecallAlert) -> Bool { seriousRisks.contains(alert.riskType) }

    // MARK: - Merk/categorie-abonnementen (aparte tak, §6)

    /// brandFollows = genormaliseerde merknamen; categoryFollows = interne categoriecodes.
    static func followTier(for alert: RecallAlert, brandFollows: Set<String>, categoryFollows: Set<String>) -> MatchTier {
        if let aBrand = alert.brand, !aBrand.isEmpty, brandFollows.contains(aBrand) {
            return .medium // gevolgd merk → zachte melding
        }
        if categoryFollows.contains(alert.category) {
            return .low // gevolgde categorie → feed (push alleen als de follow dat aanzet, Blok E)
        }
        return .none
    }

    // MARK: - Hulp

    private static func canonicalBrand(_ normalized: String, config: MatchingConfig) -> String {
        config.brandAliases[normalized] ?? normalized
    }
}
