import AppKit
import ApplicationServices
import CryptoKit
import Foundation

struct CommandError: Error, CustomStringConvertible {
    let description: String
}

struct Rect: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct AppRecord: Codable {
    let name: String?
    let bundleIdentifier: String?
    let pid: Int32
}

struct ElementNode: Codable {
    let id: String
    let stableIdentity: StableIdentity
    let role: String?
    let subrole: String?
    let title: String?
    let value: String?
    let help: String?
    let enabled: Bool?
    let frame: Rect?
    let actions: [String]
    let children: [ElementNode]
}

struct ComputerState: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let windows: [ElementNode]
}

struct AppState: Codable {
    let app: AppRecord
    let windows: [ElementNode]
}

struct AllComputerState: Codable {
    let generatedAt: String
    let platform: String
    let apps: [AppState]
}

struct AppSummary: Codable {
    let name: String?
    let bundleIdentifier: String?
    let pid: Int32
    let active: Bool
}

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

private struct WorkflowOutputSnapshot {
    let data: Data
    let totalBytes: Int
    let truncated: Bool
}

private final class WorkflowOutputCapture: @unchecked Sendable {
    private let lock = NSLock()
    private let maxOutputBytes: Int
    private var data = Data()
    private var totalBytes = 0
    private var truncated = false

    init(maxOutputBytes: Int) {
        self.maxOutputBytes = maxOutputBytes
    }

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else {
            return
        }

        lock.lock()
        defer { lock.unlock() }

        totalBytes += chunk.count
        let remainingBytes = maxOutputBytes - data.count
        if remainingBytes <= 0 {
            truncated = true
            return
        }
        if chunk.count <= remainingBytes {
            data.append(chunk)
        } else {
            data.append(chunk.prefix(remainingBytes))
            truncated = true
        }
    }

    func snapshot() -> WorkflowOutputSnapshot {
        lock.lock()
        defer { lock.unlock() }

        return WorkflowOutputSnapshot(
            data: data,
            totalBytes: totalBytes,
            truncated: truncated
        )
    }
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

struct DesktopWindowRecord: Codable {
    let id: String
    let stableIdentity: StableIdentity
    let windowNumber: UInt32
    let ownerName: String?
    let ownerBundleIdentifier: String?
    let ownerPID: Int32
    let active: Bool
    let title: String?
    let layer: Int
    let bounds: Rect?
    let onscreen: Bool?
    let alpha: Double?
    let memoryUsageBytes: Int?
    let sharingState: Int?
}

struct StableIdentity: Codable {
    let id: String
    let kind: String
    let confidence: String
    let label: String
    let components: [String: String]
    let reasons: [String]
}

struct DesktopWindowsState: Codable {
    let generatedAt: String
    let platform: String
    let available: Bool
    let message: String
    let activePID: Int32?
    let includeDesktop: Bool
    let includeAllLayers: Bool
    let limit: Int
    let count: Int
    let truncated: Bool
    let windows: [DesktopWindowRecord]
}

struct TrustRecord: Codable {
    let trusted: Bool
    let message: String
}

struct PolicyActionRecord: Codable {
    let name: String
    let domain: String
    let risk: String
    let mutates: Bool
}

struct PolicySnapshot: Codable {
    let generatedAt: String
    let platform: String
    let defaultAllowedRisk: String
    let riskLevels: [String]
    let actions: [PolicyActionRecord]
}

struct ActionResult: Codable {
    let ok: Bool
    let pid: Int32
    let element: String
    let stableIdentity: StableIdentity?
    let action: String
    let identityVerification: IdentityVerification?
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct AuditElementSummary: Codable {
    let stableIdentity: StableIdentity?
    let role: String?
    let subrole: String?
    let title: String?
    let help: String?
    let enabled: Bool?
    let actions: [String]
}

struct AuditOutcome: Codable {
    let ok: Bool
    let code: String
    let message: String
}

struct IdentityVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let expectedID: String?
    let actualID: String
    let minimumConfidence: String?
    let actualConfidence: String
    let identityMatched: Bool?
    let confidenceAccepted: Bool?
}

struct AuditPolicyDecision: Codable {
    let allowedRisk: String
    let actionRisk: String
    let allowed: Bool
    let message: String
}

struct FileAuditTarget: Codable {
    let path: String
    let id: String?
    let kind: String?
    let sizeBytes: Int?
    let exists: Bool?
}

struct FileOperationVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
}

struct ClipboardAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct ClipboardState: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let changeCount: Int
    let types: [String]
    let hasString: Bool
    let stringLength: Int?
    let stringDigest: String?
    let actions: [ClipboardAction]
}

struct ClipboardTextResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let changeCount: Int
    let hasString: Bool
    let text: String?
    let stringLength: Int?
    let stringDigest: String?
    let truncated: Bool
    let maxCharacters: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct ClipboardWriteResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let previous: ClipboardAuditSummary
    let current: ClipboardAuditSummary
    let writtenLength: Int
    let writtenDigest: String
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct BrowserTab: Codable {
    let id: String
    let type: String
    let title: String?
    let url: String?
    let description: String?
    let webSocketDebuggerURL: String?
    let devtoolsFrontendURL: String?
    let faviconURL: String?
    let attached: Bool?
    let actions: [BrowserAction]
}

struct BrowserTabsState: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let includeNonPageTargets: Bool
    let count: Int
    let tabs: [BrowserTab]
}

struct BrowserTabState: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
}

struct BrowserAuditSummary: Codable {
    let id: String
    let type: String
    let title: String?
    let url: String?
    let textLength: Int?
    let textDigest: String?
    let domNodeCount: Int?
    let domDigest: String?
    var formSelector: String? = nil
    var formTextLength: Int? = nil
    var formTextDigest: String? = nil
    var navigationURL: String? = nil
    var currentURL: String? = nil
    var urlMatched: Bool? = nil
}

struct BrowserTextResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let text: String
    let textLength: Int
    let textDigest: String
    let truncated: Bool
    let maxCharacters: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserDOMElement: Codable {
    let id: String
    let parentID: String?
    let depth: Int
    let tagName: String
    let role: String?
    let text: String?
    let textLength: Int
    let attributes: [String: String]
    let inputType: String?
    let checked: Bool?
    let disabled: Bool?
    let hasValue: Bool?
    let valueLength: Int?
}

struct BrowserDOMSnapshotPayload: Codable {
    let url: String?
    let title: String?
    let elements: [BrowserDOMElement]
    let elementCount: Int
    let truncated: Bool
}

struct BrowserDOMResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let url: String?
    let title: String?
    let elements: [BrowserDOMElement]
    let elementCount: Int
    let truncated: Bool
    let maxElements: Int
    let maxTextCharacters: Int
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserFormFillPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let valueLength: Int?
    let matched: Bool
}

struct BrowserFormFillResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let textLength: Int
    let textDigest: String
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetInputType: String?
    let targetDisabled: Bool?
    let targetReadOnly: Bool?
    let resultingValueLength: Int?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserNavigationVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let requestedURL: String
    let expectedURL: String
    let currentURL: String?
    let match: String
    let matched: Bool
}

struct BrowserNavigationResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let requestedURL: String
    let expectedURL: String
    let match: String
    let verification: BrowserNavigationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct ClipboardAuditSummary: Codable {
    let pasteboard: String
    let changeCount: Int
    let types: [String]
    let hasString: Bool
    let stringLength: Int?
    let stringDigest: String?
}

struct FilePreflightCheck: Codable {
    let name: String
    let ok: Bool
    let code: String
    let message: String
}

struct FileOperationPreflight: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let source: FileAuditTarget?
    let destination: FileAuditTarget?
    let rollbackOfAuditID: String?
    let checks: [FilePreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct ActionAuditRecord: Codable {
    let id: String
    let timestamp: String
    let command: String
    let risk: String
    let reason: String?
    let app: AppRecord?
    let elementID: String?
    let element: AuditElementSummary?
    let action: String?
    var policy: AuditPolicyDecision? = nil
    var fileSource: FileAuditTarget? = nil
    var fileDestination: FileAuditTarget? = nil
    var verification: FileOperationVerification? = nil
    var identityVerification: IdentityVerification? = nil
    var clipboard: ClipboardAuditSummary? = nil
    var clipboardBefore: ClipboardAuditSummary? = nil
    var clipboardAfter: ClipboardAuditSummary? = nil
    var browserTab: BrowserAuditSummary? = nil
    let outcome: AuditOutcome
}

struct AuditEntries: Codable {
    let path: String
    let command: String?
    let code: String?
    let limit: Int
    let entries: [ActionAuditRecord]
}

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

struct FileAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct FileRecord: Codable {
    let id: String
    let path: String
    let name: String
    let kind: String
    let sizeBytes: Int?
    let createdAt: String?
    let modifiedAt: String?
    let hidden: Bool
    let readable: Bool
    let writable: Bool
    let actions: [FileAction]
}

struct FilesystemState: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let entries: [FileRecord]
    let maxDepth: Int
    let limit: Int
    let truncated: Bool
}

struct FileLineMatch: Codable {
    let lineNumber: Int
    let text: String
}

struct FileSearchMatch: Codable {
    let file: FileRecord
    let matchedName: Bool
    let contentMatches: [FileLineMatch]
}

struct FilesystemSearchResult: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let query: String
    let caseSensitive: Bool
    let maxDepth: Int
    let limit: Int
    let includeHidden: Bool
    let maxFileBytes: Int
    let maxSnippetCharacters: Int
    let maxMatchesPerFile: Int
    let matches: [FileSearchMatch]
    let scannedFiles: Int
    let skippedUnreadable: Int
    let skippedBinary: Int
    let skippedTooLarge: Int
    let truncated: Bool
}

struct FilesystemWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let path: String
    let expectedExists: Bool
    let matched: Bool
    let elapsedMilliseconds: Int
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let file: FileRecord?
    let message: String
}

struct FileWatchEvent: Codable {
    let id: String
    let type: String
    let path: String
    let previous: FileRecord?
    let current: FileRecord?
}

struct FilesystemWatchResult: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let maxDepth: Int
    let limit: Int
    let includeHidden: Bool
    let matched: Bool
    let events: [FileWatchEvent]
    let eventCount: Int
    let beforeCount: Int
    let afterCount: Int
    let beforeTruncated: Bool
    let afterTruncated: Bool
    let elapsedMilliseconds: Int
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let message: String
}

struct FilesystemChecksumResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let algorithm: String
    let digest: String
    let maxFileBytes: Int
}

struct FilesystemCompareResult: Codable {
    let generatedAt: String
    let platform: String
    let left: FileRecord
    let right: FileRecord
    let algorithm: String
    let leftDigest: String
    let rightDigest: String
    let sameSize: Bool
    let sameDigest: Bool
    let matched: Bool
    let maxFileBytes: Int
}

struct FileOperationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let source: FileRecord
    let destination: FileRecord
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct DirectoryOperationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let directory: FileRecord
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileRollbackResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let rollbackOfAuditID: String
    let restoredSource: FileRecord
    let previousDestination: FileAuditTarget
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

private struct DevToolsTarget: Decodable {
    let id: String
    let type: String?
    let title: String?
    let url: String?
    let description: String?
    let webSocketDebuggerUrl: String?
    let devtoolsFrontendUrl: String?
    let faviconUrl: String?
    let attached: Bool?
}

private struct CDPEvaluateResponse: Decodable {
    let id: Int?
    let result: CDPEvaluateResult?
    let error: CDPError?
}

private struct CDPCommandResponse: Decodable {
    let id: Int?
    let error: CDPError?
}

private struct CDPEvaluateResult: Decodable {
    let result: CDPRemoteObject
}

private struct CDPRemoteObject: Decodable {
    let type: String?
    let value: String?
    let description: String?
}

private struct CDPError: Decodable {
    let code: Int
    let message: String
}

private final class CDPResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<CDPEvaluateResponse, Error>?

    func set(_ newValue: Result<CDPEvaluateResponse, Error>) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Result<CDPEvaluateResponse, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class CDPCommandResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<CDPCommandResponse, Error>?

    func set(_ newValue: Result<CDPCommandResponse, Error>) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Result<CDPCommandResponse, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

private final class DataResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Result<Data, Error>?

    func set(_ newValue: Result<Data, Error>) {
        lock.lock()
        value = newValue
        lock.unlock()
    }

    func get() -> Result<Data, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

let args = Array(CommandLine.arguments.dropFirst())

do {
    let cli = ZeroThreeCLI(arguments: args)
    try cli.run()
} catch let error as CommandError {
    fputs("03: \(error.description)\n", stderr)
    exit(1)
} catch {
    fputs("03: \(error)\n", stderr)
    exit(1)
}

final class ZeroThreeCLI {
    private let arguments: [String]
    private let encoder: JSONEncoder

    init(arguments: [String]) {
        self.arguments = arguments
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func run() throws {
        guard let command = arguments.first else {
            printHelp()
            return
        }

        switch command {
        case "trust":
            try trust()
        case "doctor":
            try doctor()
        case "policy":
            try policy()
        case "observe":
            try observe()
        case "workflow":
            try workflow()
        case "apps":
            try apps()
        case "desktop":
            try desktop()
        case "state":
            try state()
        case "perform":
            try perform()
        case "audit":
            try audit()
        case "task":
            try task()
        case "files":
            try files()
        case "clipboard":
            try clipboard()
        case "browser":
            try browser()
        case "schema":
            schema()
        case "help", "--help", "-h":
            printHelp()
        default:
            throw CommandError(description: "unknown command '\(command)'")
        }
    }

    private func desktop() throws {
        let mode = arguments.dropFirst().first ?? "windows"

        switch mode {
        case "windows":
            try writeJSON(desktopWindows())
        default:
            throw CommandError(description: "unknown desktop mode '\(mode)'")
        }
    }

    private func trust() throws {
        let prompt = option("--prompt").map(parseBool) ?? true
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        try writeJSON(TrustRecord(
            trusted: trusted,
            message: trusted
                ? "Accessibility access is enabled."
                : "Grant Accessibility access to the terminal app running 03, then retry."
        ))
    }

    private func doctor() throws {
        let endpoint = try? browserEndpoint()
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 1_000)
        let checks = [
            doctorAccessibilityCheck(),
            doctorDesktopMetadataCheck(),
            doctorAuditLogCheck(),
            doctorClipboardCheck(),
            doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        ]
        let hasRequiredFailure = checks.contains { $0.required && $0.status == "fail" }
        let hasWarning = checks.contains { $0.status == "warn" || $0.status == "fail" }
        let status: String
        if hasRequiredFailure {
            status = "blocked"
        } else if hasWarning {
            status = "degraded"
        } else {
            status = "ready"
        }

        try writeJSON(DoctorReport(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            status: status,
            ready: status == "ready",
            checks: checks
        ))
    }

    private func doctorAccessibilityCheck() -> DoctorCheck {
        let trusted = AXIsProcessTrusted()
        return DoctorCheck(
            name: "accessibility",
            status: trusted ? "pass" : "fail",
            required: true,
            message: trusted
                ? "Accessibility permission is enabled."
                : "Accessibility permission is not enabled, so 03 state and 03 perform cannot inspect or operate app UI.",
            remediation: trusted ? nil : "Run `03 trust`, grant Accessibility access to the terminal app, then rerun `03 doctor`."
        )
    }

    private func doctorDesktopMetadataCheck() -> DoctorCheck {
        do {
            let desktop = try desktopWindows(limitOverride: 1)
            if !desktop.available {
                return DoctorCheck(
                    name: "desktop.windowMetadata",
                    status: "fail",
                    required: true,
                    message: desktop.message,
                    remediation: "Run `03 desktop windows --limit 5` from an interactive macOS user session."
                )
            }
            if desktop.windows.isEmpty {
                return DoctorCheck(
                    name: "desktop.windowMetadata",
                    status: "warn",
                    required: true,
                    message: "WindowServer metadata is available, but no visible windows matched the current filters.",
                    remediation: "Try `03 desktop windows --include-desktop --all-layers --limit 20`."
                )
            }
            return DoctorCheck(
                name: "desktop.windowMetadata",
                status: "pass",
                required: true,
                message: "WindowServer metadata is available.",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "desktop.windowMetadata",
                status: "fail",
                required: true,
                message: "Could not inspect desktop window metadata: \(error.localizedDescription)",
                remediation: "Run `03 desktop windows --limit 5` to inspect the desktop adapter error."
            )
        }
    }

    private func doctorAuditLogCheck() -> DoctorCheck {
        do {
            let auditURL = try auditLogURL()
            let directory = auditURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let probeURL = directory.appendingPathComponent(".03-doctor-\(UUID().uuidString).tmp")
            try "doctor".write(to: probeURL, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: probeURL)
            return DoctorCheck(
                name: "auditLog.writeability",
                status: "pass",
                required: true,
                message: "Audit log directory is writable at \(directory.path).",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "auditLog.writeability",
                status: "fail",
                required: true,
                message: "Could not write an audit log probe: \(error.localizedDescription)",
                remediation: "Pass `--audit-log` with a writable path or fix permissions on the default Application Support directory."
            )
        }
    }

    private func doctorClipboardCheck() -> DoctorCheck {
        let pasteboard = targetPasteboard()
        let state = clipboardState(for: pasteboard)
        return DoctorCheck(
            name: "clipboard.metadata",
            status: "pass",
            required: true,
            message: "Clipboard metadata is readable from \(state.pasteboard).",
            remediation: nil
        )
    }

    private func doctorBrowserDevToolsCheck(endpoint: URL?, timeoutMilliseconds: Int) -> DoctorCheck {
        guard let endpoint else {
            return DoctorCheck(
                name: "browser.devTools",
                status: "warn",
                required: false,
                message: "Browser DevTools endpoint configuration is invalid.",
                remediation: "Use `03 doctor --endpoint http://127.0.0.1:9222` or pass a file path containing a DevTools /json/list fixture."
            )
        }

        do {
            let listURL = browserListURL(for: endpoint)
            let data = try readURLData(from: listURL, timeoutMilliseconds: timeoutMilliseconds)
            let targets = try JSONDecoder().decode([DevToolsTarget].self, from: data)
            let pageCount = targets.filter { ($0.type ?? "page") == "page" }.count
            return DoctorCheck(
                name: "browser.devTools",
                status: "pass",
                required: false,
                message: "Browser DevTools endpoint is reachable with \(pageCount) page target(s).",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "browser.devTools",
                status: "warn",
                required: false,
                message: "Browser DevTools endpoint is not reachable or did not return valid target JSON: \(error.localizedDescription)",
                remediation: "Start Chromium with `--remote-debugging-port=9222`, then rerun `03 doctor --endpoint http://127.0.0.1:9222`."
            )
        }
    }

    private func appSummaries(includeAll: Bool, activePid: pid_t?) -> [AppSummary] {
        var records = NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated && (includeAll || $0.activationPolicy == .regular) }
            .map {
                AppSummary(
                    name: $0.localizedName,
                    bundleIdentifier: $0.bundleIdentifier,
                    pid: $0.processIdentifier,
                    active: $0.processIdentifier == activePid
                )
            }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }

        if records.isEmpty {
            records = windowOwnerSummaries(activePid: activePid)
        }

        return records
    }

    private func policy() throws {
        try writeJSON(PolicySnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            defaultAllowedRisk: "low",
            riskLevels: ["low", "medium", "high", "unknown"],
            actions: knownPolicyActions()
        ))
    }

    private func observe() throws {
        let appLimit = max(0, option("--app-limit").flatMap(Int.init) ?? 20)
        let windowLimit = max(0, option("--window-limit").flatMap(Int.init) ?? 20)
        let includeAllApps = flag("--all")
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let allApps = appSummaries(includeAll: includeAllApps, activePid: activePid)
        let limitedApps = Array(allApps.prefix(appLimit))
        let trusted = AXIsProcessTrusted()
        let accessibility = TrustRecord(
            trusted: trusted,
            message: trusted
                ? "Accessibility access is enabled."
                : "Grant Accessibility access to the terminal app running 03 before using state or perform."
        )
        let desktop = try desktopWindows(limitOverride: windowLimit)
        let blockers = observationBlockers(accessibility: accessibility, desktop: desktop)

        try writeJSON(ObservationSnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            accessibility: accessibility,
            activeApp: allApps.first(where: \.active),
            appLimit: appLimit,
            appCount: limitedApps.count,
            appsTruncated: allApps.count > limitedApps.count,
            apps: limitedApps,
            desktop: desktop,
            blockers: blockers,
            suggestedActions: observationSuggestedActions(
                accessibilityTrusted: trusted,
                activePid: activePid,
                windowLimit: windowLimit
            )
        ))
    }

    private func workflow() throws {
        let mode = arguments.dropFirst().first ?? "preflight"
        switch mode {
        case "preflight":
            try workflowPreflight()
        case "next":
            try workflowNext()
        case "run":
            try workflowRun()
        case "log":
            try workflowLog()
        case "resume":
            try workflowResume()
        default:
            throw CommandError(description: "unknown workflow mode '\(mode)'")
        }
    }

    private func workflowPreflight() throws {
        let result = try workflowPreflightForOperation()
        try writeJSON(result)
    }

    private func workflowNext() throws {
        let preflight = try workflowPreflightForOperation()
        let command: WorkflowCommand?
        if preflight.canProceed, let argv = preflight.nextArguments {
            command = WorkflowCommand(
                display: workflowDisplayCommand(argv),
                argv: argv,
                risk: preflight.risk,
                mutates: preflight.mutates,
                requiresReason: preflight.mutates
            )
        } else {
            command = nil
        }

        try writeJSON(WorkflowNextPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: preflight.operation,
            ready: command != nil,
            risk: preflight.risk,
            mutates: preflight.mutates,
            blockers: preflight.blockers,
            command: command,
            preflight: preflight,
            message: command == nil
                ? "Workflow is blocked; run the remediation command from preflight before executing."
                : "Workflow is ready; execute the argv array directly or review the display command."
        ))
    }

    private func workflowRun() throws {
        let dryRun = option("--dry-run").map(parseBool) ?? true
        let timeoutMilliseconds = max(100, option("--run-timeout-ms").flatMap(Int.init) ?? 10_000)
        let maxOutputBytes = max(0, option("--max-output-bytes").flatMap(Int.init) ?? 1_048_576)
        let preflight = try workflowPreflightForOperation()
        let command: WorkflowCommand?
        if preflight.canProceed, let argv = preflight.nextArguments {
            command = WorkflowCommand(
                display: workflowDisplayCommand(argv),
                argv: argv,
                risk: preflight.risk,
                mutates: preflight.mutates,
                requiresReason: preflight.mutates
            )
        } else {
            command = nil
        }

        if !dryRun, command?.mutates == true {
            throw CommandError(description: "workflow run execution currently supports non-mutating commands only. Use `--dry-run true` to inspect mutating workflows.")
        }

        let execution: WorkflowExecutionResult?
        if !dryRun, let command {
            execution = try workflowExecute(
                command,
                timeoutMilliseconds: timeoutMilliseconds,
                maxOutputBytes: maxOutputBytes
            )
        } else {
            execution = nil
        }
        let executed = execution != nil
        let transcriptURL = try workflowLogURL()
        let generatedAt = ISO8601DateFormatter().string(from: Date())

        let plan = WorkflowRunPlan(
            transcriptID: UUID().uuidString,
            transcriptPath: transcriptURL.path,
            generatedAt: generatedAt,
            platform: "macOS",
            operation: preflight.operation,
            mode: dryRun ? "dry-run" : "execute",
            dryRun: dryRun,
            ready: command != nil,
            wouldExecute: command != nil,
            executed: executed,
            risk: preflight.risk,
            mutates: preflight.mutates,
            blockers: preflight.blockers,
            command: command,
            execution: execution,
            preflight: preflight,
            message: workflowRunMessage(command: command, dryRun: dryRun, executed: executed)
        )
        try appendWorkflowTranscript(plan, to: transcriptURL)
        try writeJSON(plan)
    }

    private func workflowLog() throws {
        try requirePolicyAllowed(action: "workflow.logRead")
        let workflowURL = try workflowLogURL()
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 20)
        let operation = option("--operation")
        let entries = try readWorkflowTranscriptEntries(
            from: workflowURL,
            limit: limit,
            operation: operation
        )
        try writeJSON(WorkflowLogEntries(
            path: workflowURL.path,
            operation: operation,
            limit: limit,
            count: entries.count,
            entries: entries
        ))
    }

    private func workflowResume() throws {
        try requirePolicyAllowed(action: "workflow.logRead")
        let workflowURL = try workflowLogURL()
        let operation = option("--operation")
        let latest = try readWorkflowTranscriptDictionaries(
            from: workflowURL,
            limit: 1,
            operation: operation
        ).last
        let plan = try workflowResumePlan(
            latest: latest,
            workflowURL: workflowURL,
            operation: operation
        )
        try writeJSON(plan)
    }

    private func workflowPreflightForOperation() throws -> WorkflowPreflight {
        let operation = try requiredOption("--operation")
        switch operation {
        case "inspect-active-app":
            return workflowPreflightInspectActiveApp()
        case "control-active-app":
            return workflowPreflightControlActiveApp()
        case "read-browser":
            return workflowPreflightReadBrowser()
        case "move-file":
            return try workflowPreflightMoveFile()
        case "wait-file":
            return workflowPreflightWaitFile()
        default:
            throw CommandError(description: "unsupported workflow operation '\(operation)'. Use inspect-active-app, control-active-app, read-browser, move-file, or wait-file.")
        }
    }

    private func workflowPreflightInspectActiveApp() -> WorkflowPreflight {
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let prerequisites = [
            doctorAccessibilityCheck(),
            doctorDesktopMetadataCheck()
        ]
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = ["03", "state"]
            if let activePid {
                arguments += ["--pid", String(activePid)]
            }
            arguments += ["--depth", "3", "--max-children", "80"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }
        let nextCommand = nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites)
        return workflowPreflightResult(
            operation: "inspect-active-app",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightControlActiveApp() -> WorkflowPreflight {
        let action = option("--action") ?? kAXPressAction as String
        let risk = riskLevel(for: action)
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        let element = option("--element")
        if element == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No target element was provided for control-active-app.",
                remediation: "Run `03 state\(activePid.map { " --pid \($0)" } ?? "") --depth 3 --max-children 80` and choose an element ID plus stableIdentity."
            ))
        }

        if option("--expect-identity") == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.expectedIdentity",
                status: "warn",
                required: false,
                message: "No expected stable identity was provided, so perform cannot guard against stale element paths.",
                remediation: "Pass `--expect-identity` from the element's stableIdentity.id and `--min-identity-confidence medium`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["03", "perform"]
            if let activePid {
                arguments += ["--pid", String(activePid)]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            arguments += ["--min-identity-confidence", option("--min-identity-confidence") ?? "medium"]
            arguments += ["--action", action, "--allow-risk", risk, "--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "control-active-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadBrowser() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 1_000)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        let prerequisites = [requiredBrowserCheck]
        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let id = option("--id") {
            var arguments = ["03", "browser", "dom"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--allow-risk", "medium",
                "--max-elements", "200",
                "--max-text-characters", "120",
                "--reason", "Inspect browser state"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if blockers.isEmpty {
            let arguments = ["03", "browser", "tabs", "--endpoint", endpoint?.absoluteString ?? "http://127.0.0.1:9222"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "read-browser",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightMoveFile() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let sourcePath = option("--path")
        let destinationPath = option("--to")
        if sourcePath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.sourcePath",
                status: "fail",
                required: true,
                message: "No source path was provided for move-file.",
                remediation: "Pass `--path SOURCE`."
            ))
        }
        if destinationPath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.destinationPath",
                status: "fail",
                required: true,
                message: "No destination path was provided for move-file.",
                remediation: "Pass `--to DESTINATION`."
            ))
        }

        if sourcePath != nil, destinationPath != nil {
            let preflight = try fileOperationPreflight(operation: "move")
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : "Resolve filesystem preflight check \(check.name) before moving."
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let sourcePath, let destinationPath {
            let arguments = [
                "03", "files", "move",
                "--path", sourcePath,
                "--to", destinationPath,
                "--allow-risk", "medium",
                "--reason", "Describe intent"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if sourcePath != nil, destinationPath != nil {
            let arguments = [
                "03", "files", "plan",
                "--operation", "move",
                "--path", sourcePath!,
                "--to", destinationPath!,
                "--allow-risk", "medium"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "move-file",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for wait-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            nextArguments = [
                "03", "files", "wait",
                "--path", path,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightResult(
        operation: String,
        risk: String,
        mutates: Bool,
        prerequisites: [DoctorCheck],
        blockers: [String],
        nextCommand: String?,
        nextArguments: [String]?
    ) -> WorkflowPreflight {
        WorkflowPreflight(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            risk: risk,
            mutates: mutates,
            canProceed: blockers.isEmpty,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments,
            message: blockers.isEmpty
                ? "\(operation) can proceed with the suggested command."
                : "\(operation) is blocked; resolve required prerequisites first."
        )
    }

    private func workflowBlockers(from prerequisites: [DoctorCheck]) -> [String] {
        prerequisites
            .filter { $0.required && $0.status != "pass" }
            .map(\.name)
    }

    private func workflowRemediationCommand(for prerequisites: [DoctorCheck]) -> String? {
        prerequisites.first { $0.required && $0.status != "pass" }?.remediation
    }

    private func workflowResumePlan(
        latest: [String: Any]?,
        workflowURL: URL,
        operation: String?
    ) throws -> WorkflowResumePlan {
        guard let latest else {
            let nextArguments = ["03", "observe", "--app-limit", "20", "--window-limit", "20"]
            return WorkflowResumePlan(
                path: workflowURL.path,
                operation: operation,
                status: "empty",
                transcriptID: nil,
                latestOperation: nil,
                blockers: [],
                nextCommand: workflowDisplayCommand(nextArguments),
                nextArguments: nextArguments,
                latest: nil,
                message: "No workflow transcript entries matched; start with a fresh observation."
            )
        }

        let transcriptID = latest["transcriptID"] as? String
        let latestOperation = latest["operation"] as? String
        let blockers = latest["blockers"] as? [String] ?? []
        let preflight = latest["preflight"] as? [String: Any]
        let command = latest["command"] as? [String: Any]
        let execution = latest["execution"] as? [String: Any]
        let executed = latest["executed"] as? Bool ?? false
        let wouldExecute = latest["wouldExecute"] as? Bool ?? false
        let timedOut = execution?["timedOut"] as? Bool ?? false
        let exitCode = execution?["exitCode"] as? Int

        let status: String
        let nextCommand: String?
        let nextArguments: [String]?
        let message: String

        if !blockers.isEmpty {
            status = "blocked"
            nextCommand = preflight?["nextCommand"] as? String
            nextArguments = preflight?["nextArguments"] as? [String]
            message = "Latest workflow is blocked; resolve prerequisites before rerunning."
        } else if timedOut {
            status = "timed_out"
            nextArguments = workflowDryRunArguments(for: latestOperation)
            nextCommand = nextArguments.map(workflowDisplayCommand)
            message = "Latest workflow timed out; inspect the dry-run plan or rerun with a larger --run-timeout-ms."
        } else if executed, exitCode == 0 {
            status = "completed"
            if let recommendation = workflowCompletedRecommendation(
                for: latest,
                workflowURL: workflowURL
            ) {
                nextArguments = recommendation.arguments
                nextCommand = workflowDisplayCommand(recommendation.arguments)
                message = recommendation.message
            } else {
                nextArguments = [
                    "03", "workflow", "log",
                    "--workflow-log", workflowURL.path,
                    "--allow-risk", "medium",
                    "--limit", "5"
                ]
                nextCommand = workflowDisplayCommand(nextArguments!)
                message = "Latest workflow completed; inspect recent transcript context before choosing the next operation."
            }
        } else if executed {
            status = "failed"
            nextArguments = workflowDryRunArguments(for: latestOperation)
            nextCommand = nextArguments.map(workflowDisplayCommand)
            message = "Latest workflow executed but returned a nonzero exit code; inspect the dry-run plan before retrying."
        } else if wouldExecute {
            status = "ready"
            nextCommand = command?["display"] as? String
            nextArguments = command?["argv"] as? [String]
            message = "Latest workflow was ready but not executed; review or execute the suggested command."
        } else {
            status = "not_ready"
            nextCommand = preflight?["nextCommand"] as? String
            nextArguments = preflight?["nextArguments"] as? [String]
            message = "Latest workflow was not ready; inspect blockers and preflight output."
        }

        return WorkflowResumePlan(
            path: workflowURL.path,
            operation: operation,
            status: status,
            transcriptID: transcriptID,
            latestOperation: latestOperation,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments,
            latest: try JSONValue(any: latest),
            message: message
        )
    }

    private func workflowCompletedRecommendation(
        for latest: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard latest["operation"] as? String == "read-browser",
              let execution = latest["execution"] as? [String: Any],
              let outputJSON = execution["outputJSON"] as? [String: Any],
              let tabs = outputJSON["tabs"] as? [[String: Any]],
              let firstTab = tabs.first,
              let tabID = firstTab["id"] as? String else {
            return nil
        }

        let endpoint = outputJSON["endpoint"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--endpoint")
            ?? "http://127.0.0.1:9222"
        return (
            arguments: [
                "03", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
        )
    }

    private func workflowArgumentValue(in arguments: [String]?, for option: String) -> String? {
        guard let arguments,
              let index = arguments.firstIndex(of: option) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }
        return arguments[valueIndex]
    }

    private func workflowDryRunArguments(for operation: String?) -> [String]? {
        guard let operation else {
            return nil
        }
        return ["03", "workflow", "run", "--operation", operation, "--dry-run", "true"]
    }

    private func workflowExecute(
        _ command: WorkflowCommand,
        timeoutMilliseconds: Int,
        maxOutputBytes: Int
    ) throws -> WorkflowExecutionResult {
        var childArguments = command.argv
        guard !childArguments.isEmpty else {
            throw CommandError(description: "workflow command argv was empty")
        }
        childArguments.removeFirst()

        let process = Process()
        process.executableURL = try workflowExecutableURL()
        process.arguments = childArguments
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        let stdoutCapture = WorkflowOutputCapture(maxOutputBytes: maxOutputBytes)
        let stderrCapture = WorkflowOutputCapture(maxOutputBytes: maxOutputBytes)

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            stdoutCapture.append(chunk)
        }
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            stderrCapture.append(chunk)
        }

        let termination = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            termination.signal()
        }

        try process.run()
        let timedOut = termination.wait(timeout: .now() + .milliseconds(timeoutMilliseconds)) == .timedOut
        if timedOut {
            process.terminate()
            if termination.wait(timeout: .now() + .milliseconds(1_000)) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                process.waitUntilExit()
            }
        }

        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        let remainingStdout = stdout.fileHandleForReading.readDataToEndOfFile()
        let remainingStderr = stderr.fileHandleForReading.readDataToEndOfFile()
        stdoutCapture.append(remainingStdout)
        stderrCapture.append(remainingStderr)
        let stdoutSnapshot = stdoutCapture.snapshot()
        let stderrSnapshot = stderrCapture.snapshot()
        let stdoutText = String(data: stdoutSnapshot.data, encoding: .utf8) ?? ""
        let stderrText = String(data: stderrSnapshot.data, encoding: .utf8) ?? ""
        let capturedStdoutBytes = stdoutSnapshot.totalBytes
        let capturedStderrBytes = stderrSnapshot.totalBytes
        let capturedStdoutTruncated = stdoutSnapshot.truncated
        let capturedStderrTruncated = stderrSnapshot.truncated
        let jsonOutput = capturedStdoutTruncated ? nil : try workflowJSONOutput(from: stdoutText)

        return WorkflowExecutionResult(
            argv: command.argv,
            exitCode: process.terminationStatus,
            timeoutMilliseconds: timeoutMilliseconds,
            timedOut: timedOut,
            maxOutputBytes: maxOutputBytes,
            stdout: stdoutText,
            stdoutBytes: capturedStdoutBytes,
            stdoutTruncated: capturedStdoutTruncated,
            stderr: stderrText,
            stderrBytes: capturedStderrBytes,
            stderrTruncated: capturedStderrTruncated,
            outputJSON: jsonOutput
        )
    }

    private func workflowExecutableURL() throws -> URL {
        if let executableURL = Bundle.main.executableURL {
            return executableURL
        }

        let rawPath = CommandLine.arguments.first ?? "03"
        if rawPath.hasPrefix("/") {
            return URL(fileURLWithPath: rawPath)
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(rawPath)
    }

    private func workflowJSONOutput(from stdout: String) throws -> JSONValue? {
        guard let data = stdout.data(using: .utf8), !data.isEmpty else {
            return nil
        }
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            return try JSONValue(any: object)
        } catch {
            return nil
        }
    }

    private func workflowRunMessage(command: WorkflowCommand?, dryRun: Bool, executed: Bool) -> String {
        guard let command else {
            return "Workflow run is blocked; resolve required prerequisites before execution."
        }
        if dryRun && command.mutates {
            return "Dry run only. This workflow is ready but mutating; review the argv array and provide an explicit reason before executing it outside dry-run mode."
        }
        if dryRun {
            return "Dry run only. This non-mutating workflow is ready to execute with `--dry-run false`."
        }
        if executed {
            return "Workflow executed a non-mutating command and captured its output."
        }
        return "Workflow did not execute."
    }

    private func workflowDisplayCommand(_ arguments: [String]) -> String {
        arguments.map(shellQuotedArgument).joined(separator: " ")
    }

    private func shellQuotedArgument(_ argument: String) -> String {
        if argument.isEmpty {
            return "''"
        }
        if argument.range(of: #"^[A-Za-z0-9_@%+=:,./-]+$"#, options: .regularExpression) != nil {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }

    private func observationBlockers(
        accessibility: TrustRecord,
        desktop: DesktopWindowsState
    ) -> [String] {
        var blockers: [String] = []
        if !accessibility.trusted {
            blockers.append("accessibility_not_trusted")
        }
        if !desktop.available {
            blockers.append("desktop_window_metadata_unavailable")
        }
        if desktop.windows.isEmpty {
            blockers.append("no_visible_windows_reported")
        }
        return blockers
    }

    private func observationSuggestedActions(
        accessibilityTrusted: Bool,
        activePid: pid_t?,
        windowLimit: Int
    ) -> [ObservationAction] {
        var actions = [
            ObservationAction(
                name: "desktop.listWindows",
                command: "03 desktop windows --limit \(windowLimit)",
                risk: desktopActionRisk(for: "desktop.listWindows"),
                mutates: false,
                reason: "Refresh visible window metadata and stable desktop identities."
            ),
            ObservationAction(
                name: "apps.list",
                command: "03 apps",
                risk: "low",
                mutates: false,
                reason: "List running GUI apps and identify the active process."
            ),
            ObservationAction(
                name: "clipboard.state",
                command: "03 clipboard state",
                risk: clipboardActionRisk(for: "clipboard.state"),
                mutates: false,
                reason: "Inspect clipboard metadata without reading clipboard text."
            ),
            ObservationAction(
                name: "audit.review",
                command: "03 audit --limit 20",
                risk: "low",
                mutates: false,
                reason: "Review recent audited actions and verification outcomes."
            )
        ]

        if accessibilityTrusted {
            let pidArgument = activePid.map { " --pid \($0)" } ?? ""
            actions.append(ObservationAction(
                name: "accessibility.inspectState",
                command: "03 state\(pidArgument) --depth 3 --max-children 80",
                risk: "low",
                mutates: false,
                reason: "Inspect the active app's UI tree with stable element identities."
            ))
        } else {
            actions.append(ObservationAction(
                name: "accessibility.requestTrust",
                command: "03 trust",
                risk: "low",
                mutates: false,
                reason: "Enable Accessibility inspection before using state or perform."
            ))
        }

        actions.append(ObservationAction(
            name: "browser.listTabs",
            command: "03 browser tabs --endpoint http://127.0.0.1:9222",
            risk: browserActionRisk(for: "browser.listTabs"),
            mutates: false,
            reason: "Inspect browser tabs if a Chromium DevTools endpoint is running."
        ))

        return actions
    }

    private func apps() throws {
        let includeAll = flag("--all")
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        try writeJSON(appSummaries(includeAll: includeAll, activePid: activePid))
    }

    private func state() throws {
        try requireTrusted()
        let depth = option("--depth").flatMap(Int.init) ?? 4
        let maxChildren = option("--max-children").flatMap(Int.init) ?? 120
        if flag("--all") {
            try allState(depth: depth, maxChildren: maxChildren)
            return
        }

        let app = try targetApp()
        let appState = appState(for: app, idPrefix: "w", depth: depth, maxChildren: maxChildren)

        let state = ComputerState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appState.app,
            windows: appState.windows
        )

        try writeJSON(state)
    }

    private func allState(depth: Int, maxChildren: Int) throws {
        let includeBackground = flag("--include-background")
        let apps = runningApps(includeBackground: includeBackground)
        let states = apps.enumerated().compactMap { appIndex, app -> AppState? in
            let state = appState(
                for: app,
                idPrefix: "a\(appIndex).w",
                depth: depth,
                maxChildren: maxChildren
            )
            return state.windows.isEmpty ? nil : state
        }

        try writeJSON(AllComputerState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            apps: states
        ))
    }

    private func perform() throws {
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        var appRecord: AppRecord?
        var elementSummary: AuditElementSummary?
        var elementID: String?
        var action: String?
        var policy: AuditPolicyDecision?
        var identityVerification: IdentityVerification?
        var auditWritten = false

        do {
            action = option("--action") ?? kAXPressAction as String
            policy = policyDecision(actionRisk: riskLevel(for: action!))
            guard policy?.allowed == true else {
                let message = policy?.message ?? "policy denied action"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: nil,
                    elementID: option("--element"),
                    element: nil,
                    action: action,
                    policy: policy,
                    outcome: AuditOutcome(ok: false, code: "policy_denied", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            elementID = try requiredOption("--element")
            try requireTrusted()
            let app = try targetApp()
            appRecord = AppRecord(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                pid: app.processIdentifier
            )
            let element = try resolveElement(id: elementID!, in: app.processIdentifier)
            let normalizedElementID = try normalizedElementID(elementID!)
            elementSummary = auditSummary(
                element,
                pathID: normalizedElementID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )

            identityVerification = try verifyElementIdentity(elementSummary?.stableIdentity)
            guard identityVerification?.ok != false else {
                let message = identityVerification?.message ?? "element identity verification failed"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID,
                    element: elementSummary,
                    action: action,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: identityVerification?.code ?? "identity_rejected", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            let available = elementSummary?.actions ?? actionNames(element)
            guard available.contains(action!) else {
                let message = "element \(elementID!) does not expose action \(action!). Available: \(available.joined(separator: ", "))"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID,
                    element: elementSummary,
                    action: action,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "action_unavailable", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            let result = AXUIElementPerformAction(element, action! as CFString)
            guard result == .success else {
                let message = "AXUIElementPerformAction failed with \(result)"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID,
                    element: elementSummary,
                    action: action,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "action_failed", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            let message = "Performed \(action!) on \(elementID!)."
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "perform",
                risk: riskLevel(for: action!),
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: action,
                policy: policy,
                identityVerification: identityVerification,
                outcome: AuditOutcome(ok: true, code: "performed", message: message)
            ), to: auditURL)
            auditWritten = true

            try writeJSON(ActionResult(
                ok: true,
                pid: app.processIdentifier,
                element: elementID!,
                stableIdentity: elementSummary?.stableIdentity,
                action: action!,
                identityVerification: identityVerification,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            ))
        } catch let error as CommandError {
            if !auditWritten {
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: action.map(riskLevel) ?? "unknown",
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID ?? option("--element"),
                    element: elementSummary,
                    action: action ?? option("--action") ?? kAXPressAction as String,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "rejected", message: error.description)
                ), to: auditURL)
            }
            throw error
        }
    }

    private func audit() throws {
        let auditURL = try auditLogURL()
        let limit = option("--limit").flatMap(Int.init) ?? 20
        let command = option("--command")
        let code = option("--code")
        let records = try readAuditRecords(
            from: auditURL,
            limit: max(0, limit),
            command: command,
            code: code
        )
        try writeJSON(AuditEntries(
            path: auditURL.path,
            command: command,
            code: code,
            limit: max(0, limit),
            entries: records
        ))
    }

    private func task() throws {
        let mode = arguments.dropFirst().first ?? "show"

        switch mode {
        case "start":
            try requirePolicyAllowed(action: "task.memoryStart")
            let title = try requiredOption("--title")
            let taskID = option("--task-id") ?? UUID().uuidString
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: "task.started",
                status: "active",
                title: title,
                summary: option("--summary"),
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "record":
            try requirePolicyAllowed(action: "task.memoryRecord")
            let taskID = try requiredOption("--task-id")
            let kind = try taskMemoryKind(try requiredOption("--kind"))
            let summary = try requiredOption("--summary")
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: kind,
                status: nil,
                title: nil,
                summary: summary,
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "finish":
            try requirePolicyAllowed(action: "task.memoryFinish")
            let taskID = try requiredOption("--task-id")
            let status = try taskFinishStatus(option("--status") ?? "completed")
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: "task.finished",
                status: status,
                title: nil,
                summary: option("--summary"),
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "show":
            try requirePolicyAllowed(action: "task.memoryShow")
            let taskID = try requiredOption("--task-id")
            let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: limit))
        default:
            throw CommandError(description: "unknown task mode '\(mode)'")
        }
    }

    private func files() throws {
        let mode = arguments.dropFirst().first ?? "list"

        func requestedFileURL() throws -> URL {
            let path = try requiredOption("--path")
            return URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
        }

        switch mode {
        case "stat":
            let record = try fileRecord(for: requestedFileURL())
            try writeJSON(FilesystemState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                root: record,
                entries: [],
                maxDepth: 0,
                limit: 0,
                truncated: false
            ))
        case "list":
            let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 2)
            let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
            let includeHidden = flag("--include-hidden")
            let state = try filesystemState(
                rootURL: requestedFileURL(),
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden
            )
            try writeJSON(state)
        case "search":
            let query = try requiredOption("--query")
            guard !query.isEmpty else {
                throw CommandError(description: "--query must not be empty")
            }
            let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 4)
            let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
            let includeHidden = flag("--include-hidden")
            let caseSensitive = flag("--case-sensitive")
            let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 1_048_576)
            let maxSnippetCharacters = max(20, option("--max-snippet-characters").flatMap(Int.init) ?? 240)
            let maxMatchesPerFile = max(1, option("--max-matches-per-file").flatMap(Int.init) ?? 20)
            let result = try filesystemSearchResult(
                rootURL: requestedFileURL(),
                query: query,
                caseSensitive: caseSensitive,
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden,
                maxFileBytes: maxFileBytes,
                maxSnippetCharacters: maxSnippetCharacters,
                maxMatchesPerFile: maxMatchesPerFile
            )
            try writeJSON(result)
        case "wait":
            let expectedExists = option("--exists").map(parseBool) ?? true
            let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
            let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
            let result = try waitForFileState(
                at: requestedFileURL(),
                expectedExists: expectedExists,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            try writeJSON(result)
        case "watch":
            let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 1)
            let limit = max(1, option("--limit").flatMap(Int.init) ?? 200)
            let includeHidden = flag("--include-hidden")
            let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
            let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
            let result = try watchFileChanges(
                at: requestedFileURL(),
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            try writeJSON(result)
        case "checksum":
            let algorithm = option("--algorithm") ?? "sha256"
            let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 104_857_600)
            let result = try fileChecksum(
                for: requestedFileURL(),
                algorithm: algorithm,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "compare":
            let rightPath = try requiredOption("--to")
            let rightURL = URL(fileURLWithPath: expandedPath(rightPath)).standardizedFileURL
            let algorithm = option("--algorithm") ?? "sha256"
            let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 104_857_600)
            let result = try compareFiles(
                leftURL: requestedFileURL(),
                rightURL: rightURL,
                algorithm: algorithm,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "plan":
            let operation = try requiredOption("--operation")
            let result = try fileOperationPreflight(operation: operation)
            try writeJSON(result)
        case "duplicate":
            let destinationPath = try requiredOption("--to")
            let destinationURL = URL(fileURLWithPath: expandedPath(destinationPath)).standardizedFileURL
            let result = try duplicateFile(from: requestedFileURL(), to: destinationURL)
            try writeJSON(result)
        case "move":
            let destinationPath = try requiredOption("--to")
            let destinationURL = URL(fileURLWithPath: expandedPath(destinationPath)).standardizedFileURL
            let result = try moveFile(from: requestedFileURL(), to: destinationURL)
            try writeJSON(result)
        case "mkdir":
            let result = try createDirectory(at: requestedFileURL())
            try writeJSON(result)
        case "rollback":
            let auditRecordID = try requiredOption("--audit-id")
            let result = try rollbackFileMove(auditRecordID: auditRecordID)
            try writeJSON(result)
        default:
            throw CommandError(description: "unknown files mode '\(mode)'")
        }
    }

    private func clipboard() throws {
        let mode = arguments.dropFirst().first ?? "state"
        let pasteboard = targetPasteboard()

        switch mode {
        case "state":
            try writeJSON(clipboardState(for: pasteboard))
        case "read-text":
            let maxCharacters = max(0, option("--max-characters").flatMap(Int.init) ?? 4_096)
            try writeJSON(clipboardText(for: pasteboard, maxCharacters: maxCharacters))
        case "write-text":
            guard let text = option("--text") else {
                throw CommandError(description: "missing required option --text")
            }
            try writeJSON(writeClipboardText(text, to: pasteboard))
        default:
            throw CommandError(description: "unknown clipboard mode '\(mode)'")
        }
    }

    private func browser() throws {
        let mode = arguments.dropFirst().first ?? "tabs"

        switch mode {
        case "tabs":
            let includeNonPageTargets = flag("--include-non-page")
            try writeJSON(browserTabs(includeNonPageTargets: includeNonPageTargets))
        case "tab":
            let id = try requiredOption("--id")
            let includeNonPageTargets = flag("--include-non-page")
            try writeJSON(browserTab(id: id, includeNonPageTargets: includeNonPageTargets))
        case "text":
            let id = try requiredOption("--id")
            let maxCharacters = max(0, option("--max-characters").flatMap(Int.init) ?? 16_384)
            try writeJSON(browserText(id: id, maxCharacters: maxCharacters))
        case "dom":
            let id = try requiredOption("--id")
            let maxElements = max(0, option("--max-elements").flatMap(Int.init) ?? 200)
            let maxTextCharacters = max(0, option("--max-text-characters").flatMap(Int.init) ?? 120)
            try writeJSON(browserDOM(id: id, maxElements: maxElements, maxTextCharacters: maxTextCharacters))
        case "fill":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserFill(id: id, selector: selector, text: text))
        case "navigate":
            let id = try requiredOption("--id")
            let url = try requiredOption("--url")
            try writeJSON(browserNavigate(id: id, requestedURL: url))
        default:
            throw CommandError(description: "unknown browser mode '\(mode)'")
        }
    }

    private func auditSummary(
        _ element: AXUIElement,
        pathID: String,
        ownerName: String?,
        ownerBundleIdentifier: String?
    ) -> AuditElementSummary {
        let role = stringAttribute(element, kAXRoleAttribute)
        let subrole = stringAttribute(element, kAXSubroleAttribute)
        let title = stringAttribute(element, kAXTitleAttribute)
        let help = stringAttribute(element, kAXHelpAttribute)
        let elementFrame = frame(element)
        let actions = actionNames(element)

        return AuditElementSummary(
            stableIdentity: accessibilityElementStableIdentity(
                pathID: pathID,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                role: role,
                subrole: subrole,
                title: title,
                help: help,
                frame: elementFrame,
                actions: actions
            ),
            role: role,
            subrole: subrole,
            title: title,
            help: help,
            enabled: boolAttribute(element, kAXEnabledAttribute),
            actions: actions
        )
    }

    private func verifyElementIdentity(_ stableIdentity: StableIdentity?) throws -> IdentityVerification? {
        let expectedID = option("--expect-identity")
        let minimumConfidence = option("--min-identity-confidence")
        guard expectedID != nil || minimumConfidence != nil else {
            return nil
        }

        guard let stableIdentity else {
            return IdentityVerification(
                ok: false,
                code: "identity_unavailable",
                message: "element identity is unavailable",
                expectedID: expectedID,
                actualID: "unavailable",
                minimumConfidence: minimumConfidence,
                actualConfidence: "unknown",
                identityMatched: expectedID == nil ? nil : false,
                confidenceAccepted: minimumConfidence == nil ? nil : false
            )
        }

        let identityMatched = expectedID.map { $0 == stableIdentity.id }
        let confidenceAccepted: Bool?
        if let minimumConfidence {
            guard let minimumRank = identityConfidenceRank(minimumConfidence) else {
                throw CommandError(description: "invalid --min-identity-confidence '\(minimumConfidence)'. Use low, medium, or high.")
            }
            let actualRank = identityConfidenceRank(stableIdentity.confidence) ?? -1
            confidenceAccepted = actualRank >= minimumRank
        } else {
            confidenceAccepted = nil
        }

        if identityMatched == false {
            return IdentityVerification(
                ok: false,
                code: "identity_mismatch",
                message: "element identity \(stableIdentity.id) did not match expected identity \(expectedID!)",
                expectedID: expectedID,
                actualID: stableIdentity.id,
                minimumConfidence: minimumConfidence,
                actualConfidence: stableIdentity.confidence,
                identityMatched: identityMatched,
                confidenceAccepted: confidenceAccepted
            )
        }

        if confidenceAccepted == false {
            return IdentityVerification(
                ok: false,
                code: "identity_confidence_too_low",
                message: "element identity confidence \(stableIdentity.confidence) is below required \(minimumConfidence!)",
                expectedID: expectedID,
                actualID: stableIdentity.id,
                minimumConfidence: minimumConfidence,
                actualConfidence: stableIdentity.confidence,
                identityMatched: identityMatched,
                confidenceAccepted: confidenceAccepted
            )
        }

        return IdentityVerification(
            ok: true,
            code: "identity_verified",
            message: "element identity matched requested constraints",
            expectedID: expectedID,
            actualID: stableIdentity.id,
            minimumConfidence: minimumConfidence,
            actualConfidence: stableIdentity.confidence,
            identityMatched: identityMatched,
            confidenceAccepted: confidenceAccepted
        )
    }

    private func fileOperationPreflight(operation rawOperation: String) throws -> FileOperationPreflight {
        let operation = rawOperation.lowercased()
        switch operation {
        case "duplicate":
            let sourceURL = URL(fileURLWithPath: expandedPath(try requiredOption("--path"))).standardizedFileURL
            let destinationURL = URL(fileURLWithPath: expandedPath(try requiredOption("--to"))).standardizedFileURL
            return try preflightFileCopyLikeOperation(
                operation: operation,
                action: "filesystem.duplicate",
                sourceURL: sourceURL,
                destinationURL: destinationURL
            )
        case "move":
            let sourceURL = URL(fileURLWithPath: expandedPath(try requiredOption("--path"))).standardizedFileURL
            let destinationURL = URL(fileURLWithPath: expandedPath(try requiredOption("--to"))).standardizedFileURL
            return try preflightFileCopyLikeOperation(
                operation: operation,
                action: "filesystem.move",
                sourceURL: sourceURL,
                destinationURL: destinationURL
            )
        case "mkdir":
            let directoryURL = URL(fileURLWithPath: expandedPath(try requiredOption("--path"))).standardizedFileURL
            return preflightDirectoryCreation(directoryURL)
        case "rollback":
            return try preflightMoveRollback(auditRecordID: try requiredOption("--audit-id"))
        default:
            throw CommandError(description: "unsupported files plan operation '\(rawOperation)'. Use duplicate, move, mkdir, or rollback.")
        }
    }

    private func preflightFileCopyLikeOperation(
        operation: String,
        action: String,
        sourceURL: URL,
        destinationURL: URL
    ) throws -> FileOperationPreflight {
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let sourceRecord = try? fileRecord(for: sourceURL)
        let destinationRecord = try? fileRecord(for: destinationURL)
        let sourceTarget = sourceRecord.map { fileAuditTarget(record: $0, exists: true) } ?? fileAuditTarget(url: sourceURL)
        let destinationTarget = destinationRecord.map { fileAuditTarget(record: $0, exists: true) } ?? fileAuditTarget(url: destinationURL)
        let destinationParentURL = destinationURL.deletingLastPathComponent()
        let sourceParentURL = sourceURL.deletingLastPathComponent()
        var checks: [FilePreflightCheck] = []

        if operation == "move" {
            checks.append(FilePreflightCheck(
                name: "sourceDestinationDifferent",
                ok: sourceURL.path != destinationURL.path,
                code: sourceURL.path != destinationURL.path ? "different_paths" : "same_path",
                message: sourceURL.path != destinationURL.path
                    ? "source and destination are different paths"
                    : "source and destination must be different paths"
            ))
        }

        checks.append(contentsOf: [
            FilePreflightCheck(
                name: "policyAllows",
                ok: policy.allowed,
                code: policy.allowed ? "allowed" : "denied",
                message: policy.message
            ),
            FilePreflightCheck(
                name: "sourceExists",
                ok: sourceRecord != nil,
                code: sourceRecord == nil ? "missing" : "exists",
                message: sourceRecord == nil
                    ? "source does not exist at \(sourceURL.path)"
                    : "source exists at \(sourceURL.path)"
            ),
            FilePreflightCheck(
                name: "sourceRegularFile",
                ok: sourceRecord?.kind == "regularFile",
                code: sourceRecord?.kind == "regularFile" ? "regular_file" : "unsupported_kind",
                message: sourceRecord.map { "source kind is \($0.kind)" } ?? "source kind is unavailable"
            ),
            FilePreflightCheck(
                name: "sourceReadable",
                ok: sourceRecord?.readable == true,
                code: sourceRecord?.readable == true ? "readable" : "unreadable",
                message: sourceRecord?.readable == true
                    ? "source is readable"
                    : "source is not readable"
            ),
            FilePreflightCheck(
                name: "destinationMissing",
                ok: destinationRecord == nil,
                code: destinationRecord == nil ? "missing" : "exists",
                message: destinationRecord == nil
                    ? "destination does not exist at \(destinationURL.path)"
                    : "destination already exists at \(destinationURL.path)"
            ),
            directoryExistsCheck(name: "destinationParentExists", url: destinationParentURL),
            writableDirectoryCheck(name: "destinationParentWritable", url: destinationParentURL)
        ])

        if operation == "move" {
            checks.append(writableDirectoryCheck(name: "sourceParentWritable", url: sourceParentURL))
        }

        return fileOperationPreflightResult(
            operation: operation,
            action: action,
            risk: risk,
            policy: policy,
            source: sourceTarget,
            destination: destinationTarget,
            rollbackOfAuditID: nil,
            checks: checks
        )
    }

    private func preflightDirectoryCreation(_ directoryURL: URL) -> FileOperationPreflight {
        let action = "filesystem.createDirectory"
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let directoryRecord = try? fileRecord(for: directoryURL)
        let directoryTarget = directoryRecord.map { fileAuditTarget(record: $0, exists: true) } ?? fileAuditTarget(url: directoryURL)
        let parentURL = directoryURL.deletingLastPathComponent()
        let checks = [
            FilePreflightCheck(
                name: "policyAllows",
                ok: policy.allowed,
                code: policy.allowed ? "allowed" : "denied",
                message: policy.message
            ),
            FilePreflightCheck(
                name: "destinationMissing",
                ok: directoryRecord == nil,
                code: directoryRecord == nil ? "missing" : "exists",
                message: directoryRecord == nil
                    ? "directory path is available at \(directoryURL.path)"
                    : "directory path already exists at \(directoryURL.path)"
            ),
            directoryExistsCheck(name: "parentExists", url: parentURL),
            writableDirectoryCheck(name: "parentWritable", url: parentURL)
        ]

        return fileOperationPreflightResult(
            operation: "mkdir",
            action: action,
            risk: risk,
            policy: policy,
            source: nil,
            destination: directoryTarget,
            rollbackOfAuditID: nil,
            checks: checks
        )
    }

    private func preflightMoveRollback(auditRecordID: String) throws -> FileOperationPreflight {
        let action = "filesystem.rollbackMove"
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditURL = try auditLogURL()
        let records = try readAuditRecords(from: auditURL, limit: Int.max)
        let originalRecord = records.first { $0.id == auditRecordID }
        let originalSource = originalRecord?.fileSource
        let movedDestination = originalRecord?.fileDestination
        let rollbackSourceURL = movedDestination.map { URL(fileURLWithPath: $0.path).standardizedFileURL }
        let restoreDestinationURL = originalSource.map { URL(fileURLWithPath: $0.path).standardizedFileURL }
        let rollbackSourceRecord = rollbackSourceURL.flatMap { try? fileRecord(for: $0) }
        let restoreDestinationRecord = restoreDestinationURL.flatMap { try? fileRecord(for: $0) }
        let sourceTarget = rollbackSourceRecord.map { fileAuditTarget(record: $0, exists: true) }
            ?? rollbackSourceURL.map(fileAuditTarget)
        let destinationTarget = restoreDestinationRecord.map { fileAuditTarget(record: $0, exists: true) }
            ?? restoreDestinationURL.map(fileAuditTarget)
        var checks = [
            FilePreflightCheck(
                name: "policyAllows",
                ok: policy.allowed,
                code: policy.allowed ? "allowed" : "denied",
                message: policy.message
            ),
            FilePreflightCheck(
                name: "auditRecordFound",
                ok: originalRecord != nil,
                code: originalRecord == nil ? "missing" : "found",
                message: originalRecord == nil
                    ? "no audit record found with id \(auditRecordID)"
                    : "audit record \(auditRecordID) was found"
            ),
            FilePreflightCheck(
                name: "auditRecordSupportsRollback",
                ok: originalRecord?.command == "files.move" && originalRecord?.outcome.ok == true && originalRecord?.outcome.code == "moved",
                code: originalRecord?.command == "files.move" && originalRecord?.outcome.ok == true && originalRecord?.outcome.code == "moved"
                    ? "supported"
                    : "unsupported",
                message: "rollback supports successful files.move audit records"
            ),
            FilePreflightCheck(
                name: "rollbackMetadataPresent",
                ok: originalSource != nil && movedDestination != nil,
                code: originalSource != nil && movedDestination != nil ? "present" : "missing",
                message: originalSource != nil && movedDestination != nil
                    ? "move source and destination metadata are present"
                    : "move source or destination metadata is missing"
            ),
            FilePreflightCheck(
                name: "rollbackSourceExists",
                ok: rollbackSourceRecord != nil,
                code: rollbackSourceRecord == nil ? "missing" : "exists",
                message: rollbackSourceURL.map { "moved file should exist at \($0.path)" } ?? "moved file path is unavailable"
            ),
            FilePreflightCheck(
                name: "restoreDestinationMissing",
                ok: restoreDestinationURL != nil && restoreDestinationRecord == nil,
                code: restoreDestinationRecord == nil ? "missing" : "exists",
                message: restoreDestinationURL.map { "original source path should be available at \($0.path)" } ?? "original source path is unavailable"
            )
        ]

        if let rollbackSourceRecord, let movedDestination {
            checks.append(FilePreflightCheck(
                name: "rollbackSourceMatchesAudit",
                ok: fileRecord(rollbackSourceRecord, matches: movedDestination),
                code: fileRecord(rollbackSourceRecord, matches: movedDestination) ? "matched" : "mismatched",
                message: fileRecord(rollbackSourceRecord, matches: movedDestination)
                    ? "current moved file matches audit metadata"
                    : "current moved file does not match audit metadata"
            ))
        } else {
            checks.append(FilePreflightCheck(
                name: "rollbackSourceMatchesAudit",
                ok: false,
                code: "unavailable",
                message: "current moved file metadata is unavailable"
            ))
        }

        if let restoreDestinationURL {
            let restoreParentURL = restoreDestinationURL.deletingLastPathComponent()
            checks.append(directoryExistsCheck(name: "restoreParentExists", url: restoreParentURL))
            checks.append(writableDirectoryCheck(name: "restoreParentWritable", url: restoreParentURL))
        } else {
            checks.append(FilePreflightCheck(name: "restoreParentExists", ok: false, code: "unavailable", message: "restore parent path is unavailable"))
            checks.append(FilePreflightCheck(name: "restoreParentWritable", ok: false, code: "unavailable", message: "restore parent path is unavailable"))
        }

        if let rollbackSourceURL {
            checks.append(writableDirectoryCheck(name: "rollbackSourceParentWritable", url: rollbackSourceURL.deletingLastPathComponent()))
        } else {
            checks.append(FilePreflightCheck(name: "rollbackSourceParentWritable", ok: false, code: "unavailable", message: "rollback source parent path is unavailable"))
        }

        return fileOperationPreflightResult(
            operation: "rollback",
            action: action,
            risk: risk,
            policy: policy,
            source: sourceTarget,
            destination: destinationTarget,
            rollbackOfAuditID: auditRecordID,
            checks: checks
        )
    }

    private func fileOperationPreflightResult(
        operation: String,
        action: String,
        risk: String,
        policy: AuditPolicyDecision,
        source: FileAuditTarget?,
        destination: FileAuditTarget?,
        rollbackOfAuditID: String?,
        checks: [FilePreflightCheck]
    ) -> FileOperationPreflight {
        let canExecute = checks.allSatisfy(\.ok)
        let message = canExecute
            ? "\(operation) can execute with --allow-risk \(policy.allowedRisk)."
            : "\(operation) is not ready to execute; inspect failed checks."

        return FileOperationPreflight(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            source: source,
            destination: destination,
            rollbackOfAuditID: rollbackOfAuditID,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: message
        )
    }

    private func fileAuditTarget(url: URL) -> FileAuditTarget {
        FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
    }

    private func directoryExistsCheck(name: String, url: URL) -> FilePreflightCheck {
        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        let ok = exists && isDirectory.boolValue
        return FilePreflightCheck(
            name: name,
            ok: ok,
            code: ok ? "directory_exists" : "missing_or_not_directory",
            message: ok
                ? "directory exists at \(url.path)"
                : "directory does not exist at \(url.path)"
        )
    }

    private func writableDirectoryCheck(name: String, url: URL) -> FilePreflightCheck {
        let writable = FileManager.default.isWritableFile(atPath: url.path)
        return FilePreflightCheck(
            name: name,
            ok: writable,
            code: writable ? "writable" : "unwritable",
            message: writable
                ? "directory is writable at \(url.path)"
                : "directory is not writable at \(url.path)"
        )
    }

    private func duplicateFile(from sourceURL: URL, to destinationURL: URL) throws -> FileOperationResult {
        let action = "filesystem.duplicate"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: sourceURL.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: sourceURL.path)
        )
        var destinationTarget = FileAuditTarget(
            path: destinationURL.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: destinationURL.path)
        )
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.duplicate",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
                fileDestination: destinationTarget,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let sourceRecord = try fileRecord(for: sourceURL)
            sourceTarget = fileAuditTarget(record: sourceRecord, exists: true)

            guard sourceRecord.kind == "regularFile" else {
                let message = "filesystem.duplicate currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard sourceRecord.readable else {
                let message = "source file is not readable at \(sourceURL.path)"
                try writeAudit(ok: false, code: "source_unreadable", message: message)
                throw CommandError(description: message)
            }

            guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
                let message = "destination already exists at \(destinationURL.path)"
                try writeAudit(ok: false, code: "destination_exists", message: message)
                throw CommandError(description: message)
            }

            let parentURL = destinationURL.deletingLastPathComponent()
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: parentURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                let message = "destination parent directory does not exist at \(parentURL.path)"
                try writeAudit(ok: false, code: "destination_parent_missing", message: message)
                throw CommandError(description: message)
            }

            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let destinationRecord = try fileRecord(for: destinationURL)
            destinationTarget = fileAuditTarget(record: destinationRecord, exists: true)

            verification = verifyDuplicate(source: sourceRecord, destination: destinationRecord)
            guard verification?.ok == true else {
                let message = verification?.message ?? "duplicate verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Duplicated \(sourceURL.path) to \(destinationURL.path)."
            try writeAudit(ok: true, code: "duplicated", message: message)

            return FileOperationResult(
                ok: true,
                action: action,
                risk: risk,
                source: sourceRecord,
                destination: destinationRecord,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func fileAuditTarget(record: FileRecord, exists: Bool) -> FileAuditTarget {
        FileAuditTarget(
            path: record.path,
            id: record.id,
            kind: record.kind,
            sizeBytes: record.sizeBytes,
            exists: exists
        )
    }

    private func verifyDuplicate(source: FileRecord, destination: FileRecord) -> FileOperationVerification {
        guard destination.kind == "regularFile" else {
            return FileOperationVerification(
                ok: false,
                code: "destination_not_regular_file",
                message: "destination exists but is not a regular file"
            )
        }

        guard source.sizeBytes == destination.sizeBytes else {
            return FileOperationVerification(
                ok: false,
                code: "size_mismatch",
                message: "destination size does not match source size"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "metadata_matched",
            message: "destination exists and size matches source"
        )
    }

    private func moveFile(from sourceURL: URL, to destinationURL: URL) throws -> FileOperationResult {
        let action = "filesystem.move"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: sourceURL.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: sourceURL.path)
        )
        var destinationTarget = FileAuditTarget(
            path: destinationURL.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: destinationURL.path)
        )
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.move",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
                fileDestination: destinationTarget,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            guard sourceURL.path != destinationURL.path else {
                let message = "source and destination must be different paths"
                try writeAudit(ok: false, code: "same_source_and_destination", message: message)
                throw CommandError(description: message)
            }

            let sourceRecord = try fileRecord(for: sourceURL)
            sourceTarget = fileAuditTarget(record: sourceRecord, exists: true)

            guard sourceRecord.kind == "regularFile" else {
                let message = "filesystem.move currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard FileManager.default.isWritableFile(atPath: sourceURL.deletingLastPathComponent().path) else {
                let message = "source parent directory is not writable at \(sourceURL.deletingLastPathComponent().path)"
                try writeAudit(ok: false, code: "source_parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
                let message = "destination already exists at \(destinationURL.path)"
                try writeAudit(ok: false, code: "destination_exists", message: message)
                throw CommandError(description: message)
            }

            let parentURL = destinationURL.deletingLastPathComponent()
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: parentURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                let message = "destination parent directory does not exist at \(parentURL.path)"
                try writeAudit(ok: false, code: "destination_parent_missing", message: message)
                throw CommandError(description: message)
            }

            guard FileManager.default.isWritableFile(atPath: parentURL.path) else {
                let message = "destination parent directory is not writable at \(parentURL.path)"
                try writeAudit(ok: false, code: "destination_parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)

            let destinationRecord = try fileRecord(for: destinationURL)
            destinationTarget = fileAuditTarget(record: destinationRecord, exists: true)

            verification = verifyMove(source: sourceRecord, destination: destinationRecord)
            guard verification?.ok == true else {
                let message = verification?.message ?? "move verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Moved \(sourceURL.path) to \(destinationURL.path)."
            try writeAudit(ok: true, code: "moved", message: message)

            return FileOperationResult(
                ok: true,
                action: action,
                risk: risk,
                source: sourceRecord,
                destination: destinationRecord,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func verifyMove(source: FileRecord, destination: FileRecord) -> FileOperationVerification {
        guard !FileManager.default.fileExists(atPath: source.path) else {
            return FileOperationVerification(
                ok: false,
                code: "source_still_exists",
                message: "source path still exists after move"
            )
        }

        guard destination.kind == "regularFile" else {
            return FileOperationVerification(
                ok: false,
                code: "destination_not_regular_file",
                message: "destination exists but is not a regular file"
            )
        }

        guard source.sizeBytes == destination.sizeBytes else {
            return FileOperationVerification(
                ok: false,
                code: "size_mismatch",
                message: "destination size does not match original source size"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "moved_and_metadata_matched",
            message: "source path is gone, destination exists, and size matches original source"
        )
    }

    private func createDirectory(at directoryURL: URL) throws -> DirectoryOperationResult {
        let action = "filesystem.createDirectory"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var directoryTarget = FileAuditTarget(
            path: directoryURL.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: directoryURL.path)
        )
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.mkdir",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: nil,
                fileDestination: directoryTarget,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            guard !FileManager.default.fileExists(atPath: directoryURL.path) else {
                let message = "directory already exists at \(directoryURL.path)"
                try writeAudit(ok: false, code: "destination_exists", message: message)
                throw CommandError(description: message)
            }

            let parentURL = directoryURL.deletingLastPathComponent()
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: parentURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                let message = "parent directory does not exist at \(parentURL.path)"
                try writeAudit(ok: false, code: "parent_missing", message: message)
                throw CommandError(description: message)
            }

            guard FileManager.default.isWritableFile(atPath: parentURL.path) else {
                let message = "parent directory is not writable at \(parentURL.path)"
                try writeAudit(ok: false, code: "parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: false)

            let directoryRecord = try fileRecord(for: directoryURL)
            directoryTarget = fileAuditTarget(record: directoryRecord, exists: true)

            verification = verifyCreatedDirectory(directoryRecord)
            guard verification?.ok == true else {
                let message = verification?.message ?? "directory creation verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Created directory \(directoryURL.path)."
            try writeAudit(ok: true, code: "created_directory", message: message)

            return DirectoryOperationResult(
                ok: true,
                action: action,
                risk: risk,
                directory: directoryRecord,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func verifyCreatedDirectory(_ directory: FileRecord) -> FileOperationVerification {
        guard directory.kind == "directory" else {
            return FileOperationVerification(
                ok: false,
                code: "not_directory",
                message: "created path exists but is not a directory"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "directory_exists",
            message: "directory exists at requested path"
        )
    }

    private func rollbackFileMove(auditRecordID: String) throws -> FileRollbackResult {
        let action = "filesystem.rollbackMove"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var rollbackSourceTarget: FileAuditTarget?
        var restoreDestinationTarget: FileAuditTarget?
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.rollback",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: rollbackSourceTarget,
                fileDestination: restoreDestinationTarget,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            let records = try readAuditRecords(from: auditURL, limit: Int.max)
            guard let originalRecord = records.first(where: { $0.id == auditRecordID }) else {
                let message = "no audit record found with id \(auditRecordID)"
                try writeAudit(ok: false, code: "rollback_record_missing", message: message)
                throw CommandError(description: message)
            }

            guard originalRecord.command == "files.move",
                  originalRecord.outcome.ok,
                  originalRecord.outcome.code == "moved" else {
                let message = "audit record \(auditRecordID) is not a successful files.move record"
                try writeAudit(ok: false, code: "unsupported_rollback_record", message: message)
                throw CommandError(description: message)
            }

            guard let originalSource = originalRecord.fileSource,
                  let movedDestination = originalRecord.fileDestination else {
                let message = "audit record \(auditRecordID) does not contain move source and destination metadata"
                try writeAudit(ok: false, code: "rollback_metadata_missing", message: message)
                throw CommandError(description: message)
            }

            let rollbackSourceURL = URL(fileURLWithPath: movedDestination.path).standardizedFileURL
            let restoreDestinationURL = URL(fileURLWithPath: originalSource.path).standardizedFileURL
            rollbackSourceTarget = FileAuditTarget(
                path: rollbackSourceURL.path,
                id: nil,
                kind: nil,
                sizeBytes: nil,
                exists: FileManager.default.fileExists(atPath: rollbackSourceURL.path)
            )
            restoreDestinationTarget = FileAuditTarget(
                path: restoreDestinationURL.path,
                id: nil,
                kind: nil,
                sizeBytes: nil,
                exists: FileManager.default.fileExists(atPath: restoreDestinationURL.path)
            )

            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let rollbackSourceRecord = try fileRecord(for: rollbackSourceURL)
            rollbackSourceTarget = fileAuditTarget(record: rollbackSourceRecord, exists: true)

            guard fileRecord(rollbackSourceRecord, matches: movedDestination) else {
                let message = "current moved file does not match audit metadata at \(rollbackSourceURL.path)"
                try writeAudit(ok: false, code: "rollback_source_mismatch", message: message)
                throw CommandError(description: message)
            }

            guard !FileManager.default.fileExists(atPath: restoreDestinationURL.path) else {
                let message = "restore destination already exists at \(restoreDestinationURL.path)"
                try writeAudit(ok: false, code: "restore_destination_exists", message: message)
                throw CommandError(description: message)
            }

            let restoreParentURL = restoreDestinationURL.deletingLastPathComponent()
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: restoreParentURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                let message = "restore parent directory does not exist at \(restoreParentURL.path)"
                try writeAudit(ok: false, code: "restore_parent_missing", message: message)
                throw CommandError(description: message)
            }

            guard FileManager.default.isWritableFile(atPath: restoreParentURL.path) else {
                let message = "restore parent directory is not writable at \(restoreParentURL.path)"
                try writeAudit(ok: false, code: "restore_parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            guard FileManager.default.isWritableFile(atPath: rollbackSourceURL.deletingLastPathComponent().path) else {
                let message = "moved file parent directory is not writable at \(rollbackSourceURL.deletingLastPathComponent().path)"
                try writeAudit(ok: false, code: "rollback_source_parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            try FileManager.default.moveItem(at: rollbackSourceURL, to: restoreDestinationURL)

            let restoredRecord = try fileRecord(for: restoreDestinationURL)
            restoreDestinationTarget = fileAuditTarget(record: restoredRecord, exists: true)
            rollbackSourceTarget = FileAuditTarget(
                path: rollbackSourceURL.path,
                id: movedDestination.id,
                kind: movedDestination.kind,
                sizeBytes: movedDestination.sizeBytes,
                exists: FileManager.default.fileExists(atPath: rollbackSourceURL.path)
            )

            verification = verifyMoveRollback(
                restoredSource: restoredRecord,
                originalSource: originalSource,
                movedDestination: movedDestination
            )
            guard verification?.ok == true else {
                let message = verification?.message ?? "move rollback verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Rolled back move \(auditRecordID), restoring \(restoreDestinationURL.path)."
            try writeAudit(ok: true, code: "rolled_back_move", message: message)

            return FileRollbackResult(
                ok: true,
                action: action,
                risk: risk,
                rollbackOfAuditID: auditRecordID,
                restoredSource: restoredRecord,
                previousDestination: rollbackSourceTarget!,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func fileRecord(_ record: FileRecord, matches target: FileAuditTarget) -> Bool {
        if let kind = target.kind, record.kind != kind {
            return false
        }
        if let sizeBytes = target.sizeBytes, record.sizeBytes != sizeBytes {
            return false
        }
        if let id = target.id, record.id != id {
            return false
        }
        return true
    }

    private func verifyMoveRollback(
        restoredSource: FileRecord,
        originalSource: FileAuditTarget,
        movedDestination: FileAuditTarget
    ) -> FileOperationVerification {
        guard !FileManager.default.fileExists(atPath: movedDestination.path) else {
            return FileOperationVerification(
                ok: false,
                code: "moved_destination_still_exists",
                message: "moved destination still exists after rollback"
            )
        }

        guard restoredSource.path == originalSource.path else {
            return FileOperationVerification(
                ok: false,
                code: "restored_path_mismatch",
                message: "restored file path does not match original source path"
            )
        }

        guard fileRecord(restoredSource, matches: originalSource) else {
            return FileOperationVerification(
                ok: false,
                code: "restored_metadata_mismatch",
                message: "restored file does not match original source metadata"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "move_restored",
            message: "original source path is restored and moved destination is gone"
        )
    }

    private func waitForFileState(
        at url: URL,
        expectedExists: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> FilesystemWaitResult {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var exists = FileManager.default.fileExists(atPath: url.path)

        while exists != expectedExists && Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            exists = FileManager.default.fileExists(atPath: url.path)
        }

        let elapsedMilliseconds = max(0, Int(Date().timeIntervalSince(start) * 1_000))
        let matched = exists == expectedExists
        let record = exists ? try fileRecord(for: url) : nil
        let message: String
        if matched {
            message = expectedExists
                ? "Path exists at \(url.path)."
                : "Path does not exist at \(url.path)."
        } else {
            message = expectedExists
                ? "Timed out waiting for path to exist at \(url.path)."
                : "Timed out waiting for path to disappear at \(url.path)."
        }

        return FilesystemWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            path: url.path,
            expectedExists: expectedExists,
            matched: matched,
            elapsedMilliseconds: elapsedMilliseconds,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            file: record,
            message: message
        )
    }

    private struct FileWatchSnapshot {
        let recordsByPath: [String: FileRecord]
        let truncated: Bool
    }

    private func watchFileChanges(
        at url: URL,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> FilesystemWatchResult {
        let root = try fileRecord(for: url)
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        let before = try fileWatchSnapshot(
            at: url,
            maxDepth: maxDepth,
            limit: limit,
            includeHidden: includeHidden
        )
        var after = before
        var events = fileWatchEvents(before: before.recordsByPath, after: after.recordsByPath)

        while events.isEmpty && Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            after = try fileWatchSnapshot(
                at: url,
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden
            )
            events = fileWatchEvents(before: before.recordsByPath, after: after.recordsByPath)
        }

        let elapsedMilliseconds = max(0, Int(Date().timeIntervalSince(start) * 1_000))
        let matched = !events.isEmpty
        let message = matched
            ? "Observed \(events.count) filesystem event(s) under \(url.path)."
            : "Timed out waiting for filesystem changes under \(url.path)."

        return FilesystemWatchResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            root: root,
            maxDepth: maxDepth,
            limit: limit,
            includeHidden: includeHidden,
            matched: matched,
            events: events,
            eventCount: events.count,
            beforeCount: before.recordsByPath.count,
            afterCount: after.recordsByPath.count,
            beforeTruncated: before.truncated,
            afterTruncated: after.truncated,
            elapsedMilliseconds: elapsedMilliseconds,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            message: message
        )
    }

    private func fileWatchSnapshot(
        at url: URL,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool
    ) throws -> FileWatchSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FileWatchSnapshot(recordsByPath: [:], truncated: false)
        }

        let root = try fileRecord(for: url)
        var records = [root]
        var truncated = false

        if root.kind == "directory" {
            collectFileWatchRecords(
                from: url,
                currentDepth: 0,
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden,
                records: &records,
                truncated: &truncated
            )
        }

        return FileWatchSnapshot(
            recordsByPath: Dictionary(uniqueKeysWithValues: records.map { ($0.path, $0) }),
            truncated: truncated
        )
    }

    private func collectFileWatchRecords(
        from directoryURL: URL,
        currentDepth: Int,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool,
        records: inout [FileRecord],
        truncated: inout Bool
    ) {
        guard currentDepth < maxDepth, !truncated else {
            return
        }

        let urls: [URL]
        do {
            urls = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: Array(fileResourceKeys()),
                options: includeHidden ? [] : [.skipsHiddenFiles]
            )
            .sorted { $0.path < $1.path }
        } catch {
            return
        }

        for url in urls {
            if records.count >= limit {
                truncated = true
                return
            }

            guard let record = try? fileRecord(for: url) else {
                continue
            }
            records.append(record)

            if record.kind == "directory" {
                collectFileWatchRecords(
                    from: url,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    limit: limit,
                    includeHidden: includeHidden,
                    records: &records,
                    truncated: &truncated
                )
            }

            if truncated {
                return
            }
        }
    }

    private func fileWatchEvents(
        before: [String: FileRecord],
        after: [String: FileRecord]
    ) -> [FileWatchEvent] {
        let paths = Set(before.keys).union(after.keys).sorted()
        return paths.compactMap { path in
            let previous = before[path]
            let current = after[path]

            let type: String
            if previous == nil, current != nil {
                type = "created"
            } else if previous != nil, current == nil {
                type = "deleted"
            } else if let previous, let current, fileWatchFingerprint(previous) != fileWatchFingerprint(current) {
                type = "modified"
            } else {
                return nil
            }

            return FileWatchEvent(
                id: "fileEvent:\(sha256Digest("\(type):\(path)"))",
                type: type,
                path: path,
                previous: previous,
                current: current
            )
        }
    }

    private func fileWatchFingerprint(_ record: FileRecord) -> String {
        [
            record.id,
            record.kind,
            record.sizeBytes.map(String.init) ?? "",
            record.modifiedAt ?? "",
            String(record.hidden),
            String(record.readable),
            String(record.writable)
        ].joined(separator: "|")
    }

    private func browserTabs(includeNonPageTargets: Bool) throws -> BrowserTabsState {
        let endpoint = try browserEndpoint()
        let tabs = try fetchBrowserTabs(
            from: endpoint,
            includeNonPageTargets: includeNonPageTargets
        )

        return BrowserTabsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            includeNonPageTargets: includeNonPageTargets,
            count: tabs.count,
            tabs: tabs
        )
    }

    private func browserTab(id: String, includeNonPageTargets: Bool) throws -> BrowserTabState {
        let endpoint = try browserEndpoint()
        let tabs = try fetchBrowserTabs(
            from: endpoint,
            includeNonPageTargets: includeNonPageTargets
        )
        guard let tab = tabs.first(where: { $0.id == id }) else {
            throw CommandError(description: "no browser tab found with id \(id)")
        }

        return BrowserTabState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tab: tab
        )
    }

    private func fetchBrowserTabs(
        from endpoint: URL,
        includeNonPageTargets: Bool
    ) throws -> [BrowserTab] {
        let listURL = browserListURL(for: endpoint)
        let data: Data
        do {
            data = try Data(contentsOf: listURL)
        } catch {
            throw CommandError(description: "could not read browser DevTools target list at \(listURL.absoluteString): \(error.localizedDescription)")
        }

        let targets: [DevToolsTarget]
        do {
            targets = try JSONDecoder().decode([DevToolsTarget].self, from: data)
        } catch {
            throw CommandError(description: "browser DevTools target list at \(listURL.absoluteString) was not valid JSON: \(error.localizedDescription)")
        }

        return targets
            .filter { includeNonPageTargets || ($0.type ?? "page") == "page" }
            .map(browserTab)
            .sorted { left, right in
                (left.title ?? left.url ?? left.id) < (right.title ?? right.url ?? right.id)
            }
    }

    private func browserTab(from target: DevToolsTarget) -> BrowserTab {
        BrowserTab(
            id: target.id,
            type: target.type ?? "page",
            title: target.title,
            url: target.url,
            description: target.description,
            webSocketDebuggerURL: target.webSocketDebuggerUrl,
            devtoolsFrontendURL: target.devtoolsFrontendUrl,
            faviconURL: target.faviconUrl,
            attached: target.attached,
            actions: [
                BrowserAction(
                    name: "browser.inspectTab",
                    risk: browserActionRisk(for: "browser.inspectTab"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readText",
                    risk: browserActionRisk(for: "browser.readText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readDOM",
                    risk: browserActionRisk(for: "browser.readDOM"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.fillFormField",
                    risk: browserActionRisk(for: "browser.fillFormField"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.navigate",
                    risk: browserActionRisk(for: "browser.navigate"),
                    mutates: true
                )
            ]
        )
    }

    private func browserText(id: String, maxCharacters: Int) throws -> BrowserTextResult {
        let action = "browser.readText"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let text = try readBrowserInnerText(from: webSocketURL)
            let digest = sha256Digest(text)
            let returnedText: String
            let truncated: Bool
            if text.count > maxCharacters {
                returnedText = String(text.prefix(maxCharacters))
                truncated = true
            } else {
                returnedText = text
                truncated = false
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: text.count,
                textDigest: digest,
                domNodeCount: nil,
                domDigest: nil
            )

            let message = truncated
                ? "Read truncated browser page text from tab \(id)."
                : "Read browser page text from tab \(id)."
            try writeAudit(ok: true, code: "read_text", message: message)

            return BrowserTextResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                text: returnedText,
                textLength: text.count,
                textDigest: digest,
                truncated: truncated,
                maxCharacters: maxCharacters,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func browserDOM(id: String, maxElements: Int, maxTextCharacters: Int) throws -> BrowserDOMResult {
        let action = "browser.readDOM"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.dom",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let snapshot = try readBrowserDOMSnapshot(
                from: webSocketURL,
                maxElements: maxElements,
                maxTextCharacters: maxTextCharacters
            )
            let snapshotData = try JSONEncoder().encode(snapshot)
            let digest = sha256Digest(String(decoding: snapshotData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: snapshot.elementCount,
                domDigest: digest
            )

            let message = snapshot.truncated
                ? "Read truncated browser DOM snapshot from tab \(id)."
                : "Read browser DOM snapshot from tab \(id)."
            try writeAudit(ok: true, code: "read_dom", message: message)

            return BrowserDOMResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                url: snapshot.url,
                title: snapshot.title,
                elements: snapshot.elements,
                elementCount: snapshot.elementCount,
                truncated: snapshot.truncated,
                maxElements: maxElements,
                maxTextCharacters: maxTextCharacters,
                digest: digest,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func browserFill(id: String, selector: String, text: String) throws -> BrowserFormFillResult {
        let action = "browser.fillFormField"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let textDigest = sha256Digest(text)
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            formSelector: selector,
            formTextLength: text.count,
            formTextDigest: textDigest
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.fill",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                formSelector: selector,
                formTextLength: text.count,
                formTextDigest: textDigest
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try fillBrowserFormField(
                selector: selector,
                text: text,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched && payload.valueLength == text.count,
                code: payload.ok && payload.matched && payload.valueLength == text.count ? "value_matched" : payload.code,
                message: payload.ok && payload.matched && payload.valueLength == text.count
                    ? "browser form field contains text with the requested length"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Filled browser form field matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "filled", message: message, verification: verification)

            return BrowserFormFillResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                textLength: text.count,
                textDigest: textDigest,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                resultingValueLength: payload.valueLength,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func browserNavigate(id: String, requestedURL: String) throws -> BrowserNavigationResult {
        let action = "browser.navigate"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let expectedURL = option("--expect-url") ?? requestedURL
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var verification: BrowserNavigationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            navigationURL: requestedURL,
            currentURL: nil,
            urlMatched: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.navigate",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification.map {
                    FileOperationVerification(ok: $0.ok, code: $0.code, message: $0.message)
                },
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            let normalizedRequestedURL = try validatedBrowserNavigationURL(requestedURL)
            let normalizedExpectedURL = try validatedBrowserExpectedURL(expectedURL)

            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedRequestedURL,
                currentURL: tab.url,
                urlMatched: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            verification = try navigateBrowserPage(
                tabID: id,
                requestedURL: normalizedRequestedURL,
                expectedURL: normalizedExpectedURL,
                match: match,
                endpoint: endpoint,
                webSocketURL: webSocketURL,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedRequestedURL,
                currentURL: verification?.currentURL,
                urlMatched: verification?.matched
            )

            guard let verification, verification.ok else {
                let message = verification?.message ?? "browser navigation verification failed"
                try writeAudit(ok: false, code: verification?.code ?? "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Navigated browser tab \(id) and verified the resulting URL."
            try writeAudit(ok: true, code: "navigated", message: message)

            return BrowserNavigationResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                requestedURL: normalizedRequestedURL,
                expectedURL: normalizedExpectedURL,
                match: match,
                verification: verification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func readBrowserInnerText(from webSocketURL: URL) throws -> String {
        let expression = """
        (() => {
          const root = document.body || document.documentElement;
          return root ? root.innerText : "";
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        if let value = remoteObject.value {
            return value
        }
        if remoteObject.type == "undefined" {
            return ""
        }
        throw CommandError(description: "Chrome DevTools Runtime.evaluate returned \(remoteObject.type ?? "unknown") instead of string text")
    }

    private func readBrowserDOMSnapshot(
        from webSocketURL: URL,
        maxElements: Int,
        maxTextCharacters: Int
    ) throws -> BrowserDOMSnapshotPayload {
        let expression = """
        (() => {
          const maxElements = \(maxElements);
          const maxTextCharacters = \(maxTextCharacters);
          const root = document.body || document.documentElement;
          const ignoredTags = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE"]);
          const attrNames = ["id", "class", "name", "aria-label", "placeholder", "title", "href", "type"];
          const elements = [];
          const ids = new Map();
          const queue = root ? [{ element: root, depth: 0 }] : [];

          const normalizedText = (element) => {
            const raw = (element.innerText || element.textContent || "").replace(/\\s+/g, " ").trim();
            return {
              text: raw.length > maxTextCharacters ? raw.slice(0, maxTextCharacters) : raw,
              length: raw.length
            };
          };

          const inferredRole = (element) => {
            const explicit = element.getAttribute("role");
            if (explicit) return explicit;
            const tag = element.tagName.toLowerCase();
            if (tag === "a" && element.href) return "link";
            if (tag === "button") return "button";
            if (tag === "select") return "combobox";
            if (tag === "textarea") return "textbox";
            if (tag === "form") return "form";
            if (/^h[1-6]$/.test(tag)) return "heading";
            if (tag === "nav") return "navigation";
            if (tag === "main") return "main";
            if (tag === "header") return "banner";
            if (tag === "footer") return "contentinfo";
            if (tag === "input") {
              const type = (element.getAttribute("type") || "text").toLowerCase();
              if (type === "checkbox") return "checkbox";
              if (type === "radio") return "radio";
              if (type === "button" || type === "submit" || type === "reset") return "button";
              return "textbox";
            }
            return null;
          };

          while (queue.length && elements.length < maxElements) {
            const { element, depth } = queue.shift();
            if (ignoredTags.has(element.tagName)) continue;

            const id = `dom.${elements.length}`;
            ids.set(element, id);
            const attributes = {};
            for (const name of attrNames) {
              let value = element.getAttribute(name);
              if (name === "href" && element.href) value = element.href;
              if (value) attributes[name] = value;
            }

            const text = normalizedText(element);
            const inputType = element.tagName === "INPUT" ? (element.getAttribute("type") || "text").toLowerCase() : null;
            const suppressValueMetadata = inputType === "password" || inputType === "hidden";
            const value = !suppressValueMetadata && "value" in element ? String(element.value || "") : null;
            elements.push({
              id,
              parentID: ids.get(element.parentElement) || null,
              depth,
              tagName: element.tagName.toLowerCase(),
              role: inferredRole(element),
              text: text.text || null,
              textLength: text.length,
              attributes,
              inputType,
              checked: "checked" in element ? Boolean(element.checked) : null,
              disabled: "disabled" in element ? Boolean(element.disabled) : null,
              hasValue: value === null ? null : value.length > 0,
              valueLength: value === null ? null : value.length
            });

            for (const child of element.children) {
              queue.push({ element: child, depth: depth + 1 });
            }
          }

          return JSON.stringify({
            url: location.href,
            title: document.title || null,
            elements,
            elementCount: elements.length,
            truncated: queue.length > 0
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a DOM snapshot string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools DOM snapshot was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserDOMSnapshotPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools DOM snapshot was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func fillBrowserFormField(
        selector: String,
        text: String,
        at webSocketURL: URL
    ) throws -> BrowserFormFillPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const text = \(try javascriptStringLiteral(text));
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            valueLength: extra.valueLength ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = Boolean(element.disabled);
          const readOnly = Boolean(element.readOnly);
          const metadata = { tagName, inputType, disabled, readOnly };

          if (disabled) {
            return result(false, "element_disabled", "The matched form field is disabled.", metadata);
          }
          if (readOnly) {
            return result(false, "element_readonly", "The matched form field is read-only.", metadata);
          }
          if (tagName === "input" && ["password", "hidden", "file"].includes(inputType)) {
            return result(false, "unsupported_sensitive_field", "The matched input type is not supported by browser fill.", metadata);
          }

          const setValue = "value" in element;
          const setContentEditable = !setValue && element.isContentEditable;
          if (!setValue && !setContentEditable) {
            return result(false, "unsupported_element", "The matched element does not expose a writable value.", metadata);
          }

          if (setValue) {
            element.focus?.();
            element.value = text;
          } else {
            element.focus?.();
            element.innerText = text;
          }

          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const currentValue = setValue ? String(element.value || "") : String(element.innerText || "");
          return result(true, "filled", "The matched form field was filled and verified.", {
            ...metadata,
            valueLength: currentValue.length,
            matched: currentValue === text
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a form fill result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools form fill result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserFormFillPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools form fill result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func navigateBrowserPage(
        tabID: String,
        requestedURL: String,
        expectedURL: String,
        match: String,
        endpoint: URL,
        webSocketURL: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserNavigationVerification {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try JSONDecoder().decode(BrowserNavigationVerification.self, from: data)
        }

        let response = try sendCDPCommand(
            method: "Page.navigate",
            params: ["url": requestedURL],
            at: webSocketURL,
            timeout: Double(timeoutMilliseconds) / 1_000.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Page.navigate failed with \(error.code): \(error.message)")
        }

        return try waitForBrowserURL(
            tabID: tabID,
            requestedURL: requestedURL,
            expectedURL: expectedURL,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
    }

    private func waitForBrowserURL(
        tabID: String,
        requestedURL: String,
        expectedURL: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserNavigationVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentURL: String?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            currentURL = tabs.first(where: { $0.id == tabID })?.url
            if browserURL(currentURL, matches: expectedURL, mode: match) {
                return BrowserNavigationVerification(
                    ok: true,
                    code: "url_matched",
                    message: "browser tab URL matched expected \(match) value",
                    requestedURL: requestedURL,
                    expectedURL: expectedURL,
                    currentURL: currentURL,
                    match: match,
                    matched: true
                )
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserNavigationVerification(
            ok: false,
            code: "url_mismatch",
            message: "browser tab URL did not match expected \(match) value before timeout",
            requestedURL: requestedURL,
            expectedURL: expectedURL,
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }

    private func browserURL(_ currentURL: String?, matches expectedURL: String, mode: String) -> Bool {
        guard let currentURL else {
            return false
        }

        switch mode {
        case "exact":
            return currentURL == expectedURL
        case "prefix":
            return currentURL.hasPrefix(expectedURL)
        case "contains":
            return currentURL.contains(expectedURL)
        default:
            return false
        }
    }

    private func browserURLMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "prefix", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser URL match mode '\(rawMode)'. Use exact, prefix, or contains.")
        }
    }

    private func validatedBrowserNavigationURL(_ rawURL: String) throws -> String {
        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            throw CommandError(description: "browser navigation URL must be an absolute http or https URL")
        }
        return url.absoluteString
    }

    private func validatedBrowserExpectedURL(_ rawURL: String) throws -> String {
        guard !rawURL.isEmpty else {
            throw CommandError(description: "browser expected URL must not be empty")
        }
        if rawURL.contains("://") {
            return try validatedBrowserNavigationURL(rawURL)
        }
        return rawURL
    }

    private func evaluateCDPRuntimeExpression(
        _ expression: String,
        at webSocketURL: URL,
        timeout: TimeInterval
    ) throws -> CDPEvaluateResponse {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try Self.decodeCDPEvaluateResponse(from: data)
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let requestID = 1
        let payload: [String: Any] = [
            "id": requestID,
            "method": "Runtime.evaluate",
            "params": [
                "expression": expression,
                "awaitPromise": true,
                "returnByValue": true
            ]
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let result = CDPResponseBox()

        @Sendable func receiveResponse(remainingMessages: Int) {
            guard remainingMessages > 0 else {
                result.set(.failure(CommandError(description: "Chrome DevTools did not return Runtime.evaluate response")))
                semaphore.signal()
                return
            }

            task.receive { messageResult in
                switch messageResult {
                case .failure(let error):
                    result.set(.failure(error))
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }

                        let response = try Self.decodeCDPEvaluateResponse(from: data)
                        if response.id == requestID {
                            result.set(.success(response))
                            semaphore.signal()
                        } else {
                            receiveResponse(remainingMessages: remainingMessages - 1)
                        }
                    } catch {
                        result.set(.failure(error))
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        task.send(.data(requestData)) { error in
            if let error {
                result.set(.failure(error))
                semaphore.signal()
                return
            }
            receiveResponse(remainingMessages: 20)
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools Runtime.evaluate response")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not produce a response")
        }()
    }

    private func sendCDPCommand(
        method: String,
        params: [String: Any],
        at webSocketURL: URL,
        timeout: TimeInterval
    ) throws -> CDPCommandResponse {
        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let requestID = 1
        let payload: [String: Any] = [
            "id": requestID,
            "method": method,
            "params": params
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let result = CDPCommandResponseBox()

        @Sendable func receiveResponse(remainingMessages: Int) {
            guard remainingMessages > 0 else {
                result.set(.failure(CommandError(description: "Chrome DevTools did not return \(method) response")))
                semaphore.signal()
                return
            }

            task.receive { messageResult in
                switch messageResult {
                case .failure(let error):
                    result.set(.failure(error))
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }

                        let response = try JSONDecoder().decode(CDPCommandResponse.self, from: data)
                        if response.id == requestID {
                            result.set(.success(response))
                            semaphore.signal()
                        } else {
                            receiveResponse(remainingMessages: remainingMessages - 1)
                        }
                    } catch {
                        result.set(.failure(error))
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        task.send(.data(requestData)) { error in
            if let error {
                result.set(.failure(error))
                semaphore.signal()
                return
            }
            receiveResponse(remainingMessages: 20)
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools \(method) response")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "Chrome DevTools \(method) did not produce a response")
        }()
    }

    private static func decodeCDPEvaluateResponse(from data: Data) throws -> CDPEvaluateResponse {
        do {
            return try JSONDecoder().decode(CDPEvaluateResponse.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func browserEndpoint() throws -> URL {
        let rawEndpoint = option("--endpoint") ?? "http://127.0.0.1:9222"
        if let url = URL(string: rawEndpoint), url.scheme != nil {
            guard ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
                throw CommandError(description: "unsupported browser endpoint scheme '\(url.scheme ?? "")'. Use http, https, or file.")
            }
            return url
        }

        return URL(fileURLWithPath: expandedPath(rawEndpoint)).standardizedFileURL
    }

    private func browserListURL(for endpoint: URL) -> URL {
        if endpoint.path.hasSuffix("/json/list") {
            return endpoint
        }
        return endpoint.appendingPathComponent("json/list")
    }

    private func readURLData(from url: URL, timeoutMilliseconds: Int) throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Double(timeoutMilliseconds) / 1_000.0
        configuration.timeoutIntervalForResource = Double(timeoutMilliseconds) / 1_000.0
        let session = URLSession(configuration: configuration)
        let semaphore = DispatchSemaphore(value: 0)
        let result = DataResponseBox()
        let task = session.dataTask(with: url) { data, _, error in
            if let error {
                result.set(.failure(error))
            } else if let data {
                result.set(.success(data))
            } else {
                result.set(.failure(CommandError(description: "no response data from \(url.absoluteString)")))
            }
            semaphore.signal()
        }

        task.resume()
        if semaphore.wait(timeout: .now() + Double(timeoutMilliseconds) / 1_000.0) == .timedOut {
            task.cancel()
            session.invalidateAndCancel()
            throw CommandError(description: "timed out reading \(url.absoluteString)")
        }
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "no response from \(url.absoluteString)")
        }()
    }

    private func fileChecksum(
        for url: URL,
        algorithm: String,
        maxFileBytes: Int
    ) throws -> FilesystemChecksumResult {
        let normalizedAlgorithm = algorithm.lowercased()
        guard normalizedAlgorithm == "sha256" else {
            throw CommandError(description: "unsupported checksum algorithm '\(algorithm)'. Use sha256.")
        }

        let record = try fileRecord(for: url)
        guard record.kind == "regularFile" else {
            throw CommandError(description: "filesystem.checksum currently supports regular files only")
        }
        guard record.readable else {
            throw CommandError(description: "file is not readable at \(url.path)")
        }
        if let size = record.sizeBytes, size > maxFileBytes {
            throw CommandError(description: "file size \(size) exceeds --max-file-bytes \(maxFileBytes)")
        }

        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()

        return FilesystemChecksumResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            file: record,
            algorithm: normalizedAlgorithm,
            digest: digest,
            maxFileBytes: maxFileBytes
        )
    }

    private func compareFiles(
        leftURL: URL,
        rightURL: URL,
        algorithm: String,
        maxFileBytes: Int
    ) throws -> FilesystemCompareResult {
        let leftChecksum = try fileChecksum(for: leftURL, algorithm: algorithm, maxFileBytes: maxFileBytes)
        let rightChecksum = try fileChecksum(for: rightURL, algorithm: algorithm, maxFileBytes: maxFileBytes)
        let sameSize = leftChecksum.file.sizeBytes == rightChecksum.file.sizeBytes
        let sameDigest = leftChecksum.digest == rightChecksum.digest

        return FilesystemCompareResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            left: leftChecksum.file,
            right: rightChecksum.file,
            algorithm: leftChecksum.algorithm,
            leftDigest: leftChecksum.digest,
            rightDigest: rightChecksum.digest,
            sameSize: sameSize,
            sameDigest: sameDigest,
            matched: sameSize && sameDigest,
            maxFileBytes: maxFileBytes
        )
    }

    private func targetPasteboard() -> NSPasteboard {
        guard let name = option("--pasteboard"), name != "general" else {
            return .general
        }
        return NSPasteboard(name: NSPasteboard.Name(rawValue: name))
    }

    private func clipboardState(for pasteboard: NSPasteboard) -> ClipboardState {
        let string = pasteboard.string(forType: .string)

        return ClipboardState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            pasteboard: pasteboard.name.rawValue,
            changeCount: pasteboard.changeCount,
            types: clipboardTypes(for: pasteboard),
            hasString: string != nil,
            stringLength: string?.count,
            stringDigest: string.map(sha256Digest),
            actions: [
                ClipboardAction(name: "clipboard.state", risk: "low", mutates: false),
                ClipboardAction(name: "clipboard.readText", risk: "medium", mutates: false),
                ClipboardAction(name: "clipboard.writeText", risk: "medium", mutates: true)
            ]
        )
    }

    private func clipboardText(for pasteboard: NSPasteboard, maxCharacters: Int) throws -> ClipboardTextResult {
        let action = "clipboard.readText"
        let risk = clipboardActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let string = pasteboard.string(forType: .string)
        let summary = clipboardAuditSummary(for: pasteboard, string: string)

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "clipboard.read-text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                clipboard: summary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
        }

        guard policy.allowed else {
            let message = policy.message
            try writeAudit(ok: false, code: "policy_denied", message: message)
            throw CommandError(description: message)
        }

        let text: String?
        let truncated: Bool
        if let string, string.count > maxCharacters {
            text = String(string.prefix(maxCharacters))
            truncated = true
        } else {
            text = string
            truncated = false
        }

        let message = string == nil
            ? "Clipboard has no plain text string."
            : truncated
                ? "Read truncated clipboard text from \(pasteboard.name.rawValue)."
                : "Read clipboard text from \(pasteboard.name.rawValue)."
        try writeAudit(ok: true, code: string == nil ? "no_text" : "read_text", message: message)

        return ClipboardTextResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            pasteboard: pasteboard.name.rawValue,
            changeCount: pasteboard.changeCount,
            hasString: string != nil,
            text: text,
            stringLength: string?.count,
            stringDigest: string.map(sha256Digest),
            truncated: truncated,
            maxCharacters: maxCharacters,
            auditID: auditID,
            auditLogPath: auditURL.path,
            message: message
        )
    }

    private func writeClipboardText(_ text: String, to pasteboard: NSPasteboard) throws -> ClipboardWriteResult {
        let action = "clipboard.writeText"
        let risk = clipboardActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let beforeString = pasteboard.string(forType: .string)
        let before = clipboardAuditSummary(for: pasteboard, string: beforeString)
        let writtenDigest = sha256Digest(text)
        var after = before
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "clipboard.write-text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                clipboard: after,
                clipboardBefore: before,
                clipboardAfter: after,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            pasteboard.clearContents()
            guard pasteboard.setString(text, forType: .string) else {
                let message = "failed to write plain text to \(pasteboard.name.rawValue)"
                verification = FileOperationVerification(ok: false, code: "write_failed", message: message)
                after = clipboardAuditSummary(for: pasteboard, string: pasteboard.string(forType: .string))
                try writeAudit(ok: false, code: "write_failed", message: message)
                throw CommandError(description: message)
            }

            let currentString = pasteboard.string(forType: .string)
            after = clipboardAuditSummary(for: pasteboard, string: currentString)
            verification = verifyClipboardText(currentString, expectedLength: text.count, expectedDigest: writtenDigest)
            guard verification?.ok == true else {
                let message = verification?.message ?? "clipboard write verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Wrote plain text to \(pasteboard.name.rawValue)."
            try writeAudit(ok: true, code: "wrote_text", message: message)

            return ClipboardWriteResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                pasteboard: pasteboard.name.rawValue,
                previous: before,
                current: after,
                writtenLength: text.count,
                writtenDigest: writtenDigest,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    private func verifyClipboardText(
        _ currentString: String?,
        expectedLength: Int,
        expectedDigest: String
    ) -> FileOperationVerification {
        guard let currentString else {
            return FileOperationVerification(
                ok: false,
                code: "text_missing",
                message: "clipboard does not contain plain text after write"
            )
        }

        guard currentString.count == expectedLength else {
            return FileOperationVerification(
                ok: false,
                code: "length_mismatch",
                message: "clipboard text length does not match requested text length"
            )
        }

        guard sha256Digest(currentString) == expectedDigest else {
            return FileOperationVerification(
                ok: false,
                code: "digest_mismatch",
                message: "clipboard text digest does not match requested text digest"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "text_matched",
            message: "clipboard contains text with the requested length and digest"
        )
    }

    private func clipboardAuditSummary(for pasteboard: NSPasteboard, string: String?) -> ClipboardAuditSummary {
        ClipboardAuditSummary(
            pasteboard: pasteboard.name.rawValue,
            changeCount: pasteboard.changeCount,
            types: clipboardTypes(for: pasteboard),
            hasString: string != nil,
            stringLength: string?.count,
            stringDigest: string.map(sha256Digest)
        )
    }

    private func clipboardTypes(for pasteboard: NSPasteboard) -> [String] {
        (pasteboard.types ?? []).map(\.rawValue).sorted()
    }

    private func sha256Digest(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func javascriptStringLiteral(_ string: String) throws -> String {
        let data = try JSONEncoder().encode(string)
        guard let literal = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode JavaScript string literal")
        }
        return literal
    }

    private func appendAuditRecord(_ record: ActionAuditRecord, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let lineEncoder = JSONEncoder()
        lineEncoder.outputFormatting = [.sortedKeys]
        let data = try lineEncoder.encode(record)
        guard var line = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode audit record")
        }
        line.append("\n")

        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
        } else {
            try line.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func readAuditRecords(
        from url: URL,
        limit: Int,
        command: String? = nil,
        code: String? = nil
    ) throws -> [ActionAuditRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "audit log is not valid UTF-8")
        }

        let decoder = JSONDecoder()
        let records = try contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { line in
                let data = Data(line.utf8)
                return try decoder.decode(ActionAuditRecord.self, from: data)
            }
            .filter { record in
                if let command, record.command != command {
                    return false
                }
                if let code, record.outcome.code != code {
                    return false
                }
                return true
            }

        return Array(records.suffix(limit))
    }

    private func taskMemoryEvent(
        taskID: String,
        kind: String,
        status: String?,
        title: String?,
        summary: String?,
        relatedAuditID: String?
    ) throws -> TaskMemoryEvent {
        let sensitivity = try taskMemorySensitivity(option("--sensitivity") ?? "private")
        let summaryLength = summary?.count
        let summaryDigest = summary.map(sha256Digest)
        let storedSummary = sensitivity == "sensitive" ? nil : summary

        return TaskMemoryEvent(
            id: UUID().uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            taskID: taskID,
            kind: kind,
            status: status,
            title: title,
            summary: storedSummary,
            summaryLength: summaryLength,
            summaryDigest: summaryDigest,
            sensitivity: sensitivity,
            relatedAuditID: relatedAuditID
        )
    }

    private func appendTaskMemoryEvent(_ event: TaskMemoryEvent, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let lineEncoder = JSONEncoder()
        lineEncoder.outputFormatting = [.sortedKeys]
        let data = try lineEncoder.encode(event)
        guard var line = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode task memory event")
        }
        line.append("\n")

        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
        } else {
            try line.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func appendWorkflowTranscript(_ plan: WorkflowRunPlan, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let lineEncoder = JSONEncoder()
        lineEncoder.outputFormatting = [.sortedKeys]
        let data = try lineEncoder.encode(plan)
        guard var line = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode workflow transcript")
        }
        line.append("\n")

        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
        } else {
            try line.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func readWorkflowTranscriptEntries(
        from url: URL,
        limit: Int,
        operation: String?
    ) throws -> [JSONValue] {
        try readWorkflowTranscriptDictionaries(
            from: url,
            limit: limit,
            operation: operation
        ).map { try JSONValue(any: $0) }
    }

    private func readWorkflowTranscriptDictionaries(
        from url: URL,
        limit: Int,
        operation: String?
    ) throws -> [[String: Any]] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "workflow transcript log is not valid UTF-8")
        }

        let entries = try contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> [String: Any]? in
                let object = try JSONSerialization.jsonObject(with: Data(line.utf8))
                guard let dictionary = object as? [String: Any] else {
                    throw CommandError(description: "workflow transcript line was not a JSON object")
                }
                if let operation, dictionary["operation"] as? String != operation {
                    return nil
                }
                return dictionary
            }

        return Array(entries.suffix(limit))
    }

    private func readTaskMemoryEvents(from url: URL) throws -> [TaskMemoryEvent] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "task memory log is not valid UTF-8")
        }

        let decoder = JSONDecoder()
        return try contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { line in
                try decoder.decode(TaskMemoryEvent.self, from: Data(line.utf8))
            }
    }

    private func taskMemoryResult(taskID: String, from url: URL, limit: Int) throws -> TaskMemoryResult {
        let events = try readTaskMemoryEvents(from: url).filter { $0.taskID == taskID }
        let started = events.first { $0.kind == "task.started" }
        let latestStatus = events.reversed().first { $0.status != nil }?.status
        let limitedEvents = Array(events.suffix(max(0, limit)))

        return TaskMemoryResult(
            path: url.path,
            taskID: taskID,
            status: latestStatus,
            title: started?.title,
            startedAt: started?.timestamp,
            updatedAt: events.last?.timestamp,
            eventCount: events.count,
            limit: max(0, limit),
            events: limitedEvents
        )
    }

    private func requireTaskExists(taskID: String, in url: URL) throws {
        let exists = try readTaskMemoryEvents(from: url).contains {
            $0.taskID == taskID && $0.kind == "task.started"
        }
        guard exists else {
            throw CommandError(description: "no task memory found with id \(taskID)")
        }
    }

    private func taskMemoryKind(_ rawKind: String) throws -> String {
        switch rawKind {
        case "observation", "decision", "action", "verification", "note":
            return "task.\(rawKind)"
        case "task.observation", "task.decision", "task.action", "task.verification", "task.note":
            return rawKind
        default:
            throw CommandError(description: "unsupported task memory kind '\(rawKind)'. Use observation, decision, action, verification, or note.")
        }
    }

    private func taskFinishStatus(_ status: String) throws -> String {
        switch status {
        case "completed", "blocked", "cancelled":
            return status
        default:
            throw CommandError(description: "unsupported task status '\(status)'. Use completed, blocked, or cancelled.")
        }
    }

    private func taskMemorySensitivity(_ sensitivity: String) throws -> String {
        switch sensitivity {
        case "public", "private", "sensitive":
            return sensitivity
        default:
            throw CommandError(description: "unsupported task memory sensitivity '\(sensitivity)'. Use public, private, or sensitive.")
        }
    }

    private func auditLogURL() throws -> URL {
        if let path = option("--audit-log") {
            return URL(fileURLWithPath: expandedPath(path))
        }

        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CommandError(description: "could not resolve Application Support directory")
        }

        return applicationSupport.appendingPathComponent("03/audit-log.jsonl")
    }

    private func taskMemoryURL() throws -> URL {
        if let path = option("--memory-log") {
            return URL(fileURLWithPath: expandedPath(path))
        }

        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CommandError(description: "could not resolve Application Support directory")
        }

        return applicationSupport.appendingPathComponent("03/task-memory.jsonl")
    }

    private func workflowLogURL() throws -> URL {
        if let path = option("--workflow-log") {
            return URL(fileURLWithPath: expandedPath(path))
        }

        guard let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw CommandError(description: "could not resolve Application Support directory")
        }

        return applicationSupport.appendingPathComponent("03/workflow-runs.jsonl")
    }

    private func expandedPath(_ path: String) -> String {
        guard path == "~" || path.hasPrefix("~/") else {
            return path
        }

        let suffix = path.dropFirst(path == "~" ? 1 : 2)
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(String(suffix))
            .path
    }

    private func riskLevel(for action: String) -> String {
        switch action {
        case kAXPressAction, kAXShowMenuAction:
            return "low"
        case kAXConfirmAction, kAXPickAction:
            return "medium"
        default:
            return "unknown"
        }
    }

    private func fileActionRisk(for action: String) -> String {
        switch action {
        case "filesystem.stat", "filesystem.list", "filesystem.search", "filesystem.wait", "filesystem.watch", "filesystem.checksum", "filesystem.compare", "filesystem.plan":
            return "low"
        case "filesystem.duplicate", "filesystem.move", "filesystem.createDirectory", "filesystem.rollbackMove":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func clipboardActionRisk(for action: String) -> String {
        switch action {
        case "clipboard.state":
            return "low"
        case "clipboard.readText", "clipboard.writeText":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func browserActionRisk(for action: String) -> String {
        switch action {
        case "browser.listTabs", "browser.inspectTab":
            return "low"
        case "browser.readText", "browser.readDOM", "browser.fillFormField", "browser.navigate":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func desktopActionRisk(for action: String) -> String {
        switch action {
        case "desktop.listWindows":
            return "low"
        default:
            return "unknown"
        }
    }

    private func taskMemoryActionRisk(for action: String) -> String {
        switch action {
        case "task.memoryStart", "task.memoryRecord", "task.memoryFinish", "task.memoryShow":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func workflowActionRisk(for action: String) -> String {
        switch action {
        case "workflow.logRead":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func requirePolicyAllowed(action: String) throws {
        let risk: String
        if action.hasPrefix("task.") {
            risk = taskMemoryActionRisk(for: action)
        } else if action.hasPrefix("workflow.") {
            risk = workflowActionRisk(for: action)
        } else {
            risk = "unknown"
        }
        let policy = policyDecision(actionRisk: risk)
        guard policy.allowed else {
            throw CommandError(description: policy.message)
        }
    }

    private func knownPolicyActions() -> [PolicyActionRecord] {
        [
            PolicyActionRecord(name: kAXPressAction as String, domain: "accessibility", risk: "low", mutates: true),
            PolicyActionRecord(name: kAXShowMenuAction as String, domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: kAXConfirmAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: kAXPickAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: "desktop.listWindows", domain: "desktop", risk: desktopActionRisk(for: "desktop.listWindows"), mutates: false),
            PolicyActionRecord(name: "filesystem.stat", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.list", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.search", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.wait", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.watch", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.checksum", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.compare", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.plan", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.duplicate", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.move", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.createDirectory", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.rollbackMove", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "clipboard.state", domain: "clipboard", risk: "low", mutates: false),
            PolicyActionRecord(name: "clipboard.readText", domain: "clipboard", risk: "medium", mutates: false),
            PolicyActionRecord(name: "clipboard.writeText", domain: "clipboard", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.listTabs", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.inspectTab", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.readText", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readDOM", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.fillFormField", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.navigate", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryStart", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryRecord", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryFinish", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryShow", domain: "task", risk: "medium", mutates: false),
            PolicyActionRecord(name: "workflow.logRead", domain: "workflow", risk: "medium", mutates: false)
        ]
    }

    private func policyDecision(actionRisk: String) -> AuditPolicyDecision {
        let allowedRisk = option("--allow-risk") ?? "low"
        guard let allowedRank = riskRank(allowedRisk) else {
            return AuditPolicyDecision(
                allowedRisk: allowedRisk,
                actionRisk: actionRisk,
                allowed: false,
                message: "invalid --allow-risk '\(allowedRisk)'. Use low, medium, high, or unknown."
            )
        }

        let actionRank = riskRank(actionRisk) ?? riskRank("unknown")!
        let allowed = actionRank <= allowedRank
        let message = allowed
            ? "policy allowed \(actionRisk) action with --allow-risk \(allowedRisk)"
            : "policy denied \(actionRisk) action because --allow-risk is \(allowedRisk)"

        return AuditPolicyDecision(
            allowedRisk: allowedRisk,
            actionRisk: actionRisk,
            allowed: allowed,
            message: message
        )
    }

    private func riskRank(_ risk: String) -> Int? {
        switch risk {
        case "low":
            return 0
        case "medium":
            return 1
        case "high":
            return 2
        case "unknown":
            return 3
        default:
            return nil
        }
    }

    private func identityConfidenceRank(_ confidence: String) -> Int? {
        switch confidence {
        case "low":
            return 0
        case "medium":
            return 1
        case "high":
            return 2
        default:
            return nil
        }
    }

    private func schema() {
        print("""
        {
          "policy": {
            "command": "03 policy",
            "defaultAllowedRisk": "low",
            "riskLevels": ["low", "medium", "high", "unknown"],
            "actions": [
              { "name": "filesystem.move", "domain": "filesystem", "risk": "medium", "mutates": true }
            ]
          },
          "doctor": {
            "command": "03 doctor --timeout-ms 1000",
            "result": {
              "status": "ready|degraded|blocked",
              "ready": true,
              "checks": [
                {
                  "name": "accessibility",
                  "status": "pass",
                  "required": true,
                  "message": "Accessibility permission is enabled.",
                  "remediation": null
                },
                {
                  "name": "browser.devTools",
                  "status": "warn",
                  "required": false,
                  "message": "Browser DevTools endpoint is not reachable.",
                  "remediation": "Start Chromium with --remote-debugging-port=9222."
                }
              ]
            }
          },
          "workflowPreflight": {
            "command": "03 workflow preflight --operation inspect-active-app",
            "result": {
              "operation": "inspect-active-app",
              "risk": "low",
              "mutates": false,
              "canProceed": true,
              "prerequisites": [
                {
                  "name": "accessibility",
                  "status": "pass",
                  "required": true,
                  "message": "Accessibility permission is enabled."
                }
              ],
              "blockers": [],
              "nextCommand": "03 state --pid 123 --depth 3 --max-children 80",
              "nextArguments": ["03", "state", "--pid", "123", "--depth", "3", "--max-children", "80"],
              "message": "inspect-active-app can proceed with the suggested command."
            }
          },
          "workflowNext": {
            "command": "03 workflow next --operation move-file --path ~/Desktop/a.txt --to ~/Desktop/b.txt --allow-risk medium",
            "result": {
              "operation": "move-file",
              "ready": true,
              "risk": "medium",
              "mutates": true,
              "blockers": [],
              "command": {
                "display": "03 files move --path ~/Desktop/a.txt --to ~/Desktop/b.txt --allow-risk medium --reason 'Describe intent'",
                "argv": ["03", "files", "move", "--path", "~/Desktop/a.txt", "--to", "~/Desktop/b.txt", "--allow-risk", "medium", "--reason", "Describe intent"],
                "risk": "medium",
                "mutates": true,
                "requiresReason": true
              }
            }
          },
          "workflowRun": {
            "command": "03 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --dry-run false",
            "result": {
              "transcriptID": "UUID",
              "transcriptPath": "~/Library/Application Support/03/workflow-runs.jsonl",
              "operation": "read-browser",
              "mode": "execute",
              "dryRun": false,
              "ready": true,
              "wouldExecute": true,
              "executed": true,
              "risk": "medium",
              "mutates": false,
              "blockers": [],
              "command": {
                "display": "03 browser tabs --endpoint http://127.0.0.1:9222",
                "argv": ["03", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
                "risk": "medium",
                "mutates": false,
                "requiresReason": false
              },
              "execution": {
                "argv": ["03", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
                "exitCode": 0,
                "timeoutMilliseconds": 10000,
                "timedOut": false,
                "maxOutputBytes": 1048576,
                "stdout": "{...}",
                "stdoutBytes": 128,
                "stdoutTruncated": false,
                "stderr": "",
                "stderrBytes": 0,
                "stderrTruncated": false,
                "outputJSON": {
                  "count": 1,
                  "tabs": []
                }
              },
              "message": "Workflow executed a non-mutating command and captured its output."
            }
          },
          "workflowLog": {
            "command": "03 workflow log --allow-risk medium --limit 20",
            "result": {
              "path": "~/Library/Application Support/03/workflow-runs.jsonl",
              "operation": null,
              "limit": 20,
              "count": 1,
              "entries": [
                {
                  "transcriptID": "UUID",
                  "operation": "read-browser",
                  "executed": true,
                  "blockers": []
                }
              ]
            }
          },
          "workflowResume": {
            "command": "03 workflow resume --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/03/workflow-runs.jsonl",
              "operation": null,
              "status": "completed|blocked|timed_out|failed|ready|empty",
              "transcriptID": "UUID",
              "latestOperation": "read-browser",
              "blockers": [],
              "nextCommand": "03 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/03/workflow-runs.jsonl'",
              "nextArguments": ["03", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/03/workflow-runs.jsonl"],
              "message": "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
            }
          },
          "workflowWaitFile": {
            "command": "03 workflow run --operation wait-file --path ~/Downloads/report.pdf --exists true --wait-timeout-ms 5000 --dry-run false --run-timeout-ms 1000",
            "result": {
              "operation": "wait-file",
              "risk": "low",
              "mutates": false,
              "command": {
                "argv": ["03", "files", "wait", "--path", "~/Downloads/report.pdf", "--exists", "true", "--timeout-ms", "5000", "--interval-ms", "100"]
              },
              "execution": {
                "timedOut": true,
                "timeoutMilliseconds": 1000,
                "stdoutTruncated": false,
                "stderrTruncated": false
              }
            }
          },
          "observe": {
            "command": "03 observe --app-limit 20 --window-limit 20",
            "result": {
              "accessibility": {
                "trusted": true,
                "message": "Accessibility access is enabled."
              },
              "activeApp": { "name": "Terminal", "bundleIdentifier": "com.apple.Terminal", "pid": 123, "active": true },
              "appCount": 3,
              "appsTruncated": false,
              "desktop": {
                "available": true,
                "count": 2,
                "windows": [
                  { "id": "window:456", "stableIdentity": { "id": "desktopWindow:stable-semantic-digest" } }
                ]
              },
              "blockers": [],
              "suggestedActions": [
                {
                  "name": "accessibility.inspectState",
                  "command": "03 state --pid 123 --depth 3 --max-children 80",
                  "risk": "low",
                  "mutates": false,
                  "reason": "Inspect the active app's UI tree with stable element identities."
                }
              ]
            }
          },
          "state": {
            "generatedAt": "ISO-8601 timestamp",
            "platform": "macOS",
            "app": {
              "name": "frontmost or requested app name",
              "bundleIdentifier": "com.example.App",
              "pid": 123
            },
            "windows": [
              {
                "id": "w0.3.1",
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "high",
                  "label": "Save AXButton in com.example.App",
                  "components": {
                    "owner": "com.example.app",
                    "role": "AXButton",
                    "title": "save"
                  },
                  "reasons": ["owner bundle identifier or name", "role", "title"]
                },
                "role": "AXButton",
                "subrole": null,
                "title": "Save",
                "value": null,
                "help": null,
                "enabled": true,
                "frame": { "x": 10, "y": 20, "width": 80, "height": 32 },
                "actions": ["AXPress"],
                "children": []
              }
            ]
          },
          "stateAll": {
            "generatedAt": "ISO-8601 timestamp",
            "platform": "macOS",
            "apps": [
              {
                "app": { "name": "Finder", "bundleIdentifier": "com.apple.finder", "pid": 456 },
                "windows": [
                  {
                    "id": "a0.w0.3.1",
                    "stableIdentity": {
                      "id": "accessibilityElement:stable-semantic-digest",
                      "kind": "accessibilityElement",
                      "confidence": "high",
                      "label": "Save AXButton in Finder",
                      "components": {
                        "owner": "com.apple.finder",
                        "role": "AXButton",
                        "title": "save"
                      },
                      "reasons": ["owner bundle identifier or name", "role", "title"]
                    },
                    "role": "AXButton",
                    "actions": ["AXPress"],
                    "children": []
                  }
                ]
              }
            ]
          },
          "desktopWindows": {
            "command": "03 desktop windows --limit 50",
            "result": {
              "available": true,
              "message": "Read visible desktop window metadata.",
              "activePID": 123,
              "includeDesktop": false,
              "includeAllLayers": false,
              "count": 1,
              "windows": [
                {
                  "id": "window:456",
                  "stableIdentity": {
                    "id": "desktopWindow:stable-semantic-digest",
                    "kind": "desktopWindow",
                    "confidence": "high",
                    "label": "Documents window in Finder",
                    "components": {
                      "owner": "com.apple.finder",
                      "title": "documents",
                      "layer": "0"
                    },
                    "reasons": ["owner bundle identifier or name", "window title"]
                  },
                  "windowNumber": 456,
                  "ownerName": "Finder",
                  "ownerBundleIdentifier": "com.apple.finder",
                  "ownerPID": 123,
                  "active": true,
                  "title": "Documents",
                  "layer": 0,
                  "bounds": { "x": 0, "y": 25, "width": 900, "height": 700 },
                  "onscreen": true
                }
              ]
            }
          },
          "perform": {
            "command": "03 perform --pid 456 --element a0.w0.3.1 --expect-identity accessibilityElement:stable-semantic-digest --min-identity-confidence medium --action AXPress --allow-risk low --reason 'Open details'",
            "result": {
              "ok": true,
              "stableIdentity": {
                "id": "accessibilityElement:stable-semantic-digest",
                "kind": "accessibilityElement",
                "confidence": "high"
              },
              "identityVerification": {
                "ok": true,
                "code": "identity_verified",
                "expectedID": "accessibilityElement:stable-semantic-digest",
                "actualID": "accessibilityElement:stable-semantic-digest",
                "minimumConfidence": "medium",
                "actualConfidence": "high"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "audit": {
            "command": "03 audit --command files.move --code moved --limit 20",
            "entry": {
              "id": "UUID",
              "timestamp": "ISO-8601 timestamp",
              "command": "perform",
              "risk": "low|medium|high|unknown",
              "reason": "caller supplied intent",
              "app": { "name": "Finder", "bundleIdentifier": "com.apple.finder", "pid": 456 },
              "elementID": "w0.3.1",
              "element": {
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "high"
                },
                "role": "AXButton",
                "title": "Save",
                "enabled": true,
                "actions": ["AXPress"]
              },
              "action": "AXPress",
              "policy": {
                "allowedRisk": "low",
                "actionRisk": "low",
                "allowed": true,
                "message": "policy allowed low action with --allow-risk low"
              },
              "identityVerification": {
                "ok": true,
                "code": "identity_verified",
                "expectedID": "accessibilityElement:stable-semantic-digest",
                "actualID": "accessibilityElement:stable-semantic-digest",
                "minimumConfidence": "medium",
                "actualConfidence": "high"
              },
              "outcome": { "ok": true, "code": "performed", "message": "Performed AXPress on w0.3.1." }
            }
          },
          "taskMemory": {
            "command": "03 task record --task-id UUID --kind verification --summary 'download matched expected digest' --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/03/task-memory.jsonl",
              "taskID": "UUID",
              "status": "active|completed|blocked|cancelled",
              "title": "Verify downloaded report",
              "eventCount": 2,
              "events": [
                {
                  "kind": "task.verification",
                  "summary": "download matched expected digest",
                  "summaryLength": 31,
                  "summaryDigest": "hex encoded SHA-256 digest",
                  "sensitivity": "private",
                  "relatedAuditID": "UUID"
                }
              ]
            }
          },
          "clipboardState": {
            "command": "03 clipboard state",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "types": ["public.utf8-plain-text"],
              "hasString": true,
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "actions": [
                { "name": "clipboard.state", "risk": "low", "mutates": false },
                { "name": "clipboard.readText", "risk": "medium", "mutates": false },
                { "name": "clipboard.writeText", "risk": "medium", "mutates": true }
              ]
            }
          },
          "clipboardText": {
            "command": "03 clipboard read-text --allow-risk medium --max-characters 4096 --reason 'Use copied value'",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "hasString": true,
              "text": "bounded clipboard text",
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "truncated": false,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "clipboardWrite": {
            "command": "03 clipboard write-text --allow-risk medium --text 'bounded clipboard text' --reason 'Prepare value for paste'",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "previous": {
                "changeCount": 12,
                "stringLength": 42,
                "stringDigest": "previous hex encoded SHA-256 digest"
              },
              "current": {
                "changeCount": 14,
                "stringLength": 22,
                "stringDigest": "new hex encoded SHA-256 digest"
              },
              "writtenLength": 22,
              "writtenDigest": "new hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "text_matched",
                "message": "clipboard contains text with the requested length and digest"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "browserTabs": {
            "command": "03 browser tabs --endpoint http://127.0.0.1:9222",
            "result": {
              "endpoint": "http://127.0.0.1:9222",
              "includeNonPageTargets": false,
              "count": 1,
              "tabs": [
                {
                  "id": "devtools-target-id",
                  "type": "page",
                  "title": "Page title",
                  "url": "https://example.com",
                  "webSocketDebuggerURL": "ws://127.0.0.1:9222/devtools/page/devtools-target-id",
                  "actions": [
                    { "name": "browser.inspectTab", "risk": "low", "mutates": false },
                    { "name": "browser.readText", "risk": "medium", "mutates": false },
                    { "name": "browser.readDOM", "risk": "medium", "mutates": false },
                    { "name": "browser.fillFormField", "risk": "medium", "mutates": true },
                    { "name": "browser.navigate", "risk": "medium", "mutates": true }
                  ]
                }
              ]
            }
          },
          "browserTab": {
            "command": "03 browser tab --endpoint http://127.0.0.1:9222 --id devtools-target-id",
            "result": {
              "tab": {
                "id": "devtools-target-id",
                "title": "Page title",
                "url": "https://example.com"
              }
            }
          },
          "browserDOM": {
            "command": "03 browser dom --endpoint http://127.0.0.1:9222 --id devtools-target-id --allow-risk medium --max-elements 200 --max-text-characters 120",
            "result": {
              "action": "browser.readDOM",
              "risk": "medium",
              "elementCount": 2,
              "truncated": false,
              "elements": [
                {
                  "id": "dom.0",
                  "parentID": null,
                  "depth": 0,
                  "tagName": "body",
                  "role": null,
                  "text": "Visible page text",
                  "textLength": 17,
                  "attributes": {},
                  "inputType": null,
                  "checked": null,
                  "disabled": null,
                  "hasValue": null,
                  "valueLength": null
                },
                {
                  "id": "dom.1",
                  "parentID": "dom.0",
                  "depth": 1,
                  "tagName": "input",
                  "role": "textbox",
                  "text": null,
                  "textLength": 0,
                  "attributes": { "name": "q", "placeholder": "Search" },
                  "inputType": "search",
                  "checked": false,
                  "disabled": false,
                  "hasValue": true,
                  "valueLength": 6
                }
              ]
            }
          },
          "browserFill": {
            "command": "03 browser fill --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --text 'bounded text' --allow-risk medium",
            "result": {
              "action": "browser.fillFormField",
              "risk": "medium",
              "selector": "input[name=q]",
              "textLength": 12,
              "textDigest": "hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "value_matched",
                "message": "browser form field contains text with the requested length"
              },
              "targetTagName": "input",
              "targetInputType": "text",
              "resultingValueLength": 12,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "browserNavigate": {
            "command": "03 browser navigate --endpoint http://127.0.0.1:9222 --id devtools-target-id --url https://example.com/next --allow-risk medium",
            "result": {
              "action": "browser.navigate",
              "risk": "medium",
              "requestedURL": "https://example.com/next",
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "verification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "files": {
            "command": "03 files list --path ~/Documents --depth 2 --limit 200",
            "entry": {
              "id": "file:stable-resource-identifier",
              "path": "/Users/example/Documents/Plan.md",
              "name": "Plan.md",
              "kind": "regularFile|directory|symbolicLink|other",
              "sizeBytes": 1234,
              "createdAt": "ISO-8601 timestamp",
              "modifiedAt": "ISO-8601 timestamp",
              "hidden": false,
              "readable": true,
              "writable": true,
              "actions": [
                { "name": "filesystem.stat", "risk": "low", "mutates": false }
              ]
            }
          },
          "fileSearch": {
            "command": "03 files search --path ~/Documents --query invoice --depth 4 --limit 50",
            "maxMatchesPerFile": 20,
            "match": {
              "file": {
                "path": "/Users/example/Documents/Invoice.txt",
                "kind": "regularFile",
                "actions": [
                  { "name": "filesystem.stat", "risk": "low", "mutates": false },
                  { "name": "filesystem.search", "risk": "low", "mutates": false }
                ]
              },
              "matchedName": true,
              "contentMatches": [
                { "lineNumber": 4, "text": "bounded matching line snippet" }
              ]
            }
          },
          "fileWait": {
            "command": "03 files wait --path ~/Downloads/report.pdf --exists true --timeout-ms 5000 --interval-ms 100",
            "result": {
              "path": "/Users/example/Downloads/report.pdf",
              "expectedExists": true,
              "matched": true,
              "elapsedMilliseconds": 100,
              "file": { "path": "/Users/example/Downloads/report.pdf", "kind": "regularFile" },
              "message": "Path exists at /Users/example/Downloads/report.pdf."
            }
          },
          "fileWatch": {
            "command": "03 files watch --path ~/Downloads --depth 1 --timeout-ms 30000 --interval-ms 250",
            "result": {
              "root": { "path": "/Users/example/Downloads", "kind": "directory" },
              "matched": true,
              "events": [
                {
                  "id": "fileEvent:hex encoded SHA-256 digest",
                  "type": "created",
                  "path": "/Users/example/Downloads/report.pdf",
                  "previous": null,
                  "current": { "path": "/Users/example/Downloads/report.pdf", "kind": "regularFile" }
                }
              ],
              "eventCount": 1,
              "beforeCount": 4,
              "afterCount": 5
            }
          },
          "fileChecksum": {
            "command": "03 files checksum --path ~/Documents/Plan.md --algorithm sha256 --max-file-bytes 104857600",
            "result": {
              "file": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "algorithm": "sha256",
              "digest": "hex encoded SHA-256 digest",
              "maxFileBytes": 104857600
            }
          },
          "fileCompare": {
            "command": "03 files compare --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --algorithm sha256 --max-file-bytes 104857600",
            "result": {
              "left": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "right": { "path": "/Users/example/Documents/Plan copy.md", "kind": "regularFile" },
              "algorithm": "sha256",
              "sameSize": true,
              "sameDigest": true,
              "matched": true
            }
          },
          "filePlan": {
            "command": "03 files plan --operation move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium",
            "result": {
              "operation": "move",
              "action": "filesystem.move",
              "risk": "medium",
              "actionMutates": true,
              "policy": {
                "allowedRisk": "medium",
                "actionRisk": "medium",
                "allowed": true
              },
              "source": { "path": "/Users/example/Documents/Draft.md", "exists": true },
              "destination": { "path": "/Users/example/Documents/Archive/Draft.md", "exists": false },
              "checks": [
                { "name": "destinationMissing", "ok": true, "code": "missing" }
              ],
              "canExecute": true,
              "requiredAllowRisk": "medium"
            }
          },
          "fileDuplicate": {
            "command": "03 files duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --allow-risk medium --reason 'Preserve original before editing'",
            "result": {
              "ok": true,
              "action": "filesystem.duplicate",
              "risk": "medium",
              "source": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "destination": { "path": "/Users/example/Documents/Plan copy.md", "kind": "regularFile" },
              "verification": {
                "ok": true,
                "code": "metadata_matched",
                "message": "destination exists and size matches source"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "fileMove": {
            "command": "03 files move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium --reason 'Organize completed draft'",
            "result": {
              "ok": true,
              "action": "filesystem.move",
              "risk": "medium",
              "source": { "path": "/Users/example/Documents/Draft.md", "kind": "regularFile" },
              "destination": { "path": "/Users/example/Documents/Archive/Draft.md", "kind": "regularFile" },
              "verification": {
                "ok": true,
                "code": "moved_and_metadata_matched",
                "message": "source path is gone, destination exists, and size matches original source"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "directoryCreate": {
            "command": "03 files mkdir --path ~/Documents/Archive --allow-risk medium --reason 'Create archive folder'",
            "result": {
              "ok": true,
              "action": "filesystem.createDirectory",
              "risk": "medium",
              "directory": { "path": "/Users/example/Documents/Archive", "kind": "directory" },
              "verification": {
                "ok": true,
                "code": "directory_exists",
                "message": "directory exists at requested path"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          },
          "fileRollback": {
            "command": "03 files rollback --audit-id UUID --allow-risk medium --reason 'Undo mistaken move'",
            "result": {
              "ok": true,
              "action": "filesystem.rollbackMove",
              "risk": "medium",
              "rollbackOfAuditID": "UUID",
              "restoredSource": { "path": "/Users/example/Documents/Draft.md", "kind": "regularFile" },
              "previousDestination": { "path": "/Users/example/Documents/Archive/Draft.md", "exists": false },
              "verification": {
                "ok": true,
                "code": "move_restored",
                "message": "original source path is restored and moved destination is gone"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/03/audit-log.jsonl"
            }
          }
        }
        """)
    }

    private func printHelp() {
        print("""
        03: macOS semantic computer substrate prototype

        Usage:
          03 trust [--prompt true|false]
          03 doctor [--timeout-ms N] [--endpoint URL_OR_PATH] [--audit-log PATH] [--pasteboard NAME]
          03 policy
          03 observe [--app-limit N] [--window-limit N] [--all] [--include-desktop] [--all-layers]
          03 workflow preflight --operation inspect-active-app|control-active-app|read-browser|move-file|wait-file [--path PATH] [--to PATH] [--element ID] [--expect-identity ID]
          03 workflow next --operation inspect-active-app|control-active-app|read-browser|move-file|wait-file [--path PATH] [--to PATH] [--element ID] [--expect-identity ID]
          03 workflow run --operation inspect-active-app|read-browser|wait-file --dry-run false [--endpoint URL_OR_PATH] [--id TARGET_ID] [--path PATH] [--exists true|false] [--run-timeout-ms N] [--max-output-bytes N]
          03 workflow run --operation inspect-active-app|control-active-app|read-browser|move-file|wait-file --dry-run true [--path PATH] [--to PATH] [--element ID] [--expect-identity ID] [--run-timeout-ms N] [--max-output-bytes N]
          03 workflow log --allow-risk medium [--workflow-log PATH] [--operation NAME] [--limit N]
          03 workflow resume --allow-risk medium [--workflow-log PATH] [--operation NAME]
          03 apps [--all]
          03 desktop windows [--limit N] [--include-desktop] [--all-layers]
          03 state [--pid PID] [--all] [--include-background] [--depth N] [--max-children N]
          03 perform [--pid PID] --element w0.1.2|a0.w0.1.2 [--action AXPress] [--allow-risk low|medium|high|unknown] [--reason TEXT] [--audit-log PATH]
          03 audit [--limit N] [--command NAME] [--code OUTCOME_CODE] [--audit-log PATH]
          03 task start --title TEXT [--summary TEXT] --allow-risk medium [--sensitivity public|private|sensitive] [--task-id ID] [--memory-log PATH]
          03 task record --task-id ID --kind observation|decision|action|verification|note --summary TEXT --allow-risk medium [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          03 task finish --task-id ID [--status completed|blocked|cancelled] --allow-risk medium [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          03 task show --task-id ID --allow-risk medium [--limit N] [--memory-log PATH]
          03 files stat --path PATH
          03 files list --path PATH [--depth N] [--limit N] [--include-hidden]
          03 files search --path PATH --query TEXT [--depth N] [--limit N] [--include-hidden] [--case-sensitive] [--max-file-bytes N] [--max-snippet-characters N] [--max-matches-per-file N]
          03 files wait --path PATH [--exists true|false] [--timeout-ms N] [--interval-ms N]
          03 files watch --path PATH [--depth N] [--limit N] [--include-hidden] [--timeout-ms N] [--interval-ms N]
          03 files checksum --path PATH [--algorithm sha256] [--max-file-bytes N]
          03 files compare --path LEFT --to RIGHT [--algorithm sha256] [--max-file-bytes N]
          03 files plan --operation duplicate|move --path SOURCE --to DESTINATION [--allow-risk low|medium|high|unknown]
          03 files plan --operation mkdir --path PATH [--allow-risk low|medium|high|unknown]
          03 files plan --operation rollback --audit-id AUDIT_ID [--allow-risk low|medium|high|unknown] [--audit-log PATH]
          03 files duplicate --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 files move --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 files mkdir --path PATH --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 files rollback --audit-id AUDIT_ID --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 clipboard state [--pasteboard NAME]
          03 clipboard read-text --allow-risk medium [--max-characters N] [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          03 clipboard write-text --text TEXT --allow-risk medium [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          03 browser tabs [--endpoint URL_OR_PATH] [--include-non-page]
          03 browser tab --id TARGET_ID [--endpoint URL_OR_PATH] [--include-non-page]
          03 browser text --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          03 browser dom --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-elements N] [--max-text-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          03 browser fill --id TARGET_ID --selector CSS_SELECTOR --text TEXT --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          03 browser navigate --id TARGET_ID --url URL --allow-risk medium [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          03 schema

        Notes:
          - Run `03 trust` before Accessibility-backed `state` or `perform` commands.
          - `policy` describes known action risk levels and mutation behavior.
          - `desktop windows` lists visible desktop windows from macOS window metadata without requiring screenshots.
          - `state` emits structured JSON from macOS Accessibility APIs.
          - `state --all` walks every running GUI app macOS exposes to this process.
          - Element IDs are child-index paths. Use IDs from `state` with `perform`.
          - `perform` defaults to `--allow-risk low`; medium, high, and unknown actions require explicit allowance.
          - `perform` appends a structured JSONL audit record before returning success or failure.
          - `audit` can filter records by command name and outcome code before applying the limit.
          - `task` stores and reads task-scoped memory as medium-risk local persistence with sensitive-summary redaction.
          - `files` emits read-only filesystem metadata, bounded search evidence, and available typed file actions.
          - `files wait` waits for a path to exist or disappear and returns typed evidence.
          - `files watch` waits for created, deleted, or modified file metadata events under a path and returns normalized event records.
          - `files checksum` returns a bounded SHA-256 digest for a regular file without exposing file contents.
          - `files compare` compares two regular files by bounded SHA-256 digest and size.
          - `files plan` previews mutating file operations with policy, target metadata, and preflight checks without changing files.
          - `files duplicate` copies one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files move` moves one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files mkdir` creates one directory, refuses existing paths, verifies the result, and writes an audit record.
          - `files rollback` restores a successful audited file move after validating current filesystem metadata.
          - `clipboard state` reports pasteboard metadata and text digest without returning clipboard text.
          - `clipboard read-text` returns bounded text only after medium-risk policy approval and audits metadata without storing text.
          - `clipboard write-text` writes plain text only after medium-risk policy approval, verifies by length and digest, and audits metadata without storing text.
          - `browser tabs` reads Chrome DevTools target metadata from an explicit endpoint and returns structured tab records.
          - `browser tab` inspects one DevTools target by id from the same structured browser source.
          - `browser text` reads page text through Chrome DevTools only after medium-risk policy approval and audits length/digest without storing text.
          - `browser dom` reads bounded structured page state through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing the DOM payload.
          - `browser fill` writes one form field through Chrome DevTools only after medium-risk policy approval, verifies by length, and audits selector plus text length/digest without storing text.
          - `browser navigate` navigates one tab through Chrome DevTools only after medium-risk policy approval, verifies the resulting URL from structured tab metadata, and audits the requested/current URLs.
        """)
    }

    private func filesystemState(rootURL: URL, maxDepth: Int, limit: Int, includeHidden: Bool) throws -> FilesystemState {
        let root = try fileRecord(for: rootURL)
        guard root.kind == "directory" else {
            throw CommandError(description: "\(rootURL.path) is not a directory")
        }

        var entries: [FileRecord] = []
        var truncated = false
        try collectFileRecords(
            from: rootURL,
            currentDepth: 0,
            maxDepth: maxDepth,
            limit: limit,
            includeHidden: includeHidden,
            entries: &entries,
            truncated: &truncated
        )

        return FilesystemState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            root: root,
            entries: entries,
            maxDepth: maxDepth,
            limit: limit,
            truncated: truncated
        )
    }

    private func filesystemSearchResult(
        rootURL: URL,
        query: String,
        caseSensitive: Bool,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool,
        maxFileBytes: Int,
        maxSnippetCharacters: Int,
        maxMatchesPerFile: Int
    ) throws -> FilesystemSearchResult {
        let root = try fileRecord(for: rootURL)
        var matches: [FileSearchMatch] = []
        var stats = FileSearchStats()
        var truncated = false

        try collectSearchMatches(
            from: rootURL,
            currentDepth: 0,
            maxDepth: maxDepth,
            limit: limit,
            includeHidden: includeHidden,
            query: query,
            caseSensitive: caseSensitive,
            maxFileBytes: maxFileBytes,
            maxSnippetCharacters: maxSnippetCharacters,
            maxMatchesPerFile: maxMatchesPerFile,
            matches: &matches,
            stats: &stats,
            truncated: &truncated
        )

        return FilesystemSearchResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            root: root,
            query: query,
            caseSensitive: caseSensitive,
            maxDepth: maxDepth,
            limit: limit,
            includeHidden: includeHidden,
            maxFileBytes: maxFileBytes,
            maxSnippetCharacters: maxSnippetCharacters,
            maxMatchesPerFile: maxMatchesPerFile,
            matches: matches,
            scannedFiles: stats.scannedFiles,
            skippedUnreadable: stats.skippedUnreadable,
            skippedBinary: stats.skippedBinary,
            skippedTooLarge: stats.skippedTooLarge,
            truncated: truncated
        )
    }

    private struct FileSearchStats {
        var scannedFiles = 0
        var skippedUnreadable = 0
        var skippedBinary = 0
        var skippedTooLarge = 0
    }

    private func collectSearchMatches(
        from url: URL,
        currentDepth: Int,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool,
        query: String,
        caseSensitive: Bool,
        maxFileBytes: Int,
        maxSnippetCharacters: Int,
        maxMatchesPerFile: Int,
        matches: inout [FileSearchMatch],
        stats: inout FileSearchStats,
        truncated: inout Bool
    ) throws {
        guard !truncated else {
            return
        }

        let record = try fileRecord(for: url)
        if shouldSearch(record, includeHidden: includeHidden) {
            if let match = try searchMatch(
                record: record,
                query: query,
                caseSensitive: caseSensitive,
                maxFileBytes: maxFileBytes,
                maxSnippetCharacters: maxSnippetCharacters,
                maxMatchesPerFile: maxMatchesPerFile,
                stats: &stats
            ) {
                if matches.count >= limit {
                    truncated = true
                    return
                }
                matches.append(match)
            }
        }

        guard record.kind == "directory", currentDepth < maxDepth else {
            return
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(fileResourceKeys()),
            options: includeHidden ? [] : [.skipsHiddenFiles]
        )
        .sorted { $0.path < $1.path }

        for childURL in urls {
            try collectSearchMatches(
                from: childURL,
                currentDepth: currentDepth + 1,
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden,
                query: query,
                caseSensitive: caseSensitive,
                maxFileBytes: maxFileBytes,
                maxSnippetCharacters: maxSnippetCharacters,
                maxMatchesPerFile: maxMatchesPerFile,
                matches: &matches,
                stats: &stats,
                truncated: &truncated
            )

            if truncated {
                return
            }
        }
    }

    private func shouldSearch(_ record: FileRecord, includeHidden: Bool) -> Bool {
        includeHidden || !record.hidden
    }

    private func searchMatch(
        record: FileRecord,
        query: String,
        caseSensitive: Bool,
        maxFileBytes: Int,
        maxSnippetCharacters: Int,
        maxMatchesPerFile: Int,
        stats: inout FileSearchStats
    ) throws -> FileSearchMatch? {
        let matchedName = contains(query, in: record.name, caseSensitive: caseSensitive)
        var lineMatches: [FileLineMatch] = []

        if record.kind == "regularFile" {
            guard record.readable else {
                stats.skippedUnreadable += 1
                return matchedName ? FileSearchMatch(file: record, matchedName: true, contentMatches: []) : nil
            }

            stats.scannedFiles += 1

            if let size = record.sizeBytes, size > maxFileBytes {
                stats.skippedTooLarge += 1
            } else {
                let data = try Data(contentsOf: URL(fileURLWithPath: record.path))
                if let contents = String(data: data, encoding: .utf8) {
                    lineMatches = contentLineMatches(
                        in: contents,
                        query: query,
                        caseSensitive: caseSensitive,
                        maxSnippetCharacters: maxSnippetCharacters,
                        maxMatchesPerFile: maxMatchesPerFile
                    )
                } else {
                    stats.skippedBinary += 1
                }
            }
        }

        guard matchedName || !lineMatches.isEmpty else {
            return nil
        }

        return FileSearchMatch(
            file: record,
            matchedName: matchedName,
            contentMatches: lineMatches
        )
    }

    private func contentLineMatches(
        in contents: String,
        query: String,
        caseSensitive: Bool,
        maxSnippetCharacters: Int,
        maxMatchesPerFile: Int
    ) -> [FileLineMatch] {
        var matches: [FileLineMatch] = []
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            guard matches.count < maxMatchesPerFile else {
                break
            }
            let text = String(line)
            guard contains(query, in: text, caseSensitive: caseSensitive) else {
                continue
            }
            matches.append(FileLineMatch(
                lineNumber: index + 1,
                text: snippet(for: text, query: query, caseSensitive: caseSensitive, maxCharacters: maxSnippetCharacters)
            ))
        }

        return matches
    }

    private func contains(_ needle: String, in haystack: String, caseSensitive: Bool) -> Bool {
        if caseSensitive {
            return haystack.contains(needle)
        }
        return haystack.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    private func snippet(for line: String, query: String, caseSensitive: Bool, maxCharacters: Int) -> String {
        guard line.count > maxCharacters else {
            return line
        }

        let options: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive, .diacriticInsensitive]
        guard let range = line.range(of: query, options: options) else {
            return String(line.prefix(maxCharacters))
        }

        let halfWindow = max(0, (maxCharacters - query.count) / 2)
        let start = line.index(range.lowerBound, offsetBy: -halfWindow, limitedBy: line.startIndex) ?? line.startIndex
        let end = line.index(start, offsetBy: maxCharacters, limitedBy: line.endIndex) ?? line.endIndex
        return String(line[start..<end])
    }

    private func collectFileRecords(
        from directoryURL: URL,
        currentDepth: Int,
        maxDepth: Int,
        limit: Int,
        includeHidden: Bool,
        entries: inout [FileRecord],
        truncated: inout Bool
    ) throws {
        guard currentDepth < maxDepth, !truncated else {
            return
        }

        let keys = fileResourceKeys()
        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: includeHidden ? [] : [.skipsHiddenFiles]
        )
        .sorted { $0.path < $1.path }

        for url in urls {
            if entries.count >= limit {
                truncated = true
                return
            }

            let record = try fileRecord(for: url)
            entries.append(record)

            if record.kind == "directory" {
                try collectFileRecords(
                    from: url,
                    currentDepth: currentDepth + 1,
                    maxDepth: maxDepth,
                    limit: limit,
                    includeHidden: includeHidden,
                    entries: &entries,
                    truncated: &truncated
                )
            }

            if truncated {
                return
            }
        }
    }

    private func fileRecord(for url: URL) throws -> FileRecord {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CommandError(description: "file does not exist at \(url.path)")
        }

        let values = try url.resourceValues(forKeys: fileResourceKeys())
        let kind = fileKind(values)
        let readable = FileManager.default.isReadableFile(atPath: url.path)
        let writable = FileManager.default.isWritableFile(atPath: url.path)

        return FileRecord(
            id: fileID(values: values, url: url),
            path: url.path,
            name: values.name ?? url.lastPathComponent,
            kind: kind,
            sizeBytes: values.fileSize,
            createdAt: values.creationDate.map { ISO8601DateFormatter().string(from: $0) },
            modifiedAt: values.contentModificationDate.map { ISO8601DateFormatter().string(from: $0) },
            hidden: values.isHidden ?? false,
            readable: readable,
            writable: writable,
            actions: fileActions(kind: kind, readable: readable, writable: writable)
        )
    }

    private func fileResourceKeys() -> Set<URLResourceKey> {
        [
            .nameKey,
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey,
            .isHiddenKey,
            .fileResourceIdentifierKey
        ]
    }

    private func fileKind(_ values: URLResourceValues) -> String {
        if values.isSymbolicLink == true {
            return "symbolicLink"
        }
        if values.isDirectory == true {
            return "directory"
        }
        if values.isRegularFile == true {
            return "regularFile"
        }
        return "other"
    }

    private func fileID(values: URLResourceValues, url: URL) -> String {
        if let identifier = values.fileResourceIdentifier {
            if let data = identifier as? Data {
                return "file:\(hexString(data))"
            }
            if let data = identifier as? NSData {
                return "file:\(hexString(data as Data))"
            }
            return "file:\(String(describing: identifier))"
        }
        return "path:\(url.resolvingSymlinksInPath().path)"
    }

    private func hexString(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private func fileActions(kind: String, readable: Bool, writable: Bool) -> [FileAction] {
        var actions = [
            FileAction(name: "filesystem.stat", risk: "low", mutates: false),
            FileAction(name: "filesystem.plan", risk: "low", mutates: false)
        ]

        if kind == "directory", readable {
            actions.append(FileAction(name: "filesystem.list", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.watch", risk: "low", mutates: false))
        }

        if kind == "directory", writable {
            actions.append(FileAction(name: "filesystem.createDirectory", risk: "medium", mutates: true))
        }

        if kind == "regularFile", readable {
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.watch", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.checksum", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.compare", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.duplicate", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.move", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.rollbackMove", risk: "medium", mutates: true))
        }

        return actions
    }

    private func desktopWindows(limitOverride: Int? = nil) throws -> DesktopWindowsState {
        let includeDesktop = flag("--include-desktop")
        let includeAllLayers = flag("--all-layers")
        let limit = limitOverride ?? max(0, option("--limit").flatMap(Int.init) ?? 200)
        let activePID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let bundleIdentifierByPID = Dictionary(
            uniqueKeysWithValues: NSWorkspace.shared.runningApplications.compactMap { app in
                app.bundleIdentifier.map { (app.processIdentifier, $0) }
            }
        )
        var options: CGWindowListOption = [.optionOnScreenOnly]
        if !includeDesktop {
            options.insert(.excludeDesktopElements)
        }

        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return DesktopWindowsState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                available: false,
                message: "Desktop window metadata is unavailable from this process.",
                activePID: activePID,
                includeDesktop: includeDesktop,
                includeAllLayers: includeAllLayers,
                limit: limit,
                count: 0,
                truncated: false,
                windows: []
            )
        }

        let records = rawWindows.compactMap { window -> DesktopWindowRecord? in
            guard let windowNumber = uint32Value(window[kCGWindowNumber as String]),
                  let ownerPID = int32Value(window[kCGWindowOwnerPID as String]) else {
                return nil
            }

            let layer = intValue(window[kCGWindowLayer as String]) ?? 0
            if !includeAllLayers, layer != 0 {
                return nil
            }

            let ownerName = window[kCGWindowOwnerName as String] as? String
            let ownerBundleIdentifier = bundleIdentifierByPID[ownerPID]
            let title = window[kCGWindowName as String] as? String
            let bounds = rectValue(window[kCGWindowBounds as String])

            return DesktopWindowRecord(
                id: "window:\(windowNumber)",
                stableIdentity: desktopWindowStableIdentity(
                    windowNumber: windowNumber,
                    ownerName: ownerName,
                    ownerBundleIdentifier: ownerBundleIdentifier,
                    ownerPID: ownerPID,
                    title: title,
                    layer: layer,
                    bounds: bounds
                ),
                windowNumber: windowNumber,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                ownerPID: ownerPID,
                active: ownerPID == activePID,
                title: title,
                layer: layer,
                bounds: bounds,
                onscreen: boolValue(window[kCGWindowIsOnscreen as String]),
                alpha: doubleValue(window[kCGWindowAlpha as String]),
                memoryUsageBytes: intValue(window[kCGWindowMemoryUsage as String]),
                sharingState: intValue(window[kCGWindowSharingState as String])
            )
        }
        .sorted { left, right in
            if left.active != right.active {
                return left.active && !right.active
            }
            if left.layer != right.layer {
                return left.layer < right.layer
            }
            let leftName = left.ownerName ?? left.ownerBundleIdentifier ?? "\(left.ownerPID)"
            let rightName = right.ownerName ?? right.ownerBundleIdentifier ?? "\(right.ownerPID)"
            if leftName != rightName {
                return leftName < rightName
            }
            return left.windowNumber < right.windowNumber
        }

        let limitedRecords = Array(records.prefix(limit))
        return DesktopWindowsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            available: true,
            message: records.isEmpty
                ? "No matching visible desktop windows were reported."
                : "Read visible desktop window metadata.",
            activePID: activePID,
            includeDesktop: includeDesktop,
            includeAllLayers: includeAllLayers,
            limit: limit,
            count: limitedRecords.count,
            truncated: records.count > limitedRecords.count,
            windows: limitedRecords
        )
    }

    private func uint32Value(_ value: Any?) -> UInt32? {
        if let number = value as? NSNumber {
            return number.uint32Value
        }
        if let value = value as? UInt32 {
            return value
        }
        if let value = value as? Int, value >= 0 {
            return UInt32(value)
        }
        return nil
    }

    private func int32Value(_ value: Any?) -> Int32? {
        if let number = value as? NSNumber {
            return number.int32Value
        }
        if let value = value as? Int32 {
            return value
        }
        if let value = value as? Int {
            return Int32(value)
        }
        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        return value as? Int
    }

    private func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double
    }

    private func boolValue(_ value: Any?) -> Bool? {
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return value as? Bool
    }

    private func rectValue(_ value: Any?) -> Rect? {
        guard let dictionary = value as? NSDictionary,
              let cgRect = CGRect(dictionaryRepresentation: dictionary) else {
            return nil
        }

        return Rect(
            x: Double(cgRect.origin.x),
            y: Double(cgRect.origin.y),
            width: Double(cgRect.width),
            height: Double(cgRect.height)
        )
    }

    private func desktopWindowStableIdentity(
        windowNumber: UInt32,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        ownerPID: Int32,
        title: String?,
        layer: Int,
        bounds: Rect?
    ) -> StableIdentity {
        let normalizedOwnerName = normalizedIdentityText(ownerName)
        let normalizedTitle = normalizedIdentityText(title)
        let owner = ownerBundleIdentifier.flatMap(normalizedIdentityText)
            ?? normalizedOwnerName
            ?? "pid:\(ownerPID)"
        let readableOwner = cleanIdentityText(ownerName)
            ?? ownerBundleIdentifier
            ?? "PID \(ownerPID)"

        var components = [
            "owner": owner,
            "layer": String(layer)
        ]
        var reasons = owner.hasPrefix("pid:")
            ? ["owner process identifier fallback"]
            : ["owner bundle identifier or name"]
        var fingerprintParts = [
            "desktopWindow",
            "owner:\(owner)",
            "layer:\(layer)"
        ]

        if let normalizedTitle {
            components["title"] = normalizedTitle
            reasons.append("window title")
            fingerprintParts.append("title:\(normalizedTitle)")
        } else if let bounds {
            let coarseBounds = coarseBoundsIdentityComponent(bounds)
            components["coarseBounds"] = coarseBounds
            reasons.append("coarse window bounds fallback")
            fingerprintParts.append("bounds:\(coarseBounds)")
        } else {
            components["windowNumberFallback"] = String(windowNumber)
            reasons.append("volatile window number fallback")
            fingerprintParts.append("windowNumber:\(windowNumber)")
        }

        let confidence: String
        if ownerBundleIdentifier != nil, normalizedTitle != nil {
            confidence = "high"
        } else if normalizedOwnerName != nil, normalizedTitle != nil {
            confidence = "medium"
        } else if ownerBundleIdentifier != nil, bounds != nil {
            confidence = "medium"
        } else {
            confidence = "low"
        }

        let label: String
        if let title = cleanIdentityText(title) {
            label = "\(title) window in \(readableOwner)"
        } else if let bounds {
            label = "\(readableOwner) window near \(Int(bounds.x)),\(Int(bounds.y))"
        } else {
            label = "\(readableOwner) window \(windowNumber)"
        }

        let digest = String(sha256Digest(fingerprintParts.joined(separator: "|")).prefix(24))
        return StableIdentity(
            id: "desktopWindow:\(digest)",
            kind: "desktopWindow",
            confidence: confidence,
            label: label,
            components: components,
            reasons: reasons
        )
    }

    private func normalizedIdentityText(_ text: String?) -> String? {
        guard let cleaned = cleanIdentityText(text) else {
            return nil
        }
        return cleaned.lowercased()
    }

    private func cleanIdentityText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func coarseBoundsIdentityComponent(_ bounds: Rect) -> String {
        let width = Int((bounds.width / 50.0).rounded() * 50.0)
        let height = Int((bounds.height / 50.0).rounded() * 50.0)
        let x = Int((bounds.x / 100.0).rounded() * 100.0)
        let y = Int((bounds.y / 100.0).rounded() * 100.0)
        return "x\(x)-y\(y)-w\(width)-h\(height)"
    }

    private func runningApps(includeBackground: Bool) -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                !app.isTerminated
                    && app.processIdentifier > 0
                    && (includeBackground || app.activationPolicy == .regular)
            }
            .sorted { lhs, rhs in
                let lhsName = lhs.localizedName ?? lhs.bundleIdentifier ?? "\(lhs.processIdentifier)"
                let rhsName = rhs.localizedName ?? rhs.bundleIdentifier ?? "\(rhs.processIdentifier)"
                return lhsName < rhsName
            }
    }

    private func appState(for app: NSRunningApplication, idPrefix: String, depth: Int, maxChildren: Int) -> AppState {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        let nodes = windows.enumerated().map { index, window in
            buildNode(
                window,
                id: "\(idPrefix)\(index)",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        return AppState(
            app: AppRecord(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                pid: app.processIdentifier
            ),
            windows: nodes
        )
    }

    private func targetApp() throws -> NSRunningApplication {
        if let pidString = option("--pid"), let pid = pid_t(pidString) {
            if let app = NSRunningApplication(processIdentifier: pid) {
                return app
            }
            throw CommandError(description: "no running app with pid \(pid)")
        }

        guard let app = NSWorkspace.shared.frontmostApplication else {
            throw CommandError(description: "no frontmost application found")
        }

        return app
    }

    private func requireTrusted() throws {
        guard AXIsProcessTrusted() else {
            throw CommandError(description: "Accessibility access is not enabled. Run `03 trust` first.")
        }
    }

    private func windowOwnerSummaries(activePid: pid_t?) -> [AppSummary] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var byPid: [Int32: AppSummary] = [:]
        for window in rawWindows {
            guard let pid = window[kCGWindowOwnerPID as String] as? Int32 else {
                continue
            }

            let name = window[kCGWindowOwnerName as String] as? String
            byPid[pid] = AppSummary(
                name: name,
                bundleIdentifier: nil,
                pid: pid,
                active: pid == activePid
            )
        }

        return byPid.values.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    private func resolveElement(id: String, in pid: pid_t) throws -> AXUIElement {
        let id = try normalizedElementID(id)
        guard id.first == "w" else {
            throw CommandError(description: "element id must start with a window path like w0")
        }

        let parts = id.dropFirst().split(separator: ".").map(String.init)
        guard let windowIndexString = parts.first, let windowIndex = Int(windowIndexString) else {
            throw CommandError(description: "invalid window path in element id \(id)")
        }

        let axApp = AXUIElementCreateApplication(pid)
        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        guard windows.indices.contains(windowIndex) else {
            throw CommandError(description: "window index \(windowIndex) is out of range")
        }

        var current = windows[windowIndex]
        for childIndexString in parts.dropFirst() {
            guard let childIndex = Int(childIndexString) else {
                throw CommandError(description: "invalid child index '\(childIndexString)' in \(id)")
            }

            let children = accessibilityArray(current, kAXChildrenAttribute)
            guard children.indices.contains(childIndex) else {
                throw CommandError(description: "child index \(childIndex) is out of range in \(id)")
            }
            current = children[childIndex]
        }

        return current
    }

    private func normalizedElementID(_ id: String) throws -> String {
        if id.first == "w" {
            return id
        }

        let parts = id.split(separator: ".").map(String.init)
        if parts.count >= 2, parts[0].first == "a", parts[1].first == "w" {
            return parts.dropFirst().joined(separator: ".")
        }

        throw CommandError(description: "element id must look like w0.1.2 or a0.w0.1.2")
    }

    private func buildNode(_ element: AXUIElement, id: String, depth: Int, maxChildren: Int) -> ElementNode {
        buildNode(
            element,
            id: id,
            ownerName: nil,
            ownerBundleIdentifier: nil,
            depth: depth,
            maxChildren: maxChildren
        )
    }

    private func buildNode(
        _ element: AXUIElement,
        id: String,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        depth: Int,
        maxChildren: Int
    ) -> ElementNode {
        let role = stringAttribute(element, kAXRoleAttribute)
        let subrole = stringAttribute(element, kAXSubroleAttribute)
        let title = stringAttribute(element, kAXTitleAttribute)
        let value = stringLikeAttribute(element, kAXValueAttribute)
        let help = stringAttribute(element, kAXHelpAttribute)
        let enabled = boolAttribute(element, kAXEnabledAttribute)
        let elementFrame = frame(element)
        let actions = actionNames(element)
        let children: [ElementNode]
        if depth > 0 {
            children = accessibilityArray(element, kAXChildrenAttribute)
                .prefix(maxChildren)
                .enumerated()
                .map { index, child in
                    buildNode(
                        child,
                        id: "\(id).\(index)",
                        ownerName: ownerName,
                        ownerBundleIdentifier: ownerBundleIdentifier,
                        depth: depth - 1,
                        maxChildren: maxChildren
                    )
                }
        } else {
            children = []
        }

        return ElementNode(
            id: id,
            stableIdentity: accessibilityElementStableIdentity(
                pathID: id,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                role: role,
                subrole: subrole,
                title: title,
                help: help,
                frame: elementFrame,
                actions: actions
            ),
            role: role,
            subrole: subrole,
            title: title,
            value: value,
            help: help,
            enabled: enabled,
            frame: elementFrame,
            actions: actions,
            children: children
        )
    }

    private func accessibilityElementStableIdentity(
        pathID: String,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        role: String?,
        subrole: String?,
        title: String?,
        help: String?,
        frame: Rect?,
        actions: [String]
    ) -> StableIdentity {
        let normalizedOwnerName = normalizedIdentityText(ownerName)
        let owner = ownerBundleIdentifier.flatMap(normalizedIdentityText)
            ?? normalizedOwnerName
            ?? "unknown-owner"
        let readableOwner = cleanIdentityText(ownerName)
            ?? ownerBundleIdentifier
            ?? "unknown app"
        var components = ["owner": owner]
        var reasons = owner == "unknown-owner"
            ? ["owner unavailable"]
            : ["owner bundle identifier or name"]
        var fingerprintParts = [
            "accessibilityElement",
            "owner:\(owner)"
        ]

        if let role {
            components["role"] = role
            reasons.append("role")
            fingerprintParts.append("role:\(role)")
        }
        if let subrole {
            components["subrole"] = subrole
            reasons.append("subrole")
            fingerprintParts.append("subrole:\(subrole)")
        }
        if let normalizedTitle = normalizedIdentityText(title) {
            components["title"] = normalizedTitle
            reasons.append("title")
            fingerprintParts.append("title:\(normalizedTitle)")
        } else if let normalizedHelp = normalizedIdentityText(help) {
            components["help"] = normalizedHelp
            reasons.append("help")
            fingerprintParts.append("help:\(normalizedHelp)")
        }

        if !actions.isEmpty {
            let joinedActions = actions.joined(separator: ",")
            components["actions"] = joinedActions
            reasons.append("available actions")
            fingerprintParts.append("actions:\(joinedActions)")
        }

        if let frame {
            let coarseFrame = coarseBoundsIdentityComponent(frame)
            components["coarseFrame"] = coarseFrame
            reasons.append("coarse frame")
            fingerprintParts.append("frame:\(coarseFrame)")
        } else if components["title"] == nil, components["help"] == nil {
            components["pathFallback"] = pathID
            reasons.append("path fallback")
            fingerprintParts.append("path:\(pathID)")
        }

        let hasOwner = owner != "unknown-owner"
        let hasRole = role != nil
        let hasSemanticLabel = components["title"] != nil || components["help"] != nil
        let confidence: String
        if hasOwner, hasRole, hasSemanticLabel, frame != nil {
            confidence = "high"
        } else if hasOwner, hasRole, hasSemanticLabel || frame != nil {
            confidence = "medium"
        } else {
            confidence = "low"
        }

        let label: String
        if let title = cleanIdentityText(title) {
            label = "\(title) \(role ?? "element") in \(readableOwner)"
        } else if let help = cleanIdentityText(help) {
            label = "\(help) \(role ?? "element") in \(readableOwner)"
        } else if let frame {
            label = "\(role ?? "element") in \(readableOwner) near \(Int(frame.x)),\(Int(frame.y))"
        } else {
            label = "\(role ?? "element") at \(pathID) in \(readableOwner)"
        }

        let digest = String(sha256Digest(fingerprintParts.joined(separator: "|")).prefix(24))
        return StableIdentity(
            id: "accessibilityElement:\(digest)",
            kind: "accessibilityElement",
            confidence: confidence,
            label: label,
            components: components,
            reasons: reasons
        )
    }

    private func accessibilityArray(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let array = value as? [AXUIElement] else {
            return []
        }
        return array
    }

    private func actionNames(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success,
              let names = names as? [String] else {
            return []
        }
        return names.sorted()
    }

    private func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private func stringLikeAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }

        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let number = value as? NSNumber else {
            return nil
        }
        return number.boolValue
    }

    private func frame(_ element: AXUIElement) -> Rect? {
        guard let position = pointAttribute(element, kAXPositionAttribute),
              let size = sizeAttribute(element, kAXSizeAttribute) else {
            return nil
        }

        return Rect(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height)
        )
    }

    private func pointAttribute(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    private func sizeAttribute(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }

    private func writeJSON<T: Encodable>(_ value: T) throws {
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode JSON")
        }
        print(string)
    }

    private func option(_ name: String) -> String? {
        guard let index = arguments.firstIndex(of: name) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }
        return arguments[valueIndex]
    }

    private func flag(_ name: String) -> Bool {
        arguments.contains(name)
    }

    private func requiredOption(_ name: String) throws -> String {
        guard let value = option(name), !value.isEmpty else {
            throw CommandError(description: "missing required option \(name)")
        }
        return value
    }

    private func parseBool(_ value: String) -> Bool {
        switch value.lowercased() {
        case "1", "true", "yes", "y":
            return true
        default:
            return false
        }
    }
}
