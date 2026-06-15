//
//  ContentView.swift
//  RecallRadar
//
//  C1 — Minimale verificatie-UI bovenop de index-laag: status, "laatst bijgewerkt"
//  en de meest recente recalls. De volwaardige feed met categoriefilter (P0-3) +
//  recall-detail (P0-4) komen in Blok C3/C4.
//

import SwiftUI

struct ContentView: View {
    @State private var store = RecallStore()

    var body: some View {
        NavigationStack {
            Group {
                switch store.status {
                case .idle, .loading:
                    ProgressView("Recalls laden…")
                case .empty:
                    ContentUnavailableView(
                        "Geen recalls beschikbaar",
                        systemImage: "checkmark.shield",
                        description: Text("Zodra de index beschikbaar is, verschijnen recalls hier.")
                    )
                case .loaded:
                    feed
                }
            }
            .navigationTitle("Recall Radar")
        }
        .task { await store.load() }
    }

    private var feed: some View {
        List {
            Section {
                ForEach(store.alerts.prefix(50)) { alert in
                    AlertRow(alert: alert, index: store.index)
                }
            } header: {
                Text("\(store.index.count) recalls · \(store.lastUpdatedText)")
            } footer: {
                Text(store.index.disclaimer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }
}

private struct AlertRow: View {
    let alert: RecallAlert
    let index: RecallIndex

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(alert.displayTitle)
                .font(.headline)
                .lineLimit(2)
            HStack(spacing: 6) {
                Label(index.categoryLabel(alert.category), systemImage: "tag")
                Text("·")
                Text(index.riskLabel(alert.riskType))
                Spacer()
                Text(alert.publishedAt, style: .date)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
}
