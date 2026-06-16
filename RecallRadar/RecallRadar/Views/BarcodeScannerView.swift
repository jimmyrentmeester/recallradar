//
//  BarcodeScannerView.swift
//  RecallRadar
//
//  D2 — Barcode/EAN-scan via VisionKit DataScannerViewController. Leest alleen
//  lokaal; er worden geen foto's opgeslagen of verstuurd (privacy-guardrail +
//  camera-uitleg in Info.plist). Niet beschikbaar op de Simulator → de UI vangt
//  dat af met `isScanningAvailable`.
//

import SwiftUI
import VisionKit
import Vision

enum BarcodeScanner {
    static var isScanningAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {
    /// Geeft de ruwe payload terug (validatie/normalisatie doet de aanroeper).
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            isHighFrameRateTrackingEnabled: false,
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

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var handled = false
        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ scanner: DataScannerViewController, didAdd added: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !handled else { return }
            for item in added {
                if case let .barcode(barcode) = item, let payload = barcode.payloadStringValue {
                    handled = true
                    onScan(payload)
                    break
                }
            }
        }
    }
}
