import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    let timerManager = TimerManager()
    let dataManager = DataManager.shared
    var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

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

    private func updateButton() {
        let todayTotal = dataManager.todayTotal
        let displayTime: TimeInterval
        statusItem.button?.image = nil
        if timerManager.isActive {
            displayTime = todayTotal + timerManager.currentSessionElapsed
            statusItem.button?.title = "🐱 \(formatTime(displayTime))"
        } else {
            displayTime = todayTotal
            statusItem.button?.title = "🐷 \(formatTime(displayTime))"
        }
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        dataManager.load()

        let allTimeStr = formatTime(dataManager.allTimeTotal)
        menu.addItem(NSMenuItem(title: "All-time: \(allTimeStr)", action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        let toggleTitle = timerManager.isActive ? "Stop Timer" : "Start Timer"
        menu.addItem(NSMenuItem(title: toggleTitle, action: #selector(toggleTimer), keyEquivalent: "s"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Open History (JSON)", action: #selector(openHistory), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Refresh Data", action: #selector(refreshData), keyEquivalent: "r"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit ChronoBar", action: #selector(quit), keyEquivalent: "q"))
    }

    // MARK: - Actions

    @objc private func toggleTimer() {
        timerManager.toggle()
    }

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
}
