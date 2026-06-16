//
//  AddHubView.swift
//  RecallRadar
//
//  Eén gebundeld "Toevoegen"-overzicht met alle paden om bewaakt te raken.
//  Elk pad = één gerichte stap; na voltooien sluit de hele hub.
//

import SwiftUI

struct AddHubView: View {
    let store: RecallStore
    @Environment(\.dismiss) private var dismiss

    enum Path: Hashable { case scan, manual, categories, brand }

    var body: some View {
        NavigationStack {
            List {
                Section("Een product dat je bezit") {
                    NavigationLink(value: Path.scan) {
                        row("barcode.viewfinder", "Scan de barcode", "De snelste manier")
                    }
                    NavigationLink(value: Path.manual) {
                        row("pencil.and.list.clipboard", "Handmatig invoeren", "Merk, model en categorie")
                    }
                }
                Section {
                    NavigationLink(value: Path.categories) {
                        row("square.grid.2x2", "Categorieën volgen", "Bijv. speelgoed of elektronica")
                    }
                    NavigationLink(value: Path.brand) {
                        row("tag", "Een merk volgen", "Krijg recalls van dat merk")
                    }
                } header: {
                    Text("Volg breder — zonder een product in te voeren")
                }
            }
            .navigationTitle("Toevoegen")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .scan: AddProductView(store: store, autoScan: true) { dismiss() }
                case .manual: AddProductView(store: store) { dismiss() }
                case .categories: FollowCategoriesView(store: store) { dismiss() }
                case .brand: FollowBrandView(store: store) { dismiss() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Sluit") { dismiss() } }
            }
        }
    }

    private func row(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: DS.Space.md) {
            Image(systemName: icon)
                .font(.title2).frame(width: 32)
                .foregroundStyle(DS.Color.brandPrimary)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.body).foregroundStyle(DS.Color.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }
}
