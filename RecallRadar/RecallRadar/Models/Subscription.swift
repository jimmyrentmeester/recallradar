//
//  Subscription.swift
//  RecallRadar
//
//  C2/feedback — Een gevolgd merk of categorie (0-friction hoofdpad). Per follow
//  bepaal je het notificatie-bereik (feed / alleen ernstige / alles).
//
//  CloudKit-compatibel: defaults op alles, geen unique-constraints.
//

import Foundation
import SwiftData

enum SubscriptionKind: String, Codable, CaseIterable {
    case brand
    case category
}

/// Hoeveel meldingen je van een gevolgde bron wilt (Fase 1 §6 + feedback).
enum PushScope: String, Codable, CaseIterable {
    case feed   // alleen in de feed, geen push
    case high   // alleen ernstige recalls pushen
    case all    // elke recall pushen

    var label: String {
        switch self {
        case .feed: "Alleen in feed"
        case .high: "Alleen ernstige"
        case .all: "Alle recalls"
        }
    }
    var icon: String {
        switch self {
        case .feed: "list.bullet"
        case .high: "exclamationmark.triangle"
        case .all: "bell.fill"
        }
    }
}

@Model
final class Subscription {
    var id: UUID = UUID()
    var kindRaw: String = SubscriptionKind.category.rawValue
    var value: String = ""
    /// Notificatie-bereik (rawValue). Standaard alleen feed → geen ruis.
    var pushScopeRaw: String = PushScope.feed.rawValue
    var addedAt: Date = Date()

    init(kind: SubscriptionKind, value: String, pushScope: PushScope = .feed, addedAt: Date = Date()) {
        self.kindRaw = kind.rawValue
        self.value = value
        self.pushScopeRaw = pushScope.rawValue
        self.addedAt = addedAt
    }
}

extension Subscription {
    var kind: SubscriptionKind {
        get { SubscriptionKind(rawValue: kindRaw) ?? .category }
        set { kindRaw = newValue.rawValue }
    }
    var pushScope: PushScope {
        get { PushScope(rawValue: pushScopeRaw) ?? .feed }
        set { pushScopeRaw = newValue.rawValue }
    }
}
