//
//  LabelScannerView.swift
//  RecallRadar
//
//  P1 — Typeplaatje-OCR via VisionKit live tekstherkenning. De gebruiker tikt op
//  herkende tekst (merk, dan typenummer); niets wordt opgeslagen of verstuurd
//  (privacy-guardrail). Niet beschikbaar op de Simulator (geen camera).
//

import SwiftUI
import VisionKit

struct LabelScannerView: UIViewControllerRepresentable {
    /// Geeft de aangetikte herkende tekst terug.
    var onTap: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        try? controller.startScanning()
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onTap: (String) -> Void
        init(onTap: @escaping (String) -> Void) { self.onTap = onTap }

        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case let .text(text) = item {
                let t = text.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { onTap(t) }
            }
        }
    }
}
