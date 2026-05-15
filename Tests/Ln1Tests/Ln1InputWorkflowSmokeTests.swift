import Foundation
import XCTest

final class Ln1InputWorkflowSmokeTests: Ln1TestCase {
    func testWorkflowPreflightTypeInputReturnsGuardedInputCommand() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-type-input-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "type-input",
            "--text", "hello",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "type-input")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "input", "type",
            "--text", "hello",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowResumeSuggestsInputUndoAfterTypeInput() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-type-input-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "type-input-transcript",
            "operation": "type-input",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "input", "type",
                    "--text", "hello",
                    "--allow-risk", "medium",
                    "--reason", "type test",
                    "--audit-log", auditLog.path
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "input.typeText",
                    "risk": "medium",
                    "auditLogPath": auditLog.path,
                    "verification": [
                        "ok": true,
                        "code": "text_posted",
                        "message": "text input events were posted"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "type-input",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "type-input")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "input", "undo",
            "--allow-risk", "medium",
            "--reason", "Describe intent",
            "--audit-log", auditLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("input undo") == true)
    }
}
