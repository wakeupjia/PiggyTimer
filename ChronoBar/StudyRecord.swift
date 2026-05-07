import Foundation

struct StudyRecord: Codable, Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let duration: TimeInterval
}
