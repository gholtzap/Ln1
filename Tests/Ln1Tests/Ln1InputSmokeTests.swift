import Foundation
import XCTest

final class Ln1InputSmokeTests: Ln1TestCase {
    func testInputPointerReturnsGlobalPointerMetadata() throws {
        let result = try runLn1([
            "input",
            "pointer"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["action"] as? String, "input.pointer")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)

        if object["available"] as? Bool == true {
            let position = try XCTUnwrap(object["position"] as? [String: Any])
            XCTAssertNotNil(position["x"] as? Double)
            XCTAssertNotNil(position["y"] as? Double)
        }
    }

    func testInputMoveDryRunValidatesAndAuditsWithoutMovingPointer() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-move-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "move",
            "--x", "12",
            "--y", "34",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan pointer move",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let target = try XCTUnwrap(object["to"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.movePointer")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(target["x"] as? Double, 12)
        XCTAssertEqual(target["y"] as? Double, 34)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.move")
        XCTAssertEqual(entry["action"] as? String, "input.movePointer")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "plan pointer move")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputDragDryRunValidatesAndAuditsWithoutDraggingPointer() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-drag-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "drag",
            "--from-x", "10",
            "--from-y", "20",
            "--to-x", "30",
            "--to-y", "40",
            "--steps", "4",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan pointer drag",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let start = try XCTUnwrap(object["from"] as? [String: Any])
        let target = try XCTUnwrap(object["to"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.dragPointer")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["steps"] as? Int, 4)
        XCTAssertEqual(start["x"] as? Double, 10)
        XCTAssertEqual(start["y"] as? Double, 20)
        XCTAssertEqual(target["x"] as? Double, 30)
        XCTAssertEqual(target["y"] as? Double, 40)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.drag")
        XCTAssertEqual(entry["action"] as? String, "input.dragPointer")
        XCTAssertEqual(entry["reason"] as? String, "plan pointer drag")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputScrollDryRunValidatesAndAuditsWithoutScrolling() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-scroll-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "scroll",
            "--dx", "3",
            "--dy", "-12",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan scroll",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.scrollWheel")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["deltaX"] as? Int, 3)
        XCTAssertEqual(object["deltaY"] as? Int, -12)
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.scroll")
        XCTAssertEqual(entry["action"] as? String, "input.scrollWheel")
        XCTAssertEqual(entry["reason"] as? String, "plan scroll")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputKeyDryRunValidatesAndAuditsWithoutPostingKeyboardInput() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-key-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "key",
            "--key", "k",
            "--modifiers", "command,shift",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan key",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.pressKey")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["key"] as? String, "k")
        XCTAssertEqual(object["keyCode"] as? Int, 40)
        XCTAssertEqual(object["modifiers"] as? [String], ["meta", "shift"])
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.key")
        XCTAssertEqual(entry["action"] as? String, "input.pressKey")
        XCTAssertEqual(entry["reason"] as? String, "plan key")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testInputTypeDryRunAuditsMetadataWithoutTextContents() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-type-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "type",
            "--text", "hello",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "plan text",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.typeText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["textLength"] as? Int, 5)
        XCTAssertNotNil(object["textDigest"] as? String)
        XCTAssertNil(object["text"])
        XCTAssertEqual(verification["code"] as? String, "dry_run")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])
        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "input.type")
        XCTAssertEqual(entry["action"] as? String, "input.typeText")
        XCTAssertEqual(entry["reason"] as? String, "plan text")
        XCTAssertNil(entry["text"])
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }
}
