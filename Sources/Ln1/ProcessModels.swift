import Foundation

struct ProcessRecord: Codable {
    let pid: Int32
    let name: String?
    let executablePath: String?
    let bundleIdentifier: String?
    let appName: String?
    let activeApp: Bool
    let currentProcess: Bool
}

struct ProcessListState: Codable {
    let generatedAt: String
    let platform: String
    let limit: Int
    let count: Int
    let truncated: Bool
    let processes: [ProcessRecord]
}

struct ProcessInspectState: Codable {
    let generatedAt: String
    let platform: String
    let found: Bool
    let process: ProcessRecord?
    let message: String
}

struct ProcessWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let pid: Int32
    let expectedExists: Bool
    let current: ProcessRecord?
    let matched: Bool
}

struct ProcessWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: ProcessWaitVerification
    let message: String
}
