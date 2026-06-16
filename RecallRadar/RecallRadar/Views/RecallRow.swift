//
//  RecallRow.swift
//  RecallRadar
//
//  C3 — Eén regel in de feed: foto-thumbnail, titel, categorie/risico en datum.
//

import SwiftUI

struct RecallRow: View {
    let alert: RecallAlert
    let index: RecallIndex

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.displayTitle)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Image(systemName: CategoryStyle.icon(alert.category))
                        .foregroundStyle(.secondary)
                    Text(index.categoryLabel(alert.category))
                        .lineLimit(1)
                    Text("·").foregroundStyle(.tertiary)
                    Text(index.riskLabel(alert.riskType))
                        .foregroundStyle(RiskStyle.color(alert.riskType))
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(alert.publishedAt, style: .date)
                    if alert.source == .nvwa {
                        Text("NVWA").sourceBadge()
                    } else {
                        Text("EU Safety Gate").sourceBadge()
                    }
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)
            if let url = alert.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    default:
                        Image(systemName: CategoryStyle.icon(alert.category))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: CategoryStyle.icon(alert.category))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private extension Text {
    func sourceBadge() -> some View {
        self.font(.caption2.weight(.medium))
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(.quaternary, in: Capsule())
    }
}
