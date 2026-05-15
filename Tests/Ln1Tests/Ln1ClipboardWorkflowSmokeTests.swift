import Foundation
import XCTest

final class Ln1ClipboardWorkflowSmokeTests: Ln1TestCase {
    func testWorkflowResumeSuggestsClipboardReadAfterClipboardWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-clipboard-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-clipboard-transcript",
            "operation": "wait-clipboard",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "clipboard", "wait",
                    "--changed-from", "12",
                    "--has-string", "true",
                    "--pasteboard", "Ln1-test-pasteboard"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "pasteboard": "Ln1-test-pasteboard",
                    "verification": [
                        "ok": true,
                        "code": "clipboard_matched",
                        "matched": true,
                        "current": [
                            "pasteboard": "Ln1-test-pasteboard",
                            "changeCount": 13,
                            "hasString": true,
                            "stringLength": 42,
                            "stringDigest": String(repeating: "a", count: 64)
                        ]
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-clipboard",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-clipboard")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "read-clipboard",
            "--max-characters", "4096",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path,
            "--pasteboard", "Ln1-test-pasteboard"
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("dry-run bounded clipboard text reading") == true)
    }

    func testWorkflowResumeSuggestsClipboardReadAfterClipboardInspect() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-clipboard-inspect-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let pasteboardName = "Ln1-test-pasteboard-inspect"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-clipboard-transcript",
            "operation": "inspect-clipboard",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "clipboard", "state",
                    "--pasteboard", pasteboardName
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "pasteboard": pasteboardName,
                    "changeCount": 7,
                    "hasString": true,
                    "stringLength": 9,
                    "stringDigest": String(repeating: "b", count: 64)
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-clipboard",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-clipboard")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "read-clipboard",
            "--max-characters", "4096",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path,
            "--pasteboard", pasteboardName
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("dry-run bounded clipboard text reading") == true)
    }

    func testWorkflowResumeSuggestsClipboardStateAfterClipboardRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-clipboard-read-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let pasteboardName = "Ln1-test-pasteboard-read"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "read-clipboard-transcript",
            "operation": "read-clipboard",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "clipboard", "read-text",
                    "--allow-risk", "medium",
                    "--max-characters", "4096",
                    "--reason", "Inspect clipboard text",
                    "--pasteboard", pasteboardName
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "pasteboard": pasteboardName,
                    "changeCount": 9,
                    "hasString": true,
                    "text": "clipboard",
                    "stringLength": 9,
                    "stringDigest": String(repeating: "c", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-clipboard",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "read-clipboard")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("clipboard text read completed") == true)
    }

    func testWorkflowResumeSuggestsClipboardStateAfterClipboardWrite() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-clipboard-write-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let pasteboardName = "Ln1-test-pasteboard-write"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "write-clipboard-transcript",
            "operation": "write-clipboard",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "clipboard", "write-text",
                    "--text", "prepared",
                    "--allow-risk", "medium",
                    "--reason", "prepare clipboard",
                    "--pasteboard", pasteboardName
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "pasteboard": pasteboardName,
                    "writtenLength": 8,
                    "writtenDigest": String(repeating: "d", count: 64),
                    "verification": [
                        "ok": true,
                        "code": "clipboard_text_verified"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "write-clipboard",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "write-clipboard")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("clipboard write completed") == true)
    }

    func testWorkflowResumeSuggestsClipboardRollbackAfterWriteWithSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-clipboard-write-rollback-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let pasteboardName = "Ln1-test-pasteboard-write-rollback"
        let snapshotURL = directory.appendingPathComponent("rollback.json")
        let auditID = "clipboard-write-audit-id"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "write-clipboard-rollback-transcript",
            "operation": "write-clipboard",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "clipboard", "write-text",
                    "--text", "prepared",
                    "--rollback-snapshot", snapshotURL.path,
                    "--allow-risk", "medium",
                    "--reason", "prepare clipboard",
                    "--pasteboard", pasteboardName
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "pasteboard": pasteboardName,
                    "auditID": auditID,
                    "rollbackSnapshotPath": snapshotURL.path,
                    "writtenLength": 8,
                    "writtenDigest": String(repeating: "d", count: 64),
                    "verification": [
                        "ok": true,
                        "code": "clipboard_text_verified"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "write-clipboard",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "write-clipboard")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "rollback",
            "--audit-id", auditID,
            "--allow-risk", "medium",
            "--reason", "Describe intent",
            "--pasteboard", pasteboardName
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("rollback snapshot") == true)
    }

    func testWorkflowPreflightInspectClipboardReturnsMetadataCommand() throws {
        let pasteboardName = "Ln1-workflow-inspect-clipboard-preflight-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-clipboard",
            "--pasteboard", pasteboardName
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-clipboard")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "state",
            "--pasteboard", pasteboardName
        ])
    }

    func testWorkflowPreflightReadClipboardReturnsBoundedReadCommand() throws {
        let pasteboardName = "Ln1-workflow-read-clipboard-preflight-\(UUID().uuidString)"
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-clipboard-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "read-clipboard",
            "--pasteboard", pasteboardName,
            "--max-characters", "12",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "read-clipboard")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "read-text",
            "--allow-risk", "medium",
            "--max-characters", "12",
            "--reason", "Inspect clipboard text",
            "--audit-log", auditLog.path,
            "--pasteboard", pasteboardName
        ])
    }

    func testWorkflowPreflightWriteClipboardReturnsGuardedWriteCommand() throws {
        let pasteboardName = "Ln1-workflow-write-clipboard-preflight-\(UUID().uuidString)"
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-write-clipboard-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let missingText = try runLn1([
            "workflow",
            "preflight",
            "--operation", "write-clipboard",
            "--pasteboard", pasteboardName,
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(missingText.status, 0, missingText.stderr)
        let missingObject = try decodeJSONObject(missingText.stdout)
        XCTAssertEqual(missingObject["canProceed"] as? Bool, false)
        XCTAssertTrue((missingObject["blockers"] as? [String])?.contains("workflow.text") == true)

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "write-clipboard",
            "--pasteboard", pasteboardName,
            "--text", "prepared value",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "write-clipboard")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "clipboard", "write-text",
            "--text", "prepared value",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--pasteboard", pasteboardName,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowNextReturnsStructuredArgvWithoutInspectingClipboard() throws {
        let pasteboardName = "Ln1-workflow-inspect-clipboard-next-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "inspect-clipboard",
            "--pasteboard", pasteboardName
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-clipboard")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "clipboard", "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowRunExecutesNonMutatingClipboardWaitAndCapturesJSON() throws {
        let pasteboardName = "Ln1-workflow-clipboard-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("workflow old", forType: .string)
        let changedFrom = pasteboard.changeCount
        pasteboard.clearContents()
        pasteboard.setString("workflow new", forType: .string)

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-clipboard",
            "--pasteboard", pasteboardName,
            "--changed-from", String(changedFrom),
            "--has-string", "true",
            "--timeout-ms", "0",
            "--interval-ms", "50",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-clipboard")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "clipboard", "wait",
            "--pasteboard", pasteboardName,
            "--changed-from", String(changedFrom),
            "--has-string", "true",
            "--timeout-ms", "0",
            "--interval-ms", "50"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["changedFrom"] as? Int, changedFrom)
        XCTAssertNil(outputJSON["text"])
    }

    func testWorkflowRunExecutesNonMutatingClipboardInspectAndCapturesJSON() throws {
        let pasteboardName = "Ln1-workflow-inspect-clipboard-run-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("clipboard metadata", forType: .string)
        defer { pasteboard.clearContents() }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-clipboard",
            "--pasteboard", pasteboardName,
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-clipboard")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "clipboard", "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(outputJSON["hasString"] as? Bool, true)
        XCTAssertEqual(outputJSON["stringLength"] as? Int, 18)
        XCTAssertNil(outputJSON["text"])
    }

    func testWorkflowRunExecutesNonMutatingClipboardReadAndCapturesJSON() throws {
        let pasteboardName = "Ln1-workflow-read-clipboard-run-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-clipboard-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("workflow clipboard text", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-clipboard",
            "--pasteboard", pasteboardName,
            "--max-characters", "8",
            "--audit-log", auditLog.path,
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "read-clipboard")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "clipboard", "read-text",
            "--allow-risk", "medium",
            "--max-characters", "8",
            "--reason", "Inspect clipboard text",
            "--audit-log", auditLog.path,
            "--pasteboard", pasteboardName
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(outputJSON["hasString"] as? Bool, true)
        XCTAssertEqual(outputJSON["text"] as? String, "workflow")
        XCTAssertEqual(outputJSON["stringLength"] as? Int, 23)
        XCTAssertEqual(outputJSON["truncated"] as? Bool, true)
        XCTAssertEqual(outputJSON["maxCharacters"] as? Int, 8)
    }

    func testWorkflowRunExecutesMutatingClipboardWriteWithExplicitApprovalAndReason() throws {
        let pasteboardName = "Ln1-workflow-write-clipboard-run-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-write-clipboard-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "write-clipboard",
            "--pasteboard", pasteboardName,
            "--text", "workflow clipboard write",
            "--audit-log", auditLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "prepare workflow clipboard value",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(pasteboard.string(forType: .string), "workflow clipboard write")
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "write-clipboard")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "clipboard", "write-text",
            "--text", "workflow clipboard write",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--pasteboard", pasteboardName,
            "--reason", "prepare workflow clipboard value"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(outputJSON["writtenLength"] as? Int, 24)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertNil(outputJSON["text"])
    }

}
