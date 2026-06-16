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
    @State private var editingProduct: TrackedProduct?
    @State private var newBrand = ""
    @State private var notifAuthorized = true

    private var data: UserDataStore { UserDataStore(context) }

    @State private var matches: [ScoredAlert] = []

    /// Verandert zodra de matching-input verandert → trigger voor herberekening.
    private var matchKey: String {
        let p = products.map { "\($0.id.uuidString):\($0.brand ?? ""):\($0.model ?? ""):\($0.barcode ?? ""):\($0.category):\($0.confirmedMatches.count):\($0.suppressedMatches.count)" }.joined(separator: "|")
        let s = subscriptions.map { "\($0.kindRaw)=\($0.value)" }.joined(separator: "|")
        return "\(store.index.generatedAt.timeIntervalSince1970)#\(store.alerts.count)#\(p)#\(s)"
    }

    /// Matching draait OFF-MAIN en wordt gecachet in `matches` (geen UI-hang).
    private func recomputeMatches() async {
        guard !store.alerts.isEmpty else { matches = []; return }
        let snap = MatchBridge.snapshot(products: products, subscriptions: subscriptions)
        let alerts = store.alerts
        let config = store.index.matchingConfig
        matches = await Task.detached(priority: .userInitiated) {
            MatchBridge.compute(products: snap.products, brandFollows: snap.brandFollows, alerts: alerts, config: config)
        }.value
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
                heroSection
                if !notifAuthorized && data.isMonitoringAnything { notifSection }
                if !pending.isEmpty { confirmSection }
                if !forYou.isEmpty { matchesSection }
                categoriesSection
                brandsSection
                productsSection
            }
            .navigationTitle("Recall Radar")
            .task { notifAuthorized = await NotificationService.isAuthorized() }
            .task(id: matchKey) { await recomputeMatches() }
            .navigationDestination(for: ScoredAlert.self) { scored in
                RecallDetailView(alert: scored.alert, index: store.index, tier: scored.tier, signals: scored.signals)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Label("Product toevoegen", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddProductView(store: store) }
            .sheet(item: $editingProduct) { p in AddProductView(store: store, editing: p) }
        }
    }

    // MARK: - Statuskaart (home-header, gemoedsrust)

    private var heroSection: some View {
        Section {
            StatusHeroCard(kind: heroKind)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
        }
    }

    private var heroKind: StatusHeroCard.Kind {
        let relevant = pending.count + forYou.count
        if relevant > 0 { return .attention(count: relevant) }
        if data.isMonitoringAnything { return .protected(products: products.count, follows: subscriptions.count) }
        return .setup
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
                    NavigationLink(value: scored) {
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

    private var matchesSection: some View {
        Section("Voor jou") {
            ForEach(forYou.prefix(30)) { scored in
                NavigationLink(value: scored) {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        if let p = RiskPresentation.tier(scored.tier) { RiskPill(presentation: p) }
                        RecallRow(alert: scored.alert, index: store.index)
                    }
                }
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
                Button { editingProduct = p } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.displayName).font(.body).foregroundStyle(.primary)
                            Text(store.index.categoryLabel(p.category))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
            .onDelete { idx in idx.map { products[$0] }.forEach(data.delete) }
        }
    }
}

