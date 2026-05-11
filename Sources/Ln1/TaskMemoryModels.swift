import Foundation

struct TaskMemoryEvent: Codable {
    let id: String
    let timestamp: String
    let taskID: String
    let kind: String
    let status: String?
    let title: String?
    let summary: String?
    let summaryLength: Int?
    let summaryDigest: String?
    let sensitivity: String
    let relatedAuditID: String?
}

struct TaskMemoryResult: Codable {
    let path: String
    let taskID: String
    let status: String?
    let title: String?
    let startedAt: String?
    let updatedAt: String?
    let eventCount: Int
    let limit: Int
    let events: [TaskMemoryEvent]
}
