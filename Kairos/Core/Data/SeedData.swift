import Foundation
import SwiftData

// MARK: - SeedData
// Migrated from 2025_OKRs.xlsx and 2026_OKRs_v4.xlsx
// Run once on first launch. Idempotent.

@MainActor
enum SeedData {

    static func seedIfNeeded(in container: ModelContainer) async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<KairosYear>()
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else { return }

        seed2026(context: context)
        seed2025(context: context)

        try? context.save()
    }

    // MARK: - 2026

    private static func seed2026(context: ModelContext) {
        let year = KairosYear(year: 2026, intention: "Semper porro contende")
        context.insert(year)

        year.domains.append(contentsOf: [
            makeHealth(context: context),
            makeWork(context: context),
            makeSpirit(context: context),
            makeSport(context: context),
            makeKids(context: context),
            makeLove(context: context),
            makeExternalities(context: context)
        ])
    }

    // MARK: Health

    private static func makeHealth(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Health", emoji: "🫀", sortOrder: 0, colorHex: "#4A9A6A")
        context.insert(d)

        let healthCheck = obj("Annual Health Check", 0, d, context)
        kr("Urologist check up completed", 0, healthCheck, context, [
            entry(2026, 1, .initialized), entry(2026, 2, .inProgress)
        ])
        kr("Teeth cleaning and check up completed", 1, healthCheck, context, [
            entry(2026, 1, .initialized), entry(2026, 2, .inProgress)
        ])
        kr("Cholesterol measured — result manageable", 2, healthCheck, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])
        kr("Medbase full check completed", 3, healthCheck, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])

        let weight = obj("Weight Management", 1, d, context)
        kr("Weight maintained between 80–83 kg all year", 0, weight, context, [
            entry(2026, 1, .initialized, note: "About 81.5 kg — on track"),
            entry(2026, 2, .inProgress, rating: 2)
        ])

        let nicotine = obj("Stop Nicotine", 2, d, context)
        kr("Nicotine-free for 90 consecutive days", 0, nicotine, context, [
            entry(2026, 1, .paused, note: "Bad month — Tom visiting triggered me. Need a plan, not just willpower."),
            entry(2026, 2, .paused, rating: 1)
        ])

        return d
    }

    // MARK: Work

    private static func makeWork(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Work", emoji: "💼", sortOrder: 1, colorHex: "#4A7AA8")
        context.insert(d)

        let fulfil = obj("Fulfil Role Requirements", 0, d, context)
        kr("End-of-year review meets or exceeds expectations", 0, fulfil, context, [
            entry(2026, 1, .initialized, note: "All going well so far"),
            entry(2026, 2, .inProgress, rating: 4)
        ])

        let thrive = obj("Thrive at Work", 1, d, context)
        kr("Travel to India — trip completed", 0, thrive, context, [
            entry(2026, 1, .initialized, note: "All going well so far"),
            entry(2026, 2, .notStarted)
        ])
        kr("Travel to Singapore — trip completed", 1, thrive, context, [
            entry(2026, 1, .initialized), entry(2026, 2, .notStarted)
        ])
        kr("Attend at least 6 team/social aperos", 2, thrive, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .inProgress, rating: 3, note: "Visited Jas' Apero")
        ])

        let cism = obj("Complete CISM", 2, d, context)
        kr("Online training completed", 0, cism, context, [
            entry(2026, 1, .initialized, note: "Good initial progress this month"),
            entry(2026, 2, .inProgress, rating: 2)
        ])
        kr("Bootcamp attended", 1, cism, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])
        kr("Exam passed", 2, cism, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])
        kr("Certification submitted", 3, cism, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])

        let llm = obj("Develop LLM Fluency", 3, d, context)
        kr("LLM book finished and notes written", 0, llm, context, [
            entry(2026, 1, .notStarted),
            entry(2026, 2, .inProgress, rating: 2, note: "Weak only because I've done some additional work")
        ])

        return d
    }

    // MARK: Spirit

    private static func makeSpirit(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Spirit", emoji: "✨", sortOrder: 2, colorHex: "#9A6AAA")
        context.insert(d)

        let qigong = obj("Deepen Qi Gong Practice", 0, d, context)
        kr("Daily practice streak maintained (no 2+ day gaps)", 0, qigong, context, [
            entry(2026, 1, .inProgress, note: "Core part of life. Progress feels slow — waiting on Guido for Dragon Form."),
            entry(2026, 2, .inProgress, rating: 4, note: "Some good progress here, but some interruption in Tanzania")
        ])
        kr("Weekly lesson attendance consistent", 1, qigong, context, [
            entry(2026, 1, .inProgress),
            entry(2026, 2, .inProgress, rating: 3, note: "Getting back into it")
        ])
        kr("Dragon Form learned to full sequence", 2, qigong, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .inProgress, rating: 2, note: "I've not used my notes to practice, relying on Guido to bring his")
        ])

        let philosophy = obj("Expand Philosophical Horizon", 1, d, context)
        kr("Attend at least 3 mind-broadening events (Pari or equiv)", 0, philosophy, context, [
            entry(2026, 1, .initialized, note: "Looking into Pari — close to committing"),
            entry(2026, 2, .inProgress, rating: 2, note: "Pari scheduled, but nothing else identified yet")
        ])
        kr("Journaling maintained — at least 4 entries per month", 1, philosophy, context, [
            entry(2026, 1, .inProgress, note: "Writing more regularly"),
            entry(2026, 2, .inProgress, rating: 4, note: "This is going well")
        ])

        return d
    }

    // MARK: Sport

    private static func makeSport(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Sport", emoji: "🥋", sortOrder: 3, colorHex: "#AA7A4A")
        context.insert(d)

        let karate = obj("Advance in Karate", 0, d, context)
        kr("Attend karate twice a week for at least 40 weeks", 0, karate, context, [
            entry(2026, 1, .paused, note: "Very poor month — attendance pattern needs resetting"),
            entry(2026, 2, .inProgress, rating: 3, note: "Improving here and rebuilding commitment")
        ])
        kr("2nd Dan grading attempted by year end", 1, karate, context, [
            entry(2026, 1, .notStarted),
            entry(2026, 2, .initialized, rating: 3, note: "Spoke to Sensei, and heard again today…")
        ])

        return d
    }

    // MARK: Kids

    private static func makeKids(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Kids", emoji: "👨‍👦", sortOrder: 4, colorHex: "#AA9A4A")
        context.insert(d)

        let aiden = obj("Invest in Aiden", 0, d, context)
        kr("Regular quality time — minimum 2 intentional sessions/month", 0, aiden, context, [
            entry(2026, 1, .inProgress, note: "Solid relationship. Shared-time frustration remains real."),
            entry(2026, 2, .inProgress, rating: 4)
        ])
        kr("Study habits stabilised — consistent homework routine", 1, aiden, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .inProgress, rating: 4, note: "Lerncoach is helping")
        ])
        kr("Organisation improved — uses a system independently", 2, aiden, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .initialized, rating: 3, note: "Need to continue to work here")
        ])
        kr("Progresses to Sek A", 3, aiden, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .notStarted, note: "Pending confirmation next week")
        ])

        let noam = obj("Stay Connected with Noam", 1, d, context)
        kr("Meaningful 1:1 time — at least once a month", 0, noam, context, [
            entry(2026, 1, .notStarted, note: "Hardly any time — teenager dynamic is real but passivity won't help"),
            entry(2026, 2, .paused, rating: 1, note: "Struggling to find time and interest from him")
        ])
        kr("Apprenticeship year 1 completed — you've been supportive", 1, noam, context, [
            entry(2026, 1, .notStarted),
            entry(2026, 2, .inProgress)
        ])

        return d
    }

    // MARK: Love

    private static func makeLove(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Love", emoji: "💛", sortOrder: 5, colorHex: "#AA4A6A")
        context.insert(d)

        let jas = obj("Nurture Relationship with Jas", 0, d, context)
        kr("Dedicated time alone together — at least twice a month", 0, jas, context, [
            entry(2026, 1, .inProgress, note: "Lots of time together; she seems in a great place."),
            entry(2026, 2, .inProgress, rating: 5)
        ])
        kr("Create at least 4 shared experiences with the kids", 1, jas, context, [
            entry(2026, 1, .inProgress),
            entry(2026, 2, .inProgress, rating: 5, note: "Tanzania")
        ])
        kr("Consistently show up with presence and patience", 2, jas, context, [
            entry(2026, 1, .inProgress),
            entry(2026, 2, .inProgress, rating: 4)
        ])
        kr("Have one honest conversation per quarter about how she's feeling", 3, jas, context, [
            entry(2026, 1, .notStarted),
            entry(2026, 2, .inProgress, rating: 5, note: "We had a big one just now")
        ])

        return d
    }

    // MARK: Externalities

    private static func makeExternalities(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Externalities", emoji: "🏠", sortOrder: 6, colorHex: "#6A8AAA")
        context.insert(d)

        let car = obj("New Car", 0, d, context)
        kr("Car lease arranged and signed", 0, car, context, [
            entry(2026, 1, .inProgress, note: "Hope to conclude in February"),
            entry(2026, 2, .inProgress, rating: 4, note: "Will complete March 14th — need to sell A3")
        ])

        let home = obj("New Home", 1, d, context)
        kr("Suitable property identified", 0, home, context, [
            entry(2026, 1, .initialized, note: "Need to pick up the drive I had here."),
            entry(2026, 2, .inProgress, rating: 3)
        ])
        kr("Mortgage arranged and approved", 1, home, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .blocked, rating: 1, note: "Funds locked in SS72")
        ])
        kr("Move completed", 2, home, context, [
            entry(2026, 1, .notStarted), entry(2026, 2, .notStarted)
        ])

        let teeth = obj("Get Teeth Fixed", 2, d, context)
        kr("All gaps filled by Q2", 0, teeth, context, [
            entry(2026, 1, .initialized),
            entry(2026, 2, .initialized, note: "Will schedule in March")
        ])

        return d
    }

    // MARK: - 2025 (Historical migration from flat list)

    private static func seed2025(context: ModelContext) {
        let year = KairosYear(year: 2025, intention: "")
        context.insert(year)

        year.domains.append(contentsOf: [
            make2025Health(context: context),
            make2025Work(context: context),
            make2025Spirit(context: context),
            make2025Sport(context: context),
            make2025Kids(context: context),
            make2025Love(context: context)
        ])
    }

    private static func make2025Health(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Health", emoji: "🫀", sortOrder: 0, colorHex: "#4A9A6A")
        context.insert(d)

        let drinking = obj("Drinking", 0, d, context)
        kr("Substantially reduced alcohol consumption — 3 days/week max", 0, drinking, context, [
            entry(2025, 8, .inProgress, note: "10 days and counting, significant improvements in weight, sleep and other aspects"),
            entry(2025, 9, .inProgress, note: "Some events but continues to be significantly reduced and noticeable"),
            entry(2025, 11, .inProgress, note: "This has been generally acceptable. Regular breaks, limited consumption, some sense."),
            entry(2025, 12, .inProgress, note: "All over the place, as expected")
        ])

        let nutrition = obj("Nutrition", 1, d, context)
        kr("Red meat <1/week, cholesterol balanced, uric acid balanced", 0, nutrition, context, [
            entry(2025, 5, .inProgress, note: "Been a terrible few weeks for red meat (Wagyu, too!), regular booze."),
            entry(2025, 6, .inProgress, note: "Food has improved; less red meat, more vegetables, intermittent fasting."),
            entry(2025, 8, .inProgress, note: "Small improvements from the BJB Health Check, still eating too much meat"),
            entry(2025, 9, .inProgress, note: "Weight loss significant. Still eating too much meat but reduced red meat."),
            entry(2025, 11, .inProgress, note: "Still at 80kg mostly. Eating more or less OK. Some fasting."),
            entry(2025, 12, .inProgress, note: "Weight increase")
        ])

        let nicotine = obj("Stop Nicotine / No Smoking", 2, d, context)
        kr("No smoking — VO2 Max approx. 45", 0, nicotine, context, [
            entry(2025, 5, .inProgress, note: "Can't remember when I last had a cigarette. Running again. VO2 max 36.2"),
            entry(2025, 6, .inProgress, note: "Had some smokes with Andreas H.; VO2 max 37.4. Improving"),
            entry(2025, 7, .inProgress, note: "Smoked at Jasمeet's housewarming, then cut out again. Still reliant on pouches."),
            entry(2025, 9, .inProgress, note: "Still not smoking but little running. Never 34."),
            entry(2025, 11, .inProgress, note: "Not smoked. Also dropped nicotine in SGP."),
            entry(2025, 12, .done, note: "Still no smoking, no nicotine, some temptation in Thailand, but worked out ok")
        ])

        return d
    }

    private static func make2025Work(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Work", emoji: "💼", sortOrder: 1, colorHex: "#4A7AA8")
        context.insert(d)

        let dqf = obj("Data Quality Framework Implementation", 0, d, context)
        kr("Complete Implementation in H1", 0, dqf, context, [
            entry(2025, 5, .inProgress, note: "On track to deliver this, and be ready to re-align to the re-org."),
            entry(2025, 6, .inProgress, note: "BAU and ready to support and enable the business; they have other priorities."),
            entry(2025, 9, .inProgress, note: "Well… this is almost 'ready-to-use', but this is out of my hands now."),
            entry(2025, 11, .done, note: "Done."),
            entry(2025, 12, .done, note: "Done.")
        ])

        let newRole = obj("New Role", 1, d, context)
        kr("Started new role at BJB", 0, newRole, context, [
            entry(2025, 5, .inProgress, note: "TBD"),
            entry(2025, 6, .inProgress, note: "Discussions in progress"),
            entry(2025, 9, .done, note: "New job in BJB, feels promising. Secure. Respected by leadership."),
            entry(2025, 11, .done, note: "Up and running as Head of Data Governance Risk. Making a difference."),
            entry(2025, 12, .done, note: "All good")
        ])

        let llm2025 = obj("LLM Fluency", 2, d, context)
        kr("Accelerated hands-on learning path with AI and latest technologies", 0, llm2025, context, [
            entry(2025, 8, .inProgress, note: "Started to spend some time increasing knowledge on LLMs"),
            entry(2025, 9, .inProgress, note: "Great progress. Using AI to understand AI, build apps, rediscovered love of technology."),
            entry(2025, 11, .inProgress, note: "Dropped off the radar — holidays, travel, sickness"),
            entry(2025, 12, .inProgress, note: "Some focus returned, but not really much")
        ])

        return d
    }

    private static func make2025Spirit(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Spirit", emoji: "✨", sortOrder: 2, colorHex: "#9A6AAA")
        context.insert(d)

        let qigong = obj("Qi Gong", 0, d, context)
        kr("Continued daily practice in the mornings", 0, qigong, context, [
            entry(2025, 5, .inProgress, note: "Missed a bit with Japan and struggled to get back up to speed however overall very strong"),
            entry(2025, 6, .inProgress, note: "Generally practicing Qi Gong daily, though morning stacking has fallen down."),
            entry(2025, 7, .inProgress, note: "Although I haven't practiced daily, I have reintroduced meditation and can feel progress."),
            entry(2025, 8, .inProgress, note: "Significant improvements, mostly daily practice, great benefits from the lessons."),
            entry(2025, 9, .inProgress, note: "Daily Qi gong is showing benefits"),
            entry(2025, 11, .inProgress, note: "Daily Qi gong is showing benefits — really enjoying this work, making real progress."),
            entry(2025, 12, .inProgress, note: "I continued to practice though my streak has been propped up in parts")
        ])

        let writing = obj("Writing", 1, d, context)
        kr("Start to write authentically. Drop pretense, there's no audience.", 0, writing, context, [
            entry(2025, 8, .inProgress, note: "I have been writing, inquiring. On and off."),
            entry(2025, 9, .inProgress, note: "This has been quiet in September, but really it's about the practice."),
            entry(2025, 11, .inProgress, note: "Hardly written for two months. Not sure why."),
            entry(2025, 12, .inProgress, note: "Still little writing, journaling, or even reflection")
        ])

        return d
    }

    private static func make2025Sport(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Sport", emoji: "🥋", sortOrder: 3, colorHex: "#AA7A4A")
        context.insert(d)

        let karate = obj("Karate", 0, d, context)
        kr("2nd Dan readiness, 1–2 sessions per week minimum", 0, karate, context, [
            entry(2025, 5, .inProgress, note: "Mixed performance. Too many breaks, missing consistency. Not sure if/when 2nd Dan possible"),
            entry(2025, 6, .inProgress, note: "Definitely been a good month, averaged above two sessions per week."),
            entry(2025, 7, .inProgress, note: "Not great, absences. Missing consistency."),
            entry(2025, 8, .inProgress, note: "1–2 sessions per week on average. Need to work on my hips."),
            entry(2025, 11, .inProgress, note: "Reduced due to travel and sickness, but enjoying going. I've given up 2nd dan ambitions"),
            entry(2025, 12, .inProgress, note: "OK start, but drifted off mid December")
        ])

        let strengthTraining = obj("Strength Training", 1, d, context)
        kr("Two sessions a week / increase max dumbbell to 10kg", 0, strengthTraining, context, [
            entry(2025, 5, .inProgress, note: "In progress"),
            entry(2025, 6, .inProgress, note: "3 perfect weeks of strength, taking longer than 3, but stronger."),
            entry(2025, 7, .inProgress, note: "After completion of the strength program I have dipped to once a week."),
            entry(2025, 9, .inProgress, note: "Maybe once a week, or 1.5 on average."),
            entry(2025, 11, .inProgress, note: "Impacted by travel and sickness but I have worked continuously."),
            entry(2025, 12, .inProgress, note: "Weights progressing, bought more just now.")
        ])

        return d
    }

    private static func make2025Kids(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Kids", emoji: "👨‍👦", sortOrder: 4, colorHex: "#AA9A4A")
        context.insert(d)

        let aiden = obj("Aiden", 0, d, context)
        kr("Assessment in Q1, next steps in Q2, defined Year 6 approach", 0, aiden, context, [
            entry(2025, 5, .inProgress, note: "Assessment complete, diagnosis defined, next steps Psychologist in discussion"),
            entry(2025, 7, .inProgress, note: "Some concrete next steps agreed with Melanie and with Aiden."),
            entry(2025, 8, .inProgress, note: "Tricky start to Year 6. Further reinforcement needed, open to considering medication."),
            entry(2025, 9, .inProgress, note: "Noticeable challenges in regulating emotions. Good results in general."),
            entry(2025, 11, .inProgress, note: "We've tried Ritalin but without much success. School still a bit of a battle."),
            entry(2025, 12, .inProgress, note: "Ritalin didn't work. Still struggling, no real alternatives in sight.")
        ])

        let noam = obj("Noam", 1, d, context)
        kr("Basics in place (eating, washing, tidying up)", 0, noam, context, [
            entry(2025, 5, .inProgress, note: "OK"),
            entry(2025, 7, .inProgress, note: "Still a bit of a struggle."),
            entry(2025, 8, .inProgress, note: "Work has made a difference. Very structured, motivated, engaged, great to see."),
            entry(2025, 9, .inProgress, note: "Work continues to benefit Noam, he manages work-life balance well."),
            entry(2025, 11, .inProgress, note: "Work is ok, completed probationary period but with expected feedback."),
            entry(2025, 12, .done, note: "Yes, this is going well. School too. Getting things done, quietly, minimally.")
        ])

        return d
    }

    private static func make2025Love(context: ModelContext) -> KairosDomain {
        let d = KairosDomain(name: "Love", emoji: "💛", sortOrder: 5, colorHex: "#AA4A6A")
        context.insert(d)

        let marriage = obj("Marriage Plans", 0, d, context)
        kr("A plan with Jas by end of 2025", 0, marriage, context, [
            entry(2025, 5, .inProgress, note: "Still requires moving in, which I can't commit to."),
            entry(2025, 6, .inProgress, note: "Won't happen until we move in which is a few years away."),
            entry(2025, 7, .inProgress, note: "Big discussions, but getting closer to understanding each other."),
            entry(2025, 8, .inProgress, note: "Some progress spending more time together and Big Picture alignment."),
            entry(2025, 9, .inProgress, note: "Her work and some intense discussions are bearing fruit. This feels a lot better."),
            entry(2025, 11, .inProgress, note: "We are doing really well together. There is a lot of love and care and passion."),
            entry(2025, 12, .inProgress, note: "Awesome")
        ])

        return d
    }

    // MARK: - Helpers

    @discardableResult
    private static func obj(_ title: String, _ order: Int, _ domain: KairosDomain, _ context: ModelContext) -> KairosObjective {
        let o = KairosObjective(title: title, sortOrder: order)
        context.insert(o)
        domain.objectives.append(o)
        return o
    }

    private static func kr(
        _ title: String,
        _ order: Int,
        _ objective: KairosObjective,
        _ context: ModelContext,
        _ entries: [KairosMonthlyEntry]
    ) {
        let k = KairosKeyResult(title: title, sortOrder: order)
        context.insert(k)
        objective.keyResults.append(k)
        for e in entries {
            context.insert(e)
            k.entries.append(e)
        }
    }

    private static func entry(
        _ year: Int,
        _ month: Int,
        _ status: KRStatus,
        rating: Int = 0,
        note: String = ""
    ) -> KairosMonthlyEntry {
        KairosMonthlyEntry(year: year, month: month, status: status, rating: rating, commentary: note)
    }
}
