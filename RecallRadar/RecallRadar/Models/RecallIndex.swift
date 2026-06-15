//
//  RecallIndex.swift
//  RecallRadar
//
//  C1 — Top-level index + meta + de meegereisde taxonomie/matching-config.
//  De labels en drempels reizen mee in de index, zodat de app ze kan tonen en
//  bijstellen zonder app-update (Fase 1 §6).
//

import Foundation

struct RecallIndex: Codable {
    let schemaVersion: Int
    let generatedAt: Date
    let windowMonths: Int
    let count: Int
    let categories: [String: CategoryInfo]
    let risks: [String: RiskInfo]
    let matchingConfig: MatchingConfig
    let disclaimer: String
    let alerts: [RecallAlert]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case generatedAt = "generated_at"
        case windowMonths = "window_months"
        case count, categories, risks
        case matchingConfig = "matching_config"
        case disclaimer, alerts
    }

    struct CategoryInfo: Codable, Hashable {
        let label: String
        let youngFamily: Bool
        enum CodingKeys: String, CodingKey {
            case label
            case youngFamily = "young_family"
        }
    }

    struct RiskInfo: Codable, Hashable {
        let label: String
    }

    func categoryLabel(_ code: String) -> String { categories[code]?.label ?? code }
    func riskLabel(_ code: String) -> String { risks[code]?.label ?? code }
}

/// Meta voor goedkope versie-checks (meta.json).
struct RecallMeta: Codable {
    let generatedAt: Date
    let schemaVersion: Int
    let windowMonths: Int
    let count: Int
    let etag: String

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case schemaVersion = "schema_version"
        case windowMonths = "window_months"
        case count, etag
    }
}

/// Spiegelt `matching_config` uit de index. Gebruikt door de MatchingService (Blok D).
struct MatchingConfig: Codable, Hashable {
    let weights: Weights
    let thresholds: Thresholds
    let brandAliases: [String: String]

    enum CodingKeys: String, CodingKey {
        case weights, thresholds
        case brandAliases = "brandAliases"
    }

    struct Weights: Codable, Hashable {
        let barcodeExact: Int
        let brandExact: Int
        let modelExact: Int
        let modelFuzzy: Int
        let categoryEqual: Int
        let brandFuzzy: Int
        let batchInRange: Int
        let penaltyCategoryMismatch: Int
        let penaltyModelMismatch: Int
    }

    struct Thresholds: Codable, Hashable {
        let high: Int
        let medium: Int
        let low: Int
    }
}

extension JSONDecoder {
    /// Decoder afgestemd op de index: tolerante datums ("2026-06-12" én volledige
    /// ISO-8601 met/zonder fractionele seconden).
    static var recallIndex: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { d in
            let raw = try d.singleValueContainer().decode(String.self)
            if let date = RecallDateParser.date(from: raw) { return date }
            throw DecodingError.dataCorrupted(
                .init(codingPath: d.codingPath, debugDescription: "Onbekend datumformaat: \(raw)")
            )
        }
        return decoder
    }
}

enum RecallDateParser {
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let dateOnly: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func date(from raw: String) -> Date? {
        if raw.count == 10 { return dateOnly.date(from: raw) }   // "2026-06-12"
        return isoFractional.date(from: raw) ?? iso.date(from: raw)
    }
}
