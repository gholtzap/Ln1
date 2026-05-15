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

}
