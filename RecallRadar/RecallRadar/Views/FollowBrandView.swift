//
//  FollowBrandView.swift
//  RecallRadar
//
//  Een merk volgen — met autocomplete uit de index (voorkomt typo's, betere matching).
//

import SwiftUI
import SwiftData

struct FollowBrandView: View {
    let store: RecallStore
    var onFinish: (() -> Void)? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var subscriptions: [Subscription]

    @State private var newBrand = ""

    private var data: UserDataStore { UserDataStore(context) }
    private var followedBrands: [Subscription] { subscriptions.filter { $0.kind == .brand } }

    private var suggestions: [String] {
        let q = Normalizer.text(newBrand)
        guard q.count >= 2 else { return [] }
        let followedKeys = Set(followedBrands.map { Normalizer.text($0.value) })
        return store.brandNames
            .filter { Normalizer.text($0).contains(q) && !followedKeys.contains(Normalizer.text($0)) }
            .prefix(6).map { $0 }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Merk toevoegen", text: $newBrand)
                        .textInputAutocapitalization(.words)
                        .onSubmit(add)
                    Button("Voeg toe", action: add)
                        .disabled(newBrand.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ForEach(suggestions, id: \.self) { s in
                    Button { newBrand = s; add() } label: {
                        Label(s, systemImage: "magnifyingglass").foregroundStyle(DS.Color.brandPrimary)
                    }
                }
            } footer: {
                Text("Kies bij voorkeur een merk uit de suggesties — dan herkennen we recalls beter.")
            }

            if !followedBrands.isEmpty {
                Section("Je volgt") {
                    ForEach(followedBrands) { sub in Text(sub.value) }
                        .onDelete { idx in idx.map { followedBrands[$0] }.forEach(data.delete) }
                }
            }
        }
        .navigationTitle("Merk volgen")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button { (onFinish ?? { dismiss() })() } label: { Text("Klaar").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).padding().background(.bar)
        }
    }

    private func add() {
        data.addSubscription(kind: .brand, value: newBrand)
        newBrand = ""
    }
}
