//
//  OnboardingView.swift
//  RecallRadar
//
//  D1 — Onboarding-hoofdpad (0 friction): kies categorieën om te volgen, zonder
//  een product in te voeren. Verschijnt één keer bij de eerste start.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    let store: RecallStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<String> = []

    private var categoryCodes: [String] {
        store.index.categories.keys.sorted {
            let ay = store.index.categories[$0]?.youngFamily ?? false
            let by = store.index.categories[$1]?.youngFamily ?? false
            if ay != by { return ay } // jonge-gezin-spits eerst
            return store.index.categoryLabel($0) < store.index.categoryLabel($1)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welkom bij Recall Radar")
                        .font(.largeTitle.bold())
                    Text("Kies de categorieën die je belangrijk vindt. Je krijgt alleen recalls die er voor jóu toe doen — geen ruis. Later kun je losse producten of merken toevoegen.")
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(categoryCodes, id: \.self) { code in
                            categoryCard(code)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: finish) {
                    Text(selected.isEmpty ? "Sla over" : "Volg \(selected.count) categorie\(selected.count == 1 ? "" : "ën")")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
                .background(.bar)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private func categoryCard(_ code: String) -> some View {
        let on = selected.contains(code)
        let young = store.index.categories[code]?.youngFamily ?? false
        return Button {
            if on { selected.remove(code) } else { selected.insert(code) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: CategoryStyle.icon(code))
                Text(store.index.categoryLabel(code))
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if on { Image(systemName: "checkmark.circle.fill") }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((on ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground)),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .topTrailing) {
                if young {
                    Text("populair")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.tint, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        let data = UserDataStore(context)
        for code in selected { data.addSubscription(kind: .category, value: code) }
        UserDefaults.standard.set(true, forKey: "didOnboard")
        // E2 — net nu de gebruiker iets gaat bewaken is hét moment om toestemming
        // voor meldingen te vragen.
        Task { _ = await NotificationService.requestAuthorization() }
        dismiss()
    }
}
