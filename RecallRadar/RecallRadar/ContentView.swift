//
//  ContentView.swift
//  RecallRadar
//
//  Hoofdscherm: tabs Feed + Mijn spullen. Toont éénmalig de onboarding (D1).
//

import SwiftUI

struct ContentView: View {
    @State private var store = RecallStore()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "didOnboard")

    var body: some View {
        TabView {
            // Persoonlijke home = openingsview (de waarde: raakt het míjn spullen?).
            MyStuffView(store: store)
                .tabItem { Label("Thuis", systemImage: "house.fill") }

            // De volledige recall-lijst als verkenscherm (zoeken/filteren).
            FeedView(store: store)
                .tabItem { Label("Verken", systemImage: "magnifyingglass") }
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
