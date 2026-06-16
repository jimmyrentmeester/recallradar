//
//  DesignSystem.swift
//  RecallRadar
//
//  Designtokens conform DESIGN_Recall-Radar.md §2 + ASSETS_Recall-Radar.md.
//  Kleuren ALTIJD via named Color-assets (light+dark) — nooit hardcoded hex in views.
//  Spacing/radius via DS.Space/DS.Radius. Grondhouding: rustig; risicokleur is uitzondering.
//

import SwiftUI

enum DS {
    enum Color {
        static let brandPrimary = SwiftUI.Color("brandPrimary")
        static let brandPrimaryMuted = SwiftUI.Color("brandPrimaryMuted")
        static let bgPrimary = SwiftUI.Color("bgPrimary")
        static let bgSecondary = SwiftUI.Color("bgSecondary")
        static let bgElevated = SwiftUI.Color("bgElevated")
        static let separator = SwiftUI.Color("separator")
        static let textPrimary = SwiftUI.Color("textPrimary")
        static let textSecondary = SwiftUI.Color("textSecondary")
        static let textTertiary = SwiftUI.Color("textTertiary")
        static let riskHigh = SwiftUI.Color("riskHigh")
        static let riskHighBg = SwiftUI.Color("riskHighBg")
        static let riskMedium = SwiftUI.Color("riskMedium")
        static let riskMediumBg = SwiftUI.Color("riskMediumBg")
        static let riskLow = SwiftUI.Color("riskLow")
        static let riskLowBg = SwiftUI.Color("riskLowBg")
        static let reassureGreen = SwiftUI.Color("reassureGreen")
        static let reassureGreenBg = SwiftUI.Color("reassureGreenBg")
    }
    enum Space {
        static let xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 12
        static let lg: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32
    }
    enum Radius { static let sm: CGFloat = 8, md: CGFloat = 12, lg: CGFloat = 20 }
}

/// Presentatie van een match-trede / status (kleur + symbool + label, §2.3 / §6.3).
/// Drievoudige codering: nooit kleur als enig signaal.
struct RiskPresentation {
    let color: Color
    let bg: Color
    let symbol: String
    let label: String

    static func tier(_ t: MatchTier) -> RiskPresentation? {
        switch t {
        case .high: RiskPresentation(color: DS.Color.riskHigh, bg: DS.Color.riskHighBg,
                                     symbol: "exclamationmark.octagon.fill", label: "Ernstig risico")
        case .medium: RiskPresentation(color: DS.Color.riskMedium, bg: DS.Color.riskMediumBg,
                                       symbol: "exclamationmark.triangle.fill", label: "Mogelijk van jou")
        case .low: RiskPresentation(color: DS.Color.riskLow, bg: DS.Color.riskLowBg,
                                    symbol: "info.circle.fill", label: "Ter info")
        case .none: nil
        }
    }

    static let reassure = RiskPresentation(color: DS.Color.reassureGreen, bg: DS.Color.reassureGreenBg,
                                           symbol: "checkmark.shield.fill", label: "Niets geraakt")
}

/// De kern-merkcomponent: trede/status als capsule met kleur + symbool + label.
struct RiskPill: View {
    let presentation: RiskPresentation
    var body: some View {
        Label(presentation.label, systemImage: presentation.symbol)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, DS.Space.xs)
            .foregroundStyle(presentation.color)
            .background(presentation.bg, in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(presentation.label)
    }
}

/// Geruststellingskaart bovenaan de home — de emotionele kern (gemoedsrust).
struct StatusHeroCard: View {
    enum Kind: Equatable {
        case protected
        case attention(count: Int)
        case setup
    }
    let kind: Kind

    var body: some View {
        HStack(spacing: DS.Space.lg) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(DS.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(DS.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var icon: String {
        switch kind {
        case .protected: "checkmark.shield.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .setup: "shield.lefthalf.filled"
        }
    }
    private var tint: Color {
        switch kind {
        case .protected: DS.Color.reassureGreen
        case .attention: DS.Color.riskMedium
        case .setup: DS.Color.brandPrimary
        }
    }
    private var bg: Color {
        switch kind {
        case .protected: DS.Color.reassureGreenBg
        case .attention: DS.Color.riskMediumBg
        case .setup: DS.Color.brandPrimaryMuted
        }
    }
    private var title: String {
        switch kind {
        case .protected: "Je bent beschermd"
        case .attention(let n): "\(n) recall\(n == 1 ? "" : "s") voor jou"
        case .setup: "Nog niets bewaakt"
        }
    }
    private var subtitle: String {
        switch kind {
        case .protected: "We controleren je spullen elke dag tegen nieuwe recalls."
        case .attention: "Bekijk hieronder wat je moet doen."
        case .setup: "Voeg een product toe of volg een categorie om bewaakt te worden."
        }
    }
}
