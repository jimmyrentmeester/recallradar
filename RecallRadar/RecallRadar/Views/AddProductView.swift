//
//  AddProductView.swift
//  RecallRadar
//
//  D2 — Product toevoegen: handmatig (merk/model/categorie/barcode) of via barcode-
//  scan. Bij een gescande/ingevoerde barcode die de index kent, worden merk en
//  categorie voorin gevuld (Fase 1 §2.3).
//

import SwiftUI
import SwiftData

struct AddProductView: View {
    let store: RecallStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var model = ""
    @State private var barcode = ""
    @State private var category = "overig"
    @State private var showScanner = false
    @State private var scanNote: String?

    private var categoryCodes: [String] {
        store.index.categories.keys.sorted {
            store.index.categoryLabel($0) < store.index.categoryLabel($1)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Merk", text: $brand)
                        .textInputAutocapitalization(.words)
                    TextField("Model / type (optioneel)", text: $model)
                    Picker("Categorie", selection: $category) {
                        ForEach(categoryCodes, id: \.self) { code in
                            Text(store.index.categoryLabel(code)).tag(code)
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Barcode (EAN/UPC)", text: $barcode)
                            .keyboardType(.numberPad)
                        if BarcodeScanner.isScanningAvailable {
                            Button {
                                showScanner = true
                            } label: {
                                Image(systemName: "barcode.viewfinder")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    if let note = scanNote {
                        Text(note).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Barcode")
                } footer: {
                    if !BarcodeScanner.isScanningAvailable {
                        Text("Scannen werkt op een echt toestel met camera.")
                    }
                }
            }
            .navigationTitle("Product toevoegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") { save() }
                        .disabled(brand.trimmingCharacters(in: .whitespaces).isEmpty
                                  && barcode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showScanner) {
                scannerSheet
            }
        }
    }

    private var scannerSheet: some View {
        NavigationStack {
            BarcodeScannerView { payload in
                applyScanned(payload)
                showScanner = false
            }
            .ignoresSafeArea()
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { showScanner = false }
                }
            }
        }
    }

    private func applyScanned(_ payload: String) {
        guard let valid = Normalizer.barcode(payload) else {
            scanNote = "Onleesbare of ongeldige barcode — vul handmatig in."
            return
        }
        barcode = valid
        prefillFromIndex(barcode: valid)
    }

    /// Vult merk/categorie voorin als de index deze barcode kent.
    private func prefillFromIndex(barcode: String) {
        if let hit = store.alerts.first(where: { $0.barcode == barcode }) {
            if brand.isEmpty, let b = hit.displayBrand { brand = b }
            category = hit.category
            scanNote = "Gevonden in de index: \(hit.displayTitle)."
        } else {
            scanNote = "Barcode \(barcode) herkend (nog niet in de recall-index)."
        }
    }

    private func save() {
        let store = UserDataStore(context)
        store.addProduct(
            brand: brand,
            model: model,
            category: category,
            barcode: barcode.isEmpty ? nil : Normalizer.barcode(barcode) ?? barcode
        )
        dismiss()
    }
}
