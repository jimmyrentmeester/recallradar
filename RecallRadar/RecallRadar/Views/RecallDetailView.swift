//
//  RecallDetailView.swift
//  RecallRadar
//
//  C3/C4 — Recall-detail met handelingsadvies, foto, batch/lot, bronknop en
//  disclaimer (P0-4). C3 levert de werkende kern; C4 verfijnt (galerij, delen,
//  toegankelijkheid).
//

import SwiftUI

struct RecallDetailView: View {
    let alert: RecallAlert
    let index: RecallIndex

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                header
                actionAdvice
                details
                sources
                disclaimer
            }
            .padding()
        }
        .navigationTitle(index.categoryLabel(alert.category))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var hero: some View {
        if let url = alert.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFit()
                case .failure:
                    placeholder
                default:
                    ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 260)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var placeholder: some View {
        Image(systemName: CategoryStyle.icon(alert.category))
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 160)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(alert.displayTitle)
                .font(.title2.bold())
            HStack(spacing: 8) {
                Label(index.riskLabel(alert.riskType), systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(RiskStyle.color(alert.riskType).opacity(0.15), in: Capsule())
                    .foregroundStyle(RiskStyle.color(alert.riskType))
                Label(index.categoryLabel(alert.category), systemImage: CategoryStyle.icon(alert.category))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let desc = alert.riskDesc, !desc.isEmpty {
                Text(desc).font(.body).foregroundStyle(.secondary)
            }
        }
    }

    private var actionAdvice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Wat moet je doen?", systemImage: "checklist")
                .font(.headline)
            Text(alert.measure)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            detailRow("Merk", alert.displayBrand)
            detailRow("Model/type", alert.displayModel)
            detailRow("Batch/lot", alert.batchLot)
            detailRow("Barcode", alert.barcode)
            detailRow("Meldend land", alert.country)
            detailRow("Gepubliceerd", alert.publishedAt.formatted(date: .abbreviated, time: .omitted))
            detailRow("Alertnummer", alert.alertNumber)
        }
    }

    @ViewBuilder private func detailRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label).foregroundStyle(.secondary)
                Spacer()
                Text(value).multilineTextAlignment(.trailing)
            }
            .font(.subheadline)
            .padding(.vertical, 8)
            Divider()
        }
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(sourceLinks, id: \.url) { link in
                Link(destination: link.url) {
                    Label("Bekijk bij \(link.label)", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private struct SourceLink { let label: String; let url: URL }

    private var sourceLinks: [SourceLink] {
        // Toon alle bronnen (bij cross-source merge beide), Fase 1 §9.
        let urls = (alert.mergedSourceURLs ?? [alert.sourceURLString])
        return urls.compactMap { s in
            guard let u = URL(string: s) else { return nil }
            let label = s.contains("nvwa.nl") ? "NVWA" : "EU Safety Gate"
            return SourceLink(label: label, url: u)
        }
    }

    private var disclaimer: some View {
        Text(index.disclaimer)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
