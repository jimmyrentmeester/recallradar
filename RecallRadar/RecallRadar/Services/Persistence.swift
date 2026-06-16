//
//  Persistence.swift
//  RecallRadar
//
//  C2 — SwiftData ModelContainer met CloudKit-mirroring. Valt automatisch terug
//  op een lokale store als de iCloud-capability nog niet (volledig) is ingesteld,
//  zodat de app altijd draait — ook vóór de capability in Xcode is toegevoegd.
//

import Foundation
import SwiftData

enum Persistence {
    static let schema = Schema([TrackedProduct.self, Subscription.self])

    /// Probeert CloudKit; valt terug op lokaal bij ontbrekende capability/entitlement.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        if inMemory {
            let cfg = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: cfg)
        }

        // 1) Voorkeur: CloudKit-mirroring (gratis iCloud-back-up + basis voor delen).
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
            return container
        }

        // 2) Fallback: lokaal-only (capability nog niet actief of geen iCloud-account).
        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: localConfig) {
            return container
        }

        // 3) Laatste redmiddel: in-memory, zodat de app nooit crasht bij opstarten.
        let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: memConfig)
    }
}
