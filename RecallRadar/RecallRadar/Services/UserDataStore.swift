//
//  UserDataStore.swift
//  RecallRadar
//
//  C2 — CRUD-laag boven SwiftData voor bezit (TrackedProduct) en follows
//  (Subscription). Views gebruiken meestal @Query om te lezen; muteren loopt via
//  deze store zodat dedup/feedback-logica op één plek zit (en testbaar is).
//

import Foundation
import SwiftData

@MainActor
struct UserDataStore {
    let context: ModelContext

    init(_ context: ModelContext) { self.context = context }

    // MARK: - Producten

    @discardableResult
    func addProduct(
        brand: String? = nil,
        model: String? = nil,
        category: String = "overig",
        barcode: String? = nil
    ) -> TrackedProduct {
        let product = TrackedProduct(
            brand: brand?.trimmedOrNil,
            model: model?.trimmedOrNil,
            category: category,
            barcode: barcode?.trimmedOrNil
        )
        context.insert(product)
        try? context.save()
        return product
    }

    func update(_ product: TrackedProduct, brand: String?, model: String?, category: String, barcode: String?) {
        product.brand = brand?.trimmedOrNil
        product.model = model?.trimmedOrNil
        product.category = category
        product.barcode = barcode?.trimmedOrNil
        try? context.save()
    }

    func delete(_ product: TrackedProduct) {
        context.delete(product)
        try? context.save()
    }

    func allProducts() -> [TrackedProduct] {
        let descriptor = FetchDescriptor<TrackedProduct>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    var productCount: Int {
        (try? context.fetchCount(FetchDescriptor<TrackedProduct>())) ?? 0
    }

    // MARK: - Feedback-loop ("is dit van jou?", Fase 1 §7)

    func confirmMatch(_ product: TrackedProduct, alertID: String) {
        if !product.confirmedMatches.contains(alertID) { product.confirmedMatches.append(alertID) }
        product.suppressedMatches.removeAll { $0 == alertID }
        try? context.save()
    }

    func suppressMatch(_ product: TrackedProduct, alertID: String) {
        if !product.suppressedMatches.contains(alertID) { product.suppressedMatches.append(alertID) }
        product.confirmedMatches.removeAll { $0 == alertID }
        try? context.save()
    }

    // MARK: - Follows (merk/categorie)

    /// Voegt een follow toe; voorkomt duplicaten op (kind, value, genormaliseerd).
    @discardableResult
    func addSubscription(kind: SubscriptionKind, value: String, pushScope: PushScope = .feed) -> Subscription? {
        guard let clean = value.trimmedOrNil else { return nil }
        let key = clean.lowercased()
        if allSubscriptions().contains(where: { $0.kind == kind && $0.value.lowercased() == key }) {
            return nil // bestaat al
        }
        let sub = Subscription(kind: kind, value: clean, pushScope: pushScope)
        context.insert(sub)
        try? context.save()
        return sub
    }

    func delete(_ subscription: Subscription) {
        context.delete(subscription)
        try? context.save()
    }

    func setPushScope(_ subscription: Subscription, _ scope: PushScope) {
        subscription.pushScope = scope
        try? context.save()
    }

    func allSubscriptions() -> [Subscription] {
        let descriptor = FetchDescriptor<Subscription>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Bewaakt de gebruiker iets? (voor de maandelijkse geruststelling-digest, P0-6).
    var isMonitoringAnything: Bool {
        productCount > 0 || !allSubscriptions().isEmpty
    }
}

private extension String {
    var trimmedOrNil: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
