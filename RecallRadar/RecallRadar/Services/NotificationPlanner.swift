//
//  NotificationPlanner.swift
//  RecallRadar
//
//  E2 — Pure, testbare plan-logica voor lokale notificaties: bundeling per trede
//  en rustige-uren (geen nacht-pushes; bundel tot de ochtend). Fase 1 §8.
//

import Foundation

nonisolated struct NotifItem: Equatable {
    let alertID: String
    let title: String      // bv. "Philips · HR-2520"
    let tier: MatchTier
}

nonisolated struct PlannedNotification: Equatable {
    let id: String
    let title: String
    let body: String
    let fireDate: Date?    // nil = direct afleveren
    let tier: MatchTier
    let alertIDs: [String]
}

nonisolated enum NotificationPlanner {
    /// Bundelt nieuwe matches per trede en respecteert rustige uren.
    /// quietStart/quietEnd in uren (24u). Standaard 22:00–08:00.
    static func plan(
        items: [NotifItem],
        now: Date,
        calendar: Calendar = .current,
        quietStartHour: Int = 22,
        quietEndHour: Int = 8
    ) -> [PlannedNotification] {
        let fire = quietFireDate(now: now, calendar: calendar, quietStart: quietStartHour, quietEnd: quietEndHour)
        var out: [PlannedNotification] = []

        let highs = items.filter { $0.tier == .high }
        let mediums = items.filter { $0.tier == .medium }

        // HOOG → alarmerend. Bundel bij meerdere (Fase 1 §8 "rustige bundeling").
        if highs.count == 1 {
            let h = highs[0]
            out.append(PlannedNotification(
                id: "high-\(h.alertID)", title: "Recall: \(h.title)",
                body: "Dit product dat jij bewaakt is teruggeroepen. Bekijk wat je moet doen.",
                fireDate: fire, tier: .high, alertIDs: [h.alertID]))
        } else if highs.count > 1 {
            out.append(PlannedNotification(
                id: "high-bundle-\(stableKey(highs))",
                title: "\(highs.count) van jouw producten zijn teruggeroepen",
                body: "Open Recall Radar om te zien welke en wat je moet doen.",
                fireDate: fire, tier: .high, alertIDs: highs.map(\.alertID)))
        }

        // MIDDEL → zachte "is dit van jou?".
        if mediums.count == 1 {
            let m = mediums[0]
            out.append(PlannedNotification(
                id: "med-\(m.alertID)", title: "Mogelijk jouw \(m.title)?",
                body: "Bevestig of deze recall over jouw product gaat.",
                fireDate: fire, tier: .medium, alertIDs: [m.alertID]))
        } else if mediums.count > 1 {
            out.append(PlannedNotification(
                id: "med-bundle-\(stableKey(mediums))",
                title: "\(mediums.count) mogelijke matches",
                body: "Er zijn recalls die mogelijk over jouw producten gaan. Is dit van jou?",
                fireDate: fire, tier: .medium, alertIDs: mediums.map(\.alertID)))
        }

        return out
    }

    /// Geruststelling-digest (P0-6): ook bij nul matches.
    static func digest(matchCount: Int, monitoredCount: Int, now: Date, calendar: Calendar = .current,
                       quietStartHour: Int = 22, quietEndHour: Int = 8) -> PlannedNotification {
        let fire = quietFireDate(now: now, calendar: calendar, quietStart: quietStartHour, quietEnd: quietEndHour)
        let body: String
        if matchCount == 0 {
            body = "Deze maand raakte geen enkele recall jouw \(monitoredCount) bewaakte item\(monitoredCount == 1 ? "" : "s"). We kijken mee."
        } else {
            body = "Deze maand zijn er \(matchCount) recall\(matchCount == 1 ? "" : "s") die jou kunnen raken. Bekijk ze in de app."
        }
        return PlannedNotification(id: "digest", title: "Je maandelijkse Recall Radar-check",
                                   body: body, fireDate: fire, tier: .low, alertIDs: [])
    }

    /// Binnen rustige uren → eerstvolgende quietEnd (ochtend). Anders nil (direct).
    static func quietFireDate(now: Date, calendar: Calendar, quietStart: Int, quietEnd: Int) -> Date? {
        let hour = calendar.component(.hour, from: now)
        let inQuiet = quietStart > quietEnd
            ? (hour >= quietStart || hour < quietEnd)   // bv. 22..08 over middernacht
            : (hour >= quietStart && hour < quietEnd)
        guard inQuiet else { return nil }
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = quietEnd; comps.minute = 0
        let todayMorning = calendar.date(from: comps)!
        // Als het na middernacht maar vóór quietEnd is → vanochtend; anders morgenochtend.
        if hour < quietEnd { return todayMorning }
        return calendar.date(byAdding: .day, value: 1, to: todayMorning)
    }

    private static func stableKey(_ items: [NotifItem]) -> String {
        items.map(\.alertID).sorted().joined(separator: ",").hashValue.description
    }
}
