import Foundation
import XCTest

final class Ln1ProcessSmokeTests: Ln1TestCase {
    func testProcessesListReturnsBoundedStructuredProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "--limit", "25"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let processes = try XCTUnwrap(object["processes"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["limit"] as? Int, 25)
        XCTAssertEqual(object["count"] as? Int, processes.count)
        XCTAssertLessThanOrEqual(processes.count, 25)
        XCTAssertNotNil(object["truncated"] as? Bool)
        XCTAssertTrue(processes.contains { $0["currentProcess"] as? Bool == true })

        let first = try XCTUnwrap(processes.first)
        XCTAssertNotNil(first["pid"] as? Int)
        XCTAssertNotNil(first["currentProcess"] as? Bool)
        XCTAssertNotNil(first["activeApp"] as? Bool)
    }

    func testProcessesInspectCurrentReturnsCurrentProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "inspect",
            "--current"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let process = try XCTUnwrap(object["process"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["found"] as? Bool, true)
        XCTAssertEqual(process["currentProcess"] as? Bool, true)
        XCTAssertNotNil(process["pid"] as? Int)
        XCTAssertNotNil(process["activeApp"] as? Bool)
        XCTAssertTrue(process["name"] is String || process["executablePath"] is String)
    }

    func testProcessesWaitReturnsMatchedExistingProcessMetadata() throws {
        let result = try runLn1([
            "processes",
            "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "process_matched")
        XCTAssertEqual(verification["expectedExists"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNotNil(verification["current"] as? [String: Any])
    }

    func testProcessesWaitTimesOutForExistingProcessToDisappear() throws {
        let result = try runLn1([
            "processes",
            "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "false",
            "--timeout-ms", "100",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(verification["ok"] as? Bool, false)
        XCTAssertEqual(verification["code"] as? String, "process_timeout")
        XCTAssertEqual(verification["expectedExists"] as? Bool, false)
        XCTAssertEqual(verification["matched"] as? Bool, false)
    }

    func testWorkflowPreflightInspectProcessBuildsProcessInspectCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-process",
            "--current"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-process")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "processes", "inspect", "--current"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.processTarget" && $0["status"] as? String == "pass" })
    }

    func testWorkflowRunExecutesNonMutatingProcessInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-process-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-process",
            "--current",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let process = try XCTUnwrap(outputJSON["process"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-process")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "processes", "inspect", "--current"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["found"] as? Bool, true)
        XCTAssertEqual(process["currentProcess"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowPreflightWaitProcessBuildsProcessWaitCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-process",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "wait-process")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "processes", "wait",
            "--pid", "\(ProcessInfo.processInfo.processIdentifier)",
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.processTarget" && $0["status"] as? String == "pass" })
    }
}
