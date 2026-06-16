//
//  FeedView.swift
//  RecallRadar
//
//  C3 — Browsebare NL/EU-recallfeed met categoriefilter (P0-3). Chronologisch
//  (nieuwste eerst), filterbaar op de interne categoriegroepen + zoeken op
//  merk/model. Draait op de index die al live op GitHub Pages staat.
//

import SwiftUI

struct FeedView: View {
    let store: RecallStore

    @State private var selectedCategory: String? = nil // nil = alle
    @State private var searchText: String = ""

    var body: some View {
        Group {
            switch store.status {
            case .idle, .loading:
                ProgressView("Recalls laden…")
            case .empty:
                ContentUnavailableView(
                    "Geen recalls beschikbaar",
                    systemImage: "checkmark.shield",
                    description: Text("Controleer je verbinding. Zodra de index beschikbaar is, verschijnen recalls hier.")
                )
            case .loaded:
                content
            }
        }
        .navigationTitle("Recalls")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        VStack(spacing: 0) {
            categoryBar
            if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                list
            }
        }
        .searchable(text: $searchText, prompt: "Zoek op merk of model")
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

    private func chip(code: String?, label: String, count: Int) -> some View {
        let selected = selectedCategory == code
        return Button {
            withAnimation(.snappy) { selectedCategory = code }
        } label: {
            HStack(spacing: 5) {
                if let code { Image(systemName: CategoryStyle.icon(code)) }
                Text(label)
                Text("\(count)").foregroundStyle(selected ? .white.opacity(0.8) : .secondary)
            }
            .font(.subheadline.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(selected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary),
                        in: Capsule())
            .foregroundStyle(selected ? .white : .primary)
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
            if let cat = selectedCategory, a.category != cat { return false }
            if q.isEmpty { return true }
            return [a.brandRaw, a.brand, a.modelRaw, a.model, a.alertNumber]
                .compactMap { $0?.lowercased() }
                .contains { $0.contains(q) }
        }
    }
}
