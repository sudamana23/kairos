import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Backup Root

struct KairosBackup: Codable {
    var version: Int
    var exportedAt: Date
    var years: [YearDTO]
    var pulses: [PulseDTO]
    var reviews: [ReviewDTO]

    init(years: [YearDTO], pulses: [PulseDTO], reviews: [ReviewDTO]) {
        self.version    = 1
        self.exportedAt = Date()
        self.years      = years
        self.pulses     = pulses
        self.reviews    = reviews
    }

    // MARK: Nested DTOs

    struct YearDTO: Codable {
        var id: UUID
        var year: Int
        var intention: String
        var domains: [DomainDTO]
    }

    struct DomainDTO: Codable {
        var id: UUID
        var name: String
        var emoji: String
        var identityStatement: String
        var sortOrder: Int
        var colorHex: String
        var objectives: [ObjectiveDTO]
    }

    struct ObjectiveDTO: Codable {
        var id: UUID
        var title: String
        var sortOrder: Int
        var keyResults: [KeyResultDTO]
    }

    struct KeyResultDTO: Codable {
        var id: UUID
        var title: String
        var sortOrder: Int
        var entries: [EntryDTO]
    }

    struct EntryDTO: Codable {
        var id: UUID
        var year: Int
        var month: Int
        var status: String
        var rating: Int
        var commentary: String
    }

    struct PulseDTO: Codable {
        var id: UUID
        var date: Date
        var energyLevel: Int
        var tagsRaw: String
        var transcription: String
        var note: String
        var sentimentScore: Double
        var audioFileName: String
    }

    struct ReviewDTO: Codable {
        var id: UUID
        var year: Int
        var month: Int
        var transcript: String
        var summaryPoint1: String
        var summaryPoint2: String
        var summaryPoint3: String
        var audioFileName: String
        var createdAt: Date
    }
}

// MARK: - Model → DTO conversions

extension KairosYear {
    func toDTO() -> KairosBackup.YearDTO {
        KairosBackup.YearDTO(
            id: id, year: year, intention: intention,
            domains: sortedDomains.map { $0.toDTO() }
        )
    }
}

extension KairosDomain {
    func toDTO() -> KairosBackup.DomainDTO {
        KairosBackup.DomainDTO(
            id: id, name: name, emoji: emoji,
            identityStatement: identityStatement,
            sortOrder: sortOrder, colorHex: colorHex,
            objectives: sortedObjectives.map { $0.toDTO() }
        )
    }
}

extension KairosObjective {
    func toDTO() -> KairosBackup.ObjectiveDTO {
        KairosBackup.ObjectiveDTO(
            id: id, title: title, sortOrder: sortOrder,
            keyResults: sortedKeyResults.map { $0.toDTO() }
        )
    }
}

extension KairosKeyResult {
    func toDTO() -> KairosBackup.KeyResultDTO {
        KairosBackup.KeyResultDTO(
            id: id, title: title, sortOrder: sortOrder,
            entries: entries.map { $0.toDTO() }
        )
    }
}

extension KairosMonthlyEntry {
    func toDTO() -> KairosBackup.EntryDTO {
        KairosBackup.EntryDTO(
            id: id, year: year, month: month,
            status: statusRaw, rating: rating, commentary: commentary
        )
    }
}

extension KairosWeeklyPulse {
    func toDTO() -> KairosBackup.PulseDTO {
        KairosBackup.PulseDTO(
            id: id, date: date, energyLevel: energyLevel,
            tagsRaw: tagsRaw, transcription: transcription,
            note: note, sentimentScore: sentimentScore,
            audioFileName: audioFileName
        )
    }
}

extension KairosMonthlyReview {
    func toDTO() -> KairosBackup.ReviewDTO {
        KairosBackup.ReviewDTO(
            id: id, year: year, month: month,
            transcript: transcript,
            summaryPoint1: summaryPoint1, summaryPoint2: summaryPoint2, summaryPoint3: summaryPoint3,
            audioFileName: audioFileName, createdAt: createdAt
        )
    }
}

// MARK: - FileDocument (for .fileExporter / .fileImporter)

struct KairosBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Export errors

enum KairosExportError: LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case versionMismatch(Int)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let msg): return "Export failed: \(msg)"
        case .decodingFailed(let msg): return "Import failed — the file may be corrupt or from an incompatible version. Detail: \(msg)"
        case .versionMismatch(let v):  return "Import failed: backup version \(v) is newer than this version of Kairos. Please update the app."
        }
    }
}

// MARK: - ImportResult

struct KairosImportResult {
    let yearsAdded: Int
    let pulsesAdded: Int
    let reviewsAdded: Int
    let exportedAt: Date

    var summary: String {
        var parts: [String] = []
        if yearsAdded   > 0 { parts.append("\(yearsAdded) year\(yearsAdded   == 1 ? "" : "s")") }
        if pulsesAdded  > 0 { parts.append("\(pulsesAdded) pulse\(pulsesAdded == 1 ? "" : "s")") }
        if reviewsAdded > 0 { parts.append("\(reviewsAdded) review\(reviewsAdded == 1 ? "" : "s")") }
        guard !parts.isEmpty else { return "Nothing new — all data was already up to date." }
        return "Added " + parts.joined(separator: ", ") + "."
    }
}

// MARK: - KairosExportManager

enum KairosExportManager {

    private static let maxSupportedVersion = 1

    // MARK: Export

    /// Build a JSON backup of all data.
    static func makeBackupData(years: [KairosYear], context: ModelContext) throws -> Data {
        let pulses  = (try? context.fetch(FetchDescriptor<KairosWeeklyPulse>())) ?? []
        let reviews = (try? context.fetch(FetchDescriptor<KairosMonthlyReview>())) ?? []

        let backup = KairosBackup(
            years:   years.map   { $0.toDTO() },
            pulses:  pulses.map  { $0.toDTO() },
            reviews: reviews.map { $0.toDTO() }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting     = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(backup)
        } catch {
            throw KairosExportError.encodingFailed(error.localizedDescription)
        }
    }

    // MARK: Delete all (used by onboarding replace-import)

    static func deleteAllData(in context: ModelContext) throws {
        // Must delete individually (not via context.delete(model:)) so SwiftData's
        // change tracking fires and CloudKit propagates the deletions to other devices.
        let years   = try context.fetch(FetchDescriptor<KairosYear>())
        let pulses  = try context.fetch(FetchDescriptor<KairosWeeklyPulse>())
        let reviews = try context.fetch(FetchDescriptor<KairosMonthlyReview>())

        // Delete children first to avoid constraint violations
        for year in years { year.deleteWithChildren(in: context) }
        for pulse  in pulses  { context.delete(pulse) }
        for review in reviews { context.delete(review) }

        try context.save()
    }

    // MARK: Import (merge by UUID — safe to run multiple times)

    /// Restore a backup. Always assigns fresh UUIDs so CloudKit tombstones from a
    /// prior Reset All Data never conflict with incoming records. Dedup is content-based:
    /// years by year-number, pulses by date (within 1 min), reviews by year+month.
    @discardableResult
    static func importBackup(from data: Data, into context: ModelContext) throws -> KairosImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let backup: KairosBackup
        do {
            backup = try decoder.decode(KairosBackup.self, from: data)
        } catch {
            throw KairosExportError.decodingFailed(error.localizedDescription)
        }

        guard backup.version <= maxSupportedVersion else {
            throw KairosExportError.versionMismatch(backup.version)
        }

        // Content-based dedup keys (UUIDs are NOT reused — avoids CloudKit tombstone conflicts)
        let existingYearNumbers = Set((try? context.fetch(FetchDescriptor<KairosYear>()))?.map    { $0.year } ?? [])
        let existingPulseDates  = Set((try? context.fetch(FetchDescriptor<KairosWeeklyPulse>()))?.map { $0.date.timeIntervalSince1970 } ?? [])
        let existingReviewKeys  = Set((try? context.fetch(FetchDescriptor<KairosMonthlyReview>()))?.map { "\($0.year)-\($0.month)" } ?? [])

        var yearsAdded = 0, pulsesAdded = 0, reviewsAdded = 0

        // --- Years (full cascade hierarchy) ---
        for dto in backup.years {
            guard !existingYearNumbers.contains(dto.year) else { continue }

            let year = KairosYear(year: dto.year, intention: dto.intention)
            context.insert(year)

            for dDto in dto.domains {
                let domain = KairosDomain(
                    name: dDto.name, emoji: dDto.emoji,
                    identityStatement: dDto.identityStatement,
                    sortOrder: dDto.sortOrder, colorHex: dDto.colorHex
                )
                context.insert(domain)
                year.domains.append(domain)

                for oDto in dDto.objectives {
                    let obj = KairosObjective(title: oDto.title, sortOrder: oDto.sortOrder)
                    context.insert(obj)
                    domain.objectives.append(obj)

                    for krDto in oDto.keyResults {
                        let kr = KairosKeyResult(title: krDto.title, sortOrder: krDto.sortOrder)
                        context.insert(kr)
                        obj.keyResults.append(kr)

                        for eDto in krDto.entries {
                            let entry = KairosMonthlyEntry(
                                year: eDto.year, month: eDto.month,
                                status: KRStatus(rawValue: eDto.status) ?? .notStarted,
                                rating: eDto.rating, commentary: eDto.commentary
                            )
                            context.insert(entry)
                            kr.entries.append(entry)
                        }
                    }
                }
            }
            yearsAdded += 1
        }

        // --- Weekly pulses (dedup within 60 seconds of an existing pulse date) ---
        for dto in backup.pulses {
            let t = dto.date.timeIntervalSince1970
            let isDuplicate = existingPulseDates.contains { abs($0 - t) < 60 }
            guard !isDuplicate else { continue }
            let pulse = KairosWeeklyPulse(date: dto.date)
            pulse.energyLevel    = dto.energyLevel
            pulse.tagsRaw        = dto.tagsRaw
            pulse.transcription  = dto.transcription
            pulse.note           = dto.note
            pulse.sentimentScore = dto.sentimentScore
            pulse.audioFileName  = dto.audioFileName
            context.insert(pulse)
            pulsesAdded += 1
        }

        // --- Monthly reviews ---
        for dto in backup.reviews {
            guard !existingReviewKeys.contains("\(dto.year)-\(dto.month)") else { continue }
            let review = KairosMonthlyReview(year: dto.year, month: dto.month)
            review.transcript    = dto.transcript
            review.summaryPoint1 = dto.summaryPoint1
            review.summaryPoint2 = dto.summaryPoint2
            review.summaryPoint3 = dto.summaryPoint3
            review.audioFileName = dto.audioFileName
            review.createdAt     = dto.createdAt
            context.insert(review)
            reviewsAdded += 1
        }

        try context.save()

        return KairosImportResult(
            yearsAdded: yearsAdded, pulsesAdded: pulsesAdded,
            reviewsAdded: reviewsAdded, exportedAt: backup.exportedAt
        )
    }
}
