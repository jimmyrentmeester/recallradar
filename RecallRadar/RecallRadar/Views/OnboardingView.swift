//
//  OnboardingView.swift
//  RecallRadar
//
//  D1 v2 — Stapsgewijze onboarding: wat de app doet + wat je mag verwachten
//  (scanbaar), privacy, categorie-keuze en afronding met meldingen. Rustige toon.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    let store: RecallStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0
    @State private var selected: Set<String> = []

    private let lastPage = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    privacyPage.tag(1)
                    categoriesPage.tag(2)
                    readyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.snappy, value: page)

                bottomBar
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if page < lastPage { Button("Overslaan") { finish(requestNotifications: false) } }
                }
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Pagina's

    private var welcomePage: some View {
        infoPage(
            icon: "dot.radiowaves.up.forward",
            title: "Recall Radar",
            subtitle: "We waarschuwen je alleen als jóuw spullen worden teruggeroepen — geen ruis.",
            bullets: [
                ("bell.badge", "Gerichte meldingen", "Alleen recalls die jouw producten of categorieën raken."),
                ("bolt.fill", "Automatisch", "De app kijkt op de achtergrond mee; jij hoeft niets te doen."),
                ("checkmark.seal.fill", "Betrouwbare bron", "EU Safety Gate & NVWA, dagelijks bijgewerkt."),
            ]
        )
    }

    private var privacyPage: some View {
        infoPage(
            icon: "lock.shield.fill",
            title: "Jouw spullen blijven privé",
            subtitle: "Je hoeft niet te uploaden wat je bezit.",
            bullets: [
                ("iphone", "Op je toestel", "Je productlijst blijft lokaal en in je eigen iCloud."),
                ("person.crop.circle.badge.xmark", "Geen account", "Direct beginnen, geen login nodig."),
                ("hand.raised.fill", "Geen tracking", "We sturen je lijst nooit naar ons."),
            ]
        )
    }

    private var categoriesPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.md) {
                Text("Waar letten we op?").font(.title.bold())
                Text("Kies categorieën die je belangrijk vindt. Later voeg je losse producten of merken toe.")
                    .font(.subheadline).foregroundStyle(DS.Color.textSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(categoryCodes, id: \.self) { code in categoryCard(code) }
                }
                .padding(.top, DS.Space.xs)
            }
            .padding()
        }
    }

    private var readyPage: some View {
        infoPage(
            icon: "checkmark.circle.fill",
            iconColor: DS.Color.reassureGreen,
            title: "Je radar staat aan",
            subtitle: selected.isEmpty
                ? "Je kunt straks producten, categorieën of merken toevoegen om bewaakt te worden."
                : "We houden je \(selected.count) categorie\(selected.count == 1 ? "" : "ën") in de gaten. Voeg later je eigen producten toe voor preciezere waarschuwingen.",
            bullets: [
                ("bell.fill", "Meldingen", "Zet meldingen aan zodat we je kunnen waarschuwen — ook als de app dicht is."),
            ]
        )
    }

    // MARK: - Bouwstenen

    private func infoPage(icon: String, iconColor: Color = DS.Color.brandPrimary, title: String,
                          subtitle: String, bullets: [(String, String, String)]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Image(systemName: icon)
                    .font(.system(size: 64)).symbolRenderingMode(.hierarchical)
                    .foregroundStyle(iconColor)
                    .padding(.top, DS.Space.xxl)
                    .accessibilityHidden(true)
                Text(title).font(.largeTitle.bold())
                Text(subtitle).font(.title3).foregroundStyle(DS.Color.textSecondary)
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    ForEach(bullets, id: \.0) { b in
                        HStack(alignment: .top, spacing: DS.Space.md) {
                            Image(systemName: b.0).font(.title3).foregroundStyle(DS.Color.brandPrimary).frame(width: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(b.1).font(.headline)
                                Text(b.2).font(.subheadline).foregroundStyle(DS.Color.textSecondary)
                            }
                        }
                    }
                }
                .padding(.top, DS.Space.sm)
                Spacer(minLength: DS.Space.xxl)
            }
            .padding(.horizontal, DS.Space.xl)
        }
    }

    private var bottomBar: some View {
        Button {
            if page < lastPage { withAnimation { page += 1 } }
            else { finish(requestNotifications: true) }
        } label: {
            Text(page < lastPage ? "Volgende" : "Aan de slag")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .background(.bar)
    }

    private var categoryCodes: [String] {
        store.index.categories.keys.sorted {
            let ay = store.index.categories[$0]?.youngFamily ?? false
            let by = store.index.categories[$1]?.youngFamily ?? false
            if ay != by { return ay }
            return store.index.categoryLabel($0) < store.index.categoryLabel($1)
        }
    }

    private func categoryCard(_ code: String) -> some View {
        let on = selected.contains(code)
        return Button {
            if on { selected.remove(code) } else { selected.insert(code) }
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
            .overlay(alignment: .topTrailing) {
                if store.index.categories[code]?.youngFamily == true {
                    Text("populair").font(.caption2.weight(.bold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.tint, in: Capsule()).foregroundStyle(.white).padding(6)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func finish(requestNotifications: Bool) {
        let data = UserDataStore(context)
        for code in selected { data.addSubscription(kind: .category, value: code) }
        UserDefaults.standard.set(true, forKey: "didOnboard")
        if requestNotifications {
            Task { _ = await NotificationService.requestAuthorization() }
        }
        dismiss()
    }
}
