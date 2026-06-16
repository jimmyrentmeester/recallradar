//
//  RecallRadarApp.swift
//  RecallRadar
//
//  Created by Jimmy Rentmeester on 15/06/2026.
//

import SwiftUI
import SwiftData

@main
struct RecallRadarApp: App {
    // C2 — SwiftData + CloudKit-container (valt terug op lokaal als de iCloud-
    // capability nog niet actief is).
    let container = Persistence.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
