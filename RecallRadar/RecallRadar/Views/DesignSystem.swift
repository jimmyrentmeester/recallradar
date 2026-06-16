//
//  DesignSystem.swift
//  RecallRadar
//
//  Gedeelde design-tokens voor consistentie (HIG "Consistency"/"Harmony"):
//  één set hoekradii + een herbruikbare statuskaart. Kleuren blijven semantisch.
//

import SwiftUI

enum DS {
    /// Concentrische hoekradii (groot → klein).
    static let cardRadius: CGFloat = 16
    static let thumbRadius: CGFloat = 12
}

/// Geruststellingskaart bovenaan de home — de emotionele kern (gemoedsrust).
struct StatusHeroCard: View {
    enum Kind: Equatable {
        case protected(products: Int, follows: Int)
        case attention(count: Int)
        case setup
    }
    let kind: Kind

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: DS.cardRadius))
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
        case .protected: .green
        case .attention: .red
        case .setup: .accentColor
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
        case let .protected(products, follows):
            let p = "\(products) product\(products == 1 ? "" : "en")"
            let f = "\(follows) gevolgd"
            return "We houden \(p) en \(f) in de gaten."
        case .attention:
            return "Bekijk wat je moet doen."
        case .setup:
            return "Voeg een product toe of volg een categorie om bewaakt te worden."
        }
    }
}
