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
}
