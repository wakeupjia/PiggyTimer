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
        // Monospaced digits + zero-padded HH:MM keep the title width constant.
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        updateButton()

        timerManager.$isActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        timerManager.$currentSessionElapsed
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        dataManager.$currentTheme
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        // Stop and save the running session before switching themes.
        dataManager.willSwitchTheme = { [weak self] in
            self?.timerManager.stopIfActive()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }

    @objc private func handleSleep() {
        timerManager.stopIfActive()
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

        let allTimeStr = formatHM(dataManager.allTimeTotal)
        menu.addItem(NSMenuItem(title: "\(dataManager.currentTheme) — All-time: \(allTimeStr)", action: nil, keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        let openItem = NSMenuItem(title: "Open UI", action: #selector(openUI), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let themeMenu = NSMenu()
        for theme in dataManager.themes {
            let item = NSMenuItem(title: theme, action: #selector(switchTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme
            item.state = (theme == dataManager.currentTheme) ? .on : .off
            themeMenu.addItem(item)
        }
        let switchItem = NSMenuItem(title: "Switch Theme", action: nil, keyEquivalent: "")
        switchItem.submenu = themeMenu
        menu.addItem(switchItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit ChronoBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

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
            statusItem.button?.title = "🐷 \(formatTime(displayTime))"
        }
    }

    // MARK: - Actions

    @objc private func openUI() {
        StatsWindowController.shared.show()
    }

    @objc private func switchTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? String else { return }
        dataManager.switchTheme(to: theme)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        return String(format: "%02d:%02d", h, m)
    }

    private func formatHM(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        return "\(h)h \(m)m"
    }
}
