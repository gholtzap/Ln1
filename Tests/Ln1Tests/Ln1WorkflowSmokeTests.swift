import AppKit
import Foundation
import XCTest

final class Ln1WorkflowSmokeTests: Ln1TestCase {
    func testDoctorReturnsReadinessChecksWithRemediation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-doctor-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Doctor Page",
            "url": "https://example.com"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "doctor",
            "--endpoint", directory.path,
            "--audit-log", auditLog.path,
            "--timeout-ms", "500"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])
        let checkByName = Dictionary(uniqueKeysWithValues: checks.compactMap { check -> (String, [String: Any])? in
            guard let name = check["name"] as? String else {
                return nil
            }
            return (name, check)
        })

        XCTAssertNotNil(object["status"] as? String)
        XCTAssertNotNil(object["ready"] as? Bool)
        XCTAssertEqual(checkByName["accessibility"]?["required"] as? Bool, true)
        XCTAssertEqual(checkByName["desktop.windowMetadata"]?["required"] as? Bool, true)
        XCTAssertEqual(checkByName["auditLog.writeability"]?["status"] as? String, "pass")
        XCTAssertEqual(checkByName["clipboard.metadata"]?["status"] as? String, "pass")
        XCTAssertEqual(checkByName["browser.devTools"]?["status"] as? String, "pass")
        XCTAssertEqual(checkByName["browser.devTools"]?["required"] as? Bool, false)
    }

    func testWorkflowPreflightReportsInspectActiveAppBlockersAndNextCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-active-app"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-active-app")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertNotNil(object["canProceed"] as? Bool)
        XCTAssertNotNil(object["blockers"] as? [String])
        XCTAssertFalse(prerequisites.isEmpty)
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" })
        XCTAssertNotNil(object["nextCommand"] as? String)
    }

    func testWorkflowPreflightReviewAuditBuildsBoundedAuditCommand() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-review-audit-\(UUID().uuidString)")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: auditLog)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "review-audit",
            "--id", "audit-1",
            "--command", "files.move",
            "--code", "moved",
            "--limit", "3",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "review-audit")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.auditLogReadability" && $0["status"] as? String == "pass" })
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "audit",
            "--limit", "3",
            "--id", "audit-1",
            "--command", "files.move",
            "--code", "moved",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightInspectMenuRejectsMissingAppTarget() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-menu",
            "--pid", "-1",
            "--depth", "1",
            "--max-children", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-menu")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, false)
        XCTAssertTrue(blockers.contains("workflow.appTarget"))
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "fail" })
    }

    func testWorkflowPreflightInspectMenuBuildsStateMenuCommand() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let apps = try runLn1(["apps", "--all"])
        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        guard let active = records.first(where: { $0["active"] as? Bool == true }),
              let pid = active["pid"] as? Int else {
            throw XCTSkip("No active app record was available from macOS.")
        }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-menu",
            "--pid", "\(pid)",
            "--depth", "1",
            "--max-children", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-menu")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "state", "menu",
            "--pid", "\(pid)",
            "--depth", "1",
            "--max-children", "5"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "accessibility" && $0["status"] as? String == "pass" })
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "workflow.appTarget" && $0["status"] as? String == "pass" })
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

    func testWorkflowPreflightInspectInstalledAppsReturnsInventoryCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-installed-apps",
            "--bundle-id", "com.apple.finder",
            "--limit", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-installed-apps")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "installed",
            "--limit", "5",
            "--bundle-id", "com.apple.finder"
        ])
    }

    func testWorkflowPreflightInspectAppsBuildsRunningAppsCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-apps",
            "--all",
            "--limit", "12"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-apps")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "list",
            "--limit", "12",
            "--all"
        ])
    }

    func testWorkflowPreflightInspectFrontmostAppBuildsActiveAppCommand() throws {
        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-frontmost-app"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-frontmost-app")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "apps", "active"
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

    func testWorkflowRunDryRunReportsWouldExecuteWithoutExecutingMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "move-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "move-file")
        XCTAssertEqual(object["mode"] as? String, "dry-run")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["wouldExecute"] as? Bool, true)
        XCTAssertEqual(object["executed"] as? Bool, false)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertTrue((object["message"] as? String)?.contains("Dry run only") == true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
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

    func testWorkflowRunExecutesNonMutatingInstalledAppsInspectAndCapturesJSON() throws {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder") != nil else {
            throw XCTSkip("Finder application bundle was not available from LaunchServices.")
        }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-installed-apps",
            "--bundle-id", "com.apple.finder",
            "--limit", "5",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let apps = try XCTUnwrap(outputJSON["apps"] as? [[String: Any]])
        let first = try XCTUnwrap(apps.first)

        XCTAssertEqual(object["operation"] as? String, "inspect-installed-apps")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "installed",
            "--limit", "5",
            "--bundle-id", "com.apple.finder"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["limit"] as? Int, 5)
        XCTAssertEqual(first["bundleIdentifier"] as? String, "com.apple.finder")
        XCTAssertNotNil(first["path"] as? String)
    }

    func testWorkflowRunExecutesNonMutatingRunningAppsInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-apps-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-apps",
            "--limit", "10",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let apps = try XCTUnwrap(outputJSON["apps"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "inspect-apps")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "list",
            "--limit", "10"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertEqual(outputJSON["limit"] as? Int, 10)
        XCTAssertEqual(outputJSON["count"] as? Int, apps.count)
        XCTAssertLessThanOrEqual(apps.count, 10)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesNonMutatingFrontmostAppInspectAndCapturesJSON() throws {
        let workflowLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-frontmost-app-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: workflowLog) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-frontmost-app",
            "--workflow-log", workflowLog.path,
            "--dry-run", "false"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-frontmost-app")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "apps", "active"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["platform"] as? String, "macOS")
        XCTAssertNotNil(outputJSON["found"] as? Bool)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
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

    func testWorkflowRunCapsExecutionOutputAndSkipsTruncatedJSONParsing() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-cap-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        let targets = (0..<25).map { index in
            """
              {
                "id": "page-\(index)",
                "type": "page",
                "title": "Workflow Page \(index) \(String(repeating: "x", count: 80))",
                "url": "https://example.com/workflow/\(index)"
              }
            """
        }.joined(separator: ",\n")
        try "[\n\(targets)\n]".write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-browser",
            "--endpoint", directory.path,
            "--dry-run", "false",
            "--max-output-bytes", "200"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])

        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(execution["maxOutputBytes"] as? Int, 200)
        XCTAssertEqual(execution["stdoutTruncated"] as? Bool, true)
        XCTAssertGreaterThan(execution["stdoutBytes"] as? Int ?? 0, 200)
        XCTAssertEqual((execution["stdout"] as? String)?.utf8.count, 200)
        XCTAssertNil(execution["outputJSON"])
    }

    func testWorkflowRunTimesOutLongNonMutatingWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-timeout-\(UUID().uuidString)")
        let missingPath = directory.appendingPathComponent("missing.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "wait-file",
            "--path", missingPath.path,
            "--exists", "true",
            "--wait-timeout-ms", "5000",
            "--interval-ms", "100",
            "--dry-run", "false",
            "--run-timeout-ms", "250",
            "--max-output-bytes", "5000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "wait-file")
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(execution["timeoutMilliseconds"] as? Int, 250)
        XCTAssertEqual(execution["timedOut"] as? Bool, true)
        XCTAssertNotEqual(execution["exitCode"] as? Int, 0)
        XCTAssertNil(execution["outputJSON"])
    }

    func testWorkflowRunWritesTranscriptAndWorkflowLogReadsIt() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-log-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Workflow Log Page",
            "url": "https://example.com/workflow-log"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let run = try runLn1([
            "workflow",
            "run",
            "--operation", "read-browser",
            "--endpoint", directory.path,
            "--dry-run", "false",
            "--workflow-log", workflowLog.path,
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(run.status, 0, run.stderr)
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
        let runObject = try decodeJSONObject(run.stdout)
        let transcriptID = try XCTUnwrap(runObject["transcriptID"] as? String)
        XCTAssertEqual(runObject["transcriptPath"] as? String, workflowLog.path)

        let denied = try runLn1([
            "workflow",
            "log",
            "--workflow-log", workflowLog.path
        ])

        XCTAssertNotEqual(denied.status, 0)
        XCTAssertTrue(denied.stderr.contains("policy denied"))

        let log = try runLn1([
            "workflow",
            "log",
            "--workflow-log", workflowLog.path,
            "--operation", "read-browser",
            "--limit", "5",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(log.status, 0, log.stderr)
        let logObject = try decodeJSONObject(log.stdout)
        let entries = try XCTUnwrap(logObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let execution = try XCTUnwrap(entry["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])

        XCTAssertEqual(logObject["path"] as? String, workflowLog.path)
        XCTAssertEqual(logObject["operation"] as? String, "read-browser")
        XCTAssertEqual(logObject["count"] as? Int, 1)
        XCTAssertEqual(entry["transcriptID"] as? String, transcriptID)
        XCTAssertEqual(entry["operation"] as? String, "read-browser")
        XCTAssertEqual(entry["executed"] as? Bool, true)
        XCTAssertEqual(outputJSON["count"] as? Int, 1)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-browser",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let resumeObject = try decodeJSONObject(resume.stdout)
        let latest = try XCTUnwrap(resumeObject["latest"] as? [String: Any])

        XCTAssertEqual(resumeObject["path"] as? String, workflowLog.path)
        XCTAssertEqual(resumeObject["operation"] as? String, "read-browser")
        XCTAssertEqual(resumeObject["status"] as? String, "completed")
        XCTAssertEqual(resumeObject["transcriptID"] as? String, transcriptID)
        XCTAssertEqual(resumeObject["latestOperation"] as? String, "read-browser")
        let expectedEndpoint = try XCTUnwrap(outputJSON["endpoint"] as? String)
        XCTAssertEqual(resumeObject["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "read-browser",
            "--endpoint", expectedEndpoint,
            "--id", "page-1",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((resumeObject["message"] as? String)?.contains("DOM inspection") == true)
        XCTAssertEqual(latest["transcriptID"] as? String, transcriptID)
    }

    func testWorkflowRunRequiresExplicitApprovalForMutatingExecutionMode() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run reject \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "move-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--dry-run", "false"
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.stderr.contains("workflow run mutating execution requires --execute-mutating true"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowRunExecutesMutatingMoveWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run execute move \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "move-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "Verify approved workflow mutation"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "move-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Verify approved workflow mutation"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["action"] as? String, "filesystem.move")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertTrue((object["message"] as? String)?.contains("mutating command") == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: auditLog.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesMutatingDuplicateWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run execute duplicate \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("copy file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "duplicate-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "Verify approved workflow duplication"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "duplicate-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "duplicate",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Verify approved workflow duplication"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["action"] as? String, "filesystem.duplicate")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertTrue((object["message"] as? String)?.contains("mutating command") == true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: auditLog.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesMutatingCreateDirectoryWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run execute create directory \(UUID().uuidString)")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "create-directory",
            "--path", created.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "Verify approved workflow directory creation"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "create-directory")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "mkdir",
            "--path", created.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Verify approved workflow directory creation"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["action"] as? String, "filesystem.createDirectory")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertTrue((object["message"] as? String)?.contains("mutating command") == true)

        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: created.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertTrue(FileManager.default.fileExists(atPath: auditLog.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

    func testWorkflowRunExecutesMutatingRollbackWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow run execute rollback \(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "restore through workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "move before workflow rollback execution",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(move.status, 0, move.stderr)
        let moveObject = try decodeJSONObject(move.stdout)
        let moveAuditID = try XCTUnwrap(moveObject["auditID"] as? String)

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "rollback-file-move",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "Verify approved workflow rollback"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "rollback-file-move")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "rollback",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Verify approved workflow rollback"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["action"] as? String, "filesystem.rollbackMove")
        XCTAssertEqual(outputJSON["rollbackOfAuditID"] as? String, moveAuditID)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertTrue((object["message"] as? String)?.contains("mutating command") == true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: source, encoding: .utf8), "restore through workflow")
        XCTAssertTrue(FileManager.default.fileExists(atPath: auditLog.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflowLog.path))
    }

}
