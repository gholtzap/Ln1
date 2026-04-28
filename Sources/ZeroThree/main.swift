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
    let action: String
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct AuditElementSummary: Codable {
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
    let outcome: AuditOutcome
}

struct AuditEntries: Codable {
    let path: String
    let command: String?
    let code: String?
    let limit: Int
    let entries: [ActionAuditRecord]
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
        case "policy":
            try policy()
        case "apps":
            try apps()
        case "state":
            try state()
        case "perform":
            try perform()
        case "audit":
            try audit()
        case "files":
            try files()
        case "schema":
            schema()
        case "help", "--help", "-h":
            printHelp()
        default:
            throw CommandError(description: "unknown command '\(command)'")
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

    private func policy() throws {
        try writeJSON(PolicySnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            defaultAllowedRisk: "low",
            riskLevels: ["low", "medium", "high", "unknown"],
            actions: knownPolicyActions()
        ))
    }

    private func apps() throws {
        let includeAll = flag("--all")
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
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

        try writeJSON(records)
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
            elementSummary = auditSummary(element)

            let available = actionNames(element)
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
                outcome: AuditOutcome(ok: true, code: "performed", message: message)
            ), to: auditURL)
            auditWritten = true

            try writeJSON(ActionResult(
                ok: true,
                pid: app.processIdentifier,
                element: elementID!,
                action: action!,
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

    private func files() throws {
        let mode = arguments.dropFirst().first ?? "list"
        let path = try requiredOption("--path")
        let rootURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL

        switch mode {
        case "stat":
            let record = try fileRecord(for: rootURL)
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
                rootURL: rootURL,
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
            let result = try filesystemSearchResult(
                rootURL: rootURL,
                query: query,
                caseSensitive: caseSensitive,
                maxDepth: maxDepth,
                limit: limit,
                includeHidden: includeHidden,
                maxFileBytes: maxFileBytes,
                maxSnippetCharacters: maxSnippetCharacters
            )
            try writeJSON(result)
        case "wait":
            let expectedExists = option("--exists").map(parseBool) ?? true
            let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
            let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
            let result = try waitForFileState(
                at: rootURL,
                expectedExists: expectedExists,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            try writeJSON(result)
        case "checksum":
            let algorithm = option("--algorithm") ?? "sha256"
            let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 104_857_600)
            let result = try fileChecksum(
                for: rootURL,
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
                leftURL: rootURL,
                rightURL: rightURL,
                algorithm: algorithm,
                maxFileBytes: maxFileBytes
            )
            try writeJSON(result)
        case "duplicate":
            let destinationPath = try requiredOption("--to")
            let destinationURL = URL(fileURLWithPath: expandedPath(destinationPath)).standardizedFileURL
            let result = try duplicateFile(from: rootURL, to: destinationURL)
            try writeJSON(result)
        case "move":
            let destinationPath = try requiredOption("--to")
            let destinationURL = URL(fileURLWithPath: expandedPath(destinationPath)).standardizedFileURL
            let result = try moveFile(from: rootURL, to: destinationURL)
            try writeJSON(result)
        case "mkdir":
            let result = try createDirectory(at: rootURL)
            try writeJSON(result)
        default:
            throw CommandError(description: "unknown files mode '\(mode)'")
        }
    }

    private func auditSummary(_ element: AXUIElement) -> AuditElementSummary {
        AuditElementSummary(
            role: stringAttribute(element, kAXRoleAttribute),
            subrole: stringAttribute(element, kAXSubroleAttribute),
            title: stringAttribute(element, kAXTitleAttribute),
            help: stringAttribute(element, kAXHelpAttribute),
            enabled: boolAttribute(element, kAXEnabledAttribute),
            actions: actionNames(element)
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
        case "filesystem.stat", "filesystem.list", "filesystem.search", "filesystem.wait", "filesystem.checksum", "filesystem.compare":
            return "low"
        case "filesystem.duplicate", "filesystem.move", "filesystem.createDirectory":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func knownPolicyActions() -> [PolicyActionRecord] {
        [
            PolicyActionRecord(name: kAXPressAction as String, domain: "accessibility", risk: "low", mutates: true),
            PolicyActionRecord(name: kAXShowMenuAction as String, domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: kAXConfirmAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: kAXPickAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.stat", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.list", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.search", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.wait", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.checksum", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.compare", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.duplicate", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.move", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.createDirectory", domain: "filesystem", risk: "medium", mutates: true)
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
                    "role": "AXButton",
                    "actions": ["AXPress"],
                    "children": []
                  }
                ]
              }
            ]
          },
          "perform": {
            "command": "03 perform --pid 456 --element a0.w0.3.1 --action AXPress --allow-risk low --reason 'Open details'",
            "result": {
              "ok": true,
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
              "outcome": { "ok": true, "code": "performed", "message": "Performed AXPress on w0.3.1." }
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
          }
        }
        """)
    }

    private func printHelp() {
        print("""
        03: macOS semantic computer substrate prototype

        Usage:
          03 trust [--prompt true|false]
          03 policy
          03 apps [--all]
          03 state [--pid PID] [--all] [--include-background] [--depth N] [--max-children N]
          03 perform [--pid PID] --element w0.1.2|a0.w0.1.2 [--action AXPress] [--allow-risk low|medium|high|unknown] [--reason TEXT] [--audit-log PATH]
          03 audit [--limit N] [--command NAME] [--code OUTCOME_CODE] [--audit-log PATH]
          03 files stat --path PATH
          03 files list --path PATH [--depth N] [--limit N] [--include-hidden]
          03 files search --path PATH --query TEXT [--depth N] [--limit N] [--include-hidden] [--case-sensitive] [--max-file-bytes N] [--max-snippet-characters N]
          03 files wait --path PATH [--exists true|false] [--timeout-ms N] [--interval-ms N]
          03 files checksum --path PATH [--algorithm sha256] [--max-file-bytes N]
          03 files compare --path LEFT --to RIGHT [--algorithm sha256] [--max-file-bytes N]
          03 files duplicate --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 files move --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 files mkdir --path PATH --allow-risk medium [--reason TEXT] [--audit-log PATH]
          03 schema

        Notes:
          - Run `03 trust` first and grant Accessibility access when prompted.
          - `policy` describes known action risk levels and mutation behavior.
          - `state` emits structured JSON from macOS Accessibility APIs.
          - `state --all` walks every running GUI app macOS exposes to this process.
          - Element IDs are child-index paths. Use IDs from `state` with `perform`.
          - `perform` defaults to `--allow-risk low`; medium, high, and unknown actions require explicit allowance.
          - `perform` appends a structured JSONL audit record before returning success or failure.
          - `audit` can filter records by command name and outcome code before applying the limit.
          - `files` emits read-only filesystem metadata, bounded search evidence, and available typed file actions.
          - `files wait` waits for a path to exist or disappear and returns typed evidence.
          - `files checksum` returns a bounded SHA-256 digest for a regular file without exposing file contents.
          - `files compare` compares two regular files by bounded SHA-256 digest and size.
          - `files duplicate` copies one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files move` moves one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files mkdir` creates one directory, refuses existing paths, verifies the result, and writes an audit record.
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
        maxSnippetCharacters: Int
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
                        maxSnippetCharacters: maxSnippetCharacters
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
        maxSnippetCharacters: Int
    ) -> [FileLineMatch] {
        var matches: [FileLineMatch] = []
        let lines = contents.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
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
            FileAction(name: "filesystem.stat", risk: "low", mutates: false)
        ]

        if kind == "directory", readable {
            actions.append(FileAction(name: "filesystem.list", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
        }

        if kind == "directory", writable {
            actions.append(FileAction(name: "filesystem.createDirectory", risk: "medium", mutates: true))
        }

        if kind == "regularFile", readable {
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.checksum", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.compare", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.duplicate", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.move", risk: "medium", mutates: true))
        }

        return actions
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
            buildNode(window, id: "\(idPrefix)\(index)", depth: depth, maxChildren: maxChildren)
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
        let children: [ElementNode]
        if depth > 0 {
            children = accessibilityArray(element, kAXChildrenAttribute)
                .prefix(maxChildren)
                .enumerated()
                .map { index, child in
                    buildNode(child, id: "\(id).\(index)", depth: depth - 1, maxChildren: maxChildren)
                }
        } else {
            children = []
        }

        return ElementNode(
            id: id,
            role: stringAttribute(element, kAXRoleAttribute),
            subrole: stringAttribute(element, kAXSubroleAttribute),
            title: stringAttribute(element, kAXTitleAttribute),
            value: stringLikeAttribute(element, kAXValueAttribute),
            help: stringAttribute(element, kAXHelpAttribute),
            enabled: boolAttribute(element, kAXEnabledAttribute),
            frame: frame(element),
            actions: actionNames(element),
            children: children
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
