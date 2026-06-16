//
//  FollowCategoriesView.swift
//  RecallRadar
//
//  Categorieën volgen (multi-select). Tikken zet de follow direct aan/uit.
//

import SwiftUI
import SwiftData

struct FollowCategoriesView: View {
    let store: RecallStore
    var onFinish: (() -> Void)? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var subscriptions: [Subscription]

    private var data: UserDataStore { UserDataStore(context) }
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    private var followed: Set<String> {
        Set(subscriptions.filter { $0.kind == .category }.map(\.value))
    }
    private var categoryCodes: [String] {
        store.index.categories.keys.sorted {
            let ay = store.index.categories[$0]?.youngFamily ?? false
            let by = store.index.categories[$1]?.youngFamily ?? false
            if ay != by { return ay }
            return store.index.categoryLabel($0) < store.index.categoryLabel($1)
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(categoryCodes, id: \.self) { code in card(code) }
            }
            .padding()
        }
        .navigationTitle("Categorieën volgen")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button { (onFinish ?? { dismiss() })() } label: { Text("Klaar").frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent).controlSize(.large).padding().background(.bar)
        }
    }

    private func card(_ code: String) -> some View {
        let on = followed.contains(code)
        return Button {
            if on, let sub = subscriptions.first(where: { $0.kind == .category && $0.value == code }) {
                data.delete(sub)
            } else {
                data.addSubscription(kind: .category, value: code)
            }
        } label: {
            HStack(spacing: DS.Space.sm) {
                Image(systemName: CategoryStyle.icon(code))
                Text(store.index.categoryLabel(code)).font(.subheadline.weight(.medium)).multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if on { Image(systemName: "checkmark.circle.fill") }
            }
            .padding(DS.Space.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(on ? DS.Color.brandPrimaryMuted : DS.Color.bgSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .foregroundStyle(on ? DS.Color.brandPrimary : DS.Color.textPrimary)
        }
        .buttonStyle(.plain)
    }
}
