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
    @Query private var dismissedAlerts: [DismissedAlert]

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
    private var dismissedIDs: Set<String> { Set(dismissedAlerts.map(\.alertID)) }
    private var pending: [ScoredAlert] {
        matches.filter { $0.kind == .product && $0.tier == .medium && !dismissedIDs.contains($0.alert.id) }
    }
    private var forYou: [ScoredAlert] {
        matches.filter { ($0.tier == .high || $0.kind == .brandFollow) && !dismissedIDs.contains($0.alert.id) }
    }
    private func product(for s: ScoredAlert) -> TrackedProduct? {
        guard let pid = s.productID else { return nil }
        return products.first { $0.id.uuidString == pid }
    }

    var body: some View {
        NavigationStack {
            List {
                brandHeaderSection
                heroSection
                if !pending.isEmpty { confirmSection }
                if !forYou.isEmpty { matchesSection }
                addCTASection
                if monitoring { trackedSummarySection }
                exploreSection
                if !notifAuthorized && monitoring { notifSection }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ScoredAlert.self) { s in
                RecallDetailView(alert: s.alert, index: store.index, tier: s.tier, signals: s.signals)
            }
            .sheet(isPresented: $showAdd) { AddHubView(store: store) }
            .task { notifAuthorized = await NotificationService.isAuthorized() }
            .task(id: matchKey) { await recompute() }
        }
    }

    // MARK: - Secties

    /// Gebrande dashboard-header i.p.v. de kale systeem-titel: radar-merkje + naam + versheid.
    private var brandHeaderSection: some View {
        Section {
            HStack(spacing: DS.Space.md) {
                ZStack {
                    Circle().fill(DS.Color.brandPrimaryMuted)
                    Image(systemName: "dot.radiowaves.up.forward")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(DS.Color.brandPrimary)
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recall Radar")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(freshnessText)
                        .font(.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .listRowInsets(EdgeInsets(top: DS.Space.sm, leading: DS.Space.lg, bottom: DS.Space.xs, trailing: DS.Space.lg))
            .listRowBackground(Color.clear)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Recall Radar. \(freshnessText)")
        }
    }

    private var freshnessText: String {
        store.index.count > 0 ? "Dagelijks bijgewerkt · \(store.lastUpdatedText.replacingOccurrences(of: "Laatst bijgewerkt ", with: ""))"
                              : "Recalls laden…"
    }

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
        if monitoring { return .protected }
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
                    HStack(spacing: DS.Space.sm) {
                        Button { if let p = product(for: scored) { data.confirmMatch(p, alertID: scored.alert.id) } } label: {
                            Label("Ja, van mij", systemImage: "checkmark").frame(maxWidth: .infinity)
                        }.buttonStyle(.borderedProminent)
                        Button { if let p = product(for: scored) { data.suppressMatch(p, alertID: scored.alert.id) } } label: {
                            Label("Nee", systemImage: "xmark").frame(maxWidth: .infinity)
                        }.buttonStyle(.bordered)
                    }
                    .controlSize(.small)
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
        Section {
            ForEach(forYou.prefix(30)) { scored in
                NavigationLink(value: scored) {
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        if let p = RiskPresentation.tier(scored.tier) { RiskPill(presentation: p) }
                        RecallRow(alert: scored.alert, index: store.index)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button { data.dismissAlert(scored.alert.id) } label: { Label("Gereed", systemImage: "checkmark") }
                        .tint(DS.Color.reassureGreen)
                }
            }
        } header: {
            Text("Voor jou")
        } footer: {
            Text("Afgehandeld? Veeg naar links en tik op Gereed om het hier te verbergen.")
        }
    }

    /// Prominente primaire actie (vervangt de kleine nav-"+").
    private var addCTASection: some View {
        Section {
            Button { showAdd = true } label: {
                Label(monitoring ? "Product of categorie toevoegen" : "Voeg je eerste product of categorie toe",
                      systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .listRowInsets(EdgeInsets(top: DS.Space.sm, leading: DS.Space.lg, bottom: DS.Space.sm, trailing: DS.Space.lg))
            .listRowBackground(Color.clear)
        }
    }

    /// Compacte "je bewaakt …" met doorstap naar het beheerscherm.
    private var trackedSummarySection: some View {
        Section {
            Button { selection = .manage } label: {
                HStack {
                    Label("Mijn spullen", systemImage: "shippingbox.fill")
                    Spacer()
                    Text(monitoredSummary).foregroundStyle(DS.Color.textSecondary)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.Color.textTertiary)
                }
            }
            .tint(DS.Color.textPrimary)
        }
    }

    /// Voluit, zonder afkortingen; nul-onderdelen weggelaten.
    private var monitoredSummary: String {
        let cats = subscriptions.filter { $0.kind == .category }.count
        let brands = subscriptions.filter { $0.kind == .brand }.count
        var parts: [String] = []
        if products.count > 0 { parts.append("\(products.count) product\(products.count == 1 ? "" : "en")") }
        if cats > 0 { parts.append("\(cats) categorie\(cats == 1 ? "" : "ën")") }
        if brands > 0 { parts.append("\(brands) merk\(brands == 1 ? "" : "en")") }
        return parts.isEmpty ? "niets" : parts.joined(separator: " · ")
    }

    /// Verwijst naar de volledige feed — vult de ruimte met een nuttige actie.
    private var exploreSection: some View {
        Section {
            Button { selection = .explore } label: {
                HStack {
                    Label("Verken alle recalls", systemImage: "magnifyingglass")
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(DS.Color.textTertiary)
                }
            }
            .tint(DS.Color.textPrimary)
        }
    }
}
