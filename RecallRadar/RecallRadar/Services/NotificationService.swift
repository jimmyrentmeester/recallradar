//
//  NotificationService.swift
//  RecallRadar
//
//  E2/E3 — Dunne wrapper rond UNUserNotificationCenter. Plant lokale notificaties
//  (geen APNs in v1). Inhoud/bundeling/tijdstip komen van de pure NotificationPlanner.
//

import Foundation
import UserNotifications

@MainActor
enum NotificationService {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func isAuthorized() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    static func schedule(_ planned: [PlannedNotification]) async {
        for p in planned { await add(p) }
    }

    static func scheduleDigest(_ p: PlannedNotification) async {
        await add(p)
    }

    private static func add(_ p: PlannedNotification) async {
        let content = UNMutableNotificationContent()
        content.title = p.title
        content.body = p.body
        content.sound = p.tier == .high ? .default : nil
        content.threadIdentifier = "recall-\(p.tier)"  // groepeert in het meldingencentrum
        content.interruptionLevel = p.tier == .high ? .active : .passive
        if !p.alertIDs.isEmpty { content.userInfo = ["alertIDs": p.alertIDs] }

        var trigger: UNNotificationTrigger?
        if let fire = p.fireDate {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } // nil trigger = direct afleveren

        let request = UNNotificationRequest(identifier: p.id, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
