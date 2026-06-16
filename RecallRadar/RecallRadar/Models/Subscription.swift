//
//  Subscription.swift
//  RecallRadar
//
//  C2 — Een gevolgd merk of categorie (hoofdpad uit de onboarding, 0 friction).
//  Levert waarde zonder dat de gebruiker een concreet product invoert (Fase 1 §6,
//  "aparte tak: merk/categorie-abonnementen").
//
//  CloudKit-compatibel: defaults op alles, geen unique-constraints.
//

import Foundation
import SwiftData

enum SubscriptionKind: String, Codable, CaseIterable {
    case brand
    case category
}

@Model
final class Subscription {
    var id: UUID = UUID()

    /// Opgeslagen als rawValue (String) — robuust voor CloudKit-mirroring.
    var kindRaw: String = SubscriptionKind.category.rawValue
    var value: String = ""
    /// Push aan/uit voor deze follow. Default uit → categorie-feed zonder ruis
    /// (Fase 1 §6: push alleen als de gebruiker het expliciet aanzet).
    var pushEnabled: Bool = false
    var addedAt: Date = Date()

    init(kind: SubscriptionKind, value: String, pushEnabled: Bool = false, addedAt: Date = Date()) {
        self.kindRaw = kind.rawValue
        self.value = value
        self.pushEnabled = pushEnabled
        self.addedAt = addedAt
    }
}

extension Subscription {
    var kind: SubscriptionKind {
        get { SubscriptionKind(rawValue: kindRaw) ?? .category }
        set { kindRaw = newValue.rawValue }
    }
}
