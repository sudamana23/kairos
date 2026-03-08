import Foundation
import SwiftData

// Auto-generated from 2025_OKRs.xlsx and 2026_OKRs_v4.xlsx
// Do not edit by hand — regenerate with generate_seed.py

enum SeedData {

    @MainActor
    static func seedIfNeeded(in container: ModelContainer) async {
        let ctx = ModelContext(container)
        let existing = (try? ctx.fetch(FetchDescriptor<KairosYear>())) ?? []
        guard existing.isEmpty else { return }

        seed2025(ctx)
        seed2026(ctx)
        try? ctx.save()
    }

    // MARK: - 2025
    private static func seed2025(_ ctx: ModelContext) {
        let year = KairosYear(year: 2025, intention: "Foundations")
        ctx.insert(year)

        let d0 = KairosDomain(name: "Foundation", emoji: "◆", identityStatement: "I build strong physical and mental foundations daily.", sortOrder: 0, colorHex: "#4CAF50")
        ctx.insert(d0)
        year.domains.append(d0)
        let o0 = KairosObjective(title: "Foundation Goals", sortOrder: 0)
        ctx.insert(o0)
        o0.domain = d0
        let kr0_0 = KairosKeyResult(title: "Dry January", sortOrder: 0)
        ctx.insert(kr0_0)
        kr0_0.objective = o0
        let e0_0_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .blocked, rating: 3, commentary: "Failed")
        ctx.insert(e0_0_5)
        e0_0_5.keyResult = kr0_0
        let kr0_1 = KairosKeyResult(title: "Drinking", sortOrder: 1)
        ctx.insert(kr0_1)
        kr0_1.objective = o0
        let e0_1_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "10 days and counting, significant improvements in weight, sleep and other aspects")
        ctx.insert(e0_1_8)
        e0_1_8.keyResult = kr0_1
        let e0_1_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Some events but continues to be significantly reduced and noticeable")
        ctx.insert(e0_1_9)
        e0_1_9.keyResult = kr0_1
        let e0_1_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "This has been generally acceptable.  Regular breaks, limited consumption, some sense.")
        ctx.insert(e0_1_11)
        e0_1_11.keyResult = kr0_1
        let e0_1_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "All over the place, as expected")
        ctx.insert(e0_1_12)
        e0_1_12.keyResult = kr0_1
        let kr0_2 = KairosKeyResult(title: "Karate", sortOrder: 2)
        ctx.insert(kr0_2)
        kr0_2.objective = o0
        let e0_2_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Mixed performance on my side.  Too many breaks, missing consistency.  Not sure if and when a 2nd Dan is possible")
        ctx.insert(e0_2_5)
        e0_2_5.keyResult = kr0_2
        let e0_2_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Definitely been a good month, averaged above two sessions per week; augmented with strength training and running in the last weeks, after settling back down since Japan, this has been a good spell.")
        ctx.insert(e0_2_6)
        e0_2_6.keyResult = kr0_2
        let e0_2_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Not great, absences (WFA). Missing consistency here.")
        ctx.insert(e0_2_7)
        e0_2_7.keyResult = kr0_2
        let e0_2_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Not great, absences (WFA). Missing consistency here.")
        ctx.insert(e0_2_8)
        e0_2_8.keyResult = kr0_2
        let e0_2_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "1-2 sessions per week on average, and enjoying the lessons, no clockwatching.  Need to work on my hips.")
        ctx.insert(e0_2_9)
        e0_2_9.keyResult = kr0_2
        let e0_2_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Last month has been reduced due to travel and sickness, but I've enjoyed going and have it on my radar.  It's an acceptable level.  I have given up ambitions for 2nd dan")
        ctx.insert(e0_2_11)
        e0_2_11.keyResult = kr0_2
        let e0_2_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "OK start, but drifted off mid December")
        ctx.insert(e0_2_12)
        e0_2_12.keyResult = kr0_2
        let kr0_3 = KairosKeyResult(title: "No Smoking", sortOrder: 3)
        ctx.insert(kr0_3)
        kr0_3.objective = o0
        let e0_3_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Can't remember when I last had a cigarette.  Running again.  VO2 max 36.2 as of 15.5")
        ctx.insert(e0_3_5)
        e0_3_5.keyResult = kr0_3
        let e0_3_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Had some smokes with Andreas H.; VO2 max 37.4.  Improving")
        ctx.insert(e0_3_6)
        e0_3_6.keyResult = kr0_3
        let e0_3_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Smoked at Jasmeets housewarming, then cut it out again.  Reliant on pouches at the moment.  And pushing that fix.  So, although VO2 Max is improving… nicotine remains.  Didn't smoke at the Abifeier.")
        ctx.insert(e0_3_7)
        e0_3_7.keyResult = kr0_3
        let e0_3_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "VO2 max increased recently, not smoked in months, but still reliant on nicotine, that's the next focus.")
        ctx.insert(e0_3_8)
        e0_3_8.keyResult = kr0_3
        let e0_3_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Still not smoking but little running and so no Vo2 max measurements, never 34")
        ctx.insert(e0_3_9)
        e0_3_9.keyResult = kr0_3
        let e0_3_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Not smoked.  Also dropped nicotine in SGP, chewing gums this weekend, but without real value.  Not something i need going foward.")
        ctx.insert(e0_3_11)
        e0_3_11.keyResult = kr0_3
        let e0_3_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Still no smoking, no nicotine, some temptation in Thailand, but worked out ok")
        ctx.insert(e0_3_12)
        e0_3_12.keyResult = kr0_3
        let kr0_4 = KairosKeyResult(title: "Nutrition", sortOrder: 4)
        ctx.insert(kr0_4)
        kr0_4.objective = o0
        let e0_4_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Been a terrible few weeks for red meat (Wagyu, too!), regular booze.")
        ctx.insert(e0_4_5)
        e0_4_5.keyResult = kr0_4
        let e0_4_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Food has improved; less red meat, more vegetables, intermittent fasting.  Still, drinking has been terrible.  BJB Health check scheduled")
        ctx.insert(e0_4_6)
        e0_4_6.keyResult = kr0_4
        let e0_4_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "BHB Health Check this week,  have eaten a lot of red meat, barbecues… definitely not that conscious of my food right now.")
        ctx.insert(e0_4_7)
        e0_4_7.keyResult = kr0_4
        let e0_4_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Small improvements from the BJB Health Check, still eating too much meat, cholestorl not desperate")
        ctx.insert(e0_4_8)
        e0_4_8.keyResult = kr0_4
        let e0_4_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Weight loss has been significant, noticed a need for more sugar.  Still eating too much meet but I have reduced red meat.  Cholesterol should be much better.")
        ctx.insert(e0_4_9)
        e0_4_9.keyResult = kr0_4
        let e0_4_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Still at 80kg mostly.  I've been eating more or less OK.  Some fasting.  Could do more here.")
        ctx.insert(e0_4_11)
        e0_4_11.keyResult = kr0_4
        let e0_4_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Weight increase")
        ctx.insert(e0_4_12)
        e0_4_12.keyResult = kr0_4
        let kr0_5 = KairosKeyResult(title: "Qi Gong", sortOrder: 5)
        ctx.insert(kr0_5)
        kr0_5.objective = o0
        let e0_5_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Missed a bit with Japan and struggled to get back up to speed however overall has been very strong")
        ctx.insert(e0_5_5)
        e0_5_5.keyResult = kr0_5
        let e0_5_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Generally practicing Qi Gong daily, though my morning stacking has fallen down.  Probably related to drinking")
        ctx.insert(e0_5_6)
        e0_5_6.keyResult = kr0_5
        let e0_5_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Although I haven't practiced daily, I have reintroduced meditation and can feel progress in our meditation.")
        ctx.insert(e0_5_7)
        e0_5_7.keyResult = kr0_5
        let e0_5_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Significant improvements, mostly daily practice, great benefits from the lessons.  Improved focus, resilience and concentration.")
        ctx.insert(e0_5_8)
        e0_5_8.keyResult = kr0_5
        let e0_5_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Daily Qi gong is showing benefits")
        ctx.insert(e0_5_9)
        e0_5_9.keyResult = kr0_5
        let e0_5_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Daily Qi gong is showing benefits - really enjoying this work, and making real progress.")
        ctx.insert(e0_5_11)
        e0_5_11.keyResult = kr0_5
        let e0_5_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "I continued to practice though my streak has been propped up in parts")
        ctx.insert(e0_5_12)
        e0_5_12.keyResult = kr0_5
        let kr0_6 = KairosKeyResult(title: "Strength Training", sortOrder: 6)
        ctx.insert(kr0_6)
        kr0_6.objective = o0
        let e0_6_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "In progress")
        ctx.insert(e0_6_5)
        e0_6_5.keyResult = kr0_6
        let e0_6_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "3 perfect weeks of strength taking longer than 3, but stronger.")
        ctx.insert(e0_6_6)
        e0_6_6.keyResult = kr0_6
        let e0_6_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "After completion of the strength program I have dipped to once a week.")
        ctx.insert(e0_6_7)
        e0_6_7.keyResult = kr0_6
        let e0_6_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Once a week, but getting in more exercise in general")
        ctx.insert(e0_6_8)
        e0_6_8.keyResult = kr0_6
        let e0_6_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Maybe once a week, or 1.5 on average.  Last two weeks have been a bit more difficult, energy levels have been low.")
        ctx.insert(e0_6_9)
        e0_6_9.keyResult = kr0_6
        let e0_6_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Impacted by travel and sickness this month but I have worked continuously here.")
        ctx.insert(e0_6_11)
        e0_6_11.keyResult = kr0_6
        let e0_6_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Weights progressing, bought more just now.")
        ctx.insert(e0_6_12)
        e0_6_12.keyResult = kr0_6

        let d1 = KairosDomain(name: "Kids", emoji: "◆", identityStatement: "I am a present, patient, and invested father.", sortOrder: 1, colorHex: "#FFC107")
        ctx.insert(d1)
        year.domains.append(d1)
        let o1 = KairosObjective(title: "Kids Goals", sortOrder: 0)
        ctx.insert(o1)
        o1.domain = d1
        let kr1_0 = KairosKeyResult(title: "Agree Plan for Housework", sortOrder: 0)
        ctx.insert(kr1_0)
        kr1_0.objective = o1
        let e1_0_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .notStarted, rating: 3, commentary: "Plan not agreed but raised expectations")
        ctx.insert(e1_0_5)
        e1_0_5.keyResult = kr1_0
        let e1_0_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .notStarted, rating: 3, commentary: "Some improvements, less moaning about putting plates away, keeping the place tidy, making bed, etc.  This is OK, almost Green.")
        ctx.insert(e1_0_6)
        e1_0_6.keyResult = kr1_0
        let e1_0_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .notStarted, rating: 3, commentary: "Slow progress compounded by an bit of an absence of structure (WFA, upcoming summer holidays).")
        ctx.insert(e1_0_7)
        e1_0_7.keyResult = kr1_0
        let e1_0_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .notStarted, rating: 3, commentary: "Some progress but needs continuous focus.")
        ctx.insert(e1_0_8)
        e1_0_8.keyResult = kr1_0
        let e1_0_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .notStarted, rating: 3, commentary: "Actually i think this is trending downwards.  Struggling to get the basics in place")
        ctx.insert(e1_0_9)
        e1_0_9.keyResult = kr1_0
        let e1_0_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .notStarted, rating: 3, commentary: "Kids still doing very little around the house.  I have to ask my self if this is actually a goal.")
        ctx.insert(e1_0_11)
        e1_0_11.keyResult = kr1_0
        let e1_0_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .notStarted, rating: 3, commentary: "I don't have a handle on this yet.  I'm struggling.  Need to work out a a away forward")
        ctx.insert(e1_0_12)
        e1_0_12.keyResult = kr1_0
        let kr1_1 = KairosKeyResult(title: "Aiden", sortOrder: 1)
        ctx.insert(kr1_1)
        kr1_1.objective = o1
        let e1_1_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Assessment complete, diagnosis defined, next steps Psychologist in discussion as enabler for Year 6")
        ctx.insert(e1_1_5)
        e1_1_5.keyResult = kr1_1
        let e1_1_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Q2 almost done, seeking somewhere for a psychological assessment, trending Amber if I don't get next steps lined up in the next weeks")
        ctx.insert(e1_1_6)
        e1_1_6.keyResult = kr1_1
        let e1_1_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Some concrete next steps agreed with Melanie and with Aiden.  Discussion needed.")
        ctx.insert(e1_1_7)
        e1_1_7.keyResult = kr1_1
        let e1_1_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Tricky start to Year 6.  Further reinforcement needed, open to considering medication.")
        ctx.insert(e1_1_8)
        e1_1_8.keyResult = kr1_1
        let e1_1_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Noticeable challenges in regulating emotions.  On the plus side, good results in general, improvements in homework and self management.  Plenty of time with friends.")
        ctx.insert(e1_1_9)
        e1_1_9.keyResult = kr1_1
        let e1_1_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "We've tried Ritalin but without much success.  School stil a bit of a battle.  Unsure of next steps here.")
        ctx.insert(e1_1_11)
        e1_1_11.keyResult = kr1_1
        let e1_1_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Ritalin didn't work.  Still struggling, no real alternatives in sight.  Gaming probably not helping")
        ctx.insert(e1_1_12)
        e1_1_12.keyResult = kr1_1
        let kr1_2 = KairosKeyResult(title: "Fit kids", sortOrder: 2)
        ctx.insert(kr1_2)
        kr1_2.objective = o1
        let e1_2_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Noam playing football.  Aiden more engaged outside and will pick up Muay Thai")
        ctx.insert(e1_2_5)
        e1_2_5.keyResult = kr1_2
        let e1_2_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Noam all over football and out a lot.  Aiden out regularly with his friends and on his bike.")
        ctx.insert(e1_2_6)
        e1_2_6.keyResult = kr1_2
        let e1_2_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Still a lot of action outside at the moment, spending time on bikes, football, in the badi.")
        ctx.insert(e1_2_7)
        e1_2_7.keyResult = kr1_2
        let e1_2_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Still a lot of action outside at the moment, spending time on bikes, football, in the badi.")
        ctx.insert(e1_2_8)
        e1_2_8.keyResult = kr1_2
        let e1_2_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Noam regularly in football.  Aiden out a lot on the bike and with friends, this remains encouraging")
        ctx.insert(e1_2_9)
        e1_2_9.keyResult = kr1_2
        let e1_2_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Noam vaping.  Discussion points there.  Trying to find the right balance.  Difficult in these conditions to send the kids out, but they are still out and about - there is some sense of balance.  Aiden doesn't yet have a sport.  Noam visits football more or less regularly, but reduced training and matches over winter")
        ctx.insert(e1_2_11)
        e1_2_11.keyResult = kr1_2
        let e1_2_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Seems to have improved for Noam, but not so for Aiden.  Winter not helping")
        ctx.insert(e1_2_12)
        e1_2_12.keyResult = kr1_2
        let kr1_3 = KairosKeyResult(title: "Noam", sortOrder: 3)
        ctx.insert(kr1_3)
        kr1_3.objective = o1
        let e1_3_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "OK")
        ctx.insert(e1_3_5)
        e1_3_5.keyResult = kr1_3
        let e1_3_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "OK")
        ctx.insert(e1_3_6)
        e1_3_6.keyResult = kr1_3
        let e1_3_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "still a bit of a struggle.")
        ctx.insert(e1_3_7)
        e1_3_7.keyResult = kr1_3
        let e1_3_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "Work has made a difference.  Very structured, motivated, engaged, great to see.")
        ctx.insert(e1_3_8)
        e1_3_8.keyResult = kr1_3
        let e1_3_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Work continues to benefit Noam, he continues to manage his work life balance well and is retaining his relationships.")
        ctx.insert(e1_3_9)
        e1_3_9.keyResult = kr1_3
        let e1_3_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Work is ok, completed Probationary period but with expected feedback - a bit too easy and a bit to disorganised.  School results are good though, with little effort, there is potential there.")
        ctx.insert(e1_3_11)
        e1_3_11.keyResult = kr1_3
        let e1_3_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Yes, this is going well.  School too.  Getting things done, quietly minimalistically.")
        ctx.insert(e1_3_12)
        e1_3_12.keyResult = kr1_3

        let d2 = KairosDomain(name: "Plans", emoji: "◆", identityStatement: "I plan intentionally and follow through.", sortOrder: 2, colorHex: "#2196F3")
        ctx.insert(d2)
        year.domains.append(d2)
        let o2 = KairosObjective(title: "Plans Goals", sortOrder: 0)
        ctx.insert(o2)
        o2.domain = d2
        let kr2_0 = KairosKeyResult(title: "Data Quality Framework Implementation", sortOrder: 0)
        ctx.insert(kr2_0)
        kr2_0.objective = o2
        let e2_0_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .done, rating: 3, commentary: "On track to deliver this, and be ready to re-align to the re-org.")
        ctx.insert(e2_0_5)
        e2_0_5.keyResult = kr2_0
        let e2_0_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .done, rating: 3, commentary: "I would say we're BAU and ready to support and enable the business; they have other priorities.")
        ctx.insert(e2_0_6)
        e2_0_6.keyResult = kr2_0
        let e2_0_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .done, rating: 3, commentary: "Making progress and new vehicle identified, seems very promising.")
        ctx.insert(e2_0_7)
        e2_0_7.keyResult = kr2_0
        let e2_0_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .done, rating: 3, commentary: "Results are starting to come.  Not sure new management sees the value.  Storyline is there, hopeful to better transport the results")
        ctx.insert(e2_0_8)
        e2_0_8.keyResult = kr2_0
        let e2_0_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .done, rating: 3, commentary: "Well… this is almost \"ready-to-use\", but this is out of my hands now.  Will wrap it up and hand it over.")
        ctx.insert(e2_0_9)
        e2_0_9.keyResult = kr2_0
        let e2_0_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .done, rating: 3, commentary: "Done.")
        ctx.insert(e2_0_11)
        e2_0_11.keyResult = kr2_0
        let e2_0_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .done, rating: 3, commentary: "Done.")
        ctx.insert(e2_0_12)
        e2_0_12.keyResult = kr2_0
        let kr2_1 = KairosKeyResult(title: "Data Quality Framework Implementation Readiness", sortOrder: 1)
        ctx.insert(kr2_1)
        kr2_1.objective = o2
        let e2_1_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .done, rating: 3, commentary: "Done")
        ctx.insert(e2_1_5)
        e2_1_5.keyResult = kr2_1
        let e2_1_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .done, rating: 3, commentary: "Done")
        ctx.insert(e2_1_6)
        e2_1_6.keyResult = kr2_1
        let kr2_2 = KairosKeyResult(title: "Financial Plan", sortOrder: 2)
        ctx.insert(kr2_2)
        kr2_2.objective = o2
        let e2_2_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "No financial plan, funding for pension allocated, savings took a dent but time to recover in H2.  ISAP funds depleted.")
        ctx.insert(e2_2_5)
        e2_2_5.keyResult = kr2_2
        let e2_2_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Savings plan back in place, though will have to squeeze a bit in the next months.  Amber until reserves rebuilt.")
        ctx.insert(e2_2_6)
        e2_2_6.keyResult = kr2_2
        let e2_2_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Still struggling a bit to save beyond Truewealth, 3a and in general.  Taxes, mortgage etc. still being put away, needs more work over the next months before the next big spends…..")
        ctx.insert(e2_2_7)
        e2_2_7.keyResult = kr2_2
        let e2_2_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "It's tight, bought some holidays, had to drawdown from Truewealth to bridge a gap.  Pension fund 10k top-up.  Somehow making it work.  Not sure when this will be stable.")
        ctx.insert(e2_2_8)
        e2_2_8.keyResult = kr2_2
        let e2_2_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "Am somewhat happy to spend money and borrowing a little from the future these days, but new job and a newfound sense of security is helping here.")
        ctx.insert(e2_2_9)
        e2_2_9.keyResult = kr2_2
        let e2_2_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Tight enough, but will somehow scrabble myself through to the bonus.  Tanzania kind of broke the bank this time around, need to better save for q1 holidays in future.")
        ctx.insert(e2_2_11)
        e2_2_11.keyResult = kr2_2
        let e2_2_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Onhold")
        ctx.insert(e2_2_12)
        e2_2_12.keyResult = kr2_2
        let kr2_3 = KairosKeyResult(title: "Japan", sortOrder: 3)
        ctx.insert(kr2_3)
        kr2_3.objective = o2
        let e2_3_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .done, rating: 3, commentary: "Done")
        ctx.insert(e2_3_5)
        e2_3_5.keyResult = kr2_3
        let e2_3_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .done, rating: 3, commentary: "Done - fond memories coming back")
        ctx.insert(e2_3_6)
        e2_3_6.keyResult = kr2_3
        let kr2_4 = KairosKeyResult(title: "Jung", sortOrder: 4)
        ctx.insert(kr2_4)
        kr2_4.objective = o2
        let e2_4_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .inProgress, rating: 3, commentary: "Starting Volume 8 now")
        ctx.insert(e2_4_5)
        e2_4_5.keyResult = kr2_4
        let e2_4_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .inProgress, rating: 3, commentary: "Stopped.  Reading has been OK, but a bit haphazard, less focussed, missing direction.")
        ctx.insert(e2_4_6)
        e2_4_6.keyResult = kr2_4
        let e2_4_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .inProgress, rating: 3, commentary: "Reading blocked.  Accepted - time to write.")
        ctx.insert(e2_4_7)
        e2_4_7.keyResult = kr2_4
        let e2_4_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "I have been writing, inquiring.  On and off.  Read one book on spies.  I think the impediment is being overly focussed on ingestion and not synthesis.  Good to see honest exploration.  Though distracting myself with tech work (AI) at the moment.")
        ctx.insert(e2_4_8)
        e2_4_8.keyResult = kr2_4
        let e2_4_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "This will not happen.  Deprioritized.")
        ctx.insert(e2_4_9)
        e2_4_9.keyResult = kr2_4
        let e2_4_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "This will not happen.  Deprioritized.")
        ctx.insert(e2_4_11)
        e2_4_11.keyResult = kr2_4
        let e2_4_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "This will not happen.  Deprioritized.")
        ctx.insert(e2_4_12)
        e2_4_12.keyResult = kr2_4
        let kr2_5 = KairosKeyResult(title: "New role", sortOrder: 5)
        ctx.insert(kr2_5)
        kr2_5.objective = o2
        let e2_5_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .done, rating: 3, commentary: "TBD")
        ctx.insert(e2_5_5)
        e2_5_5.keyResult = kr2_5
        let e2_5_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .done, rating: 3, commentary: "Discussions in progress and will see what opens up.")
        ctx.insert(e2_5_6)
        e2_5_6.keyResult = kr2_5
        let e2_5_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .done, rating: 3, commentary: "Some conversations ongoing.  2nd interview with Sarasin, went very well for me, not sure I can expect an offer that works for me.")
        ctx.insert(e2_5_7)
        e2_5_7.keyResult = kr2_5
        let e2_5_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .done, rating: 3, commentary: "Nothing happening here.  But settled enough at work in this role and don't feel that I'm at risk right now.  Still rrequires ongoing monitoring and attention, and exploration of opportunities.")
        ctx.insert(e2_5_8)
        e2_5_8.keyResult = kr2_5
        let e2_5_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .done, rating: 3, commentary: "New job in BJB, feels promising.  Secure.  Respected by leadership who can give me the right level of support and guidance.  A good start.")
        ctx.insert(e2_5_9)
        e2_5_9.keyResult = kr2_5
        let e2_5_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .done, rating: 3, commentary: "Up and running as Head of Data Governance Risk.  Making a difference.")
        ctx.insert(e2_5_11)
        e2_5_11.keyResult = kr2_5
        let e2_5_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .done, rating: 3, commentary: "All good")
        ctx.insert(e2_5_12)
        e2_5_12.keyResult = kr2_5
        let kr2_6 = KairosKeyResult(title: "Writing", sortOrder: 6)
        ctx.insert(kr2_6)
        kr2_6.objective = o2
        let e2_6_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .inProgress, rating: 3, commentary: "I have been writing, inquiring.  On and off.  Read one book on spies.  I think the impediment is being overly focussed on ingestion and not synthesis.  Good to see honest exploration.  Though distracting myself with tech work (AI) at the moment.")
        ctx.insert(e2_6_8)
        e2_6_8.keyResult = kr2_6
        let e2_6_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .inProgress, rating: 3, commentary: "This has been quiet in September, but really it's about the practice - this is where the inquiry led me.  There will be more work needed to better understand the energetic maps …. Interesting how \"Psychophysics\" grabbed my attention this morning.")
        ctx.insert(e2_6_9)
        e2_6_9.keyResult = kr2_6
        let e2_6_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .inProgress, rating: 3, commentary: "Hardly written for two months.  Not sure why.  Feels like I'm devoted to practice and less ot thinking")
        ctx.insert(e2_6_11)
        e2_6_11.keyResult = kr2_6
        let e2_6_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .inProgress, rating: 3, commentary: "Still little writing, journaling, or even reflection")
        ctx.insert(e2_6_12)
        e2_6_12.keyResult = kr2_6

        let d3 = KairosDomain(name: "Wish", emoji: "◆", identityStatement: "I nurture love and partnership.", sortOrder: 3, colorHex: "#E91E63")
        ctx.insert(d3)
        year.domains.append(d3)
        let o3 = KairosObjective(title: "Wish Goals", sortOrder: 0)
        ctx.insert(o3)
        o3.domain = d3
        let kr3_0 = KairosKeyResult(title: "Marriage Plans", sortOrder: 0)
        ctx.insert(kr3_0)
        kr3_0.objective = o3
        let e3_0_5 = KairosMonthlyEntry(year: 2025, month: 5, status: .notStarted, rating: 3, commentary: "Still requires moving in, which I can't commit too.")
        ctx.insert(e3_0_5)
        e3_0_5.keyResult = kr3_0
        let e3_0_6 = KairosMonthlyEntry(year: 2025, month: 6, status: .notStarted, rating: 3, commentary: "Won't happen until we move in which is a few years away.")
        ctx.insert(e3_0_6)
        e3_0_6.keyResult = kr3_0
        let e3_0_7 = KairosMonthlyEntry(year: 2025, month: 7, status: .notStarted, rating: 3, commentary: "Big discussions, but getting closer to understanding each other.")
        ctx.insert(e3_0_7)
        e3_0_7.keyResult = kr3_0
        let e3_0_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .notStarted, rating: 3, commentary: "Some progress spending more time together and Big Picture alignment; i've also had insights that I need to let go (of what?) and just push forward.")
        ctx.insert(e3_0_8)
        e3_0_8.keyResult = kr3_0
        let e3_0_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .notStarted, rating: 3, commentary: "Her Work and some intense discussions in the last two months are bearing fruit, her acceptance of the situation has strengthened and my willingness to adjust accordingly are benefitting us.  This feels a lot better.  Still, the weekends are hard.")
        ctx.insert(e3_0_9)
        e3_0_9.keyResult = kr3_0
        let e3_0_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .notStarted, rating: 3, commentary: "We are doing really well together.  There is a lot of love and care and passion and I feel that things are moving well, if not fast enough.  We will get there.")
        ctx.insert(e3_0_11)
        e3_0_11.keyResult = kr3_0
        let e3_0_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .notStarted, rating: 3, commentary: "Awesome")
        ctx.insert(e3_0_12)
        e3_0_12.keyResult = kr3_0

        let d4 = KairosDomain(name: "Work", emoji: "◆", identityStatement: "I lead with integrity and grow professionally.", sortOrder: 4, colorHex: "#607D8B")
        ctx.insert(d4)
        year.domains.append(d4)
        let o4 = KairosObjective(title: "Work Goals", sortOrder: 0)
        ctx.insert(o4)
        o4.domain = d4
        let kr4_0 = KairosKeyResult(title: "LLMs", sortOrder: 0)
        ctx.insert(kr4_0)
        kr4_0.objective = o4
        let e4_0_8 = KairosMonthlyEntry(year: 2025, month: 8, status: .initialized, rating: 3, commentary: "Started to spend some time increasing knowledge on LLMs, not sure about my real ambitions here (buy a new computer!?!).")
        ctx.insert(e4_0_8)
        e4_0_8.keyResult = kr4_0
        let e4_0_9 = KairosMonthlyEntry(year: 2025, month: 9, status: .initialized, rating: 3, commentary: "great progress here and increased learning.  Using AI to understand AI, build apps, rediscovered my love of technology.  Bash, learning a bit about proper coding, deep-diving on LLMs, model risk management etc.")
        ctx.insert(e4_0_9)
        e4_0_9.keyResult = kr4_0
        let e4_0_11 = KairosMonthlyEntry(year: 2025, month: 11, status: .initialized, rating: 3, commentary: "This dropped off the radar, holidays, travel, sickness and reading again…would like to get some focus back here.")
        ctx.insert(e4_0_11)
        e4_0_11.keyResult = kr4_0
        let e4_0_12 = KairosMonthlyEntry(year: 2025, month: 12, status: .initialized, rating: 3, commentary: "Some focus returned, but not really much")
        ctx.insert(e4_0_12)
        e4_0_12.keyResult = kr4_0

    }

    // MARK: - 2026
    private static func seed2026(_ ctx: ModelContext) {
        let year = KairosYear(year: 2026, intention: "Growth")
        ctx.insert(year)

        let d26_0 = KairosDomain(name: "Externalities", emoji: "◆", identityStatement: "I navigate life changes with intention and calm.", sortOrder: 0, colorHex: "#8A8A9A")
        ctx.insert(d26_0)
        year.domains.append(d26_0)
        let o26_0_0 = KairosObjective(title: "New Car", sortOrder: 0)
        ctx.insert(o26_0_0)
        o26_0_0.domain = d26_0
        let kr26_0_0_0 = KairosKeyResult(title: "Car lease arranged and signed", sortOrder: 0)
        ctx.insert(kr26_0_0_0)
        kr26_0_0_0.objective = o26_0_0
        let e26_0_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "Hope to conclude in February")
        ctx.insert(e26_0_0_0_1)
        e26_0_0_0_1.keyResult = kr26_0_0_0
        let e26_0_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "Will complete March 14th - need to sell A3")
        ctx.insert(e26_0_0_0_2)
        e26_0_0_0_2.keyResult = kr26_0_0_0

        let o26_0_1 = KairosObjective(title: "New Home", sortOrder: 1)
        ctx.insert(o26_0_1)
        o26_0_1.domain = d26_0
        let kr26_0_1_0 = KairosKeyResult(title: "Suitable property identified", sortOrder: 0)
        ctx.insert(kr26_0_1_0)
        kr26_0_1_0.objective = o26_0_1
        let e26_0_1_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "Need to pick up the drive I had here.")
        ctx.insert(e26_0_1_0_1)
        e26_0_1_0_1.keyResult = kr26_0_1_0
        let e26_0_1_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 3, commentary: "")
        ctx.insert(e26_0_1_0_2)
        e26_0_1_0_2.keyResult = kr26_0_1_0
        let kr26_0_1_1 = KairosKeyResult(title: "Mortgage arranged and approved", sortOrder: 1)
        ctx.insert(kr26_0_1_1)
        kr26_0_1_1.objective = o26_0_1
        let e26_0_1_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_0_1_1_1)
        e26_0_1_1_1.keyResult = kr26_0_1_1
        let e26_0_1_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .blocked, rating: 1, commentary: "Funds locked in SS72")
        ctx.insert(e26_0_1_1_2)
        e26_0_1_1_2.keyResult = kr26_0_1_1
        let kr26_0_1_2 = KairosKeyResult(title: "Move completed", sortOrder: 2)
        ctx.insert(kr26_0_1_2)
        kr26_0_1_2.objective = o26_0_1
        let e26_0_1_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_0_1_2_1)
        e26_0_1_2_1.keyResult = kr26_0_1_2
        let e26_0_1_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_0_1_2_2)
        e26_0_1_2_2.keyResult = kr26_0_1_2

        let o26_0_2 = KairosObjective(title: "Get Teeth Fixed", sortOrder: 2)
        ctx.insert(o26_0_2)
        o26_0_2.domain = d26_0
        let kr26_0_2_0 = KairosKeyResult(title: "All gaps filled by Q2", sortOrder: 0)
        ctx.insert(kr26_0_2_0)
        kr26_0_2_0.objective = o26_0_2
        let e26_0_2_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_0_2_0_1)
        e26_0_2_0_1.keyResult = kr26_0_2_0
        let e26_0_2_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .initialized, rating: 0, commentary: "Will schedule in March")
        ctx.insert(e26_0_2_0_2)
        e26_0_2_0_2.keyResult = kr26_0_2_0


        let d26_1 = KairosDomain(name: "Health", emoji: "◆", identityStatement: "I invest consistently in my physical health.", sortOrder: 1, colorHex: "#4CAF50")
        ctx.insert(d26_1)
        year.domains.append(d26_1)
        let o26_1_0 = KairosObjective(title: "Annual Health Check", sortOrder: 0)
        ctx.insert(o26_1_0)
        o26_1_0.domain = d26_1
        let kr26_1_0_0 = KairosKeyResult(title: "Urologist check up completed", sortOrder: 0)
        ctx.insert(kr26_1_0_0)
        kr26_1_0_0.objective = o26_1_0
        let e26_1_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_1_0_0_1)
        e26_1_0_0_1.keyResult = kr26_1_0_0
        let e26_1_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_1_0_0_2)
        e26_1_0_0_2.keyResult = kr26_1_0_0
        let kr26_1_0_1 = KairosKeyResult(title: "Teeth cleaning and check up completed", sortOrder: 1)
        ctx.insert(kr26_1_0_1)
        kr26_1_0_1.objective = o26_1_0
        let e26_1_0_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_1_0_1_1)
        e26_1_0_1_1.keyResult = kr26_1_0_1
        let e26_1_0_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_1_0_1_2)
        e26_1_0_1_2.keyResult = kr26_1_0_1
        let kr26_1_0_2 = KairosKeyResult(title: "Cholesterol measured — result manageable", sortOrder: 2)
        ctx.insert(kr26_1_0_2)
        kr26_1_0_2.objective = o26_1_0
        let e26_1_0_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_1_0_2_1)
        e26_1_0_2_1.keyResult = kr26_1_0_2
        let e26_1_0_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_1_0_2_2)
        e26_1_0_2_2.keyResult = kr26_1_0_2
        let kr26_1_0_3 = KairosKeyResult(title: "Medbase full check completed", sortOrder: 3)
        ctx.insert(kr26_1_0_3)
        kr26_1_0_3.objective = o26_1_0
        let e26_1_0_3_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_1_0_3_1)
        e26_1_0_3_1.keyResult = kr26_1_0_3
        let e26_1_0_3_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_1_0_3_2)
        e26_1_0_3_2.keyResult = kr26_1_0_3

        let o26_1_1 = KairosObjective(title: "Weight Management", sortOrder: 1)
        ctx.insert(o26_1_1)
        o26_1_1.domain = d26_1
        let kr26_1_1_0 = KairosKeyResult(title: "Weight maintained between 80-83 kg all year", sortOrder: 0)
        ctx.insert(kr26_1_1_0)
        kr26_1_1_0.objective = o26_1_1
        let e26_1_1_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "About 81.5 kg — on track")
        ctx.insert(e26_1_1_0_1)
        e26_1_1_0_1.keyResult = kr26_1_1_0
        let e26_1_1_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 2, commentary: "")
        ctx.insert(e26_1_1_0_2)
        e26_1_1_0_2.keyResult = kr26_1_1_0

        let o26_1_2 = KairosObjective(title: "Stop Nicotine", sortOrder: 2)
        ctx.insert(o26_1_2)
        o26_1_2.domain = d26_1
        let kr26_1_2_0 = KairosKeyResult(title: "Nicotine-free for 90 consecutive days", sortOrder: 0)
        ctx.insert(kr26_1_2_0)
        kr26_1_2_0.objective = o26_1_2
        let e26_1_2_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .paused, rating: 0, commentary: "Bad month — Tom visiting triggered me. Need a plan, not just willpower.")
        ctx.insert(e26_1_2_0_1)
        e26_1_2_0_1.keyResult = kr26_1_2_0
        let e26_1_2_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .paused, rating: 1, commentary: "")
        ctx.insert(e26_1_2_0_2)
        e26_1_2_0_2.keyResult = kr26_1_2_0


        let d26_2 = KairosDomain(name: "Work", emoji: "◆", identityStatement: "I lead with integrity and grow professionally.", sortOrder: 2, colorHex: "#2196F3")
        ctx.insert(d26_2)
        year.domains.append(d26_2)
        let o26_2_0 = KairosObjective(title: "Fulfil Role Requirements", sortOrder: 0)
        ctx.insert(o26_2_0)
        o26_2_0.domain = d26_2
        let kr26_2_0_0 = KairosKeyResult(title: "End-of-year review meets or exceeds expectations", sortOrder: 0)
        ctx.insert(kr26_2_0_0)
        kr26_2_0_0.objective = o26_2_0
        let e26_2_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "All going well so far")
        ctx.insert(e26_2_0_0_1)
        e26_2_0_0_1.keyResult = kr26_2_0_0
        let e26_2_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "")
        ctx.insert(e26_2_0_0_2)
        e26_2_0_0_2.keyResult = kr26_2_0_0

        let o26_2_1 = KairosObjective(title: "Thrive at Work", sortOrder: 1)
        ctx.insert(o26_2_1)
        o26_2_1.domain = d26_2
        let kr26_2_1_0 = KairosKeyResult(title: "Travel to India — trip completed", sortOrder: 0)
        ctx.insert(kr26_2_1_0)
        kr26_2_1_0.objective = o26_2_1
        let e26_2_1_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "All going well so far")
        ctx.insert(e26_2_1_0_1)
        e26_2_1_0_1.keyResult = kr26_2_1_0
        let e26_2_1_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_1_0_2)
        e26_2_1_0_2.keyResult = kr26_2_1_0
        let kr26_2_1_1 = KairosKeyResult(title: "Travel to Singapore — trip completed", sortOrder: 1)
        ctx.insert(kr26_2_1_1)
        kr26_2_1_1.objective = o26_2_1
        let e26_2_1_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_2_1_1_1)
        e26_2_1_1_1.keyResult = kr26_2_1_1
        let e26_2_1_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_1_1_2)
        e26_2_1_1_2.keyResult = kr26_2_1_1
        let kr26_2_1_2 = KairosKeyResult(title: "Attend at least 6 team/social aperos", sortOrder: 2)
        ctx.insert(kr26_2_1_2)
        kr26_2_1_2.objective = o26_2_1
        let e26_2_1_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_2_1_2_1)
        e26_2_1_2_1.keyResult = kr26_2_1_2
        let e26_2_1_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 3, commentary: "Visited Jas' Apero")
        ctx.insert(e26_2_1_2_2)
        e26_2_1_2_2.keyResult = kr26_2_1_2

        let o26_2_2 = KairosObjective(title: "Complete CISM", sortOrder: 2)
        ctx.insert(o26_2_2)
        o26_2_2.domain = d26_2
        let kr26_2_2_0 = KairosKeyResult(title: "Online training completed", sortOrder: 0)
        ctx.insert(kr26_2_2_0)
        kr26_2_2_0.objective = o26_2_2
        let e26_2_2_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "Good initial progress this month")
        ctx.insert(e26_2_2_0_1)
        e26_2_2_0_1.keyResult = kr26_2_2_0
        let e26_2_2_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 2, commentary: "")
        ctx.insert(e26_2_2_0_2)
        e26_2_2_0_2.keyResult = kr26_2_2_0
        let kr26_2_2_1 = KairosKeyResult(title: "Bootcamp attended", sortOrder: 1)
        ctx.insert(kr26_2_2_1)
        kr26_2_2_1.objective = o26_2_2
        let e26_2_2_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_1_1)
        e26_2_2_1_1.keyResult = kr26_2_2_1
        let e26_2_2_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_1_2)
        e26_2_2_1_2.keyResult = kr26_2_2_1
        let kr26_2_2_2 = KairosKeyResult(title: "Exam passed", sortOrder: 2)
        ctx.insert(kr26_2_2_2)
        kr26_2_2_2.objective = o26_2_2
        let e26_2_2_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_2_1)
        e26_2_2_2_1.keyResult = kr26_2_2_2
        let e26_2_2_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_2_2)
        e26_2_2_2_2.keyResult = kr26_2_2_2
        let kr26_2_2_3 = KairosKeyResult(title: "Certification submitted", sortOrder: 3)
        ctx.insert(kr26_2_2_3)
        kr26_2_2_3.objective = o26_2_2
        let e26_2_2_3_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_3_1)
        e26_2_2_3_1.keyResult = kr26_2_2_3
        let e26_2_2_3_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_2_3_2)
        e26_2_2_3_2.keyResult = kr26_2_2_3

        let o26_2_3 = KairosObjective(title: "Develop LLM Fluency", sortOrder: 3)
        ctx.insert(o26_2_3)
        o26_2_3.domain = d26_2
        let kr26_2_3_0 = KairosKeyResult(title: "LLM book finished and notes written", sortOrder: 0)
        ctx.insert(kr26_2_3_0)
        kr26_2_3_0.objective = o26_2_3
        let e26_2_3_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_2_3_0_1)
        e26_2_3_0_1.keyResult = kr26_2_3_0
        let e26_2_3_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 2, commentary: "Weak only because I've done some additional work")
        ctx.insert(e26_2_3_0_2)
        e26_2_3_0_2.keyResult = kr26_2_3_0


        let d26_3 = KairosDomain(name: "Spirit", emoji: "◆", identityStatement: "I cultivate inner stillness and philosophical curiosity.", sortOrder: 3, colorHex: "#9C27B0")
        ctx.insert(d26_3)
        year.domains.append(d26_3)
        let o26_3_0 = KairosObjective(title: "Deepen Qi Gong Practice", sortOrder: 0)
        ctx.insert(o26_3_0)
        o26_3_0.domain = d26_3
        let kr26_3_0_0 = KairosKeyResult(title: "Daily practice streak maintained (no 2+ day gaps)", sortOrder: 0)
        ctx.insert(kr26_3_0_0)
        kr26_3_0_0.objective = o26_3_0
        let e26_3_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "Core part of life. Progress feels slow — waiting on Guido for Dragon Form.")
        ctx.insert(e26_3_0_0_1)
        e26_3_0_0_1.keyResult = kr26_3_0_0
        let e26_3_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "Some good progress here, but some interruption in Tanzania")
        ctx.insert(e26_3_0_0_2)
        e26_3_0_0_2.keyResult = kr26_3_0_0
        let kr26_3_0_1 = KairosKeyResult(title: "Weekly lesson attendance consistent", sortOrder: 1)
        ctx.insert(kr26_3_0_1)
        kr26_3_0_1.objective = o26_3_0
        let e26_3_0_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_3_0_1_1)
        e26_3_0_1_1.keyResult = kr26_3_0_1
        let e26_3_0_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 3, commentary: "Getting back into it")
        ctx.insert(e26_3_0_1_2)
        e26_3_0_1_2.keyResult = kr26_3_0_1
        let kr26_3_0_2 = KairosKeyResult(title: "Dragon Form learned to full sequence", sortOrder: 2)
        ctx.insert(kr26_3_0_2)
        kr26_3_0_2.objective = o26_3_0
        let e26_3_0_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_3_0_2_1)
        e26_3_0_2_1.keyResult = kr26_3_0_2
        let e26_3_0_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 2, commentary: "I've not used my notes to practice, relying on Guido to bring his")
        ctx.insert(e26_3_0_2_2)
        e26_3_0_2_2.keyResult = kr26_3_0_2

        let o26_3_1 = KairosObjective(title: "Expand Philosophical Horizon", sortOrder: 1)
        ctx.insert(o26_3_1)
        o26_3_1.domain = d26_3
        let kr26_3_1_0 = KairosKeyResult(title: "Attend at least 3 mind-broadening events (Pari or equiv)", sortOrder: 0)
        ctx.insert(kr26_3_1_0)
        kr26_3_1_0.objective = o26_3_1
        let e26_3_1_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "Looking into Pari — close to committing")
        ctx.insert(e26_3_1_0_1)
        e26_3_1_0_1.keyResult = kr26_3_1_0
        let e26_3_1_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 2, commentary: "Pari scheduled, but nothing else identified yet")
        ctx.insert(e26_3_1_0_2)
        e26_3_1_0_2.keyResult = kr26_3_1_0
        let kr26_3_1_1 = KairosKeyResult(title: "Journaling maintained — at least 4 entries per month", sortOrder: 1)
        ctx.insert(kr26_3_1_1)
        kr26_3_1_1.objective = o26_3_1
        let e26_3_1_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "Writing more regularly")
        ctx.insert(e26_3_1_1_1)
        e26_3_1_1_1.keyResult = kr26_3_1_1
        let e26_3_1_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "This is going well")
        ctx.insert(e26_3_1_1_2)
        e26_3_1_1_2.keyResult = kr26_3_1_1


        let d26_4 = KairosDomain(name: "Sport", emoji: "◆", identityStatement: "I show up to train with discipline and heart.", sortOrder: 4, colorHex: "#FF5722")
        ctx.insert(d26_4)
        year.domains.append(d26_4)
        let o26_4_0 = KairosObjective(title: "Advance in Karate", sortOrder: 0)
        ctx.insert(o26_4_0)
        o26_4_0.domain = d26_4
        let kr26_4_0_0 = KairosKeyResult(title: "Attend karate twice a week for at least 40 weeks", sortOrder: 0)
        ctx.insert(kr26_4_0_0)
        kr26_4_0_0.objective = o26_4_0
        let e26_4_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .paused, rating: 0, commentary: "Very poor month — attendance pattern needs resetting")
        ctx.insert(e26_4_0_0_1)
        e26_4_0_0_1.keyResult = kr26_4_0_0
        let e26_4_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 3, commentary: "Improving here and rebuilding commitment")
        ctx.insert(e26_4_0_0_2)
        e26_4_0_0_2.keyResult = kr26_4_0_0
        let kr26_4_0_1 = KairosKeyResult(title: "2nd Dan grading attempted by year end", sortOrder: 1)
        ctx.insert(kr26_4_0_1)
        kr26_4_0_1.objective = o26_4_0
        let e26_4_0_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_4_0_1_1)
        e26_4_0_1_1.keyResult = kr26_4_0_1
        let e26_4_0_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .initialized, rating: 3, commentary: "Spoke to Sensei, and heard again today…")
        ctx.insert(e26_4_0_1_2)
        e26_4_0_1_2.keyResult = kr26_4_0_1


        let d26_5 = KairosDomain(name: "Kids", emoji: "◆", identityStatement: "I am a present, patient, and invested father.", sortOrder: 5, colorHex: "#FFC107")
        ctx.insert(d26_5)
        year.domains.append(d26_5)
        let o26_5_0 = KairosObjective(title: "Invest in Aiden", sortOrder: 0)
        ctx.insert(o26_5_0)
        o26_5_0.domain = d26_5
        let kr26_5_0_0 = KairosKeyResult(title: "Regular quality time — minimum 2 intentional sessions/month", sortOrder: 0)
        ctx.insert(kr26_5_0_0)
        kr26_5_0_0.objective = o26_5_0
        let e26_5_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "Solid relationship. Shared-time frustration remains real.")
        ctx.insert(e26_5_0_0_1)
        e26_5_0_0_1.keyResult = kr26_5_0_0
        let e26_5_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "")
        ctx.insert(e26_5_0_0_2)
        e26_5_0_0_2.keyResult = kr26_5_0_0
        let kr26_5_0_1 = KairosKeyResult(title: "Study habits stabilised — consistent homework routine", sortOrder: 1)
        ctx.insert(kr26_5_0_1)
        kr26_5_0_1.objective = o26_5_0
        let e26_5_0_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_5_0_1_1)
        e26_5_0_1_1.keyResult = kr26_5_0_1
        let e26_5_0_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "Lerncoach is helping")
        ctx.insert(e26_5_0_1_2)
        e26_5_0_1_2.keyResult = kr26_5_0_1
        let kr26_5_0_2 = KairosKeyResult(title: "Organisation improved — uses a system independently", sortOrder: 2)
        ctx.insert(kr26_5_0_2)
        kr26_5_0_2.objective = o26_5_0
        let e26_5_0_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_5_0_2_1)
        e26_5_0_2_1.keyResult = kr26_5_0_2
        let e26_5_0_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .initialized, rating: 3, commentary: "Need to continue to work here")
        ctx.insert(e26_5_0_2_2)
        e26_5_0_2_2.keyResult = kr26_5_0_2
        let kr26_5_0_3 = KairosKeyResult(title: "Progresses to Sek A", sortOrder: 3)
        ctx.insert(kr26_5_0_3)
        kr26_5_0_3.objective = o26_5_0
        let e26_5_0_3_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .initialized, rating: 0, commentary: "")
        ctx.insert(e26_5_0_3_1)
        e26_5_0_3_1.keyResult = kr26_5_0_3
        let e26_5_0_3_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .notStarted, rating: 0, commentary: "Pending confirmation next week")
        ctx.insert(e26_5_0_3_2)
        e26_5_0_3_2.keyResult = kr26_5_0_3

        let o26_5_1 = KairosObjective(title: "Stay Connected with Noam", sortOrder: 1)
        ctx.insert(o26_5_1)
        o26_5_1.domain = d26_5
        let kr26_5_1_0 = KairosKeyResult(title: "Meaningful 1:1 time — at least once a month", sortOrder: 0)
        ctx.insert(kr26_5_1_0)
        kr26_5_1_0.objective = o26_5_1
        let e26_5_1_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "Hardly any time — teenager dynamic is real but passivity won't help")
        ctx.insert(e26_5_1_0_1)
        e26_5_1_0_1.keyResult = kr26_5_1_0
        let e26_5_1_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .paused, rating: 1, commentary: "struggling to find time and interest from him")
        ctx.insert(e26_5_1_0_2)
        e26_5_1_0_2.keyResult = kr26_5_1_0
        let kr26_5_1_1 = KairosKeyResult(title: "Apprenticeship year 1 completed — you've been supportive", sortOrder: 1)
        ctx.insert(kr26_5_1_1)
        kr26_5_1_1.objective = o26_5_1
        let e26_5_1_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_5_1_1_1)
        e26_5_1_1_1.keyResult = kr26_5_1_1
        let e26_5_1_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_5_1_1_2)
        e26_5_1_1_2.keyResult = kr26_5_1_1


        let d26_6 = KairosDomain(name: "Love", emoji: "◆", identityStatement: "I nurture love with presence and honesty.", sortOrder: 6, colorHex: "#E91E63")
        ctx.insert(d26_6)
        year.domains.append(d26_6)
        let o26_6_0 = KairosObjective(title: "Nurture Relationship with Jas", sortOrder: 0)
        ctx.insert(o26_6_0)
        o26_6_0.domain = d26_6
        let kr26_6_0_0 = KairosKeyResult(title: "Dedicated time alone together — at least twice a month", sortOrder: 0)
        ctx.insert(kr26_6_0_0)
        kr26_6_0_0.objective = o26_6_0
        let e26_6_0_0_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "Lots of time together; she seems in a great place.")
        ctx.insert(e26_6_0_0_1)
        e26_6_0_0_1.keyResult = kr26_6_0_0
        let e26_6_0_0_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 5, commentary: "")
        ctx.insert(e26_6_0_0_2)
        e26_6_0_0_2.keyResult = kr26_6_0_0
        let kr26_6_0_1 = KairosKeyResult(title: "Create at least 4 shared experiences with the kids", sortOrder: 1)
        ctx.insert(kr26_6_0_1)
        kr26_6_0_1.objective = o26_6_0
        let e26_6_0_1_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_6_0_1_1)
        e26_6_0_1_1.keyResult = kr26_6_0_1
        let e26_6_0_1_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 5, commentary: "Tanzania")
        ctx.insert(e26_6_0_1_2)
        e26_6_0_1_2.keyResult = kr26_6_0_1
        let kr26_6_0_2 = KairosKeyResult(title: "Consistently show up with presence and patience", sortOrder: 2)
        ctx.insert(kr26_6_0_2)
        kr26_6_0_2.objective = o26_6_0
        let e26_6_0_2_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .inProgress, rating: 0, commentary: "")
        ctx.insert(e26_6_0_2_1)
        e26_6_0_2_1.keyResult = kr26_6_0_2
        let e26_6_0_2_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 4, commentary: "")
        ctx.insert(e26_6_0_2_2)
        e26_6_0_2_2.keyResult = kr26_6_0_2
        let kr26_6_0_3 = KairosKeyResult(title: "Have one honest conversation per quarter about how she's feeling", sortOrder: 3)
        ctx.insert(kr26_6_0_3)
        kr26_6_0_3.objective = o26_6_0
        let e26_6_0_3_1 = KairosMonthlyEntry(year: 2026, month: 1, status: .notStarted, rating: 0, commentary: "")
        ctx.insert(e26_6_0_3_1)
        e26_6_0_3_1.keyResult = kr26_6_0_3
        let e26_6_0_3_2 = KairosMonthlyEntry(year: 2026, month: 2, status: .inProgress, rating: 5, commentary: "We had a big one just now")
        ctx.insert(e26_6_0_3_2)
        e26_6_0_3_2.keyResult = kr26_6_0_3


    }
}