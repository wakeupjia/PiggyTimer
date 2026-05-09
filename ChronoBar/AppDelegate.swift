import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let timerManager = TimerManager()
    let dataManager = DataManager.shared
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusBarClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        updateButton()

        timerManager.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        timerManager.$currentSessionElapsed
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)
    }

    @objc private func statusBarClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            timerManager.toggle()
        }
    }

    private func showContextMenu() {
        dataManager.load()
        let menu = NSMenu()

        let allTimeStr = formatTime(dataManager.allTimeTotal)
        menu.addItem(NSMenuItem(title: "All-time: \(allTimeStr)", action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Open History (JSON)", action: #selector(openHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Refresh Data", action: #selector(refreshData), keyEquivalent: "r"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit ChronoBar", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func updateButton() {
        let todayTotal = dataManager.todayTotal
        let displayTime: TimeInterval
        statusItem.button?.image = nil
        if timerManager.isActive {
            displayTime = todayTotal + timerManager.currentSessionElapsed
            statusItem.button?.title = "🐱 \(formatTime(displayTime))"
        } else {
            displayTime = todayTotal
            statusItem.button?.title = "🐷 \(formatTimeShort(displayTime))"
        }
    }

    // MARK: - Actions

    @objc private func openHistory() {
        dataManager.openHistoryFile()
    }

    @objc private func refreshData() {
        dataManager.load()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        let s = Int(seconds) % 60
        return "\(h)h \(m)m \(s)s"
    }

    private func formatTimeShort(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        return "\(h)h \(m)m"
    }
}
