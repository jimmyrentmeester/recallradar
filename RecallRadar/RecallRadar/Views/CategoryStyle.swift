//
//  CategoryStyle.swift
//  RecallRadar
//
//  Presentatie-helpers voor categorie-iconen en hazard-accent. Hazard-kleur wordt
//  ALLEEN in het recall-detail (accentband) gebruikt — nooit in de feed (rustig).
//

import SwiftUI

enum CategoryStyle {
    static func icon(_ code: String) -> String {
        switch code {
        case "kinderen_speelgoed": "teddybear.fill"
        case "verzorging_mode": "tshirt.fill"
        case "auto_vervoer": "car.fill"
        case "elektronica_smarthome": "powerplug.fill"
        case "wonen_interieur": "sofa.fill"
        case "chemie": "testtube.2"
        case "hobby_sport_tuin": "figure.outdoor.cycle"
        case "veiligheid_bescherming": "shield.lefthalf.filled"
        case "vuurwerk_brand": "flame.fill"
        case "witgoed_keuken": "fork.knife"
        default: "shippingbox.fill"
        }
    }
}

/// Hazard (risico-type) → accent voor het detailscherm. Ernstige gevaren krijgen de
/// terracotta `riskHigh`, informatief de neutrale `riskLow`, rest amber `riskMedium`.
enum HazardStyle {
    private static let severe: Set<String> = [
        "verstikking", "brand_hitte", "elektrisch", "beknelling", "verdrinking",
    ]
    static func color(_ riskType: String) -> Color {
        if severe.contains(riskType) { return DS.Color.riskHigh }
        if riskType == "overig_risico" { return DS.Color.riskLow }
        return DS.Color.riskMedium
    }
    static func background(_ riskType: String) -> Color {
        if severe.contains(riskType) { return DS.Color.riskHighBg }
        if riskType == "overig_risico" { return DS.Color.riskLowBg }
        return DS.Color.riskMediumBg
    }
    static func symbol(_ riskType: String) -> String {
        riskType == "overig_risico" ? "info.circle.fill" : "exclamationmark.triangle.fill"
    }
}
