//
//  MatchingTests/planner.swift
//  RecallRadar
//
//  E2 — Headless tests voor de pure NotificationPlanner (bundeling + rustige uren).
//  Meegecompileerd met main.swift; gebruikt dezelfde check/eq helpers.
//

import Foundation

func runPlannerTests() {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Europe/Amsterdam")!

    func at(_ hour: Int) -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 6; c.day = 16; c.hour = hour; c.minute = 0
        c.timeZone = cal.timeZone
        return cal.date(from: c)!
    }

    let day = at(14) // overdag → geen rustige uren

    // 1 HOOG → individuele alarm-notificatie, direct (overdag).
    let oneHigh = NotificationPlanner.plan(items: [NotifItem(alertID: "a1", title: "Philips · HR-2520", tier: .high)],
                                           now: day, calendar: cal)
    eq(oneHigh.count, 1, "1 HOOG → 1 notificatie")
    check(oneHigh.first?.fireDate == nil, "overdag → direct (geen fireDate)")
    check(oneHigh.first?.title.contains("Recall:") == true, "HOOG-titel begint met Recall:")

    // 2 HOOG → gebundeld tot één.
    let twoHigh = NotificationPlanner.plan(items: [
        NotifItem(alertID: "a1", title: "X", tier: .high),
        NotifItem(alertID: "a2", title: "Y", tier: .high),
    ], now: day, calendar: cal)
    eq(twoHigh.count, 1, "2 HOOG → gebundeld tot 1")
    check(twoHigh.first?.title.contains("2 van jouw producten") == true, "bundel-titel klopt")
    eq(twoHigh.first?.alertIDs.count, 2, "bundel bevat beide alert-ids")

    // HOOG + MIDDEL → twee notificaties (per trede).
    let mixed = NotificationPlanner.plan(items: [
        NotifItem(alertID: "a1", title: "X", tier: .high),
        NotifItem(alertID: "a2", title: "Y", tier: .medium),
    ], now: day, calendar: cal)
    eq(mixed.count, 2, "HOOG + MIDDEL → 2 notificaties")

    // Rustige uren: 's nachts (02:00) → uitgesteld tot 08:00 dezelfde ochtend.
    let night = NotificationPlanner.plan(items: [NotifItem(alertID: "a1", title: "X", tier: .high)],
                                         now: at(2), calendar: cal)
    let fire = night.first?.fireDate
    check(fire != nil, "nacht → uitgesteld (fireDate gezet)")
    if let fire { eq(cal.component(.hour, from: fire), 8, "uitgesteld tot 08:00") }

    // Avond 23:00 → uitgesteld tot 08:00 de VOLGENDE dag.
    let evening = NotificationPlanner.quietFireDate(now: at(23), calendar: cal, quietStart: 22, quietEnd: 8)
    check(evening != nil, "23:00 is rustige uren")
    if let evening { eq(cal.component(.day, from: evening), 17, "23:00 → morgenochtend (dag 17)") }

    // Digest: nul matches → geruststellende tekst.
    let digest = NotificationPlanner.digest(matchCount: 0, monitoredCount: 12, now: day, calendar: cal)
    check(digest.body.contains("geen enkele recall") && digest.body.contains("12"), "digest nul-matches tekst")
    let digest2 = NotificationPlanner.digest(matchCount: 3, monitoredCount: 5, now: day, calendar: cal)
    check(digest2.body.contains("3 recall"), "digest met matches tekst")
}
