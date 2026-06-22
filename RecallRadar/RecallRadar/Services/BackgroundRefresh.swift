//
//  BackgroundRefresh.swift
//  RecallRadar
//
//  E1/E3 — BGAppRefreshTask: ~1×/dag de index verversen, ALLEEN nieuwe/gewijzigde
//  alerts matchen tegen het bezit/de follows, en lokale notificaties plannen.
//  Plus de maandelijkse geruststelling-digest (P0-6). Geen server/APNs.
//

import Foundation
import BackgroundTasks
import SwiftData

/// Kleine persistente staat voor refresh/notificatie-dedup (geen bezit-data).
enum NotifState {
    private static let d = UserDefaults.standard
    private static let watermarkKey = "notif.watermark"        // laatst verwerkte updatedAt
    private static let notifiedKey = "notif.notifiedAlertIDs"  // al gepushte alert-ids
    private static let digestKey = "notif.lastDigestAt"

    static var watermark: Date? {
        get { d.object(forKey: watermarkKey) as? Date }
        set { d.set(newValue, forKey: watermarkKey) }
    }
    static var notifiedIDs: Set<String> {
        get { Set(d.stringArray(forKey: notifiedKey) ?? []) }
        set { d.set(Array(newValue.suffix(2000)), forKey: notifiedKey) } // begrens groei
    }
    static var lastDigestAt: Date? {
        get { d.object(forKey: digestKey) as? Date }
        set { d.set(newValue, forKey: digestKey) }
    }
}

/// Instelbare notificatie-voorkeuren (§4.6). HOOG is altijd aan (niet instelbaar).
enum NotifPrefs {
    private static let d = UserDefaults.standard
    // Defaults = aan; `object(forKey:) == nil` → standaard true.
    static var mediumEnabled: Bool {
        get { d.object(forKey: "pref.medium") as? Bool ?? true }
        set { d.set(newValue, forKey: "pref.medium") }
    }
    static var digestEnabled: Bool {
        get { d.object(forKey: "pref.digest") as? Bool ?? true }
        set { d.set(newValue, forKey: "pref.digest") }
    }
    /// Globale opt-in: push álle ernstige recalls, ook buiten je spullen. Standaard uit.
    static var allCriticalEnabled: Bool {
        get { d.object(forKey: "pref.allCritical") as? Bool ?? false }
        set { d.set(newValue, forKey: "pref.allCritical") }
    }
}

@MainActor
enum BackgroundRefresh {
    static let taskID = "jire.RecallRadar.refresh"

    static func register(container: ModelContainer) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            Task { @MainActor in await handle(task as! BGAppRefreshTask, container: container) }
        }
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        // Vroegst over ~1 uur; iOS plant de echte tijd op basis van gebruik. Goedkoop:
        // ongewijzigde index → HTTP 304 dankzij de ETag.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask, container: ModelContainer) async {
        scheduleNext() // plan de volgende altijd opnieuw
        let work = Task { @MainActor in await runRefresh(container: container) }
        task.expirationHandler = { work.cancel() }
        _ = await work.value
        task.setTaskCompleted(success: true)
    }

    /// Kernlogica, ook handmatig aanroepbaar (bv. bij app-start voor testen).
    static func runRefresh(container: ModelContainer) async {
        let result = await IndexService.shared.refresh()
        let index = result.index
        guard !index.alerts.isEmpty else { return }

        let context = ModelContext(container)
        let products = (try? context.fetch(FetchDescriptor<TrackedProduct>())) ?? []
        let subs = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []

        // Eerste run: alleen een baseline zetten, geen backlog-notificaties.
        guard let watermark = NotifState.watermark else {
            NotifState.watermark = index.generatedAt
            return
        }

        let newAlerts = index.alerts.filter { $0.updatedAt > watermark }
        if !newAlerts.isEmpty, await NotificationService.isAuthorized() {
            let snap = MatchBridge.snapshot(products: products, subscriptions: subs)
            let follows = MatchBridge.followSnapshot(subs)
            let items = MatchBridge.pushItems(
                alerts: newAlerts, products: snap.products, follows: follows, config: index.matchingConfig,
                mediumEnabled: NotifPrefs.mediumEnabled, allCritical: NotifPrefs.allCriticalEnabled
            )
            let alreadyNotified = NotifState.notifiedIDs
            let fresh = items.filter { !alreadyNotified.contains($0.alertID) }
            if !fresh.isEmpty {
                // Rustige uren overgelaten aan iPhone Focus/Slaapstand → direct afleveren.
                await NotificationService.schedule(
                    NotificationPlanner.plan(items: fresh, now: .now, quietStartHour: 0, quietEndHour: 0)
                )
                NotifState.notifiedIDs = alreadyNotified.union(fresh.map(\.alertID))
            }
        }

        // Watermark vooruit schuiven naar de nieuwste verwerkte wijziging.
        if let newest = newAlerts.map(\.updatedAt).max() {
            NotifState.watermark = max(watermark, newest)
        }

        await maybeSendDigest(index: index, products: products, subs: subs)
    }

    /// Maandelijkse geruststelling-digest (P0-6), ook bij nul matches.
    private static func maybeSendDigest(index: RecallIndex, products: [TrackedProduct], subs: [Subscription]) async {
        let data = UserDataStoreMonitoring(products: products, subs: subs)
        guard NotifPrefs.digestEnabled, data.isMonitoringAnything,
              await NotificationService.isAuthorized() else { return }

        let now = Date()
        if let last = NotifState.lastDigestAt,
           now.timeIntervalSince(last) < 28 * 24 * 60 * 60 { return } // < ~maand
        // Eerste keer: zet alleen het ankerpunt zonder meteen te sturen.
        guard NotifState.lastDigestAt != nil else { NotifState.lastDigestAt = now; return }

        let matches = MatchBridge.personalMatches(
            products: products, subscriptions: subs, alerts: index.alerts, config: index.matchingConfig
        )
        let monitored = products.count + subs.count
        await NotificationService.scheduleDigest(
            NotificationPlanner.digest(matchCount: matches.count, monitoredCount: monitored, now: now)
        )
        NotifState.lastDigestAt = now
    }
}

/// Lichtgewicht check zonder ModelContext-afhankelijkheid in de digest-stap.
private struct UserDataStoreMonitoring {
    let products: [TrackedProduct]
    let subs: [Subscription]
    var isMonitoringAnything: Bool { !products.isEmpty || !subs.isEmpty }
}
