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

nonisolated enum MatchKind: Sendable, Hashable { case product, brandFollow }

nonisolated struct ScoredAlert: Identifiable, Sendable, Hashable {
    let alert: RecallAlert
    let tier: MatchTier
    let productID: String?   // uuidString van het matchende product (voor confirm/suppress)
    let kind: MatchKind
    var signals: [String] = [] // "Waarom zie ik dit?" — gematchte signalen
    var id: String { alert.id }
}

enum MatchBridge {
    @MainActor static func brandFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .brand }.map { Normalizer.text($0.value) }.filter { !$0.isEmpty })
    }
    @MainActor static func categoryFollows(_ subs: [Subscription]) -> Set<String> {
        Set(subs.filter { $0.kind == .category }.map(\.value))
    }

    /// Goedkope main-actor snapshot van SwiftData → value-types, zodat de zware
    /// scoring daarna OFF-MAIN kan (geen UI-hang bij save/bevestigen).
    @MainActor static func snapshot(
        products: [TrackedProduct], subscriptions: [Subscription]
    ) -> (products: [MatchableProduct], brandFollows: Set<String>) {
        (products.map { $0.matchable() }, brandFollows(subscriptions))
    }

    /// Zware, pure scoring — bedoeld om buiten de main actor te draaien.
    /// Persoonlijke matches: bezit-matches (≥ MIDDEL) + gevolgde-merk-matches (MIDDEL).
    /// Categorie-follows zitten hier NIET in (Fase 1 §6). Ontdubbeld per alert, hoogste trede.
    nonisolated static func compute(
        products: [MatchableProduct],
        brandFollows: Set<String>,
        alerts: [RecallAlert],
        config: MatchingConfig
    ) -> [ScoredAlert] {
        var best: [String: ScoredAlert] = [:]
        func consider(_ s: ScoredAlert) {
            if let e = best[s.alert.id], e.tier >= s.tier { return }
            best[s.alert.id] = s
        }
        for p in products {
            for alert in alerts {
                let m = MatchingService.evaluate(product: p, alert: alert, config: config)
                if m.tier >= .medium {
                    let signals = MatchingService.matchedSignals(product: p, alert: alert, config: config)
                    consider(ScoredAlert(alert: alert, tier: m.tier, productID: p.id, kind: .product, signals: signals))
                }
            }
        }
        for alert in alerts {
            let t = MatchingService.followTier(for: alert, brandFollows: brandFollows, categoryFollows: [])
            if t == .medium {
                consider(ScoredAlert(alert: alert, tier: .medium, productID: nil, kind: .brandFollow,
                                     signals: ["Je volgt dit merk"]))
            }
        }
        return best.values.sorted {
            if $0.tier != $1.tier { return $0.tier > $1.tier }
            return $0.alert.publishedAt > $1.alert.publishedAt
        }
    }

    /// Beste match (≥ LAAG) voor één zojuist toegevoegd/bewerkt product — voor de
    /// directe "dit product heeft mogelijk een recall"-check bij toevoegen.
    nonisolated static func bestMatch(
        product: MatchableProduct, alerts: [RecallAlert], config: MatchingConfig
    ) -> ScoredAlert? {
        var best: ScoredAlert?
        for alert in alerts {
            let m = MatchingService.evaluate(product: product, alert: alert, config: config)
            guard m.tier > .none else { continue }
            if best == nil || m.tier > best!.tier ||
                (m.tier == best!.tier && alert.publishedAt > best!.alert.publishedAt) {
                best = ScoredAlert(alert: alert, tier: m.tier, productID: product.id, kind: .product)
            }
        }
        return best
    }

    /// Gemaks-wrapper (snapshot + compute) voor niet-UI-paden zoals de achtergrond-refresh.
    @MainActor static func personalMatches(
        products: [TrackedProduct], subscriptions: [Subscription],
        alerts: [RecallAlert], config: MatchingConfig
    ) -> [ScoredAlert] {
        let snap = snapshot(products: products, subscriptions: subscriptions)
        return compute(products: snap.products, brandFollows: snap.brandFollows, alerts: alerts, config: config)
    }
}
