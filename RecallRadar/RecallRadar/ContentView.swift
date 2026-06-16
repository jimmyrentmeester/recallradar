//
//  ContentView.swift
//  RecallRadar
//
//  Vier tabs: Thuis (dashboard) · Mijn spullen (beheer) · Verken (feed) · Instellingen.
//  Toont éénmalig de onboarding (D1).
//

import SwiftUI

struct ContentView: View {
    enum Tab: Hashable { case home, manage, explore, settings }

    @State private var store = RecallStore()
    @State private var selection: Tab = .home
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "didOnboard")

    var body: some View {
        TabView(selection: $selection) {
            HomeView(store: store, selection: $selection)
                .tabItem { Label("Thuis", systemImage: "house.fill") }
                .tag(Tab.home)

            ManageView(store: store)
                .tabItem { Label("Mijn spullen", systemImage: "shippingbox.fill") }
                .tag(Tab.manage)

            FeedView(store: store)
                .tabItem { Label("Verken", systemImage: "magnifyingglass") }
                .tag(Tab.explore)

            SettingsView(store: store)
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .task { await store.load() }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(store: store)
        }
    }
}

#Preview {
    ContentView()
}
