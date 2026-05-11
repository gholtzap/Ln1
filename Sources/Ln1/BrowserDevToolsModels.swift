import Foundation

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
