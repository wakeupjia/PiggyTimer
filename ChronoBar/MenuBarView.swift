import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var timerManager: TimerManager
    @ObservedObject var dataManager = DataManager.shared

    var body: some View {
        let today = formatTotal(dataManager.todayTotal)
        let allTime = formatTotal(dataManager.allTimeTotal)

        Text("Today: \(today)")
            .fontWeight(.bold)

        Text("All-time: \(allTime)")
            .foregroundColor(.secondary)

        Divider()

        Button(timerManager.isActive ? "Stop Timer" : "Start Timer") {
            timerManager.toggle()
        }

        Divider()

        Button("Open History (JSON)") {
            dataManager.openHistoryFile()
        }

        Button("Refresh Data") {
            dataManager.load()
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }

    private func formatTotal(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        if h > 0 {
            return "\(h)h \(m)m"
        } else {
            return "\(m)m"
        }
    }
}
