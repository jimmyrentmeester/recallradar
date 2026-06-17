//
//  AddProductView.swift
//  RecallRadar
//
//  D2 — Product toevoegen of bewerken: handmatig (merk/model/categorie/barcode) of
//  via barcode-scan. Bij een gescande/ingevoerde barcode die de index kent worden
//  merk en categorie voorin gevuld (Fase 1 §2.3). Na bewaren volgt direct een
//  recall-check zodat je meteen weet of dit product geraakt wordt.
//

import SwiftUI
import SwiftData

struct AddProductView: View {
    let store: RecallStore
    var editing: TrackedProduct?
    /// Open meteen de scanner (vanuit de Toevoegen-hub "Scan de barcode").
    var autoScan: Bool = false
    /// Aangeroepen na opslaan i.p.v. dismiss — sluit de hele Toevoegen-hub.
    var onFinish: (() -> Void)? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var brand: String
    @State private var model: String
    @State private var barcode: String
    @State private var category: String
    @State private var showScanner = false
    @State private var scanNote: String?
    @State private var needsName = false
    @State private var matchResult: ScoredAlert?
    @State private var showMatchAlert = false
    @FocusState private var nameFocused: Bool

    init(store: RecallStore, editing: TrackedProduct? = nil, autoScan: Bool = false,
         prefillBrand: String? = nil, prefillModel: String? = nil, onFinish: (() -> Void)? = nil) {
        self.store = store
        self.editing = editing
        self.autoScan = autoScan
        self.onFinish = onFinish
        _brand = State(initialValue: editing?.brand ?? prefillBrand ?? "")
        _model = State(initialValue: editing?.model ?? prefillModel ?? "")
        _barcode = State(initialValue: editing?.barcode ?? "")
        _category = State(initialValue: editing?.category ?? "overig")
    }

    private func finish() { if let onFinish { onFinish() } else { dismiss() } }

    private var categoryCodes: [String] {
        store.index.categories.keys.sorted { store.index.categoryLabel($0) < store.index.categoryLabel($1) }
    }
    private var isEditing: Bool { editing != nil }

    /// Merk-suggesties uit de index (normaliseert input naar bekende merken → minder typo's).
    private var brandSuggestions: [String] {
        let q = Normalizer.text(brand)
        guard q.count >= 2 else { return [] }
        let matches = store.brandNames.filter { Normalizer.text($0).contains(q) }
        // Verberg als de invoer al exact een bekend merk is.
        if matches.contains(where: { Normalizer.text($0) == q }) { return [] }
        return Array(matches.prefix(5))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Merk", text: $brand)
                        .textInputAutocapitalization(.words)
                        .focused($nameFocused)
                    ForEach(brandSuggestions, id: \.self) { suggestion in
                        Button { brand = suggestion } label: {
                            Label(suggestion, systemImage: "magnifyingglass")
                                .font(.subheadline).foregroundStyle(.tint)
                        }
                    }
                    TextField("Model / type (optioneel)", text: $model)
                    Picker("Categorie", selection: $category) {
                        ForEach(categoryCodes, id: \.self) { code in
                            Text(store.index.categoryLabel(code)).tag(code)
                        }
                    }
                } header: {
                    Text("Product")
                } footer: {
                    if needsName {
                        Label("Geef dit product een merk/naam zodat je het herkent — deze barcode staat (nog) niet in de recall-index.",
                              systemImage: "pencil.line")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    HStack {
                        TextField("Barcode (EAN/UPC)", text: $barcode)
                            .keyboardType(.numberPad)
                        if BarcodeScanner.isScanningAvailable {
                            Button { showScanner = true } label: { Image(systemName: "barcode.viewfinder") }
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

                if isEditing {
                    Section {
                        Button("Verwijder product", role: .destructive) {
                            if let editing { UserDataStore(context).delete(editing); dismiss() }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Product bewerken" : "Product toevoegen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuleer") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Bewaar" : "Voeg toe") { Task { await save() } }
                        .disabled(brand.trimmingCharacters(in: .whitespaces).isEmpty
                                  && barcode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showScanner) { scannerSheet }
            .alert("Mogelijke recall gevonden", isPresented: $showMatchAlert, presenting: matchResult) { _ in
                Button("Oké") { finish() }
            } message: { m in
                Text("\(m.alert.displayTitle) — \(store.index.riskLabel(m.alert.riskType)).\n\(confidenceText(m.tier)) Bekijk 'm bij Voor jou of in Verken.")
            }
            .onAppear { if autoScan, barcode.isEmpty, BarcodeScanner.isScanningAvailable { showScanner = true } }
        }
    }

    private var scannerSheet: some View {
        NavigationStack {
            BarcodeScannerView { payload in applyScanned(payload); showScanner = false }
                .ignoresSafeArea()
                .navigationTitle("Scan barcode").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Sluit") { showScanner = false } } }
        }
    }

    private func applyScanned(_ payload: String) {
        guard let valid = Normalizer.barcode(payload) else {
            scanNote = "Onleesbare of ongeldige barcode — vul handmatig in."
            return
        }
        barcode = valid
        if let hit = store.alerts.first(where: { $0.barcode == valid }) {
            if brand.isEmpty, let b = hit.displayBrand { brand = b }
            category = hit.category
            needsName = false
            scanNote = "Gevonden in de index: \(hit.displayTitle)."
        } else {
            needsName = brand.trimmingCharacters(in: .whitespaces).isEmpty
            nameFocused = needsName
            scanNote = "Barcode \(valid) herkend (nog niet in de recall-index)."
        }
    }

    private func confidenceText(_ tier: MatchTier) -> String {
        switch tier {
        case .high: "Sterke match."
        case .medium: "Mogelijke match — bevestig of dit van jou is."
        case .low: "Zwakke match (lage zekerheid)."
        case .none: ""
        }
    }

    private func save() async {
        let data = UserDataStore(context)
        let cleanBarcode = barcode.isEmpty ? nil : (Normalizer.barcode(barcode) ?? barcode)
        if let editing {
            data.update(editing, brand: brand, model: model, category: category, barcode: cleanBarcode)
        } else {
            data.addProduct(brand: brand, model: model, category: category, barcode: cleanBarcode)
        }

        // Directe recall-check (off-main) — meteen weten of dit product geraakt wordt.
        let probe = MatchableProduct(id: "probe", brand: brand, model: model, category: category, barcode: cleanBarcode)
        let alerts = store.alerts
        let config = store.index.matchingConfig
        let hit = await Task.detached(priority: .userInitiated) {
            MatchBridge.bestMatch(product: probe, alerts: alerts, config: config)
        }.value

        if let hit {
            matchResult = hit
            showMatchAlert = true   // finish gebeurt na "Oké"
        } else {
            finish()
        }
    }
}
