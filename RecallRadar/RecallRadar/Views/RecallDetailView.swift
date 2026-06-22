//
//  RecallDetailView.swift
//  RecallRadar
//
//  C3/C4 — Recall-detail met handelingsadvies, foto, batch/lot, bronknop en
//  disclaimer (P0-4). C3 levert de werkende kern; C4 verfijnt (galerij, delen,
//  toegankelijkheid).
//

import SwiftUI
import SwiftData
import Translation

struct RecallDetailView: View {
    let alert: RecallAlert
    let index: RecallIndex
    /// Gezet wanneer geopend vanuit een persoonlijke match → toont de trede-pill + "waarom".
    var tier: MatchTier? = nil
    /// Gematchte signalen voor "Waarom zie ik dit?" (§3.6).
    var signals: [String] = []

    @Environment(\.modelContext) private var context
    @Query private var products: [TrackedProduct]

    // On-device vertaling van de Engelse risico-omschrijving (Safety Gate) → NL.
    @State private var translatedDesc: String?
    @State private var translationConfig: TranslationSession.Configuration?
    @State private var justAdded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                gallery
                header
                iHaveThis
                actionAdvice
                if !signals.isEmpty { confidence }
                details
                sources
                disclaimer
            }
            .padding()
        }
        .navigationTitle(index.categoryLabel(alert.category))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Alleen Engelstalige bron (Safety Gate) vertalen; NVWA is al NL.
            if alert.source == .safetyGate, let d = alert.riskDesc, !d.isEmpty {
                translationConfig = .init(source: Locale.Language(identifier: "en"),
                                          target: Locale.Language(identifier: "nl"))
            }
        }
        .translationTask(translationConfig) { session in
            guard let d = alert.riskDesc, !d.isEmpty else { return }
            translatedDesc = try? await session.translate(d).targetText
        }
        .toolbar {
            if let share = shareURL {
                ShareLink(item: share, subject: Text(alert.displayTitle),
                          message: Text("Recall via Recall Radar")) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Deel deze recall")
            }
        }
    }

    /// Hoofdfoto + extra foto's, ontdubbeld. Galerij bij meerdere; enkel beeld anders.
    private var images: [URL] {
        var urls: [URL] = []
        if let main = alert.imageURL { urls.append(main) }
        for u in alert.imageURLs where !urls.contains(u) { urls.append(u) }
        return urls
    }

    @ViewBuilder private var gallery: some View {
        if images.count > 1 {
            TabView {
                ForEach(images, id: \.self) { url in
                    photo(url)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 280)
            .background(.fill.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
            .accessibilityLabel("Productfoto's, \(images.count) stuks")
        } else if let url = images.first {
            photo(url)
                .frame(maxHeight: 260)
                .background(.fill.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
        }
    }

    private func photo(_ url: URL) -> some View {
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
        .accessibilityLabel("Foto van \(alert.displayTitle)")
    }

    private var placeholder: some View {
        Image(systemName: CategoryStyle.icon(alert.category))
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 160)
            .accessibilityHidden(true)
    }

    private var shareURL: URL? { alert.sourceURL }

    // "Ik heb dit product" — voegt het toe aan Mijn spullen én bevestigt de match,
    // zodat het meteen bij "Voor jou" verschijnt (snel toevoegen vanuit de feed).
    private var alreadyTracked: Bool {
        products.contains { p in
            if let pb = Normalizer.barcode(p.barcode), let ab = alert.barcode, pb == ab { return true }
            let sameBrand = !Normalizer.text(p.brand).isEmpty && Normalizer.text(p.brand) == (alert.brand ?? "")
            let sameModel = !Normalizer.model(p.model).isEmpty && Normalizer.model(p.model) == (alert.model ?? "")
            return sameBrand && sameModel
        }
    }

    @ViewBuilder private var iHaveThis: some View {
        if justAdded || alreadyTracked {
            Label("Staat in Mijn spullen", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(DS.Color.reassureGreen)
        } else {
            Button {
                let store = UserDataStore(context)
                let p = store.addProduct(brand: alert.displayBrand, model: alert.displayModel,
                                         category: alert.category, barcode: alert.barcode)
                store.confirmMatch(p, alertID: alert.id)
                justAdded = true
            } label: {
                Label("Ik heb dit product", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // Accent-header (§4.4): het enige scherm waar risicokleur prominent mag zijn.
    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text(alert.displayTitle)
                .font(.title2.bold())
                .foregroundStyle(DS.Color.textPrimary)
            HStack(spacing: DS.Space.sm) {
                if let tier, let p = RiskPresentation.tier(tier) {
                    RiskPill(presentation: p)
                }
                Label(index.riskLabel(alert.riskType), systemImage: HazardStyle.symbol(alert.riskType))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, DS.Space.sm).padding(.vertical, DS.Space.xs)
                    .foregroundStyle(HazardStyle.color(alert.riskType))
                    .background(HazardStyle.background(alert.riskType), in: Capsule())
                Label(index.categoryLabel(alert.category), systemImage: CategoryStyle.icon(alert.category))
                    .font(.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            if let desc = alert.riskDesc, !desc.isEmpty {
                Text(translatedDesc ?? desc).font(.body).foregroundStyle(DS.Color.textSecondary)
                if translatedDesc != nil {
                    Text("Automatisch vertaald")
                        .font(.caption2).foregroundStyle(DS.Color.textTertiary)
                }
            }
        }
        .padding(DS.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HazardStyle.background(alert.riskType).opacity(0.5), in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var actionAdvice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Wat moet je doen?", systemImage: "checklist")
                .font(.headline)
            Text(alert.action ?? alert.measure)
                .font(.body)
            DisclosureGroup("Officiële maatregel") {
                Text(alert.measure)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.footnote)
            .tint(.secondary)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Color.bgSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wat moet je doen? \(alert.action ?? alert.measure)")
    }

    // §3.6 — transparante uitleg waarom dit een match is (zonder het scoregetal).
    private var confidence: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Label("Waarom zie ik dit?", systemImage: "questionmark.circle")
                .font(.headline)
            ForEach(signals, id: \.self) { s in
                Label(s, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(DS.Color.brandPrimaryMuted, in: RoundedRectangle(cornerRadius: DS.Radius.md))
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
