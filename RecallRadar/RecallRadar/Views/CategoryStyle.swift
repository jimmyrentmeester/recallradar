//
//  CategoryStyle.swift
//  RecallRadar
//
//  C3 — Presentatie-helpers voor de interne categorie- en risicocodes (SF Symbols
//  + kleur). Puur cosmetisch; de codes/labels zelf komen uit de index-taxonomie.
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

enum RiskStyle {
    static func color(_ code: String) -> Color {
        switch code {
        case "brand_hitte", "elektrisch", "vuurwerk_brand": .orange
        case "verstikking", "beknelling", "verdrinking": .red
        case "chemisch", "microbiologisch": .purple
        case "letsel": .pink
        case "milieu": .green
        default: .secondary
        }
    }
}
