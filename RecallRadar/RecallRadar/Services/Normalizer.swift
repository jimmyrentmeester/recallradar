//
//  Normalizer.swift
//  RecallRadar
//
//  D3 — Swift-port van de ingestion-normalisatie (`ingestion/src/util.js`). MOET
//  identieke output geven, want de alert-velden zijn al door util.js genormaliseerd
//  en de productvelden gaan hier doorheen — anders matchen ze niet (Fase 1 §4).
//

import Foundation

nonisolated enum Normalizer {
    private static let legalSuffixes = [
        "b.v.", "bv", "n.v.", "nv", "gmbh", "ltd", "ltd.", "llc", "inc", "inc.",
        "s.r.l.", "srl", "s.a.", "sa", "co.", "co", "kg", "ag", "oy", "ab", "as",
        "sp. z o.o.", "spa", "s.p.a.",
    ]

    /// Lowercase, diacritics weg, leestekens→spatie (. & - behouden), juridische
    /// suffixen eraf. Spiegelt util.js `normalizeText`.
    static func text(_ input: String?) -> String {
        guard let input, !input.isEmpty else { return "" }
        var s = input.lowercased().folding(options: .diacriticInsensitive, locale: .init(identifier: "en"))
        s = s.replacingOccurrences(of: "[^a-z0-9\\s.&-]", with: " ", options: .regularExpression)
        s = collapse(s)
        for suf in legalSuffixes {
            let pattern = "(^|\\s)" + NSRegularExpression.escapedPattern(for: suf) + "(\\s|$)"
            s = s.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        return collapse(s)
    }

    /// Alfanumeriek, scheidingstekens weg ("HX-200" → "hx200"). Spiegelt `normalizeModel`.
    static func model(_ input: String?) -> String {
        guard let input, !input.isEmpty else { return "" }
        let s = input.lowercased().folding(options: .diacriticInsensitive, locale: .init(identifier: "en"))
        return s.replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    }

    /// Cijfers; UPC-12→EAN-13; EAN-13/EAN-8 checkdigit-valide of nil. Spiegelt `normalizeBarcode`.
    static func barcode(_ input: String?) -> String? {
        guard let input else { return nil }
        var digits = input.filter(\.isNumber)
        if digits.count == 12 { digits = "0" + digits }
        if digits.count == 8 { return isValidEAN8(digits) ? digits : nil }
        if digits.count != 13 { return nil }
        return isValidEAN13(digits) ? digits : nil
    }

    private static func collapse(_ s: String) -> String {
        s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func isValidEAN13(_ code: String) -> Bool {
        let d = code.compactMap { $0.wholeNumberValue }
        guard d.count == 13 else { return false }
        let sum = (0..<12).reduce(0) { $0 + d[$1] * ($1 % 2 == 0 ? 1 : 3) }
        return (10 - sum % 10) % 10 == d[12]
    }

    private static func isValidEAN8(_ code: String) -> Bool {
        let d = code.compactMap { $0.wholeNumberValue }
        guard d.count == 8 else { return false }
        let sum = (0..<7).reduce(0) { $0 + d[$1] * ($1 % 2 == 0 ? 3 : 1) }
        return (10 - sum % 10) % 10 == d[7]
    }

    /// Jaro-Winkler-similariteit (0…1) voor fuzzy merk/model-vergelijking (Fase 1 §5).
    static func jaroWinkler(_ a: String, _ b: String) -> Double {
        if a == b { return 1 }
        if a.isEmpty || b.isEmpty { return 0 }
        let s = Array(a), t = Array(b)
        let matchDistance = max(s.count, t.count) / 2 - 1
        var sMatches = [Bool](repeating: false, count: s.count)
        var tMatches = [Bool](repeating: false, count: t.count)
        var matches = 0

        for i in 0..<s.count {
            let lo = max(0, i - matchDistance)
            let hi = min(i + matchDistance + 1, t.count)
            guard lo < hi else { continue }
            for j in lo..<hi where !tMatches[j] && s[i] == t[j] {
                sMatches[i] = true; tMatches[j] = true; matches += 1; break
            }
        }
        if matches == 0 { return 0 }

        var transpositions = 0, k = 0
        for i in 0..<s.count where sMatches[i] {
            while !tMatches[k] { k += 1 }
            if s[i] != t[k] { transpositions += 1 }
            k += 1
        }
        let m = Double(matches)
        let jaro = (m / Double(s.count) + m / Double(t.count) + (m - Double(transpositions) / 2) / m) / 3

        // Winkler-bonus voor gemeenschappelijke prefix (max 4).
        var prefix = 0
        for i in 0..<min(4, min(s.count, t.count)) {
            if s[i] == t[i] { prefix += 1 } else { break }
        }
        return jaro + Double(prefix) * 0.1 * (1 - jaro)
    }
}
