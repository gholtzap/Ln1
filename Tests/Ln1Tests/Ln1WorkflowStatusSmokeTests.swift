import Foundation
import XCTest

final class Ln1WorkflowStatusSmokeTests: Ln1TestCase {
    func testWorkflowStatusReportsEmptyTranscriptWithObserveNextStep() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-status-empty-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "status",
            "--workflow-log", workflowLog.path,
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["path"] as? String, workflowLog.path)
        XCTAssertEqual(object["status"] as? String, "empty")
        XCTAssertEqual(object["count"] as? Int, 0)
        XCTAssertEqual(object["controlLoop"] as? [String], ["observe", "inspect", "preflight", "act", "verify", "audit"])
        XCTAssertNil(object["latest"])
        XCTAssertEqual(object["nextArguments"] as? [String], ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"])
    }

    func testWorkflowStatusSummarizesLoopPhasesAndMutationEvidence() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-status-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try writeJSONObjectLine([
            "transcriptID": "inspect-1",
            "operation": "inspect-frontmost-app",
            "risk": "low",
            "mutates": false,
            "dryRun": false,
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": ["Ln1", "apps", "active"],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": ["pid": 123, "name": "Example"]
            ]
        ], to: workflowLog)
        try appendJSONObjectLine([
            "transcriptID": "preflight-1",
            "operation": "click-browser",
            "risk": "medium",
            "mutates": true,
            "dryRun": true,
            "blockers": [],
            "executed": false,
            "wouldExecute": true,
            "command": [
                "argv": [
                    "Ln1", "browser", "click",
                    "--endpoint", "http://127.0.0.1:9222",
                    "--id", "page-1",
                    "--selector", "button",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ]
            ]
        ], to: workflowLog)
        try appendJSONObjectLine([
            "transcriptID": "act-1",
            "operation": "click-browser",
            "risk": "medium",
            "mutates": true,
            "dryRun": false,
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "command": [
                "argv": [
                    "Ln1", "browser", "click",
                    "--endpoint", "http://127.0.0.1:9222",
                    "--id", "page-1",
                    "--selector", "button",
                    "--allow-risk", "medium",
                    "--reason", "Submit reviewed form",
                    "--audit-log", auditLog.path
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "browser", "click",
                    "--endpoint", "http://127.0.0.1:9222",
                    "--id", "page-1",
                    "--selector", "button",
                    "--allow-risk", "medium",
                    "--reason", "Submit reviewed form",
                    "--audit-log", auditLog.path
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "auditID": "audit-1",
                    "auditLogPath": auditLog.path,
                    "verification": [
                        "ok": true,
                        "code": "clicked"
                    ]
                ]
            ]
        ], to: workflowLog)
        try appendJSONObjectLine([
            "transcriptID": "verify-1",
            "operation": "wait-browser-url",
            "risk": "low",
            "mutates": false,
            "dryRun": false,
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": ["Ln1", "browser", "wait-url"],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "verification": [
                        "ok": true,
                        "code": "url_matched"
                    ]
                ]
            ]
        ], to: workflowLog)
        try appendJSONObjectLine([
            "transcriptID": "audit-1",
            "operation": "review-audit",
            "risk": "medium",
            "mutates": false,
            "dryRun": false,
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": ["Ln1", "audit", "--id", "audit-1"],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": ["entries": []]
            ]
        ], to: workflowLog)

        let result = try runLn1([
            "workflow",
            "status",
            "--workflow-log", workflowLog.path,
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let latest = try XCTUnwrap(object["latest"] as? [String: Any])
        let mutationSummary = try XCTUnwrap(object["mutationSummary"] as? [String: Any])
        let phaseCounts = try XCTUnwrap(object["phaseCounts"] as? [[String: Any]])
        let phaseCountByName = Dictionary(uniqueKeysWithValues: phaseCounts.compactMap { phase -> (String, Int)? in
            guard let name = phase["phase"] as? String,
                  let count = phase["count"] as? Int else {
                return nil
            }
            return (name, count)
        })

        XCTAssertEqual(object["status"] as? String, "ready")
        XCTAssertEqual(object["count"] as? Int, 5)
        XCTAssertEqual(object["missingTranscriptPhases"] as? [String], [])
        XCTAssertEqual(phaseCountByName["inspect"], 1)
        XCTAssertEqual(phaseCountByName["preflight"], 1)
        XCTAssertEqual(phaseCountByName["act"], 1)
        XCTAssertEqual(phaseCountByName["verify"], 1)
        XCTAssertEqual(phaseCountByName["audit"], 1)
        XCTAssertEqual(latest["operation"] as? String, "review-audit")
        XCTAssertEqual(latest["phase"] as? String, "audit")
        XCTAssertEqual(latest["status"] as? String, "completed")
        XCTAssertEqual(mutationSummary["planned"] as? Int, 2)
        XCTAssertEqual(mutationSummary["executed"] as? Int, 1)
        XCTAssertEqual(mutationSummary["withReason"] as? Int, 1)
        XCTAssertEqual(mutationSummary["withAuditEvidence"] as? Int, 1)
        XCTAssertEqual(mutationSummary["withVerificationEvidence"] as? Int, 1)
        XCTAssertEqual((mutationSummary["gaps"] as? [[String: Any]])?.count, 0)
    }

    func testWorkflowStatusFlagsMutatingExecutionEvidenceGaps() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-status-gaps-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        try writeJSONObjectLine([
            "transcriptID": "act-with-gaps",
            "operation": "type-input",
            "risk": "medium",
            "mutates": true,
            "dryRun": false,
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "command": [
                "argv": [
                    "Ln1", "input", "type",
                    "--text", "hello",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ]
            ],
            "execution": [
                "argv": [
                    "Ln1", "input", "type",
                    "--text", "hello",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": ["ok": true]
            ]
        ], to: workflowLog)

        let result = try runLn1([
            "workflow",
            "status",
            "--workflow-log", workflowLog.path,
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let mutationSummary = try XCTUnwrap(object["mutationSummary"] as? [String: Any])
        let gaps = try XCTUnwrap(mutationSummary["gaps"] as? [[String: Any]])
        let firstGap = try XCTUnwrap(gaps.first)

        XCTAssertEqual(object["status"] as? String, "needs_review")
        XCTAssertEqual(firstGap["operation"] as? String, "type-input")
        XCTAssertEqual(firstGap["missing"] as? [String], ["reason", "audit", "verification"])
    }

    private func appendJSONObjectLine(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let line = String(decoding: data, as: UTF8.self) + "\n"
        if FileManager.default.fileExists(atPath: url.path) {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: Data(line.utf8))
        } else {
            try line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
