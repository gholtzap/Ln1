import AppKit
import Foundation
import XCTest

final class Ln1AuditClipboardSmokeTests: Ln1TestCase {
    func testAuditCommandReturnsEmptyEntriesForMissingLog() throws {
        let missingLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-missing-\(UUID().uuidString).jsonl")
        let result = try runLn1([
            "audit",
            "--audit-log", missingLog.path,
            "--limit", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        XCTAssertEqual(object["path"] as? String, missingLog.path)
        XCTAssertEqual((object["entries"] as? [Any])?.count, 0)
    }

    func testAuditCommandFiltersByCommandAndOutcomeCodeBeforeLimit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-audit-filter-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "copy".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try runLn1([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", directory.appendingPathComponent("copy.txt").path,
            "--reason", "policy duplicate",
            "--audit-log", auditLog.path
        ])
        _ = try runLn1([
            "files",
            "mkdir",
            "--path", created.path,
            "--allow-risk", "medium",
            "--reason", "allowed mkdir",
            "--audit-log", auditLog.path
        ])

        let commandFiltered = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.mkdir",
            "--limit", "1"
        ])

        XCTAssertEqual(commandFiltered.status, 0, commandFiltered.stderr)
        let commandObject = try decodeJSONObject(commandFiltered.stdout)
        let commandEntries = try XCTUnwrap(commandObject["entries"] as? [[String: Any]])
        let commandEntry = try XCTUnwrap(commandEntries.first)
        let commandOutcome = try XCTUnwrap(commandEntry["outcome"] as? [String: Any])

        XCTAssertEqual(commandObject["command"] as? String, "files.mkdir")
        XCTAssertEqual(commandObject["limit"] as? Int, 1)
        XCTAssertEqual(commandEntries.count, 1)
        XCTAssertEqual(commandEntry["command"] as? String, "files.mkdir")
        XCTAssertEqual(commandOutcome["code"] as? String, "created_directory")

        let codeFiltered = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--code", "policy_denied",
            "--limit", "5"
        ])

        XCTAssertEqual(codeFiltered.status, 0, codeFiltered.stderr)
        let codeObject = try decodeJSONObject(codeFiltered.stdout)
        let codeEntries = try XCTUnwrap(codeObject["entries"] as? [[String: Any]])
        let codeEntry = try XCTUnwrap(codeEntries.first)
        let codeOutcome = try XCTUnwrap(codeEntry["outcome"] as? [String: Any])

        XCTAssertEqual(codeObject["code"] as? String, "policy_denied")
        XCTAssertEqual(codeEntries.count, 1)
        XCTAssertEqual(codeEntry["command"] as? String, "files.duplicate")
        XCTAssertEqual(codeOutcome["code"] as? String, "policy_denied")
    }

    func testAuditCommandFiltersByIDBeforeLimit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-audit-id-filter-\(UUID().uuidString)")
        let firstCreated = directory.appendingPathComponent("first")
        let secondCreated = directory.appendingPathComponent("second")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let first = try runLn1([
            "files",
            "mkdir",
            "--path", firstCreated.path,
            "--allow-risk", "medium",
            "--reason", "first allowed mkdir",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(first.status, 0, first.stderr)
        let firstObject = try decodeJSONObject(first.stdout)
        let firstAuditID = try XCTUnwrap(firstObject["auditID"] as? String)

        let second = try runLn1([
            "files",
            "mkdir",
            "--path", secondCreated.path,
            "--allow-risk", "medium",
            "--reason", "second allowed mkdir",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(second.status, 0, second.stderr)

        let idFiltered = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--id", firstAuditID,
            "--limit", "5"
        ])

        XCTAssertEqual(idFiltered.status, 0, idFiltered.stderr)
        let object = try decodeJSONObject(idFiltered.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(object["id"] as? String, firstAuditID)
        XCTAssertEqual(object["limit"] as? Int, 5)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entry["id"] as? String, firstAuditID)
        XCTAssertEqual(entry["command"] as? String, "files.mkdir")
        XCTAssertEqual(outcome["code"] as? String, "created_directory")

        let missing = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--id", "missing-audit-id",
            "--limit", "5"
        ])

        XCTAssertEqual(missing.status, 0, missing.stderr)
        let missingObject = try decodeJSONObject(missing.stdout)
        XCTAssertEqual(missingObject["id"] as? String, "missing-audit-id")
        XCTAssertEqual((missingObject["entries"] as? [Any])?.count, 0)
    }

    func testClipboardStateReturnsMetadataWithoutTextContents() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer { pasteboard.clearContents() }

        let result = try runLn1([
            "clipboard",
            "state",
            "--pasteboard", pasteboardName
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let actions = try XCTUnwrap(object["actions"] as? [[String: Any]])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["hasString"] as? Bool, true)
        XCTAssertEqual(object["stringLength"] as? Int, 15)
        XCTAssertEqual(object["stringDigest"] as? String, "65b2b576750477c2424fc19794e6c3c5ac6821e29e8464294aed6aa8485304c2")
        XCTAssertNil(object["text"])
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.state" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.wait" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.readText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.writeText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.rollbackText" })
    }

    func testClipboardWaitReturnsMetadataWithoutTextContents() throws {
        let pasteboardName = "Ln1-test-wait-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)

        let before = try runLn1([
            "clipboard",
            "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertEqual(before.status, 0, before.stderr)
        let beforeObject = try decodeJSONObject(before.stdout)
        let beforeChangeCount = try XCTUnwrap(beforeObject["changeCount"] as? Int)

        let write = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "new clipboard",
            "--allow-risk", "medium",
            "--reason", "prepare clipboard wait test"
        ])
        XCTAssertEqual(write.status, 0, write.stderr)
        let writeObject = try decodeJSONObject(write.stdout)
        let writtenDigest = try XCTUnwrap(writeObject["writtenDigest"] as? String)

        let wait = try runLn1([
            "clipboard",
            "wait",
            "--pasteboard", pasteboardName,
            "--changed-from", String(beforeChangeCount),
            "--has-string", "true",
            "--string-digest", writtenDigest.uppercased(),
            "--timeout-ms", "0",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(wait.status, 0, wait.stderr)
        let object = try decodeJSONObject(wait.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [String: Any])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "clipboard_matched")
        XCTAssertEqual(verification["changedFrom"] as? Int, beforeChangeCount)
        XCTAssertEqual(verification["expectedHasString"] as? Bool, true)
        XCTAssertEqual(verification["expectedStringDigest"] as? String, writtenDigest)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertEqual(current["hasString"] as? Bool, true)
        XCTAssertEqual(current["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringDigest"] as? String, writtenDigest)
        XCTAssertNil(object["text"])
        XCTAssertNil(verification["text"])
        XCTAssertNil(current["text"])
    }

    func testClipboardReadTextRequiresMediumRiskAndAuditsRead() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-clipboard-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runLn1([
            "clipboard",
            "read-text",
            "--pasteboard", pasteboardName,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "clipboard",
            "read-text",
            "--pasteboard", pasteboardName,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--audit-log", auditLog.path,
            "--reason", "read test clipboard"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["hasString"] as? Bool, true)
        XCTAssertEqual(object["text"] as? String, "hello")
        XCTAssertEqual(object["stringLength"] as? Int, 15)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxCharacters"] as? Int, 5)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.read-text",
            "--code", "read_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let clipboard = try XCTUnwrap(entry["clipboard"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "clipboard.read-text")
        XCTAssertEqual(entry["action"] as? String, "clipboard.readText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "read test clipboard")
        XCTAssertEqual(clipboard["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(clipboard["stringLength"] as? Int, 15)
        XCTAssertNil(clipboard["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_text")
    }

    func testClipboardWriteTextRequiresMediumRiskVerifiesAndAuditsWithoutText() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-clipboard-write-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "blocked clipboard",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.write-text",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])
        let deniedBefore = try XCTUnwrap(deniedEntry["clipboardBefore"] as? [String: Any])
        let deniedAfter = try XCTUnwrap(deniedEntry["clipboardAfter"] as? [String: Any])
        let deniedOutcome = try XCTUnwrap(deniedEntry["outcome"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "clipboard.writeText")
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)
        XCTAssertEqual(deniedAfter["stringDigest"] as? String, deniedBefore["stringDigest"] as? String)
        XCTAssertEqual(deniedOutcome["code"] as? String, "policy_denied")

        let result = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "new clipboard",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "write test clipboard"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(pasteboard.string(forType: .string), "new clipboard")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["writtenLength"] as? Int, 13)
        XCTAssertEqual(previous["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringDigest"] as? String, object["writtenDigest"] as? String)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_matched")
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.write-text",
            "--code", "wrote_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let before = try XCTUnwrap(entry["clipboardBefore"] as? [String: Any])
        let after = try XCTUnwrap(entry["clipboardAfter"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "clipboard.write-text")
        XCTAssertEqual(entry["action"] as? String, "clipboard.writeText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "write test clipboard")
        XCTAssertEqual(before["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(after["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(after["stringLength"] as? Int, 13)
        XCTAssertNil(after["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "wrote_text")
    }

    func testClipboardRollbackRestoresAuditedWriteFromSnapshot() throws {
        let pasteboardName = "Ln1-test-rollback-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-clipboard-rollback-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let snapshot = directory.appendingPathComponent("rollback.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: directory)
        }

        let write = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "new clipboard",
            "--rollback-snapshot", snapshot.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "write before rollback"
        ])

        XCTAssertEqual(write.status, 0, write.stderr)
        XCTAssertEqual(pasteboard.string(forType: .string), "new clipboard")
        let writeObject = try decodeJSONObject(write.stdout)
        let writeAuditID = try XCTUnwrap(writeObject["auditID"] as? String)
        XCTAssertEqual(writeObject["rollbackSnapshotPath"] as? String, snapshot.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: snapshot.path))

        let deniedRollback = try runLn1([
            "clipboard",
            "rollback",
            "--audit-id", writeAuditID,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(deniedRollback.status, 0)
        XCTAssertEqual(pasteboard.string(forType: .string), "new clipboard")

        let rollback = try runLn1([
            "clipboard",
            "rollback",
            "--audit-id", writeAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "restore clipboard"
        ])

        XCTAssertEqual(rollback.status, 0, rollback.stderr)
        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")
        let object = try decodeJSONObject(rollback.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "clipboard.rollbackText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["rollbackOfAuditID"] as? String, writeAuditID)
        XCTAssertEqual(previous["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringDigest"] as? String, "0312018b065d8cb2e51c979661397ec81de42a3c324db8f3642e82a8e61d9f4f")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "clipboard_rolled_back")
        XCTAssertNil(object["text"])
        XCTAssertNil(current["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.rollback",
            "--code", "rolled_back_clipboard",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let after = try XCTUnwrap(entry["clipboardAfter"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["action"] as? String, "clipboard.rollbackText")
        XCTAssertEqual(entry["rollbackOfAuditID"] as? String, writeAuditID)
        XCTAssertEqual(entry["clipboardRollbackSnapshotPath"] as? String, snapshot.path)
        XCTAssertEqual(after["stringDigest"] as? String, current["stringDigest"] as? String)
        XCTAssertNil(after["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "rolled_back_clipboard")
    }

    func testRejectedPerformWritesAuditRecord() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-audit-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "perform",
            "--audit-log", auditLog.path,
            "--reason", "verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "perform")
        XCTAssertEqual(entry["reason"] as? String, "verification")
        XCTAssertEqual(entry["action"] as? String, "AXPress")
        XCTAssertEqual(entry["risk"] as? String, "low")
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "rejected")
    }

    func testPerformPolicyDenialIsAuditedBeforeAccessibilityTrust() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "perform",
            "--audit-log", auditLog.path,
            "--element", "w0",
            "--action", "AXCustomAction",
            "--allow-risk", "low",
            "--reason", "policy verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "perform")
        XCTAssertEqual(entry["reason"] as? String, "policy verification")
        XCTAssertEqual(entry["elementID"] as? String, "w0")
        XCTAssertEqual(entry["action"] as? String, "AXCustomAction")
        XCTAssertEqual(entry["risk"] as? String, "unknown")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "unknown")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testSetValuePolicyDenialIsAuditedBeforeAccessibilityTrust() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-set-value-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "set-value",
            "--audit-log", auditLog.path,
            "--element", "w0",
            "--value", "secret",
            "--reason", "policy verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "set-value")
        XCTAssertEqual(entry["reason"] as? String, "policy verification")
        XCTAssertEqual(entry["elementID"] as? String, "w0")
        XCTAssertEqual(entry["action"] as? String, "accessibility.setValue")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertNil(entry["value"] as? String)
        XCTAssertNil(entry["valueLength"] as? Int)
        XCTAssertNil(entry["valueDigest"] as? String)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testOpenPolicyDenialWritesAuditWithoutOpeningTarget() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-open-denied-\(UUID().uuidString)")
        let target = directory.appendingPathComponent("artifact.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "artifact".write(to: target, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let denied = try runLn1([
            "open",
            "--path", target.path,
            "--allow-risk", "low",
            "--reason", "policy verification",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(denied.status, 0)
        XCTAssertTrue(denied.stderr.contains("policy denied medium action"), denied.stderr)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "open"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let targetSummary = try XCTUnwrap(entry["workspaceOpenTarget"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "open")
        XCTAssertEqual(entry["reason"] as? String, "policy verification")
        XCTAssertEqual(entry["action"] as? String, "workspace.open")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(targetSummary["kind"] as? String, "file")
        XCTAssertEqual(targetSummary["path"] as? String, target.path)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

}
