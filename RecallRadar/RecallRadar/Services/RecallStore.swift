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
        case loaded(origin: String)
        case empty
    }

    private(set) var index: RecallIndex = .empty
    private(set) var status: Status = .idle

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
        status = .loading
        // Snelle eerste render uit cache/bundle, daarna verversen over het netwerk.
        if let quick = await service.cachedOrBundled() {
            index = quick
        }
        let result = await service.refresh()
        index = result.index
        status = result.index.count == 0 ? .empty : .loaded(origin: originLabel(result.origin))
    }

    private func originLabel(_ origin: IndexService.Origin) -> String {
        switch origin {
        case .network: "netwerk"
        case .notModified: "cache (ongewijzigd)"
        case .cache: "cache (offline)"
        case .bundle: "ingebouwd"
        }
    }
}
