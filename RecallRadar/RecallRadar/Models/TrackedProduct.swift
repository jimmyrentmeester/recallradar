//
//  TrackedProduct.swift
//  RecallRadar
//
//  C2 — Een product dat de gebruiker bezit en laat bewaken. Blijft privé op het
//  toestel + in de eigen iCloud (CloudKit-mirroring); verlaat het toestel nooit
//  richting onze infra (guardrail: privacy-first, geen bezit-upload).
//
//  CloudKit-eisen waaraan dit model voldoet: elke property heeft een default,
//  geen @Attribute(.unique), geen verplichte relaties.
//

import Foundation
import SwiftData

@Model
final class TrackedProduct {
    /// Eigen stabiele id (geen unique-constraint i.v.m. CloudKit).
    var id: UUID = UUID()

    /// Zoals de gebruiker invoerde (voor weergave). Normalisatie gebeurt in de
    /// MatchingService op matchmoment (Blok D), zodat dit ruw blijft.
    var brand: String?
    var model: String?
    var category: String = "overig"
    var barcode: String?

    var addedAt: Date = Date()

    /// Alert-id's die de gebruiker bevestigde als "van mij" → toekomstige recalls
    /// hierop gaan naar HOOG (Fase 1 §7).
    var confirmedMatches: [String] = []
    /// Alert-id's die de gebruiker wegklikte ("nee, niet van mij") → onderdrukt.
    var suppressedMatches: [String] = []

    init(
        id: UUID = UUID(),
        brand: String? = nil,
        model: String? = nil,
        category: String = "overig",
        barcode: String? = nil,
        addedAt: Date = Date(),
        confirmedMatches: [String] = [],
        suppressedMatches: [String] = []
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.category = category
        self.barcode = barcode
        self.addedAt = addedAt
        self.confirmedMatches = confirmedMatches
        self.suppressedMatches = suppressedMatches
    }
}

extension TrackedProduct {
    var displayName: String {
        let parts = [brand, model].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? (barcode ?? "Onbekend product") : parts.joined(separator: " · ")
    }

    func hasConfirmed(_ alertID: String) -> Bool { confirmedMatches.contains(alertID) }
    func hasSuppressed(_ alertID: String) -> Bool { suppressedMatches.contains(alertID) }
}
