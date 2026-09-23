import Foundation
import AppKit

struct ThemeState: Codable {
    var themes: [String]
    var current: String
}

class DataManager: ObservableObject {
    static let shared = DataManager()

    @Published var records: [StudyRecord] = []
    @Published var themes: [String] = []
    @Published var currentTheme: String = "AI"

    /// Called before switching/creating a theme so a running timer can be stopped and saved first.
    var willSwitchTheme: (() -> Void)?

    private let baseDir: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ChronoBar", isDirectory: true)
    }()

    private var themesURL: URL {
        baseDir.appendingPathComponent("themes.json")
    }

    private var fileURL: URL {
        baseDir.appendingPathComponent("history-\(currentTheme).json")
    }

    private init() {
        loadThemes()
        load()
    }

    // MARK: - Themes

    private func loadThemes() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDir.path) {
            try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
        }

        if let data = try? Data(contentsOf: themesURL),
           let state = try? JSONDecoder.decoder.decode(ThemeState.self, from: data),
           !state.themes.isEmpty {
            themes = state.themes
            currentTheme = state.themes.contains(state.current) ? state.current : state.themes[0]
            return
        }

        // First launch after themes were introduced:
        // migrate legacy history.json to the "AI" theme.
        let legacyURL = baseDir.appendingPathComponent("history.json")
        let aiURL = baseDir.appendingPathComponent("history-AI.json")
        if fm.fileExists(atPath: legacyURL.path), !fm.fileExists(atPath: aiURL.path) {
            try? fm.moveItem(at: legacyURL, to: aiURL)
        }

        themes = ["AI", "paper1"]
        currentTheme = "AI"
        persistThemes()
    }

    private func persistThemes() {
        let state = ThemeState(themes: themes, current: currentTheme)
        if let data = try? JSONEncoder.encoder.encode(state) {
            try? data.write(to: themesURL, options: .atomic)
        }
    }

    func switchTheme(to theme: String) {
        guard themes.contains(theme), theme != currentTheme else { return }
        willSwitchTheme?()
        currentTheme = theme
        persistThemes()
        load()
    }

    /// Creates a new theme and switches to it. Returns an error message on failure, nil on success.
    @discardableResult
    func createTheme(named rawName: String) -> String? {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            return "Theme name cannot be empty."
        }
        if name.contains("/") || name.contains(":") || name.contains("\\") {
            return "Theme name cannot contain / : or \\."
        }
        if themes.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            return "Theme \"\(name)\" already exists."
        }
        willSwitchTheme?()
        themes.append(name)
        currentTheme = name
        persistThemes()
        load()
        return nil
    }

    // MARK: - Records

    func load() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: baseDir.path) {
            try? fm.createDirectory(at: baseDir, withIntermediateDirectories: true)
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
            alert.messageText = "ChronoBar: Failed to parse \(fileURL.lastPathComponent)"
            alert.informativeText = error.localizedDescription + "\n\nPlease fix the file and reopen the menu."
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
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        do {
            let data = try JSONEncoder.encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            let alert = NSAlert()
            alert.messageText = "ChronoBar: Failed to save \(fileURL.lastPathComponent)"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func openHistoryFile() {
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
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
