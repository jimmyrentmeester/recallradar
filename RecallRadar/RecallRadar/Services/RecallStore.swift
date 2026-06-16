//
//  RecallStore.swift
//  RecallRadar
//
//  C1 — Observable laag tussen IndexService en de UI. Houdt de geladen index +
//  laadstatus vast. De echte feed/filter komt in C3; dit is het fundament.
//

import Foundation
import Observation

@MainActor
@Observable
final class RecallStore {
    enum Status: Equatable {
        case idle
        case loading
        case loaded
        case failed   // geen netwerk én geen cache/bundle — nooit als "geen recalls" tonen
    }

    private(set) var index: RecallIndex = .empty
    private(set) var status: Status = .idle
    private(set) var origin: IndexService.Origin?

    /// Unieke merknamen uit de index (1× berekend) — voedt merk-autocomplete.
    private(set) var brandNames: [String] = []

    /// Tonen we niet-verse data (cache/ingebouwd)? Voor een eerlijke "offline"-melding.
    var isOffline: Bool { origin == .cache || origin == .bundle }

    private let service: IndexService

    init(service: IndexService = .shared) {
        self.service = service
    }

    var alerts: [RecallAlert] { index.alerts }

    /// "Laatst bijgewerkt …" voor transparantie (Fase 3 §3.6).
    var lastUpdatedText: String {
        guard index.count > 0 else { return "Nog niet bijgewerkt" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "nl_NL")
        return "Laatst bijgewerkt " + f.localizedString(for: index.generatedAt, relativeTo: .now)
    }

    func load() async {
        if index.count == 0 { status = .loading }
        // Snelle eerste render uit cache/bundle, daarna verversen over het netwerk.
        if let quick = await service.cachedOrBundled() {
            index = quick
        }
        let result = await service.refresh()
        index = result.index
        origin = result.origin
        status = result.index.count == 0 ? .failed : .loaded
        rebuildBrandNames()
    }

    private func rebuildBrandNames() {
        var seen = Set<String>()
        var names: [String] = []
        for a in index.alerts {
            guard let b = a.displayBrand?.trimmingCharacters(in: .whitespaces), !b.isEmpty else { continue }
            let key = b.lowercased()
            if seen.insert(key).inserted { names.append(b) }
        }
        brandNames = names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
