import AppKit
import CryptoKit
import Foundation

extension Ln1CLI {
    func files() throws {
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
        case "rollback-text":
            let auditRecordID = try requiredOption("--audit-id")
            let result = try rollbackFileText(auditRecordID: auditRecordID)
            try writeJSON(result)
        default:
            throw CommandError(description: "unknown files mode '\(mode)'")
        }
    }

    func browser() throws {
        let mode = arguments.dropFirst().first ?? "tabs"

        switch mode {
        case "launch":
            try writeJSON(browserLaunch())
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
        case "screenshot":
            let id = try requiredOption("--id")
            try writeJSON(browserScreenshot(id: id))
        case "console":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 100)
            let maxMessageCharacters = max(0, option("--max-message-characters").flatMap(Int.init) ?? 1_000)
            let sampleMilliseconds = max(0, option("--sample-ms").flatMap(Int.init) ?? 1_000)
            try writeJSON(browserConsole(
                id: id,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            ))
        case "dialogs":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 20)
            let maxMessageCharacters = max(0, option("--max-message-characters").flatMap(Int.init) ?? 1_000)
            let sampleMilliseconds = max(0, option("--sample-ms").flatMap(Int.init) ?? 1_000)
            try writeJSON(browserDialogs(
                id: id,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            ))
        case "network":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 100)
            try writeJSON(browserNetwork(id: id, maxEntries: maxEntries))
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

    func browserLaunch() throws -> BrowserLaunchResult {
        let action = "browser.launch"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        guard policy.allowed else {
            throw CommandError(description: policy.message)
        }

        let browser = option("--browser") ?? "chrome"
        let port = try browserLaunchPort()
        let profileURL = URL(fileURLWithPath: expandedPath(
            option("--profile") ?? FileManager.default.temporaryDirectory
                .appendingPathComponent("Ln1-browser-profile-\(browser)-\(port)")
                .path
        )).standardizedFileURL
        let endpoint = "http://127.0.0.1:\(port)"
        let dryRun = try option("--dry-run").map {
            try booleanOption($0, optionName: "--dry-run")
        } ?? true
        let url = option("--url")
        let browserTarget = browserLaunchTarget(browser: browser)
        let appURL = try browserLaunchAppURL(target: browserTarget)
        let executableURL = try browserLaunchExecutableURL(target: browserTarget, appURL: appURL)
        let launchArguments = browserLaunchArguments(port: port, profileURL: profileURL, url: url)

        guard !dryRun else {
            return BrowserLaunchResult(
                ok: true,
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                action: action,
                risk: risk,
                browser: browserTarget.name,
                bundleIdentifier: browserTarget.bundleIdentifier,
                appPath: appURL?.path,
                executablePath: executableURL.path,
                profilePath: profileURL.path,
                endpoint: endpoint,
                remoteDebuggingPort: port,
                url: url,
                dryRun: true,
                launched: false,
                pid: nil,
                arguments: [executableURL.path] + launchArguments,
                message: "Dry run only. Browser launch command was planned with an isolated profile and DevTools endpoint."
            )
        }

        try FileManager.default.createDirectory(at: profileURL, withIntermediateDirectories: true)
        let process = Process()
        process.executableURL = executableURL
        process.arguments = launchArguments
        try process.run()

        return BrowserLaunchResult(
            ok: true,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            action: action,
            risk: risk,
            browser: browserTarget.name,
            bundleIdentifier: browserTarget.bundleIdentifier,
            appPath: appURL?.path,
            executablePath: executableURL.path,
            profilePath: profileURL.path,
            endpoint: endpoint,
            remoteDebuggingPort: port,
            url: url,
            dryRun: false,
            launched: true,
            pid: process.processIdentifier,
            arguments: [executableURL.path] + launchArguments,
            message: "Launched browser with an isolated profile and DevTools endpoint."
        )
    }

    struct BrowserLaunchTarget {
        let name: String
        let bundleIdentifier: String?
        let executableName: String?
    }

    func browserLaunchTarget(browser rawBrowser: String) -> BrowserLaunchTarget {
        switch rawBrowser.lowercased() {
        case "chrome", "google-chrome", "google chrome":
            return BrowserLaunchTarget(
                name: "chrome",
                bundleIdentifier: "com.google.Chrome",
                executableName: "Google Chrome"
            )
        case "chrome-canary", "canary":
            return BrowserLaunchTarget(
                name: "chrome-canary",
                bundleIdentifier: "com.google.Chrome.canary",
                executableName: "Google Chrome Canary"
            )
        case "chromium":
            return BrowserLaunchTarget(
                name: "chromium",
                bundleIdentifier: "org.chromium.Chromium",
                executableName: "Chromium"
            )
        case "edge", "microsoft-edge":
            return BrowserLaunchTarget(
                name: "edge",
                bundleIdentifier: "com.microsoft.edgemac",
                executableName: "Microsoft Edge"
            )
        case "brave":
            return BrowserLaunchTarget(
                name: "brave",
                bundleIdentifier: "com.brave.Browser",
                executableName: "Brave Browser"
            )
        default:
            return BrowserLaunchTarget(name: rawBrowser, bundleIdentifier: nil, executableName: nil)
        }
    }

    func browserLaunchPort() throws -> Int {
        let port = option("--remote-debugging-port").flatMap(Int.init) ?? 9_222
        guard (1...65_535).contains(port) else {
            throw CommandError(description: "--remote-debugging-port must be between 1 and 65535")
        }
        return port
    }

    func browserLaunchAppURL(target: BrowserLaunchTarget) throws -> URL? {
        if let appPath = option("--app-path") {
            return URL(fileURLWithPath: expandedPath(appPath)).standardizedFileURL
        }
        guard let bundleIdentifier = target.bundleIdentifier else {
            return nil
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    func browserLaunchExecutableURL(target: BrowserLaunchTarget, appURL: URL?) throws -> URL {
        if let executablePath = option("--executable") {
            return URL(fileURLWithPath: expandedPath(executablePath)).standardizedFileURL
        }
        guard let appURL, let executableName = target.executableName else {
            throw CommandError(description: "could not resolve a browser executable; pass --executable PATH or --app-path PATH")
        }
        return appURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("MacOS")
            .appendingPathComponent(executableName)
            .standardizedFileURL
    }

    func browserLaunchArguments(port: Int, profileURL: URL, url: String?) -> [String] {
        var launchArguments = [
            "--remote-debugging-port=\(port)",
            "--user-data-dir=\(profileURL.path)",
            "--no-first-run",
            "--no-default-browser-check"
        ]
        if let url {
            launchArguments.append(url)
        }
        return launchArguments
    }

    func fileOperationPreflight(operation rawOperation: String) throws -> FileOperationPreflight {
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

    func preflightFileCopyLikeOperation(
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

    func preflightDirectoryCreation(_ directoryURL: URL) -> FileOperationPreflight {
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

    func preflightMoveRollback(auditRecordID: String) throws -> FileOperationPreflight {
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

    func fileOperationPreflightResult(
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

    func fileAuditTarget(url: URL) -> FileAuditTarget {
        FileAuditTarget(
            path: url.path,
            id: nil,
            kind: nil,
            sizeBytes: nil,
            exists: FileManager.default.fileExists(atPath: url.path)
        )
    }

    func directoryExistsCheck(name: String, url: URL) -> FilePreflightCheck {
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

    func writableDirectoryCheck(name: String, url: URL) -> FilePreflightCheck {
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

    func workflowDoctorCheck(from fileCheck: FilePreflightCheck, remediation: String) -> DoctorCheck {
        DoctorCheck(
            name: fileCheck.name,
            status: fileCheck.ok ? "pass" : "fail",
            required: true,
            message: fileCheck.message,
            remediation: fileCheck.ok ? nil : remediation
        )
    }

    func directoryExistsDoctorCheck(name: String, url: URL) -> DoctorCheck {
        workflowDoctorCheck(
            from: directoryExistsCheck(name: name, url: url),
            remediation: "Pass an existing directory path."
        )
    }

    func writableDirectoryDoctorCheck(name: String, url: URL) -> DoctorCheck {
        workflowDoctorCheck(
            from: writableDirectoryCheck(name: name, url: url),
            remediation: "Choose a writable directory or adjust filesystem permissions."
        )
    }

    func duplicateFile(from sourceURL: URL, to destinationURL: URL) throws -> FileOperationResult {
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

    func fileAuditTarget(record: FileRecord, exists: Bool) -> FileAuditTarget {
        FileAuditTarget(
            path: record.path,
            id: record.id,
            kind: record.kind,
            sizeBytes: record.sizeBytes,
            exists: exists
        )
    }

    func verifyDuplicate(source: FileRecord, destination: FileRecord) -> FileOperationVerification {
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

    func writeFileText(
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
        let rollbackSnapshotURL = option("--rollback-snapshot")
            .map { URL(fileURLWithPath: expandedPath($0)).standardizedFileURL }
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
                fileRollbackSnapshotPath: rollbackSnapshotURL?.path,
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

            if let rollbackSnapshotURL {
                try writeFileTextRollbackSnapshot(
                    auditID: auditID,
                    fileURL: url,
                    previousRecord: previousRecord,
                    to: rollbackSnapshotURL
                )
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
                rollbackSnapshotPath: rollbackSnapshotURL?.path,
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

    func verifyWrittenTextFile(
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

    func appendFileText(
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
        let rollbackSnapshotURL = option("--rollback-snapshot")
            .map { URL(fileURLWithPath: expandedPath($0)).standardizedFileURL }
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
                fileRollbackSnapshotPath: rollbackSnapshotURL?.path,
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
                if let rollbackSnapshotURL {
                    try writeFileTextRollbackSnapshot(
                        auditID: auditID,
                        fileURL: url,
                        previousRecord: previousRecord,
                        to: rollbackSnapshotURL
                    )
                }
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
                if let rollbackSnapshotURL {
                    try writeFileTextRollbackSnapshot(
                        auditID: auditID,
                        fileURL: url,
                        previousRecord: previousRecord,
                        to: rollbackSnapshotURL
                    )
                }
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
                rollbackSnapshotPath: rollbackSnapshotURL?.path,
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

    func verifyAppendedTextFile(
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

    func writeFileTextRollbackSnapshot(
        auditID: String,
        fileURL: URL,
        previousRecord: FileRecord?,
        to url: URL
    ) throws {
        let previousText: String?
        if let previousRecord {
            guard previousRecord.kind == "regularFile" else {
                throw CommandError(description: "file text rollback snapshots support regular files only")
            }
            let data = try Data(contentsOf: fileURL)
            guard let text = String(data: data, encoding: .utf8) else {
                throw CommandError(description: "previous file contents are not valid UTF-8 at \(fileURL.path)")
            }
            previousText = text
        } else {
            previousText = nil
        }

        let textData = previousText?.data(using: .utf8)
        let snapshot = FileTextRollbackSnapshot(
            version: 1,
            auditID: auditID,
            savedAt: ISO8601DateFormatter().string(from: Date()),
            path: fileURL.path,
            previousExists: previousRecord != nil,
            previousTextLength: previousText?.count,
            previousTextDigest: previousText.map(sha256Digest),
            previousTextBase64: textData?.base64EncodedString()
        )
        let data = try JSONEncoder().encode(snapshot)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: Int16(0o600))], ofItemAtPath: url.path)
    }

    func readFileTextRollbackSnapshot(from url: URL) throws -> FileTextRollbackSnapshot {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(FileTextRollbackSnapshot.self, from: data)
        } catch {
            throw CommandError(description: "could not read file text rollback snapshot at \(url.path): \(error.localizedDescription)")
        }
    }

    func fileTextRollbackText(from snapshot: FileTextRollbackSnapshot) throws -> String? {
        guard snapshot.previousExists else {
            return nil
        }
        guard let base64 = snapshot.previousTextBase64,
              let data = Data(base64Encoded: base64),
              let text = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "file text rollback snapshot does not contain valid UTF-8 text")
        }
        guard snapshot.previousTextLength == text.count,
              snapshot.previousTextDigest == sha256Digest(text) else {
            throw CommandError(description: "file text rollback snapshot text does not match its metadata")
        }
        return text
    }

    func rollbackFileText(auditRecordID: String) throws -> FileTextRollbackResult {
        let action = "filesystem.rollbackTextWrite"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = fileActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        var rollbackSourceTarget: FileAuditTarget?
        var restoreTarget: FileAuditTarget?
        var verification: FileOperationVerification?
        var snapshotPath: String?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "files.rollback-text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                fileSource: rollbackSourceTarget,
                fileDestination: restoreTarget,
                fileRollbackSnapshotPath: snapshotPath,
                verification: verification,
                rollbackOfAuditID: auditRecordID,
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

            let supportedCodes: Set<String> = [
                "created_text_file",
                "overwrote_text_file",
                "appended_text_file",
                "created_appended_text_file"
            ]
            guard (originalRecord.command == "files.write-text" || originalRecord.command == "files.append-text"),
                  originalRecord.outcome.ok,
                  supportedCodes.contains(originalRecord.outcome.code) else {
                let message = "audit record \(auditRecordID) is not a successful file text write or append record"
                try writeAudit(ok: false, code: "unsupported_rollback_record", message: message)
                throw CommandError(description: message)
            }

            guard let originalSource = originalRecord.fileSource,
                  let writtenDestination = originalRecord.fileDestination else {
                let message = "audit record \(auditRecordID) does not contain file text source and destination metadata"
                try writeAudit(ok: false, code: "rollback_metadata_missing", message: message)
                throw CommandError(description: message)
            }

            guard let originalSnapshotPath = originalRecord.fileRollbackSnapshotPath else {
                let message = "audit record \(auditRecordID) does not include a rollback snapshot path"
                try writeAudit(ok: false, code: "rollback_snapshot_missing", message: message)
                throw CommandError(description: message)
            }
            snapshotPath = originalSnapshotPath

            let fileURL = URL(fileURLWithPath: writtenDestination.path).standardizedFileURL
            rollbackSourceTarget = FileAuditTarget(
                path: fileURL.path,
                id: nil,
                kind: nil,
                sizeBytes: nil,
                exists: FileManager.default.fileExists(atPath: fileURL.path)
            )
            restoreTarget = originalSource

            let snapshotURL = URL(fileURLWithPath: expandedPath(originalSnapshotPath)).standardizedFileURL
            let snapshot = try readFileTextRollbackSnapshot(from: snapshotURL)
            guard snapshot.auditID == auditRecordID,
                  URL(fileURLWithPath: snapshot.path).standardizedFileURL.path == fileURL.path else {
                let message = "file text rollback snapshot does not match audit record \(auditRecordID)"
                try writeAudit(ok: false, code: "rollback_snapshot_mismatch", message: message)
                throw CommandError(description: message)
            }

            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let currentRecord = try fileRecord(for: fileURL)
            rollbackSourceTarget = fileAuditTarget(record: currentRecord, exists: true)
            guard fileTextRecord(currentRecord, matches: writtenDestination) else {
                let message = "current file does not match audited write result at \(fileURL.path)"
                try writeAudit(ok: false, code: "rollback_current_mismatch", message: message)
                throw CommandError(description: message)
            }

            let parentURL = fileURL.deletingLastPathComponent()
            guard FileManager.default.isWritableFile(atPath: parentURL.path) else {
                let message = "file parent directory is not writable at \(parentURL.path)"
                try writeAudit(ok: false, code: "rollback_parent_unwritable", message: message)
                throw CommandError(description: message)
            }

            if snapshot.previousExists {
                guard currentRecord.writable else {
                    let message = "current file is not writable at \(fileURL.path)"
                    try writeAudit(ok: false, code: "rollback_file_unwritable", message: message)
                    throw CommandError(description: message)
                }
                guard let restoredText = try fileTextRollbackText(from: snapshot) else {
                    let message = "file text rollback snapshot is missing previous text"
                    try writeAudit(ok: false, code: "rollback_snapshot_missing_text", message: message)
                    throw CommandError(description: message)
                }
                try restoredText.write(to: fileURL, atomically: true, encoding: .utf8)
            } else {
                try FileManager.default.removeItem(at: fileURL)
            }

            if let restoredRecord = try? refreshedFileRecord(for: fileURL) {
                restoreTarget = fileAuditTarget(record: restoredRecord, exists: true)
            } else {
                restoreTarget = FileAuditTarget(
                    path: fileURL.path,
                    id: originalSource.id,
                    kind: originalSource.kind,
                    sizeBytes: originalSource.sizeBytes,
                    exists: false
                )
            }

            verification = try verifyFileTextRollback(
                path: fileURL.path,
                expectedPrevious: originalSource,
                snapshot: snapshot
            )
            guard verification?.ok == true else {
                let message = verification?.message ?? "file text rollback verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Rolled back file text write \(auditRecordID) at \(fileURL.path)."
            try writeAudit(ok: true, code: "rolled_back_text_write", message: message)

            return FileTextRollbackResult(
                ok: true,
                action: action,
                risk: risk,
                rollbackOfAuditID: auditRecordID,
                path: fileURL.path,
                previous: rollbackSourceTarget!,
                current: restoreTarget!,
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

    func fileTextRecord(_ record: FileRecord, matches target: FileAuditTarget) -> Bool {
        record.path == target.path
            && (target.kind == nil || record.kind == target.kind)
            && (target.sizeBytes == nil || record.sizeBytes == target.sizeBytes)
    }

    func verifyFileTextRollback(
        path: String,
        expectedPrevious: FileAuditTarget,
        snapshot: FileTextRollbackSnapshot
    ) throws -> FileOperationVerification {
        if snapshot.previousExists {
            let restoredRecord = try fileRecord(for: URL(fileURLWithPath: path))
            guard restoredRecord.path == expectedPrevious.path else {
                return FileOperationVerification(
                    ok: false,
                    code: "restored_path_mismatch",
                    message: "restored file path does not match original path"
                )
            }
            guard restoredRecord.kind == "regularFile" else {
                return FileOperationVerification(
                    ok: false,
                    code: "restored_not_regular_file",
                    message: "restored path is not a regular file"
                )
            }
            if let expectedSize = expectedPrevious.sizeBytes, restoredRecord.sizeBytes != expectedSize {
                return FileOperationVerification(
                    ok: false,
                    code: "restored_size_mismatch",
                    message: "restored file size does not match original metadata"
                )
            }
            let text = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
            guard snapshot.previousTextLength == text.count,
                  snapshot.previousTextDigest == sha256Digest(text) else {
                return FileOperationVerification(
                    ok: false,
                    code: "restored_text_mismatch",
                    message: "restored file text does not match rollback snapshot metadata"
                )
            }
            return FileOperationVerification(
                ok: true,
                code: "text_restored",
                message: "file text matches the rollback snapshot previous state"
            )
        }

        guard !FileManager.default.fileExists(atPath: path) else {
            return FileOperationVerification(
                ok: false,
                code: "restored_missing_mismatch",
                message: "file still exists after rollback to missing state"
            )
        }
        guard expectedPrevious.exists == false else {
            return FileOperationVerification(
                ok: false,
                code: "previous_metadata_mismatch",
                message: "audit source metadata did not describe a missing file"
            )
        }
        return FileOperationVerification(
            ok: true,
            code: "missing_restored",
            message: "file was removed to restore the audited missing previous state"
        )
    }

    func moveFile(from sourceURL: URL, to destinationURL: URL) throws -> FileOperationResult {
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

    func verifyMove(source: FileRecord, destination: FileRecord) -> FileOperationVerification {
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

    func createDirectory(at directoryURL: URL) throws -> DirectoryOperationResult {
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

    func verifyCreatedDirectory(_ directory: FileRecord) -> FileOperationVerification {
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

    func rollbackFileMove(auditRecordID: String) throws -> FileRollbackResult {
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

    func fileRecord(_ record: FileRecord, matches target: FileAuditTarget) -> Bool {
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

    func verifyMoveRollback(
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

    func waitForFileState(
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

    struct FileWaitSnapshot {
        let exists: Bool
        let record: FileRecord?
        let digest: String?
        let digestError: String?
    }

    func fileWaitSnapshot(
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

    func fileWaitSnapshot(
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

    struct FileWatchSnapshot {
        let recordsByPath: [String: FileRecord]
        let truncated: Bool
    }

    func watchFileChanges(
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

    func fileWatchSnapshot(
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

    func collectFileWatchRecords(
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

    func fileWatchEvents(
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

    func fileWatchFingerprint(_ record: FileRecord) -> String {
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

    func browserTabs(includeNonPageTargets: Bool) throws -> BrowserTabsState {
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

    func browserTab(id: String, includeNonPageTargets: Bool) throws -> BrowserTabState {
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

    func fetchBrowserTabs(
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

    func browserTab(from target: DevToolsTarget) -> BrowserTab {
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
                    name: "browser.captureScreenshot",
                    risk: browserActionRisk(for: "browser.captureScreenshot"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readConsole",
                    risk: browserActionRisk(for: "browser.readConsole"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readDialogs",
                    risk: browserActionRisk(for: "browser.readDialogs"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readNetwork",
                    risk: browserActionRisk(for: "browser.readNetwork"),
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

    func browserText(id: String, maxCharacters: Int) throws -> BrowserTextResult {
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

    func browserScreenshot(id: String) throws -> BrowserScreenshotResult {
        let action = "browser.captureScreenshot"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let format = try browserScreenshotFormat(option("--format") ?? "png")
        let quality = option("--quality").flatMap(Int.init)
        let fromSurface = option("--from-surface").map(parseBool) ?? true
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            screenshotFormat: format
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.screenshot",
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
                domDigest: nil,
                screenshotFormat: format
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let bytes = try captureBrowserScreenshot(
                format: format,
                quality: quality,
                fromSurface: fromSurface,
                at: webSocketURL
            )
            let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            let image = NSImage(data: bytes)
            let width = image.map { Double($0.size.width) }
            let height = image.map { Double($0.size.height) }
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                screenshotFormat: format,
                screenshotByteCount: bytes.count,
                screenshotDigest: digest
            )

            let message = "Captured browser screenshot metadata from tab \(id)."
            try writeAudit(ok: true, code: "captured_screenshot", message: message)

            return BrowserScreenshotResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                format: format,
                byteCount: bytes.count,
                digest: digest,
                imageWidth: width,
                imageHeight: height,
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

    func browserConsole(
        id: String,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserConsoleResult {
        let action = "browser.readConsole"
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
                command: "browser.console",
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

            let payload = try readBrowserConsoleMessages(
                from: webSocketURL,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                consoleEntryCount: payload.entryCount,
                consoleDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser console metadata from tab \(id)."
                : "Read browser console metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_console", message: message)

            return BrowserConsoleResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds,
                entries: payload.entries,
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

    func browserDialogs(
        id: String,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserDialogResult {
        let action = "browser.readDialogs"
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
                command: "browser.dialogs",
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

            let payload = try readBrowserDialogEvents(
                from: webSocketURL,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                dialogEntryCount: payload.entryCount,
                dialogDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser dialog metadata from tab \(id)."
                : "Read browser dialog metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_dialogs", message: message)

            return BrowserDialogResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds,
                entries: payload.entries,
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

    func browserNetwork(id: String, maxEntries: Int) throws -> BrowserNetworkResult {
        let action = "browser.readNetwork"
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
                command: "browser.network",
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

            let payload = try readBrowserNetworkActivity(
                from: webSocketURL,
                maxEntries: maxEntries
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                networkEntryCount: payload.entryCount,
                networkDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser network timing metadata from tab \(id)."
                : "Read browser network timing metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_network", message: message)

            return BrowserNetworkResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                url: payload.url,
                title: payload.title,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                entries: payload.entries,
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

    func browserDOM(id: String, maxElements: Int, maxTextCharacters: Int) throws -> BrowserDOMResult {
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

    func browserFill(id: String, selector: String, text: String) throws -> BrowserFormFillResult {
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

    func browserSelect(id: String, selector: String) throws -> BrowserSelectOptionResult {
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

    func browserCheck(id: String, selector: String) throws -> BrowserCheckedResult {
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

    func browserFocus(id: String, selector: String) throws -> BrowserFocusResult {
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

    func browserPressKey(id: String, key rawKey: String) throws -> BrowserKeyPressResult {
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

    func browserClick(id: String, selector: String) throws -> BrowserClickResult {
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

    func browserNavigate(id: String, requestedURL: String) throws -> BrowserNavigationResult {
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

    func browserWaitURL(id: String, expectedURL: String) throws -> BrowserURLWaitResult {
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

    func browserWaitSelector(id: String, selector: String) throws -> BrowserSelectorWaitResult {
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

    func browserWaitCount(id: String, selector: String) throws -> BrowserCountWaitResult {
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

    func browserWaitText(id: String, expectedText: String) throws -> BrowserTextWaitResult {
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

    func browserWaitElementText(id: String, selector: String, expectedText: String) throws -> BrowserElementTextWaitResult {
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

    func browserWaitValue(id: String, selector: String, expectedValue: String) throws -> BrowserValueWaitResult {
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

    func browserWaitReady(id: String) throws -> BrowserReadyWaitResult {
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

    func browserWaitTitle(id: String, expectedTitle: String) throws -> BrowserTitleWaitResult {
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

    func browserWaitChecked(id: String, selector: String) throws -> BrowserCheckedWaitResult {
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

    func browserWaitEnabled(id: String, selector: String) throws -> BrowserEnabledWaitResult {
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

    func browserWaitFocus(id: String, selector: String) throws -> BrowserFocusWaitResult {
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

    func browserWaitAttribute(id: String, selector: String, attribute: String, expectedValue: String) throws -> BrowserAttributeWaitResult {
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

    func readBrowserInnerText(from webSocketURL: URL) throws -> String {
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

    func readBrowserConsoleMessages(
        from webSocketURL: URL,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserConsolePayload {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try Self.browserConsolePayload(
                fromEventData: data,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters
            )
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { max(0, $0) } ?? max(sampleMilliseconds + 1_000, 2_000)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let entries = BrowserConsoleEntriesBox()
        let semaphore = DispatchSemaphore(value: 0)
        let deadline = Date().addingTimeInterval(Double(sampleMilliseconds) / 1_000.0)

        @Sendable func receiveNext() {
            task.receive { result in
                switch result {
                case .failure(let error):
                    entries.setError(error)
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
                        if let entry = try Self.browserConsoleEntry(fromEventData: data, maxMessageCharacters: maxMessageCharacters) {
                            entries.append(entry)
                        }
                        if Date() >= deadline {
                            semaphore.signal()
                        } else {
                            receiveNext()
                        }
                    } catch {
                        entries.setError(error)
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        receiveNext()
        try sendBrowserConsoleSetupCommand(id: 1, method: "Runtime.enable", task: task)
        try sendBrowserConsoleSetupCommand(id: 2, method: "Log.enable", task: task)

        if semaphore.wait(timeout: .now() + Double(timeout) / 1_000.0) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools console events")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        let capturedEntries = try entries.snapshot()
        return Self.browserConsolePayload(
            fromEntries: capturedEntries,
            maxEntries: maxEntries
        )
    }

    func sendBrowserConsoleSetupCommand(id: Int, method: String, task: URLSessionWebSocketTask) throws {
        let payload: [String: Any] = [
            "id": id,
            "method": method,
            "params": [:]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        task.send(.data(data)) { _ in }
    }

    private static func browserConsolePayload(
        fromEventData data: Data,
        maxEntries: Int,
        maxMessageCharacters: Int
    ) throws -> BrowserConsolePayload {
        let json = try JSONSerialization.jsonObject(with: data)
        let messages: [[String: Any]]
        if let array = json as? [[String: Any]] {
            messages = array
        } else if let object = json as? [String: Any] {
            messages = [object]
        } else {
            throw CommandError(description: "Chrome DevTools console event fixture was not an object or array")
        }
        let entries = try messages.compactMap { message -> BrowserConsoleEntry? in
            let eventData = try JSONSerialization.data(withJSONObject: message, options: [])
            return try browserConsoleEntry(fromEventData: eventData, maxMessageCharacters: maxMessageCharacters)
        }
        return browserConsolePayload(fromEntries: entries, maxEntries: maxEntries)
    }

    private static func browserConsolePayload(
        fromEntries entries: [BrowserConsoleEntry],
        maxEntries: Int
    ) -> BrowserConsolePayload {
        let selected = maxEntries == 0 ? [] : Array(entries.suffix(maxEntries))
        return BrowserConsolePayload(
            entryCount: entries.count,
            returnedCount: selected.count,
            truncated: entries.count > selected.count,
            entries: selected
        )
    }

    private static func browserConsoleEntry(
        fromEventData data: Data,
        maxMessageCharacters: Int
    ) throws -> BrowserConsoleEntry? {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let object = json as? [String: Any],
              let method = object["method"] as? String,
              let params = object["params"] as? [String: Any] else {
            return nil
        }

        if method == "Runtime.consoleAPICalled" {
            let level = params["type"] as? String ?? "log"
            let args = params["args"] as? [[String: Any]] ?? []
            let text = args.map(browserConsoleArgumentText).joined(separator: " ")
            return browserConsoleEntry(
                source: "runtime",
                level: level,
                text: text,
                maxMessageCharacters: maxMessageCharacters,
                url: nil,
                lineNumber: nil,
                timestamp: params["timestamp"] as? Double
            )
        }

        if method == "Log.entryAdded",
           let entry = params["entry"] as? [String: Any] {
            return browserConsoleEntry(
                source: entry["source"] as? String ?? "log",
                level: entry["level"] as? String ?? "info",
                text: entry["text"] as? String ?? "",
                maxMessageCharacters: maxMessageCharacters,
                url: entry["url"] as? String,
                lineNumber: entry["lineNumber"] as? Int,
                timestamp: entry["timestamp"] as? Double
            )
        }

        return nil
    }

    private static func browserConsoleArgumentText(_ argument: [String: Any]) -> String {
        if let value = argument["value"] {
            return String(describing: value)
        }
        if let description = argument["description"] as? String {
            return description
        }
        return argument["type"] as? String ?? ""
    }

    private static func browserConsoleEntry(
        source: String,
        level: String,
        text: String,
        maxMessageCharacters: Int,
        url: String?,
        lineNumber: Int?,
        timestamp: Double?
    ) -> BrowserConsoleEntry {
        let returnedText = String(text.prefix(maxMessageCharacters))
        return BrowserConsoleEntry(
            source: source,
            level: level,
            text: returnedText,
            textLength: text.count,
            textDigest: SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined(),
            truncated: text.count > returnedText.count,
            url: url,
            lineNumber: lineNumber,
            timestamp: timestamp
        )
    }

    func readBrowserDialogEvents(
        from webSocketURL: URL,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserDialogPayload {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try Self.browserDialogPayload(
                fromEventData: data,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters
            )
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { max(0, $0) } ?? max(sampleMilliseconds + 1_000, 2_000)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let entries = BrowserDialogEntriesBox()
        let semaphore = DispatchSemaphore(value: 0)
        let deadline = Date().addingTimeInterval(Double(sampleMilliseconds) / 1_000.0)

        @Sendable func receiveNext() {
            task.receive { result in
                switch result {
                case .failure(let error):
                    entries.setError(error)
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
                        if let entry = try Self.browserDialogEntry(fromEventData: data, maxMessageCharacters: maxMessageCharacters) {
                            entries.append(entry)
                        }
                        if Date() >= deadline {
                            semaphore.signal()
                        } else {
                            receiveNext()
                        }
                    } catch {
                        entries.setError(error)
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        receiveNext()
        try sendBrowserConsoleSetupCommand(id: 1, method: "Page.enable", task: task)

        if semaphore.wait(timeout: .now() + Double(timeout) / 1_000.0) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools dialog events")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        let capturedEntries = try entries.snapshot()
        return Self.browserDialogPayload(
            fromEntries: capturedEntries,
            maxEntries: maxEntries
        )
    }

    private static func browserDialogPayload(
        fromEventData data: Data,
        maxEntries: Int,
        maxMessageCharacters: Int
    ) throws -> BrowserDialogPayload {
        let json = try JSONSerialization.jsonObject(with: data)
        let messages: [[String: Any]]
        if let array = json as? [[String: Any]] {
            messages = array
        } else if let object = json as? [String: Any] {
            messages = [object]
        } else {
            throw CommandError(description: "Chrome DevTools dialog event fixture was not an object or array")
        }
        let entries = try messages.compactMap { message -> BrowserDialogEntry? in
            let eventData = try JSONSerialization.data(withJSONObject: message, options: [])
            return try browserDialogEntry(fromEventData: eventData, maxMessageCharacters: maxMessageCharacters)
        }
        return browserDialogPayload(fromEntries: entries, maxEntries: maxEntries)
    }

    private static func browserDialogPayload(
        fromEntries entries: [BrowserDialogEntry],
        maxEntries: Int
    ) -> BrowserDialogPayload {
        let selected = maxEntries == 0 ? [] : Array(entries.suffix(maxEntries))
        return BrowserDialogPayload(
            entryCount: entries.count,
            returnedCount: selected.count,
            truncated: entries.count > selected.count,
            entries: selected
        )
    }

    private static func browserDialogEntry(
        fromEventData data: Data,
        maxMessageCharacters: Int
    ) throws -> BrowserDialogEntry? {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let object = json as? [String: Any],
              let method = object["method"] as? String,
              method == "Page.javascriptDialogOpening",
              let params = object["params"] as? [String: Any] else {
            return nil
        }

        let message = params["message"] as? String ?? ""
        let returnedMessage = String(message.prefix(maxMessageCharacters))
        let defaultPrompt = params["defaultPrompt"] as? String
        let defaultPromptDigest = defaultPrompt.map { prompt in
            SHA256.hash(data: Data(prompt.utf8)).map { String(format: "%02x", $0) }.joined()
        }
        return BrowserDialogEntry(
            type: params["type"] as? String ?? "unknown",
            message: returnedMessage,
            messageLength: message.count,
            messageDigest: SHA256.hash(data: Data(message.utf8)).map { String(format: "%02x", $0) }.joined(),
            truncated: message.count > returnedMessage.count,
            url: params["url"] as? String,
            frameID: params["frameId"] as? String,
            hasBrowserHandler: params["hasBrowserHandler"] as? Bool,
            defaultPromptLength: defaultPrompt?.count,
            defaultPromptDigest: defaultPromptDigest
        )
    }

    func readBrowserNetworkActivity(
        from webSocketURL: URL,
        maxEntries: Int
    ) throws -> BrowserNetworkPayload {
        let expression = """
        (() => {
          const maxEntries = \(maxEntries);
          const round = (value) => Number.isFinite(value) ? Math.round(value * 1000) / 1000 : null;
          const finiteInteger = (value) => Number.isFinite(value) ? Math.round(value) : null;
          const urlParts = (name) => {
            try {
              const url = new URL(name, location.href);
              return {
                scheme: url.protocol ? url.protocol.replace(/:$/, "") : null,
                host: url.host || null
              };
            } catch {
              return { scheme: null, host: null };
            }
          };
          const entries = [
            ...performance.getEntriesByType("navigation"),
            ...performance.getEntriesByType("resource")
          ];
          const selected = maxEntries === 0 ? [] : entries.slice(Math.max(0, entries.length - maxEntries));
          const resultEntries = selected.map((entry) => {
            const parts = urlParts(entry.name || "");
            return {
              name: entry.name || "",
              entryType: entry.entryType || "",
              initiatorType: entry.initiatorType || null,
              startTime: round(entry.startTime),
              duration: round(entry.duration),
              transferSize: finiteInteger(entry.transferSize),
              encodedBodySize: finiteInteger(entry.encodedBodySize),
              decodedBodySize: finiteInteger(entry.decodedBodySize),
              nextHopProtocol: entry.nextHopProtocol || null,
              responseStatus: finiteInteger(entry.responseStatus),
              urlScheme: parts.scheme,
              urlHost: parts.host
            };
          });
          return JSON.stringify({
            url: location.href || null,
            title: document.title || null,
            entryCount: entries.length,
            returnedCount: resultEntries.length,
            truncated: entries.length > resultEntries.length,
            entries: resultEntries
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
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a network timing result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools network timing result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserNetworkPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools network timing result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func readBrowserDOMSnapshot(
        from webSocketURL: URL,
        maxElements: Int,
        maxTextCharacters: Int
    ) throws -> BrowserDOMSnapshotPayload {
        let expression = """
        (() => {
          const maxElements = \(maxElements);
          const maxTextCharacters = \(maxTextCharacters);
          const ignoredTags = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE"]);
          const attrNames = [
            "id", "class", "name", "aria-label", "placeholder", "title", "href", "type",
            "aria-expanded", "aria-selected", "aria-checked", "aria-pressed", "aria-disabled",
            "aria-current", "aria-controls"
          ];
          const elements = [];
          const ids = new Map();
          const root = document.body || document.documentElement;
          const queue = root ? [{
            element: root,
            depth: 0,
            parentID: null,
            context: "document",
            framePath: "top",
            frameURL: location.href || null,
            frameAccessible: null,
            shadowPath: null
          }] : [];
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
          const isUniqueSelector = (selector, rootNode = document) => {
            try {
              return rootNode.querySelectorAll(selector).length === 1;
            } catch {
              return false;
            }
          };
          const selectorFor = (element) => {
            const rootNode = typeof element.getRootNode === "function" ? element.getRootNode() : document;
            const uniqueInRoot = (selector) => isUniqueSelector(selector, rootNode);
            const tag = element.tagName.toLowerCase();
            if (element.id) {
              const candidate = `#${cssEscape(element.id)}`;
              if (uniqueInRoot(candidate)) return candidate;
            }

            for (const name of ["name", "aria-label", "placeholder", "title", "href", "aria-controls", "aria-current"]) {
              const value = element.getAttribute(name);
              if (!value) continue;
              const candidate = `${tag}[${name}="${cssString(value)}"]`;
              if (uniqueInRoot(candidate)) return candidate;
            }

            const parts = [];
            let current = element;
            while (current && current.nodeType === Node.ELEMENT_NODE && current !== rootNode.documentElement) {
              let part = current.tagName.toLowerCase();
              if (current.id) {
                parts.unshift(`#${cssEscape(current.id)}`);
                const candidate = parts.join(" > ");
                if (uniqueInRoot(candidate)) return candidate;
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
              if (uniqueInRoot(candidate)) return candidate;
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
            const {
              element,
              depth,
              parentID,
              context,
              framePath,
              frameURL,
              frameAccessible,
              shadowPath
            } = queue.shift();
            if (!element.tagName || ignoredTags.has(element.tagName)) continue;

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
            const tagName = element.tagName.toLowerCase();
            let elementFrameURL = context === "iframe" ? frameURL : null;
            let elementFrameAccessible = frameAccessible;
            if (tagName === "iframe") {
              elementFrameURL = element.src || element.getAttribute("src") || null;
              try {
                elementFrameAccessible = Boolean(element.contentDocument && (element.contentDocument.body || element.contentDocument.documentElement));
              } catch {
                elementFrameAccessible = false;
              }
            }
            elements.push({
              id,
              parentID,
              depth,
              selector: selectorFor(element),
              context,
              framePath,
              frameURL: elementFrameURL,
              frameAccessible: elementFrameAccessible,
              shadowPath,
              tagName,
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
              queue.push({
                element: child,
                depth: depth + 1,
                parentID: id,
                context,
                framePath,
                frameURL,
                frameAccessible,
                shadowPath
              });
            }

            if (element.shadowRoot) {
              const hostSelector = selectorFor(element);
              const nextShadowPath = shadowPath ? `${shadowPath} > ${hostSelector}` : hostSelector;
              for (const child of element.shadowRoot.children) {
                queue.push({
                  element: child,
                  depth: depth + 1,
                  parentID: id,
                  context: "shadow-root",
                  framePath,
                  frameURL,
                  frameAccessible,
                  shadowPath: nextShadowPath
                });
              }
            }

            if (tagName === "iframe") {
              try {
                const frameDocument = element.contentDocument;
                const frameRoot = frameDocument ? (frameDocument.body || frameDocument.documentElement) : null;
                if (frameRoot) {
                  const nextFramePath = `${framePath} > ${selectorFor(element)}`;
                  const nextFrameURL = element.contentWindow?.location?.href || element.src || null;
                  queue.push({
                    element: frameRoot,
                    depth: depth + 1,
                    parentID: id,
                    context: "iframe",
                    framePath: nextFramePath,
                    frameURL: nextFrameURL,
                    frameAccessible: true,
                    shadowPath: null
                  });
                }
              } catch {
                // Cross-origin frames are represented by their iframe element metadata.
              }
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

    func captureBrowserScreenshot(
        format: String,
        quality: Int?,
        fromSurface: Bool,
        at webSocketURL: URL
    ) throws -> Data {
        var params: [String: Any] = [
            "format": format,
            "fromSurface": fromSurface
        ]
        if format == "jpeg", let quality {
            params["quality"] = min(100, max(0, quality))
        }
        let response = try sendCDPCommand(
            method: "Page.captureScreenshot",
            params: params,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot failed with \(error.code): \(error.message)")
        }
        guard let data = response.result?.data else {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot response did not include screenshot data")
        }
        guard let bytes = Data(base64Encoded: data) else {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot returned invalid base64 data")
        }
        return bytes
    }

    func fillBrowserFormField(
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

    func selectBrowserOption(
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

    func setBrowserCheckedState(
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

    func inspectBrowserCheckedState(
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

    func inspectBrowserValue(
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

    func inspectBrowserElementText(
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

    func dispatchBrowserKey(
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

    func focusBrowserElement(
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

    func clickBrowserElement(
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

    func inspectBrowserSelector(
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

    func inspectBrowserCount(
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

    func inspectBrowserEnabledState(
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

    func inspectBrowserFocusState(
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

    func inspectBrowserAttribute(
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

    func inspectBrowserReadyState(
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

    func navigateBrowserPage(
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

    func waitForBrowserURL(
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

    func waitForBrowserSelector(
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

    func waitForBrowserCount(
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

    func waitForBrowserReady(
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

    func waitForBrowserTitle(
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

    func waitForBrowserChecked(
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

    func waitForBrowserEnabled(
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

    func waitForBrowserFocus(
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

    func waitForBrowserAttribute(
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

    func waitForBrowserValue(
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

    func waitForBrowserText(
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

    func waitForBrowserElementText(
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

    func browserURL(_ currentURL: String?, matches expectedURL: String, mode: String) -> Bool {
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

    func browserText(_ currentText: String?, matches expectedText: String, mode: String) -> Bool {
        stringValue(currentText, matches: expectedText, mode: mode)
    }

    func stringValue(_ currentValue: String?, matches expectedValue: String, mode: String) -> Bool {
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

    func browserTitle(_ currentTitle: String?, matches expectedTitle: String, mode: String) -> Bool {
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

    func browserTextMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser text match mode '\(rawMode)'. Use exact or contains.")
        }
    }

    func browserTitleMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser title match mode '\(rawMode)'. Use exact or contains.")
        }
    }

    func browserURLMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "prefix", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser URL match mode '\(rawMode)'. Use exact, prefix, or contains.")
        }
    }

    func browserSelectorWaitState(_ rawState: String) throws -> String {
        switch rawState {
        case "attached", "visible", "hidden", "detached":
            return rawState
        default:
            throw CommandError(description: "unsupported browser selector wait state '\(rawState)'. Use attached, visible, hidden, or detached.")
        }
    }

    func browserSelectorCountValue(_ rawCount: String) throws -> Int {
        guard let count = Int(rawCount), count >= 0 else {
            throw CommandError(description: "unsupported browser selector count '\(rawCount)'. Use a non-negative integer.")
        }
        return count
    }

    func browserCountMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "at-least", "at-most":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser count match mode '\(rawMode)'. Use exact, at-least, or at-most.")
        }
    }

    func browserScreenshotFormat(_ rawFormat: String) throws -> String {
        let format = rawFormat.lowercased()
        switch format {
        case "png", "jpeg":
            return format
        case "jpg":
            return "jpeg"
        default:
            throw CommandError(description: "browser screenshot format must be png or jpeg")
        }
    }

    func browserReadyState(_ rawState: String) throws -> String {
        switch rawState {
        case "loading", "interactive", "complete":
            return rawState
        default:
            throw CommandError(description: "unsupported browser ready state '\(rawState)'. Use loading, interactive, or complete.")
        }
    }

    func browserCheckedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser checked value '\(rawValue)'. Use true or false.")
        }
    }

    func browserEnabledValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser enabled value '\(rawValue)'. Use true or false.")
        }
    }

    func browserFocusedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser focused value '\(rawValue)'. Use true or false.")
        }
    }

    func browserKeyDefinition(for rawKey: String) throws -> BrowserKeyDefinition {
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

    func browserFunctionKeyDefinition(for rawKey: String) -> BrowserKeyDefinition? {
        let upper = rawKey.uppercased()
        guard upper.range(of: #"^F([1-9]|1[0-2])$"#, options: .regularExpression) != nil,
              let number = Int(upper.dropFirst()) else {
            return nil
        }
        return BrowserKeyDefinition(key: upper, code: upper, windowsVirtualKeyCode: 111 + number, text: nil)
    }

    func browserModifierSet(_ rawModifiers: String?) throws -> [String] {
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

    func browserModifierMask(_ rawModifiers: String) throws -> Int {
        browserModifierMask(for: try browserModifierSet(rawModifiers))
    }

    func browserModifierMask(for modifiers: [String]) -> Int {
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

    func validatedBrowserSelector(_ rawSelector: String) throws -> String {
        guard !rawSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommandError(description: "browser selector must not be empty")
        }
        return rawSelector
    }

    func validatedBrowserNavigationURL(_ rawURL: String) throws -> String {
        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            throw CommandError(description: "browser navigation URL must be an absolute http or https URL")
        }
        return url.absoluteString
    }

    func validatedBrowserExpectedURL(_ rawURL: String) throws -> String {
        guard !rawURL.isEmpty else {
            throw CommandError(description: "browser expected URL must not be empty")
        }
        if rawURL.contains("://") {
            return try validatedBrowserNavigationURL(rawURL)
        }
        return rawURL
    }

    func validatedBrowserExpectedText(_ rawText: String) throws -> String {
        guard !rawText.isEmpty else {
            throw CommandError(description: "browser expected text must not be empty")
        }
        return rawText
    }

    func validatedBrowserAttributeName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else {
            throw CommandError(description: "browser attribute name must not be empty")
        }
        guard name.range(of: #"^[a-z_:][a-z0-9_:.:-]*$"#, options: .regularExpression) != nil else {
            throw CommandError(description: "browser attribute name '\(rawName)' is not supported")
        }
        return name
    }

    func validatedBrowserExpectedTitle(_ rawTitle: String) throws -> String {
        guard !rawTitle.isEmpty else {
            throw CommandError(description: "browser expected title must not be empty")
        }
        return rawTitle
    }

    func validatedBrowserSelectOption(_ rawOption: String, optionName: String) throws -> String {
        guard !rawOption.isEmpty else {
            throw CommandError(description: "browser select \(optionName) must not be empty")
        }
        return rawOption
    }

    func evaluateCDPRuntimeExpression(
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

    func sendCDPCommand(
        method: String,
        params: [String: Any],
        at webSocketURL: URL,
        timeout: TimeInterval
    ) throws -> CDPCommandResponse {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try JSONDecoder().decode(CDPCommandResponse.self, from: data)
        }

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

    func browserEndpoint() throws -> URL {
        let rawEndpoint = option("--endpoint") ?? "http://127.0.0.1:9222"
        if let url = URL(string: rawEndpoint), url.scheme != nil {
            guard ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
                throw CommandError(description: "unsupported browser endpoint scheme '\(url.scheme ?? "")'. Use http, https, or file.")
            }
            return url
        }

        return URL(fileURLWithPath: expandedPath(rawEndpoint)).standardizedFileURL
    }

    func browserListURL(for endpoint: URL) -> URL {
        if endpoint.path.hasSuffix("/json/list") {
            return endpoint
        }
        return endpoint.appendingPathComponent("json/list")
    }

    func readURLData(from url: URL, timeoutMilliseconds: Int) throws -> Data {
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

    func fileChecksum(
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

    func fileText(
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

    func fileLines(
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

    func fileJSON(
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

    func filePropertyList(
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

    func jsonValue(at pointer: String, in root: Any) throws -> (found: Bool, value: Any?) {
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

    func structuredValue(at pointer: String, in root: Any) throws -> (found: Bool, value: Any?) {
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

    func boundedJSONNode(
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

    func boundedPropertyListNode(
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

    func boundedPropertyListDictionaryNode(
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

    func propertyListFormatName(_ format: PropertyListSerialization.PropertyListFormat) -> String {
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

    func compareFiles(
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

    func fileActionRisk(for action: String) -> String {
        switch action {
        case "filesystem.stat", "filesystem.list", "filesystem.search", "filesystem.wait", "filesystem.watch", "filesystem.checksum", "filesystem.compare", "filesystem.plan":
            return "low"
        case "filesystem.readText", "filesystem.tailText", "filesystem.readLines", "filesystem.readJSON", "filesystem.readPropertyList", "filesystem.writeText", "filesystem.appendText", "filesystem.duplicate", "filesystem.move", "filesystem.createDirectory", "filesystem.rollbackMove", "filesystem.rollbackTextWrite":
            return "medium"
        default:
            return "unknown"
        }
    }

    func filesystemState(rootURL: URL, maxDepth: Int, limit: Int, includeHidden: Bool) throws -> FilesystemState {
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

    func filesystemSearchResult(
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

    struct FileSearchStats {
        var scannedFiles = 0
        var skippedUnreadable = 0
        var skippedBinary = 0
        var skippedTooLarge = 0
    }

    func collectSearchMatches(
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

    func shouldSearch(_ record: FileRecord, includeHidden: Bool) -> Bool {
        includeHidden || !record.hidden
    }

    func searchMatch(
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

    func contentLineMatches(
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

    func contains(_ needle: String, in haystack: String, caseSensitive: Bool) -> Bool {
        if caseSensitive {
            return haystack.contains(needle)
        }
        return haystack.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    func snippet(for line: String, query: String, caseSensitive: Bool, maxCharacters: Int) -> String {
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

    func collectFileRecords(
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
    func fileRecord(for url: URL) throws -> FileRecord {
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

    func refreshedFileRecord(for url: URL) throws -> FileRecord {
        var refreshedURL = url
        refreshedURL.removeAllCachedResourceValues()
        return try fileRecord(for: refreshedURL)
    }

    func fileByteSize(at url: URL) throws -> Int {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? NSNumber {
            return size.intValue
        }
        throw CommandError(description: "file size is unavailable at \(url.path)")
    }

    func fileResourceKeys() -> Set<URLResourceKey> {
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

    func fileKind(_ values: URLResourceValues) -> String {
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

    func fileID(values: URLResourceValues, url: URL) -> String {
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

    func hexString(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    func fileActions(kind: String, readable: Bool, writable: Bool) -> [FileAction] {
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
            actions.append(FileAction(name: "filesystem.rollbackTextWrite", risk: "medium", mutates: true))
        }

        if kind == "regularFile", writable {
            actions.append(FileAction(name: "filesystem.writeText", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.appendText", risk: "medium", mutates: true))
            actions.append(FileAction(name: "filesystem.rollbackTextWrite", risk: "medium", mutates: true))
        }

        return actions
    }

}
