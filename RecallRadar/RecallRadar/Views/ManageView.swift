//
//  ManageView.swift
//  RecallRadar
//
//  "Mijn spullen" — beheer van alles wat je bewaakt: producten, gevolgde categorieën
//  en merken. Toevoegen loopt via de gedeelde Toevoegen-hub.
//

import SwiftUI
import SwiftData

struct ManageView: View {
    let store: RecallStore
    @Environment(\.modelContext) private var context
    @Query(sort: \TrackedProduct.addedAt, order: .reverse) private var products: [TrackedProduct]
    @Query(sort: \Subscription.addedAt, order: .reverse) private var subscriptions: [Subscription]

    @State private var showAdd = false
    @State private var editingProduct: TrackedProduct?

    private var data: UserDataStore { UserDataStore(context) }
    private var followedCategories: [Subscription] { subscriptions.filter { $0.kind == .category } }
    private var followedBrands: [Subscription] { subscriptions.filter { $0.kind == .brand } }
    private var isEmpty: Bool { products.isEmpty && subscriptions.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    ContentUnavailableView {
                        Label("Nog niets om te bewaken", systemImage: "shippingbox")
                    } description: {
                        Text("Voeg een product toe of volg een categorie of merk, dan houden wij het voor je in de gaten.")
                    } actions: {
                        Button { showAdd = true } label: { Label("Toevoegen", systemImage: "plus") }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    list
                }
            }
            .navigationTitle("Mijn spullen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Label("Toevoegen", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddHubView(store: store) }
            .sheet(item: $editingProduct) { p in AddProductView(store: store, editing: p) }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(products) { p in
                    Button { editingProduct = p } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.displayName).font(.body).foregroundStyle(DS.Color.textPrimary)
                                Text(store.index.categoryLabel(p.category)).font(.caption).foregroundStyle(DS.Color.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                }
                .onDelete { idx in idx.map { products[$0] }.forEach(data.delete) }
            } header: {
                Text("Producten")
            } footer: {
                if products.isEmpty { Text("Nog geen producten. Tik op + om er een toe te voegen of te scannen.") }
            }

            if !followedCategories.isEmpty {
                Section("Gevolgde categorieën") {
                    ForEach(followedCategories) { sub in
                        Label(store.index.categoryLabel(sub.value), systemImage: CategoryStyle.icon(sub.value))
                    }
                    .onDelete { idx in idx.map { followedCategories[$0] }.forEach(data.delete) }
                }
            }

            if !followedBrands.isEmpty {
                Section("Gevolgde merken") {
                    ForEach(followedBrands) { sub in Text(sub.value) }
                        .onDelete { idx in idx.map { followedBrands[$0] }.forEach(data.delete) }
                }
            }
        }
    }
}
