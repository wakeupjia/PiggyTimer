import SwiftUI
import Charts
import AppKit

// MARK: - Stats Window

struct StatsView: View {
    @ObservedObject var dataManager = DataManager.shared

    private var monthData: [(date: Date, seconds: TimeInterval)] {
        dataManager.dailyTotals(days: 30)
    }

    private var monthTotal: TimeInterval {
        monthData.reduce(0) { $0 + $1.seconds }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Past 30 Days")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(formatDuration(monthTotal))
                        .font(.title)
                        .bold()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("All-time Total")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(formatDuration(dataManager.allTimeTotal))
                        .font(.title)
                        .bold()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Picker(selection: themeBinding, label: EmptyView()) {
                        ForEach(dataManager.themes, id: \.self) { theme in
                            Text(theme).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .fixedSize()

                    Button("Create a new theme") {
                        promptCreateTheme()
                    }
                    .font(.caption)
                }
            }

            // Chart
            Text("Daily Study Time (Past 30 Days)")
                .font(.headline)

            Chart(monthData, id: \.date) { item in
                AreaMark(
                    x: .value("Date", item.date),
                    y: .value("Hours", item.seconds / 3600)
                )
                .foregroundStyle(.blue.opacity(0.15))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Hours", item.seconds / 3600)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Date", item.date),
                    y: .value("Hours", item.seconds / 3600)
                )
                .foregroundStyle(.blue)
                .symbolSize(20)
            }
            .chartYAxisLabel("Hours")
            .frame(height: 180)

            Divider()

            // Today's sessions
            Text("Today's Sessions")
                .font(.headline)

            if dataManager.todayRecords.isEmpty {
                Text("No sessions recorded today.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(dataManager.todayRecords) { record in
                        HStack {
                            Text("\(formatClock(record.start)) – \(formatClock(record.end))")
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(formatDuration(record.duration))
                                .foregroundColor(.secondary)
                            Button(role: .destructive) {
                                dataManager.delete(record)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(20)
        .frame(minWidth: 480, minHeight: 540)
    }

    private var themeBinding: Binding<String> {
        Binding(
            get: { dataManager.currentTheme },
            set: { dataManager.switchTheme(to: $0) }
        )
    }

    private func promptCreateTheme() {
        let alert = NSAlert()
        alert.messageText = "Create a new theme"
        alert.informativeText = "Study time will be tracked separately under the new theme."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.placeholderString = "Theme name"
        alert.accessoryView = field
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        if let error = dataManager.createTheme(named: field.stringValue) {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Could not create theme"
            errorAlert.informativeText = error
            errorAlert.alertStyle = .warning
            errorAlert.addButton(withTitle: "OK")
            errorAlert.runModal()
        }
    }

    private func formatClock(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: - Window Controller

class StatsWindowController {
    static let shared = StatsWindowController()

    private var window: NSWindow?

    func show() {
        DataManager.shared.load()

        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 580),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ChronoBar Stats"
        window.contentView = NSHostingView(rootView: StatsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
