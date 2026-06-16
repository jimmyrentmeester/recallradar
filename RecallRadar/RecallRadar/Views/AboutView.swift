//
//  AboutView.swift
//  RecallRadar
//
//  F1 — Altijd bereikbaar info/disclaimer-scherm met bronvermelding en privacy-
//  uitleg (P0-5/P0-7). Bevestigt: informatief niet uitputtend, bron leidend,
//  on-device, geen account, geen tracking.
//

import SwiftUI

struct AboutView: View {
    let store: RecallStore
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(store.index.disclaimer)
                        .font(.callout)
                } header: {
                    Text("Disclaimer")
                }

                Section("Bronnen") {
                    Link(destination: URL(string: "https://ec.europa.eu/safety-gate-alerts/")!) {
                        sourceRow("EU Safety Gate", "Europese non-food productwaarschuwingen (CC0)")
                    }
                    Link(destination: URL(string: "https://www.nvwa.nl/onderwerpen/veiligheidswaarschuwingen")!) {
                        sourceRow("NVWA", "Nederlandse veiligheidswaarschuwingen (CC0)")
                    }
                }

                Section("Privacy") {
                    privacyRow("iphone", "Op je toestel", "Je producten en gevolgde merken/categorieën blijven op je toestel en in je eigen iCloud.")
                    privacyRow("person.crop.circle.badge.xmark", "Geen account", "De kernfunctie werkt zonder in te loggen.")
                    privacyRow("hand.raised", "Geen tracking", "We sturen je productlijst nooit naar ons. Er is geen tracking of advertentie-SDK.")
                }

                Section("Gegevens") {
                    LabeledContent("Laatst bijgewerkt", value: store.lastUpdatedText.replacingOccurrences(of: "Laatst bijgewerkt ", with: ""))
                    LabeledContent("Recalls in index", value: "\(store.index.count)")
                    LabeledContent("Versie", value: appVersion)
                }

                Section {
                    Link("Broncode op GitHub", destination: URL(string: "https://github.com/jimmyrentmeester/recallradar")!)
                }
            }
            .navigationTitle("Over Recall Radar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") { dismiss() }
                }
            }
        }
    }

    private func sourceRow(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func privacyRow(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).frame(width: 26).foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(body).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
