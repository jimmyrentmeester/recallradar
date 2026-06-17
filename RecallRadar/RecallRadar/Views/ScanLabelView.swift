//
//  ScanLabelView.swift
//  RecallRadar
//
//  P1 — Typeplaatje-flow: tik het merk en (optioneel) het typenummer aan op het
//  label; daarna opent het voorgevulde productformulier. Valt terug op handmatig
//  invoeren als scannen niet beschikbaar is (Simulator/geen camera).
//

import SwiftUI

struct ScanLabelView: View {
    let store: RecallStore
    var onFinish: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var model = ""
    @State private var goToForm = false

    var body: some View {
        Group {
            if goToForm {
                AddProductView(store: store, prefillBrand: brand, prefillModel: model,
                               onFinish: onFinish ?? { dismiss() })
            } else if BarcodeScanner.isScanningAvailable {
                scanner
            } else {
                unavailable
            }
        }
        .navigationTitle("Typeplaatje scannen")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scanner: some View {
        ZStack(alignment: .bottom) {
            LabelScannerView { text in capture(text) }
                .ignoresSafeArea()
            VStack(spacing: DS.Space.sm) {
                Text(prompt)
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, DS.Space.lg).padding(.vertical, DS.Space.sm)
                    .background(.black.opacity(0.55), in: Capsule())
                if !brand.isEmpty {
                    Text("Merk: \(brand)").font(.subheadline).foregroundStyle(.white)
                }
                Button {
                    goToForm = true
                } label: {
                    Text(brand.isEmpty ? "Sla over — handmatig" : "Klaar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, DS.Space.xl)
            }
            .padding(.bottom, DS.Space.xl)
        }
    }

    private var unavailable: some View {
        ContentUnavailableView {
            Label("Scannen niet beschikbaar", systemImage: "camera.fill")
        } description: {
            Text("Het typeplaatje scannen werkt op een echt toestel met camera. Voer het product hier handmatig in.")
        } actions: {
            Button("Handmatig invoeren") { goToForm = true }.buttonStyle(.borderedProminent)
        }
    }

    private var prompt: String {
        brand.isEmpty ? "Tik op het merk op het typeplaatje" : "Tik op het typenummer (of Klaar)"
    }

    private func capture(_ text: String) {
        if brand.isEmpty { brand = text }
        else { model = text; goToForm = true }
    }
}
