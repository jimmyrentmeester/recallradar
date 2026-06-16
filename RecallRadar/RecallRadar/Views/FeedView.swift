//
//  FeedView.swift
//  RecallRadar
//
//  C3 — Browsebare NL/EU-recallfeed met categoriefilter (P0-3). Chronologisch
//  (nieuwste eerst), filterbaar op de interne categoriegroepen + zoeken op
//  merk/model. Draait op de index die al live op GitHub Pages staat.
//

import SwiftUI
import SwiftData

struct FeedView: View {
    let store: RecallStore
    @Query private var subscriptions: [Subscription]

    @State private var selectedCategory: String? = nil // nil = alle
    @State private var searchText: String = ""
    @State private var onlyFollowed = false

    private var followedCategories: Set<String> {
        Set(subscriptions.filter { $0.kind == .category }.map(\.value))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch store.status {
                case .idle, .loading:
                    ProgressView("Recalls laden…")
                case .failed:
                    failedState
                case .loaded:
                    content
                }
            }
            .navigationTitle("Verken")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// Geen netwerk én geen cache/bundle. Nooit als "geen recalls" framen (guardrail).
    private var failedState: some View {
        ContentUnavailableView {
            Label("Recalls niet geladen", systemImage: "wifi.exclamationmark")
        } description: {
            Text("We konden de recall-lijst nu niet ophalen. Dit betekent niet dat er geen recalls zijn.")
        } actions: {
            Button("Opnieuw proberen") { Task { await store.load() } }
                .buttonStyle(.borderedProminent)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            if store.isOffline { offlineBanner }
            categoryBar
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                list
            }
        }
        .searchable(text: $searchText, prompt: "Zoek op merk of model")
    }

    private var offlineBanner: some View {
        HStack(spacing: DS.Space.xs) {
            Image(systemName: "wifi.slash")
            Text("Offline — laatst bekende lijst wordt getoond.")
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(DS.Color.textSecondary)
        .padding(.horizontal, DS.Space.lg).padding(.vertical, DS.Space.sm)
        .background(DS.Color.riskLowBg) // nooit als alarm vormgeven (§3.4)
    }

    private var list: some View {
        List {
            Section {
                ForEach(filtered) { alert in
                    NavigationLink(value: alert) {
                        RecallRow(alert: alert, index: store.index)
                    }
                }
            } header: {
                Text("\(filtered.count) recalls · \(store.lastUpdatedText)")
            } footer: {
                Text(store.index.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: RecallAlert.self) { alert in
            RecallDetailView(alert: alert, index: store.index)
        }
    }

    // MARK: - Categoriefilter (chips)

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if !followedCategories.isEmpty { mineChip }
                chip(code: nil, label: "Alle", count: store.alerts.count)
                ForEach(categoryOptions, id: \.code) { opt in
                    chip(code: opt.code, label: store.index.categoryLabel(opt.code), count: opt.count)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    /// Snelfilter: alleen recalls in je gevolgde categorieën.
    private var mineChip: some View {
        Button { withAnimation(.snappy) { onlyFollowed.toggle(); if onlyFollowed { selectedCategory = nil } } } label: {
            Label("Mijn categorieën", systemImage: "star.fill")
                .font(.subheadline.weight(onlyFollowed ? .semibold : .regular))
                .padding(.horizontal, DS.Space.md).padding(.vertical, 7)
                .background(onlyFollowed ? DS.Color.brandPrimaryMuted : DS.Color.bgSecondary, in: Capsule())
                .foregroundStyle(onlyFollowed ? DS.Color.brandPrimary : DS.Color.textPrimary)
                .overlay(Capsule().stroke(DS.Color.separator, lineWidth: onlyFollowed ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private func chip(code: String?, label: String, count: Int) -> some View {
        let selected = selectedCategory == code
        return Button {
            withAnimation(.snappy) { selectedCategory = code }
        } label: {
            HStack(spacing: 5) {
                if let code { Image(systemName: CategoryStyle.icon(code)) }
                Text(label)
                Text("\(count)").foregroundStyle(DS.Color.textTertiary)
            }
            .font(.subheadline.weight(selected ? .semibold : .regular))
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, 7)
            // §3.7: geselecteerd = brandPrimaryMuted-vulling + brandPrimary-tekst; anders neutraal.
            .background(selected ? DS.Color.brandPrimaryMuted : DS.Color.bgSecondary, in: Capsule())
            .foregroundStyle(selected ? DS.Color.brandPrimary : DS.Color.textPrimary)
            .overlay(Capsule().stroke(DS.Color.separator, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Afgeleide data

    private struct CategoryOption { let code: String; let count: Int }

    /// Categorieën die daadwerkelijk in de feed voorkomen, jonge-gezin-spits eerst,
    /// daarna op aantal aflopend.
    private var categoryOptions: [CategoryOption] {
        var counts: [String: Int] = [:]
        for a in store.alerts { counts[a.category, default: 0] += 1 }
        return counts
            .map { CategoryOption(code: $0.key, count: $0.value) }
            .sorted {
                let ay = store.index.categories[$0.code]?.youngFamily ?? false
                let by = store.index.categories[$1.code]?.youngFamily ?? false
                if ay != by { return ay } // youngFamily eerst
                return $0.count > $1.count
            }
    }

    private var filtered: [RecallAlert] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.alerts.filter { a in
            if onlyFollowed, !followedCategories.contains(a.category) { return false }
            if let cat = selectedCategory, a.category != cat { return false }
            if q.isEmpty { return true }
            return [a.brandRaw, a.brand, a.modelRaw, a.model, a.alertNumber]
                .compactMap { $0?.lowercased() }
                .contains { $0.contains(q) }
        }
    }
}
