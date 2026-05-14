import Foundation
import XCTest

final class Ln1InputUndoSmokeTests: Ln1TestCase {
    func testInputUndoDryRunValidatesAndAuditsCompensatingShortcut() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-input-undo-dry-run-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "input",
            "undo",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--reason", "undo last text entry",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "input.undo")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["key"] as? String, "z")
        XCTAssertEqual(object["keyCode"] as? Int, 6)
        XCTAssertEqual(object["modifiers"] as? [String], ["meta"])
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

        XCTAssertEqual(entry["command"] as? String, "input.undo")
        XCTAssertEqual(entry["action"] as? String, "input.undo")
        XCTAssertEqual(entry["reason"] as? String, "undo last text entry")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "dry_run")
    }

    func testPolicyIncludesInputUndoAsMutatingMediumRiskAction() throws {
        let result = try runLn1(["policy"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let actions = try XCTUnwrap(object["actions"] as? [[String: Any]])
        let action = try XCTUnwrap(actions.first { $0["name"] as? String == "input.undo" })

        XCTAssertEqual(action["domain"] as? String, "input")
        XCTAssertEqual(action["risk"] as? String, "medium")
        XCTAssertEqual(action["mutates"] as? Bool, true)
    }
}
