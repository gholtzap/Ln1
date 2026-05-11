import Foundation

struct ObservationAction: Codable {
    let name: String
    let command: String
    let risk: String
    let mutates: Bool
    let reason: String
}

struct ObservationSnapshot: Codable {
    let generatedAt: String
    let platform: String
    let accessibility: TrustRecord
    let activeApp: AppSummary?
    let appLimit: Int
    let appCount: Int
    let appsTruncated: Bool
    let apps: [AppSummary]
    let desktop: DesktopWindowsState
    let blockers: [String]
    let suggestedActions: [ObservationAction]
}

struct DoctorCheck: Codable {
    let name: String
    let status: String
    let required: Bool
    let message: String
    let remediation: String?
}

struct DoctorReport: Codable {
    let generatedAt: String
    let platform: String
    let status: String
    let ready: Bool
    let checks: [DoctorCheck]
}

struct WorkflowPreflight: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let risk: String
    let mutates: Bool
    let canProceed: Bool
    let prerequisites: [DoctorCheck]
    let blockers: [String]
    let nextCommand: String?
    let nextArguments: [String]?
    let message: String
}

struct WorkflowCommand: Codable {
    let display: String
    let argv: [String]
    let risk: String
    let mutates: Bool
    let requiresReason: Bool
}

struct WorkflowNextPlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let ready: Bool
    let risk: String
    let mutates: Bool
    let blockers: [String]
    let command: WorkflowCommand?
    let preflight: WorkflowPreflight
    let message: String
}

enum JSONValue: Encodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(any value: Any) throws {
        switch value {
        case let string as String:
            self = .string(string)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else {
                self = .number(number.doubleValue)
            }
        case let dictionary as [String: Any]:
            self = .object(try dictionary.mapValues(JSONValue.init(any:)))
        case let array as [Any]:
            self = .array(try array.map(JSONValue.init(any:)))
        case _ as NSNull:
            self = .null
        default:
            throw CommandError(description: "unsupported JSON value in workflow execution output")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

struct WorkflowExecutionResult: Encodable {
    let argv: [String]
    let exitCode: Int32
    let timeoutMilliseconds: Int
    let timedOut: Bool
    let maxOutputBytes: Int
    let stdout: String
    let stdoutBytes: Int
    let stdoutTruncated: Bool
    let stderr: String
    let stderrBytes: Int
    let stderrTruncated: Bool
    let outputJSON: JSONValue?
}

struct WorkflowRunPlan: Encodable {
    let transcriptID: String
    let transcriptPath: String
    let generatedAt: String
    let platform: String
    let operation: String
    let mode: String
    let dryRun: Bool
    let ready: Bool
    let wouldExecute: Bool
    let executed: Bool
    let risk: String
    let mutates: Bool
    let blockers: [String]
    let command: WorkflowCommand?
    let execution: WorkflowExecutionResult?
    let preflight: WorkflowPreflight
    let message: String
}

struct WorkflowLogEntries: Encodable {
    let path: String
    let operation: String?
    let limit: Int
    let count: Int
    let entries: [JSONValue]
}

struct WorkflowResumePlan: Encodable {
    let path: String
    let operation: String?
    let status: String
    let transcriptID: String?
    let latestOperation: String?
    let blockers: [String]
    let nextCommand: String?
    let nextArguments: [String]?
    let latest: JSONValue?
    let message: String
}
