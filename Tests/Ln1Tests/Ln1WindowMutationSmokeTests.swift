import ApplicationServices
import Foundation
import XCTest

final class Ln1WindowMutationSmokeTests: Ln1TestCase {
    func testDesktopRaiseWindowPolicyDenialIsAuditedWithoutRaising() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-raise-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "raise-window",
            "--element", "w0",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.raise-window")
        XCTAssertEqual(entry["action"] as? String, "desktop.raiseWindow")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testDesktopSetWindowFramePolicyDenialIsAuditedWithoutMovingWindow() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-desktop-frame-denied-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "desktop",
            "set-window-frame",
            "--element", "w0",
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(result.status, 0)
        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "desktop.set-window-frame")
        XCTAssertEqual(entry["action"] as? String, "desktop.setWindowFrame")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testWorkflowPreflightRaiseWindowBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window raising.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for raise preflight.")
        }
        let actions = firstWindow["actions"] as? [String] ?? []
        guard actions.contains(kAXRaiseAction as String) else {
            throw XCTSkip("The current Accessibility window does not expose AXRaise.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-raise-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "raise-window")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowElement" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRole" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRaiseAction" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowPreflightSetWindowFrameBuildsAuditedDesktopCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window frame changes.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for frame preflight.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXPositionAttribute as String),
              settableAttributes.contains(kAXSizeAttribute as String),
              firstWindow["frame"] as? [String: Any] != nil else {
            throw XCTSkip("The current Accessibility window does not expose settable, readable geometry.")
        }

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-frame-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--wait-timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "set-window-frame")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "desktop", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10.0",
            "--y", "20.0",
            "--width", "640.0",
            "--height", "480.0",
            "--timeout-ms", "1500",
            "--interval-ms", "75",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowElement" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowFrame" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowRole" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowPositionSettable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowSizeSettable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.windowFrameReadable" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.policy" && $0["status"] as? String == "pass" })
    }

    func testWorkflowRunDryRunRaiseWindowReturnsStructuredCommandWithoutRaising() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window raising.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for raise dry-run.")
        }
        let actions = firstWindow["actions"] as? [String] ?? []
        guard actions.contains(kAXRaiseAction as String) else {
            throw XCTSkip("The current Accessibility window does not expose AXRaise.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-raise-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "raise-window")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "raise-window",
            "--pid", "\(pid)",
            "--element", elementID,
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }

    func testWorkflowRunDryRunSetWindowFrameReturnsStructuredCommandWithoutMovingWindow() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility permission is required to preflight window frame changes.")
        }
        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for frame dry-run.")
        }
        let settableAttributes = firstWindow["settableAttributes"] as? [String] ?? []
        guard settableAttributes.contains(kAXPositionAttribute as String),
              settableAttributes.contains(kAXSizeAttribute as String),
              firstWindow["frame"] as? [String: Any] != nil else {
            throw XCTSkip("The current Accessibility window does not expose settable, readable geometry.")
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-desktop-frame-dry-run-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10",
            "--y", "20",
            "--width", "640",
            "--height", "480",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "set-window-frame")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "desktop", "set-window-frame",
            "--pid", "\(pid)",
            "--element", elementID,
            "--x", "10.0",
            "--y", "20.0",
            "--width", "640.0",
            "--height", "480.0",
            "--timeout-ms", "2000",
            "--interval-ms", "100",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: auditLog.path))
    }
}
