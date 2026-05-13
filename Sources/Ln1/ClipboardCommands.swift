import AppKit
import CryptoKit
import Foundation

extension Ln1CLI {
    func clipboard() throws {
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
        case "rollback":
            let auditRecordID = try requiredOption("--audit-id")
            try writeJSON(rollbackClipboardText(auditRecordID: auditRecordID))
        default:
            throw CommandError(description: "unknown clipboard mode '\(mode)'")
        }
    }

    func targetPasteboard() -> NSPasteboard {
        guard let name = option("--pasteboard"), name != "general" else {
            return .general
        }
        return NSPasteboard(name: NSPasteboard.Name(rawValue: name))
    }

    func clipboardState(for pasteboard: NSPasteboard) -> ClipboardState {
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
                ClipboardAction(name: "clipboard.writeText", risk: "medium", mutates: true),
                ClipboardAction(name: "clipboard.rollbackText", risk: "medium", mutates: true)
            ]
        )
    }

    func clipboardWait(for pasteboard: NSPasteboard) throws -> ClipboardWaitResult {
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

    func clipboardText(for pasteboard: NSPasteboard, maxCharacters: Int) throws -> ClipboardTextResult {
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

    func writeClipboardText(_ text: String, to pasteboard: NSPasteboard) throws -> ClipboardWriteResult {
        let action = "clipboard.writeText"
        let risk = clipboardActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let beforeString = pasteboard.string(forType: .string)
        let before = clipboardAuditSummary(for: pasteboard, string: beforeString)
        let writtenDigest = sha256Digest(text)
        let rollbackSnapshotURL = option("--rollback-snapshot")
            .map { URL(fileURLWithPath: expandedPath($0)).standardizedFileURL }
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
                clipboardRollbackSnapshotPath: rollbackSnapshotURL?.path,
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

            if let rollbackSnapshotURL {
                try writeClipboardRollbackSnapshot(
                    auditID: auditID,
                    pasteboard: pasteboard,
                    previousText: beforeString,
                    to: rollbackSnapshotURL
                )
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
                rollbackSnapshotPath: rollbackSnapshotURL?.path,
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

    func rollbackClipboardText(auditRecordID: String) throws -> ClipboardRollbackResult {
        let action = "clipboard.rollbackText"
        let risk = clipboardActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        var pasteboard: NSPasteboard?
        var before: ClipboardAuditSummary?
        var after: ClipboardAuditSummary?
        var verification: FileOperationVerification?
        var snapshotPath: String?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "clipboard.rollback",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                clipboard: after ?? before,
                clipboardBefore: before,
                clipboardAfter: after,
                clipboardRollbackSnapshotPath: snapshotPath,
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

            guard originalRecord.command == "clipboard.write-text",
                  originalRecord.outcome.ok,
                  originalRecord.outcome.code == "wrote_text" else {
                let message = "audit record \(auditRecordID) is not a successful clipboard.write-text record"
                try writeAudit(ok: false, code: "unsupported_rollback_record", message: message)
                throw CommandError(description: message)
            }

            guard let originalBefore = originalRecord.clipboardBefore,
                  let originalAfter = originalRecord.clipboardAfter else {
                let message = "audit record \(auditRecordID) does not contain clipboard before/after metadata"
                try writeAudit(ok: false, code: "rollback_metadata_missing", message: message)
                throw CommandError(description: message)
            }

            guard let originalSnapshotPath = originalRecord.clipboardRollbackSnapshotPath else {
                let message = "audit record \(auditRecordID) does not include a rollback snapshot path"
                try writeAudit(ok: false, code: "rollback_snapshot_missing", message: message)
                throw CommandError(description: message)
            }
            snapshotPath = originalSnapshotPath

            let snapshotURL = URL(fileURLWithPath: expandedPath(originalSnapshotPath)).standardizedFileURL
            let snapshot = try readClipboardRollbackSnapshot(from: snapshotURL)
            guard snapshot.auditID == auditRecordID else {
                let message = "clipboard rollback snapshot does not match audit record \(auditRecordID)"
                try writeAudit(ok: false, code: "rollback_snapshot_mismatch", message: message)
                throw CommandError(description: message)
            }

            pasteboard = clipboardPasteboard(named: option("--pasteboard") ?? snapshot.pasteboard)
            let currentString = pasteboard?.string(forType: .string)
            before = pasteboard.map { clipboardAuditSummary(for: $0, string: currentString) }

            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            guard clipboardSummary(before, matches: originalAfter) else {
                let message = "current clipboard metadata does not match audited write result"
                try writeAudit(ok: false, code: "rollback_current_mismatch", message: message)
                throw CommandError(description: message)
            }

            let restoredText = try clipboardRollbackText(from: snapshot)
            pasteboard?.clearContents()
            if let restoredText, pasteboard?.setString(restoredText, forType: .string) != true {
                let message = "failed to restore plain text to \(pasteboard?.name.rawValue ?? snapshot.pasteboard)"
                verification = FileOperationVerification(ok: false, code: "restore_failed", message: message)
                after = pasteboard.map { clipboardAuditSummary(for: $0, string: $0.string(forType: .string)) }
                try writeAudit(ok: false, code: "restore_failed", message: message)
                throw CommandError(description: message)
            }

            after = pasteboard.map { clipboardAuditSummary(for: $0, string: $0.string(forType: .string)) }
            verification = verifyClipboardSummary(after, matches: originalBefore)
            guard verification?.ok == true else {
                let message = verification?.message ?? "clipboard rollback verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Rolled back clipboard write \(auditRecordID)."
            try writeAudit(ok: true, code: "rolled_back_clipboard", message: message)

            return ClipboardRollbackResult(
                ok: true,
                action: action,
                risk: risk,
                pasteboard: after?.pasteboard ?? snapshot.pasteboard,
                rollbackOfAuditID: auditRecordID,
                previous: before!,
                current: after!,
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

    func writeClipboardRollbackSnapshot(
        auditID: String,
        pasteboard: NSPasteboard,
        previousText: String?,
        to url: URL
    ) throws {
        let textData = previousText?.data(using: .utf8)
        let snapshot = ClipboardRollbackSnapshot(
            version: 1,
            auditID: auditID,
            savedAt: ISO8601DateFormatter().string(from: Date()),
            pasteboard: pasteboard.name.rawValue,
            previousHadString: previousText != nil,
            previousTextLength: previousText?.count,
            previousTextDigest: previousText.map(sha256Digest),
            previousTextBase64: textData?.base64EncodedString()
        )
        let data = try JSONEncoder().encode(snapshot)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: Int16(0o600))], ofItemAtPath: url.path)
    }

    func readClipboardRollbackSnapshot(from url: URL) throws -> ClipboardRollbackSnapshot {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ClipboardRollbackSnapshot.self, from: data)
        } catch {
            throw CommandError(description: "could not read clipboard rollback snapshot at \(url.path): \(error.localizedDescription)")
        }
    }

    func clipboardRollbackText(from snapshot: ClipboardRollbackSnapshot) throws -> String? {
        guard snapshot.previousHadString else {
            return nil
        }
        guard let base64 = snapshot.previousTextBase64,
              let data = Data(base64Encoded: base64),
              let text = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "clipboard rollback snapshot does not contain valid UTF-8 text")
        }
        guard snapshot.previousTextLength == text.count,
              snapshot.previousTextDigest == sha256Digest(text) else {
            throw CommandError(description: "clipboard rollback snapshot text does not match its metadata")
        }
        return text
    }

    func clipboardPasteboard(named name: String) -> NSPasteboard {
        if name == "general" || name == NSPasteboard.general.name.rawValue {
            return .general
        }
        return NSPasteboard(name: NSPasteboard.Name(rawValue: name))
    }

    func verifyClipboardText(
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

    func verifyClipboardSummary(_ current: ClipboardAuditSummary?, matches expected: ClipboardAuditSummary) -> FileOperationVerification {
        guard clipboardSummary(current, matches: expected) else {
            return FileOperationVerification(
                ok: false,
                code: "clipboard_metadata_mismatch",
                message: "clipboard metadata does not match expected rollback state"
            )
        }
        return FileOperationVerification(
            ok: true,
            code: "clipboard_rolled_back",
            message: "clipboard metadata matches the audited previous state"
        )
    }

    func clipboardSummary(_ current: ClipboardAuditSummary?, matches expected: ClipboardAuditSummary) -> Bool {
        guard let current else {
            return false
        }
        return current.hasString == expected.hasString
            && current.stringLength == expected.stringLength
            && current.stringDigest == expected.stringDigest
    }

    func clipboardAuditSummary(for pasteboard: NSPasteboard, string: String?) -> ClipboardAuditSummary {
        ClipboardAuditSummary(
            pasteboard: pasteboard.name.rawValue,
            changeCount: pasteboard.changeCount,
            types: clipboardTypes(for: pasteboard),
            hasString: string != nil,
            stringLength: string?.count,
            stringDigest: string.map(sha256Digest)
        )
    }

    func clipboardTypes(for pasteboard: NSPasteboard) -> [String] {
        (pasteboard.types ?? []).map(\.rawValue).sorted()
    }

    func waitForClipboard(
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

    func clipboardSummary(
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

    func isSHA256HexDigest(_ value: String) -> Bool {
        value.range(of: #"^[0-9a-fA-F]{64}$"#, options: .regularExpression) != nil
    }

    func normalizedChecksumAlgorithm(_ algorithm: String) throws -> String {
        let normalizedAlgorithm = algorithm.lowercased()
        guard normalizedAlgorithm == "sha256" else {
            throw CommandError(description: "unsupported checksum algorithm '\(algorithm)'. Use sha256.")
        }
        return normalizedAlgorithm
    }

    func fileExpectedSizeBytes(_ rawValue: String) throws -> Int {
        guard let value = Int(rawValue), value >= 0 else {
            throw CommandError(description: "--size-bytes must be a non-negative integer")
        }
        return value
    }

    func fileMaxBytes(_ rawValue: String, optionName: String) throws -> Int {
        guard let value = Int(rawValue), value >= 0 else {
            throw CommandError(description: "\(optionName) must be a non-negative integer")
        }
        return value
    }

    func booleanOption(_ rawValue: String, optionName: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "1", "true", "yes", "y":
            return true
        case "0", "false", "no", "n":
            return false
        default:
            throw CommandError(description: "\(optionName) must be true or false")
        }
    }

    func sha256Digest(_ string: String) -> String {
        SHA256.hash(data: Data(string.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    func javascriptStringLiteral(_ string: String) throws -> String {
        let data = try JSONEncoder().encode(string)
        guard let literal = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode JavaScript string literal")
        }
        return literal
    }

    func appendAuditRecord(_ record: ActionAuditRecord, to url: URL) throws {
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

    func readAuditRecords(
        from url: URL,
        limit: Int,
        id: String? = nil,
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
                if let id, record.id != id {
                    return false
                }
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

    func taskMemoryEvent(
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

    func appendTaskMemoryEvent(_ event: TaskMemoryEvent, to url: URL) throws {
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

    func appendWorkflowTranscript(_ plan: WorkflowRunPlan, to url: URL) throws {
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

    func readWorkflowTranscriptEntries(
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

    func readWorkflowTranscriptDictionaries(
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

    func readTaskMemoryEvents(from url: URL) throws -> [TaskMemoryEvent] {
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

    func taskMemoryResult(taskID: String, from url: URL, limit: Int) throws -> TaskMemoryResult {
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

    func requireTaskExists(taskID: String, in url: URL) throws {
        let exists = try readTaskMemoryEvents(from: url).contains {
            $0.taskID == taskID && $0.kind == "task.started"
        }
        guard exists else {
            throw CommandError(description: "no task memory found with id \(taskID)")
        }
    }

    func taskMemoryKind(_ rawKind: String) throws -> String {
        switch rawKind {
        case "observation", "decision", "action", "verification", "note":
            return "task.\(rawKind)"
        case "task.observation", "task.decision", "task.action", "task.verification", "task.note":
            return rawKind
        default:
            throw CommandError(description: "unsupported task memory kind '\(rawKind)'. Use observation, decision, action, verification, or note.")
        }
    }

    func taskFinishStatus(_ status: String) throws -> String {
        switch status {
        case "completed", "blocked", "cancelled":
            return status
        default:
            throw CommandError(description: "unsupported task status '\(status)'. Use completed, blocked, or cancelled.")
        }
    }

    func taskMemorySensitivity(_ sensitivity: String) throws -> String {
        switch sensitivity {
        case "public", "private", "sensitive":
            return sensitivity
        default:
            throw CommandError(description: "unsupported task memory sensitivity '\(sensitivity)'. Use public, private, or sensitive.")
        }
    }

    func auditLogURL() throws -> URL {
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

    func taskMemoryURL() throws -> URL {
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

    func workflowLogURL() throws -> URL {
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

    func expandedPath(_ path: String) -> String {
        guard path == "~" || path.hasPrefix("~/") else {
            return path
        }

        let suffix = path.dropFirst(path == "~" ? 1 : 2)
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(String(suffix))
            .path
    }

    func riskLevel(for action: String) -> String {
        switch action {
        case kAXPressAction, kAXShowMenuAction:
            return "low"
        case kAXConfirmAction, kAXPickAction:
            return "medium"
        default:
            return "unknown"
        }
    }

    func accessibilityActionRisk(for action: String) -> String {
        switch action {
        case "accessibility.inspectMenu", "accessibility.inspectElement", "accessibility.waitElement":
            return "low"
        case "accessibility.setValue":
            return "medium"
        default:
            return riskLevel(for: action)
        }
    }

    func clipboardActionRisk(for action: String) -> String {
        switch action {
        case "clipboard.state", "clipboard.wait":
            return "low"
        case "clipboard.readText", "clipboard.writeText", "clipboard.rollbackText":
            return "medium"
        default:
            return "unknown"
        }
    }

}
