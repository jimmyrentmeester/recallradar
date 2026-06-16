//
//  MatchBridge.swift
//  RecallRadar
//
//  D1/D2/D4 — Brug tussen SwiftData (TrackedProduct/Subscription, main-actor) en de
//  pure MatchingService (value-types). Houdt de MatchingService vrij van SwiftData.
//

import Foundation

@MainActor
extension TrackedProduct {
    func matchable() -> MatchableProduct {
        MatchableProduct(
            id: id.uuidString,
            brand: brand,
            model: model,
            category: category,
            barcode: barcode,
            confirmedAlertIDs: Set(confirmedMatches),
            suppressedAlertIDs: Set(suppressedMatches)
        )
    }
}

nonisolated enum MatchKind { case product, brandFollow }

nonisolated struct ScoredAlert: Identifiable {
    let alert: RecallAlert
    let tier: MatchTier
    let productID: String?   // uuidString van het matchende product (voor confirm/suppress)
    let kind: MatchKind
    var id: String { alert.id }
}

@MainActor
enum MatchBridge {
    static func brandFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .brand }.map { Normalizer.text($0.value) }.filter { !$0.isEmpty })
    }
    static func categoryFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .category }.map(\.value))
    }

    /// Persoonlijke matches: bezit-matches (≥ MIDDEL) + gevolgde-merk-matches (MIDDEL).
    /// Categorie-follows zitten hier NIET in — die horen in de feed (Fase 1 §6).
    /// Ontdubbeld per alert op de hoogste trede.
    static func personalMatches(
        products: [TrackedProduct],
        subscriptions: [Subscription],
        alerts: [RecallAlert],
        config: MatchingConfig
    ) -> [ScoredAlert] {
        let matchable = products.map { ($0.id.uuidString, $0.matchable()) }
        let brand = brandFollows(subscriptions)

        var best: [String: ScoredAlert] = [:]
        func consider(_ s: ScoredAlert) {
            if let e = best[s.alert.id], e.tier >= s.tier { return }
            best[s.alert.id] = s
        }

        for (pid, p) in matchable {
            for alert in alerts {
                let m = MatchingService.evaluate(product: p, alert: alert, config: config)
                if m.tier >= .medium { // LAAG = feed, niet persoonlijk
                    consider(ScoredAlert(alert: alert, tier: m.tier, productID: pid, kind: .product))
                }
            }
        }
        // Gevolgde merken (geen categorie hier): zachte MIDDEL-melding.
        for alert in alerts {
            let t = MatchingService.followTier(for: alert, brandFollows: brand, categoryFollows: [])
            if t == .medium {
                consider(ScoredAlert(alert: alert, tier: .medium, productID: nil, kind: .brandFollow))
            }
        }

        return best.values.sorted {
            if $0.tier != $1.tier { return $0.tier > $1.tier }
            return $0.alert.publishedAt > $1.alert.publishedAt
        }
    }
}
