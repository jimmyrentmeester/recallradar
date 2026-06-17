//
//  DismissedAlert.swift
//  RecallRadar
//
//  Onthoudt welke dashboard-matches de gebruiker heeft afgehandeld/verborgen, zodat
//  ze van "Thuis" verdwijnen (de recall blijft vindbaar in detail/feed).
//  CloudKit-compatibel: defaults overal.
//

import Foundation
import SwiftData

@Model
final class DismissedAlert {
    var alertID: String = ""
    var dismissedAt: Date = Date()

    init(alertID: String, dismissedAt: Date = Date()) {
        self.alertID = alertID
        self.dismissedAt = dismissedAt
    }
}
