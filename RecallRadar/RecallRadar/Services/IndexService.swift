//
//  IndexService.swift
//  RecallRadar
//
//  C1 — Download + cache van de alert-index. Privacy-first: dit is een GET van
//  publieke data; er gaat NOOIT iets van de gebruiker mee in een verzoek.
//
//  Strategie:
//   • GET index.json met `If-None-Match` (ETag van GitHub Pages).
//   • 200 → decode, schrijf naar Caches/ + bewaar ETag.
//   • 304 → gebruik de cache.
//   • Netwerkfout → laatst bekende cache; geen cache → gebundelde fixture.
//  De service faalt nooit hard: de feed moet altijd iets kunnen tonen
//  (guardrail: nooit een "geen recalls"-conclusie door een technische fout).
//

import Foundation

actor IndexService {
    enum Origin { case network, notModified, cache, bundle }

    struct Result {
        let index: RecallIndex
        let origin: Origin
    }

    struct Configuration {
        /// Wordt omgezet naar de echte GitHub Pages-URL zodra die live is.
        /// Nu: project-Pages onder de user-site (raakt de hoofdpagina niet).
        var indexURL: URL
        var session: URLSession

        static let `default` = Configuration(
            indexURL: URL(string: "https://jimmyrentmeester.github.io/recallradar/index.json")!,
            session: .shared
        )
    }

    static let shared = IndexService()

    private let config: Configuration
    private let cacheURL: URL
    private let etagDefaultsKey = "recall.index.etag"

    init(config: Configuration = .default) {
        self.config = config
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = caches.appendingPathComponent("recall-index.json")
    }

    /// Haalt de index op met de volledige fallback-keten. Gooit nooit.
    func refresh() async -> Result {
        do {
            var request = URLRequest(url: config.indexURL)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalCacheData
            if let etag = storedETag {
                request.setValue(etag, forHTTPHeaderField: "If-None-Match")
            }

            let (data, response) = try await config.session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return fallback()
            }

            if http.statusCode == 304, let cached = loadCache() {
                return Result(index: cached, origin: .notModified)
            }

            guard (200...299).contains(http.statusCode) else {
                return fallback()
            }

            let index = try JSONDecoder.recallIndex.decode(RecallIndex.self, from: data)
            try? data.write(to: cacheURL, options: .atomic)
            if let etag = http.value(forHTTPHeaderField: "ETag") { storedETag = etag }
            return Result(index: index, origin: .network)
        } catch {
            return fallback()
        }
    }

    /// Synchrone best-effort load (cache → bundle) voor een snelle eerste render.
    func cachedOrBundled() -> RecallIndex? {
        loadCache() ?? loadBundle()
    }

    // MARK: - Fallback

    private func fallback() -> Result {
        if let cached = loadCache() { return Result(index: cached, origin: .cache) }
        if let bundled = loadBundle() { return Result(index: bundled, origin: .bundle) }
        // Absolute laatste redmiddel: een lege-maar-geldige index.
        return Result(index: .empty, origin: .bundle)
    }

    private func loadCache() -> RecallIndex? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder.recallIndex.decode(RecallIndex.self, from: data)
    }

    private func loadBundle() -> RecallIndex? {
        guard let url = Bundle.main.url(forResource: "index.sample", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.recallIndex.decode(RecallIndex.self, from: data)
    }

    private var storedETag: String? {
        get { UserDefaults.standard.string(forKey: etagDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: etagDefaultsKey) }
    }
}

extension RecallIndex {
    /// Geldige lege index voor de allereerste run zonder cache/bundle/netwerk.
    static var empty: RecallIndex {
        RecallIndex(
            schemaVersion: 1,
            generatedAt: .distantPast,
            windowMonths: 24,
            count: 0,
            categories: [:],
            risks: [:],
            matchingConfig: MatchingConfig(
                weights: .init(barcodeExact: 70, brandExact: 30, modelExact: 40, modelFuzzy: 20,
                               categoryEqual: 15, brandFuzzy: 15, batchInRange: 25,
                               penaltyCategoryMismatch: -15, penaltyModelMismatch: -20),
                thresholds: .init(high: 75, medium: 45, low: 20),
                brandAliases: [:]
            ),
            disclaimer: "Informatief, niet uitputtend. De officiële bron is leidend.",
            alerts: []
        )
    }
}
