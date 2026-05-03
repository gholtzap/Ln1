import AppKit
import ApplicationServices
import CryptoKit
import Darwin
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

struct AccessibilityElementInspectResult: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let element: ElementNode
    let identityVerification: IdentityVerification?
    let depth: Int
    let maxChildren: Int
    let message: String
}

struct AccessibilityElementWaitTarget: Codable {
    let element: String
    let expectedIdentity: String?
    let minimumConfidence: String?
    let title: String?
    let value: String?
    let match: String
    let enabled: Bool?
}

struct AccessibilityElementWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: AccessibilityElementWaitTarget
    let expectedExists: Bool
    let current: ElementNode?
    let identityVerification: IdentityVerification?
    let titleMatched: Bool?
    let valueMatched: Bool?
    let enabledMatched: Bool?
    let matched: Bool
}

struct AccessibilityElementWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let depth: Int
    let maxChildren: Int
    let verification: AccessibilityElementWaitVerification
    let message: String
}

struct AccessibilityMenuState: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let menuBar: ElementNode?
    let depth: Int
    let maxChildren: Int
    let message: String
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

struct SystemContextState: Codable {
    let generatedAt: String
    let platform: String
    let hostName: String
    let userName: String
    let homeDirectory: String
    let currentDirectory: String
    let shellPath: String?
    let processIdentifier: Int32
    let executablePath: String?
    let operatingSystemVersion: String
    let operatingSystemVersionString: String
    let architecture: String
    let processorCount: Int
    let activeProcessorCount: Int
    let physicalMemoryBytes: UInt64
    let systemUptimeSeconds: Double
    let timeZoneIdentifier: String
    let localeIdentifier: String
}

struct AppSummary: Codable {
    let name: String?
    let bundleIdentifier: String?
    let pid: Int32
    let active: Bool
}

struct AppPreflightCheck: Codable {
    let name: String
    let ok: Bool
    let code: String
    let message: String
}

struct AppActivationPlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppRecord
    let activeBefore: AppRecord?
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppActivationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppRecord
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppActiveWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: AppRecord
    let current: AppRecord?
    let matched: Bool
}

struct AppActiveWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: AppActiveWaitVerification
    let message: String
}

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

struct DesktopWindowWaitTarget: Codable {
    let id: String?
    let ownerPID: Int32?
    let bundleIdentifier: String?
    let title: String?
    let titleMatch: String
}

struct DesktopWindowWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: DesktopWindowWaitTarget
    let expectedExists: Bool
    let currentCount: Int
    let current: [DesktopWindowRecord]
    let matched: Bool
}

struct DesktopWindowWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let includeDesktop: Bool
    let includeAllLayers: Bool
    let limit: Int
    let verification: DesktopWindowWaitVerification
    let message: String
}

struct DesktopDisplayRecord: Codable {
    let id: String
    let displayID: UInt32
    let name: String?
    let main: Bool
    let active: Bool
    let online: Bool
    let builtin: Bool
    let inMirrorSet: Bool
    let bounds: Rect
    let pixelWidth: Int
    let pixelHeight: Int
    let scaleFactor: Double?
    let rotationDegrees: Double
    let colorSpaceName: String?
}

struct DesktopDisplaysState: Codable {
    let generatedAt: String
    let platform: String
    let available: Bool
    let message: String
    let count: Int
    let displays: [DesktopDisplayRecord]
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

struct ClipboardWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let changedFrom: Int?
    let expectedHasString: Bool?
    let expectedStringDigest: String?
    let current: ClipboardAuditSummary
    let matched: Bool
}

struct ClipboardWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: ClipboardWaitVerification
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
    var formChecked: Bool? = nil
    var navigationURL: String? = nil
    var currentURL: String? = nil
    var urlMatched: Bool? = nil
    var clickSelector: String? = nil
    var clickTagName: String? = nil
    var focusSelector: String? = nil
    var focusTagName: String? = nil
    var keyName: String? = nil
    var keyModifiers: [String]? = nil
    var keyModifierMask: Int? = nil
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

struct BrowserTextWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let expectedTextLength: Int
    let expectedTextDigest: String
    let currentTextLength: Int?
    let currentTextDigest: String?
    let currentURL: String?
    let match: String
    let matched: Bool
}

struct BrowserTextWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let expectedTextLength: Int
    let expectedTextDigest: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserTextWaitVerification
    let message: String
}

struct BrowserElementTextWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedTextLength: Int
    let expectedTextDigest: String
    let currentTextLength: Int?
    let currentTextDigest: String?
    let currentURL: String?
    let tagName: String?
    let match: String
    let matched: Bool
}

struct BrowserElementTextWaitPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let currentText: String?
    let currentURL: String?
    let tagName: String?
    let match: String
    let matched: Bool
}

struct BrowserElementTextWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedTextLength: Int
    let expectedTextDigest: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserElementTextWaitVerification
    let message: String
}

struct BrowserValueWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedValueLength: Int
    let expectedValueDigest: String
    let currentValueLength: Int?
    let currentValueDigest: String?
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let match: String
    let matched: Bool
}

struct BrowserValueWaitPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let currentValue: String?
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let match: String
    let matched: Bool
}

struct BrowserValueWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedValueLength: Int
    let expectedValueDigest: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserValueWaitVerification
    let message: String
}

struct BrowserReadyWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let expectedState: String
    let currentState: String?
    let currentURL: String?
    let matched: Bool
}

struct BrowserReadyWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let expectedState: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserReadyWaitVerification
    let message: String
}

struct BrowserTitleWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let expectedTitle: String
    let currentTitle: String?
    let currentURL: String?
    let match: String
    let matched: Bool
}

struct BrowserTitleWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let expectedTitle: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserTitleWaitVerification
    let message: String
}

struct BrowserCheckedWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedChecked: Bool
    let currentChecked: Bool?
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let matched: Bool
}

struct BrowserCheckedWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedChecked: Bool
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserCheckedWaitVerification
    let message: String
}

struct BrowserEnabledWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedEnabled: Bool
    let currentEnabled: Bool?
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let matched: Bool
}

struct BrowserEnabledWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedEnabled: Bool
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserEnabledWaitVerification
    let message: String
}

struct BrowserFocusWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedFocused: Bool
    let currentFocused: Bool?
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let activeTagName: String?
    let activeInputType: String?
    let matched: Bool
}

struct BrowserFocusWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedFocused: Bool
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserFocusWaitVerification
    let message: String
}

struct BrowserAttributeWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let attribute: String
    let expectedValueLength: Int
    let expectedValueDigest: String
    let currentValueLength: Int?
    let currentValueDigest: String?
    let currentURL: String?
    let tagName: String?
    let match: String
    let matched: Bool
}

struct BrowserAttributeWaitPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let attribute: String
    let currentValue: String?
    let currentURL: String?
    let tagName: String?
    let match: String
    let matched: Bool
}

struct BrowserAttributeWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let attribute: String
    let expectedValueLength: Int
    let expectedValueDigest: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserAttributeWaitVerification
    let message: String
}

struct BrowserDOMElement: Codable {
    let id: String
    let parentID: String?
    let depth: Int
    let selector: String?
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

struct BrowserSelectOptionPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let disabled: Bool?
    let optionCount: Int?
    let selectedIndex: Int?
    let selectedValueLength: Int?
    let selectedLabelLength: Int?
    let matched: Bool
}

struct BrowserCheckedPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let requestedChecked: Bool
    let currentChecked: Bool?
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

struct BrowserSelectOptionResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let requestedValueLength: Int?
    let requestedValueDigest: String?
    let requestedLabelLength: Int?
    let requestedLabelDigest: String?
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetDisabled: Bool?
    let optionCount: Int?
    let selectedIndex: Int?
    let selectedValueLength: Int?
    let selectedLabelLength: Int?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserCheckedResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let requestedChecked: Bool
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetInputType: String?
    let targetDisabled: Bool?
    let targetReadOnly: Bool?
    let currentChecked: Bool?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserFocusPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let matched: Bool
}

struct BrowserFocusResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetInputType: String?
    let targetDisabled: Bool?
    let targetReadOnly: Bool?
    let activeElementMatched: Bool
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserKeyPressVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let key: String
    let modifiers: [String]
    let modifierMask: Int
    let selector: String?
    let keyDownDispatched: Bool
    let keyUpDispatched: Bool
}

struct BrowserKeyPressResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let key: String
    let modifiers: [String]
    let modifierMask: Int
    let selector: String?
    let focusVerification: FileOperationVerification?
    let verification: BrowserKeyPressVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserClickPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let disabled: Bool?
    let href: String?
    let matched: Bool
}

struct BrowserClickResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetDisabled: Bool?
    let targetHref: String?
    let expectedURL: String?
    let match: String?
    let urlVerification: BrowserNavigationVerification?
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

struct BrowserURLWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let expectedURL: String
    let match: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserNavigationVerification
    let message: String
}

struct BrowserSelectorWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let state: String
    let matched: Bool
    let currentURL: String?
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let readOnly: Bool?
    let href: String?
    let textLength: Int?
}

struct BrowserSelectorWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let state: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserSelectorWaitVerification
    let message: String
}

struct BrowserCountWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let expectedCount: Int
    let currentCount: Int?
    let currentURL: String?
    let countMatch: String
    let matched: Bool
}

struct BrowserCountWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tabID: String
    let selector: String
    let expectedCount: Int
    let countMatch: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: BrowserCountWaitVerification
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

struct FilesystemTextResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let text: String
    let selection: String
    let textLength: Int
    let textDigest: String
    let byteLength: Int
    let truncated: Bool
    let maxCharacters: Int
    let maxFileBytes: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct FilesystemLinesResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let startLine: Int
    let requestedLineCount: Int
    let returnedLineCount: Int
    let totalLineCount: Int
    let lines: [FileLineMatch]
    let truncated: Bool
    let maxLineCharacters: Int
    let maxFileBytes: Int
    let textDigest: String
    let byteLength: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BoundedJSONProperty: Encodable {
    let key: String
    let value: BoundedJSONNode
}

struct BoundedJSONNode: Encodable {
    let type: String
    let value: JSONValue?
    let entries: [BoundedJSONProperty]?
    let items: [BoundedJSONNode]?
    let count: Int?
    let truncated: Bool
}

struct FilesystemJSONResult: Encodable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let pointer: String?
    let found: Bool
    let valueType: String?
    let value: BoundedJSONNode?
    let truncated: Bool
    let maxDepth: Int
    let maxItems: Int
    let maxStringCharacters: Int
    let maxFileBytes: Int
    let textDigest: String
    let byteLength: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BoundedPropertyListProperty: Encodable {
    let key: String
    let value: BoundedPropertyListNode
}

struct BoundedPropertyListNode: Encodable {
    let type: String
    let value: JSONValue?
    let entries: [BoundedPropertyListProperty]?
    let items: [BoundedPropertyListNode]?
    let count: Int?
    let dataDigest: String?
    let truncated: Bool
}

struct FilesystemPropertyListResult: Encodable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let pointer: String?
    let found: Bool
    let valueType: String?
    let value: BoundedPropertyListNode?
    let truncated: Bool
    let maxDepth: Int
    let maxItems: Int
    let maxStringCharacters: Int
    let maxFileBytes: Int
    let format: String
    let byteLength: Int
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct FilesystemWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let path: String
    let expectedExists: Bool
    let expectedSizeBytes: Int?
    let expectedDigest: String?
    let algorithm: String?
    let maxFileBytes: Int?
    let matched: Bool
    let sizeMatched: Bool?
    let digestMatched: Bool?
    let currentDigest: String?
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

struct FileTextWriteResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let path: String
    let created: Bool
    let overwritten: Bool
    let previous: FileAuditTarget
    let current: FileRecord
    let writtenLength: Int
    let writtenBytes: Int
    let writtenDigest: String
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileTextAppendResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let path: String
    let created: Bool
    let previous: FileAuditTarget
    let current: FileRecord
    let appendedLength: Int
    let appendedBytes: Int
    let appendedDigest: String
    let finalBytes: Int
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

private struct BrowserKeyDefinition {
    let key: String
    let code: String
    let windowsVirtualKeyCode: Int
    let text: String?
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
    let cli = Ln1CLI(arguments: args)
    try cli.run()
} catch let error as CommandError {
    fputs("Ln1: \(error.description)\n", stderr)
    exit(1)
} catch {
    fputs("Ln1: \(error)\n", stderr)
    exit(1)
}

final class Ln1CLI {
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
        case "system":
            try system()
        case "observe":
            try observe()
        case "workflow":
            try workflow()
        case "apps":
            try apps()
        case "processes":
            try processes()
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

    private func system() throws {
        let mode = arguments.dropFirst().first ?? "context"
        switch mode {
        case "context", "info":
            try writeJSON(systemContextState())
        case "--help", "-h", "help":
            printHelp()
        default:
            throw CommandError(description: "unknown system mode '\(mode)'")
        }
    }

    private func desktop() throws {
        let mode = arguments.dropFirst().first ?? "windows"

        switch mode {
        case "displays":
            try writeJSON(desktopDisplays())
        case "wait-window":
            try writeJSON(desktopWindowWaitState())
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
                : "Grant Accessibility access to the terminal app running Ln1, then retry."
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
                : "Accessibility permission is not enabled, so Ln1 state and Ln1 perform cannot inspect or operate app UI.",
            remediation: trusted ? nil : "Run `Ln1 trust`, grant Accessibility access to the terminal app, then rerun `Ln1 doctor`."
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
                    remediation: "Run `Ln1 desktop windows --limit 5` from an interactive macOS user session."
                )
            }
            if desktop.windows.isEmpty {
                return DoctorCheck(
                    name: "desktop.windowMetadata",
                    status: "warn",
                    required: true,
                    message: "WindowServer metadata is available, but no visible windows matched the current filters.",
                    remediation: "Try `Ln1 desktop windows --include-desktop --all-layers --limit 20`."
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
                remediation: "Run `Ln1 desktop windows --limit 5` to inspect the desktop adapter error."
            )
        }
    }

    private func doctorAuditLogCheck() -> DoctorCheck {
        do {
            let auditURL = try auditLogURL()
            let directory = auditURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let probeURL = directory.appendingPathComponent(".Ln1-doctor-\(UUID().uuidString).tmp")
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
                remediation: "Use `Ln1 doctor --endpoint http://127.0.0.1:9222` or pass a file path containing a DevTools /json/list fixture."
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
                remediation: "Start Chromium with `--remote-debugging-port=9222`, then rerun `Ln1 doctor --endpoint http://127.0.0.1:9222`."
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

    private func targetRunningApplicationForAppCommand() throws -> NSRunningApplication {
        if flag("--current") {
            return .current
        }

        if let pidValue = option("--pid") {
            guard let pid = pid_t(pidValue),
                  let app = NSRunningApplication(processIdentifier: pid),
                  !app.isTerminated else {
                throw CommandError(description: "no running app found for --pid \(pidValue)")
            }
            return app
        }

        if let bundleIdentifier = option("--bundle-id") {
            let matches = NSWorkspace.shared.runningApplications
                .filter { !$0.isTerminated && $0.bundleIdentifier == bundleIdentifier }
                .sorted { lhs, rhs in
                    let lhsRegular = lhs.activationPolicy == .regular
                    let rhsRegular = rhs.activationPolicy == .regular
                    if lhsRegular != rhsRegular {
                        return lhsRegular && !rhsRegular
                    }
                    return lhs.processIdentifier < rhs.processIdentifier
                }
            guard let app = matches.first else {
                throw CommandError(description: "no running app found for --bundle-id \(bundleIdentifier)")
            }
            return app
        }

        throw CommandError(description: "apps plan/activate requires --pid PID, --bundle-id BUNDLE_ID, or --current")
    }

    private func appActivationChecks(target: NSRunningApplication) -> [AppPreflightCheck] {
        [
            AppPreflightCheck(
                name: "apps.targetRunning",
                ok: !target.isTerminated,
                code: target.isTerminated ? "terminated" : "running",
                message: target.isTerminated
                    ? "target app is terminated"
                    : "target app is running"
            ),
            AppPreflightCheck(
                name: "apps.targetActivatable",
                ok: target.activationPolicy == .regular,
                code: target.activationPolicy == .regular ? "regular" : "not_regular",
                message: target.activationPolicy == .regular
                    ? "target app has regular activation policy"
                    : "target app is not a regular GUI application"
            )
        ]
    }

    private func verifyAppActivation(
        target: NSRunningApplication,
        requested: Bool,
        activeAfter: AppRecord?
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "activation_request_failed",
                message: "macOS did not accept the app activation request"
            )
        }

        guard activeAfter?.pid == target.processIdentifier else {
            return FileOperationVerification(
                ok: false,
                code: "active_app_mismatch",
                message: "frontmost app did not match the requested app after activation"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "active_app_matched",
            message: "frontmost app matches the requested app"
        )
    }

    private func waitForActiveApp(
        target: AppRecord,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> AppActiveWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var current = activeAppRecord()

        while current?.pid != target.pid, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            current = activeAppRecord()
        }

        let matched = current?.pid == target.pid
        return AppActiveWaitVerification(
            ok: matched,
            code: matched ? "active_app_matched" : "active_app_timeout",
            message: matched
                ? "frontmost app matched the expected target"
                : "frontmost app did not match the expected target before timeout",
            target: target,
            current: current,
            matched: matched
        )
    }

    private func activeAppRecord() -> AppRecord? {
        NSWorkspace.shared.frontmostApplication.map(appRecord(for:))
    }

    private func appRecord(for app: NSRunningApplication) -> AppRecord {
        AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier
        )
    }

    private func appDisplayName(_ app: AppRecord) -> String {
        app.name ?? app.bundleIdentifier ?? "pid \(app.pid)"
    }

    private func runningProcessRecords() -> [ProcessRecord] {
        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else {
            return []
        }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let bytesReturned = pids.withUnsafeMutableBytes { buffer in
            proc_listpids(
                UInt32(PROC_ALL_PIDS),
                0,
                buffer.baseAddress,
                Int32(buffer.count)
            )
        }
        guard bytesReturned > 0 else {
            return []
        }

        let returnedCount = min(
            pids.count,
            Int(bytesReturned) / MemoryLayout<pid_t>.stride
        )
        return pids
            .prefix(returnedCount)
            .filter { $0 > 0 }
            .compactMap(processRecord(for:))
            .sorted(by: processRecordPrecedes)
    }

    private func processRecord(for pid: pid_t) -> ProcessRecord? {
        let name = processName(for: pid)
        let path = processPath(for: pid)
        let app = NSRunningApplication(processIdentifier: pid)
        if name == nil, path == nil, app == nil {
            return nil
        }

        let activePID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        return ProcessRecord(
            pid: pid,
            name: name,
            executablePath: path,
            bundleIdentifier: app?.bundleIdentifier,
            appName: app?.localizedName,
            activeApp: pid == activePID,
            currentProcess: pid == getpid()
        )
    }

    private func processName(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 1_024)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else {
            return nil
        }
        return stringFromNullTerminatedBuffer(buffer)
    }

    private func processPath(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4_096)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else {
            return nil
        }
        return stringFromNullTerminatedBuffer(buffer)
    }

    private func processRecordPrecedes(_ lhs: ProcessRecord, _ rhs: ProcessRecord) -> Bool {
        if lhs.currentProcess != rhs.currentProcess {
            return lhs.currentProcess && !rhs.currentProcess
        }
        if lhs.activeApp != rhs.activeApp {
            return lhs.activeApp && !rhs.activeApp
        }
        let lhsGUI = lhs.bundleIdentifier != nil
        let rhsGUI = rhs.bundleIdentifier != nil
        if lhsGUI != rhsGUI {
            return lhsGUI && !rhsGUI
        }
        return lhs.pid < rhs.pid
    }

    private func waitForProcess(
        pid: pid_t,
        expectedExists: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> ProcessWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var current = processRecord(for: pid)

        while (current != nil) != expectedExists, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            current = processRecord(for: pid)
        }

        let matched = (current != nil) == expectedExists
        return ProcessWaitVerification(
            ok: matched,
            code: matched ? "process_matched" : "process_timeout",
            message: matched
                ? "process existence matched expected state"
                : "process existence did not match expected state before timeout",
            pid: pid,
            expectedExists: expectedExists,
            current: current,
            matched: matched
        )
    }

    private func stringFromNullTerminatedBuffer(_ buffer: [CChar]) -> String? {
        let endIndex = buffer.firstIndex(of: 0) ?? buffer.count
        guard endIndex > 0 else {
            return nil
        }
        let bytes = buffer[..<endIndex].map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func systemContextState() -> SystemContextState {
        let processInfo = ProcessInfo.processInfo
        let version = processInfo.operatingSystemVersion
        return SystemContextState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            hostName: processInfo.hostName,
            userName: NSUserName(),
            homeDirectory: NSHomeDirectory(),
            currentDirectory: FileManager.default.currentDirectoryPath,
            shellPath: processInfo.environment["SHELL"],
            processIdentifier: processInfo.processIdentifier,
            executablePath: Bundle.main.executableURL?.path,
            operatingSystemVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
            operatingSystemVersionString: processInfo.operatingSystemVersionString,
            architecture: systemArchitecture(),
            processorCount: processInfo.processorCount,
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemoryBytes: processInfo.physicalMemory,
            systemUptimeSeconds: processInfo.systemUptime,
            timeZoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier
        )
    }

    private func systemArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #elseif arch(arm)
        return "arm"
        #elseif arch(i386)
        return "i386"
        #else
        return "unknown"
        #endif
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
                : "Grant Accessibility access to the terminal app running Ln1 before using state or perform."
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
        var command: WorkflowCommand?
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
            guard option("--execute-mutating").map(parseBool) == true else {
                throw CommandError(description: "workflow run mutating execution requires --execute-mutating true. Use `--dry-run true` to inspect the command first.")
            }
            let reason = try workflowExecutionReason()
            if let currentCommand = command {
                let argv = try workflowArguments(currentCommand.argv, replacingReasonWith: reason)
                command = WorkflowCommand(
                    display: workflowDisplayCommand(argv),
                    argv: argv,
                    risk: currentCommand.risk,
                    mutates: currentCommand.mutates,
                    requiresReason: currentCommand.requiresReason
                )
            }
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
        case "inspect-menu":
            return workflowPreflightInspectMenu()
        case "inspect-system":
            return workflowPreflightInspectSystem()
        case "inspect-displays":
            return workflowPreflightInspectDisplays()
        case "inspect-process":
            return workflowPreflightInspectProcess()
        case "inspect-element":
            return workflowPreflightInspectElement()
        case "wait-process":
            return workflowPreflightWaitProcess()
        case "wait-window":
            return workflowPreflightWaitWindow()
        case "wait-element":
            return workflowPreflightWaitElement()
        case "wait-active-app":
            return workflowPreflightWaitActiveApp()
        case "activate-app":
            return try workflowPreflightActivateApp()
        case "control-active-app":
            return workflowPreflightControlActiveApp()
        case "read-browser":
            return workflowPreflightReadBrowser()
        case "fill-browser":
            return workflowPreflightBrowserAction(kind: "fill")
        case "select-browser":
            return workflowPreflightBrowserAction(kind: "select")
        case "check-browser":
            return workflowPreflightBrowserAction(kind: "check")
        case "focus-browser":
            return workflowPreflightBrowserAction(kind: "focus")
        case "press-browser-key":
            return workflowPreflightBrowserAction(kind: "press-key")
        case "click-browser":
            return workflowPreflightBrowserAction(kind: "click")
        case "navigate-browser":
            return workflowPreflightBrowserAction(kind: "navigate")
        case "wait-browser-url":
            return workflowPreflightWaitBrowserURL()
        case "wait-browser-selector":
            return workflowPreflightWaitBrowserSelector()
        case "wait-browser-count":
            return workflowPreflightWaitBrowserCount()
        case "wait-browser-text":
            return workflowPreflightWaitBrowserText()
        case "wait-browser-element-text":
            return workflowPreflightWaitBrowserElementText()
        case "wait-browser-value":
            return workflowPreflightWaitBrowserValue()
        case "wait-browser-ready":
            return workflowPreflightWaitBrowserReady()
        case "wait-browser-title":
            return workflowPreflightWaitBrowserTitle()
        case "wait-browser-checked":
            return workflowPreflightWaitBrowserChecked()
        case "wait-browser-enabled":
            return workflowPreflightWaitBrowserEnabled()
        case "wait-browser-focus":
            return workflowPreflightWaitBrowserFocus()
        case "wait-browser-attribute":
            return workflowPreflightWaitBrowserAttribute()
        case "wait-clipboard":
            return workflowPreflightWaitClipboard()
        case "inspect-clipboard":
            return workflowPreflightInspectClipboard()
        case "read-clipboard":
            return workflowPreflightReadClipboard()
        case "inspect-file":
            return workflowPreflightInspectFile()
        case "read-file":
            return workflowPreflightReadFile()
        case "tail-file":
            return workflowPreflightTailFile()
        case "read-file-lines":
            return workflowPreflightReadFileLines()
        case "read-file-json":
            return workflowPreflightReadFileJSON()
        case "read-file-plist":
            return workflowPreflightReadFilePropertyList()
        case "write-file":
            return try workflowPreflightWriteFile()
        case "append-file":
            return try workflowPreflightAppendFile()
        case "list-files":
            return workflowPreflightListFiles()
        case "search-files":
            return workflowPreflightSearchFiles()
        case "create-directory":
            return try workflowPreflightCreateDirectory()
        case "duplicate-file":
            return try workflowPreflightDuplicateFile()
        case "move-file":
            return try workflowPreflightMoveFile()
        case "rollback-file-move":
            return try workflowPreflightRollbackFileMove()
        case "checksum-file":
            return workflowPreflightChecksumFile()
        case "compare-files":
            return workflowPreflightCompareFiles()
        case "watch-file":
            return workflowPreflightWatchFile()
        case "wait-file":
            return workflowPreflightWaitFile()
        default:
            throw CommandError(description: "unsupported workflow operation '\(operation)'. Use inspect-active-app, inspect-menu, inspect-system, inspect-displays, inspect-process, inspect-element, wait-process, wait-window, wait-element, wait-active-app, activate-app, control-active-app, read-browser, fill-browser, select-browser, check-browser, focus-browser, press-browser-key, click-browser, navigate-browser, wait-browser-url, wait-browser-selector, wait-browser-count, wait-browser-text, wait-browser-element-text, wait-browser-value, wait-browser-ready, wait-browser-title, wait-browser-checked, wait-browser-enabled, wait-browser-focus, wait-browser-attribute, wait-clipboard, inspect-clipboard, read-clipboard, inspect-file, read-file, tail-file, read-file-lines, read-file-json, read-file-plist, write-file, append-file, list-files, search-files, create-directory, duplicate-file, move-file, rollback-file-move, checksum-file, compare-files, watch-file, or wait-file.")
        }
    }

    private func workflowPreflightInspectSystem() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-system",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 system context",
            nextArguments: ["Ln1", "system", "context"]
        )
    }

    private func workflowPreflightInspectDisplays() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-displays",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 desktop displays",
            nextArguments: ["Ln1", "desktop", "displays"]
        )
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
            var arguments = ["Ln1", "state"]
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

    private func workflowPreflightInspectMenu() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let targetPID: pid_t?
        if let pid = option("--pid") {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                targetPID = processIdentifier
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for inspect-menu.",
                    remediation: nil
                ))
            } else {
                targetPID = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        } else if let frontmost = NSWorkspace.shared.frontmostApplication {
            targetPID = frontmost.processIdentifier
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "pass",
                required: true,
                message: "The frontmost app was selected for inspect-menu.",
                remediation: nil
            ))
        } else {
            targetPID = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No frontmost app target was available for inspect-menu.",
                remediation: "Pass `--pid PID` from `Ln1 apps`."
            ))
        }

        let depth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetPID {
            nextArguments = [
                "Ln1", "state", "menu",
                "--pid", String(targetPID),
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-menu",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectProcess() -> WorkflowPreflight {
        let targetArguments: [String]?
        var prerequisites: [DoctorCheck] = []

        if flag("--current") {
            targetArguments = ["--current"]
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "pass",
                required: true,
                message: "Current Ln1 process was selected for inspection.",
                remediation: nil
            ))
        } else if let rawPID = option("--pid"), let pid = pid_t(rawPID), pid > 0 {
            targetArguments = ["--pid", rawPID]
            let found = processRecord(for: pid) != nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: found ? "pass" : "fail",
                required: true,
                message: found
                    ? "Process metadata is available for pid \(pid)."
                    : "No running process metadata was available for pid \(pid).",
                remediation: found ? nil : "Run `Ln1 processes --limit 50` and choose a current pid."
            ))
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "fail",
                required: true,
                message: "No process target was provided for inspect-process.",
                remediation: "Pass `--pid PID` from `Ln1 processes` or use `--current`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        let nextCommand: String?
        if blockers.isEmpty, let targetArguments {
            let arguments = ["Ln1", "processes", "inspect"] + targetArguments
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "inspect-process",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectElement() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let element = option("--element")
        let pid = option("--pid")

        if let element {
            do {
                _ = try normalizedElementID(element)
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "pass",
                    required: true,
                    message: "An Accessibility element path is available for inspect-element.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass an element ID like `w0.1.2`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No Accessibility element path was provided for inspect-element.",
                remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass `--element ID`."
            ))
        }

        if let pid {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for inspect-element.",
                    remediation: nil
                ))
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        }

        if let minimumConfidence = option("--min-identity-confidence"),
           identityConfidenceRank(minimumConfidence) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.identityConfidence",
                status: "fail",
                required: true,
                message: "Invalid minimum stable identity confidence '\(minimumConfidence)'.",
                remediation: "Use `--min-identity-confidence low`, `medium`, or `high`."
            ))
        }

        let depth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["Ln1", "state", "element"]
            if let pid {
                arguments += ["--pid", pid]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            arguments += [
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-element",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitProcess() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let rawPID = option("--pid")
        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)

        if let rawPID, let pid = pid_t(rawPID), pid > 0 {
            let found = processRecord(for: pid) != nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "pass",
                required: true,
                message: found
                    ? "Process metadata is currently available for pid \(pid)."
                    : "Process metadata is not currently available for pid \(pid); wait-process can wait for this state to change.",
                remediation: nil
            ))
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "fail",
                required: true,
                message: "No process pid was provided for wait-process.",
                remediation: "Pass `--pid PID` from `Ln1 processes`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let rawPID {
            nextArguments = [
                "Ln1", "processes", "wait",
                "--pid", rawPID,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-process",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitWindow() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        var targetArguments: [String] = []
        if let id = option("--id") {
            targetArguments += ["--id", id]
        }
        if let ownerPID = option("--owner-pid") {
            if Int32(ownerPID).map({ $0 > 0 }) == true {
                targetArguments += ["--owner-pid", ownerPID]
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowTarget",
                    status: "fail",
                    required: true,
                    message: "Window owner pid must be a positive integer.",
                    remediation: "Pass `--owner-pid PID` from `Ln1 desktop windows`."
                ))
            }
        }
        if let bundleIdentifier = option("--bundle-id") {
            targetArguments += ["--bundle-id", bundleIdentifier]
        }
        if let title = option("--title") {
            targetArguments += ["--title", title]
        }

        if targetArguments.isEmpty && prerequisites.isEmpty {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowTarget",
                status: "fail",
                required: true,
                message: "No desktop window target was provided for wait-window.",
                remediation: "Pass `--id ID`, `--owner-pid PID`, `--bundle-id BUNDLE_ID`, or `--title TEXT` from `Ln1 desktop windows`."
            ))
        } else if prerequisites.isEmpty {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowTarget",
                status: "pass",
                required: true,
                message: "A desktop window target filter is available for wait-window.",
                remediation: nil
            ))
        }

        let match = option("--match") ?? "contains"
        if !["exact", "prefix", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowMatch",
                status: "fail",
                required: true,
                message: "Window title match mode must be exact, prefix, or contains.",
                remediation: "Pass `--match exact`, `--match prefix`, or `--match contains`."
            ))
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let limit = max(1, option("--limit").flatMap(Int.init) ?? 200)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "desktop", "wait-window"
            ] + targetArguments + [
                "--match", match,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--limit", String(limit)
            ]
            if flag("--include-desktop") {
                arguments.append("--include-desktop")
            }
            if flag("--all-layers") {
                arguments.append("--all-layers")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-window",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitElement() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let element = option("--element")
        let match = option("--match") ?? "contains"
        let pid = option("--pid")

        if let element {
            do {
                _ = try normalizedElementID(element)
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "pass",
                    required: true,
                    message: "An Accessibility element path is available for wait-element.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass an element ID like `w0.1.2`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No Accessibility element path was provided for wait-element.",
                remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass `--element ID`."
            ))
        }

        if let pid {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for wait-element.",
                    remediation: nil
                ))
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        }

        if !["exact", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.elementMatch",
                status: "fail",
                required: true,
                message: "Accessibility element text match mode must be exact or contains.",
                remediation: "Use `--match exact` or `--match contains`."
            ))
        }

        if let minimumConfidence = option("--min-identity-confidence"),
           identityConfidenceRank(minimumConfidence) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.identityConfidence",
                status: "fail",
                required: true,
                message: "Invalid minimum stable identity confidence '\(minimumConfidence)'.",
                remediation: "Use `--min-identity-confidence low`, `medium`, or `high`."
            ))
        }

        if let enabled = option("--enabled") {
            do {
                _ = try booleanOption(enabled, optionName: "--enabled")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.elementEnabled",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--enabled true` or `--enabled false`."
                ))
            }
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 0)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["Ln1", "state", "wait-element"]
            if let pid {
                arguments += ["--pid", pid]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            if let title = option("--title") {
                arguments += ["--title", title]
            }
            if let value = option("--value") {
                arguments += ["--value", value]
            }
            arguments += [
                "--match", match,
                "--exists", String(expectedExists)
            ]
            if let enabled = option("--enabled") {
                arguments += ["--enabled", enabled]
            }
            arguments += [
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-element",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitActiveApp() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for wait-active-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                _ = try targetRunningApplicationForAppCommand()
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for wait-active-app.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments {
            nextArguments = [
                "Ln1", "apps", "wait-active"
            ] + targetArguments + [
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-active-app",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightActivateApp() throws -> WorkflowPreflight {
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        var prerequisites = [
            doctorAuditLogCheck()
        ]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for activate-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                let target = try targetRunningApplicationForAppCommand()
                prerequisites += appActivationChecks(target: target).map { check in
                    DoctorCheck(
                        name: check.name,
                        status: check.ok ? "pass" : "fail",
                        required: true,
                        message: check.message,
                        remediation: check.ok ? nil : "Choose a running regular GUI app from `Ln1 apps`."
                    )
                }
            } catch {
                let message = (error as? CommandError)?.description ?? error.localizedDescription
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: message,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the app activation target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        let nextCommand: String?
        if blockers.isEmpty, let targetArguments {
            var arguments = ["Ln1", "apps", "activate"] + targetArguments
            arguments += [
                "--allow-risk", risk,
                "--audit-log", try auditLogURL().path,
                "--reason", "Describe intent"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "activate-app",
            risk: risk,
            mutates: true,
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
        var targetPid = activePid
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        if option("--pid") != nil || option("--bundle-id") != nil || flag("--current") {
            do {
                let target = try targetRunningApplicationForAppCommand()
                targetPid = target.processIdentifier
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for control-active-app.",
                    remediation: nil
                ))
            } catch {
                targetPid = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 apps` and choose a running app target, or omit app targeting to use the frontmost app."
                ))
            }
        }

        let element = option("--element")
        if element == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No target element was provided for control-active-app.",
                remediation: "Run `Ln1 state\(targetPid.map { " --pid \($0)" } ?? "") --depth 3 --max-children 80` and choose an element ID plus stableIdentity."
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
            var arguments = ["Ln1", "perform"]
            if let targetPid {
                arguments += ["--pid", String(targetPid)]
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
            var arguments = ["Ln1", "browser", "dom"]
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
            let arguments = ["Ln1", "browser", "tabs", "--endpoint", endpoint?.absoluteString ?? "http://127.0.0.1:9222"]
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

    private func workflowPreflightBrowserAction(kind: String) -> WorkflowPreflight {
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
        var prerequisites = [
            requiredBrowserCheck,
            doctorAuditLogCheck()
        ]

        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let value = option("--value")
        let label = option("--label")
        let checked = option("--checked")
        let url = option("--url")
        let expectedURL = option("--expect-url")
        let match = option("--match")
        let key = option("--key")
        let modifiers = option("--modifiers")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for \(kind)-browser.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if kind == "fill" || kind == "select" || kind == "check" || kind == "focus" || kind == "click", selector == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for \(kind)-browser.",
                remediation: "Run `Ln1 workflow run --operation read-browser --id TARGET_ID --dry-run false --allow-risk medium` and choose an element selector."
            ))
        }
        if kind == "press-key" {
            if let key {
                do {
                    _ = try browserKeyDefinition(for: key)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserKey",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a supported key with `--key Enter`, `--key Escape`, `--key Tab`, an arrow key, a function key, or one ASCII letter/digit."
                    ))
                }
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserKey",
                    status: "fail",
                    required: true,
                    message: "No key was provided for press-browser-key.",
                    remediation: "Pass `--key Enter`, `--key Escape`, `--key Tab`, an arrow key, a function key, or one ASCII letter/digit."
                ))
            }
            if let modifiers {
                do {
                    _ = try browserModifierMask(modifiers)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserModifiers",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use comma-separated modifiers from shift, control, alt, or meta."
                    ))
                }
            }
        }
        if kind == "fill", text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No text was provided for fill-browser.",
                remediation: "Pass `--text TEXT` for the target field."
            ))
        }
        if kind == "select" {
            if value == nil && label == nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectOption",
                    status: "fail",
                    required: true,
                    message: "No option value or label was provided for select-browser.",
                    remediation: "Pass `--value VALUE` or `--label LABEL` for the target option."
                ))
            }
            if value != nil && label != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectOption",
                    status: "fail",
                    required: true,
                    message: "select-browser accepts either --value or --label, not both.",
                    remediation: "Pass only one of `--value VALUE` or `--label LABEL`."
                ))
            }
            if let value {
                do {
                    _ = try validatedBrowserSelectOption(value, optionName: "--value")
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserSelectOption",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty option value with `--value VALUE`."
                    ))
                }
            }
            if let label {
                do {
                    _ = try validatedBrowserSelectOption(label, optionName: "--label")
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserSelectOption",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty option label with `--label LABEL`."
                    ))
                }
            }
        }
        if kind == "check", let checked {
            do {
                _ = try browserCheckedValue(checked)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserChecked",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--checked true` or `--checked false`."
                ))
            }
        }
        let normalizedURL: String?
        if kind == "navigate" {
            if let url {
                do {
                    normalizedURL = try validatedBrowserNavigationURL(url)
                } catch {
                    normalizedURL = nil
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass an absolute HTTP(S) URL with `--url URL`."
                    ))
                }
            } else {
                normalizedURL = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserURL",
                    status: "fail",
                    required: true,
                    message: "No URL was provided for navigate-browser.",
                    remediation: "Pass `--url URL` for the target navigation."
                ))
            }
            if let expectedURL {
                do {
                    _ = try validatedBrowserExpectedURL(expectedURL)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserExpectedURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                    ))
                }
            }
            if let match {
                do {
                    _ = try browserURLMatchMode(match)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURLMatch",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                    ))
                }
            }
        } else if kind == "click" {
            normalizedURL = nil
            if let expectedURL {
                do {
                    _ = try validatedBrowserExpectedURL(expectedURL)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserExpectedURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                    ))
                }
            }
            if let match {
                do {
                    _ = try browserURLMatchMode(match)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURLMatch",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                    ))
                }
            }
        } else {
            normalizedURL = nil
        }

        let blockers = workflowBlockers(from: prerequisites)
        let operation = kind == "press-key" ? "press-browser-key" : "\(kind)-browser"
        let nextArguments: [String]?
        if blockers.isEmpty, kind == "navigate", let id, let normalizedURL {
            var arguments = ["Ln1", "browser", "navigate"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--url", normalizedURL]
            if let expectedURL {
                arguments += ["--expect-url", expectedURL]
            }
            if let match {
                arguments += ["--match", match]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else if blockers.isEmpty, kind == "press-key", let id, let key {
            var arguments = ["Ln1", "browser", "press-key"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--key", key]
            if let selector {
                arguments += ["--selector", selector]
            }
            if let modifiers {
                arguments += ["--modifiers", modifiers]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", kind]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--selector", selector]
            if kind == "fill", let text {
                arguments += ["--text", text]
            }
            if kind == "select" {
                if let value {
                    arguments += ["--value", value]
                }
                if let label {
                    arguments += ["--label", label]
                }
            }
            if kind == "check" {
                arguments += ["--checked", checked ?? "true"]
            }
            if kind == "click", let expectedURL {
                arguments += ["--expect-url", expectedURL, "--match", match ?? "exact"]
                if let timeout = option("--timeout-ms") {
                    arguments += ["--timeout-ms", timeout]
                }
                if let interval = option("--interval-ms") {
                    arguments += ["--interval-ms", interval]
                }
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: operation,
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserURL() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let expectedURL = option("--expect-url")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-url.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let expectedURL {
            do {
                _ = try validatedBrowserExpectedURL(expectedURL)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserExpectedURL",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserExpectedURL",
                status: "fail",
                required: true,
                message: "No expected URL was provided for wait-browser-url.",
                remediation: "Pass `--expect-url VALUE` for the target URL."
            ))
        }
        if let match {
            do {
                _ = try browserURLMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserURLMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let expectedURL {
            var arguments = ["Ln1", "browser", "wait-url"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--expect-url", expectedURL,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-url",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserSelector() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let state = option("--state")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-selector.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-selector.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let state {
            do {
                _ = try browserSelectorWaitState(state)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectorState",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--state attached`, `--state visible`, `--state hidden`, or `--state detached`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-selector"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--state", state ?? "attached",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-selector",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserCount() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let count = option("--count")
        let countMatch = option("--count-match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-count.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-count.",
                remediation: "Pass `--selector CSS_SELECTOR` for the repeated elements."
            ))
        }
        if let count {
            do {
                _ = try browserSelectorCountValue(count)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserCount",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--count N`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserCount",
                status: "fail",
                required: true,
                message: "No expected selector count was provided for wait-browser-count.",
                remediation: "Pass `--count N` for the expected selector count."
            ))
        }
        if let countMatch {
            do {
                _ = try browserCountMatchMode(countMatch)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserCountMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--count-match exact`, `--count-match at-least`, or `--count-match at-most`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let count {
            var arguments = ["Ln1", "browser", "wait-count"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--count", count,
                "--count-match", countMatch ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-count",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserText() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-text.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected text was provided for wait-browser-text.",
                remediation: "Pass `--text TEXT` for the expected page text."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTextMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match contains` or `--match exact`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let text {
            var arguments = ["Ln1", "browser", "wait-text"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--text", text,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-text",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserElementText() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-element-text.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-element-text.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected element text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected element text was provided for wait-browser-element-text.",
                remediation: "Pass `--text TEXT` for the expected element text."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserElementTextMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let text {
            var arguments = ["Ln1", "browser", "wait-element-text"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--text", text,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-element-text",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserValue() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-value.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-value.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target input, textarea, or select."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected value text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected value text was provided for wait-browser-value.",
                remediation: "Pass `--text TEXT` for the expected field value."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserValueMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let text {
            var arguments = ["Ln1", "browser", "wait-value"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--text", text,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-value",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserReady() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let state = option("--state")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-ready.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let state {
            do {
                _ = try browserReadyState(state)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserReadyState",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--state loading`, `--state interactive`, or `--state complete`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id {
            var arguments = ["Ln1", "browser", "wait-ready"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--state", state ?? "complete",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-ready",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserTitle() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let title = option("--title")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-title.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let title {
            do {
                _ = try validatedBrowserExpectedTitle(title)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTitle",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected title with `--title TITLE`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTitle",
                status: "fail",
                required: true,
                message: "No expected title was provided for wait-browser-title.",
                remediation: "Pass `--title TITLE` for the expected page title."
            ))
        }
        if let match {
            do {
                _ = try browserTitleMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTitleMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match contains` or `--match exact`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let title {
            var arguments = ["Ln1", "browser", "wait-title"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--title", title,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-title",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserChecked() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let checked = option("--checked")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-checked.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-checked.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target checkbox or radio input."
            ))
        }
        if let checked {
            do {
                _ = try browserCheckedValue(checked)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserChecked",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--checked true` or `--checked false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-checked"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--checked", checked ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-checked",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserEnabled() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let enabled = option("--enabled")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-enabled.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-enabled.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let enabled {
            do {
                _ = try browserEnabledValue(enabled)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserEnabled",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--enabled true` or `--enabled false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-enabled"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--enabled", enabled ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-enabled",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserFocus() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let focused = option("--focused")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-focus.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-focus.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let focused {
            do {
                _ = try browserFocusedValue(focused)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserFocused",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--focused true` or `--focused false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-focus"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--focused", focused ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-focus",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserAttribute() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let attribute = option("--attribute")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-attribute.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-attribute.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let attribute {
            do {
                _ = try validatedBrowserAttributeName(attribute)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserAttribute",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a safe attribute name such as `aria-expanded`, `data-state`, `href`, or `class`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserAttribute",
                status: "fail",
                required: true,
                message: "No attribute name was provided for wait-browser-attribute.",
                remediation: "Pass `--attribute NAME` for the target element attribute."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected attribute text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected attribute text was provided for wait-browser-attribute.",
                remediation: "Pass `--text TEXT` for the expected attribute value."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserAttributeMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let attribute, let text {
            var arguments = ["Ln1", "browser", "wait-attribute"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--attribute", attribute,
                "--text", text,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-attribute",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightDuplicateFile() throws -> WorkflowPreflight {
        try workflowPreflightCopyLikeFile(
            workflowOperation: "duplicate-file",
            fileOperation: "duplicate",
            fileCommand: "duplicate",
            missingSourceMessage: "No source path was provided for duplicate-file.",
            missingDestinationMessage: "No destination path was provided for duplicate-file.",
            blockedRemediation: "Resolve filesystem preflight check %@ before duplicating."
        )
    }

    private func workflowPreflightCreateDirectory() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.directoryPath",
                status: "fail",
                required: true,
                message: "No directory path was provided for create-directory.",
                remediation: "Pass `--path DIRECTORY`."
            ))
        }

        if path != nil {
            let preflight = try fileOperationPreflight(operation: "mkdir")
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : "Resolve filesystem preflight check \(check.name) before creating the directory."
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "mkdir",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if let path {
            let arguments = [
                "Ln1", "files", "plan",
                "--operation", "mkdir",
                "--path", path,
                "--allow-risk", "medium"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "create-directory",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightMoveFile() throws -> WorkflowPreflight {
        try workflowPreflightCopyLikeFile(
            workflowOperation: "move-file",
            fileOperation: "move",
            fileCommand: "move",
            missingSourceMessage: "No source path was provided for move-file.",
            missingDestinationMessage: "No destination path was provided for move-file.",
            blockedRemediation: "Resolve filesystem preflight check %@ before moving."
        )
    }

    private func workflowPreflightRollbackFileMove() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let auditID = option("--audit-id")
        if auditID == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.auditID",
                status: "fail",
                required: true,
                message: "No move audit ID was provided for rollback-file-move.",
                remediation: "Pass `--audit-id AUDIT_ID` from a successful files.move audit record."
            ))
        }

        if auditID != nil {
            let preflight = try fileOperationPreflight(operation: "rollback")
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : "Resolve filesystem preflight check \(check.name) before rolling back the move."
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let auditID {
            var arguments = [
                "Ln1", "files", "rollback",
                "--audit-id", auditID,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if let auditID {
            var arguments = [
                "Ln1", "files", "plan",
                "--operation", "rollback",
                "--audit-id", auditID,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "rollback-file-move",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if !FileManager.default.fileExists(atPath: expandedURL.path) {
                prerequisites.append(DoctorCheck(
                    name: "workflow.inspectPath",
                    status: "fail",
                    required: true,
                    message: "File path does not exist at \(expandedURL.path).",
                    remediation: "Pass an existing file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for inspect-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            nextArguments = [
                "Ln1", "files", "stat",
                "--path", path
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFile() -> WorkflowPreflight {
        workflowPreflightFileText(
            operation: "read-file",
            command: "read-text",
            supportDescription: "read-file",
            missingPathMessage: "No path was provided for read-file.",
            reason: "Inspect file text"
        )
    }

    private func workflowPreflightTailFile() -> WorkflowPreflight {
        workflowPreflightFileText(
            operation: "tail-file",
            command: "tail-text",
            supportDescription: "tail-file",
            missingPathMessage: "No path was provided for tail-file.",
            reason: "Inspect file tail text"
        )
    }

    private func workflowPreflightReadFileLines() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        var startLine = 1
        var lineCount = 80
        var maxLineCharacters = 240
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawStartLine = option("--start-line") {
            if let parsed = Int(rawStartLine) {
                startLine = max(1, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileStartLine",
                    status: "fail",
                    required: true,
                    message: "--start-line must be an integer.",
                    remediation: "Pass a positive integer with `--start-line N`."
                ))
            }
        }

        if let rawLineCount = option("--line-count") {
            if let parsed = Int(rawLineCount) {
                lineCount = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileLineCount",
                    status: "fail",
                    required: true,
                    message: "--line-count must be an integer.",
                    remediation: "Pass a non-negative integer with `--line-count N`."
                ))
            }
        }

        if let rawMaxLineCharacters = option("--max-line-characters") {
            if let parsed = Int(rawMaxLineCharacters) {
                maxLineCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxLineCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-line-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-line-characters N`."
                ))
            }
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-lines supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-lines.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-lines",
                "--path", path,
                "--allow-risk", "medium",
                "--start-line", String(startLine),
                "--line-count", String(lineCount),
                "--max-line-characters", String(maxLineCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect file line range"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-lines",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFileJSON() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let pointer = option("--pointer")
        var maxDepth = 4
        var maxItems = 50
        var maxStringCharacters = 1_024
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxDepth = option("--max-depth") {
            if let parsed = Int(rawMaxDepth) {
                maxDepth = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxDepth",
                    status: "fail",
                    required: true,
                    message: "--max-depth must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-depth N`."
                ))
            }
        }

        if let rawMaxItems = option("--max-items") {
            if let parsed = Int(rawMaxItems) {
                maxItems = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxItems",
                    status: "fail",
                    required: true,
                    message: "--max-items must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-items N`."
                ))
            }
        }

        if let rawMaxStringCharacters = option("--max-string-characters") {
            if let parsed = Int(rawMaxStringCharacters) {
                maxStringCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxStringCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-string-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-string-characters N`."
                ))
            }
        }

        if let rawPointer = pointer, !rawPointer.isEmpty, !rawPointer.hasPrefix("/") {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileJSONPointer",
                status: "fail",
                required: true,
                message: "--pointer must be an empty string or a JSON Pointer starting with '/'.",
                remediation: "Pass a valid JSON Pointer such as `/items/0`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-json supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 JSON file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 JSON file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-json.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-json",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let pointer {
                arguments += ["--pointer", pointer]
            }
            arguments += [
                "--max-depth", String(maxDepth),
                "--max-items", String(maxItems),
                "--max-string-characters", String(maxStringCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect JSON file value"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-json",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFilePropertyList() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let pointer = option("--pointer")
        var maxDepth = 4
        var maxItems = 50
        var maxStringCharacters = 1_024
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxDepth = option("--max-depth") {
            if let parsed = Int(rawMaxDepth) {
                maxDepth = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxDepth",
                    status: "fail",
                    required: true,
                    message: "--max-depth must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-depth N`."
                ))
            }
        }

        if let rawMaxItems = option("--max-items") {
            if let parsed = Int(rawMaxItems) {
                maxItems = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxItems",
                    status: "fail",
                    required: true,
                    message: "--max-items must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-items N`."
                ))
            }
        }

        if let rawMaxStringCharacters = option("--max-string-characters") {
            if let parsed = Int(rawMaxStringCharacters) {
                maxStringCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxStringCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-string-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-string-characters N`."
                ))
            }
        }

        if let rawPointer = pointer, !rawPointer.isEmpty, !rawPointer.hasPrefix("/") {
            prerequisites.append(DoctorCheck(
                name: "workflow.filePropertyListPointer",
                status: "fail",
                required: true,
                message: "--pointer must be an empty string or a pointer starting with '/'.",
                remediation: "Pass a valid pointer such as `/items/0`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-plist supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular property list file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular property list file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-plist.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-plist",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let pointer {
                arguments += ["--pointer", pointer]
            }
            arguments += [
                "--max-depth", String(maxDepth),
                "--max-items", String(maxItems),
                "--max-string-characters", String(maxStringCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect property list file value"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-plist",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightFileText(
        operation: String,
        command: String,
        supportDescription: String,
        missingPathMessage: String,
        reason: String
    ) -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        var maxCharacters = 16_384
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxCharacters = option("--max-characters") {
            if let parsed = Int(rawMaxCharacters) {
                maxCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-characters N`."
                ))
            }
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "\(supportDescription) supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: missingPathMessage,
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", command,
                "--path", path,
                "--allow-risk", "medium",
                "--max-characters", String(maxCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", reason
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: operation,
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWriteFile() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        let text = option("--text")
        let overwrite = flag("--overwrite")

        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for write-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        if text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.text",
                status: "fail",
                required: true,
                message: "No text was provided for write-file.",
                remediation: "Pass `--text TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            let parentURL = expandedURL.deletingLastPathComponent()
            prerequisites.append(directoryExistsDoctorCheck(name: "workflow.destinationParentExists", url: parentURL))
            prerequisites.append(writableDirectoryDoctorCheck(name: "workflow.destinationParentWritable", url: parentURL))

            if FileManager.default.fileExists(atPath: expandedURL.path) {
                do {
                    let record = try fileRecord(for: expandedURL)
                    if !overwrite {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationOverwrite",
                            status: "fail",
                            required: true,
                            message: "Destination already exists at \(expandedURL.path).",
                            remediation: "Pass `--overwrite` only when replacing the existing file is intended."
                        ))
                    }
                    if record.kind != "regularFile" {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationRegularFile",
                            status: "fail",
                            required: true,
                            message: "write-file can overwrite regular files only; \(expandedURL.path) is \(record.kind).",
                            remediation: "Choose a regular file path or a missing path."
                        ))
                    }
                    if !record.writable {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationWritable",
                            status: "fail",
                            required: true,
                            message: "Destination file is not writable at \(expandedURL.path).",
                            remediation: "Choose a writable file or adjust filesystem permissions."
                        ))
                    }
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationReadable",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Choose a writable regular file or a missing path."
                    ))
                }
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let text {
            var arguments = [
                "Ln1", "files", "write-text",
                "--path", path,
                "--text", text,
                "--allow-risk", "medium"
            ]
            if overwrite {
                arguments.append("--overwrite")
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "write-file",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightAppendFile() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        let text = option("--text")
        let create = flag("--create")

        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for append-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        if text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.text",
                status: "fail",
                required: true,
                message: "No text was provided for append-file.",
                remediation: "Pass `--text TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if FileManager.default.fileExists(atPath: expandedURL.path) {
                do {
                    let record = try fileRecord(for: expandedURL)
                    if record.kind != "regularFile" {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationRegularFile",
                            status: "fail",
                            required: true,
                            message: "append-file supports regular files only; \(expandedURL.path) is \(record.kind).",
                            remediation: "Choose a writable regular file or a missing path with `--create`."
                        ))
                    }
                    if !record.writable {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationWritable",
                            status: "fail",
                            required: true,
                            message: "Destination file is not writable at \(expandedURL.path).",
                            remediation: "Choose a writable file or adjust filesystem permissions."
                        ))
                    }
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationReadable",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Choose a writable regular file or a missing path with `--create`."
                    ))
                }
            } else {
                if !create {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationCreate",
                        status: "fail",
                        required: true,
                        message: "Destination does not exist at \(expandedURL.path).",
                        remediation: "Pass `--create` only when creating the file before appending is intended."
                    ))
                }
                let parentURL = expandedURL.deletingLastPathComponent()
                prerequisites.append(directoryExistsDoctorCheck(name: "workflow.destinationParentExists", url: parentURL))
                prerequisites.append(writableDirectoryDoctorCheck(name: "workflow.destinationParentWritable", url: parentURL))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let text {
            var arguments = [
                "Ln1", "files", "append-text",
                "--path", path,
                "--text", text,
                "--allow-risk", "medium"
            ]
            if create {
                arguments.append("--create")
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "append-file",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightListFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "directory" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.listDirectory",
                        status: "fail",
                        required: true,
                        message: "list-files requires a directory; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a directory with `--path PATH`, or use `inspect-file` for one file."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.listReadable",
                        status: "fail",
                        required: true,
                        message: "Directory is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable directory or adjust filesystem permissions."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.listPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing readable directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for list-files.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "list",
                "--path", path,
                "--depth", String(maxDepth),
                "--limit", String(limit)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "list-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightSearchFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let query = option("--query")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 4)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
        let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 1_048_576)
        let maxSnippetCharacters = max(20, option("--max-snippet-characters").flatMap(Int.init) ?? 240)
        let maxMatchesPerFile = max(1, option("--max-matches-per-file").flatMap(Int.init) ?? 20)

        if let query {
            if query.isEmpty {
                prerequisites.append(DoctorCheck(
                    name: "workflow.searchQuery",
                    status: "fail",
                    required: true,
                    message: "search-files requires a non-empty query.",
                    remediation: "Pass non-empty text with `--query TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.searchQuery",
                status: "fail",
                required: true,
                message: "No query was provided for search-files.",
                remediation: "Pass `--query TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.searchReadable",
                        status: "fail",
                        required: true,
                        message: "Search root is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or directory, or adjust filesystem permissions."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.searchPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing readable file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for search-files.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let query {
            var arguments = [
                "Ln1", "files", "search",
                "--path", path,
                "--query", query,
                "--depth", String(maxDepth),
                "--limit", String(limit),
                "--max-file-bytes", String(maxFileBytes),
                "--max-snippet-characters", String(maxSnippetCharacters),
                "--max-matches-per-file", String(maxMatchesPerFile)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            if flag("--case-sensitive") {
                arguments.append("--case-sensitive")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "search-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWatchFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let limit = max(1, option("--limit").flatMap(Int.init) ?? 200)
        let watchTimeoutMilliseconds = max(0, option("--watch-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if !FileManager.default.fileExists(atPath: expandedURL.path) {
                prerequisites.append(DoctorCheck(
                    name: "workflow.watchRoot",
                    status: "fail",
                    required: true,
                    message: "Watch root does not exist at \(expandedURL.path).",
                    remediation: "Pass an existing file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for watch-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "watch",
                "--path", path,
                "--depth", String(maxDepth),
                "--limit", String(limit),
                "--timeout-ms", String(watchTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "watch-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightChecksumFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let algorithm = option("--algorithm") ?? "sha256"
        var normalizedAlgorithm = "sha256"
        var maxFileBytes = 104_857_600
        var parsedMaxFileBytes = true

        do {
            normalizedAlgorithm = try normalizedChecksumAlgorithm(algorithm)
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigestAlgorithm",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Use `--algorithm sha256`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumRegularFile",
                        status: "fail",
                        required: true,
                        message: "checksum-file supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.checksumPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for checksum-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            nextArguments = [
                "Ln1", "files", "checksum",
                "--path", path,
                "--algorithm", normalizedAlgorithm,
                "--max-file-bytes", String(maxFileBytes)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "checksum-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightCompareFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let leftPath = option("--path")
        let rightPath = option("--to")
        let algorithm = option("--algorithm") ?? "sha256"
        var normalizedAlgorithm = "sha256"
        var maxFileBytes = 104_857_600
        var parsedMaxFileBytes = true

        do {
            normalizedAlgorithm = try normalizedChecksumAlgorithm(algorithm)
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigestAlgorithm",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Use `--algorithm sha256`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        workflowAppendComparableFileChecks(
            path: leftPath,
            role: "left",
            missingName: "workflow.leftPath",
            missingMessage: "No left path was provided for compare-files.",
            maxFileBytes: maxFileBytes,
            parsedMaxFileBytes: parsedMaxFileBytes,
            prerequisites: &prerequisites
        )
        workflowAppendComparableFileChecks(
            path: rightPath,
            role: "right",
            missingName: "workflow.rightPath",
            missingMessage: "No right path was provided for compare-files.",
            maxFileBytes: maxFileBytes,
            parsedMaxFileBytes: parsedMaxFileBytes,
            prerequisites: &prerequisites
        )

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let leftPath, let rightPath {
            nextArguments = [
                "Ln1", "files", "compare",
                "--path", leftPath,
                "--to", rightPath,
                "--algorithm", normalizedAlgorithm,
                "--max-file-bytes", String(maxFileBytes)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "compare-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowAppendComparableFileChecks(
        path: String?,
        role: String,
        missingName: String,
        missingMessage: String,
        maxFileBytes: Int,
        parsedMaxFileBytes: Bool,
        prerequisites: inout [DoctorCheck]
    ) {
        guard let path else {
            prerequisites.append(DoctorCheck(
                name: missingName,
                status: "fail",
                required: true,
                message: missingMessage,
                remediation: "Pass `--path LEFT` and `--to RIGHT`."
            ))
            return
        }

        let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
        do {
            let record = try fileRecord(for: expandedURL)
            if record.kind != "regularFile" {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)RegularFile",
                    status: "fail",
                    required: true,
                    message: "compare-files supports regular files only; \(expandedURL.path) is \(record.kind).",
                    remediation: "Pass a regular file for the \(role) path."
                ))
            }
            if !record.readable {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)Readable",
                    status: "fail",
                    required: true,
                    message: "The \(role) file is not readable at \(expandedURL.path).",
                    remediation: "Choose a readable file or adjust filesystem permissions."
                ))
            }
            if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)MaxBytes",
                    status: "fail",
                    required: true,
                    message: "The \(role) file size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                    remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                ))
            }
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.\(role)Path",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Pass an existing regular file for the \(role) path."
            ))
        }
    }

    private func workflowPreflightCopyLikeFile(
        workflowOperation: String,
        fileOperation: String,
        fileCommand: String,
        missingSourceMessage: String,
        missingDestinationMessage: String,
        blockedRemediation: String
    ) throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let sourcePath = option("--path")
        let destinationPath = option("--to")
        if sourcePath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.sourcePath",
                status: "fail",
                required: true,
                message: missingSourceMessage,
                remediation: "Pass `--path SOURCE`."
            ))
        }
        if destinationPath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.destinationPath",
                status: "fail",
                required: true,
                message: missingDestinationMessage,
                remediation: "Pass `--to DESTINATION`."
            ))
        }

        if sourcePath != nil, destinationPath != nil {
            let preflight = try fileOperationPreflight(operation: fileOperation)
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : String(format: blockedRemediation, check.name)
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let sourcePath, let destinationPath {
            var arguments = [
                "Ln1", "files", fileCommand,
                "--path", sourcePath,
                "--to", destinationPath,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if sourcePath != nil, destinationPath != nil {
            let arguments = [
                "Ln1", "files", "plan",
                "--operation", fileOperation,
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
            operation: workflowOperation,
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
        let expectedExists = option("--exists").map(parseBool) ?? true
        let expectedSizeBytes = option("--size-bytes")
        let expectedDigest = option("--digest")
        let algorithm = option("--algorithm")
        let maxFileBytes = option("--max-file-bytes")
        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for wait-file.",
                remediation: "Pass `--path PATH`."
            ))
        }
        if let expectedSizeBytes {
            do {
                _ = try fileExpectedSizeBytes(expectedSizeBytes)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileSize",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--size-bytes N`."
                ))
            }
        }
        if let expectedDigest, !isSHA256HexDigest(expectedDigest) {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigest",
                status: "fail",
                required: true,
                message: "file digest must be a 64-character SHA-256 hex digest",
                remediation: "Pass a digest from `Ln1 files checksum --path PATH` with `--digest HEX`."
            ))
        }
        if let algorithm {
            do {
                _ = try normalizedChecksumAlgorithm(algorithm)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileDigestAlgorithm",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--algorithm sha256`."
                ))
            }
        }
        if let maxFileBytes {
            do {
                _ = try fileMaxBytes(maxFileBytes, optionName: "--max-file-bytes")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }
        if expectedExists == false && (expectedSizeBytes != nil || expectedDigest != nil) {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileMetadataExpectation",
                status: "fail",
                required: true,
                message: "wait-file cannot verify size or digest while expecting the path to be missing.",
                remediation: "Use `--exists true` with metadata expectations, or remove `--size-bytes` and `--digest`."
            ))
        }

        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "wait",
                "--path", path,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            if let expectedSizeBytes {
                arguments += ["--size-bytes", expectedSizeBytes]
            }
            if let expectedDigest {
                arguments += ["--digest", expectedDigest.lowercased()]
                arguments += ["--algorithm", algorithm ?? "sha256"]
                if let maxFileBytes {
                    arguments += ["--max-file-bytes", maxFileBytes]
                }
            }
            nextArguments = arguments
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

    private func workflowPreflightWaitClipboard() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let changedFrom = option("--changed-from")
        let hasString = option("--has-string")
        let stringDigest = option("--string-digest")

        if changedFrom == nil && hasString == nil && stringDigest == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardExpectation",
                status: "fail",
                required: true,
                message: "No clipboard wait expectation was provided.",
                remediation: "Pass `--changed-from N`, `--has-string true|false`, or `--string-digest SHA256`."
            ))
        }
        if let changedFrom, Int(changedFrom) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardChangeCount",
                status: "fail",
                required: true,
                message: "Clipboard changed-from value must be an integer.",
                remediation: "Pass the previous clipboard change count with `--changed-from N`."
            ))
        }
        if let hasString {
            do {
                _ = try booleanOption(hasString, optionName: "--has-string")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.clipboardHasString",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--has-string true` or `--has-string false`."
                ))
            }
        }
        if let stringDigest, !isSHA256HexDigest(stringDigest) {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardDigest",
                status: "fail",
                required: true,
                message: "Clipboard string digest must be a 64-character SHA-256 hex digest.",
                remediation: "Pass a digest from `Ln1 clipboard state` with `--string-digest HEX`."
            ))
        }

        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = ["Ln1", "clipboard", "wait"]
            if let pasteboard = option("--pasteboard") {
                arguments += ["--pasteboard", pasteboard]
            }
            if let changedFrom {
                arguments += ["--changed-from", changedFrom]
            }
            if let hasString {
                arguments += ["--has-string", hasString]
            }
            if let stringDigest {
                arguments += ["--string-digest", stringDigest.lowercased()]
            }
            arguments += [
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-clipboard",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectClipboard() -> WorkflowPreflight {
        var arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard = option("--pasteboard") {
            arguments += ["--pasteboard", pasteboard]
        }

        return workflowPreflightResult(
            operation: "inspect-clipboard",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightReadClipboard() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        var maxCharacters = 4_096

        if let rawMaxCharacters = option("--max-characters") {
            if let parsed = Int(rawMaxCharacters) {
                maxCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.clipboardMaxCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-characters N`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "clipboard", "read-text",
                "--allow-risk", "medium",
                "--max-characters", String(maxCharacters),
                "--reason", "Inspect clipboard text"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            if let pasteboard = option("--pasteboard") {
                arguments += ["--pasteboard", pasteboard]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-clipboard",
            risk: "medium",
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
            let nextArguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
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
                    "Ln1", "workflow", "log",
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
        let latestOperation = latest["operation"] as? String
        guard let execution = latest["execution"] as? [String: Any],
              let outputJSON = execution["outputJSON"] as? [String: Any] else {
            return nil
        }

        let endpoint = outputJSON["endpoint"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--endpoint")
            ?? "http://127.0.0.1:9222"

        if latestOperation == "wait-browser-url" {
            return workflowBrowserURLWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-selector" {
            return workflowBrowserSelectorWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-count" {
            return workflowBrowserCountWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-text" {
            return workflowBrowserTextWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-element-text" {
            return workflowBrowserElementTextWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-value" {
            return workflowBrowserValueWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-ready" {
            return workflowBrowserReadyWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-title" {
            return workflowBrowserTitleWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-checked" {
            return workflowBrowserCheckedWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-enabled" {
            return workflowBrowserEnabledWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-focus" {
            return workflowBrowserFocusWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-attribute" {
            return workflowBrowserAttributeWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-element" {
            return workflowAccessibilityElementInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-menu" {
            return workflowAccessibilityMenuInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "create-directory" {
            return workflowCreateDirectoryRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "duplicate-file" {
            return workflowDestinationFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file duplicate completed and verified; inspect destination metadata before further file operations."
            )
        }
        if latestOperation == "move-file" {
            return workflowDestinationFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file move completed and verified; inspect destination metadata before further file operations."
            )
        }
        if latestOperation == "rollback-file-move" {
            return workflowRollbackFileMoveRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-file" {
            return workflowFileInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "read-file" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file text read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "tail-file" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file tail text read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-lines" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file line range read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-json" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest JSON file read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-plist" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest property list file read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "write-file" {
            return workflowWrittenFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file text write completed and verified; inspect current metadata before further file operations."
            )
        }
        if latestOperation == "append-file" {
            return workflowWrittenFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file text append completed and verified; inspect current metadata before further file operations."
            )
        }
        if latestOperation == "list-files" {
            return workflowFileListRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "search-files" {
            return workflowFileSearchRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "checksum-file" {
            return workflowFileChecksumRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "compare-files" {
            return workflowFileCompareRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "watch-file" {
            return workflowFileWatchRecommendation(outputJSON: outputJSON)
        }
        if latestOperation == "wait-file" {
            return workflowFileWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "wait-clipboard" {
            return workflowClipboardWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-process" {
            return workflowProcessWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-window" {
            return workflowWindowWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-element" {
            return workflowAccessibilityElementWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-system" {
            let arguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
            return (
                arguments,
                "Latest system context inspection completed; observe current app, process, and desktop state before choosing the next action."
            )
        }
        if latestOperation == "inspect-displays" {
            let arguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
            return (
                arguments,
                "Latest display topology inspection completed; observe current app, process, and desktop state before choosing the next action."
            )
        }
        if latestOperation == "wait-active-app" {
            return workflowActiveAppWaitRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-clipboard" {
            return workflowClipboardInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "read-clipboard" {
            return workflowClipboardReadRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-process" {
            return workflowProcessInspectRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "activate-app" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest app activation completed and verified; dry-run active app inspection before choosing the next UI action."
            )
        }

        guard latestOperation == "read-browser" else {
            return nil
        }

        if let domRecommendation = workflowBrowserDOMRecommendation(
            outputJSON: outputJSON,
            execution: execution,
            endpoint: endpoint
        ) {
            return domRecommendation
        }

        guard
              let tabs = outputJSON["tabs"] as? [[String: Any]],
              let firstTab = tabs.first,
              let tabID = firstTab["id"] as? String else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
        )
    }

    private func workflowFileInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let root = outputJSON["root"] as? [String: Any],
              let path = root["path"] as? String
                ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        if root["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file inspection found a directory; list immediate children before acting."
            )
        }

        if root["kind"] as? String == "regularFile", root["readable"] as? Bool == true {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "checksum-file",
                    "--path", path,
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest file inspection found a readable file; dry-run a checksum workflow before depending on contents."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file inspection completed; re-check metadata before choosing a mutating operation."
        )
    }

    private func workflowFileListRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let entries = outputJSON["entries"] as? [[String: Any]]
        let root = outputJSON["root"] as? [String: Any]
        let selectedPath = entries?.first?["path"] as? String
            ?? root?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path")
        guard let selectedPath else {
            return nil
        }

        let message = entries?.isEmpty == false
            ? "Latest file listing completed; dry-run inspection for the first listed path."
            : "Latest file listing was empty; dry-run inspection for the listed directory."
        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-file",
                "--path", selectedPath,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: message
        )
    }

    private func workflowFileReadRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL,
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        let file = outputJSON["file"] as? [String: Any]
        guard let path = file?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "checksum-file",
                "--path", path,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: successMessage
        )
    }

    private func workflowWrittenFileRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let current = outputJSON["current"] as? [String: Any]
        guard let path = current?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: successMessage
        )
    }

    private func workflowFileSearchRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let matches = outputJSON["matches"] as? [[String: Any]]
        let firstFile = matches?.first?["file"] as? [String: Any]
        let root = outputJSON["root"] as? [String: Any]
        guard let selectedPath = firstFile?["path"] as? String
            ?? root?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-file",
                "--path", selectedPath,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: matches?.isEmpty == false
                ? "Latest file search completed; dry-run inspection for the first matched file."
                : "Latest file search found no matches; dry-run inspection for the search root."
        )
    }

    private func workflowFileChecksumRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let file = outputJSON["file"] as? [String: Any]
        guard let path = file?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path"),
              let digest = outputJSON["digest"] as? String,
              isSHA256HexDigest(digest) else {
            return nil
        }

        let algorithm = outputJSON["algorithm"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--algorithm")
            ?? "sha256"
        let maxFileBytes = (outputJSON["maxFileBytes"] as? Int).map(String.init)
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--max-file-bytes")
            ?? "104857600"

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "wait-file",
                "--path", path,
                "--exists", "true",
                "--digest", digest.lowercased(),
                "--algorithm", algorithm,
                "--max-file-bytes", maxFileBytes,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest file checksum completed; dry-run a digest wait before depending on this file state."
        )
    }

    private func workflowFileCompareRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let right = outputJSON["right"] as? [String: Any]
        guard let rightPath = right?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--to") else {
            return nil
        }

        let matched = outputJSON["matched"] as? Bool == true
        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", rightPath
            ],
            message: matched
                ? "Latest file compare matched; inspect right-side metadata before depending on the file."
                : "Latest file compare found a difference; inspect right-side metadata before choosing the next file operation."
        )
    }

    private func workflowFileWatchRecommendation(
        outputJSON: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["matched"] as? Bool == true,
              let events = outputJSON["events"] as? [[String: Any]],
              let event = events.first,
              let eventType = event["type"] as? String,
              let path = event["path"] as? String else {
            return nil
        }

        if eventType == "deleted" {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", parent,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file watch observed a deletion; list the parent directory before choosing the next file operation."
            )
        }

        let current = event["current"] as? [String: Any]
        if current?["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file watch observed a directory event; list immediate children before acting."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file watch observed a file event; inspect current metadata before acting."
        )
    }

    private func workflowRollbackFileMoveRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let restoredSource = outputJSON["restoredSource"] as? [String: Any]
        guard let restoredPath = restoredSource?["path"] as? String else {
            return nil
        }
        let arguments = [
            "Ln1", "files", "stat",
            "--path", restoredPath
        ]

        return (
            arguments: arguments,
            message: "Latest file move rollback completed and verified; inspect restored source metadata before further file operations."
        )
    }

    private func workflowCreateDirectoryRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let directory = outputJSON["directory"] as? [String: Any]
        guard let directoryPath = directory?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", directoryPath
            ],
            message: "Latest directory creation completed and verified; inspect directory metadata before further file operations."
        )
    }

    private func workflowDestinationFileRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let destination = outputJSON["destination"] as? [String: Any]
        guard let destinationPath = destination?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--to") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", destinationPath
            ],
            message: successMessage
        )
    }

    private func workflowFileWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["matched"] as? Bool == true else {
            return nil
        }
        guard let path = outputJSON["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        let expectedExists = outputJSON["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true

        if !expectedExists {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", parent,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file wait confirmed the path is absent; list the parent directory to choose the next file operation."
            )
        }

        let file = outputJSON["file"] as? [String: Any]
        if file?["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file wait found the expected directory; list immediate children before acting."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file wait found the expected path and metadata; inspect current file metadata before acting."
        )
    }

    private func workflowClipboardInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let pasteboard = outputJSON["pasteboard"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        let hasString = outputJSON["hasString"] as? Bool

        if hasString == true {
            var arguments = [
                "Ln1", "workflow", "run",
                "--operation", "read-clipboard",
                "--max-characters", "4096",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            if let pasteboard, pasteboard != "general" {
                arguments += ["--pasteboard", pasteboard]
            }
            return (
                arguments: arguments,
                message: "Latest clipboard inspection found plain text metadata; dry-run bounded clipboard text reading before using clipboard contents."
            )
        }

        var arguments = [
            "Ln1", "clipboard", "wait",
            "--has-string", "true",
            "--timeout-ms", "5000",
            "--interval-ms", "100"
        ]
        if let changeCount = outputJSON["changeCount"] as? Int {
            arguments += ["--changed-from", String(changeCount)]
        }
        if let pasteboard, pasteboard != "general" {
            arguments += ["--pasteboard", pasteboard]
        }
        return (
            arguments: arguments,
            message: "Latest clipboard inspection found no plain text; wait for text metadata before reading."
        )
    }

    private func workflowClipboardWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        let pasteboard = workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        let current = verification["current"] as? [String: Any]
        let hasString = current?["hasString"] as? Bool
        var arguments: [String]

        if hasString == true {
            arguments = [
                "Ln1", "workflow", "run",
                "--operation", "read-clipboard",
                "--max-characters", "4096",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            if let pasteboard {
                arguments.append(contentsOf: ["--pasteboard", pasteboard])
            }
            return (
                arguments: arguments,
                message: "Latest clipboard wait found plain text metadata; dry-run bounded clipboard text reading before using clipboard contents."
            )
        }

        arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard {
            arguments.append(contentsOf: ["--pasteboard", pasteboard])
        }
        return (
            arguments: arguments,
            message: "Latest clipboard wait completed without plain text; inspect clipboard metadata before choosing the next operation."
        )
    }

    private func workflowClipboardReadRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let pasteboard = outputJSON["pasteboard"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        var arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard, pasteboard != "general" {
            arguments += ["--pasteboard", pasteboard]
        }
        return (
            arguments: arguments,
            message: "Latest clipboard text read completed; inspect clipboard metadata before depending on unchanged contents."
        )
    }

    private func workflowBrowserURLWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let verification = outputJSON["verification"] as? [String: Any]
        guard verification?["ok"] as? Bool == true else {
            return nil
        }

        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser URL wait completed; dry-run DOM inspection for the arrived page."
        )
    }

    private func workflowBrowserSelectorWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }
        guard let selector = outputJSON["selector"] as? String
            ?? verification["selector"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--selector") else {
            return nil
        }

        if workflowSelectorWaitAcceptsText(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "fill",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--text", "Describe text",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready text field; fill it by selector after replacing the text and reason."
            )
        }

        if workflowSelectorWaitAcceptsSelect(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "select",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--value", "Describe value",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready select control; choose an option by value after replacing the value and reason."
            )
        }

        if workflowSelectorWaitAcceptsCheckedState(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "check",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--checked", "true",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready checkbox or radio input; set its checked state after confirming intent."
            )
        }

        if workflowSelectorWaitCanClick(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "click",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready actionable element; click it by selector after confirming intent."
            )
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser selector wait completed; dry-run DOM inspection to choose the next action."
        )
    }

    private func workflowBrowserCountWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser count wait completed; dry-run DOM inspection for the matched collection state."
        )
    }

    private func workflowBrowserTextWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser text wait completed; dry-run DOM inspection for the matched page state."
        )
    }

    private func workflowBrowserElementTextWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser element text wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowBrowserValueWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser value wait completed; dry-run DOM inspection for the matched field state."
        )
    }

    private func workflowBrowserReadyWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser ready-state wait completed; dry-run DOM inspection for the loaded page state."
        )
    }

    private func workflowBrowserTitleWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser title wait completed; dry-run DOM inspection for the matched page."
        )
    }

    private func workflowBrowserCheckedWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser checked-state wait completed; dry-run DOM inspection for the matched form state."
        )
    }

    private func workflowBrowserEnabledWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }
        guard let selector = outputJSON["selector"] as? String
            ?? verification["selector"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--selector") else {
            return nil
        }

        if verification["currentEnabled"] as? Bool == true {
            if workflowSelectorWaitAcceptsText(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "fill",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--text", "Describe text",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled text field; fill it by selector after replacing the text and reason."
                )
            }

            if workflowSelectorWaitAcceptsSelect(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "select",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--value", "Describe value",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled select control; choose an option by value after replacing the value and reason."
                )
            }

            if workflowSelectorWaitAcceptsCheckedState(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "check",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--checked", "true",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled checkbox or radio input; set its checked state after confirming intent."
                )
            }

            if workflowSelectorWaitCanClick(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "click",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled actionable element; click it by selector after confirming intent."
                )
            }
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser enabled-state wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowBrowserFocusWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser focus wait completed; dry-run DOM inspection for the focused element state."
        )
    }

    private func workflowBrowserAttributeWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser attribute wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowProcessInspectRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["found"] as? Bool == true,
              let process = outputJSON["process"] as? [String: Any] else {
            return (
                ["Ln1", "processes", "--limit", "50"],
                "Latest process inspection found no process; list current process metadata before choosing the next step."
            )
        }

        if process["activeApp"] as? Bool == true {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest process inspection is the active app process; dry-run active app inspection before choosing a UI action."
            )
        }

        if let bundleIdentifier = process["bundleIdentifier"] as? String {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "activate-app",
                "--bundle-id", bundleIdentifier,
                "--allow-risk", "medium",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest process inspection found a GUI app process; dry-run activation before inspecting or controlling it."
            )
        }

        return (
            ["Ln1", "processes", "--limit", "50"],
            "Latest process inspection completed; list process metadata before selecting another structured action."
        )
    }

    private func workflowProcessWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any] else {
            return nil
        }

        let pid = verification["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true
        let matched = verification["matched"] as? Bool == true
        let ok = verification["ok"] as? Bool == true

        if ok, matched, expectedExists, let pid {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(pid),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest process wait confirmed the pid exists; dry-run process inspection before choosing the next app or process action."
            )
        }

        if ok, matched, !expectedExists {
            return (
                arguments: ["Ln1", "processes", "--limit", "50"],
                message: "Latest process wait confirmed the pid is absent; list current process metadata before choosing the next step."
            )
        }

        if let pid {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "wait-process",
                    "--pid", String(pid),
                    "--exists", String(expectedExists),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest process wait completed without matching; dry-run another bounded wait before retrying."
            )
        }

        return nil
    }

    private func workflowWindowWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any] else {
            return nil
        }

        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true
        let matched = verification["matched"] as? Bool == true
        let ok = verification["ok"] as? Bool == true
        let current = verification["current"] as? [[String: Any]] ?? []

        if ok, matched, expectedExists, let window = current.first {
            if window["active"] as? Bool == true {
                return (
                    arguments: [
                        "Ln1", "workflow", "run",
                        "--operation", "inspect-active-app",
                        "--dry-run", "true",
                        "--workflow-log", workflowURL.path
                    ],
                    message: "Latest desktop window wait found a window owned by the active app; dry-run active app inspection before choosing a UI action."
                )
            }

            if let ownerPID = window["ownerPID"] as? Int {
                return (
                    arguments: [
                        "Ln1", "workflow", "run",
                        "--operation", "inspect-process",
                        "--pid", String(ownerPID),
                        "--dry-run", "true",
                        "--workflow-log", workflowURL.path
                    ],
                    message: "Latest desktop window wait found a visible window; dry-run owner process inspection before choosing the next app or UI action."
                )
            }
        }

        if ok, matched, !expectedExists {
            return (
                arguments: ["Ln1", "desktop", "windows", "--limit", "50"],
                message: "Latest desktop window wait confirmed the matching window is absent; list current desktop windows before choosing the next step."
            )
        }

        let retryArguments = workflowWindowWaitRetryArguments(from: execution["argv"] as? [String], workflowURL: workflowURL)
        if let retryArguments {
            return (
                arguments: retryArguments,
                message: "Latest desktop window wait completed without matching; dry-run another bounded wait before retrying."
            )
        }

        return (
            arguments: ["Ln1", "desktop", "windows", "--limit", "50"],
            message: "Latest desktop window wait completed; list current desktop windows before choosing the next step."
        )
    }

    private func workflowWindowWaitRetryArguments(from arguments: [String]?, workflowURL: URL) -> [String]? {
        guard let arguments else {
            return nil
        }

        var retry = ["Ln1", "workflow", "run", "--operation", "wait-window"]
        for optionName in ["--id", "--owner-pid", "--bundle-id", "--title", "--match", "--exists", "--limit"] {
            guard let value = workflowArgumentValue(in: arguments, for: optionName) else {
                continue
            }
            retry += [optionName, value]
        }
        if let timeout = workflowArgumentValue(in: arguments, for: "--timeout-ms") {
            retry += ["--wait-timeout-ms", timeout]
        }
        if let interval = workflowArgumentValue(in: arguments, for: "--interval-ms") {
            retry += ["--interval-ms", interval]
        }
        if arguments.contains("--include-desktop") {
            retry.append("--include-desktop")
        }
        if arguments.contains("--all-layers") {
            retry.append("--all-layers")
        }
        retry += ["--dry-run", "true", "--workflow-log", workflowURL.path]
        return retry
    }

    private func workflowAccessibilityElementWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true

        guard expectedExists else {
            var arguments = ["Ln1", "state", "--depth", "2", "--max-children", "80"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            return (
                arguments: arguments,
                message: "Latest Accessibility element wait confirmed the matching state is absent; inspect current UI state before choosing the next action."
            )
        }

        guard let current = verification["current"] as? [String: Any],
              let elementID = current["id"] as? String else {
            return nil
        }

        let stableIdentity = current["stableIdentity"] as? [String: Any]
        let expectedIdentity = stableIdentity?["id"] as? String
        let enabled = current["enabled"] as? Bool
        let actions = current["actions"] as? [String] ?? []
        if enabled != false, actions.contains(kAXPressAction as String) {
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", kAXPressAction as String,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element wait matched an enabled pressable element; perform a guarded press after replacing the reason."
            )
        }

        var arguments = ["Ln1", "state", "--depth", "2", "--max-children", "80"]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        return (
            arguments: arguments,
            message: "Latest Accessibility element wait matched; inspect current UI state before choosing the next action."
        )
    }

    private func workflowAccessibilityElementInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        guard let element = outputJSON["element"] as? [String: Any],
              let elementID = element["id"] as? String else {
            return nil
        }

        let stableIdentity = element["stableIdentity"] as? [String: Any]
        let expectedIdentity = stableIdentity?["id"] as? String
        let enabled = element["enabled"] as? Bool
        let actions = element["actions"] as? [String] ?? []
        if enabled != false, actions.contains(kAXPressAction as String) {
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", kAXPressAction as String,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element inspection found an enabled pressable element; perform a guarded press after replacing the reason."
            )
        }

        var arguments = ["Ln1", "state", "element", "--element", elementID, "--depth", "1", "--max-children", "20"]
        if let pid {
            arguments.insert(contentsOf: ["--pid", String(pid)], at: 3)
        }
        return (
            arguments: arguments,
            message: "Latest Accessibility element inspection completed; re-inspect the element or inspect broader UI state before choosing the next action."
        )
    }

    private func workflowAccessibilityMenuInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let menuBar = outputJSON["menuBar"] as? [String: Any]
        let hasMenuChildren = (menuBar?["children"] as? [[String: Any]])?.isEmpty == false

        if let menuBar,
           let candidate = workflowAccessibilityActionCandidate(
                in: menuBar,
                preferredActions: [
                    kAXShowMenuAction as String,
                    kAXPressAction as String
                ]
           ),
           let elementID = candidate.element["id"] as? String {
            let stableIdentity = candidate.element["stableIdentity"] as? [String: Any]
            let expectedIdentity = stableIdentity?["id"] as? String
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", candidate.action,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility menu inspection found an enabled actionable menu element; perform a guarded menu action after replacing the reason."
            )
        }

        var arguments = ["Ln1", "state", "--depth", "3", "--max-children", "80"]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        return (
            arguments: arguments,
            message: hasMenuChildren
                ? "Latest Accessibility menu inspection found menu items; inspect the target app UI state before choosing a trusted action."
                : "Latest Accessibility menu inspection completed without menu items; inspect the target app UI state before choosing the next action."
        )
    }

    private func workflowAccessibilityActionCandidate(
        in element: [String: Any],
        preferredActions: [String]
    ) -> (element: [String: Any], action: String)? {
        let enabled = element["enabled"] as? Bool
        let actions = element["actions"] as? [String] ?? []
        if enabled != false {
            for action in preferredActions where actions.contains(action) {
                return (element: element, action: action)
            }
        }

        let children = element["children"] as? [[String: Any]] ?? []
        for child in children {
            if let candidate = workflowAccessibilityActionCandidate(
                in: child,
                preferredActions: preferredActions
            ) {
                return candidate
            }
        }

        return nil
    }

    private func workflowActiveAppWaitRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest active app wait matched; dry-run active app inspection before choosing the next UI action."
        )
    }

    private func workflowBrowserDOMRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String
    ) -> (arguments: [String], message: String)? {
        guard let elements = outputJSON["elements"] as? [[String: Any]], !elements.isEmpty else {
            return nil
        }
        let tab = outputJSON["tab"] as? [String: Any]
        guard let tabID = tab?["id"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        if let fillTarget = elements.first(where: workflowDOMElementAcceptsText),
           let selector = fillTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "fill",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--text", "Describe text",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a text field; fill it by selector after replacing the text and reason."
            )
        }

        if let selectTarget = elements.first(where: workflowDOMElementAcceptsSelect),
           let selector = selectTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "select",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--value", "Describe value",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a select control; choose an option by value after replacing the value and reason."
            )
        }

        if let checkedTarget = elements.first(where: workflowDOMElementAcceptsCheckedState),
           let selector = checkedTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "check",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--checked", "true",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a checkbox or radio input; set its checked state after confirming intent."
            )
        }

        if let clickTarget = elements.first(where: workflowDOMElementCanClick),
           let selector = clickTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "click",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found an actionable element; click it by selector after confirming intent."
            )
        }

        return nil
    }

    private func workflowDOMElementAcceptsText(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        let tagName = element["tagName"] as? String
        let role = element["role"] as? String
        let inputType = element["inputType"] as? String
        if tagName == "textarea" || role == "textbox" {
            return workflowInputTypeAcceptsText(inputType)
        }
        return tagName == "input" && workflowInputTypeAcceptsText(inputType)
    }

    private func workflowDOMElementAcceptsSelect(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        return element["tagName"] as? String == "select"
    }

    private func workflowDOMElementAcceptsCheckedState(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        guard element["tagName"] as? String == "input" else {
            return false
        }
        let inputType = element["inputType"] as? String
        return inputType == "checkbox" || inputType == "radio"
    }

    private func workflowInputTypeAcceptsText(_ inputType: String?) -> Bool {
        guard let inputType else {
            return true
        }
        switch inputType {
        case "text", "search", "email", "url", "tel", "number":
            return true
        default:
            return false
        }
    }

    private func workflowDOMElementCanClick(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        let tagName = element["tagName"] as? String
        let role = element["role"] as? String
        let attributes = element["attributes"] as? [String: Any]
        return role == "button"
            || role == "link"
            || tagName == "button"
            || tagName == "a"
            || attributes?["href"] != nil
    }

    private func workflowSelectorWaitAcceptsText(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true || verification["readOnly"] as? Bool == true {
            return false
        }
        let tagName = verification["tagName"] as? String
        let inputType = verification["inputType"] as? String
        if tagName == "textarea" {
            return true
        }
        return tagName == "input" && workflowInputTypeAcceptsText(inputType)
    }

    private func workflowSelectorWaitAcceptsSelect(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true {
            return false
        }
        return verification["tagName"] as? String == "select"
    }

    private func workflowSelectorWaitAcceptsCheckedState(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true || verification["readOnly"] as? Bool == true {
            return false
        }
        guard verification["tagName"] as? String == "input" else {
            return false
        }
        let inputType = verification["inputType"] as? String
        return inputType == "checkbox" || inputType == "radio"
    }

    private func workflowSelectorWaitCanClick(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true {
            return false
        }
        let tagName = verification["tagName"] as? String
        return tagName == "button"
            || tagName == "a"
            || verification["href"] as? String != nil
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
        return ["Ln1", "workflow", "run", "--operation", operation, "--dry-run", "true"]
    }

    private func workflowExecutionReason() throws -> String {
        guard let reason = option("--reason")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reason.isEmpty,
              reason != "Describe intent" else {
            throw CommandError(description: "workflow run mutating execution requires a non-placeholder --reason.")
        }
        return reason
    }

    private func workflowArguments(_ arguments: [String], replacingReasonWith reason: String) throws -> [String] {
        guard let reasonIndex = arguments.firstIndex(of: "--reason") else {
            return arguments + ["--reason", reason]
        }
        let valueIndex = arguments.index(after: reasonIndex)
        guard arguments.indices.contains(valueIndex) else {
            throw CommandError(description: "workflow command argv includes --reason without a value")
        }
        var updatedArguments = arguments
        updatedArguments[valueIndex] = reason
        return updatedArguments
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

        let rawPath = CommandLine.arguments.first ?? "Ln1"
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
            return command.mutates
                ? "Workflow executed a mutating command after explicit approval and captured its output."
                : "Workflow executed a non-mutating command and captured its output."
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
                name: "system.context",
                command: "Ln1 system context",
                risk: systemActionRisk(for: "system.context"),
                mutates: false,
                reason: "Inspect OS, host, shell, working directory, and runtime metadata."
            ),
            ObservationAction(
                name: "desktop.listWindows",
                command: "Ln1 desktop windows --limit \(windowLimit)",
                risk: desktopActionRisk(for: "desktop.listWindows"),
                mutates: false,
                reason: "Refresh visible window metadata and stable desktop identities."
            ),
            ObservationAction(
                name: "desktop.waitWindow",
                command: activePid.map { "Ln1 desktop wait-window --owner-pid \($0) --exists true --timeout-ms 5000" }
                    ?? "Ln1 desktop wait-window --title TITLE --exists true --timeout-ms 5000",
                risk: desktopActionRisk(for: "desktop.waitWindow"),
                mutates: false,
                reason: "Wait for a visible desktop window to appear or disappear using structured metadata."
            ),
            ObservationAction(
                name: "desktop.listDisplays",
                command: "Ln1 desktop displays",
                risk: desktopActionRisk(for: "desktop.listDisplays"),
                mutates: false,
                reason: "Inspect connected display topology, coordinate bounds, scale, and rotation."
            ),
            ObservationAction(
                name: "apps.list",
                command: "Ln1 apps",
                risk: appActionRisk(for: "apps.list"),
                mutates: false,
                reason: "List running GUI apps and identify the active process."
            ),
            ObservationAction(
                name: "processes.list",
                command: "Ln1 processes --limit 50",
                risk: processActionRisk(for: "processes.list"),
                mutates: false,
                reason: "List running process metadata without reading command-line arguments."
            ),
            ObservationAction(
                name: "clipboard.state",
                command: "Ln1 clipboard state",
                risk: clipboardActionRisk(for: "clipboard.state"),
                mutates: false,
                reason: "Inspect clipboard metadata without reading clipboard text."
            ),
            ObservationAction(
                name: "clipboard.wait",
                command: "Ln1 clipboard wait --has-string true --timeout-ms 5000",
                risk: clipboardActionRisk(for: "clipboard.wait"),
                mutates: false,
                reason: "Wait for copied text metadata without reading clipboard text."
            ),
            ObservationAction(
                name: "audit.review",
                command: "Ln1 audit --limit 20",
                risk: "low",
                mutates: false,
                reason: "Review recent audited actions and verification outcomes."
            )
        ]

        if accessibilityTrusted {
            let pidArgument = activePid.map { " --pid \($0)" } ?? ""
            actions.append(ObservationAction(
                name: "accessibility.inspectState",
                command: "Ln1 state\(pidArgument) --depth 3 --max-children 80",
                risk: "low",
                mutates: false,
                reason: "Inspect the active app's UI tree with stable element identities."
            ))
        } else {
            actions.append(ObservationAction(
                name: "accessibility.requestTrust",
                command: "Ln1 trust",
                risk: "low",
                mutates: false,
                reason: "Enable Accessibility inspection before using state or perform."
            ))
        }

        actions.append(ObservationAction(
            name: "browser.listTabs",
            command: "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
            risk: browserActionRisk(for: "browser.listTabs"),
            mutates: false,
            reason: "Inspect browser tabs if a Chromium DevTools endpoint is running."
        ))

        return actions
    }

    private func apps() throws {
        let mode = arguments.dropFirst().first
        switch mode {
        case nil:
            let includeAll = flag("--all")
            let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            try writeJSON(appSummaries(includeAll: includeAll, activePid: activePid))
        case "--help", "-h", "help":
            printHelp()
        case let option? where option.hasPrefix("--"):
            let includeAll = flag("--all")
            let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            try writeJSON(appSummaries(includeAll: includeAll, activePid: activePid))
        case "plan":
            try writeJSON(appActivationPlan())
        case "activate":
            try writeJSON(activateApp())
        case "wait-active":
            try writeJSON(appActiveWaitState())
        default:
            throw CommandError(description: "unknown apps mode '\(mode!)'")
        }
    }

    private func processes() throws {
        let mode = arguments.dropFirst().first
        switch mode {
        case nil:
            try writeJSON(processListState())
        case let option? where option.hasPrefix("--"):
            try writeJSON(processListState())
        case "list":
            try writeJSON(processListState())
        case "inspect":
            try writeJSON(processInspectState())
        case "wait":
            try writeJSON(processWaitState())
        case "--help", "-h", "help":
            printHelp()
        default:
            throw CommandError(description: "unknown processes mode '\(mode!)'")
        }
    }

    private func processListState() throws -> ProcessListState {
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
        let nameFilter = option("--name")?.lowercased()
        var records = runningProcessRecords()
        if let nameFilter, !nameFilter.isEmpty {
            records = records.filter { record in
                (record.name?.lowercased().contains(nameFilter) == true)
                    || (record.appName?.lowercased().contains(nameFilter) == true)
                    || (record.bundleIdentifier?.lowercased().contains(nameFilter) == true)
            }
        }

        let limited = Array(records.prefix(limit))
        return ProcessListState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            limit: limit,
            count: limited.count,
            truncated: records.count > limited.count,
            processes: limited
        )
    }

    private func processInspectState() throws -> ProcessInspectState {
        let pid: pid_t
        if flag("--current") {
            pid = getpid()
        } else if let rawPID = option("--pid"), let parsedPID = pid_t(rawPID), parsedPID > 0 {
            pid = parsedPID
        } else {
            throw CommandError(description: "processes inspect requires --pid PID or --current")
        }

        guard let record = processRecord(for: pid) else {
            return ProcessInspectState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                found: false,
                process: nil,
                message: "No running process metadata was available for pid \(pid)."
            )
        }

        return ProcessInspectState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            found: true,
            process: record,
            message: "Read process metadata for pid \(pid)."
        )
    }

    private func processWaitState() throws -> ProcessWaitResult {
        guard let rawPID = option("--pid"), let pid = pid_t(rawPID), pid > 0 else {
            throw CommandError(description: "processes wait requires --pid PID")
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = waitForProcess(
            pid: pid,
            expectedExists: expectedExists,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return ProcessWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Process matched the expected existence state."
                : "Timed out waiting for process existence state."
        )
    }

    private func appActivationPlan() throws -> AppActivationPlan {
        let operation = option("--operation") ?? "activate"
        guard operation == "activate" else {
            throw CommandError(description: "unsupported apps plan operation '\(operation)'. Use activate.")
        }

        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let checks = appActivationChecks(target: target)
        let canExecute = policy.allowed && checks.allSatisfy(\.ok)
        let targetRecord = appRecord(for: target)

        return AppActivationPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: targetRecord,
            activeBefore: activeBefore,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Activation preflight passed for \(appDisplayName(targetRecord))."
                : "Activation preflight did not pass for \(appDisplayName(targetRecord))."
        )
    }

    private func activateApp() throws -> AppActivationResult {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let targetRecord = appRecord(for: target)
        let activeBefore = activeAppRecord()
        let checks = appActivationChecks(target: target)
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.activate",
                risk: risk,
                reason: option("--reason"),
                app: targetRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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

            if let failedCheck = checks.first(where: { !$0.ok }) {
                let message = failedCheck.message
                verification = FileOperationVerification(ok: false, code: failedCheck.code, message: message)
                try writeAudit(ok: false, code: "preflight_failed", message: message)
                throw CommandError(description: message)
            }

            let requested = target.activate(options: [])
            Thread.sleep(forTimeInterval: 0.10)
            activeAfter = activeAppRecord()
            verification = verifyAppActivation(target: target, requested: requested, activeAfter: activeAfter)

            guard verification?.ok == true else {
                let message = verification?.message ?? "app activation verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Activated \(appDisplayName(targetRecord))."
            try writeAudit(ok: true, code: "activated", message: message)

            return AppActivationResult(
                ok: true,
                action: action,
                risk: risk,
                target: targetRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
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

    private func appActiveWaitState() throws -> AppActiveWaitResult {
        let target = appRecord(for: try targetRunningApplicationForAppCommand())
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = waitForActiveApp(
            target: target,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return AppActiveWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Frontmost app matched the expected target."
                : "Timed out waiting for frontmost app target."
        )
    }

    private func stateElementWaitState() throws -> AccessibilityElementWaitResult {
        let target = try accessibilityElementWaitTarget()
        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 0)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier
        )
        let verification = try waitForAccessibilityElement(
            target: target,
            expectedExists: expectedExists,
            app: app,
            depth: depth,
            maxChildren: maxChildren,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return AccessibilityElementWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            depth: depth,
            maxChildren: maxChildren,
            verification: verification,
            message: verification.ok
                ? "Accessibility element matched the expected structured state."
                : verification.message
        )
    }

    private func stateElementInspectState() throws -> AccessibilityElementInspectResult {
        let elementID = try requiredOption("--element")
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier
        )
        let normalizedID = try normalizedElementID(elementID)
        let element = try resolveElement(id: normalizedID, in: app.processIdentifier)
        let node = buildNode(
            element,
            id: normalizedID,
            ownerName: app.localizedName,
            ownerBundleIdentifier: app.bundleIdentifier,
            depth: depth,
            maxChildren: maxChildren
        )
        let identityVerification = try verifyElementIdentity(node.stableIdentity)

        return AccessibilityElementInspectResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            element: node,
            identityVerification: identityVerification,
            depth: depth,
            maxChildren: maxChildren,
            message: identityVerification?.ok == false
                ? identityVerification!.message
                : "Accessibility element state inspected."
        )
    }

    private func stateMenuState() throws -> AccessibilityMenuState {
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier
        )
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let menuBar = accessibilityElement(axApp, kAXMenuBarAttribute).map { menuBar in
            buildNode(
                menuBar,
                id: "m0",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        return AccessibilityMenuState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            menuBar: menuBar,
            depth: depth,
            maxChildren: maxChildren,
            message: menuBar == nil
                ? "No Accessibility menu bar was available for the target app."
                : "Accessibility menu bar state inspected."
        )
    }

    private func accessibilityElementWaitTarget() throws -> AccessibilityElementWaitTarget {
        let element = try requiredOption("--element")
        let match = option("--match") ?? "contains"
        guard ["exact", "contains"].contains(match) else {
            throw CommandError(description: "state wait-element --match must be exact or contains")
        }
        let enabled = try option("--enabled").map {
            try booleanOption($0, optionName: "--enabled")
        }

        return AccessibilityElementWaitTarget(
            element: element,
            expectedIdentity: option("--expect-identity"),
            minimumConfidence: option("--min-identity-confidence"),
            title: option("--title"),
            value: option("--value"),
            match: match,
            enabled: enabled
        )
    }

    private func waitForAccessibilityElement(
        target: AccessibilityElementWaitTarget,
        expectedExists: Bool,
        app: NSRunningApplication,
        depth: Int,
        maxChildren: Int,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> AccessibilityElementWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var snapshot = try accessibilityElementWaitSnapshot(
            target: target,
            app: app,
            depth: depth,
            maxChildren: maxChildren
        )

        while snapshot.matches != expectedExists, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            snapshot = try accessibilityElementWaitSnapshot(
                target: target,
                app: app,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        let matched = snapshot.matches == expectedExists
        return AccessibilityElementWaitVerification(
            ok: matched,
            code: matched ? "accessibility_element_matched" : "accessibility_element_timeout",
            message: matched
                ? "accessibility element state matched expected criteria"
                : "accessibility element state did not match expected criteria before timeout",
            target: target,
            expectedExists: expectedExists,
            current: snapshot.node,
            identityVerification: snapshot.identityVerification,
            titleMatched: snapshot.titleMatched,
            valueMatched: snapshot.valueMatched,
            enabledMatched: snapshot.enabledMatched,
            matched: matched
        )
    }

    private struct AccessibilityElementWaitSnapshot {
        let node: ElementNode?
        let identityVerification: IdentityVerification?
        let titleMatched: Bool?
        let valueMatched: Bool?
        let enabledMatched: Bool?
        let matches: Bool
    }

    private func accessibilityElementWaitSnapshot(
        target: AccessibilityElementWaitTarget,
        app: NSRunningApplication,
        depth: Int,
        maxChildren: Int
    ) throws -> AccessibilityElementWaitSnapshot {
        let normalizedID: String
        do {
            normalizedID = try normalizedElementID(target.element)
        } catch {
            throw error
        }

        let element: AXUIElement
        do {
            element = try resolveElement(id: normalizedID, in: app.processIdentifier)
        } catch let error as CommandError {
            if error.description.contains("out of range") {
                return AccessibilityElementWaitSnapshot(
                    node: nil,
                    identityVerification: nil,
                    titleMatched: target.title == nil ? nil : false,
                    valueMatched: target.value == nil ? nil : false,
                    enabledMatched: target.enabled == nil ? nil : false,
                    matches: false
                )
            }
            throw error
        }

        let node = buildNode(
            element,
            id: normalizedID,
            ownerName: app.localizedName,
            ownerBundleIdentifier: app.bundleIdentifier,
            depth: depth,
            maxChildren: maxChildren
        )
        let identityVerification = try verifyElementIdentity(node.stableIdentity)
        let identityMatched = identityVerification?.ok != false
        let titleMatched = target.title.map { expectedTitle in
            stringValue(node.title, matches: expectedTitle, mode: target.match)
        }
        let valueMatched = target.value.map { expectedValue in
            stringValue(node.value, matches: expectedValue, mode: target.match)
        }
        let enabledMatched = target.enabled.map { expectedEnabled in
            node.enabled == expectedEnabled
        }
        let matches = identityMatched
            && (titleMatched ?? true)
            && (valueMatched ?? true)
            && (enabledMatched ?? true)

        return AccessibilityElementWaitSnapshot(
            node: node,
            identityVerification: identityVerification,
            titleMatched: titleMatched,
            valueMatched: valueMatched,
            enabledMatched: enabledMatched,
            matches: matches
        )
    }

    private func state() throws {
        if arguments.dropFirst().first == "menu" {
            try writeJSON(stateMenuState())
            return
        }

        if arguments.dropFirst().first == "element" {
            try writeJSON(stateElementInspectState())
            return
        }

        if arguments.dropFirst().first == "wait-element" {
            try writeJSON(stateElementWaitState())
            return
        }

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
        case "read-text":
            let maxCharacters = max(0, option("--max-characters").flatMap(Int.init) ?? 16_384)
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "1048576", optionName: "--max-file-bytes")
            let result = try fileText(
                for: requestedFileURL(),
                maxCharacters: maxCharacters,
                maxFileBytes: maxFileBytes,
                selection: "prefix"
            )
            try writeJSON(result)
        case "tail-text":
            let maxCharacters = max(0, option("--max-characters").flatMap(Int.init) ?? 16_384)
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "1048576", optionName: "--max-file-bytes")
            let result = try fileText(
                for: requestedFileURL(),
                maxCharacters: maxCharacters,
                maxFileBytes: maxFileBytes,
                selection: "suffix"
            )
            try writeJSON(result)
        case "read-lines":
            let startLine = max(1, option("--start-line").flatMap(Int.init) ?? 1)
            let lineCount = max(0, option("--line-count").flatMap(Int.init) ?? 80)
            let maxLineCharacters = max(0, option("--max-line-characters").flatMap(Int.init) ?? 240)
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "1048576", optionName: "--max-file-bytes")
            let result = try fileLines(
                for: requestedFileURL(),
                startLine: startLine,
                lineCount: lineCount,
                maxLineCharacters: maxLineCharacters,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "read-json":
            let pointer = option("--pointer")
            let maxDepth = max(0, option("--max-depth").flatMap(Int.init) ?? 4)
            let maxItems = max(0, option("--max-items").flatMap(Int.init) ?? 50)
            let maxStringCharacters = max(0, option("--max-string-characters").flatMap(Int.init) ?? 1_024)
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "1048576", optionName: "--max-file-bytes")
            let result = try fileJSON(
                for: requestedFileURL(),
                pointer: pointer,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "read-plist":
            let pointer = option("--pointer")
            let maxDepth = max(0, option("--max-depth").flatMap(Int.init) ?? 4)
            let maxItems = max(0, option("--max-items").flatMap(Int.init) ?? 50)
            let maxStringCharacters = max(0, option("--max-string-characters").flatMap(Int.init) ?? 1_024)
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "1048576", optionName: "--max-file-bytes")
            let result = try filePropertyList(
                for: requestedFileURL(),
                pointer: pointer,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "write-text":
            let text = try requiredOption("--text")
            let overwrite = flag("--overwrite")
            let result = try writeFileText(
                text,
                to: requestedFileURL(),
                overwrite: overwrite
            )
            try writeJSON(result)
        case "append-text":
            let text = try requiredOption("--text")
            let create = flag("--create")
            let result = try appendFileText(
                text,
                to: requestedFileURL(),
                create: create
            )
            try writeJSON(result)
        case "wait":
            let expectedExists = option("--exists").map(parseBool) ?? true
            let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
            let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
            let expectedSizeBytes = try option("--size-bytes").map(fileExpectedSizeBytes)
            let rawExpectedDigest = option("--digest")
            if let rawExpectedDigest, !isSHA256HexDigest(rawExpectedDigest) {
                throw CommandError(description: "file digest must be a 64-character SHA-256 hex digest")
            }
            let expectedDigest = rawExpectedDigest?.lowercased()
            if expectedExists == false && (expectedSizeBytes != nil || expectedDigest != nil) {
                throw CommandError(description: "files wait cannot verify size or digest while expecting the path to be missing")
            }
            let algorithm: String?
            if expectedDigest == nil {
                algorithm = nil
            } else {
                algorithm = try normalizedChecksumAlgorithm(option("--algorithm") ?? "sha256")
            }
            let maxFileBytes = try fileMaxBytes(option("--max-file-bytes") ?? "104857600", optionName: "--max-file-bytes")
            let result = try waitForFileState(
                at: requestedFileURL(),
                expectedExists: expectedExists,
                expectedSizeBytes: expectedSizeBytes,
                expectedDigest: expectedDigest,
                algorithm: algorithm,
                maxFileBytes: maxFileBytes,
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
        case "wait":
            try writeJSON(clipboardWait(for: pasteboard))
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
        case "select":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserSelect(id: id, selector: selector))
        case "check":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserCheck(id: id, selector: selector))
        case "focus":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserFocus(id: id, selector: selector))
        case "press-key":
            let id = try requiredOption("--id")
            let key = try requiredOption("--key")
            try writeJSON(browserPressKey(id: id, key: key))
        case "click":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserClick(id: id, selector: selector))
        case "navigate":
            let id = try requiredOption("--id")
            let url = try requiredOption("--url")
            try writeJSON(browserNavigate(id: id, requestedURL: url))
        case "wait-url":
            let id = try requiredOption("--id")
            let expectedURL = try requiredOption("--expect-url")
            try writeJSON(browserWaitURL(id: id, expectedURL: expectedURL))
        case "wait-selector":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitSelector(id: id, selector: selector))
        case "wait-count":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitCount(id: id, selector: selector))
        case "wait-text":
            let id = try requiredOption("--id")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitText(id: id, expectedText: text))
        case "wait-element-text":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitElementText(id: id, selector: selector, expectedText: text))
        case "wait-value":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitValue(id: id, selector: selector, expectedValue: text))
        case "wait-ready":
            let id = try requiredOption("--id")
            try writeJSON(browserWaitReady(id: id))
        case "wait-title":
            let id = try requiredOption("--id")
            let title = try requiredOption("--title")
            try writeJSON(browserWaitTitle(id: id, expectedTitle: title))
        case "wait-checked":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitChecked(id: id, selector: selector))
        case "wait-enabled":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitEnabled(id: id, selector: selector))
        case "wait-focus":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitFocus(id: id, selector: selector))
        case "wait-attribute":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let attribute = try requiredOption("--attribute")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitAttribute(id: id, selector: selector, attribute: attribute, expectedValue: text))
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

    private func workflowDoctorCheck(from fileCheck: FilePreflightCheck, remediation: String) -> DoctorCheck {
        DoctorCheck(
            name: fileCheck.name,
            status: fileCheck.ok ? "pass" : "fail",
            required: true,
            message: fileCheck.message,
            remediation: fileCheck.ok ? nil : remediation
        )
    }

    private func directoryExistsDoctorCheck(name: String, url: URL) -> DoctorCheck {
        workflowDoctorCheck(
            from: directoryExistsCheck(name: name, url: url),
            remediation: "Pass an existing directory path."
        )
    }

    private func writableDirectoryDoctorCheck(name: String, url: URL) -> DoctorCheck {
        workflowDoctorCheck(
            from: writableDirectoryCheck(name: name, url: url),
            remediation: "Choose a writable directory or adjust filesystem permissions."
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

    private func writeFileText(
        _ text: String,
        to url: URL,
        overwrite: Bool
    ) throws -> FileTextWriteResult {
        let action = "filesystem.writeText"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let previousRecord = try? fileRecord(for: url)
        var previousTarget = previousRecord.map { fileAuditTarget(record: $0, exists: true) } ?? fileAuditTarget(url: url)
        var currentTarget = previousTarget
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.write-text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: previousTarget,
                fileDestination: currentTarget,
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

            if let previousRecord {
                previousTarget = fileAuditTarget(record: previousRecord, exists: true)
                currentTarget = previousTarget

                guard overwrite else {
                    let message = "destination already exists at \(url.path); pass --overwrite to replace it"
                    try writeAudit(ok: false, code: "destination_exists", message: message)
                    throw CommandError(description: message)
                }

                guard previousRecord.kind == "regularFile" else {
                    let message = "filesystem.writeText currently supports regular files only"
                    try writeAudit(ok: false, code: "unsupported_destination_kind", message: message)
                    throw CommandError(description: message)
                }

                guard previousRecord.writable else {
                    let message = "destination file is not writable at \(url.path)"
                    try writeAudit(ok: false, code: "destination_unwritable", message: message)
                    throw CommandError(description: message)
                }
            }

            let parentURL = url.deletingLastPathComponent()
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

            try text.write(to: url, atomically: true, encoding: .utf8)

            let currentRecord = try fileRecord(for: url)
            currentTarget = fileAuditTarget(record: currentRecord, exists: true)
            let writtenDigest = sha256Digest(text)
            let writtenBytes = Data(text.utf8).count
            verification = try verifyWrittenTextFile(
                at: url,
                expectedByteLength: writtenBytes,
                expectedDigest: writtenDigest
            )
            guard verification?.ok == true else {
                let message = verification?.message ?? "file text write verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let created = previousRecord == nil
            let message = created
                ? "Wrote text to new file \(url.path)."
                : "Overwrote text in \(url.path)."
            try writeAudit(ok: true, code: created ? "created_text_file" : "overwrote_text_file", message: message)

            return FileTextWriteResult(
                ok: true,
                action: action,
                risk: risk,
                path: url.path,
                created: created,
                overwritten: !created,
                previous: previousTarget,
                current: currentRecord,
                writtenLength: text.count,
                writtenBytes: writtenBytes,
                writtenDigest: writtenDigest,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func verifyWrittenTextFile(
        at url: URL,
        expectedByteLength: Int,
        expectedDigest: String
    ) throws -> FileOperationVerification {
        let data = try Data(contentsOf: url)
        guard data.count == expectedByteLength else {
            return FileOperationVerification(
                ok: false,
                code: "size_mismatch",
                message: "written file byte length does not match requested text byte length"
            )
        }

        guard let string = String(data: data, encoding: .utf8) else {
            return FileOperationVerification(
                ok: false,
                code: "encoding_mismatch",
                message: "written file is not valid UTF-8"
            )
        }

        guard sha256Digest(string) == expectedDigest else {
            return FileOperationVerification(
                ok: false,
                code: "digest_mismatch",
                message: "written file text digest does not match requested text digest"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "text_matched",
            message: "written file contains text with the requested byte length and digest"
        )
    }

    private func appendFileText(
        _ text: String,
        to url: URL,
        create: Bool
    ) throws -> FileTextAppendResult {
        let action = "filesystem.appendText"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let previousRecord = try? fileRecord(for: url)
        var previousTarget = previousRecord.map { fileAuditTarget(record: $0, exists: true) } ?? fileAuditTarget(url: url)
        var currentTarget = previousTarget
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.append-text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: previousTarget,
                fileDestination: currentTarget,
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

            let appendedData = Data(text.utf8)
            let previousSize: Int

            if let previousRecord {
                previousTarget = fileAuditTarget(record: previousRecord, exists: true)
                currentTarget = previousTarget

                guard previousRecord.kind == "regularFile" else {
                    let message = "filesystem.appendText currently supports regular files only"
                    try writeAudit(ok: false, code: "unsupported_destination_kind", message: message)
                    throw CommandError(description: message)
                }

                guard previousRecord.writable else {
                    let message = "destination file is not writable at \(url.path)"
                    try writeAudit(ok: false, code: "destination_unwritable", message: message)
                    throw CommandError(description: message)
                }

                previousSize = try fileByteSize(at: url)
                let handle = try FileHandle(forWritingTo: url)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: appendedData)
            } else {
                guard create else {
                    let message = "destination does not exist at \(url.path); pass --create to create it before appending"
                    try writeAudit(ok: false, code: "destination_missing", message: message)
                    throw CommandError(description: message)
                }

                let parentURL = url.deletingLastPathComponent()
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

                previousSize = 0
                try appendedData.write(to: url, options: .atomic)
            }

            let currentRecord = try refreshedFileRecord(for: url)
            currentTarget = fileAuditTarget(record: currentRecord, exists: true)
            verification = try verifyAppendedTextFile(
                at: url,
                expectedFinalByteLength: previousSize + appendedData.count,
                appendedData: appendedData
            )
            guard verification?.ok == true else {
                let message = verification?.message ?? "file text append verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let created = previousRecord == nil
            let message = created
                ? "Created \(url.path) and appended text."
                : "Appended text to \(url.path)."
            try writeAudit(ok: true, code: created ? "created_appended_text_file" : "appended_text_file", message: message)

            return FileTextAppendResult(
                ok: true,
                action: action,
                risk: risk,
                path: url.path,
                created: created,
                previous: previousTarget,
                current: currentRecord,
                appendedLength: text.count,
                appendedBytes: appendedData.count,
                appendedDigest: sha256Digest(text),
                finalBytes: currentRecord.sizeBytes ?? previousSize + appendedData.count,
                verification: verification!,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func verifyAppendedTextFile(
        at url: URL,
        expectedFinalByteLength: Int,
        appendedData: Data
    ) throws -> FileOperationVerification {
        let byteLength = try fileByteSize(at: url)
        guard byteLength == expectedFinalByteLength else {
            return FileOperationVerification(
                ok: false,
                code: "size_mismatch",
                message: "appended file byte length does not match previous byte length plus appended text"
            )
        }

        guard !appendedData.isEmpty else {
            return FileOperationVerification(
                ok: true,
                code: "text_appended",
                message: "file byte length matched after appending empty text"
            )
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let tailOffset = UInt64(max(0, expectedFinalByteLength - appendedData.count))
        try handle.seek(toOffset: tailOffset)
        let tailData = try handle.readToEnd() ?? Data()

        guard tailData == appendedData else {
            return FileOperationVerification(
                ok: false,
                code: "tail_mismatch",
                message: "appended file tail bytes do not match requested text"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "text_appended",
            message: "file grew by the requested byte length and ends with the requested text bytes"
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
        expectedSizeBytes: Int?,
        expectedDigest: String?,
        algorithm: String?,
        maxFileBytes: Int,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> FilesystemWaitResult {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var snapshot = fileWaitSnapshot(
            at: url,
            expectedDigest: expectedDigest,
            algorithm: algorithm,
            maxFileBytes: maxFileBytes
        )

        while !fileWaitSnapshot(
            snapshot,
            matchesExpectedExists: expectedExists,
            expectedSizeBytes: expectedSizeBytes,
            expectedDigest: expectedDigest
        ), Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            snapshot = fileWaitSnapshot(
                at: url,
                expectedDigest: expectedDigest,
                algorithm: algorithm,
                maxFileBytes: maxFileBytes
            )
        }

        let elapsedMilliseconds = max(0, Int(Date().timeIntervalSince(start) * 1_000))
        let matched = fileWaitSnapshot(
            snapshot,
            matchesExpectedExists: expectedExists,
            expectedSizeBytes: expectedSizeBytes,
            expectedDigest: expectedDigest
        )
        let record = snapshot.record
        let sizeMatched = expectedSizeBytes.map { record?.sizeBytes == $0 }
        let digestMatched = expectedDigest.map { snapshot.digest == $0 }
        let message: String
        if matched {
            if expectedExists {
                if expectedSizeBytes != nil || expectedDigest != nil {
                    message = "Path exists at \(url.path) and matched expected metadata."
                } else {
                    message = "Path exists at \(url.path)."
                }
            } else {
                message = "Path does not exist at \(url.path)."
            }
        } else {
            if expectedExists {
                let digestMessage = snapshot.digestError.map { " Last digest check: \($0)" } ?? ""
                message = expectedSizeBytes != nil || expectedDigest != nil
                    ? "Timed out waiting for path metadata to match at \(url.path).\(digestMessage)"
                    : "Timed out waiting for path to exist at \(url.path)."
            } else {
                message = "Timed out waiting for path to disappear at \(url.path)."
            }
        }

        return FilesystemWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            path: url.path,
            expectedExists: expectedExists,
            expectedSizeBytes: expectedSizeBytes,
            expectedDigest: expectedDigest,
            algorithm: algorithm,
            maxFileBytes: expectedDigest == nil ? nil : maxFileBytes,
            matched: matched,
            sizeMatched: sizeMatched,
            digestMatched: digestMatched,
            currentDigest: snapshot.digest,
            elapsedMilliseconds: elapsedMilliseconds,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            file: record,
            message: message
        )
    }

    private struct FileWaitSnapshot {
        let exists: Bool
        let record: FileRecord?
        let digest: String?
        let digestError: String?
    }

    private func fileWaitSnapshot(
        at url: URL,
        expectedDigest: String?,
        algorithm: String?,
        maxFileBytes: Int
    ) -> FileWaitSnapshot {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return FileWaitSnapshot(exists: false, record: nil, digest: nil, digestError: nil)
        }

        guard let record = try? fileRecord(for: url) else {
            return FileWaitSnapshot(exists: true, record: nil, digest: nil, digestError: "file metadata is unavailable")
        }

        guard expectedDigest != nil else {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: nil)
        }
        guard algorithm == "sha256" else {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: "unsupported checksum algorithm")
        }
        guard record.kind == "regularFile" else {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: "file is not a regular file")
        }
        guard record.readable else {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: "file is not readable")
        }
        if let size = record.sizeBytes, size > maxFileBytes {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: "file size \(size) exceeds --max-file-bytes \(maxFileBytes)")
        }

        do {
            let data = try Data(contentsOf: url)
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            return FileWaitSnapshot(exists: true, record: record, digest: digest, digestError: nil)
        } catch {
            return FileWaitSnapshot(exists: true, record: record, digest: nil, digestError: error.localizedDescription)
        }
    }

    private func fileWaitSnapshot(
        _ snapshot: FileWaitSnapshot,
        matchesExpectedExists expectedExists: Bool,
        expectedSizeBytes: Int?,
        expectedDigest: String?
    ) -> Bool {
        guard snapshot.exists == expectedExists else {
            return false
        }
        guard expectedExists else {
            return true
        }
        guard let record = snapshot.record else {
            return false
        }
        if let expectedSizeBytes, record.sizeBytes != expectedSizeBytes {
            return false
        }
        if let expectedDigest, snapshot.digest != expectedDigest {
            return false
        }
        return true
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
                    name: "browser.selectOption",
                    risk: browserActionRisk(for: "browser.selectOption"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.setChecked",
                    risk: browserActionRisk(for: "browser.setChecked"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.focusElement",
                    risk: browserActionRisk(for: "browser.focusElement"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.pressKey",
                    risk: browserActionRisk(for: "browser.pressKey"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.clickElement",
                    risk: browserActionRisk(for: "browser.clickElement"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.navigate",
                    risk: browserActionRisk(for: "browser.navigate"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.waitURL",
                    risk: browserActionRisk(for: "browser.waitURL"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitSelector",
                    risk: browserActionRisk(for: "browser.waitSelector"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitCount",
                    risk: browserActionRisk(for: "browser.waitCount"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitText",
                    risk: browserActionRisk(for: "browser.waitText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitElementText",
                    risk: browserActionRisk(for: "browser.waitElementText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitValue",
                    risk: browserActionRisk(for: "browser.waitValue"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitReady",
                    risk: browserActionRisk(for: "browser.waitReady"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitTitle",
                    risk: browserActionRisk(for: "browser.waitTitle"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitChecked",
                    risk: browserActionRisk(for: "browser.waitChecked"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitEnabled",
                    risk: browserActionRisk(for: "browser.waitEnabled"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitFocus",
                    risk: browserActionRisk(for: "browser.waitFocus"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitAttribute",
                    risk: browserActionRisk(for: "browser.waitAttribute"),
                    mutates: false
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

    private func browserSelect(id: String, selector: String) throws -> BrowserSelectOptionResult {
        let action = "browser.selectOption"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let requestedValue: String?
        if let rawValue = option("--value") {
            requestedValue = try validatedBrowserSelectOption(rawValue, optionName: "--value")
        } else {
            requestedValue = nil
        }
        let requestedLabel: String?
        if let rawLabel = option("--label") {
            requestedLabel = try validatedBrowserSelectOption(rawLabel, optionName: "--label")
        } else {
            requestedLabel = nil
        }
        guard requestedValue != nil || requestedLabel != nil else {
            throw CommandError(description: "browser select requires --value or --label")
        }
        guard !(requestedValue != nil && requestedLabel != nil) else {
            throw CommandError(description: "browser select accepts either --value or --label, not both")
        }
        let auditOption = requestedValue ?? requestedLabel ?? ""
        let optionDigest = sha256Digest(auditOption)
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
            formTextLength: auditOption.count,
            formTextDigest: optionDigest
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.select",
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
                formTextLength: auditOption.count,
                formTextDigest: optionDigest
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try selectBrowserOption(
                selector: selector,
                requestedValue: requestedValue,
                requestedLabel: requestedLabel,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "option_selected" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser select contains the requested option"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Selected browser option matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "selected", message: message, verification: verification)

            return BrowserSelectOptionResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                requestedValueLength: requestedValue?.count,
                requestedValueDigest: requestedValue.map(sha256Digest),
                requestedLabelLength: requestedLabel?.count,
                requestedLabelDigest: requestedLabel.map(sha256Digest),
                verification: verification,
                targetTagName: payload.tagName,
                targetDisabled: payload.disabled,
                optionCount: payload.optionCount,
                selectedIndex: payload.selectedIndex,
                selectedValueLength: payload.selectedValueLength,
                selectedLabelLength: payload.selectedLabelLength,
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

    private func browserCheck(id: String, selector: String) throws -> BrowserCheckedResult {
        let action = "browser.setChecked"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let requestedChecked = try browserCheckedValue(option("--checked") ?? "true")
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
            formChecked: requestedChecked
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.check",
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
                formChecked: requestedChecked
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try setBrowserCheckedState(
                selector: selector,
                checked: requestedChecked,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched && payload.currentChecked == requestedChecked,
                code: payload.ok && payload.matched && payload.currentChecked == requestedChecked ? "checked_matched" : payload.code,
                message: payload.ok && payload.matched && payload.currentChecked == requestedChecked
                    ? "browser control checked state matches the requested value"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Set browser checked state matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "checked", message: message, verification: verification)

            return BrowserCheckedResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                requestedChecked: requestedChecked,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                currentChecked: payload.currentChecked,
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

    private func browserFocus(id: String, selector: String) throws -> BrowserFocusResult {
        let action = "browser.focusElement"
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
            domDigest: nil,
            focusSelector: selector
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.focus",
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
                focusSelector: selector
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try focusBrowserElement(selector: selector, at: webSocketURL)
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "element_focused" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser active element matches the requested selector"
                    : payload.message
            )

            tabSummary?.focusTagName = payload.tagName

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Focused browser element matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "focused", message: message, verification: verification)

            return BrowserFocusResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                activeElementMatched: payload.matched,
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

    private func browserPressKey(id: String, key rawKey: String) throws -> BrowserKeyPressResult {
        let action = "browser.pressKey"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let key = try browserKeyDefinition(for: rawKey)
        let modifierSet = try browserModifierSet(option("--modifiers"))
        let modifierMask = browserModifierMask(for: modifierSet)
        let selector = option("--selector")
        var focusVerification: FileOperationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            focusSelector: selector,
            keyName: key.key,
            keyModifiers: modifierSet,
            keyModifierMask: modifierMask
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.press-key",
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
                focusSelector: selector,
                keyName: key.key,
                keyModifiers: modifierSet,
                keyModifierMask: modifierMask
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            if let selector {
                let focusPayload = try focusBrowserElement(selector: selector, at: webSocketURL)
                focusVerification = FileOperationVerification(
                    ok: focusPayload.ok && focusPayload.matched,
                    code: focusPayload.ok && focusPayload.matched ? "element_focused" : focusPayload.code,
                    message: focusPayload.ok && focusPayload.matched
                        ? "browser active element matches the requested selector"
                        : focusPayload.message
                )
                tabSummary?.focusTagName = focusPayload.tagName

                guard focusVerification?.ok == true else {
                    let message = focusVerification?.message ?? focusPayload.message
                    try writeAudit(ok: false, code: focusPayload.code, message: message, verification: focusVerification)
                    throw CommandError(description: message)
                }
            }

            let verification = try dispatchBrowserKey(
                key,
                modifiers: modifierSet,
                modifierMask: modifierMask,
                selector: selector,
                at: webSocketURL
            )

            guard verification.ok else {
                try writeAudit(
                    ok: false,
                    code: verification.code,
                    message: verification.message,
                    verification: FileOperationVerification(ok: verification.ok, code: verification.code, message: verification.message)
                )
                throw CommandError(description: verification.message)
            }

            let message = "Pressed browser key '\(key.key)' in tab \(id)."
            try writeAudit(
                ok: true,
                code: "key_pressed",
                message: message,
                verification: FileOperationVerification(ok: true, code: verification.code, message: verification.message)
            )

            return BrowserKeyPressResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                key: key.key,
                modifiers: modifierSet,
                modifierMask: modifierMask,
                selector: selector,
                focusVerification: focusVerification,
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

    private func browserClick(id: String, selector: String) throws -> BrowserClickResult {
        let action = "browser.clickElement"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let expectedURL = option("--expect-url")
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var urlVerification: BrowserNavigationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            navigationURL: expectedURL,
            currentURL: nil,
            urlMatched: nil,
            clickSelector: selector
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.click",
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
            let normalizedExpectedURL = try expectedURL.map(validatedBrowserExpectedURL)

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
                navigationURL: normalizedExpectedURL,
                currentURL: tab.url,
                urlMatched: nil,
                clickSelector: selector
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try clickBrowserElement(selector: selector, at: webSocketURL)
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedExpectedURL,
                currentURL: tab.url,
                urlMatched: nil,
                clickSelector: selector,
                clickTagName: payload.tagName
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "element_clicked" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser element matched selector and received a click"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            if let normalizedExpectedURL {
                urlVerification = try waitForBrowserURL(
                    tabID: id,
                    requestedURL: normalizedExpectedURL,
                    expectedURL: normalizedExpectedURL,
                    match: match,
                    endpoint: endpoint,
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
                    navigationURL: normalizedExpectedURL,
                    currentURL: urlVerification?.currentURL,
                    urlMatched: urlVerification?.matched,
                    clickSelector: selector,
                    clickTagName: payload.tagName
                )
                guard urlVerification?.ok == true else {
                    let message = urlVerification?.message ?? "browser click URL verification failed"
                    let auditVerification = FileOperationVerification(
                        ok: false,
                        code: urlVerification?.code ?? "url_verification_failed",
                        message: message
                    )
                    try writeAudit(ok: false, code: auditVerification.code, message: message, verification: auditVerification)
                    throw CommandError(description: message)
                }
            }

            let message = normalizedExpectedURL == nil
                ? "Clicked browser element matching selector '\(selector)' in tab \(id)."
                : "Clicked browser element matching selector '\(selector)' in tab \(id) and verified the resulting URL."
            let auditVerification = urlVerification.map {
                FileOperationVerification(ok: $0.ok, code: $0.code, message: $0.message)
            } ?? verification
            try writeAudit(ok: true, code: "clicked", message: message, verification: auditVerification)

            return BrowserClickResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                verification: verification,
                targetTagName: payload.tagName,
                targetDisabled: payload.disabled,
                targetHref: payload.href,
                expectedURL: normalizedExpectedURL,
                match: normalizedExpectedURL == nil ? nil : match,
                urlVerification: urlVerification,
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

    private func browserWaitURL(id: String, expectedURL: String) throws -> BrowserURLWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedURL = try validatedBrowserExpectedURL(expectedURL)
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserURL(
            tabID: id,
            requestedURL: normalizedExpectedURL,
            expectedURL: normalizedExpectedURL,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected URL."
            : "Timed out waiting for browser tab \(id) to reach the expected URL."
        return BrowserURLWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedURL: normalizedExpectedURL,
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitSelector(id: String, selector: String) throws -> BrowserSelectorWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let state = try browserSelectorWaitState(option("--state") ?? "attached")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserSelector(
            tabID: id,
            selector: normalizedSelector,
            state: state,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected selector state."
            : "Timed out waiting for browser tab \(id) to reach the expected selector state."
        return BrowserSelectorWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            state: state,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitCount(id: String, selector: String) throws -> BrowserCountWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedCount = try browserSelectorCountValue(try requiredOption("--count"))
        let countMatch = try browserCountMatchMode(option("--count-match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserCount(
            tabID: id,
            selector: normalizedSelector,
            expectedCount: expectedCount,
            countMatch: countMatch,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected selector count."
            : "Timed out waiting for browser tab \(id) to reach the expected selector count."
        return BrowserCountWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedCount: expectedCount,
            countMatch: countMatch,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitText(id: String, expectedText: String) throws -> BrowserTextWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedText = try validatedBrowserExpectedText(expectedText)
        let match = try browserTextMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserText(
            tabID: id,
            expectedText: normalizedExpectedText,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected text state."
            : "Timed out waiting for browser tab \(id) to reach the expected text state."
        return BrowserTextWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedTextLength: normalizedExpectedText.count,
            expectedTextDigest: sha256Digest(normalizedExpectedText),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitElementText(id: String, selector: String, expectedText: String) throws -> BrowserElementTextWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedExpectedText = try validatedBrowserExpectedText(expectedText)
        let match = try browserTextMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserElementText(
            tabID: id,
            selector: normalizedSelector,
            expectedText: normalizedExpectedText,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected element text state."
            : "Timed out waiting for browser tab \(id) to reach the expected element text state."
        return BrowserElementTextWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedTextLength: normalizedExpectedText.count,
            expectedTextDigest: sha256Digest(normalizedExpectedText),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitValue(id: String, selector: String, expectedValue: String) throws -> BrowserValueWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedExpectedValue = try validatedBrowserExpectedText(expectedValue)
        let match = try browserTextMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserValue(
            tabID: id,
            selector: normalizedSelector,
            expectedValue: normalizedExpectedValue,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected field value state."
            : "Timed out waiting for browser tab \(id) to reach the expected field value state."
        return BrowserValueWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedValueLength: normalizedExpectedValue.count,
            expectedValueDigest: sha256Digest(normalizedExpectedValue),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitReady(id: String) throws -> BrowserReadyWaitResult {
        let endpoint = try browserEndpoint()
        let state = try browserReadyState(option("--state") ?? "complete")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserReady(
            tabID: id,
            expectedState: state,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected ready state."
            : "Timed out waiting for browser tab \(id) to reach the expected ready state."
        return BrowserReadyWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedState: state,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitTitle(id: String, expectedTitle: String) throws -> BrowserTitleWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedTitle = try validatedBrowserExpectedTitle(expectedTitle)
        let match = try browserTitleMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserTitle(
            tabID: id,
            expectedTitle: normalizedExpectedTitle,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected title state."
            : "Timed out waiting for browser tab \(id) to reach the expected title state."
        return BrowserTitleWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedTitle: normalizedExpectedTitle,
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitChecked(id: String, selector: String) throws -> BrowserCheckedWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedChecked = try browserCheckedValue(option("--checked") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserChecked(
            tabID: id,
            selector: normalizedSelector,
            expectedChecked: expectedChecked,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected checked state."
            : "Timed out waiting for browser tab \(id) to reach the expected checked state."
        return BrowserCheckedWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedChecked: expectedChecked,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitEnabled(id: String, selector: String) throws -> BrowserEnabledWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedEnabled = try browserEnabledValue(option("--enabled") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserEnabled(
            tabID: id,
            selector: normalizedSelector,
            expectedEnabled: expectedEnabled,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected enabled state."
            : "Timed out waiting for browser tab \(id) to reach the expected enabled state."
        return BrowserEnabledWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedEnabled: expectedEnabled,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitFocus(id: String, selector: String) throws -> BrowserFocusWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedFocused = try browserFocusedValue(option("--focused") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserFocus(
            tabID: id,
            selector: normalizedSelector,
            expectedFocused: expectedFocused,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected focus state."
            : "Timed out waiting for browser tab \(id) to reach the expected focus state."
        return BrowserFocusWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedFocused: expectedFocused,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    private func browserWaitAttribute(id: String, selector: String, attribute: String, expectedValue: String) throws -> BrowserAttributeWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedAttribute = try validatedBrowserAttributeName(attribute)
        let normalizedExpectedValue = try validatedBrowserExpectedText(expectedValue)
        let match = try browserTextMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserAttribute(
            tabID: id,
            selector: normalizedSelector,
            attribute: normalizedAttribute,
            expectedValue: normalizedExpectedValue,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected attribute state."
            : "Timed out waiting for browser tab \(id) to reach the expected attribute state."
        return BrowserAttributeWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            attribute: normalizedAttribute,
            expectedValueLength: normalizedExpectedValue.count,
            expectedValueDigest: sha256Digest(normalizedExpectedValue),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
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
          const attrNames = [
            "id", "class", "name", "aria-label", "placeholder", "title", "href", "type",
            "aria-expanded", "aria-selected", "aria-checked", "aria-pressed", "aria-disabled",
            "aria-current", "aria-controls"
          ];
          const elements = [];
          const ids = new Map();
          const queue = root ? [{ element: root, depth: 0 }] : [];
          const cssEscape = (value) => {
            if (window.CSS && typeof window.CSS.escape === "function") {
              return window.CSS.escape(value);
            }
            return String(value).replace(/[^a-zA-Z0-9_-]/g, (character) => {
              const codePoint = character.codePointAt(0).toString(16);
              return `\\${codePoint} `;
            });
          };
          const cssString = (value) => String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
          const isUniqueSelector = (selector) => {
            try {
              return document.querySelectorAll(selector).length === 1;
            } catch {
              return false;
            }
          };
          const selectorFor = (element) => {
            const tag = element.tagName.toLowerCase();
            if (element.id) {
              const candidate = `#${cssEscape(element.id)}`;
              if (isUniqueSelector(candidate)) return candidate;
            }

            for (const name of ["name", "aria-label", "placeholder", "title", "href", "aria-controls", "aria-current"]) {
              const value = element.getAttribute(name);
              if (!value) continue;
              const candidate = `${tag}[${name}="${cssString(value)}"]`;
              if (isUniqueSelector(candidate)) return candidate;
            }

            const parts = [];
            let current = element;
            while (current && current.nodeType === Node.ELEMENT_NODE && current !== document.documentElement) {
              let part = current.tagName.toLowerCase();
              if (current.id) {
                parts.unshift(`#${cssEscape(current.id)}`);
                const candidate = parts.join(" > ");
                if (isUniqueSelector(candidate)) return candidate;
                current = current.parentElement;
                continue;
              }

              let index = 1;
              let sibling = current;
              while ((sibling = sibling.previousElementSibling)) {
                if (sibling.tagName === current.tagName) index += 1;
              }
              part += `:nth-of-type(${index})`;
              parts.unshift(part);

              const candidate = parts.join(" > ");
              if (isUniqueSelector(candidate)) return candidate;
              current = current.parentElement;
            }
            return parts.join(" > ") || tag;
          };

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
              selector: selectorFor(element),
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

    private func selectBrowserOption(
        selector: String,
        requestedValue: String?,
        requestedLabel: String?,
        at webSocketURL: URL
    ) throws -> BrowserSelectOptionPayload {
        let requestedValueLiteral = try requestedValue.map(javascriptStringLiteral) ?? "null"
        let requestedLabelLiteral = try requestedLabel.map(javascriptStringLiteral) ?? "null"
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const requestedValue = \(requestedValueLiteral);
          const requestedLabel = \(requestedLabelLiteral);
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            disabled: extra.disabled ?? null,
            optionCount: extra.optionCount ?? null,
            selectedIndex: extra.selectedIndex ?? null,
            selectedValueLength: extra.selectedValueLength ?? null,
            selectedLabelLength: extra.selectedLabelLength ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const metadata = {
            tagName,
            disabled: "disabled" in element ? Boolean(element.disabled) : null,
            optionCount: element.options ? element.options.length : null,
            selectedIndex: "selectedIndex" in element ? element.selectedIndex : null
          };

          if (tagName !== "select" || !element.options) {
            return result(false, "unsupported_element", "The matched element is not a select control.", metadata);
          }
          if (element.disabled) {
            return result(false, "element_disabled", "The matched select control is disabled.", metadata);
          }

          const normalizedLabel = (option) => String(option.label || option.textContent || "").replace(/\\s+/g, " ").trim();
          const options = Array.from(element.options);
          const option = options.find((candidate) => {
            if (requestedValue !== null) return candidate.value === requestedValue;
            return normalizedLabel(candidate) === requestedLabel;
          });

          if (!option) {
            return result(false, "option_missing", "No select option matched the requested value or label.", metadata);
          }

          element.value = option.value;
          option.selected = true;
          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const selected = element.options[element.selectedIndex] || null;
          const selectedLabel = selected ? normalizedLabel(selected) : "";
          const matched = selected
            ? (requestedValue !== null ? selected.value === requestedValue : selectedLabel === requestedLabel)
            : false;
          return result(true, "selected", "The requested select option was selected.", {
            ...metadata,
            selectedIndex: element.selectedIndex,
            selectedValueLength: selected ? String(selected.value || "").length : null,
            selectedLabelLength: selectedLabel.length,
            matched
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a select result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools select result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserSelectOptionPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools select result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func setBrowserCheckedState(
        selector: String,
        checked: Bool,
        at webSocketURL: URL
    ) throws -> BrowserCheckedPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const requestedChecked = \(checked ? "true" : "false");
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
            requestedChecked,
            currentChecked: extra.currentChecked ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly, currentChecked: "checked" in element ? Boolean(element.checked) : null };

          if (tagName !== "input" || !["checkbox", "radio"].includes(inputType)) {
            return result(false, "unsupported_element", "The matched element is not a checkbox or radio input.", metadata);
          }
          if (disabled) {
            return result(false, "element_disabled", "The matched input is disabled.", metadata);
          }
          if (readOnly) {
            return result(false, "element_readonly", "The matched input is read-only.", metadata);
          }
          if (inputType === "radio" && requestedChecked === false) {
            return result(false, "unsupported_radio_uncheck", "Radio inputs can only be checked by this command.", metadata);
          }

          element.checked = requestedChecked;
          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const currentChecked = Boolean(element.checked);
          return result(true, "checked", "The requested checked state was applied.", {
            ...metadata,
            currentChecked,
            matched: currentChecked === requestedChecked
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a checked-state result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools checked-state result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserCheckedPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools checked-state result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserCheckedState(
        selector: String,
        expectedChecked: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserCheckedWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedChecked = \(expectedChecked ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedChecked,
            currentChecked: extra.currentChecked ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const currentChecked = "checked" in element ? Boolean(element.checked) : null;
          const metadata = { tagName, inputType, disabled, readOnly, currentChecked };

          if (tagName !== "input" || !["checkbox", "radio"].includes(inputType)) {
            return result(false, "unsupported_element", "The matched element is not a checkbox or radio input.", metadata);
          }

          const matched = currentChecked === expectedChecked;
          return result(
            matched,
            matched ? "checked_matched" : "checked_mismatch",
            matched
              ? "browser checked state matched expected value"
              : "browser checked state did not match expected value",
            { ...metadata, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a checked-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools checked-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserCheckedWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserCheckedWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedChecked: verification.expectedChecked,
                    currentChecked: verification.currentChecked,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools checked-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserValue(
        selector: String,
        expectedValue: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserValueWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedValue = \(try javascriptStringLiteral(expectedValue));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            currentValue: extra.currentValue ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly };

          if (!["input", "textarea", "select"].includes(tagName)) {
            return result(false, "unsupported_element", "The matched element does not expose a form value.", metadata);
          }
          if (inputType === "password") {
            return result(false, "unsupported_sensitive_input", "Password input values are not inspected by this command.", metadata);
          }

          const currentValue = String(element.value ?? "");
          const matched = match === "exact"
            ? currentValue === expectedValue
            : currentValue.includes(expectedValue);
          return result(
            matched,
            matched ? "value_matched" : "value_mismatch",
            matched
              ? `browser field value matched expected ${match} value`
              : `browser field value did not match expected ${match} value`,
            { ...metadata, currentValue, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a value wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools value wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserValueWaitPayload.self, from: data)
            return BrowserValueWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                expectedValueLength: expectedValue.count,
                expectedValueDigest: sha256Digest(expectedValue),
                currentValueLength: payload.currentValue?.count,
                currentValueDigest: payload.currentValue.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                inputType: payload.inputType,
                disabled: payload.disabled,
                readOnly: payload.readOnly,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools value wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserElementText(
        selector: String,
        expectedText: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserElementTextWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedText = \(try javascriptStringLiteral(expectedText));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            currentText: extra.currentText ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const rawText = "innerText" in element ? element.innerText : element.textContent;
          const currentText = String(rawText || "").replace(/\\s+/g, " ").trim();
          const matched = match === "exact"
            ? currentText === expectedText
            : currentText.includes(expectedText);
          return result(
            matched,
            matched ? "element_text_matched" : "element_text_mismatch",
            matched
              ? `browser element text matched expected ${match} value`
              : `browser element text did not match expected ${match} value`,
            { tagName, currentText, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an element text wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools element text wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserElementTextWaitPayload.self, from: data)
            return BrowserElementTextWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                expectedTextLength: expectedText.count,
                expectedTextDigest: sha256Digest(expectedText),
                currentTextLength: payload.currentText?.count,
                currentTextDigest: payload.currentText.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools element text wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func dispatchBrowserKey(
        _ key: BrowserKeyDefinition,
        modifiers: [String],
        modifierMask: Int,
        selector: String?,
        at webSocketURL: URL
    ) throws -> BrowserKeyPressVerification {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try JSONDecoder().decode(BrowserKeyPressVerification.self, from: data)
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        var downParams: [String: Any] = [
            "type": key.text == nil ? "rawKeyDown" : "keyDown",
            "key": key.key,
            "code": key.code,
            "windowsVirtualKeyCode": key.windowsVirtualKeyCode,
            "nativeVirtualKeyCode": key.windowsVirtualKeyCode,
            "modifiers": modifierMask
        ]
        if let text = key.text, modifierMask == 0 {
            downParams["text"] = text
            downParams["unmodifiedText"] = text
        }
        let upParams: [String: Any] = [
            "type": "keyUp",
            "key": key.key,
            "code": key.code,
            "windowsVirtualKeyCode": key.windowsVirtualKeyCode,
            "nativeVirtualKeyCode": key.windowsVirtualKeyCode,
            "modifiers": modifierMask
        ]

        let down = try sendCDPCommand(method: "Input.dispatchKeyEvent", params: downParams, at: webSocketURL, timeout: timeout)
        if let error = down.error {
            throw CommandError(description: "Chrome DevTools Input.dispatchKeyEvent keyDown failed with \(error.code): \(error.message)")
        }
        let up = try sendCDPCommand(method: "Input.dispatchKeyEvent", params: upParams, at: webSocketURL, timeout: timeout)
        if let error = up.error {
            throw CommandError(description: "Chrome DevTools Input.dispatchKeyEvent keyUp failed with \(error.code): \(error.message)")
        }

        return BrowserKeyPressVerification(
            ok: true,
            code: "key_pressed",
            message: "browser key press dispatched through Chrome DevTools",
            key: key.key,
            modifiers: modifiers,
            modifierMask: modifierMask,
            selector: selector,
            keyDownDispatched: true,
            keyUpDispatched: true
        )
    }

    private func focusBrowserElement(
        selector: String,
        at webSocketURL: URL
    ) throws -> BrowserFocusPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly };

          if (disabled) {
            return result(false, "element_disabled", "The matched element is disabled.", metadata);
          }
          if (typeof element.focus !== "function") {
            return result(false, "unsupported_element", "The matched element cannot receive focus.", metadata);
          }

          element.scrollIntoView({ block: "center", inline: "center" });
          element.focus({ preventScroll: true });

          const matched = document.activeElement === element;
          return result(
            matched,
            matched ? "focused" : "focus_mismatch",
            matched
              ? "The matched element received focus."
              : "The active element did not match the requested selector after focus.",
            { ...metadata, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a focus result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools focus result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserFocusPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools focus result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func clickBrowserElement(
        selector: String,
        at webSocketURL: URL
    ) throws -> BrowserClickPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            disabled: extra.disabled ?? null,
            href: extra.href || null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const disabled = Boolean(element.disabled);
          const href = element.href || element.getAttribute("href") || null;
          const metadata = { tagName, disabled, href, matched: true };

          if (disabled) {
            return result(false, "element_disabled", "The matched element is disabled.", metadata);
          }

          element.scrollIntoView({ block: "center", inline: "center" });
          element.click();
          return result(true, "clicked", "The matched element received a click.", metadata);
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a click result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools click result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserClickPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools click result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserSelector(
        selector: String,
        state: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserSelectorWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const state = \(try javascriptStringLiteral(state));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            state,
            matched: extra.matched || false,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            href: extra.href || null,
            textLength: extra.textLength ?? null
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            if (state === "detached" || state === "hidden") {
              return result(true, state === "detached" ? "selector_detached" : "selector_hidden", `The selector reached '${state}' state.`, {
                matched: true
              });
            }
            return result(false, "selector_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const href = element.href || element.getAttribute?.("href") || null;
          const text = (element.innerText || element.textContent || "").replace(/\\s+/g, " ").trim();
          const metadata = { tagName, inputType, disabled, readOnly, href, textLength: text.length, matched: true };
          const style = window.getComputedStyle(element);
          const rect = element.getBoundingClientRect();
          const visible = rect.width > 0
            && rect.height > 0
            && style.display !== "none"
            && style.visibility !== "hidden"
            && style.visibility !== "collapse"
            && style.opacity !== "0";

          if (state === "visible") {
            if (!visible) {
              return result(false, "selector_not_visible", "The matched element is not visible.", {
                ...metadata,
                matched: false
              });
            }
          } else if (state === "hidden") {
            if (visible) {
              return result(false, "selector_still_visible", "The matched element is still visible.", {
                ...metadata,
                matched: false
              });
            }
            return result(true, "selector_hidden", "The selector reached 'hidden' state.", metadata);
          } else if (state === "detached") {
            return result(false, "selector_still_attached", "The matched element is still attached.", {
              ...metadata,
              matched: false
            });
          }

          return result(true, "selector_matched", `The selector reached '${state}' state.`, metadata);
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a selector wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools selector wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserSelectorWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserSelectorWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    state: verification.state,
                    matched: verification.matched,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    href: verification.href,
                    textLength: verification.textLength
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools selector wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserCount(
        selector: String,
        expectedCount: Int,
        countMatch: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserCountWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedCount = \(expectedCount);
          const countMatch = \(try javascriptStringLiteral(countMatch));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedCount,
            currentCount: extra.currentCount ?? null,
            currentURL: location.href || null,
            countMatch,
            matched: extra.matched || false
          });

          let elements = null;
          try {
            elements = document.querySelectorAll(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          const currentCount = elements.length;
          const matched = countMatch === "exact"
            ? currentCount === expectedCount
            : countMatch === "at-least"
              ? currentCount >= expectedCount
              : currentCount <= expectedCount;
          return result(
            matched,
            matched ? "count_matched" : "count_mismatch",
            matched
              ? `browser selector count matched expected ${countMatch} value`
              : `browser selector count did not match expected ${countMatch} value`,
            { currentCount, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a selector count wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools selector count wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserCountWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserCountWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedCount: verification.expectedCount,
                    currentCount: verification.currentCount,
                    currentURL: currentURL,
                    countMatch: verification.countMatch,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools selector count wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserEnabledState(
        selector: String,
        expectedEnabled: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserEnabledWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedEnabled = \(expectedEnabled ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedEnabled,
            currentEnabled: extra.currentEnabled ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const nativeDisabled = "disabled" in element ? Boolean(element.disabled) : false;
          const ariaDisabled = String(element.getAttribute("aria-disabled") || "").toLowerCase() === "true";
          const disabled = nativeDisabled || ariaDisabled;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const currentEnabled = !disabled;
          const matched = currentEnabled === expectedEnabled;
          return result(
            matched,
            matched ? "enabled_matched" : "enabled_mismatch",
            matched
              ? "browser element enabled state matched expected value"
              : "browser element enabled state did not match expected value",
            { tagName, inputType, disabled, readOnly, currentEnabled, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an enabled-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools enabled-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserEnabledWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserEnabledWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedEnabled: verification.expectedEnabled,
                    currentEnabled: verification.currentEnabled,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools enabled-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserFocusState(
        selector: String,
        expectedFocused: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserFocusWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedFocused = \(expectedFocused ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedFocused,
            currentFocused: extra.currentFocused ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            activeTagName: extra.activeTagName || null,
            activeInputType: extra.activeInputType || null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const active = document.activeElement || null;
          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const activeTagName = active && active.tagName ? active.tagName.toLowerCase() : null;
          const activeInputType = activeTagName === "input" ? (active.getAttribute("type") || "text").toLowerCase() : null;
          const currentFocused = active === element;
          const matched = currentFocused === expectedFocused;
          return result(
            matched,
            matched ? "focus_matched" : "focus_mismatch",
            matched
              ? "browser element focus state matched expected value"
              : "browser element focus state did not match expected value",
            { tagName, inputType, activeTagName, activeInputType, currentFocused, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a focus-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools focus-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserFocusWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserFocusWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedFocused: verification.expectedFocused,
                    currentFocused: verification.currentFocused,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    activeTagName: verification.activeTagName,
                    activeInputType: verification.activeInputType,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools focus-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserAttribute(
        selector: String,
        attribute: String,
        expectedValue: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserAttributeWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const attribute = \(try javascriptStringLiteral(attribute));
          const expectedValue = \(try javascriptStringLiteral(expectedValue));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            attribute,
            currentValue: extra.currentValue ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const currentValue = element.hasAttribute(attribute) ? String(element.getAttribute(attribute) || "") : null;
          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const matched = currentValue !== null && (
            match === "exact" ? currentValue === expectedValue : currentValue.includes(expectedValue)
          );
          return result(
            matched,
            matched ? "attribute_matched" : currentValue === null ? "attribute_missing" : "attribute_mismatch",
            matched
              ? `browser attribute matched expected ${match} value`
              : currentValue === null
                ? "browser attribute is missing"
                : `browser attribute did not match expected ${match} value`,
            { tagName, currentValue, matched }
          );
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an attribute wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools attribute wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserAttributeWaitPayload.self, from: data)
            return BrowserAttributeWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                attribute: payload.attribute,
                expectedValueLength: expectedValue.count,
                expectedValueDigest: sha256Digest(expectedValue),
                currentValueLength: payload.currentValue?.count,
                currentValueDigest: payload.currentValue.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools attribute wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    private func inspectBrowserReadyState(
        expectedState: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserReadyWaitVerification {
        let expression = """
        (() => {
          const expectedState = \(try javascriptStringLiteral(expectedState));
          const stateOrder = { loading: 0, interactive: 1, complete: 2 };
          const currentState = document.readyState || null;
          const matched = currentState
            ? stateOrder[currentState] >= stateOrder[expectedState]
            : false;
          return JSON.stringify({
            ok: matched,
            code: matched ? "ready_state_matched" : "ready_state_pending",
            message: matched
              ? `browser document ready state reached ${expectedState}`
              : `browser document ready state has not reached ${expectedState}`,
            expectedState,
            currentState,
            currentURL: location.href || null,
            matched
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a ready-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools ready-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserReadyWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserReadyWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    expectedState: verification.expectedState,
                    currentState: verification.currentState,
                    currentURL: currentURL,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools ready-state wait result was not valid JSON: \(error.localizedDescription)")
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

    private func waitForBrowserSelector(
        tabID: String,
        selector: String,
        state: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserSelectorWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserSelectorWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserSelectorWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    state: state,
                    matched: false,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    href: nil,
                    textLength: nil
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserSelector(
                selector: selector,
                state: state,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserSelectorWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "selector_missing",
            message: "browser selector did not reach \(state) state before timeout",
            selector: selector,
            state: state,
            matched: false,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            href: lastVerification?.href,
            textLength: lastVerification?.textLength
        )
    }

    private func waitForBrowserCount(
        tabID: String,
        selector: String,
        expectedCount: Int,
        countMatch: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserCountWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserCountWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserCountWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedCount: expectedCount,
                    currentCount: nil,
                    currentURL: nil,
                    countMatch: countMatch,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserCount(
                selector: selector,
                expectedCount: expectedCount,
                countMatch: countMatch,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserCountWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "count_mismatch",
            message: "browser selector count did not match expected \(countMatch) value before timeout",
            selector: selector,
            expectedCount: expectedCount,
            currentCount: lastVerification?.currentCount,
            currentURL: lastVerification?.currentURL,
            countMatch: countMatch,
            matched: false
        )
    }

    private func waitForBrowserReady(
        tabID: String,
        expectedState: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserReadyWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserReadyWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserReadyWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    expectedState: expectedState,
                    currentState: nil,
                    currentURL: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserReadyState(
                expectedState: expectedState,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserReadyWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "ready_state_unavailable",
            message: "browser document ready state did not reach \(expectedState) before timeout",
            expectedState: expectedState,
            currentState: lastVerification?.currentState,
            currentURL: lastVerification?.currentURL,
            matched: false
        )
    }

    private func waitForBrowserTitle(
        tabID: String,
        expectedTitle: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserTitleWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentTitle: String?
        var currentURL: String?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            if let tab = tabs.first(where: { $0.id == tabID }) {
                currentTitle = tab.title
                currentURL = tab.url
                if browserTitle(currentTitle, matches: expectedTitle, mode: match) {
                    return BrowserTitleWaitVerification(
                        ok: true,
                        code: "title_matched",
                        message: "browser tab title matched expected \(match) value",
                        expectedTitle: expectedTitle,
                        currentTitle: currentTitle,
                        currentURL: currentURL,
                        match: match,
                        matched: true
                    )
                }
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserTitleWaitVerification(
            ok: false,
            code: currentTitle == nil ? "title_unavailable" : "title_mismatch",
            message: "browser tab title did not match expected \(match) value before timeout",
            expectedTitle: expectedTitle,
            currentTitle: currentTitle,
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }

    private func waitForBrowserChecked(
        tabID: String,
        selector: String,
        expectedChecked: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserCheckedWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserCheckedWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserCheckedWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedChecked: expectedChecked,
                    currentChecked: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserCheckedState(
                selector: selector,
                expectedChecked: expectedChecked,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" || verification.code == "unsupported_element" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserCheckedWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "checked_mismatch",
            message: "browser checked state did not match expected value before timeout",
            selector: selector,
            expectedChecked: expectedChecked,
            currentChecked: lastVerification?.currentChecked,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            matched: false
        )
    }

    private func waitForBrowserEnabled(
        tabID: String,
        selector: String,
        expectedEnabled: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserEnabledWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserEnabledWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserEnabledWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedEnabled: expectedEnabled,
                    currentEnabled: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserEnabledState(
                selector: selector,
                expectedEnabled: expectedEnabled,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserEnabledWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "enabled_mismatch",
            message: "browser enabled state did not match expected value before timeout",
            selector: selector,
            expectedEnabled: expectedEnabled,
            currentEnabled: lastVerification?.currentEnabled,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            matched: false
        )
    }

    private func waitForBrowserFocus(
        tabID: String,
        selector: String,
        expectedFocused: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserFocusWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserFocusWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserFocusWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedFocused: expectedFocused,
                    currentFocused: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    activeTagName: nil,
                    activeInputType: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserFocusState(
                selector: selector,
                expectedFocused: expectedFocused,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserFocusWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "focus_mismatch",
            message: "browser focus state did not match expected value before timeout",
            selector: selector,
            expectedFocused: expectedFocused,
            currentFocused: lastVerification?.currentFocused,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            activeTagName: lastVerification?.activeTagName,
            activeInputType: lastVerification?.activeInputType,
            matched: false
        )
    }

    private func waitForBrowserAttribute(
        tabID: String,
        selector: String,
        attribute: String,
        expectedValue: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserAttributeWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserAttributeWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserAttributeWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    attribute: attribute,
                    expectedValueLength: expectedValue.count,
                    expectedValueDigest: sha256Digest(expectedValue),
                    currentValueLength: nil,
                    currentValueDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserAttribute(
                selector: selector,
                attribute: attribute,
                expectedValue: expectedValue,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserAttributeWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "attribute_mismatch",
            message: "browser attribute did not match expected \(match) value before timeout",
            selector: selector,
            attribute: attribute,
            expectedValueLength: expectedValue.count,
            expectedValueDigest: sha256Digest(expectedValue),
            currentValueLength: lastVerification?.currentValueLength,
            currentValueDigest: lastVerification?.currentValueDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            match: match,
            matched: false
        )
    }

    private func waitForBrowserValue(
        tabID: String,
        selector: String,
        expectedValue: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserValueWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserValueWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserValueWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedValueLength: expectedValue.count,
                    expectedValueDigest: sha256Digest(expectedValue),
                    currentValueLength: nil,
                    currentValueDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserValue(
                selector: selector,
                expectedValue: expectedValue,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok
                || verification.code == "selector_invalid"
                || verification.code == "unsupported_element"
                || verification.code == "unsupported_sensitive_input" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserValueWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "value_mismatch",
            message: "browser field value did not match expected \(match) value before timeout",
            selector: selector,
            expectedValueLength: expectedValue.count,
            expectedValueDigest: sha256Digest(expectedValue),
            currentValueLength: lastVerification?.currentValueLength,
            currentValueDigest: lastVerification?.currentValueDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            match: match,
            matched: false
        )
    }

    private func waitForBrowserText(
        tabID: String,
        expectedText: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserTextWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentText: String?
        var currentURL: String?
        let expectedDigest = sha256Digest(expectedText)

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            currentURL = tab.url
            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }
            currentText = try readBrowserInnerText(from: webSocketURL)
            if browserText(currentText, matches: expectedText, mode: match) {
                return BrowserTextWaitVerification(
                    ok: true,
                    code: "text_matched",
                    message: "browser tab text matched expected \(match) value",
                    expectedTextLength: expectedText.count,
                    expectedTextDigest: expectedDigest,
                    currentTextLength: currentText?.count,
                    currentTextDigest: currentText.map(sha256Digest),
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

        return BrowserTextWaitVerification(
            ok: false,
            code: currentText == nil ? "text_unavailable" : "text_mismatch",
            message: "browser tab text did not match expected \(match) value before timeout",
            expectedTextLength: expectedText.count,
            expectedTextDigest: expectedDigest,
            currentTextLength: currentText?.count,
            currentTextDigest: currentText.map(sha256Digest),
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }

    private func waitForBrowserElementText(
        tabID: String,
        selector: String,
        expectedText: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserElementTextWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserElementTextWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserElementTextWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedTextLength: expectedText.count,
                    expectedTextDigest: sha256Digest(expectedText),
                    currentTextLength: nil,
                    currentTextDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserElementText(
                selector: selector,
                expectedText: expectedText,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserElementTextWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "element_text_mismatch",
            message: "browser element text did not match expected \(match) value before timeout",
            selector: selector,
            expectedTextLength: expectedText.count,
            expectedTextDigest: sha256Digest(expectedText),
            currentTextLength: lastVerification?.currentTextLength,
            currentTextDigest: lastVerification?.currentTextDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
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

    private func browserText(_ currentText: String?, matches expectedText: String, mode: String) -> Bool {
        stringValue(currentText, matches: expectedText, mode: mode)
    }

    private func stringValue(_ currentValue: String?, matches expectedValue: String, mode: String) -> Bool {
        guard let currentValue else {
            return false
        }

        switch mode {
        case "exact":
            return currentValue == expectedValue
        case "contains":
            return currentValue.contains(expectedValue)
        default:
            return false
        }
    }

    private func browserTitle(_ currentTitle: String?, matches expectedTitle: String, mode: String) -> Bool {
        guard let currentTitle else {
            return false
        }

        switch mode {
        case "exact":
            return currentTitle == expectedTitle
        case "contains":
            return currentTitle.contains(expectedTitle)
        default:
            return false
        }
    }

    private func browserTextMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser text match mode '\(rawMode)'. Use exact or contains.")
        }
    }

    private func browserTitleMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser title match mode '\(rawMode)'. Use exact or contains.")
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

    private func browserSelectorWaitState(_ rawState: String) throws -> String {
        switch rawState {
        case "attached", "visible", "hidden", "detached":
            return rawState
        default:
            throw CommandError(description: "unsupported browser selector wait state '\(rawState)'. Use attached, visible, hidden, or detached.")
        }
    }

    private func browserSelectorCountValue(_ rawCount: String) throws -> Int {
        guard let count = Int(rawCount), count >= 0 else {
            throw CommandError(description: "unsupported browser selector count '\(rawCount)'. Use a non-negative integer.")
        }
        return count
    }

    private func browserCountMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "at-least", "at-most":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser count match mode '\(rawMode)'. Use exact, at-least, or at-most.")
        }
    }

    private func browserReadyState(_ rawState: String) throws -> String {
        switch rawState {
        case "loading", "interactive", "complete":
            return rawState
        default:
            throw CommandError(description: "unsupported browser ready state '\(rawState)'. Use loading, interactive, or complete.")
        }
    }

    private func browserCheckedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser checked value '\(rawValue)'. Use true or false.")
        }
    }

    private func browserEnabledValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser enabled value '\(rawValue)'. Use true or false.")
        }
    }

    private func browserFocusedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser focused value '\(rawValue)'. Use true or false.")
        }
    }

    private func browserKeyDefinition(for rawKey: String) throws -> BrowserKeyDefinition {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CommandError(description: "browser key must not be empty")
        }

        let namedKeys: [String: BrowserKeyDefinition] = [
            "enter": BrowserKeyDefinition(key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r"),
            "return": BrowserKeyDefinition(key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r"),
            "tab": BrowserKeyDefinition(key: "Tab", code: "Tab", windowsVirtualKeyCode: 9, text: "\t"),
            "escape": BrowserKeyDefinition(key: "Escape", code: "Escape", windowsVirtualKeyCode: 27, text: nil),
            "esc": BrowserKeyDefinition(key: "Escape", code: "Escape", windowsVirtualKeyCode: 27, text: nil),
            "backspace": BrowserKeyDefinition(key: "Backspace", code: "Backspace", windowsVirtualKeyCode: 8, text: nil),
            "delete": BrowserKeyDefinition(key: "Delete", code: "Delete", windowsVirtualKeyCode: 46, text: nil),
            "arrowup": BrowserKeyDefinition(key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38, text: nil),
            "up": BrowserKeyDefinition(key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38, text: nil),
            "arrowdown": BrowserKeyDefinition(key: "ArrowDown", code: "ArrowDown", windowsVirtualKeyCode: 40, text: nil),
            "down": BrowserKeyDefinition(key: "ArrowDown", code: "ArrowDown", windowsVirtualKeyCode: 40, text: nil),
            "arrowleft": BrowserKeyDefinition(key: "ArrowLeft", code: "ArrowLeft", windowsVirtualKeyCode: 37, text: nil),
            "left": BrowserKeyDefinition(key: "ArrowLeft", code: "ArrowLeft", windowsVirtualKeyCode: 37, text: nil),
            "arrowright": BrowserKeyDefinition(key: "ArrowRight", code: "ArrowRight", windowsVirtualKeyCode: 39, text: nil),
            "right": BrowserKeyDefinition(key: "ArrowRight", code: "ArrowRight", windowsVirtualKeyCode: 39, text: nil),
            "home": BrowserKeyDefinition(key: "Home", code: "Home", windowsVirtualKeyCode: 36, text: nil),
            "end": BrowserKeyDefinition(key: "End", code: "End", windowsVirtualKeyCode: 35, text: nil),
            "pageup": BrowserKeyDefinition(key: "PageUp", code: "PageUp", windowsVirtualKeyCode: 33, text: nil),
            "pagedown": BrowserKeyDefinition(key: "PageDown", code: "PageDown", windowsVirtualKeyCode: 34, text: nil),
            "space": BrowserKeyDefinition(key: " ", code: "Space", windowsVirtualKeyCode: 32, text: " ")
        ]
        if let named = namedKeys[trimmed.lowercased()] {
            return named
        }

        if let functionKey = browserFunctionKeyDefinition(for: trimmed) {
            return functionKey
        }

        guard trimmed.range(of: #"^[A-Za-z0-9]$"#, options: .regularExpression) != nil,
              let scalar = trimmed.uppercased().unicodeScalars.first else {
            throw CommandError(description: "unsupported browser key '\(rawKey)'. Use a named key, function key, or one ASCII letter/digit.")
        }
        let upper = String(scalar)
        let lower = trimmed.lowercased()
        let code = scalar.properties.isAlphabetic ? "Key\(upper)" : "Digit\(upper)"
        return BrowserKeyDefinition(key: lower, code: code, windowsVirtualKeyCode: Int(scalar.value), text: lower)
    }

    private func browserFunctionKeyDefinition(for rawKey: String) -> BrowserKeyDefinition? {
        let upper = rawKey.uppercased()
        guard upper.range(of: #"^F([1-9]|1[0-2])$"#, options: .regularExpression) != nil,
              let number = Int(upper.dropFirst()) else {
            return nil
        }
        return BrowserKeyDefinition(key: upper, code: upper, windowsVirtualKeyCode: 111 + number, text: nil)
    }

    private func browserModifierSet(_ rawModifiers: String?) throws -> [String] {
        guard let rawModifiers, !rawModifiers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        var normalized: [String] = []
        for rawPart in rawModifiers.split(separator: ",") {
            let part = rawPart.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let modifier: String
            switch part {
            case "shift":
                modifier = "shift"
            case "control", "ctrl":
                modifier = "control"
            case "alt", "option":
                modifier = "alt"
            case "meta", "command", "cmd":
                modifier = "meta"
            default:
                throw CommandError(description: "unsupported browser key modifier '\(part)'. Use shift, control, alt, or meta.")
            }
            if !normalized.contains(modifier) {
                normalized.append(modifier)
            }
        }
        return normalized
    }

    private func browserModifierMask(_ rawModifiers: String) throws -> Int {
        browserModifierMask(for: try browserModifierSet(rawModifiers))
    }

    private func browserModifierMask(for modifiers: [String]) -> Int {
        var mask = 0
        if modifiers.contains("alt") {
            mask |= 1
        }
        if modifiers.contains("control") {
            mask |= 2
        }
        if modifiers.contains("meta") {
            mask |= 4
        }
        if modifiers.contains("shift") {
            mask |= 8
        }
        return mask
    }

    private func validatedBrowserSelector(_ rawSelector: String) throws -> String {
        guard !rawSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommandError(description: "browser selector must not be empty")
        }
        return rawSelector
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

    private func validatedBrowserExpectedText(_ rawText: String) throws -> String {
        guard !rawText.isEmpty else {
            throw CommandError(description: "browser expected text must not be empty")
        }
        return rawText
    }

    private func validatedBrowserAttributeName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else {
            throw CommandError(description: "browser attribute name must not be empty")
        }
        guard name.range(of: #"^[a-z_:][a-z0-9_:.:-]*$"#, options: .regularExpression) != nil else {
            throw CommandError(description: "browser attribute name '\(rawName)' is not supported")
        }
        return name
    }

    private func validatedBrowserExpectedTitle(_ rawTitle: String) throws -> String {
        guard !rawTitle.isEmpty else {
            throw CommandError(description: "browser expected title must not be empty")
        }
        return rawTitle
    }

    private func validatedBrowserSelectOption(_ rawOption: String, optionName: String) throws -> String {
        guard !rawOption.isEmpty else {
            throw CommandError(description: "browser select \(optionName) must not be empty")
        }
        return rawOption
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
        let normalizedAlgorithm = try normalizedChecksumAlgorithm(algorithm)

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

    private func fileText(
        for url: URL,
        maxCharacters: Int,
        maxFileBytes: Int,
        selection: String
    ) throws -> FilesystemTextResult {
        let suffix = selection == "suffix"
        let action = suffix ? "filesystem.tailText" : "filesystem.readText"
        let command = suffix ? "files.tail-text" : "files.read-text"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: command,
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
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

            let record = try fileRecord(for: url)
            sourceTarget = fileAuditTarget(record: record, exists: true)

            guard record.kind == "regularFile" else {
                let message = "\(action) currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard record.readable else {
                let message = "source file is not readable at \(url.path)"
                try writeAudit(ok: false, code: "source_unreadable", message: message)
                throw CommandError(description: message)
            }

            if let size = record.sizeBytes, size > maxFileBytes {
                let message = "file size \(size) exceeds --max-file-bytes \(maxFileBytes)"
                try writeAudit(ok: false, code: "file_too_large", message: message)
                throw CommandError(description: message)
            }

            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .utf8) else {
                let message = "file is not valid UTF-8 text at \(url.path)"
                try writeAudit(ok: false, code: "unsupported_encoding", message: message)
                throw CommandError(description: message)
            }

            let text: String
            let truncated: Bool
            if string.count > maxCharacters {
                text = suffix
                    ? String(string.suffix(maxCharacters))
                    : String(string.prefix(maxCharacters))
                truncated = true
            } else {
                text = string
                truncated = false
            }

            let message: String
            if suffix {
                message = truncated
                    ? "Read truncated tail text from \(url.path)."
                    : "Read tail text from \(url.path)."
            } else {
                message = truncated
                    ? "Read truncated text from \(url.path)."
                    : "Read text from \(url.path)."
            }
            try writeAudit(ok: true, code: suffix ? "tail_text" : "read_text", message: message)

            return FilesystemTextResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                file: record,
                text: text,
                selection: selection,
                textLength: string.count,
                textDigest: sha256Digest(string),
                byteLength: data.count,
                truncated: truncated,
                maxCharacters: maxCharacters,
                maxFileBytes: maxFileBytes,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func fileLines(
        for url: URL,
        startLine: Int,
        lineCount: Int,
        maxLineCharacters: Int,
        maxFileBytes: Int
    ) throws -> FilesystemLinesResult {
        let action = "filesystem.readLines"
        let command = "files.read-lines"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: command,
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
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

            let record = try fileRecord(for: url)
            sourceTarget = fileAuditTarget(record: record, exists: true)

            guard record.kind == "regularFile" else {
                let message = "\(action) currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard record.readable else {
                let message = "source file is not readable at \(url.path)"
                try writeAudit(ok: false, code: "source_unreadable", message: message)
                throw CommandError(description: message)
            }

            if let size = record.sizeBytes, size > maxFileBytes {
                let message = "file size \(size) exceeds --max-file-bytes \(maxFileBytes)"
                try writeAudit(ok: false, code: "file_too_large", message: message)
                throw CommandError(description: message)
            }

            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .utf8) else {
                let message = "file is not valid UTF-8 text at \(url.path)"
                try writeAudit(ok: false, code: "unsupported_encoding", message: message)
                throw CommandError(description: message)
            }

            let allLines = string.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            let zeroBasedStart = max(0, startLine - 1)
            let selected = allLines.dropFirst(zeroBasedStart).prefix(lineCount)
            var lineTextTruncated = false
            let lines = selected.enumerated().map { offset, line -> FileLineMatch in
                if line.count > maxLineCharacters {
                    lineTextTruncated = true
                }
                return FileLineMatch(
                    lineNumber: startLine + offset,
                    text: String(line.prefix(maxLineCharacters))
                )
            }
            let rangeHasMore = lineCount > 0 && zeroBasedStart + lineCount < allLines.count
            let truncated = lineTextTruncated || rangeHasMore
            let message = truncated
                ? "Read truncated line range from \(url.path)."
                : "Read line range from \(url.path)."
            try writeAudit(ok: true, code: "read_lines", message: message)

            return FilesystemLinesResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                file: record,
                startLine: startLine,
                requestedLineCount: lineCount,
                returnedLineCount: lines.count,
                totalLineCount: allLines.count,
                lines: lines,
                truncated: truncated,
                maxLineCharacters: maxLineCharacters,
                maxFileBytes: maxFileBytes,
                textDigest: sha256Digest(string),
                byteLength: data.count,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func fileJSON(
        for url: URL,
        pointer: String?,
        maxDepth: Int,
        maxItems: Int,
        maxStringCharacters: Int,
        maxFileBytes: Int
    ) throws -> FilesystemJSONResult {
        let action = "filesystem.readJSON"
        let command = "files.read-json"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: command,
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
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

            let record = try fileRecord(for: url)
            sourceTarget = fileAuditTarget(record: record, exists: true)

            guard record.kind == "regularFile" else {
                let message = "\(action) currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard record.readable else {
                let message = "source file is not readable at \(url.path)"
                try writeAudit(ok: false, code: "source_unreadable", message: message)
                throw CommandError(description: message)
            }

            if let size = record.sizeBytes, size > maxFileBytes {
                let message = "file size \(size) exceeds --max-file-bytes \(maxFileBytes)"
                try writeAudit(ok: false, code: "file_too_large", message: message)
                throw CommandError(description: message)
            }

            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .utf8) else {
                let message = "file is not valid UTF-8 text at \(url.path)"
                try writeAudit(ok: false, code: "unsupported_encoding", message: message)
                throw CommandError(description: message)
            }

            let parsed: Any
            do {
                parsed = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            } catch {
                let message = "file is not valid JSON at \(url.path): \(error.localizedDescription)"
                try writeAudit(ok: false, code: "invalid_json", message: message)
                throw CommandError(description: message)
            }

            let selected = try jsonValue(at: pointer ?? "", in: parsed)
            var value: BoundedJSONNode?
            var valueType: String?
            var truncated = false
            if selected.found, let selectedValue = selected.value {
                value = try boundedJSONNode(
                    from: selectedValue,
                    depth: 0,
                    maxDepth: maxDepth,
                    maxItems: maxItems,
                    maxStringCharacters: maxStringCharacters,
                    truncated: &truncated
                )
                valueType = value?.type
            }

            let message: String
            if selected.found {
                message = truncated
                    ? "Read truncated JSON value from \(url.path)."
                    : "Read JSON value from \(url.path)."
            } else {
                message = "JSON pointer was not found in \(url.path)."
            }
            try writeAudit(ok: true, code: selected.found ? "read_json" : "json_pointer_missing", message: message)

            return FilesystemJSONResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                file: record,
                pointer: pointer,
                found: selected.found,
                valueType: valueType,
                value: value,
                truncated: truncated,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                maxFileBytes: maxFileBytes,
                textDigest: sha256Digest(string),
                byteLength: data.count,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func filePropertyList(
        for url: URL,
        pointer: String?,
        maxDepth: Int,
        maxItems: Int,
        maxStringCharacters: Int,
        maxFileBytes: Int
    ) throws -> FilesystemPropertyListResult {
        let action = "filesystem.readPropertyList"
        let command = "files.read-plist"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var sourceTarget = FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: command,
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: sourceTarget,
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

            let record = try fileRecord(for: url)
            sourceTarget = fileAuditTarget(record: record, exists: true)

            guard record.kind == "regularFile" else {
                let message = "\(action) currently supports regular files only"
                try writeAudit(ok: false, code: "unsupported_source_kind", message: message)
                throw CommandError(description: message)
            }

            guard record.readable else {
                let message = "source file is not readable at \(url.path)"
                try writeAudit(ok: false, code: "source_unreadable", message: message)
                throw CommandError(description: message)
            }

            if let size = record.sizeBytes, size > maxFileBytes {
                let message = "file size \(size) exceeds --max-file-bytes \(maxFileBytes)"
                try writeAudit(ok: false, code: "file_too_large", message: message)
                throw CommandError(description: message)
            }

            let data = try Data(contentsOf: url)
            var format = PropertyListSerialization.PropertyListFormat.xml
            let parsed: Any
            do {
                parsed = try PropertyListSerialization.propertyList(
                    from: data,
                    options: [],
                    format: &format
                )
            } catch {
                let message = "file is not a valid property list at \(url.path): \(error.localizedDescription)"
                try writeAudit(ok: false, code: "invalid_plist", message: message)
                throw CommandError(description: message)
            }

            let selected = try structuredValue(at: pointer ?? "", in: parsed)
            var value: BoundedPropertyListNode?
            var valueType: String?
            var truncated = false
            if selected.found, let selectedValue = selected.value {
                value = try boundedPropertyListNode(
                    from: selectedValue,
                    depth: 0,
                    maxDepth: maxDepth,
                    maxItems: maxItems,
                    maxStringCharacters: maxStringCharacters,
                    truncated: &truncated
                )
                valueType = value?.type
            }

            let message: String
            if selected.found {
                message = truncated
                    ? "Read truncated property list value from \(url.path)."
                    : "Read property list value from \(url.path)."
            } else {
                message = "Property list pointer was not found in \(url.path)."
            }
            try writeAudit(ok: true, code: selected.found ? "read_plist" : "plist_pointer_missing", message: message)

            return FilesystemPropertyListResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                file: record,
                pointer: pointer,
                found: selected.found,
                valueType: valueType,
                value: value,
                truncated: truncated,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                maxFileBytes: maxFileBytes,
                format: propertyListFormatName(format),
                byteLength: data.count,
                digest: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func jsonValue(at pointer: String, in root: Any) throws -> (found: Bool, value: Any?) {
        guard !pointer.isEmpty else {
            return (true, root)
        }
        guard pointer.hasPrefix("/") else {
            throw CommandError(description: "--pointer must be an empty string or a JSON Pointer starting with '/'")
        }

        let tokens = pointer
            .dropFirst()
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { token in
                token.replacingOccurrences(of: "~1", with: "/")
                    .replacingOccurrences(of: "~0", with: "~")
            }
        var current = root

        for token in tokens {
            if let object = current as? [String: Any] {
                guard let next = object[token] else {
                    return (false, nil)
                }
                current = next
                continue
            }

            if let array = current as? [Any] {
                guard let index = Int(token), index >= 0, index < array.count else {
                    return (false, nil)
                }
                current = array[index]
                continue
            }

            return (false, nil)
        }

        return (true, current)
    }

    private func structuredValue(at pointer: String, in root: Any) throws -> (found: Bool, value: Any?) {
        guard !pointer.isEmpty else {
            return (true, root)
        }
        guard pointer.hasPrefix("/") else {
            throw CommandError(description: "--pointer must be an empty string or a pointer starting with '/'")
        }

        let tokens = pointer
            .dropFirst()
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { token in
                token.replacingOccurrences(of: "~1", with: "/")
                    .replacingOccurrences(of: "~0", with: "~")
            }
        var current = root

        for token in tokens {
            if let object = current as? [String: Any] {
                guard let next = object[token] else {
                    return (false, nil)
                }
                current = next
                continue
            }

            if let object = current as? [AnyHashable: Any] {
                guard let next = object[token] else {
                    return (false, nil)
                }
                current = next
                continue
            }

            if let array = current as? [Any] {
                guard let index = Int(token), index >= 0, index < array.count else {
                    return (false, nil)
                }
                current = array[index]
                continue
            }

            return (false, nil)
        }

        return (true, current)
    }

    private func boundedJSONNode(
        from value: Any,
        depth: Int,
        maxDepth: Int,
        maxItems: Int,
        maxStringCharacters: Int,
        truncated: inout Bool
    ) throws -> BoundedJSONNode {
        switch value {
        case let object as [String: Any]:
            let keys = object.keys.sorted()
            guard depth < maxDepth else {
                let nodeTruncated = !keys.isEmpty
                truncated = truncated || nodeTruncated
                return BoundedJSONNode(
                    type: "object",
                    value: nil,
                    entries: nil,
                    items: nil,
                    count: keys.count,
                    truncated: nodeTruncated
                )
            }

            let limitedKeys = Array(keys.prefix(maxItems))
            let nodeTruncated = limitedKeys.count < keys.count
            truncated = truncated || nodeTruncated
            let entries = try limitedKeys.map { key -> BoundedJSONProperty in
                guard let child = object[key] else {
                    throw CommandError(description: "JSON object changed during bounded encoding")
                }
                return BoundedJSONProperty(
                    key: key,
                    value: try boundedJSONNode(
                        from: child,
                        depth: depth + 1,
                        maxDepth: maxDepth,
                        maxItems: maxItems,
                        maxStringCharacters: maxStringCharacters,
                        truncated: &truncated
                    )
                )
            }
            return BoundedJSONNode(
                type: "object",
                value: nil,
                entries: entries,
                items: nil,
                count: keys.count,
                truncated: nodeTruncated
            )
        case let array as [Any]:
            guard depth < maxDepth else {
                let nodeTruncated = !array.isEmpty
                truncated = truncated || nodeTruncated
                return BoundedJSONNode(
                    type: "array",
                    value: nil,
                    entries: nil,
                    items: nil,
                    count: array.count,
                    truncated: nodeTruncated
                )
            }

            let limitedItems = Array(array.prefix(maxItems))
            let nodeTruncated = limitedItems.count < array.count
            truncated = truncated || nodeTruncated
            let items = try limitedItems.map {
                try boundedJSONNode(
                    from: $0,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    maxItems: maxItems,
                    maxStringCharacters: maxStringCharacters,
                    truncated: &truncated
                )
            }
            return BoundedJSONNode(
                type: "array",
                value: nil,
                entries: nil,
                items: items,
                count: array.count,
                truncated: nodeTruncated
            )
        case let string as String:
            let nodeTruncated = string.count > maxStringCharacters
            truncated = truncated || nodeTruncated
            return BoundedJSONNode(
                type: "string",
                value: .string(String(string.prefix(maxStringCharacters))),
                entries: nil,
                items: nil,
                count: string.count,
                truncated: nodeTruncated
            )
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return BoundedJSONNode(
                    type: "boolean",
                    value: .bool(number.boolValue),
                    entries: nil,
                    items: nil,
                    count: nil,
                    truncated: false
                )
            }
            return BoundedJSONNode(
                type: "number",
                value: .number(number.doubleValue),
                entries: nil,
                items: nil,
                count: nil,
                truncated: false
            )
        case _ as NSNull:
            return BoundedJSONNode(
                type: "null",
                value: .null,
                entries: nil,
                items: nil,
                count: nil,
                truncated: false
            )
        default:
            throw CommandError(description: "unsupported JSON value while encoding bounded JSON")
        }
    }

    private func boundedPropertyListNode(
        from value: Any,
        depth: Int,
        maxDepth: Int,
        maxItems: Int,
        maxStringCharacters: Int,
        truncated: inout Bool
    ) throws -> BoundedPropertyListNode {
        switch value {
        case let object as [String: Any]:
            return try boundedPropertyListDictionaryNode(
                object,
                depth: depth,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                truncated: &truncated
            )
        case let object as [AnyHashable: Any]:
            var stringObject: [String: Any] = [:]
            for (key, child) in object {
                stringObject[String(describing: key)] = child
            }
            return try boundedPropertyListDictionaryNode(
                stringObject,
                depth: depth,
                maxDepth: maxDepth,
                maxItems: maxItems,
                maxStringCharacters: maxStringCharacters,
                truncated: &truncated
            )
        case let array as [Any]:
            guard depth < maxDepth else {
                let nodeTruncated = !array.isEmpty
                truncated = truncated || nodeTruncated
                return BoundedPropertyListNode(
                    type: "array",
                    value: nil,
                    entries: nil,
                    items: nil,
                    count: array.count,
                    dataDigest: nil,
                    truncated: nodeTruncated
                )
            }

            let limitedItems = Array(array.prefix(maxItems))
            let nodeTruncated = limitedItems.count < array.count
            truncated = truncated || nodeTruncated
            let items = try limitedItems.map {
                try boundedPropertyListNode(
                    from: $0,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    maxItems: maxItems,
                    maxStringCharacters: maxStringCharacters,
                    truncated: &truncated
                )
            }
            return BoundedPropertyListNode(
                type: "array",
                value: nil,
                entries: nil,
                items: items,
                count: array.count,
                dataDigest: nil,
                truncated: nodeTruncated
            )
        case let string as String:
            let nodeTruncated = string.count > maxStringCharacters
            truncated = truncated || nodeTruncated
            return BoundedPropertyListNode(
                type: "string",
                value: .string(String(string.prefix(maxStringCharacters))),
                entries: nil,
                items: nil,
                count: string.count,
                dataDigest: nil,
                truncated: nodeTruncated
            )
        case let date as Date:
            return BoundedPropertyListNode(
                type: "date",
                value: .string(ISO8601DateFormatter().string(from: date)),
                entries: nil,
                items: nil,
                count: nil,
                dataDigest: nil,
                truncated: false
            )
        case let data as Data:
            return BoundedPropertyListNode(
                type: "data",
                value: nil,
                entries: nil,
                items: nil,
                count: data.count,
                dataDigest: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                truncated: false
            )
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return BoundedPropertyListNode(
                    type: "boolean",
                    value: .bool(number.boolValue),
                    entries: nil,
                    items: nil,
                    count: nil,
                    dataDigest: nil,
                    truncated: false
                )
            }
            return BoundedPropertyListNode(
                type: "number",
                value: .number(number.doubleValue),
                entries: nil,
                items: nil,
                count: nil,
                dataDigest: nil,
                truncated: false
            )
        default:
            throw CommandError(description: "unsupported property list value while encoding bounded property list")
        }
    }

    private func boundedPropertyListDictionaryNode(
        _ object: [String: Any],
        depth: Int,
        maxDepth: Int,
        maxItems: Int,
        maxStringCharacters: Int,
        truncated: inout Bool
    ) throws -> BoundedPropertyListNode {
        let keys = object.keys.sorted()
        guard depth < maxDepth else {
            let nodeTruncated = !keys.isEmpty
            truncated = truncated || nodeTruncated
            return BoundedPropertyListNode(
                type: "dictionary",
                value: nil,
                entries: nil,
                items: nil,
                count: keys.count,
                dataDigest: nil,
                truncated: nodeTruncated
            )
        }

        let limitedKeys = Array(keys.prefix(maxItems))
        let nodeTruncated = limitedKeys.count < keys.count
        truncated = truncated || nodeTruncated
        let entries = try limitedKeys.map { key -> BoundedPropertyListProperty in
            guard let child = object[key] else {
                throw CommandError(description: "property list dictionary changed during bounded encoding")
            }
            return BoundedPropertyListProperty(
                key: key,
                value: try boundedPropertyListNode(
                    from: child,
                    depth: depth + 1,
                    maxDepth: maxDepth,
                    maxItems: maxItems,
                    maxStringCharacters: maxStringCharacters,
                    truncated: &truncated
                )
            )
        }

        return BoundedPropertyListNode(
            type: "dictionary",
            value: nil,
            entries: entries,
            items: nil,
            count: keys.count,
            dataDigest: nil,
            truncated: nodeTruncated
        )
    }

    private func propertyListFormatName(_ format: PropertyListSerialization.PropertyListFormat) -> String {
        switch format {
        case .openStep:
            return "openStep"
        case .xml:
            return "xml"
        case .binary:
            return "binary"
        @unknown default:
            return "unknown"
        }
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
                ClipboardAction(name: "clipboard.wait", risk: "low", mutates: false),
                ClipboardAction(name: "clipboard.readText", risk: "medium", mutates: false),
                ClipboardAction(name: "clipboard.writeText", risk: "medium", mutates: true)
            ]
        )
    }

    private func clipboardWait(for pasteboard: NSPasteboard) throws -> ClipboardWaitResult {
        let changedFrom = try option("--changed-from").map { rawValue in
            guard let value = Int(rawValue) else {
                throw CommandError(description: "clipboard changed-from value must be an integer")
            }
            return value
        }
        let expectedHasString = try option("--has-string").map {
            try booleanOption($0, optionName: "--has-string")
        }
        let rawExpectedStringDigest = option("--string-digest")
        if let rawExpectedStringDigest, !isSHA256HexDigest(rawExpectedStringDigest) {
            throw CommandError(description: "clipboard string digest must be a 64-character SHA-256 hex digest")
        }
        let expectedStringDigest = rawExpectedStringDigest?.lowercased()
        guard changedFrom != nil || expectedHasString != nil || expectedStringDigest != nil else {
            throw CommandError(description: "clipboard wait requires --changed-from, --has-string, or --string-digest")
        }

        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = waitForClipboard(
            pasteboard: pasteboard,
            changedFrom: changedFrom,
            expectedHasString: expectedHasString,
            expectedStringDigest: expectedStringDigest,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return ClipboardWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            pasteboard: pasteboard.name.rawValue,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Clipboard reached the expected metadata state."
                : "Timed out waiting for clipboard metadata state."
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

    private func waitForClipboard(
        pasteboard: NSPasteboard,
        changedFrom: Int?,
        expectedHasString: Bool?,
        expectedStringDigest: String?,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> ClipboardWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var current = clipboardAuditSummary(for: pasteboard, string: pasteboard.string(forType: .string))

        while !clipboardSummary(
            current,
            matchesChangedFrom: changedFrom,
            expectedHasString: expectedHasString,
            expectedStringDigest: expectedStringDigest
        ), Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            current = clipboardAuditSummary(for: pasteboard, string: pasteboard.string(forType: .string))
        }

        let matched = clipboardSummary(
            current,
            matchesChangedFrom: changedFrom,
            expectedHasString: expectedHasString,
            expectedStringDigest: expectedStringDigest
        )
        return ClipboardWaitVerification(
            ok: matched,
            code: matched ? "clipboard_matched" : "clipboard_timeout",
            message: matched
                ? "clipboard metadata matched expected state"
                : "clipboard metadata did not match expected state before timeout",
            changedFrom: changedFrom,
            expectedHasString: expectedHasString,
            expectedStringDigest: expectedStringDigest,
            current: current,
            matched: matched
        )
    }

    private func clipboardSummary(
        _ summary: ClipboardAuditSummary,
        matchesChangedFrom changedFrom: Int?,
        expectedHasString: Bool?,
        expectedStringDigest: String?
    ) -> Bool {
        if let changedFrom, summary.changeCount == changedFrom {
            return false
        }
        if let expectedHasString, summary.hasString != expectedHasString {
            return false
        }
        if let expectedStringDigest, summary.stringDigest != expectedStringDigest {
            return false
        }
        return true
    }

    private func isSHA256HexDigest(_ value: String) -> Bool {
        value.range(of: #"^[0-9a-fA-F]{64}$"#, options: .regularExpression) != nil
    }

    private func normalizedChecksumAlgorithm(_ algorithm: String) throws -> String {
        let normalizedAlgorithm = algorithm.lowercased()
        guard normalizedAlgorithm == "sha256" else {
            throw CommandError(description: "unsupported checksum algorithm '\(algorithm)'. Use sha256.")
        }
        return normalizedAlgorithm
    }

    private func fileExpectedSizeBytes(_ rawValue: String) throws -> Int {
        guard let value = Int(rawValue), value >= 0 else {
            throw CommandError(description: "--size-bytes must be a non-negative integer")
        }
        return value
    }

    private func fileMaxBytes(_ rawValue: String, optionName: String) throws -> Int {
        guard let value = Int(rawValue), value >= 0 else {
            throw CommandError(description: "\(optionName) must be a non-negative integer")
        }
        return value
    }

    private func booleanOption(_ rawValue: String, optionName: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "1", "true", "yes", "y":
            return true
        case "0", "false", "no", "n":
            return false
        default:
            throw CommandError(description: "\(optionName) must be true or false")
        }
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

        return applicationSupport.appendingPathComponent("Ln1/audit-log.jsonl")
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

        return applicationSupport.appendingPathComponent("Ln1/task-memory.jsonl")
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

        return applicationSupport.appendingPathComponent("Ln1/workflow-runs.jsonl")
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
        case "filesystem.readText", "filesystem.tailText", "filesystem.readLines", "filesystem.readJSON", "filesystem.readPropertyList", "filesystem.writeText", "filesystem.appendText", "filesystem.duplicate", "filesystem.move", "filesystem.createDirectory", "filesystem.rollbackMove":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func clipboardActionRisk(for action: String) -> String {
        switch action {
        case "clipboard.state", "clipboard.wait":
            return "low"
        case "clipboard.readText", "clipboard.writeText":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func browserActionRisk(for action: String) -> String {
        switch action {
        case "browser.listTabs", "browser.inspectTab", "browser.waitURL", "browser.waitSelector", "browser.waitCount", "browser.waitText", "browser.waitElementText", "browser.waitValue", "browser.waitReady", "browser.waitTitle", "browser.waitChecked", "browser.waitEnabled", "browser.waitFocus", "browser.waitAttribute":
            return "low"
        case "browser.readText", "browser.readDOM", "browser.fillFormField", "browser.selectOption", "browser.setChecked", "browser.focusElement", "browser.pressKey", "browser.clickElement", "browser.navigate":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func desktopActionRisk(for action: String) -> String {
        switch action {
        case "desktop.listDisplays", "desktop.listWindows", "desktop.waitWindow":
            return "low"
        default:
            return "unknown"
        }
    }

    private func systemActionRisk(for action: String) -> String {
        switch action {
        case "system.context":
            return "low"
        default:
            return "unknown"
        }
    }

    private func appActionRisk(for action: String) -> String {
        switch action {
        case "apps.list", "apps.plan", "apps.waitActive":
            return "low"
        case "apps.activate":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func processActionRisk(for action: String) -> String {
        switch action {
        case "processes.list", "processes.inspect", "processes.wait":
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
            PolicyActionRecord(name: "accessibility.inspectMenu", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.inspectElement", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.waitElement", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "apps.list", domain: "apps", risk: appActionRisk(for: "apps.list"), mutates: false),
            PolicyActionRecord(name: "apps.plan", domain: "apps", risk: appActionRisk(for: "apps.plan"), mutates: false),
            PolicyActionRecord(name: "apps.waitActive", domain: "apps", risk: appActionRisk(for: "apps.waitActive"), mutates: false),
            PolicyActionRecord(name: "apps.activate", domain: "apps", risk: appActionRisk(for: "apps.activate"), mutates: true),
            PolicyActionRecord(name: "processes.list", domain: "processes", risk: processActionRisk(for: "processes.list"), mutates: false),
            PolicyActionRecord(name: "processes.inspect", domain: "processes", risk: processActionRisk(for: "processes.inspect"), mutates: false),
            PolicyActionRecord(name: "processes.wait", domain: "processes", risk: processActionRisk(for: "processes.wait"), mutates: false),
            PolicyActionRecord(name: "system.context", domain: "system", risk: systemActionRisk(for: "system.context"), mutates: false),
            PolicyActionRecord(name: "desktop.listDisplays", domain: "desktop", risk: desktopActionRisk(for: "desktop.listDisplays"), mutates: false),
            PolicyActionRecord(name: "desktop.listWindows", domain: "desktop", risk: desktopActionRisk(for: "desktop.listWindows"), mutates: false),
            PolicyActionRecord(name: "desktop.waitWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.waitWindow"), mutates: false),
            PolicyActionRecord(name: "filesystem.stat", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.list", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.search", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.wait", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.watch", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.checksum", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.compare", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.plan", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.readText", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.tailText", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readLines", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readJSON", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readPropertyList", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.writeText", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.appendText", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.duplicate", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.move", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.createDirectory", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.rollbackMove", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "clipboard.state", domain: "clipboard", risk: "low", mutates: false),
            PolicyActionRecord(name: "clipboard.wait", domain: "clipboard", risk: "low", mutates: false),
            PolicyActionRecord(name: "clipboard.readText", domain: "clipboard", risk: "medium", mutates: false),
            PolicyActionRecord(name: "clipboard.writeText", domain: "clipboard", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.listTabs", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.inspectTab", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.readText", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readDOM", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.fillFormField", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.selectOption", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.setChecked", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.focusElement", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.pressKey", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.clickElement", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.navigate", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.waitURL", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitSelector", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitCount", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitText", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitElementText", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitValue", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitReady", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitTitle", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitChecked", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitEnabled", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitFocus", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitAttribute", domain: "browser", risk: "low", mutates: false),
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
            "command": "Ln1 policy",
            "defaultAllowedRisk": "low",
            "riskLevels": ["low", "medium", "high", "unknown"],
            "actions": [
              { "name": "filesystem.move", "domain": "filesystem", "risk": "medium", "mutates": true }
            ]
          },
          "doctor": {
            "command": "Ln1 doctor --timeout-ms 1000",
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
            "command": "Ln1 workflow preflight --operation inspect-active-app",
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
              "nextCommand": "Ln1 state --pid 123 --depth 3 --max-children 80",
              "nextArguments": ["Ln1", "state", "--pid", "123", "--depth", "3", "--max-children", "80"],
              "message": "inspect-active-app can proceed with the suggested command."
            }
          },
          "workflowNext": {
            "command": "Ln1 workflow next --operation duplicate-file --path ~/Desktop/a.txt --to ~/Desktop/a-copy.txt --allow-risk medium",
            "result": {
              "operation": "duplicate-file",
              "ready": true,
              "risk": "medium",
              "mutates": true,
              "blockers": [],
              "command": {
                "display": "Ln1 files duplicate --path ~/Desktop/a.txt --to ~/Desktop/a-copy.txt --allow-risk medium --reason 'Describe intent'",
                "argv": ["Ln1", "files", "duplicate", "--path", "~/Desktop/a.txt", "--to", "~/Desktop/a-copy.txt", "--allow-risk", "medium", "--reason", "Describe intent"],
                "risk": "medium",
                "mutates": true,
                "requiresReason": true
              }
            }
          },
          "workflowBrowserAction": {
            "command": "Ln1 workflow preflight --operation navigate-browser --endpoint http://127.0.0.1:9222 --id page-id --url https://example.com/next --expect-url https://example.com/next --match exact",
            "result": {
              "operation": "navigate-browser",
              "risk": "medium",
              "mutates": true,
              "canProceed": true,
              "prerequisites": [
                {
                  "name": "browser.devTools",
                  "status": "pass",
                  "required": true,
                  "message": "Browser DevTools endpoint is reachable with 1 page target(s)."
                },
                {
                  "name": "auditLog",
                  "status": "pass",
                  "required": true,
                  "message": "Audit log path is writable."
                }
              ],
              "blockers": [],
              "nextCommand": "Ln1 browser navigate --endpoint http://127.0.0.1:9222 --id page-id --url https://example.com/next --expect-url https://example.com/next --match exact --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "navigate", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--url", "https://example.com/next", "--expect-url", "https://example.com/next", "--match", "exact", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "navigate-browser can proceed with the suggested command."
            }
          },
          "workflowRun": {
            "command": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --dry-run false",
            "result": {
              "transcriptID": "UUID",
              "transcriptPath": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
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
                "display": "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
                "argv": ["Ln1", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
                "risk": "medium",
                "mutates": false,
                "requiresReason": false
              },
              "execution": {
                "argv": ["Ln1", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
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
            "command": "Ln1 workflow log --allow-risk medium --limit 20",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
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
            "command": "Ln1 workflow resume --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": null,
              "status": "completed|blocked|timed_out|failed|ready|empty",
              "transcriptID": "UUID",
              "latestOperation": "read-browser",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
            }
          },
          "workflowResumeDOM": {
            "command": "Ln1 workflow resume --allow-risk medium --operation read-browser",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "read-browser",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "read-browser",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser DOM inspection found an actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitURL": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-url",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-url",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-url",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser URL wait completed; dry-run DOM inspection for the arrived page."
            }
          },
          "workflowWaitFile": {
            "command": "Ln1 workflow run --operation wait-file --path ~/Downloads/report.pdf --exists true --wait-timeout-ms 5000 --dry-run false --run-timeout-ms 1000",
            "result": {
              "operation": "wait-file",
              "risk": "low",
              "mutates": false,
              "command": {
                "argv": ["Ln1", "files", "wait", "--path", "~/Downloads/report.pdf", "--exists", "true", "--timeout-ms", "5000", "--interval-ms", "100"]
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
            "command": "Ln1 observe --app-limit 20 --window-limit 20",
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
                  "command": "Ln1 state --pid 123 --depth 3 --max-children 80",
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
          "stateMenu": {
            "command": "Ln1 state menu --depth 2 --max-children 80",
            "result": {
              "generatedAt": "ISO-8601 timestamp",
              "platform": "macOS",
              "app": {
                "name": "frontmost or requested app name",
                "bundleIdentifier": "com.example.App",
                "pid": 123
              },
              "menuBar": {
                "id": "m0",
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "medium",
                  "label": "AXMenuBar in com.example.App"
                },
                "role": "AXMenuBar",
                "title": null,
                "actions": [],
                "children": [
                  {
                    "id": "m0.0",
                    "role": "AXMenuBarItem",
                    "title": "File",
                    "children": []
                  }
                ]
              },
              "depth": 2,
              "maxChildren": 80,
              "message": "Accessibility menu bar state inspected."
            }
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
            "command": "Ln1 desktop windows --limit 50",
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
            "command": "Ln1 perform --pid 456 --element a0.w0.3.1|a0.m0.1 --expect-identity accessibilityElement:stable-semantic-digest --min-identity-confidence medium --action AXPress --allow-risk low --reason 'Open details'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "audit": {
            "command": "Ln1 audit --command files.move --code moved --limit 20",
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
            "command": "Ln1 task record --task-id UUID --kind verification --summary 'download matched expected digest' --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/Ln1/task-memory.jsonl",
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
            "command": "Ln1 clipboard state",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "types": ["public.utf8-plain-text"],
              "hasString": true,
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "actions": [
                { "name": "clipboard.state", "risk": "low", "mutates": false },
                { "name": "clipboard.wait", "risk": "low", "mutates": false },
                { "name": "clipboard.readText", "risk": "medium", "mutates": false },
                { "name": "clipboard.writeText", "risk": "medium", "mutates": true }
              ]
            }
          },
          "clipboardWait": {
            "command": "Ln1 clipboard wait --changed-from 12 --has-string true --timeout-ms 5000",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "clipboard_matched",
                "message": "clipboard metadata matched expected state",
                "changedFrom": 12,
                "expectedHasString": true,
                "current": {
                  "pasteboard": "Apple CFPasteboard general",
                  "changeCount": 13,
                  "types": ["public.utf8-plain-text"],
                  "hasString": true,
                  "stringLength": 42,
                  "stringDigest": "hex encoded SHA-256 digest"
                },
                "matched": true
              }
            }
          },
          "clipboardText": {
            "command": "Ln1 clipboard read-text --allow-risk medium --max-characters 4096 --reason 'Use copied value'",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "hasString": true,
              "text": "bounded clipboard text",
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "truncated": false,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "clipboardWrite": {
            "command": "Ln1 clipboard write-text --allow-risk medium --text 'bounded clipboard text' --reason 'Prepare value for paste'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserTabs": {
            "command": "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
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
                    { "name": "browser.selectOption", "risk": "medium", "mutates": true },
                    { "name": "browser.setChecked", "risk": "medium", "mutates": true },
                    { "name": "browser.focusElement", "risk": "medium", "mutates": true },
                    { "name": "browser.pressKey", "risk": "medium", "mutates": true },
                    { "name": "browser.clickElement", "risk": "medium", "mutates": true },
                    { "name": "browser.navigate", "risk": "medium", "mutates": true },
                    { "name": "browser.waitURL", "risk": "low", "mutates": false },
                    { "name": "browser.waitSelector", "risk": "low", "mutates": false },
                    { "name": "browser.waitCount", "risk": "low", "mutates": false },
                    { "name": "browser.waitText", "risk": "low", "mutates": false },
                    { "name": "browser.waitElementText", "risk": "low", "mutates": false },
                    { "name": "browser.waitValue", "risk": "low", "mutates": false },
                    { "name": "browser.waitReady", "risk": "low", "mutates": false },
                    { "name": "browser.waitTitle", "risk": "low", "mutates": false },
                    { "name": "browser.waitChecked", "risk": "low", "mutates": false },
                    { "name": "browser.waitEnabled", "risk": "low", "mutates": false },
                    { "name": "browser.waitFocus", "risk": "low", "mutates": false },
                    { "name": "browser.waitAttribute", "risk": "low", "mutates": false }
                  ]
                }
              ]
            }
          },
          "browserTab": {
            "command": "Ln1 browser tab --endpoint http://127.0.0.1:9222 --id devtools-target-id",
            "result": {
              "tab": {
                "id": "devtools-target-id",
                "title": "Page title",
                "url": "https://example.com"
              }
            }
          },
          "browserDOM": {
            "command": "Ln1 browser dom --endpoint http://127.0.0.1:9222 --id devtools-target-id --allow-risk medium --max-elements 200 --max-text-characters 120",
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
                  "selector": "body",
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
                  "selector": "input[name=\\"q\\"]",
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
            "command": "Ln1 browser fill --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --text 'bounded text' --allow-risk medium",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserSelect": {
            "command": "Ln1 browser select --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'select[name=country]' --value ca --allow-risk medium",
            "result": {
              "action": "browser.selectOption",
              "risk": "medium",
              "selector": "select[name=country]",
              "requestedValueLength": 2,
              "requestedValueDigest": "hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "option_selected",
                "message": "browser select contains the requested option"
              },
              "targetTagName": "select",
              "targetDisabled": false,
              "optionCount": 3,
              "selectedIndex": 2,
              "selectedValueLength": 2,
              "selectedLabelLength": 6,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserCheck": {
            "command": "Ln1 browser check --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=subscribe]' --checked true --allow-risk medium",
            "result": {
              "action": "browser.setChecked",
              "risk": "medium",
              "selector": "input[name=subscribe]",
              "requestedChecked": true,
              "verification": {
                "ok": true,
                "code": "checked_matched",
                "message": "browser control checked state matches the requested value"
              },
              "targetTagName": "input",
              "targetInputType": "checkbox",
              "targetDisabled": false,
              "targetReadOnly": false,
              "currentChecked": true,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserFocus": {
            "command": "Ln1 browser focus --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --allow-risk medium",
            "result": {
              "action": "browser.focusElement",
              "risk": "medium",
              "selector": "input[name=q]",
              "verification": {
                "ok": true,
                "code": "element_focused",
                "message": "browser active element matches the requested selector"
              },
              "targetTagName": "input",
              "targetInputType": "text",
              "targetDisabled": false,
              "targetReadOnly": false,
              "activeElementMatched": true,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserPressKey": {
            "command": "Ln1 browser press-key --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --key Enter --allow-risk medium",
            "result": {
              "action": "browser.pressKey",
              "risk": "medium",
              "key": "Enter",
              "modifiers": [],
              "modifierMask": 0,
              "selector": "input[name=q]",
              "focusVerification": {
                "ok": true,
                "code": "element_focused",
                "message": "browser active element matches the requested selector"
              },
              "verification": {
                "ok": true,
                "code": "key_pressed",
                "message": "browser key press dispatched through Chrome DevTools",
                "keyDownDispatched": true,
                "keyUpDispatched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserClick": {
            "command": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --expect-url https://example.com/next --match exact --allow-risk medium",
            "result": {
              "action": "browser.clickElement",
              "risk": "medium",
              "selector": "button[type=submit]",
              "verification": {
                "ok": true,
                "code": "element_clicked",
                "message": "browser element matched selector and received a click"
              },
              "targetTagName": "button",
              "targetDisabled": false,
              "targetHref": null,
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "urlVerification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserNavigate": {
            "command": "Ln1 browser navigate --endpoint http://127.0.0.1:9222 --id devtools-target-id --url https://example.com/next --allow-risk medium",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserWaitURL": {
            "command": "Ln1 browser wait-url --endpoint http://127.0.0.1:9222 --id devtools-target-id --expect-url https://example.com/next --match exact --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              }
            }
          },
          "browserWaitSelector": {
            "command": "Ln1 browser wait-selector --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --state visible --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "button[type=submit]",
              "state": "visible",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "selector_matched",
                "message": "The selector reached 'visible' state.",
                "currentURL": "https://example.com/form",
                "tagName": "button",
                "matched": true
              }
            }
          },
          "browserWaitCount": {
            "command": "Ln1 browser wait-count --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector '.result-row' --count 3 --count-match at-least --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": ".result-row",
              "expectedCount": 3,
              "countMatch": "at-least",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "count_matched",
                "message": "browser selector count matched expected at-least value",
                "currentCount": 5,
                "currentURL": "https://example.com/results",
                "matched": true
              }
            }
          },
          "browserWaitText": {
            "command": "Ln1 browser wait-text --endpoint http://127.0.0.1:9222 --id devtools-target-id --text 'Saved successfully' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedTextLength": 18,
              "expectedTextDigest": "hex encoded SHA-256 digest",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "text_matched",
                "message": "browser tab text matched expected contains value",
                "currentTextLength": 120,
                "currentTextDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "matched": true
              }
            }
          },
          "browserWaitElementText": {
            "command": "Ln1 browser wait-element-text --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector '[data-testid=status]' --text 'Saved successfully' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "[data-testid=status]",
              "expectedTextLength": 18,
              "expectedTextDigest": "hex encoded SHA-256 digest",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "element_text_matched",
                "message": "browser element text matched expected contains value",
                "currentTextLength": 18,
                "currentTextDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "tagName": "div",
                "matched": true
              }
            }
          },
          "browserWaitValue": {
            "command": "Ln1 browser wait-value --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --text 'bounded text' --match exact --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=q]",
              "expectedValueLength": 12,
              "expectedValueDigest": "hex encoded SHA-256 digest",
              "match": "exact",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "value_matched",
                "message": "browser field value matched expected exact value",
                "currentValueLength": 12,
                "currentValueDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "tagName": "input",
                "inputType": "text",
                "matched": true
              }
            }
          },
          "browserWaitReady": {
            "command": "Ln1 browser wait-ready --endpoint http://127.0.0.1:9222 --id devtools-target-id --state complete --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedState": "complete",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "ready_state_matched",
                "message": "browser document ready state reached complete",
                "currentState": "complete",
                "currentURL": "https://example.com/form",
                "matched": true
              }
            }
          },
          "browserWaitTitle": {
            "command": "Ln1 browser wait-title --endpoint http://127.0.0.1:9222 --id devtools-target-id --title 'Checkout' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedTitle": "Checkout",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "title_matched",
                "message": "browser tab title matched expected contains value",
                "currentTitle": "Checkout - Example",
                "currentURL": "https://example.com/checkout",
                "matched": true
              }
            }
          },
          "browserWaitChecked": {
            "command": "Ln1 browser wait-checked --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=subscribe]' --checked true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=subscribe]",
              "expectedChecked": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "checked_matched",
                "message": "browser checked state matched expected value",
                "currentChecked": true,
                "currentURL": "https://example.com/preferences",
                "tagName": "input",
                "inputType": "checkbox",
                "matched": true
              }
            }
          },
          "browserWaitEnabled": {
            "command": "Ln1 browser wait-enabled --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --enabled true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "button[type=submit]",
              "expectedEnabled": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "enabled_matched",
                "message": "browser element enabled state matched expected value",
                "currentEnabled": true,
                "currentURL": "https://example.com/form",
                "tagName": "button",
                "disabled": false,
                "matched": true
              }
            }
          },
          "browserWaitFocus": {
            "command": "Ln1 browser wait-focus --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --focused true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=q]",
              "expectedFocused": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "focus_matched",
                "message": "browser element focus state matched expected value",
                "currentFocused": true,
                "currentURL": "https://example.com/form",
                "tagName": "input",
                "inputType": "text",
                "activeTagName": "input",
                "activeInputType": "text",
                "matched": true
              }
            }
          },
          "workflowResumeWaitSelector": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-selector",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-selector",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-selector",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser selector wait found a ready actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitCount": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-count",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-count",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-count",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser count wait completed; dry-run DOM inspection for the matched collection state."
            }
          },
          "workflowResumeWaitEnabled": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-enabled",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-enabled",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-enabled",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser enabled-state wait found an enabled actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitFocus": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-focus",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-focus",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-focus",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser focus wait completed; dry-run DOM inspection for the focused element state."
            }
          },
          "workflowResumeWaitText": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-text",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-text",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-text",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser text wait completed; dry-run DOM inspection for the matched page state."
            }
          },
          "workflowResumeWaitElementText": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-element-text",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-element-text",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-element-text",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser element text wait completed; dry-run DOM inspection for the matched element state."
            }
          },
          "workflowResumeWaitValue": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-value",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-value",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-value",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser value wait completed; dry-run DOM inspection for the matched field state."
            }
          },
          "workflowResumeWaitReady": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-ready",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-ready",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-ready",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser ready-state wait completed; dry-run DOM inspection for the loaded page state."
            }
          },
          "workflowResumeWaitTitle": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-title",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-title",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-title",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser title wait completed; dry-run DOM inspection for the matched page."
            }
          },
          "workflowResumeWaitChecked": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-checked",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-checked",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-checked",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser checked-state wait completed; dry-run DOM inspection for the matched form state."
            }
          },
          "files": {
            "command": "Ln1 files list --path ~/Documents --depth 2 --limit 200",
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
            "command": "Ln1 files search --path ~/Documents --query invoice --depth 4 --limit 50",
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
            "command": "Ln1 files wait --path ~/Downloads/report.pdf --exists true --size-bytes 1048576 --digest 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824 --timeout-ms 5000 --interval-ms 100",
            "result": {
              "path": "/Users/example/Downloads/report.pdf",
              "expectedExists": true,
              "expectedSizeBytes": 1048576,
              "expectedDigest": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
              "algorithm": "sha256",
              "matched": true,
              "sizeMatched": true,
              "digestMatched": true,
              "currentDigest": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
              "elapsedMilliseconds": 100,
              "file": { "path": "/Users/example/Downloads/report.pdf", "kind": "regularFile" },
              "message": "Path exists at /Users/example/Downloads/report.pdf and matched expected metadata."
            }
          },
          "fileWatch": {
            "command": "Ln1 files watch --path ~/Downloads --depth 1 --timeout-ms 30000 --interval-ms 250",
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
            "command": "Ln1 files checksum --path ~/Documents/Plan.md --algorithm sha256 --max-file-bytes 104857600",
            "result": {
              "file": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "algorithm": "sha256",
              "digest": "hex encoded SHA-256 digest",
              "maxFileBytes": 104857600
            }
          },
          "fileCompare": {
            "command": "Ln1 files compare --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --algorithm sha256 --max-file-bytes 104857600",
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
            "command": "Ln1 files plan --operation move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium",
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
            "command": "Ln1 files duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --allow-risk medium --reason 'Preserve original before editing'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "fileMove": {
            "command": "Ln1 files move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium --reason 'Organize completed draft'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "directoryCreate": {
            "command": "Ln1 files mkdir --path ~/Documents/Archive --allow-risk medium --reason 'Create archive folder'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "fileRollback": {
            "command": "Ln1 files rollback --audit-id UUID --allow-risk medium --reason 'Undo mistaken move'",
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
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          }
        }
        """)
    }

    private func printHelp() {
        print("""
        Ln1: macOS semantic computer substrate prototype

        Usage:
          Ln1 trust [--prompt true|false]
          Ln1 doctor [--timeout-ms N] [--endpoint URL_OR_PATH] [--audit-log PATH] [--pasteboard NAME]
          Ln1 policy
          Ln1 system [context|info]
          Ln1 observe [--app-limit N] [--window-limit N] [--all] [--include-desktop] [--all-layers]
          Ln1 workflow preflight --operation inspect-active-app|inspect-menu|inspect-system|inspect-displays|inspect-process|inspect-element|wait-process|wait-window|wait-element|wait-active-app|activate-app|control-active-app|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete]
          Ln1 workflow next --operation inspect-active-app|inspect-menu|inspect-system|inspect-displays|inspect-process|inspect-element|wait-process|wait-window|wait-element|wait-active-app|activate-app|control-active-app|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete]
          Ln1 workflow run --operation inspect-active-app|inspect-menu|inspect-system|inspect-displays|inspect-process|inspect-element|wait-process|wait-window|wait-element|wait-active-app|read-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|list-files|search-files|checksum-file|compare-files|watch-file|wait-file --dry-run false [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--endpoint URL_OR_PATH] [--id TARGET_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--path PATH] [--to PATH] [--query TEXT] [--exists true|false] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--case-sensitive] [--watch-timeout-ms N] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--expect-url URL_OR_TEXT] [--selector CSS_SELECTOR] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--value VALUE] [--attribute NAME] [--title TITLE] [--checked true|false] [--enabled true|false] [--focused true|false] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow run --operation activate-app|control-active-app|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|write-file|append-file|create-directory|duplicate-file|move-file|rollback-file-move --dry-run false --execute-mutating true --reason TEXT [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--id TARGET_ID] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--text TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--overwrite] [--create] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow run --operation inspect-active-app|inspect-menu|inspect-system|inspect-displays|inspect-process|inspect-element|wait-process|wait-window|wait-element|wait-active-app|activate-app|control-active-app|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file --dry-run true [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow log --allow-risk medium [--workflow-log PATH] [--operation NAME] [--limit N]
          Ln1 workflow resume --allow-risk medium [--workflow-log PATH] [--operation NAME]
          Ln1 apps [--all]
          Ln1 apps plan --operation activate (--pid PID|--bundle-id BUNDLE_ID|--current) [--allow-risk low|medium|high|unknown]
          Ln1 apps activate (--pid PID|--bundle-id BUNDLE_ID|--current) --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 apps wait-active (--pid PID|--bundle-id BUNDLE_ID|--current) [--timeout-ms N] [--interval-ms N]
          Ln1 processes [list] [--limit N] [--name TEXT]
          Ln1 processes inspect (--pid PID|--current)
          Ln1 processes wait --pid PID [--exists true|false] [--timeout-ms N] [--interval-ms N]
          Ln1 desktop displays
          Ln1 desktop windows [--limit N] [--include-desktop] [--all-layers]
          Ln1 desktop wait-window (--id ID|--owner-pid PID|--bundle-id BUNDLE_ID|--title TEXT) [--match exact|prefix|contains] [--exists true|false] [--timeout-ms N] [--interval-ms N] [--limit N] [--include-desktop] [--all-layers]
          Ln1 state [--pid PID] [--all] [--include-background] [--depth N] [--max-children N]
          Ln1 state menu [--pid PID] [--depth N] [--max-children N]
          Ln1 state element [--pid PID] --element ID [--expect-identity ID] [--min-identity-confidence low|medium|high] [--depth N] [--max-children N]
          Ln1 state wait-element [--pid PID] --element ID [--expect-identity ID] [--min-identity-confidence low|medium|high] [--title TEXT] [--value TEXT] [--match exact|contains] [--enabled true|false] [--exists true|false] [--timeout-ms N] [--interval-ms N] [--depth N] [--max-children N]
          Ln1 perform [--pid PID] --element w0.1.2|m0.1|a0.w0.1.2|a0.m0.1 [--action AXPress] [--allow-risk low|medium|high|unknown] [--reason TEXT] [--audit-log PATH]
          Ln1 audit [--limit N] [--command NAME] [--code OUTCOME_CODE] [--audit-log PATH]
          Ln1 task start --title TEXT [--summary TEXT] --allow-risk medium [--sensitivity public|private|sensitive] [--task-id ID] [--memory-log PATH]
          Ln1 task record --task-id ID --kind observation|decision|action|verification|note --summary TEXT --allow-risk medium [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          Ln1 task finish --task-id ID [--status completed|blocked|cancelled] --allow-risk medium [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          Ln1 task show --task-id ID --allow-risk medium [--limit N] [--memory-log PATH]
          Ln1 files stat --path PATH
          Ln1 files list --path PATH [--depth N] [--limit N] [--include-hidden]
          Ln1 files search --path PATH --query TEXT [--depth N] [--limit N] [--include-hidden] [--case-sensitive] [--max-file-bytes N] [--max-characters N] [--max-snippet-characters N] [--max-matches-per-file N]
          Ln1 files read-text --path PATH --allow-risk medium [--max-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files tail-text --path PATH --allow-risk medium [--max-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-lines --path PATH --allow-risk medium [--start-line N] [--line-count N] [--max-line-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-json --path PATH --allow-risk medium [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-plist --path PATH --allow-risk medium [--pointer POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files write-text --path PATH --text TEXT --allow-risk medium [--overwrite] [--reason TEXT] [--audit-log PATH]
          Ln1 files append-text --path PATH --text TEXT --allow-risk medium [--create] [--reason TEXT] [--audit-log PATH]
          Ln1 files wait --path PATH [--exists true|false] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--timeout-ms N] [--interval-ms N]
          Ln1 files watch --path PATH [--depth N] [--limit N] [--include-hidden] [--timeout-ms N] [--interval-ms N]
          Ln1 files checksum --path PATH [--algorithm sha256] [--max-file-bytes N]
          Ln1 files compare --path LEFT --to RIGHT [--algorithm sha256] [--max-file-bytes N]
          Ln1 files plan --operation duplicate|move --path SOURCE --to DESTINATION [--allow-risk low|medium|high|unknown]
          Ln1 files plan --operation mkdir --path PATH [--allow-risk low|medium|high|unknown]
          Ln1 files plan --operation rollback --audit-id AUDIT_ID [--allow-risk low|medium|high|unknown] [--audit-log PATH]
          Ln1 files duplicate --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files move --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files mkdir --path PATH --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files rollback --audit-id AUDIT_ID --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 clipboard state [--pasteboard NAME]
          Ln1 clipboard wait [--changed-from N] [--has-string true|false] [--string-digest HEX] [--timeout-ms N] [--interval-ms N] [--pasteboard NAME]
          Ln1 clipboard read-text --allow-risk medium [--max-characters N] [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          Ln1 clipboard write-text --text TEXT --allow-risk medium [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          Ln1 browser tabs [--endpoint URL_OR_PATH] [--include-non-page]
          Ln1 browser tab --id TARGET_ID [--endpoint URL_OR_PATH] [--include-non-page]
          Ln1 browser text --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser dom --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-elements N] [--max-text-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser fill --id TARGET_ID --selector CSS_SELECTOR --text TEXT --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser select --id TARGET_ID --selector CSS_SELECTOR (--value VALUE|--label LABEL) --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser check --id TARGET_ID --selector CSS_SELECTOR [--checked true|false] --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser focus --id TARGET_ID --selector CSS_SELECTOR --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser press-key --id TARGET_ID --key KEY --allow-risk medium [--selector CSS_SELECTOR] [--modifiers shift,control,alt,meta] [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser click --id TARGET_ID --selector CSS_SELECTOR --allow-risk medium [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser navigate --id TARGET_ID --url URL --allow-risk medium [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser wait-url --id TARGET_ID --expect-url URL_OR_TEXT [--endpoint URL_OR_PATH] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-selector --id TARGET_ID --selector CSS_SELECTOR [--endpoint URL_OR_PATH] [--state attached|visible|hidden|detached] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-count --id TARGET_ID --selector CSS_SELECTOR --count N [--endpoint URL_OR_PATH] [--count-match exact|at-least|at-most] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-text --id TARGET_ID --text TEXT [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-element-text --id TARGET_ID --selector CSS_SELECTOR --text TEXT [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-value --id TARGET_ID --selector CSS_SELECTOR --text TEXT [--endpoint URL_OR_PATH] [--match exact|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-ready --id TARGET_ID [--endpoint URL_OR_PATH] [--state loading|interactive|complete] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-title --id TARGET_ID --title TITLE [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-checked --id TARGET_ID --selector CSS_SELECTOR [--checked true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-enabled --id TARGET_ID --selector CSS_SELECTOR [--enabled true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-focus --id TARGET_ID --selector CSS_SELECTOR [--focused true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-attribute --id TARGET_ID --selector CSS_SELECTOR --attribute NAME --text TEXT [--endpoint URL_OR_PATH] [--match exact|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 schema

        Notes:
          - Run `Ln1 trust` before Accessibility-backed `state` or `perform` commands.
          - `policy` describes known action risk levels and mutation behavior.
          - `system context` reports bounded host, OS, shell, working directory, and runtime metadata.
          - `apps plan` previews app activation with policy and target checks without changing focus.
          - `apps activate` brings one regular GUI app forward after medium-risk approval and writes an audit record.
          - `apps wait-active` waits for the frontmost app to match a target without changing focus.
          - `processes` lists and inspects bounded process metadata without reading command-line arguments.
          - `desktop displays` lists connected display topology, bounds, scale, and rotation without screenshots.
          - `desktop windows` lists visible desktop windows from macOS window metadata without requiring screenshots.
          - `desktop wait-window` waits for visible desktop window metadata to appear or disappear without fixed sleeps.
          - `state` emits structured JSON from macOS Accessibility APIs.
          - `state menu` inspects the target app menu bar as a bounded Accessibility tree.
          - `state element` inspects one Accessibility element path with optional stable identity verification.
          - `state wait-element` waits for an Accessibility element path and optional identity, text, or enabled-state criteria.
          - `state --all` walks every running GUI app macOS exposes to this process.
          - Element IDs are child-index paths. Use window IDs from `state` and menu IDs from `state menu` with `perform`.
          - `perform` defaults to `--allow-risk low`; medium, high, and unknown actions require explicit allowance.
          - `perform` appends a structured JSONL audit record before returning success or failure.
          - `audit` can filter records by command name and outcome code before applying the limit.
          - `task` stores and reads task-scoped memory as medium-risk local persistence with sensitive-summary redaction.
          - `files` emits read-only filesystem metadata, bounded search evidence, and available typed file actions.
          - `files read-text` returns bounded UTF-8 text from the start of one regular file only after medium-risk approval and audits metadata without storing text.
          - `files tail-text` returns bounded UTF-8 text from the end of one regular file only after medium-risk approval and audits metadata without storing text.
          - `files read-lines` returns bounded, numbered UTF-8 lines from one regular file only after medium-risk approval and audits metadata without storing text.
          - `files read-json` returns a bounded typed JSON tree, optionally at a JSON Pointer, from one regular file only after medium-risk approval and audits metadata without storing JSON values.
          - `files read-plist` returns a bounded typed property list tree, optionally at a pointer, from one regular file only after medium-risk approval and audits metadata without storing property list values.
          - `files write-text` creates one UTF-8 text file, or overwrites with `--overwrite`, after medium-risk approval and verifies by length/digest without storing text in audit logs.
          - `files append-text` appends UTF-8 text to one regular file, or creates it with `--create`, after medium-risk approval and verifies by size/tail bytes without storing text in audit logs.
          - `files wait` waits for a path to exist, disappear, or match expected size/digest metadata.
          - `files watch` waits for created, deleted, or modified file metadata events under a path and returns normalized event records.
          - `files checksum` returns a bounded SHA-256 digest for a regular file without exposing file contents.
          - `files compare` compares two regular files by bounded SHA-256 digest and size.
          - `files plan` previews mutating file operations with policy, target metadata, and preflight checks without changing files.
          - `files duplicate` copies one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files move` moves one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files mkdir` creates one directory, refuses existing paths, verifies the result, and writes an audit record.
          - `files rollback` restores a successful audited file move after validating current filesystem metadata.
          - `clipboard state` reports pasteboard metadata and text digest without returning clipboard text.
          - `clipboard wait` waits for pasteboard metadata changes without returning clipboard text.
          - `clipboard read-text` returns bounded text only after medium-risk policy approval and audits metadata without storing text.
          - `clipboard write-text` writes plain text only after medium-risk policy approval, verifies by length and digest, and audits metadata without storing text.
          - `browser tabs` reads Chrome DevTools target metadata from an explicit endpoint and returns structured tab records.
          - `browser tab` inspects one DevTools target by id from the same structured browser source.
          - `browser text` reads page text through Chrome DevTools only after medium-risk policy approval and audits length/digest without storing text.
          - `browser dom` reads bounded structured page state through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing the DOM payload.
          - `browser fill` writes one form field through Chrome DevTools only after medium-risk policy approval, verifies by length, and audits selector plus text length/digest without storing text.
          - `browser select` chooses one select option through Chrome DevTools only after medium-risk policy approval, verifies the selection, and audits selector plus option length/digest without storing option text.
          - `browser check` sets one checkbox or radio input through Chrome DevTools only after medium-risk policy approval and audits selector plus requested checked state.
          - `browser focus` focuses one DOM element by CSS selector through Chrome DevTools only after medium-risk policy approval and audits selector/target metadata.
          - `browser press-key` dispatches one key press through Chrome DevTools only after medium-risk policy approval and audits key/modifier metadata.
          - `browser click` clicks one DOM element by CSS selector through Chrome DevTools only after medium-risk policy approval, optionally waits for an expected resulting URL, and audits selector/target metadata plus URL verification when requested.
          - `browser navigate` navigates one tab through Chrome DevTools only after medium-risk policy approval, verifies the resulting URL from structured tab metadata, and audits the requested/current URLs.
          - `browser wait-url` waits for one tab URL to match exact, prefix, or contains criteria without mutating the page.
          - `browser wait-selector` waits for one DOM selector to become attached, visible, hidden, or detached without mutating the page.
          - `browser wait-count` waits for a selector count to match exact, at-least, or at-most criteria without mutating the page.
          - `browser wait-text` waits for page text to match without returning page text contents.
          - `browser wait-element-text` waits for one element's text to match without returning text contents.
          - `browser wait-value` waits for one input, textarea, or select value without returning value contents.
          - `browser wait-ready` waits for one tab document readiness state without mutating the page.
          - `browser wait-title` waits for one tab title to match without reading page contents.
          - `browser wait-checked` waits for one checkbox or radio checked state without mutating the page.
          - `browser wait-enabled` waits for one element enabled or disabled state without mutating the page.
          - `browser wait-focus` waits for one element focused or unfocused state without mutating the page.
          - `browser wait-attribute` waits for one element attribute to match without returning attribute contents.
          - Workflow fill-browser, select-browser, check-browser, focus-browser, press-browser-key, click-browser, and navigate-browser preflight browser actions before returning typed mutating browser argv arrays for review.
          - Workflow mutating execution requires --execute-mutating true and a non-placeholder --reason before running the underlying audited command.
          - Workflow inspect-menu inspects one app menu bar before choosing a trusted UI action.
          - Workflow inspect-element inspects one Accessibility element before choosing a guarded UI action.
          - Workflow read-clipboard reads bounded clipboard text through workflow preflight, transcript capture, and audit logging.
          - Workflow wait-window waits for desktop window appearance or disappearance before inspecting owner process or active app state.
          - Workflow wait-element waits for Accessibility element appearance or readiness before guarded UI actions.
          - Workflow wait-browser-url waits for post-action browser URL verification without fixed sleeps.
          - Workflow wait-browser-selector waits for dynamic page UI readiness or disappearance before the next browser action.
          - Workflow wait-browser-count waits for dynamic collection sizes before inspecting or acting.
          - Workflow wait-browser-text waits for page text readiness without fixed sleeps.
          - Workflow wait-browser-element-text waits for one element's text readiness without fixed sleeps.
          - Workflow wait-browser-value waits for field value readiness without exposing value contents.
          - Workflow wait-browser-ready waits for document readiness before inspecting or acting.
          - Workflow wait-browser-title waits for title changes before inspecting or acting.
          - Workflow wait-browser-checked waits for checkbox or radio state before inspecting or acting.
          - Workflow wait-browser-enabled waits for an element to become enabled or disabled before inspecting or acting.
          - Workflow wait-browser-focus waits for focus state before inspecting or acting.
          - Workflow wait-browser-attribute waits for DOM attribute state before inspecting or acting.
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

    private func refreshedFileRecord(for url: URL) throws -> FileRecord {
        var refreshedURL = url
        refreshedURL.removeAllCachedResourceValues()
        return try fileRecord(for: refreshedURL)
    }

    private func fileByteSize(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? NSNumber {
            return size.intValue
        }
        throw CommandError(description: "file size is unavailable at \(url.path)")
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
            actions.append(FileAction(name: "filesystem.writeText", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.appendText", risk: "medium", mutates: true))
        }

        if kind == "regularFile", readable {
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.watch", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.checksum", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.compare", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.readText", risk: "medium", mutates: false))
            actions.append(FileAction(name: "filesystem.tailText", risk: "medium", mutates: false))
            actions.append(FileAction(name: "filesystem.readLines", risk: "medium", mutates: false))
            actions.append(FileAction(name: "filesystem.readJSON", risk: "medium", mutates: false))
            actions.append(FileAction(name: "filesystem.readPropertyList", risk: "medium", mutates: false))
            actions.append(FileAction(name: "filesystem.duplicate", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.move", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.rollbackMove", risk: "medium", mutates: true))
        }

        if kind == "regularFile", writable {
            actions.append(FileAction(name: "filesystem.writeText", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.appendText", risk: "medium", mutates: true))
        }

        return actions
    }

    private func desktopDisplays() -> DesktopDisplaysState {
        var screenByDisplayID: [CGDirectDisplayID: NSScreen] = [:]
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            screenByDisplayID[CGDirectDisplayID(screenNumber.uint32Value)] = screen
        }

        let maxDisplays: UInt32 = 32
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        let result = CGGetOnlineDisplayList(maxDisplays, &displayIDs, &displayCount)
        guard result == .success else {
            return DesktopDisplaysState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                available: false,
                message: "Display metadata is unavailable from this process.",
                count: 0,
                displays: []
            )
        }

        var resolvedDisplayIDs = Array(displayIDs.prefix(Int(displayCount)))
        if resolvedDisplayIDs.isEmpty {
            resolvedDisplayIDs = screenByDisplayID.keys.sorted()
        }
        let mainDisplayID = CGMainDisplayID()
        if resolvedDisplayIDs.isEmpty, mainDisplayID != 0 {
            resolvedDisplayIDs = [mainDisplayID]
        }

        let displays = resolvedDisplayIDs.map { displayID -> DesktopDisplayRecord in
            let bounds = CGDisplayBounds(displayID)
            let screen = screenByDisplayID[displayID]
            return DesktopDisplayRecord(
                id: "display:\(displayID)",
                displayID: displayID,
                name: screen?.localizedName,
                main: CGDisplayIsMain(displayID) != 0,
                active: CGDisplayIsActive(displayID) != 0,
                online: CGDisplayIsOnline(displayID) != 0,
                builtin: CGDisplayIsBuiltin(displayID) != 0,
                inMirrorSet: CGDisplayIsInMirrorSet(displayID) != 0,
                bounds: Rect(
                    x: Double(bounds.origin.x),
                    y: Double(bounds.origin.y),
                    width: Double(bounds.size.width),
                    height: Double(bounds.size.height)
                ),
                pixelWidth: CGDisplayPixelsWide(displayID),
                pixelHeight: CGDisplayPixelsHigh(displayID),
                scaleFactor: screen.map { Double($0.backingScaleFactor) },
                rotationDegrees: CGDisplayRotation(displayID),
                colorSpaceName: screen?.colorSpace?.localizedName
            )
        }
        .sorted { left, right in
            if left.main != right.main {
                return left.main && !right.main
            }
            if left.active != right.active {
                return left.active && !right.active
            }
            return left.displayID < right.displayID
        }

        return DesktopDisplaysState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            available: true,
            message: displays.isEmpty
                ? "No online displays were reported."
                : "Read connected display metadata.",
            count: displays.count,
            displays: displays
        )
    }

    private func desktopWindowWaitState() throws -> DesktopWindowWaitResult {
        let target = try desktopWindowWaitTarget()
        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
        let verification = try waitForDesktopWindow(
            target: target,
            expectedExists: expectedExists,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            limit: limit
        )

        return DesktopWindowWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            includeDesktop: flag("--include-desktop"),
            includeAllLayers: flag("--all-layers"),
            limit: limit,
            verification: verification,
            message: verification.ok
                ? "Desktop window metadata matched the expected state."
                : verification.message
        )
    }

    private func desktopWindowWaitTarget() throws -> DesktopWindowWaitTarget {
        let id = option("--id")
        let ownerPID = try option("--owner-pid").map { rawValue -> Int32 in
            guard let pid = Int32(rawValue), pid > 0 else {
                throw CommandError(description: "desktop wait-window --owner-pid must be a positive integer")
            }
            return pid
        }
        let bundleIdentifier = option("--bundle-id")
        let title = option("--title")
        let titleMatch = option("--match") ?? "contains"
        guard ["exact", "prefix", "contains"].contains(titleMatch) else {
            throw CommandError(description: "desktop wait-window --match must be exact, prefix, or contains")
        }
        guard id != nil || ownerPID != nil || bundleIdentifier != nil || title != nil else {
            throw CommandError(description: "desktop wait-window requires --id, --owner-pid, --bundle-id, or --title")
        }

        return DesktopWindowWaitTarget(
            id: id,
            ownerPID: ownerPID,
            bundleIdentifier: bundleIdentifier,
            title: title,
            titleMatch: titleMatch
        )
    }

    private func waitForDesktopWindow(
        target: DesktopWindowWaitTarget,
        expectedExists: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int,
        limit: Int
    ) throws -> DesktopWindowWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var state = try desktopWindows(limitOverride: limit)
        var current = desktopWindowMatches(in: state, target: target)

        while state.available && (current.isEmpty != !expectedExists), Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            state = try desktopWindows(limitOverride: limit)
            current = desktopWindowMatches(in: state, target: target)
        }

        guard state.available else {
            return DesktopWindowWaitVerification(
                ok: false,
                code: "desktop_window_metadata_unavailable",
                message: state.message,
                target: target,
                expectedExists: expectedExists,
                currentCount: 0,
                current: [],
                matched: false
            )
        }

        let matched = current.isEmpty == !expectedExists
        return DesktopWindowWaitVerification(
            ok: matched,
            code: matched ? "desktop_window_matched" : "desktop_window_timeout",
            message: matched
                ? "desktop window state matched expected existence"
                : "desktop window state did not match expected existence before timeout",
            target: target,
            expectedExists: expectedExists,
            currentCount: current.count,
            current: current,
            matched: matched
        )
    }

    private func desktopWindowMatches(
        in state: DesktopWindowsState,
        target: DesktopWindowWaitTarget
    ) -> [DesktopWindowRecord] {
        state.windows.filter { desktopWindow($0, matches: target) }
    }

    private func desktopWindow(
        _ window: DesktopWindowRecord,
        matches target: DesktopWindowWaitTarget
    ) -> Bool {
        if let id = target.id,
           window.id != id && window.stableIdentity.id != id {
            return false
        }
        if let ownerPID = target.ownerPID, window.ownerPID != ownerPID {
            return false
        }
        if let bundleIdentifier = target.bundleIdentifier,
           window.ownerBundleIdentifier != bundleIdentifier {
            return false
        }
        if let title = target.title,
           !desktopWindowTitle(window.title, matches: title, mode: target.titleMatch) {
            return false
        }
        return true
    }

    private func desktopWindowTitle(_ currentTitle: String?, matches expectedTitle: String, mode: String) -> Bool {
        guard let currentTitle else {
            return false
        }

        switch mode {
        case "exact":
            return currentTitle == expectedTitle
        case "prefix":
            return currentTitle.hasPrefix(expectedTitle)
        case "contains":
            return currentTitle.contains(expectedTitle)
        default:
            return false
        }
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
            throw CommandError(description: "Accessibility access is not enabled. Run `Ln1 trust` first.")
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
        let axApp = AXUIElementCreateApplication(pid)

        if id.first == "m" {
            let parts = id.dropFirst().split(separator: ".").map(String.init)
            guard let menuIndexString = parts.first, let menuIndex = Int(menuIndexString) else {
                throw CommandError(description: "invalid menu path in element id \(id)")
            }
            guard menuIndex == 0 else {
                throw CommandError(description: "menu bar index \(menuIndex) is out of range")
            }
            guard var current = accessibilityElement(axApp, kAXMenuBarAttribute) else {
                throw CommandError(description: "menu bar is unavailable")
            }
            for childIndexString in parts.dropFirst() {
                current = try childElement(
                    of: current,
                    childIndexString: childIndexString,
                    in: id
                )
            }
            return current
        }

        guard id.first == "w" else {
            throw CommandError(description: "element id must start with a window path like w0 or menu path like m0")
        }

        let parts = id.dropFirst().split(separator: ".").map(String.init)
        guard let windowIndexString = parts.first, let windowIndex = Int(windowIndexString) else {
            throw CommandError(description: "invalid window path in element id \(id)")
        }

        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        guard windows.indices.contains(windowIndex) else {
            throw CommandError(description: "window index \(windowIndex) is out of range")
        }

        var current = windows[windowIndex]
        for childIndexString in parts.dropFirst() {
            current = try childElement(
                of: current,
                childIndexString: childIndexString,
                in: id
            )
        }

        return current
    }

    private func childElement(
        of element: AXUIElement,
        childIndexString: String,
        in id: String
    ) throws -> AXUIElement {
        guard let childIndex = Int(childIndexString) else {
            throw CommandError(description: "invalid child index '\(childIndexString)' in \(id)")
        }

        let children = accessibilityArray(element, kAXChildrenAttribute)
        guard children.indices.contains(childIndex) else {
            throw CommandError(description: "child index \(childIndex) is out of range in \(id)")
        }
        return children[childIndex]
    }

    private func normalizedElementID(_ id: String) throws -> String {
        if id.first == "w" || id.first == "m" {
            return id
        }

        let parts = id.split(separator: ".").map(String.init)
        if parts.count >= 2,
           parts[0].first == "a",
           (parts[1].first == "w" || parts[1].first == "m") {
            return parts.dropFirst().joined(separator: ".")
        }

        throw CommandError(description: "element id must look like w0.1.2, m0.1.2, a0.w0.1.2, or a0.m0.1.2")
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

    private func accessibilityElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
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
