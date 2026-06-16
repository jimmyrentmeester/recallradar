//
//  SettingsView.swift
//  RecallRadar
//
//  §4.6 — Instellingen: notificaties per trede, privacy, bronnen & disclaimer, over.
//  HOOG-meldingen zijn altijd aan (niet uitschakelbaar).
//

import SwiftUI

struct SettingsView: View {
    let store: RecallStore

    @State private var mediumEnabled = NotifPrefs.mediumEnabled
    @State private var digestEnabled = NotifPrefs.digestEnabled
    @State private var quietHours = NotifPrefs.quietHoursEnabled
    @State private var notifAuthorized = true

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                notificationsSection
                privacySection
                sourcesSection
                aboutSection
            }
            .navigationTitle("Instellingen")
            .task { notifAuthorized = await NotificationService.isAuthorized() }
        }
    }

    // MARK: - Notificaties

    private var notificationsSection: some View {
        Section {
            if !notifAuthorized {
                Button {
                    Task { _ = await NotificationService.requestAuthorization(); notifAuthorized = await NotificationService.isAuthorized() }
                } label: { Label("Zet meldingen aan", systemImage: "bell.badge") }
            }
            LabeledContent {
                Text("Altijd aan").foregroundStyle(DS.Color.textSecondary)
            } label: {
                Label("Ernstige recalls (HOOG)", systemImage: "exclamationmark.octagon.fill")
                    .foregroundStyle(DS.Color.riskHigh)
            }
            Toggle(isOn: $mediumEnabled) {
                Label("Mogelijke matches (\"is dit van jou?\")", systemImage: "exclamationmark.triangle.fill")
            }
            .onChange(of: mediumEnabled) { _, v in NotifPrefs.mediumEnabled = v }
            Toggle(isOn: $digestEnabled) {
                Label("Maandelijkse geruststelling", systemImage: "calendar")
            }
            .onChange(of: digestEnabled) { _, v in NotifPrefs.digestEnabled = v }
            Toggle(isOn: $quietHours) {
                Label("Rustige uren (22–08)", systemImage: "moon.fill")
            }
            .onChange(of: quietHours) { _, v in NotifPrefs.quietHoursEnabled = v }
        } header: {
            Text("Meldingen")
        } footer: {
            Text("""
            • Ernstige recalls (HOOG) krijg je altijd — die kun je niet uitzetten.
            • Mogelijke matches: zachte "is dit van jou?"-vraag bij twijfelgevallen.
            • Maandelijkse geruststelling: één bericht per maand, ook als er níéts geraakt is.
            • Rustige uren: 's nachts geen meldingen — we bundelen ze tot 08:00.
            """)
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section {
            row("iphone", "Op je toestel", "Je producten en gevolgde merken/categorieën blijven op je toestel en in je eigen iCloud.")
            row("person.crop.circle.badge.xmark", "Geen account", "De kernfunctie werkt zonder in te loggen.")
            row("hand.raised", "Geen tracking", "We sturen je productlijst nooit naar ons. Geen tracking of advertentie-SDK.")
        } header: {
            Text("Privacy")
        } footer: {
            Text("Recall Radar haalt alleen de publieke recall-lijst óp; jouw spullen worden lokaal vergeleken en gaan nooit het toestel uit.")
        }
    }

    // MARK: - Bronnen & disclaimer

    private var sourcesSection: some View {
        Section {
            Link(destination: URL(string: "https://ec.europa.eu/safety-gate-alerts/")!) {
                row("link", "EU Safety Gate", "Europese non-food productwaarschuwingen (CC0)")
            }
            Link(destination: URL(string: "https://www.nvwa.nl/onderwerpen/veiligheidswaarschuwingen")!) {
                row("link", "NVWA", "Nederlandse veiligheidswaarschuwingen (CC0)")
            }
            Text(store.index.disclaimer)
                .font(.footnote).foregroundStyle(DS.Color.textSecondary)
        } header: {
            Text("Bronnen & disclaimer")
        }
    }

    // MARK: - Over

    private var aboutSection: some View {
        Section("Over") {
            LabeledContent("Recalls in index", value: "\(store.index.count)")
            LabeledContent("Laatst bijgewerkt",
                           value: store.lastUpdatedText.replacingOccurrences(of: "Laatst bijgewerkt ", with: ""))
            LabeledContent("Versie", value: appVersion)
            Link("Broncode op GitHub", destination: URL(string: "https://github.com/jimmyrentmeester/recallradar")!)
        }
    }

    private func row(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: DS.Space.md) {
            Image(systemName: icon).frame(width: 26).foregroundStyle(DS.Color.brandPrimary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(DS.Color.textPrimary)
                Text(body).font(.caption).foregroundStyle(DS.Color.textSecondary)
            }
        }
    }
}
