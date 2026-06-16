//
//  MyStuffView.swift
//  RecallRadar
//
//  D1/D2 — "Mijn spullen": gevolgde categorieën/merken (0-friction hoofdpad) +
//  toegevoegde producten. Toont bovenaan de recalls die het bezit/de follows
//  raken (via MatchingService). De "is dit van jou?"-bevestiging volgt in D4.
//

import SwiftUI
import SwiftData

struct MyStuffView: View {
    let store: RecallStore
    @Environment(\.modelContext) private var context
    @Query(sort: \TrackedProduct.addedAt, order: .reverse) private var products: [TrackedProduct]
    @Query(sort: \Subscription.addedAt, order: .reverse) private var subscriptions: [Subscription]

    @State private var showAdd = false
    @State private var showInfo = false
    @State private var newBrand = ""
    @State private var notifAuthorized = true

    private var data: UserDataStore { UserDataStore(context) }

    private var matches: [ScoredAlert] {
        guard !store.alerts.isEmpty else { return [] }
        return MatchBridge.personalMatches(
            products: products, subscriptions: subscriptions,
            alerts: store.alerts, config: store.index.matchingConfig
        )
    }

    /// MIDDEL bezit-matches die nog bevestigd/weggeklikt moeten worden (Fase 1 §7).
    private var pending: [ScoredAlert] {
        matches.filter { $0.kind == .product && $0.tier == .medium }
    }
    /// Zekere/bevestigde matches + gevolgde-merk-meldingen.
    private var forYou: [ScoredAlert] {
        matches.filter { $0.tier == .high || $0.kind == .brandFollow }
    }

    private func product(for scored: ScoredAlert) -> TrackedProduct? {
        guard let pid = scored.productID else { return nil }
        return products.first { $0.id.uuidString == pid }
    }

    private var followedCategories: Set<String> {
        Set(subscriptions.filter { $0.kind == .category }.map(\.value))
    }
    private var followedBrands: [Subscription] {
        subscriptions.filter { $0.kind == .brand }
    }

    var body: some View {
        NavigationStack {
            List {
                if !notifAuthorized && data.isMonitoringAnything { notifSection }
                if !pending.isEmpty { confirmSection }
                if data.isMonitoringAnything { matchesSection }
                categoriesSection
                brandsSection
                productsSection
            }
            .navigationTitle("Mijn spullen")
            .task { notifAuthorized = await NotificationService.isAuthorized() }
            .navigationDestination(for: RecallAlert.self) { alert in
                RecallDetailView(alert: alert, index: store.index)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showInfo = true } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("Over en disclaimer")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Label("Product toevoegen", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddProductView(store: store) }
            .sheet(isPresented: $showInfo) { AboutView(store: store) }
        }
    }

    // MARK: - Meldingen aanzetten (voor wie de onboarding oversloeg)

    private var notifSection: some View {
        Section {
            Button {
                Task {
                    _ = await NotificationService.requestAuthorization()
                    notifAuthorized = await NotificationService.isAuthorized()
                }
            } label: {
                Label("Zet meldingen aan", systemImage: "bell.badge")
            }
        } footer: {
            Text("Zo waarschuwen we je zodra een recall jouw spullen raakt.")
        }
    }

    // MARK: - Is dit van jou? (MIDDEL bevestigen, Fase 1 §7)

    private var confirmSection: some View {
        Section {
            ForEach(pending) { scored in
                VStack(alignment: .leading, spacing: 8) {
                    if let p = product(for: scored) {
                        Text("Lijkt op: \(p.displayName)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    NavigationLink(value: scored.alert) {
                        RecallRow(alert: scored.alert, index: store.index)
                    }
                    HStack {
                        Button {
                            if let p = product(for: scored) { data.confirmMatch(p, alertID: scored.alert.id) }
                        } label: { Label("Ja, van mij", systemImage: "checkmark") }
                            .buttonStyle(.borderedProminent).controlSize(.small)
                        Button {
                            if let p = product(for: scored) { data.suppressMatch(p, alertID: scored.alert.id) }
                        } label: { Label("Nee", systemImage: "xmark") }
                            .buttonStyle(.bordered).controlSize(.small)
                        Spacer()
                        Text("Weet ik niet").font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Is dit van jou?")
        } footer: {
            Text("Mogelijke matches met je producten. Bevestig of klik weg — dat verscherpt toekomstige meldingen.")
        }
    }

    // MARK: - Voor jou (zekere + gevolgde-merk-matches)

    @ViewBuilder private var matchesSection: some View {
        Section {
            if forYou.isEmpty {
                Label("Geen enkele recall raakt jouw spullen", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            } else {
                ForEach(forYou.prefix(30)) { scored in
                    NavigationLink(value: scored.alert) {
                        HStack {
                            RecallRow(alert: scored.alert, index: store.index)
                            TierBadge(tier: scored.tier)
                        }
                    }
                }
            }
        } header: {
            Text(forYou.isEmpty ? "Voor jou" : "Voor jou · \(forYou.count)")
        } footer: {
            if forYou.isEmpty {
                Text("Recalls in je gevolgde categorieën vind je in de Feed.")
            }
        }
    }

    // MARK: - Categorieën volgen

    private var categoriesSection: some View {
        Section {
            ForEach(store.index.categories.keys.sorted(by: { store.index.categoryLabel($0) < store.index.categoryLabel($1) }), id: \.self) { code in
                Toggle(isOn: Binding(
                    get: { followedCategories.contains(code) },
                    set: { on in toggleCategory(code, on: on) }
                )) {
                    Label(store.index.categoryLabel(code), systemImage: CategoryStyle.icon(code))
                }
            }
        } header: {
            Text("Categorieën die ik volg")
        } footer: {
            Text("Je krijgt recalls in deze categorieën in de feed. Push zet je later per categorie aan.")
        }
    }

    private func toggleCategory(_ code: String, on: Bool) {
        if on {
            data.addSubscription(kind: .category, value: code)
        } else if let sub = subscriptions.first(where: { $0.kind == .category && $0.value == code }) {
            data.delete(sub)
        }
    }

    // MARK: - Merken volgen

    private var brandsSection: some View {
        Section("Merken die ik volg") {
            HStack {
                TextField("Merk toevoegen", text: $newBrand)
                    .textInputAutocapitalization(.words)
                    .onSubmit(addBrand)
                Button("Voeg toe", action: addBrand)
                    .disabled(newBrand.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ForEach(followedBrands) { sub in
                Text(sub.value)
            }
            .onDelete { idx in idx.map { followedBrands[$0] }.forEach(data.delete) }
        }
    }

    private func addBrand() {
        data.addSubscription(kind: .brand, value: newBrand)
        newBrand = ""
    }

    // MARK: - Producten

    private var productsSection: some View {
        Section("Mijn producten") {
            if products.isEmpty {
                Text("Nog geen producten. Tik op + om er een toe te voegen of te scannen.")
                    .foregroundStyle(.secondary)
            }
            ForEach(products) { p in
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.displayName).font(.body)
                    Text(store.index.categoryLabel(p.category))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .onDelete { idx in idx.map { products[$0] }.forEach(data.delete) }
        }
    }
}

struct TierBadge: View {
    let tier: MatchTier
    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }
    private var label: String {
        switch tier { case .high: "Hoog"; case .medium: "Mogelijk"; case .low: "Misschien"; case .none: "" }
    }
    private var color: Color {
        switch tier { case .high: .red; case .medium: .orange; case .low: .secondary; case .none: .secondary }
    }
}
