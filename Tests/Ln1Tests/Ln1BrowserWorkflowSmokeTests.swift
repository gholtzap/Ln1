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

    func testWorkflowResumeSuggestsBrowserActionsAfterSelectorWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-selector-wait-resume-\(UUID().uuidString)")
        let clickWorkflowLog = directory.appendingPathComponent("click-workflow-runs.jsonl")
        let fillWorkflowLog = directory.appendingPathComponent("fill-workflow-runs.jsonl")
        let selectWorkflowLog = directory.appendingPathComponent("select-workflow-runs.jsonl")
        let checkWorkflowLog = directory.appendingPathComponent("check-workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let baseExecution: [String: Any] = [
            "argv": [
                "Ln1", "browser", "wait-selector",
                "--endpoint", endpoint,
                "--id", "page-1"
            ],
            "exitCode": 0,
            "timedOut": false
        ]

        let clickTranscript: [String: Any] = [
            "transcriptID": "selector-click-transcript",
            "operation": "wait-browser-selector",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "button[type=\"submit\"]",
                    "verification": [
                        "ok": true,
                        "code": "selector_matched",
                        "selector": "button[type=\"submit\"]",
                        "state": "visible",
                        "tagName": "button",
                        "disabled": false
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(clickTranscript, to: clickWorkflowLog)

        let clickResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", clickWorkflowLog.path,
            "--operation", "wait-browser-selector",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(clickResume.status, 0, clickResume.stderr)
        let clickObject = try decodeJSONObject(clickResume.stdout)
        XCTAssertEqual(clickObject["status"] as? String, "completed")
        XCTAssertEqual(clickObject["latestOperation"] as? String, "wait-browser-selector")
        XCTAssertEqual(clickObject["nextArguments"] as? [String], [
            "Ln1", "browser", "click",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((clickObject["message"] as? String)?.contains("actionable element") == true)

        let fillTranscript: [String: Any] = [
            "transcriptID": "selector-fill-transcript",
            "operation": "wait-browser-selector",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "input[name=\"q\"]",
                    "verification": [
                        "ok": true,
                        "code": "selector_matched",
                        "selector": "input[name=\"q\"]",
                        "state": "visible",
                        "tagName": "input",
                        "inputType": "search",
                        "disabled": false,
                        "readOnly": false
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(fillTranscript, to: fillWorkflowLog)

        let fillResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", fillWorkflowLog.path,
            "--operation", "wait-browser-selector",
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
            "transcriptID": "selector-select-transcript",
            "operation": "wait-browser-selector",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "select[name=\"country\"]",
                    "verification": [
                        "ok": true,
                        "code": "selector_matched",
                        "selector": "select[name=\"country\"]",
                        "state": "visible",
                        "tagName": "select",
                        "disabled": false
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(selectTranscript, to: selectWorkflowLog)

        let selectResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", selectWorkflowLog.path,
            "--operation", "wait-browser-selector",
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
            "transcriptID": "selector-check-transcript",
            "operation": "wait-browser-selector",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": baseExecution.merging([
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "input[name=\"subscribe\"]",
                    "verification": [
                        "ok": true,
                        "code": "selector_matched",
                        "selector": "input[name=\"subscribe\"]",
                        "state": "visible",
                        "tagName": "input",
                        "inputType": "checkbox",
                        "disabled": false,
                        "readOnly": false
                    ]
                ]
            ]) { _, new in new }
        ]
        try writeJSONObjectLine(checkTranscript, to: checkWorkflowLog)

        let checkResume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", checkWorkflowLog.path,
            "--operation", "wait-browser-selector",
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
    }

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserTextWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-text-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-text-transcript",
            "operation": "wait-browser-text",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-text",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--text", "Saved successfully"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "verification": [
                        "ok": true,
                        "code": "text_matched",
                        "currentURL": "https://example.com/form",
                        "currentTextLength": 23
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-text",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-text")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserElementTextWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-element-text-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-element-text-transcript",
            "operation": "wait-browser-element-text",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-element-text",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "[data-testid='status']",
                    "--text", "Saved successfully"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "[data-testid='status']",
                    "verification": [
                        "ok": true,
                        "code": "element_text_matched",
                        "selector": "[data-testid='status']",
                        "currentURL": "https://example.com/form",
                        "currentTextLength": 18
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-element-text",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-element-text")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserCountWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-count-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-count-transcript",
            "operation": "wait-browser-count",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-count",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", ".result-row",
                    "--count", "3"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": ".result-row",
                    "verification": [
                        "ok": true,
                        "code": "count_matched",
                        "selector": ".result-row",
                        "expectedCount": 3,
                        "currentCount": 5,
                        "countMatch": "at-least",
                        "currentURL": "https://example.com/results"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-count",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-count")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserValueWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-value-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-value-transcript",
            "operation": "wait-browser-value",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-value",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "input[name='q']",
                    "--text", "bounded text"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "input[name='q']",
                    "verification": [
                        "ok": true,
                        "code": "value_matched",
                        "currentURL": "https://example.com/form",
                        "currentValueLength": 12,
                        "currentValueDigest": "digest"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-value",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-value")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserReadyWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-ready-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-ready-transcript",
            "operation": "wait-browser-ready",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-ready",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--state", "complete"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "verification": [
                        "ok": true,
                        "code": "ready_state_matched",
                        "currentState": "complete",
                        "currentURL": "https://example.com/form"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-ready",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-ready")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserTitleWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-title-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-title-transcript",
            "operation": "wait-browser-title",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-title",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--title", "Checkout"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "verification": [
                        "ok": true,
                        "code": "title_matched",
                        "currentTitle": "Checkout - Example",
                        "currentURL": "https://example.com/checkout"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-title",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-title")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserCheckedWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-checked-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-checked-transcript",
            "operation": "wait-browser-checked",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-checked",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "input[name='subscribe']",
                    "--checked", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "input[name='subscribe']",
                    "verification": [
                        "ok": true,
                        "code": "checked_matched",
                        "selector": "input[name='subscribe']",
                        "expectedChecked": true,
                        "currentChecked": true,
                        "currentURL": "https://example.com/preferences"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-checked",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-checked")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserFocusWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-focus-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-focus-transcript",
            "operation": "wait-browser-focus",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-focus",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "input[name='q']",
                    "--focused", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "input[name='q']",
                    "verification": [
                        "ok": true,
                        "code": "focus_matched",
                        "selector": "input[name='q']",
                        "expectedFocused": true,
                        "currentFocused": true,
                        "currentURL": "https://example.com/form"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-focus",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-focus")
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

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserAttributeWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-attribute-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-attribute-transcript",
            "operation": "wait-browser-attribute",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-attribute",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "button[aria-expanded]",
                    "--attribute", "aria-expanded",
                    "--text", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "button[aria-expanded]",
                    "attribute": "aria-expanded",
                    "verification": [
                        "ok": true,
                        "code": "attribute_matched",
                        "selector": "button[aria-expanded]",
                        "attribute": "aria-expanded",
                        "currentValueLength": 4,
                        "currentURL": "https://example.com/menu"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-attribute",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-attribute")
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

    func testWorkflowResumeSuggestsBrowserActionAfterBrowserEnabledWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-enabled-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let transcript: [String: Any] = [
            "transcriptID": "wait-enabled-transcript",
            "operation": "wait-browser-enabled",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "browser", "wait-enabled",
                    "--endpoint", endpoint,
                    "--id", "page-1",
                    "--selector", "button[type='submit']",
                    "--enabled", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "endpoint": endpoint,
                    "tabID": "page-1",
                    "selector": "button[type='submit']",
                    "verification": [
                        "ok": true,
                        "code": "enabled_matched",
                        "selector": "button[type='submit']",
                        "expectedEnabled": true,
                        "currentEnabled": true,
                        "currentURL": "https://example.com/form",
                        "tagName": "button",
                        "disabled": false
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-browser-enabled",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-browser-enabled")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "browser", "click",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("enabled actionable element") == true)
    }

    func testWorkflowPreflightBrowserActionsReturnTypedCommands() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-browser-action-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Workflow Browser Page",
            "url": "https://example.com/form"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fill = try runLn1([
            "workflow",
            "preflight",
            "--operation", "fill-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "search text",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(fill.status, 0, fill.stderr)
        let fillObject = try decodeJSONObject(fill.stdout)
        let fillBlockers = try XCTUnwrap(fillObject["blockers"] as? [String])
        XCTAssertEqual(fillObject["operation"] as? String, "fill-browser")
        XCTAssertEqual(fillObject["risk"] as? String, "medium")
        XCTAssertEqual(fillObject["mutates"] as? Bool, true)
        XCTAssertTrue(fillBlockers.isEmpty)
        XCTAssertEqual(fillObject["nextArguments"] as? [String], [
            "Ln1", "browser", "fill",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "search text",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let select = try runLn1([
            "workflow",
            "preflight",
            "--operation", "select-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "select[name=\"country\"]",
            "--value", "ca",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(select.status, 0, select.stderr)
        let selectObject = try decodeJSONObject(select.stdout)
        let selectBlockers = try XCTUnwrap(selectObject["blockers"] as? [String])
        XCTAssertEqual(selectObject["operation"] as? String, "select-browser")
        XCTAssertEqual(selectObject["risk"] as? String, "medium")
        XCTAssertEqual(selectObject["mutates"] as? Bool, true)
        XCTAssertTrue(selectBlockers.isEmpty)
        XCTAssertEqual(selectObject["nextArguments"] as? [String], [
            "Ln1", "browser", "select",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "select[name=\"country\"]",
            "--value", "ca",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let check = try runLn1([
            "workflow",
            "preflight",
            "--operation", "check-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"subscribe\"]",
            "--checked", "true",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(check.status, 0, check.stderr)
        let checkObject = try decodeJSONObject(check.stdout)
        let checkBlockers = try XCTUnwrap(checkObject["blockers"] as? [String])
        XCTAssertEqual(checkObject["operation"] as? String, "check-browser")
        XCTAssertEqual(checkObject["risk"] as? String, "medium")
        XCTAssertEqual(checkObject["mutates"] as? Bool, true)
        XCTAssertTrue(checkBlockers.isEmpty)
        XCTAssertEqual(checkObject["nextArguments"] as? [String], [
            "Ln1", "browser", "check",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"subscribe\"]",
            "--checked", "true",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let focus = try runLn1([
            "workflow",
            "preflight",
            "--operation", "focus-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(focus.status, 0, focus.stderr)
        let focusObject = try decodeJSONObject(focus.stdout)
        let focusBlockers = try XCTUnwrap(focusObject["blockers"] as? [String])
        XCTAssertEqual(focusObject["operation"] as? String, "focus-browser")
        XCTAssertEqual(focusObject["risk"] as? String, "medium")
        XCTAssertEqual(focusObject["mutates"] as? Bool, true)
        XCTAssertTrue(focusBlockers.isEmpty)
        XCTAssertEqual(focusObject["nextArguments"] as? [String], [
            "Ln1", "browser", "focus",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let pressKey = try runLn1([
            "workflow",
            "preflight",
            "--operation", "press-browser-key",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--key", "Enter",
            "--modifiers", "control",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(pressKey.status, 0, pressKey.stderr)
        let pressKeyObject = try decodeJSONObject(pressKey.stdout)
        let pressKeyBlockers = try XCTUnwrap(pressKeyObject["blockers"] as? [String])
        XCTAssertEqual(pressKeyObject["operation"] as? String, "press-browser-key")
        XCTAssertEqual(pressKeyObject["risk"] as? String, "medium")
        XCTAssertEqual(pressKeyObject["mutates"] as? Bool, true)
        XCTAssertTrue(pressKeyBlockers.isEmpty)
        XCTAssertEqual(pressKeyObject["nextArguments"] as? [String], [
            "Ln1", "browser", "press-key",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--key", "Enter",
            "--selector", "input[name=\"q\"]",
            "--modifiers", "control",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let undo = try runLn1([
            "workflow",
            "preflight",
            "--operation", "undo-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(undo.status, 0, undo.stderr)
        let undoObject = try decodeJSONObject(undo.stdout)
        let undoBlockers = try XCTUnwrap(undoObject["blockers"] as? [String])
        XCTAssertEqual(undoObject["operation"] as? String, "undo-browser")
        XCTAssertEqual(undoObject["risk"] as? String, "medium")
        XCTAssertEqual(undoObject["mutates"] as? Bool, true)
        XCTAssertTrue(undoBlockers.isEmpty)
        XCTAssertEqual(undoObject["nextArguments"] as? [String], [
            "Ln1", "browser", "undo",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let click = try runLn1([
            "workflow",
            "next",
            "--operation", "click-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(click.status, 0, click.stderr)
        let clickObject = try decodeJSONObject(click.stdout)
        let command = try XCTUnwrap(clickObject["command"] as? [String: Any])
        XCTAssertEqual(clickObject["operation"] as? String, "click-browser")
        XCTAssertEqual(clickObject["ready"] as? Bool, true)
        XCTAssertEqual(clickObject["risk"] as? String, "medium")
        XCTAssertEqual(clickObject["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "browser", "click",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let clickWithExpectedURL = try runLn1([
            "workflow",
            "preflight",
            "--operation", "click-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--expect-url", "https://example.com/results",
            "--match", "prefix",
            "--timeout-ms", "750",
            "--interval-ms", "50",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(clickWithExpectedURL.status, 0, clickWithExpectedURL.stderr)
        let clickWithExpectedURLObject = try decodeJSONObject(clickWithExpectedURL.stdout)
        XCTAssertEqual(clickWithExpectedURLObject["operation"] as? String, "click-browser")
        XCTAssertEqual(clickWithExpectedURLObject["nextArguments"] as? [String], [
            "Ln1", "browser", "click",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--expect-url", "https://example.com/results",
            "--match", "prefix",
            "--timeout-ms", "750",
            "--interval-ms", "50",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let navigate = try runLn1([
            "workflow",
            "preflight",
            "--operation", "navigate-browser",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--url", "https://example.com/next",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(navigate.status, 0, navigate.stderr)
        let navigateObject = try decodeJSONObject(navigate.stdout)
        let navigateBlockers = try XCTUnwrap(navigateObject["blockers"] as? [String])
        XCTAssertEqual(navigateObject["operation"] as? String, "navigate-browser")
        XCTAssertEqual(navigateObject["risk"] as? String, "medium")
        XCTAssertEqual(navigateObject["mutates"] as? Bool, true)
        XCTAssertTrue(navigateBlockers.isEmpty)
        XCTAssertEqual(navigateObject["nextArguments"] as? [String], [
            "Ln1", "browser", "navigate",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--url", "https://example.com/next",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--audit-log", auditLog.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let waitURL = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-url",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitURL.status, 0, waitURL.stderr)
        let waitObject = try decodeJSONObject(waitURL.stdout)
        let waitBlockers = try XCTUnwrap(waitObject["blockers"] as? [String])
        XCTAssertEqual(waitObject["operation"] as? String, "wait-browser-url")
        XCTAssertEqual(waitObject["risk"] as? String, "low")
        XCTAssertEqual(waitObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitBlockers.isEmpty)
        XCTAssertEqual(waitObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-url",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitSelector = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-selector",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--state", "visible",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitSelector.status, 0, waitSelector.stderr)
        let waitSelectorObject = try decodeJSONObject(waitSelector.stdout)
        let waitSelectorBlockers = try XCTUnwrap(waitSelectorObject["blockers"] as? [String])
        XCTAssertEqual(waitSelectorObject["operation"] as? String, "wait-browser-selector")
        XCTAssertEqual(waitSelectorObject["risk"] as? String, "low")
        XCTAssertEqual(waitSelectorObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitSelectorBlockers.isEmpty)
        XCTAssertEqual(waitSelectorObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-selector",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--state", "visible",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitSelectorHidden = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-selector",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", ".loading-overlay",
            "--state", "hidden",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitSelectorHidden.status, 0, waitSelectorHidden.stderr)
        let waitSelectorHiddenObject = try decodeJSONObject(waitSelectorHidden.stdout)
        let waitSelectorHiddenBlockers = try XCTUnwrap(waitSelectorHiddenObject["blockers"] as? [String])
        XCTAssertEqual(waitSelectorHiddenObject["operation"] as? String, "wait-browser-selector")
        XCTAssertEqual(waitSelectorHiddenObject["risk"] as? String, "low")
        XCTAssertEqual(waitSelectorHiddenObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitSelectorHiddenBlockers.isEmpty)
        XCTAssertEqual(waitSelectorHiddenObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-selector",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", ".loading-overlay",
            "--state", "hidden",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitCount = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-count",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", ".result-row",
            "--count", "3",
            "--count-match", "at-least",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitCount.status, 0, waitCount.stderr)
        let waitCountObject = try decodeJSONObject(waitCount.stdout)
        let waitCountBlockers = try XCTUnwrap(waitCountObject["blockers"] as? [String])
        XCTAssertEqual(waitCountObject["operation"] as? String, "wait-browser-count")
        XCTAssertEqual(waitCountObject["risk"] as? String, "low")
        XCTAssertEqual(waitCountObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitCountBlockers.isEmpty)
        XCTAssertEqual(waitCountObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-count",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", ".result-row",
            "--count", "3",
            "--count-match", "at-least",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitText = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitText.status, 0, waitText.stderr)
        let waitTextObject = try decodeJSONObject(waitText.stdout)
        let waitTextBlockers = try XCTUnwrap(waitTextObject["blockers"] as? [String])
        XCTAssertEqual(waitTextObject["operation"] as? String, "wait-browser-text")
        XCTAssertEqual(waitTextObject["risk"] as? String, "low")
        XCTAssertEqual(waitTextObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitTextBlockers.isEmpty)
        XCTAssertEqual(waitTextObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-text",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitElementText = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-element-text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "[data-testid=\"status\"]",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitElementText.status, 0, waitElementText.stderr)
        let waitElementTextObject = try decodeJSONObject(waitElementText.stdout)
        let waitElementTextBlockers = try XCTUnwrap(waitElementTextObject["blockers"] as? [String])
        XCTAssertEqual(waitElementTextObject["operation"] as? String, "wait-browser-element-text")
        XCTAssertEqual(waitElementTextObject["risk"] as? String, "low")
        XCTAssertEqual(waitElementTextObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitElementTextBlockers.isEmpty)
        XCTAssertEqual(waitElementTextObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-element-text",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "[data-testid=\"status\"]",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitReady = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-ready",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--state", "interactive",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitReady.status, 0, waitReady.stderr)
        let waitReadyObject = try decodeJSONObject(waitReady.stdout)
        let waitReadyBlockers = try XCTUnwrap(waitReadyObject["blockers"] as? [String])
        XCTAssertEqual(waitReadyObject["operation"] as? String, "wait-browser-ready")
        XCTAssertEqual(waitReadyObject["risk"] as? String, "low")
        XCTAssertEqual(waitReadyObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitReadyBlockers.isEmpty)
        XCTAssertEqual(waitReadyObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-ready",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--state", "interactive",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitTitle = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-title",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--title", "Workflow Browser",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitTitle.status, 0, waitTitle.stderr)
        let waitTitleObject = try decodeJSONObject(waitTitle.stdout)
        let waitTitleBlockers = try XCTUnwrap(waitTitleObject["blockers"] as? [String])
        XCTAssertEqual(waitTitleObject["operation"] as? String, "wait-browser-title")
        XCTAssertEqual(waitTitleObject["risk"] as? String, "low")
        XCTAssertEqual(waitTitleObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitTitleBlockers.isEmpty)
        XCTAssertEqual(waitTitleObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-title",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--title", "Workflow Browser",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitValue = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-value",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "bounded text",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitValue.status, 0, waitValue.stderr)
        let waitValueObject = try decodeJSONObject(waitValue.stdout)
        let waitValueBlockers = try XCTUnwrap(waitValueObject["blockers"] as? [String])
        XCTAssertEqual(waitValueObject["operation"] as? String, "wait-browser-value")
        XCTAssertEqual(waitValueObject["risk"] as? String, "low")
        XCTAssertEqual(waitValueObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitValueBlockers.isEmpty)
        XCTAssertEqual(waitValueObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-value",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "bounded text",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitChecked = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-checked",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"subscribe\"]",
            "--checked", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitChecked.status, 0, waitChecked.stderr)
        let waitCheckedObject = try decodeJSONObject(waitChecked.stdout)
        let waitCheckedBlockers = try XCTUnwrap(waitCheckedObject["blockers"] as? [String])
        XCTAssertEqual(waitCheckedObject["operation"] as? String, "wait-browser-checked")
        XCTAssertEqual(waitCheckedObject["risk"] as? String, "low")
        XCTAssertEqual(waitCheckedObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitCheckedBlockers.isEmpty)
        XCTAssertEqual(waitCheckedObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-checked",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"subscribe\"]",
            "--checked", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitEnabled = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-enabled",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--enabled", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitEnabled.status, 0, waitEnabled.stderr)
        let waitEnabledObject = try decodeJSONObject(waitEnabled.stdout)
        let waitEnabledBlockers = try XCTUnwrap(waitEnabledObject["blockers"] as? [String])
        XCTAssertEqual(waitEnabledObject["operation"] as? String, "wait-browser-enabled")
        XCTAssertEqual(waitEnabledObject["risk"] as? String, "low")
        XCTAssertEqual(waitEnabledObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitEnabledBlockers.isEmpty)
        XCTAssertEqual(waitEnabledObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-enabled",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--enabled", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitFocus = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-focus",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--focused", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitFocus.status, 0, waitFocus.stderr)
        let waitFocusObject = try decodeJSONObject(waitFocus.stdout)
        let waitFocusBlockers = try XCTUnwrap(waitFocusObject["blockers"] as? [String])
        XCTAssertEqual(waitFocusObject["operation"] as? String, "wait-browser-focus")
        XCTAssertEqual(waitFocusObject["risk"] as? String, "low")
        XCTAssertEqual(waitFocusObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitFocusBlockers.isEmpty)
        XCTAssertEqual(waitFocusObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-focus",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--focused", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitAttribute = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-browser-attribute",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[aria-expanded]",
            "--attribute", "aria-expanded",
            "--text", "true",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(waitAttribute.status, 0, waitAttribute.stderr)
        let waitAttributeObject = try decodeJSONObject(waitAttribute.stdout)
        let waitAttributeBlockers = try XCTUnwrap(waitAttributeObject["blockers"] as? [String])
        XCTAssertEqual(waitAttributeObject["operation"] as? String, "wait-browser-attribute")
        XCTAssertEqual(waitAttributeObject["risk"] as? String, "low")
        XCTAssertEqual(waitAttributeObject["mutates"] as? Bool, false)
        XCTAssertTrue(waitAttributeBlockers.isEmpty)
        XCTAssertEqual(waitAttributeObject["nextArguments"] as? [String], [
            "Ln1", "browser", "wait-attribute",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[aria-expanded]",
            "--attribute", "aria-expanded",
            "--text", "true",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
    }

    func testWorkflowRunExecutesNonMutatingBrowserReadAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-browser-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Workflow Page",
            "url": "https://example.com/workflow"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-browser",
            "--endpoint", directory.path,
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let tabs = try XCTUnwrap(outputJSON["tabs"] as? [[String: Any]])
        let firstTab = try XCTUnwrap(tabs.first)

        XCTAssertEqual(object["operation"] as? String, "read-browser")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["wouldExecute"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["mutates"] as? Bool, false)
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(execution["timeoutMilliseconds"] as? Int, 5000)
        XCTAssertEqual(execution["timedOut"] as? Bool, false)
        XCTAssertEqual(execution["maxOutputBytes"] as? Int, 50000)
        XCTAssertEqual(execution["stdoutTruncated"] as? Bool, false)
        XCTAssertEqual(execution["stderrTruncated"] as? Bool, false)
        XCTAssertGreaterThan(execution["stdoutBytes"] as? Int ?? 0, 0)
        XCTAssertEqual(execution["stderrBytes"] as? Int, 0)
        XCTAssertEqual(outputJSON["count"] as? Int, 1)
        XCTAssertEqual(firstTab["id"] as? String, "page-1")
        XCTAssertEqual(firstTab["title"] as? String, "Workflow Page")
        XCTAssertTrue((execution["stdout"] as? String)?.contains("\"tabs\"") == true)
        XCTAssertEqual(execution["stderr"] as? String, "")
    }

}
