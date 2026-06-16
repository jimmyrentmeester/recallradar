//
//  HomeView.swift
//  RecallRadar
//
//  Thuis = overzichtelijk dashboard: status, te bevestigen matches, "Voor jou", en
//  één primaire actie (+ Toevoegen). Beheer van wat je bewaakt staat in "Mijn spullen".
//

import SwiftUI
import SwiftData

struct HomeView: View {
    let store: RecallStore
    @Binding var selection: ContentView.Tab
    @Environment(\.modelContext) private var context
    @Query(sort: \TrackedProduct.addedAt, order: .reverse) private var products: [TrackedProduct]
    @Query(sort: \Subscription.addedAt, order: .reverse) private var subscriptions: [Subscription]

    @State private var matches: [ScoredAlert] = []
    @State private var notifAuthorized = true
    @State private var showAdd = false

    private var data: UserDataStore { UserDataStore(context) }
    private var monitoring: Bool { !products.isEmpty || !subscriptions.isEmpty }

    private var matchKey: String {
        let p = products.map { "\($0.id.uuidString):\($0.brand ?? ""):\($0.model ?? ""):\($0.barcode ?? ""):\($0.category):\($0.confirmedMatches.count):\($0.suppressedMatches.count)" }.joined(separator: "|")
        let s = subscriptions.map { "\($0.kindRaw)=\($0.value)" }.joined(separator: "|")
        return "\(store.index.generatedAt.timeIntervalSince1970)#\(store.alerts.count)#\(p)#\(s)"
    }
    private func recompute() async {
        guard !store.alerts.isEmpty else { matches = []; return }
        let snap = MatchBridge.snapshot(products: products, subscriptions: subscriptions)
        let alerts = store.alerts, config = store.index.matchingConfig
        matches = await Task.detached(priority: .userInitiated) {
            MatchBridge.compute(products: snap.products, brandFollows: snap.brandFollows, alerts: alerts, config: config)
        }.value
    }
    private var pending: [ScoredAlert] { matches.filter { $0.kind == .product && $0.tier == .medium } }
    private var forYou: [ScoredAlert] { matches.filter { $0.tier == .high || $0.kind == .brandFollow } }
    private func product(for s: ScoredAlert) -> TrackedProduct? {
        guard let pid = s.productID else { return nil }
        return products.first { $0.id.uuidString == pid }
    }

    var body: some View {
        NavigationStack {
            List {
                heroSection
                if !notifAuthorized && monitoring { notifSection }
                if !pending.isEmpty { confirmSection }
                if !forYou.isEmpty { matchesSection }
                if monitoring { trackedSummarySection } else { getStartedSection }
            }
            .navigationTitle("Recall Radar")
            .navigationDestination(for: ScoredAlert.self) { s in
                RecallDetailView(alert: s.alert, index: store.index, tier: s.tier, signals: s.signals)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Label("Toevoegen", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddHubView(store: store) }
            .task { notifAuthorized = await NotificationService.isAuthorized() }
            .task(id: matchKey) { await recompute() }
        }
    }

    // MARK: - Secties

    private var heroSection: some View {
        Section {
            StatusHeroCard(kind: heroKind)
                .listRowInsets(EdgeInsets(top: DS.Space.sm, leading: DS.Space.lg, bottom: DS.Space.sm, trailing: DS.Space.lg))
                .listRowBackground(Color.clear)
        }
    }
    private var heroKind: StatusHeroCard.Kind {
        let n = pending.count + forYou.count
        if n > 0 { return .attention(count: n) }
        if monitoring { return .protected(products: products.count, follows: subscriptions.count) }
        return .setup
    }

    private var notifSection: some View {
        Section {
            Button {
                Task { _ = await NotificationService.requestAuthorization(); notifAuthorized = await NotificationService.isAuthorized() }
            } label: { Label("Zet meldingen aan", systemImage: "bell.badge") }
        } footer: {
            Text("Zo waarschuwen we je zodra een recall jouw spullen raakt.")
        }
    }

    private var confirmSection: some View {
        Section {
            ForEach(pending) { scored in
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    if let p = product(for: scored) {
                        Text("Lijkt op: \(p.displayName)").font(.caption).foregroundStyle(DS.Color.textSecondary)
                    }
                    NavigationLink(value: scored) { RecallRow(alert: scored.alert, index: store.index) }
                    HStack {
                        Button { if let p = product(for: scored) { data.confirmMatch(p, alertID: scored.alert.id) } } label: {
                            Label("Ja, van mij", systemImage: "checkmark")
                        }.buttonStyle(.borderedProminent).controlSize(.small)
                        Button { if let p = product(for: scored) { data.suppressMatch(p, alertID: scored.alert.id) } } label: {
                            Label("Nee", systemImage: "xmark")
                        }.buttonStyle(.bordered).controlSize(.small)
                        Spacer()
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Is dit van jou?")
        } footer: {
            Text("Mogelijke matches met je producten. Bevestigen of wegklikken verscherpt toekomstige meldingen.")
        }
    }

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

    /// Compacte "je bewaakt …" met doorstap naar het beheerscherm.
    private var trackedSummarySection: some View {
        Section {
            Button { selection = .manage } label: {
                HStack {
                    Label("Je bewaakt", systemImage: "shippingbox.fill")
                    Spacer()
                    Text("\(products.count) prod. · \(followCount) gevolgd")
                        .foregroundStyle(DS.Color.textSecondary)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.Color.textTertiary)
                }
            }
            .tint(DS.Color.textPrimary)
        }
    }
    private var followCount: Int { subscriptions.count }

    private var getStartedSection: some View {
        Section {
            Button { showAdd = true } label: {
                Label("Voeg je eerste product of categorie toe", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .listRowInsets(EdgeInsets(top: DS.Space.sm, leading: DS.Space.lg, bottom: DS.Space.sm, trailing: DS.Space.lg))
            .listRowBackground(Color.clear)
        }
    }
}
