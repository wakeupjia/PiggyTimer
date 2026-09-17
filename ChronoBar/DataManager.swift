import Foundation
import AppKit

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var records: [StudyRecord] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ChronoBar", isDirectory: true)
        return dir.appendingPathComponent("history.json")
    }()

    private init() {
        load()
    }

    func load() {
        let fm = FileManager.default
        let dir = fileURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        guard fm.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            records = try JSONDecoder.decoder.decode([StudyRecord].self, from: data)
        } catch {
            let alert = NSAlert()
            alert.messageText = "ChronoBar: Failed to parse history.json"
            alert.informativeText = error.localizedDescription + "\n\nPlease fix the file and click Refresh Data."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            records = []
        }
    }

    func save(_ record: StudyRecord) {
        records.append(record)
        persist()
    }

    func delete(_ record: StudyRecord) {
        records.removeAll { $0.id == record.id }
        persist()
    }

    func persist() {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        do {
            let data = try JSONEncoder.encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            let alert = NSAlert()
            alert.messageText = "ChronoBar: Failed to save history.json"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func openHistoryFile() {
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try? "[]".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        NSWorkspace.shared.open(fileURL)
    }

    var todayTotal: TimeInterval {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return records
            .filter { cal.isDate($0.start, inSameDayAs: today) }
            .reduce(0) { $0 + $1.duration }
    }

    var allTimeTotal: TimeInterval {
        records.reduce(0) { $0 + $1.duration }
    }

    var todayRecords: [StudyRecord] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return records
            .filter { cal.isDate($0.start, inSameDayAs: today) }
            .sorted { $0.start < $1.start }
    }

    /// Daily totals for the past `days` days (including today), oldest first.
    /// Days without records are included with 0.
    func dailyTotals(days: Int) -> [(date: Date, seconds: TimeInterval)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let startDay = cal.date(byAdding: .day, value: -(days - 1), to: today) else { return [] }

        var totals: [Date: TimeInterval] = [:]
        for record in records {
            let day = cal.startOfDay(for: record.start)
            guard day >= startDay else { continue }
            totals[day, default: 0] += record.duration
        }

        var result: [(date: Date, seconds: TimeInterval)] = []
        for offset in 0..<days {
            if let day = cal.date(byAdding: .day, value: offset, to: startDay) {
                result.append((date: day, seconds: totals[day] ?? 0))
            }
        }
        return result
    }
}

extension JSONDecoder {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

extension JSONEncoder {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}
