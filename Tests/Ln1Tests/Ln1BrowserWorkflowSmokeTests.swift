import Foundation
import XCTest

final class Ln1BrowserWorkflowSmokeTests: Ln1TestCase {
    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserURLWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-url-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-url-transcript",
            "operation": "wait-browser-url",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-url",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--expect-url", "https://example.com/done"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "verification": [
                        "ok": true,
                        "code": "url_matched",
                        "currentURL": "https://example.com/done"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-url",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-url")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "read-browser",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("DOM inspection") == true)
    }
    func testWorkflowResumeSuggestsBrowserActionsAfterDOMInspection() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-dom-resume-\(UUID().uuidString)")
        let fillWorkflowLog = directory.appendingPathComponent("fill-workflow-runs.jsonl")
        let selectWorkflowLog = directory.appendingPathComponent("select-workflow-runs.jsonl")
        let checkWorkflowLog = directory.appendingPathComponent("check-workflow-runs.jsonl")
        let clickWorkflowLog = directory.appendingPathComponent("click-workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let baseExecution: [String: Any] = [
            "argv": [
                "Ln1", "browser", "dom",
                "--endpoint", endpoint,
                "--id", "page-1",
                "--allow-risk", "medium"
            ],
            "exitCode": 0,
            "timedOut": false
        ]

        let fillTranscript: [String: Any] = [
            "transcriptID": "fill-transcript",
            "operation": "read-browser",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tab": ["id": "page-1"],
                    "elements": [
                        [
                            "id": "dom.1",
                            "selector": "input[name=\"q\"]",
                            "tagName": "input",
                            "role": "textbox",
                            "inputType": "search",
                            "disabled": false
                        ]
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(fillTranscript, to: fillWorkflowLog)

        let fillResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", fillWorkflowLog.path,
            "--operation", "read-browser",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(fillResume.status, 0, fillResume.stderr)
        let fillObject = try decodeJSONObject(fillResume.stdout)
        XCTAssertEqual(fillObject["status"] as? String, "completed")
        XCTAssertEqual(fillObject["nextArguments"] as? [String], [
            "Ln1", "browser", "fill",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "Describe text",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((fillObject["message"] as? String)?.contains("text field") == true)

        let selectTranscript: [String: Any] = [
            "transcriptID": "select-transcript",
            "operation": "read-browser",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tab": ["id": "page-1"],
                    "elements": [
                        [
                            "id": "dom.1",
                            "selector": "select[name=\"country\"]",
                            "tagName": "select",
                            "role": "combobox",
                            "disabled": false
                        ]
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(selectTranscript, to: selectWorkflowLog)

        let selectResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", selectWorkflowLog.path,
            "--operation", "read-browser",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(selectResume.status, 0, selectResume.stderr)
        let selectObject = try decodeJSONObject(selectResume.stdout)
        XCTAssertEqual(selectObject["status"] as? String, "completed")
        XCTAssertEqual(selectObject["nextArguments"] as? [String], [
            "Ln1", "browser", "select",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "select[name=\"country\"]",
            "--value", "Describe value",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((selectObject["message"] as? String)?.contains("select control") == true)

        let checkTranscript: [String: Any] = [
            "transcriptID": "check-transcript",
            "operation": "read-browser",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tab": ["id": "page-1"],
                    "elements": [
                        [
                            "id": "dom.1",
                            "selector": "input[name=\"subscribe\"]",
                            "tagName": "input",
                            "role": "checkbox",
                            "inputType": "checkbox",
                            "checked": false,
                            "disabled": false
                        ]
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(checkTranscript, to: checkWorkflowLog)

        let checkResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", checkWorkflowLog.path,
            "--operation", "read-browser",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(checkResume.status, 0, checkResume.stderr)
        let checkObject = try decodeJSONObject(checkResume.stdout)
        XCTAssertEqual(checkObject["status"] as? String, "completed")
        XCTAssertEqual(checkObject["nextArguments"] as? [String], [
            "Ln1", "browser", "check",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "input[name=\"subscribe\"]",
            "--checked", "true",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((checkObject["message"] as? String)?.contains("checkbox or radio") == true)

        let clickTranscript: [String: Any] = [
            "transcriptID": "click-transcript",
            "operation": "read-browser",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tab": ["id": "page-1"],
                    "elements": [
                        [
                            "id": "dom.1",
                            "selector": "button[type=\"submit\"]",
                            "tagName": "button",
                            "role": "button",
                            "disabled": false
                        ]
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(clickTranscript, to: clickWorkflowLog)

        let clickResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", clickWorkflowLog.path,
            "--operation", "read-browser",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(clickResume.status, 0, clickResume.stderr)
        let clickObject = try decodeJSONObject(clickResume.stdout)
        XCTAssertEqual(clickObject["status"] as? String, "completed")
        XCTAssertEqual(clickObject["nextArguments"] as? [String], [
            "Ln1", "browser", "click",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((clickObject["message"] as? String)?.contains("actionable element") == true)
    }

}
