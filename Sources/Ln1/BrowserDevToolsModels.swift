import Foundation

struct BrowserAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct BrowserLaunchResult: Codable {
    let ok: Bool
    let generatedAt: String
    let platform: String
    let action: String
    let risk: String
    let browser: String
    let bundleIdentifier: String?
    let appPath: String?
    let executablePath: String?
    let profilePath: String
    let downloadDirectoryPath: String?
    let preferencesPath: String?
    let preferenceKeys: [String]
    let endpoint: String
    let remoteDebuggingPort: Int
    let url: String?
    let dryRun: Bool
    let launched: Bool
    let pid: Int32?
    let arguments: [String]
    let message: String
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

struct BrowserKeyDefinition {
    let key: String
    let code: String
    let windowsVirtualKeyCode: Int
    let text: String?
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
    let context: String?
    let framePath: String?
    let frameURL: String?
    let frameAccessible: Bool?
    let shadowPath: String?
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

struct BrowserFileUploadPayload: Codable {
    let ok: Bool
    let code: String
    let message: String
    let selector: String
    let tagName: String?
    let inputType: String?
    let disabled: Bool?
    let multiple: Bool?
    let fileCount: Int
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

struct BrowserFileUploadResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let selector: String
    let fileCount: Int
    let totalBytes: Int
    let pathDigest: String
    let verification: FileOperationVerification
    let targetTagName: String?
    let targetInputType: String?
    let targetDisabled: Bool?
    let targetMultiple: Bool?
    let resultingFileCount: Int
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

struct DevToolsTarget: Decodable {
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

struct CDPEvaluateResponse: Decodable {
    let id: Int?
    let result: CDPEvaluateResult?
    let error: CDPError?
}

struct CDPCommandResponse: Decodable {
    let id: Int?
    let result: CDPCommandResult?
    let error: CDPError?
}

struct CDPCommandResult: Decodable {
    let data: String?
    let root: CDPNode?
    let nodeId: Int?
}

struct CDPNode: Decodable {
    let nodeId: Int?
}

struct CDPEvaluateResult: Decodable {
    let result: CDPRemoteObject
}

struct CDPRemoteObject: Decodable {
    let type: String?
    let value: String?
    let description: String?
}

struct CDPError: Decodable {
    let code: Int
    let message: String
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
    var uploadSelector: String? = nil
    var uploadFileCount: Int? = nil
    var uploadTotalBytes: Int? = nil
    var uploadDigest: String? = nil
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
    var screenshotFormat: String? = nil
    var screenshotByteCount: Int? = nil
    var screenshotDigest: String? = nil
    var networkEntryCount: Int? = nil
    var networkDigest: String? = nil
    var consoleEntryCount: Int? = nil
    var consoleDigest: String? = nil
    var dialogEntryCount: Int? = nil
    var dialogDigest: String? = nil
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

struct BrowserScreenshotResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let format: String
    let byteCount: Int
    let digest: String
    let imageWidth: Double?
    let imageHeight: Double?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserNetworkEntry: Codable {
    let name: String
    let entryType: String
    let initiatorType: String?
    let startTime: Double?
    let duration: Double?
    let transferSize: Int?
    let encodedBodySize: Int?
    let decodedBodySize: Int?
    let nextHopProtocol: String?
    let responseStatus: Int?
    let urlScheme: String?
    let urlHost: String?
}

struct BrowserNetworkPayload: Codable {
    let url: String?
    let title: String?
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let entries: [BrowserNetworkEntry]
}

struct BrowserNetworkResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let url: String?
    let title: String?
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let maxEntries: Int
    let entries: [BrowserNetworkEntry]
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserConsoleEntry: Codable {
    let source: String
    let level: String
    let text: String
    let textLength: Int
    let textDigest: String
    let truncated: Bool
    let url: String?
    let lineNumber: Int?
    let timestamp: Double?
}

struct BrowserConsolePayload: Codable {
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let entries: [BrowserConsoleEntry]
}

struct BrowserConsoleResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let maxEntries: Int
    let maxMessageCharacters: Int
    let sampleMilliseconds: Int
    let entries: [BrowserConsoleEntry]
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BrowserDialogEntry: Codable {
    let type: String
    let message: String
    let messageLength: Int
    let messageDigest: String
    let truncated: Bool
    let url: String?
    let frameID: String?
    let hasBrowserHandler: Bool?
    let defaultPromptLength: Int?
    let defaultPromptDigest: String?
}

struct BrowserDialogPayload: Codable {
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let entries: [BrowserDialogEntry]
}

struct BrowserDialogResult: Codable {
    let generatedAt: String
    let platform: String
    let endpoint: String
    let tab: BrowserTab
    let action: String
    let risk: String
    let entryCount: Int
    let returnedCount: Int
    let truncated: Bool
    let maxEntries: Int
    let maxMessageCharacters: Int
    let sampleMilliseconds: Int
    let entries: [BrowserDialogEntry]
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

final class BrowserConsoleEntriesBox: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [BrowserConsoleEntry] = []
    private var error: Error?

    func append(_ entry: BrowserConsoleEntry) {
        lock.lock()
        entries.append(entry)
        lock.unlock()
    }

    func setError(_ newError: Error) {
        lock.lock()
        error = newError
        lock.unlock()
    }

    func snapshot() throws -> [BrowserConsoleEntry] {
        lock.lock()
        defer { lock.unlock() }
        if let error {
            throw error
        }
        return entries
    }
}

final class BrowserDialogEntriesBox: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [BrowserDialogEntry] = []
    private var error: Error?

    func append(_ entry: BrowserDialogEntry) {
        lock.lock()
        entries.append(entry)
        lock.unlock()
    }

    func setError(_ newError: Error) {
        lock.lock()
        error = newError
        lock.unlock()
    }

    func snapshot() throws -> [BrowserDialogEntry] {
        lock.lock()
        defer { lock.unlock() }
        if let error {
            throw error
        }
        return entries
    }
}

final class CDPResponseBox: @unchecked Sendable {
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

final class CDPCommandResponseBox: @unchecked Sendable {
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

final class DataResponseBox: @unchecked Sendable {
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
