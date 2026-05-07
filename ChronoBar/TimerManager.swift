import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var isActive = false
    @Published var elapsedTimeString = "00:00:00"

    private var startTime: Date?
    private var timer: Timer?

    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }

    private func start() {
        isActive = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        tick()
    }

    private func stop() {
        timer?.invalidate()
        timer = nil

        if let start = startTime {
            let end = Date()
            let duration = end.timeIntervalSince(start)
            let record = StudyRecord(
                id: UUID(),
                start: start,
                end: end,
                duration: duration
            )
            DataManager.shared.save(record)
        }

        isActive = false
        startTime = nil
        elapsedTimeString = "00:00:00"
    }

    private func tick() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        elapsedTimeString = formatDuration(elapsed)
    }

    func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) % 3600 / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
