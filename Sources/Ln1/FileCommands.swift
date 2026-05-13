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
