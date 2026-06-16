//
//  ContentView.swift
//  RecallRadar
//
//  Hoofdscherm. C3 — host de browsebare feed. Tabs (Mijn spullen, onboarding)
//  volgen in Blok D.
//

import SwiftUI

struct ContentView: View {
    @State private var store = RecallStore()

    var body: some View {
        NavigationStack {
            FeedView(store: store)
        }
        .task { await store.load() }
    }
}

#Preview {
    ContentView()
}
