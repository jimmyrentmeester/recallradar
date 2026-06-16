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

@MainActor
enum MatchBridge {
    /// Genormaliseerde merknamen van gevolgde merken (voor de follow-tak).
    static func brandFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .brand }.map { Normalizer.text($0.value) }.filter { !$0.isEmpty })
    }

    /// Interne categoriecodes van gevolgde categorieën.
    static func categoryFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .category }.map(\.value))
    }

    /// Alle relevante matches: bezit-matches (≥ LAAG) + follow-matches, ontdubbeld per alert
    /// op de hoogste trede. Nieuwste/hoogste eerst.
    static func relevantMatches(
        products: [TrackedProduct],
        subscriptions: [Subscription],
        alerts: [RecallAlert],
        config: MatchingConfig
    ) -> [ScoredAlert] {
        let matchable = products.map { $0.matchable() }
        let brand = brandFollows(subscriptions)
        let cat = categoryFollows(subscriptions)

        var best: [String: ScoredAlert] = [:] // alert.id → hoogste trede
        func consider(_ alert: RecallAlert, _ tier: MatchTier, productID: String?) {
            guard tier > .none else { return }
            if let existing = best[alert.id], existing.tier >= tier { return }
            best[alert.id] = ScoredAlert(alert: alert, tier: tier, productID: productID)
        }

        for p in matchable {
            for alert in alerts {
                let m = MatchingService.evaluate(product: p, alert: alert, config: config)
                consider(alert, m.tier, productID: m.tier > .none ? p.id : nil)
            }
        }
        for alert in alerts {
            consider(alert, MatchingService.followTier(for: alert, brandFollows: brand, categoryFollows: cat), productID: nil)
        }

        return best.values.sorted {
            if $0.tier != $1.tier { return $0.tier > $1.tier }
            return $0.alert.publishedAt > $1.alert.publishedAt
        }
    }
}

nonisolated struct ScoredAlert: Identifiable {
    let alert: RecallAlert
    let tier: MatchTier
    let productID: String?
    var id: String { alert.id }
}
