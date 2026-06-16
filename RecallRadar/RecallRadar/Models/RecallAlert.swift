//
//  RecallAlert.swift
//  RecallRadar
//
//  C1 — Codable-model dat exact het genormaliseerde RecallAlert-schema spiegelt
//  dat de ingestion-job publiceert (Fase 2 Alert-schema). De app kent alleen dit
//  schema, niet de bronnen.
//
//  Ontwerpkeuze: URL-velden worden als String opgeslagen met computed `URL?`-
//  accessors, en datums via een tolerante decoder (zie RecallIndex). Eén
//  misvormd veld mag nooit de hele index-decode laten falen — de feed moet altijd
//  laden (guardrail: nooit een "geen recalls"-conclusie door een technische fout).
//

import Foundation

nonisolated enum AlertSource: String, Codable, Hashable, Sendable {
    case safetyGate = "safety_gate"
    case nvwa
    case rasff // food-ready (later)
}

nonisolated struct RecallAlert: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let source: AlertSource
    let alertNumber: String

    let brand: String?       // genormaliseerd (voor matching)
    let brandRaw: String?    // oorspronkelijk (voor weergave)
    let model: String?       // genormaliseerd
    let modelRaw: String?    // oorspronkelijk

    let category: String         // interne taxonomie-code
    let sourceCategory: String?  // oorspronkelijke broncategorie

    let barcode: String?
    let batchLot: String?

    let riskType: String     // interne risico-code
    let riskDesc: String?
    let measure: String      // officiële markt-maatregel (vertaald)
    let action: String?      // consumentenactie ("wat moet je doen?")

    let country: String      // ISO-2

    let imageURLString: String?
    let imageURLStrings: [String]?
    let sourceURLString: String

    let publishedAt: Date
    let updatedAt: Date
    let ingestedAt: Date?

    // Cross-source merge (Fase 1 §9: "toon één item met beide bronnen").
    let mergedSources: [String]?
    let mergedSourceURLs: [String]?

    enum CodingKeys: String, CodingKey {
        case id, source
        case alertNumber = "alert_number"
        case brand
        case brandRaw = "brand_raw"
        case model
        case modelRaw = "model_raw"
        case category
        case sourceCategory = "source_category"
        case barcode
        case batchLot = "batch_lot"
        case riskType = "risk_type"
        case riskDesc = "risk_desc"
        case measure
        case action
        case country
        case imageURLString = "image_url"
        case imageURLStrings = "image_urls"
        case sourceURLString = "source_url"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
        case ingestedAt = "ingested_at"
        case mergedSources = "merged_sources"
        case mergedSourceURLs = "merged_source_urls"
    }
}

nonisolated extension RecallAlert {
    var sourceURL: URL? { URL(string: sourceURLString) }
    var imageURL: URL? { imageURLString.flatMap(URL.init(string:)) }
    var imageURLs: [URL] { (imageURLStrings ?? []).compactMap { URL(string: $0) } }

    /// Naam zoals getoond aan de gebruiker (raw boven genormaliseerd).
    var displayBrand: String? { brandRaw ?? brand }
    var displayModel: String? { modelRaw ?? model }

    /// Korte titel voor feed/notificatie.
    var displayTitle: String {
        let parts = [displayBrand, displayModel].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? alertNumber : parts.joined(separator: " · ")
    }
}
