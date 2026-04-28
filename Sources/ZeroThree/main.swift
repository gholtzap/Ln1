import AppKit
import ApplicationServices
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
    let outcome: AuditOutcome
}

struct AuditEntries: Codable {
    let path: String
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
        let records = try readAuditRecords(from: auditURL, limit: max(0, limit))
        try writeJSON(AuditEntries(path: auditURL.path, entries: records))
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

    private func readAuditRecords(from url: URL, limit: Int) throws -> [ActionAuditRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "audit log is not valid UTF-8")
        }

        let decoder = JSONDecoder()
        let lines = contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .suffix(limit)

        return try lines.map { line in
            let data = Data(line.utf8)
            return try decoder.decode(ActionAuditRecord.self, from: data)
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
            "command": "03 audit --limit 20",
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
          }
        }
        """)
    }

    private func printHelp() {
        print("""
        03: macOS semantic computer substrate prototype

        Usage:
          03 trust [--prompt true|false]
          03 apps [--all]
          03 state [--pid PID] [--all] [--include-background] [--depth N] [--max-children N]
          03 perform [--pid PID] --element w0.1.2|a0.w0.1.2 [--action AXPress] [--allow-risk low|medium|high|unknown] [--reason TEXT] [--audit-log PATH]
          03 audit [--limit N] [--audit-log PATH]
          03 files stat --path PATH
          03 files list --path PATH [--depth N] [--limit N] [--include-hidden]
          03 files search --path PATH --query TEXT [--depth N] [--limit N] [--include-hidden] [--case-sensitive] [--max-file-bytes N] [--max-snippet-characters N]
          03 schema

        Notes:
          - Run `03 trust` first and grant Accessibility access when prompted.
          - `state` emits structured JSON from macOS Accessibility APIs.
          - `state --all` walks every running GUI app macOS exposes to this process.
          - Element IDs are child-index paths. Use IDs from `state` with `perform`.
          - `perform` defaults to `--allow-risk low`; medium, high, and unknown actions require explicit allowance.
          - `perform` appends a structured JSONL audit record before returning success or failure.
          - `files` emits read-only filesystem metadata, bounded search evidence, and available typed file actions.
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
            actions: fileActions(kind: kind, readable: readable)
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

    private func fileActions(kind: String, readable: Bool) -> [FileAction] {
        var actions = [
            FileAction(name: "filesystem.stat", risk: "low", mutates: false)
        ]

        if kind == "directory", readable {
            actions.append(FileAction(name: "filesystem.list", risk: "low", mutates: false))
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
        }

        if kind == "regularFile", readable {
            actions.append(FileAction(name: "filesystem.search", risk: "low", mutates: false))
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
