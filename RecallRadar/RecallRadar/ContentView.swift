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
            FeedView(store: store)
                .tabItem { Label("Feed", systemImage: "list.bullet.rectangle") }

            MyStuffView(store: store)
                .tabItem { Label("Mijn spullen", systemImage: "checkmark.shield") }
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
