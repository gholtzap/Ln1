import AppKit
import Foundation
import XCTest

final class Ln1SmokeTests: XCTestCase {
    func testPolicyCommandReturnsKnownActionRiskClassifications() throws {
        let result = try runLn1(["policy"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let riskLevels = try XCTUnwrap(object["riskLevels"] as? [String])
        let actions = try XCTUnwrap(object["actions"] as? [[String: Any]])
        let actionByName = Dictionary(uniqueKeysWithValues: actions.compactMap { action -> (String, [String: Any])? in
            guard let name = action["name"] as? String else {
                return nil
            }
            return (name, action)
        })

        XCTAssertEqual(object["defaultAllowedRisk"] as? String, "low")
        XCTAssertEqual(riskLevels, ["low", "medium", "high", "unknown"])
        XCTAssertEqual(actionByName["apps.list"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.list"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.list"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.plan"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.plan"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["apps.plan"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["apps.activate"]?["domain"] as? String, "apps")
        XCTAssertEqual(actionByName["apps.activate"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["apps.activate"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["desktop.listWindows"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.search"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.search"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.watch"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.watch"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.plan"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.plan"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.tailText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.tailText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.tailText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readLines"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readLines"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readLines"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readJSON"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.readPropertyList"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.writeText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.writeText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.writeText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.appendText"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.appendText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.appendText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.move"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.move"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.createDirectory"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["clipboard.state"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.state"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["clipboard.state"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.wait"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.wait"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["clipboard.wait"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.readText"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["clipboard.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["clipboard.writeText"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.writeText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["clipboard.writeText"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.listTabs"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.listTabs"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.listTabs"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.inspectTab"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.inspectTab"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.inspectTab"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readText"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.readDOM"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.readDOM"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.readDOM"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.fillFormField"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.fillFormField"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.fillFormField"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.selectOption"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.selectOption"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.selectOption"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.setChecked"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.setChecked"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.setChecked"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.focusElement"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.focusElement"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.focusElement"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.pressKey"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.pressKey"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.pressKey"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.clickElement"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.clickElement"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.clickElement"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.navigate"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.navigate"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.navigate"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["browser.waitURL"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitURL"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitURL"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitSelector"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitSelector"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitSelector"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitCount"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitCount"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitCount"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitText"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitElementText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitElementText"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitElementText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitValue"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitValue"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitValue"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitReady"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitReady"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitReady"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitTitle"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitTitle"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitTitle"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitChecked"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitChecked"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitChecked"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitEnabled"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitFocus"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitFocus"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitFocus"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitAttribute"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["task.memoryStart"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryStart"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryStart"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryRecord"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryRecord"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryRecord"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryFinish"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryFinish"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryFinish"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["task.memoryShow"]?["domain"] as? String, "task")
        XCTAssertEqual(actionByName["task.memoryShow"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["task.memoryShow"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["workflow.logRead"]?["domain"] as? String, "workflow")
        XCTAssertEqual(actionByName["workflow.logRead"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["workflow.logRead"]?["mutates"] as? Bool, false)
    }

    func testDesktopWindowsReturnsStructuredVisibleWindowInventory() throws {
        let result = try runLn1([
            "desktop",
            "windows",
            "--limit", "25"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let windows = try XCTUnwrap(object["windows"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["available"] as? Bool)
        XCTAssertNotNil(object["message"] as? String)
        XCTAssertEqual(object["includeDesktop"] as? Bool, false)
        XCTAssertEqual(object["includeAllLayers"] as? Bool, false)
        XCTAssertEqual(object["limit"] as? Int, 25)
        XCTAssertEqual(object["count"] as? Int, windows.count)
        XCTAssertLessThanOrEqual(windows.count, 25)

        if let first = windows.first {
            XCTAssertNotNil(first["id"] as? String)
            let stableIdentity = try XCTUnwrap(first["stableIdentity"] as? [String: Any])
            XCTAssertNotNil(stableIdentity["id"] as? String)
            XCTAssertEqual(stableIdentity["kind"] as? String, "desktopWindow")
            XCTAssertNotNil(stableIdentity["confidence"] as? String)
            XCTAssertNotNil(stableIdentity["label"] as? String)
            XCTAssertNotNil(stableIdentity["components"] as? [String: String])
            XCTAssertNotNil(stableIdentity["reasons"] as? [String])
            XCTAssertNotNil(first["windowNumber"] as? Int)
            XCTAssertNotNil(first["ownerPID"] as? Int)
            XCTAssertNotNil(first["active"] as? Bool)
            XCTAssertNotNil(first["layer"] as? Int)
            if let bounds = first["bounds"] as? [String: Any] {
                XCTAssertNotNil(bounds["x"] as? Double)
                XCTAssertNotNil(bounds["y"] as? Double)
                XCTAssertNotNil(bounds["width"] as? Double)
                XCTAssertNotNil(bounds["height"] as? Double)
            }
        }
    }

    func testObserveReturnsStructuredFirstStepSnapshot() throws {
        let result = try runLn1([
            "observe",
            "--app-limit", "5",
            "--window-limit", "3"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let accessibility = try XCTUnwrap(object["accessibility"] as? [String: Any])
        let apps = try XCTUnwrap(object["apps"] as? [[String: Any]])
        let desktop = try XCTUnwrap(object["desktop"] as? [String: Any])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])
        let suggestedActions = try XCTUnwrap(object["suggestedActions"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["appLimit"] as? Int, 5)
        XCTAssertLessThanOrEqual(apps.count, 5)
        XCTAssertEqual(object["appCount"] as? Int, apps.count)
        XCTAssertNotNil(object["appsTruncated"] as? Bool)
        XCTAssertNotNil(accessibility["trusted"] as? Bool)
        XCTAssertNotNil(accessibility["message"] as? String)
        XCTAssertEqual(desktop["limit"] as? Int, 3)
        XCTAssertNotNil(desktop["available"] as? Bool)
        XCTAssertNotNil(blockers)
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "desktop.listWindows" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "apps.list" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "clipboard.state" })
        XCTAssertTrue(suggestedActions.contains { $0["name"] as? String == "clipboard.wait" })
    }

    func testAppsPlanPreflightsActivationWithoutChangingFocus() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let result = try runLn1([
            "apps",
            "plan",
            "--operation", "activate",
            "--pid", "\(pid)"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let target = try XCTUnwrap(object["target"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "activate")
        XCTAssertEqual(object["action"] as? String, "apps.activate")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(object["canExecute"] as? Bool, false)
        XCTAssertEqual(target["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetRunning" })
        XCTAssertTrue(checks.contains { $0["name"] as? String == "apps.targetActivatable" })
    }

    func testAppsActivatePolicyDenialIsAuditedWithoutChangingFocus() throws {
        let apps = try runLn1(["apps"])

        XCTAssertEqual(apps.status, 0, apps.stderr)
        let records = try XCTUnwrap(try decodeJSON(apps.stdout) as? [[String: Any]])
        let first = try XCTUnwrap(records.first)
        let pid = try XCTUnwrap(first["pid"] as? Int)

        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-app-activate-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "apps",
            "activate",
            "--pid", "\(pid)",
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let app = try XCTUnwrap(entry["app"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "apps.activate")
        XCTAssertEqual(entry["action"] as? String, "apps.activate")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(app["pid"] as? Int, pid)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

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

    func testWorkflowPreflightMoveFileUsesFilesystemPlanChecks() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("destination.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "move-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let prerequisites = try XCTUnwrap(object["prerequisites"] as? [[String: Any]])
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "move-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(object["canProceed"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertTrue((object["nextCommand"] as? String)?.contains("Ln1 files move") == true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "filesystem.sourceExists" && $0["status"] as? String == "pass" })
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowPreflightWaitFileForwardsMetadataExpectations() throws {
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-report-\(UUID().uuidString).pdf")
            .path
        let digest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "wait-file",
            "--path", path,
            "--exists", "true",
            "--size-bytes", "5",
            "--digest", digest.uppercased(),
            "--max-file-bytes", "10",
            "--wait-timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "wait-file")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "wait",
            "--path", path,
            "--exists", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--size-bytes", "5",
            "--digest", digest,
            "--algorithm", "sha256",
            "--max-file-bytes", "10"
        ])
    }

    func testWorkflowPreflightChecksumFileValidatesBoundedRegularFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-checksum-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "checksum-file",
            "--path", file.path,
            "--algorithm", "SHA256",
            "--max-file-bytes", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "checksum-file")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "checksum",
            "--path", file.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "10"
        ])
    }

    func testWorkflowPreflightCompareFilesValidatesBoundedRegularFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-compare-preflight-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: left, atomically: true, encoding: .utf8)
        try "hello".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "compare-files",
            "--path", left.path,
            "--to", right.path,
            "--algorithm", "SHA256",
            "--max-file-bytes", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "compare-files")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "compare",
            "--path", left.path,
            "--to", right.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "10"
        ])
    }

    func testWorkflowPreflightInspectFileValidatesExistingPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-inspect-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "inspect-file",
            "--path", file.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "inspect-file")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", file.path
        ])
    }

    func testWorkflowPreflightReadFileValidatesBoundedTextRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello file".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "read-file",
            "--path", file.path,
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "read-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "read-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--reason", "Inspect file text",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightTailFileValidatesBoundedTailRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-tail-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello file".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "tail-file",
            "--path", file.path,
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "tail-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "tail-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--reason", "Inspect file tail text",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightReadFileLinesBuildsBoundedLineRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-lines-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "one\ntwo\nthree".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "read-file-lines",
            "--path", file.path,
            "--start-line", "2",
            "--line-count", "1",
            "--max-line-characters", "12",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "read-file-lines")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "read-lines",
            "--path", file.path,
            "--allow-risk", "medium",
            "--start-line", "2",
            "--line-count", "1",
            "--max-line-characters", "12",
            "--max-file-bytes", "100",
            "--reason", "Inspect file line range",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightReadFileJSONBuildsBoundedJSONRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-json-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try #"{"items":[{"name":"one"}]}"#.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "read-file-json",
            "--path", file.path,
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "read-file-json")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "read-json",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "100",
            "--reason", "Inspect JSON file value",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightReadFilePlistBuildsBoundedPropertyListRead() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-plist-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.plist")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let plist: [String: Any] = [
            "items": [
                ["name": "one"]
            ]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: file)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "read-file-plist",
            "--path", file.path,
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "500",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "read-file-plist")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "read-plist",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "500",
            "--reason", "Inspect property list file value",
            "--audit-log", auditLog.path
        ])
    }

    func testWorkflowPreflightWriteFileBuildsVerifiedWriteCommand() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-write-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("created.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "write-file",
            "--path", file.path,
            "--text", "hello",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "write-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "write-text",
            "--path", file.path,
            "--text", "hello",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowPreflightWriteFileRequiresOverwriteForExistingPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-write-overwrite-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("existing.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "old".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let blocked = try runLn1([
            "workflow",
            "preflight",
            "--operation", "write-file",
            "--path", file.path,
            "--text", "new",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(blocked.status, 0, blocked.stderr)
        let blockedObject = try decodeJSONObject(blocked.stdout)
        XCTAssertEqual(blockedObject["canProceed"] as? Bool, false)
        XCTAssertTrue((blockedObject["blockers"] as? [String])?.contains("workflow.destinationOverwrite") == true)

        let allowed = try runLn1([
            "workflow",
            "preflight",
            "--operation", "write-file",
            "--path", file.path,
            "--text", "new",
            "--overwrite",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(allowed.status, 0, allowed.stderr)
        let allowedObject = try decodeJSONObject(allowed.stdout)
        XCTAssertEqual(allowedObject["canProceed"] as? Bool, true)
        XCTAssertEqual(allowedObject["nextArguments"] as? [String], [
            "Ln1", "files", "write-text",
            "--path", file.path,
            "--text", "new",
            "--allow-risk", "medium",
            "--overwrite",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowPreflightAppendFileBuildsAppendCommand() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-append-preflight-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("existing.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "old".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "append-file",
            "--path", file.path,
            "--text", "\nnew",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "append-file")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "append-text",
            "--path", file.path,
            "--text", "\nnew",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowPreflightAppendFileRequiresCreateForMissingPath() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-append-create-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("created.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let blocked = try runLn1([
            "workflow",
            "preflight",
            "--operation", "append-file",
            "--path", file.path,
            "--text", "created",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(blocked.status, 0, blocked.stderr)
        let blockedObject = try decodeJSONObject(blocked.stdout)
        XCTAssertEqual(blockedObject["canProceed"] as? Bool, false)
        XCTAssertTrue((blockedObject["blockers"] as? [String])?.contains("workflow.destinationCreate") == true)

        let allowed = try runLn1([
            "workflow",
            "preflight",
            "--operation", "append-file",
            "--path", file.path,
            "--text", "created",
            "--create",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(allowed.status, 0, allowed.stderr)
        let allowedObject = try decodeJSONObject(allowed.stdout)
        XCTAssertEqual(allowedObject["canProceed"] as? Bool, true)
        XCTAssertEqual(allowedObject["nextArguments"] as? [String], [
            "Ln1", "files", "append-text",
            "--path", file.path,
            "--text", "created",
            "--allow-risk", "medium",
            "--create",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
    }

    func testWorkflowPreflightListFilesValidatesReadableDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-list-preflight-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "list-files",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50",
            "--include-hidden"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "list-files")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "list",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50",
            "--include-hidden"
        ])
    }

    func testWorkflowPreflightSearchFilesForwardsBoundedSearchOptions() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-search-preflight-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "preflight",
            "--operation", "search-files",
            "--path", directory.path,
            "--query", "Needle",
            "--depth", "3",
            "--limit", "25",
            "--max-file-bytes", "1000",
            "--max-snippet-characters", "80",
            "--max-matches-per-file", "2",
            "--include-hidden",
            "--case-sensitive"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let blockers = try XCTUnwrap(object["blockers"] as? [String])

        XCTAssertEqual(object["operation"] as? String, "search-files")
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertTrue(blockers.isEmpty)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "search",
            "--path", directory.path,
            "--query", "Needle",
            "--depth", "3",
            "--limit", "25",
            "--max-file-bytes", "1000",
            "--max-snippet-characters", "80",
            "--max-matches-per-file", "2",
            "--include-hidden",
            "--case-sensitive"
        ])
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

    func testWorkflowNextReturnsStructuredArgvWithoutExecutingMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "move-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "move-file")
        XCTAssertEqual(object["ready"] as? Bool, true)
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
        XCTAssertTrue((command["display"] as? String)?.contains("'") == true)
        XCTAssertTrue((command["display"] as? String)?.contains("source file.txt") == true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowNextReturnsStructuredArgvWithoutExecutingDuplicate() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next duplicate \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("copy file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "duplicate-file",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "duplicate-file")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "duplicate",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowNextReturnsStructuredArgvWithoutCreatingDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next create directory \(UUID().uuidString)")
        let destination = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "create-directory",
            "--path", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "create-directory")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "mkdir",
            "--path", destination.path,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowNextReturnsStructuredArgvWithoutRollingBackMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next rollback \(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "rollback workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "move before workflow rollback",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(move.status, 0, move.stderr)
        let moveObject = try decodeJSONObject(move.stdout)
        let moveAuditID = try XCTUnwrap(moveObject["auditID"] as? String)

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "rollback-file-move",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "rollback-file-move")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "rollback",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "Describe intent"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowNextReturnsStructuredArgvWithoutWatchingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next watch \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "watch-file",
            "--path", directory.path,
            "--depth", "2",
            "--limit", "25",
            "--watch-timeout-ms", "500",
            "--interval-ms", "50",
            "--include-hidden"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "watch-file")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "watch",
            "--path", directory.path,
            "--depth", "2",
            "--limit", "25",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--include-hidden"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowNextReturnsStructuredArgvWithoutChecksummingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next checksum \(UUID().uuidString)")
        let file = directory.appendingPathComponent("source file.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "checksum".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "checksum-file",
            "--path", file.path,
            "--max-file-bytes", "20"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "checksum-file")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "checksum",
            "--path", file.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "20"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowNextReturnsStructuredArgvWithoutComparingFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next compare \(UUID().uuidString)")
        let left = directory.appendingPathComponent("left file.txt")
        let right = directory.appendingPathComponent("right file.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "compare".write(to: left, atomically: true, encoding: .utf8)
        try "compare".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "compare-files",
            "--path", left.path,
            "--to", right.path,
            "--max-file-bytes", "20"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "compare-files")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "compare",
            "--path", left.path,
            "--to", right.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "20"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowNextReturnsStructuredArgvWithoutInspectingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next inspect \(UUID().uuidString)")
        let file = directory.appendingPathComponent("source file.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "inspect".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "inspect-file",
            "--path", file.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-file")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "stat",
            "--path", file.path
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowNextReturnsStructuredArgvWithoutListingFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next list \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "list-files",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "list-files")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "list",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
    }

    func testWorkflowNextReturnsStructuredArgvWithoutSearchingFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1 workflow next search \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "next",
            "--operation", "search-files",
            "--path", directory.path,
            "--query", "needle",
            "--depth", "2",
            "--limit", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let preflight = try XCTUnwrap(object["preflight"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "search-files")
        XCTAssertEqual(object["ready"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "low")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "search",
            "--path", directory.path,
            "--query", "needle",
            "--depth", "2",
            "--limit", "10",
            "--max-file-bytes", "1048576",
            "--max-snippet-characters", "240",
            "--max-matches-per-file", "20"
        ])
        XCTAssertEqual(command["requiresReason"] as? Bool, false)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
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

    func testWorkflowRunExecutesNonMutatingFileReadAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-read-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("source.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow file text".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-file",
            "--path", file.path,
            "--max-characters", "8",
            "--max-file-bytes", "100",
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
        let outputFile = try XCTUnwrap(outputJSON["file"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "read-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "read-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "8",
            "--max-file-bytes", "100",
            "--reason", "Inspect file text",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputFile["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["text"] as? String, "workflow")
        XCTAssertEqual(outputJSON["textLength"] as? Int, 18)
        XCTAssertEqual(outputJSON["truncated"] as? Bool, true)
    }

    func testWorkflowRunExecutesNonMutatingFileTailAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-tail-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("source.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "line one\nline two\nline three".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "tail-file",
            "--path", file.path,
            "--max-characters", "10",
            "--max-file-bytes", "100",
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
        let outputFile = try XCTUnwrap(outputJSON["file"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "tail-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "tail-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "10",
            "--max-file-bytes", "100",
            "--reason", "Inspect file tail text",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputFile["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["text"] as? String, "line three")
        XCTAssertEqual(outputJSON["selection"] as? String, "suffix")
        XCTAssertEqual(outputJSON["textLength"] as? Int, 28)
        XCTAssertEqual(outputJSON["truncated"] as? Bool, true)
    }

    func testWorkflowRunExecutesNonMutatingFileLineReadAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-lines-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("source.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "line one\nline two\nline three".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-file-lines",
            "--path", file.path,
            "--start-line", "2",
            "--line-count", "1",
            "--max-line-characters", "8",
            "--max-file-bytes", "100",
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
        let outputFile = try XCTUnwrap(outputJSON["file"] as? [String: Any])
        let lines = try XCTUnwrap(outputJSON["lines"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "read-file-lines")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "read-lines",
            "--path", file.path,
            "--allow-risk", "medium",
            "--start-line", "2",
            "--line-count", "1",
            "--max-line-characters", "8",
            "--max-file-bytes", "100",
            "--reason", "Inspect file line range",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputFile["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["startLine"] as? Int, 2)
        XCTAssertEqual(outputJSON["returnedLineCount"] as? Int, 1)
        XCTAssertEqual(lines.first?["lineNumber"] as? Int, 2)
        XCTAssertEqual(lines.first?["text"] as? String, "line two")
        XCTAssertEqual(outputJSON["truncated"] as? Bool, true)
    }

    func testWorkflowRunExecutesNonMutatingFileJSONReadAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-json-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try #"{"items":[{"name":"one"}]}"#.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-file-json",
            "--path", file.path,
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "100",
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
        let outputFile = try XCTUnwrap(outputJSON["file"] as? [String: Any])
        let value = try XCTUnwrap(outputJSON["value"] as? [String: Any])
        let entries = try XCTUnwrap(value["entries"] as? [[String: Any]])
        let nameEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "name" })
        let nameValue = try XCTUnwrap(nameEntry["value"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "read-file-json")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "read-json",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "100",
            "--reason", "Inspect JSON file value",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputFile["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["pointer"] as? String, "/items/0")
        XCTAssertEqual(outputJSON["found"] as? Bool, true)
        XCTAssertEqual(outputJSON["valueType"] as? String, "object")
        XCTAssertEqual(nameValue["type"] as? String, "string")
        XCTAssertEqual(nameValue["value"] as? String, "one")
    }

    func testWorkflowRunExecutesNonMutatingFilePlistReadAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-plist-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.plist")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let plist: [String: Any] = [
            "items": [
                ["name": "one"]
            ]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: file)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "read-file-plist",
            "--path", file.path,
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "500",
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
        let outputFile = try XCTUnwrap(outputJSON["file"] as? [String: Any])
        let value = try XCTUnwrap(outputJSON["value"] as? [String: Any])
        let entries = try XCTUnwrap(value["entries"] as? [[String: Any]])
        let nameEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "name" })
        let nameValue = try XCTUnwrap(nameEntry["value"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "read-file-plist")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "read-plist",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/items/0",
            "--max-depth", "3",
            "--max-items", "4",
            "--max-string-characters", "12",
            "--max-file-bytes", "500",
            "--reason", "Inspect property list file value",
            "--audit-log", auditLog.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputFile["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["pointer"] as? String, "/items/0")
        XCTAssertEqual(outputJSON["found"] as? Bool, true)
        XCTAssertEqual(outputJSON["valueType"] as? String, "dictionary")
        XCTAssertEqual(outputJSON["format"] as? String, "binary")
        XCTAssertEqual(nameValue["type"] as? String, "string")
        XCTAssertEqual(nameValue["value"] as? String, "one")
    }

    func testWorkflowRunExecutesMutatingFileWriteWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-write-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("created.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "write-file",
            "--path", file.path,
            "--text", "workflow write",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "write workflow test",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "workflow write")
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let current = try XCTUnwrap(outputJSON["current"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "write-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "write-text",
            "--path", file.path,
            "--text", "workflow write",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "write workflow test"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["ok"] as? Bool, true)
        XCTAssertEqual(outputJSON["created"] as? Bool, true)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertNil(outputJSON["text"])
    }

    func testWorkflowRunExecutesMutatingFileAppendWithExplicitApprovalAndReason() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-append-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "first".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "append-file",
            "--path", file.path,
            "--text", "\nworkflow append",
            "--audit-log", auditLog.path,
            "--workflow-log", workflowLog.path,
            "--dry-run", "false",
            "--execute-mutating", "true",
            "--reason", "append workflow test",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "first\nworkflow append")
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let current = try XCTUnwrap(outputJSON["current"] as? [String: Any])
        let verification = try XCTUnwrap(outputJSON["verification"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "append-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["mutates"] as? Bool, true)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "append-text",
            "--path", file.path,
            "--text", "\nworkflow append",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "append workflow test"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["ok"] as? Bool, true)
        XCTAssertEqual(outputJSON["created"] as? Bool, false)
        XCTAssertEqual(outputJSON["appendedLength"] as? Int, 16)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertNil(outputJSON["text"])
    }

    func testWorkflowRunExecutesNonMutatingFileWatchAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-watch-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("created.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            try? "created".write(to: created, atomically: true, encoding: .utf8)
        }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "watch-file",
            "--path", directory.path,
            "--depth", "1",
            "--watch-timeout-ms", "3000",
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
        let events = try XCTUnwrap(outputJSON["events"] as? [[String: Any]])
        let event = try XCTUnwrap(events.first)

        XCTAssertEqual(object["operation"] as? String, "watch-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "watch",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "200",
            "--timeout-ms", "3000",
            "--interval-ms", "50"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["matched"] as? Bool, true)
        XCTAssertEqual(outputJSON["eventCount"] as? Int, 1)
        XCTAssertEqual(event["type"] as? String, "created")
        XCTAssertTrue((event["path"] as? String)?.hasSuffix("/created.txt") == true)
    }

    func testWorkflowRunExecutesNonMutatingFileChecksumAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-checksum-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "checksum-file",
            "--path", file.path,
            "--max-file-bytes", "10",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let fileObject = try XCTUnwrap(outputJSON["file"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "checksum-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "checksum",
            "--path", file.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "10"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(fileObject["path"] as? String, file.path)
        XCTAssertEqual(outputJSON["digest"] as? String, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertNil(outputJSON["contents"])
    }

    func testWorkflowRunExecutesNonMutatingFileCompareAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-compare-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: left, atomically: true, encoding: .utf8)
        try "hello".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "compare-files",
            "--path", left.path,
            "--to", right.path,
            "--max-file-bytes", "10",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let rightObject = try XCTUnwrap(outputJSON["right"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "compare-files")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "compare",
            "--path", left.path,
            "--to", right.path,
            "--algorithm", "sha256",
            "--max-file-bytes", "10"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(rightObject["path"] as? String, right.path)
        XCTAssertEqual(outputJSON["matched"] as? Bool, true)
        XCTAssertEqual(outputJSON["sameDigest"] as? Bool, true)
        XCTAssertNil(outputJSON["contents"])
    }

    func testWorkflowRunExecutesNonMutatingFileInspectAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-inspect-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "inspect-file",
            "--path", file.path,
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let root = try XCTUnwrap(outputJSON["root"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "inspect-file")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "stat",
            "--path", file.path
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(root["path"] as? String, file.path)
        XCTAssertEqual(root["kind"] as? String, "regularFile")
    }

    func testWorkflowRunExecutesNonMutatingFileListAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-list-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "list-files",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let entries = try XCTUnwrap(outputJSON["entries"] as? [[String: Any]])

        XCTAssertEqual(object["operation"] as? String, "list-files")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "list",
            "--path", directory.path,
            "--depth", "1",
            "--limit", "50"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertTrue((entries.first?["path"] as? String)?.hasSuffix("/hello.txt") == true)
    }

    func testWorkflowRunExecutesNonMutatingFileSearchAndCapturesJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-run-search-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("alpha.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "first\nneedle here\nlast".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "workflow",
            "run",
            "--operation", "search-files",
            "--path", directory.path,
            "--query", "needle",
            "--depth", "1",
            "--limit", "10",
            "--dry-run", "false",
            "--run-timeout-ms", "5000",
            "--max-output-bytes", "50000"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let command = try XCTUnwrap(object["command"] as? [String: Any])
        let execution = try XCTUnwrap(object["execution"] as? [String: Any])
        let outputJSON = try XCTUnwrap(execution["outputJSON"] as? [String: Any])
        let matches = try XCTUnwrap(outputJSON["matches"] as? [[String: Any]])
        let firstFile = try XCTUnwrap(matches.first?["file"] as? [String: Any])

        XCTAssertEqual(object["operation"] as? String, "search-files")
        XCTAssertEqual(object["mode"] as? String, "execute")
        XCTAssertEqual(object["dryRun"] as? Bool, false)
        XCTAssertEqual(object["executed"] as? Bool, true)
        XCTAssertEqual(object["mutates"] as? Bool, false)
        XCTAssertEqual(command["argv"] as? [String], [
            "Ln1", "files", "search",
            "--path", directory.path,
            "--query", "needle",
            "--depth", "1",
            "--limit", "10",
            "--max-file-bytes", "1048576",
            "--max-snippet-characters", "240",
            "--max-matches-per-file", "20"
        ])
        XCTAssertEqual(execution["exitCode"] as? Int, 0)
        XCTAssertEqual(outputJSON["query"] as? String, "needle")
        XCTAssertEqual(firstFile["name"] as? String, "alpha.txt")
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

    func testWorkflowResumeSuggestsDestinationStatAfterMoveFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-move-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let sourceURL = directory.appendingPathComponent("draft.txt")
        let destinationURL = directory.appendingPathComponent("archive/draft.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "move-file-transcript",
            "operation": "move-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "move",
                    "--path", sourceURL.path,
                    "--to", destinationURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Archive completed draft"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "filesystem.move",
                    "destination": [
                        "path": destinationURL.path,
                        "kind": "regularFile",
                        "sizeBytes": 42
                    ],
                    "verification": [
                        "ok": true,
                        "code": "moved_and_metadata_matched",
                        "message": "source path is gone, destination exists, and size matches original source"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "move-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "move-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", destinationURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("move completed") == true)
    }

    func testWorkflowResumeSuggestsDestinationStatAfterDuplicateFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-duplicate-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let sourceURL = directory.appendingPathComponent("draft.txt")
        let destinationURL = directory.appendingPathComponent("draft-copy.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "duplicate-file-transcript",
            "operation": "duplicate-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "duplicate",
                    "--path", sourceURL.path,
                    "--to", destinationURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Keep original before editing"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "filesystem.duplicate",
                    "destination": [
                        "path": destinationURL.path,
                        "kind": "regularFile",
                        "sizeBytes": 42
                    ],
                    "verification": [
                        "ok": true,
                        "code": "metadata_matched",
                        "message": "destination exists and size matches source"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "duplicate-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "duplicate-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", destinationURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("duplicate completed") == true)
    }

    func testWorkflowResumeSuggestsDirectoryStatAfterCreateDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-create-directory-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let createdURL = directory.appendingPathComponent("archive")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "create-directory-transcript",
            "operation": "create-directory",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "mkdir",
                    "--path", createdURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Prepare archive folder"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "filesystem.createDirectory",
                    "directory": [
                        "path": createdURL.path,
                        "kind": "directory"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "directory_exists",
                        "message": "directory exists at requested path"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "create-directory",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "create-directory")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", createdURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("directory creation completed") == true)
    }

    func testWorkflowResumeSuggestsRestoredSourceStatAfterRollbackFileMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-rollback-file-move-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let sourceURL = directory.appendingPathComponent("draft.txt")
        let destinationURL = directory.appendingPathComponent("archive.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "rollback-file-move-transcript",
            "operation": "rollback-file-move",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "rollback",
                    "--audit-id", "move-audit-id",
                    "--allow-risk", "medium",
                    "--reason", "Undo mistaken move"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "action": "filesystem.rollbackMove",
                    "rollbackOfAuditID": "move-audit-id",
                    "restoredSource": [
                        "path": sourceURL.path,
                        "kind": "regularFile",
                        "sizeBytes": 42
                    ],
                    "previousDestination": [
                        "path": destinationURL.path,
                        "exists": false
                    ],
                    "verification": [
                        "ok": true,
                        "code": "move_restored",
                        "message": "original source restored and moved destination removed"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "rollback-file-move",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "rollback-file-move")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", sourceURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("rollback completed") == true)
    }

    func testWorkflowResumeSuggestsFileStatAfterWatchFileEvent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-watch-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let createdURL = directory.appendingPathComponent("created.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "watch-file-transcript",
            "operation": "watch-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "watch",
                    "--path", directory.path,
                    "--depth", "1",
                    "--timeout-ms", "5000"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "matched": true,
                    "events": [
                        [
                            "id": "created:\(createdURL.path)",
                            "type": "created",
                            "path": createdURL.path,
                            "current": [
                                "path": createdURL.path,
                                "kind": "regularFile",
                                "sizeBytes": 7
                            ]
                        ]
                    ],
                    "eventCount": 1
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "watch-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "watch-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", createdURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file watch observed") == true)
    }

    func testWorkflowResumeSuggestsDigestWaitAfterChecksumFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-checksum-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let digest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        let transcript: [String: Any] = [
            "transcriptID": "checksum-file-transcript",
            "operation": "checksum-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "checksum",
                    "--path", fileURL.path,
                    "--algorithm", "sha256",
                    "--max-file-bytes", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile"
                    ],
                    "algorithm": "sha256",
                    "digest": digest,
                    "maxFileBytes": 10
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "checksum-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "checksum-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "wait-file",
            "--path", fileURL.path,
            "--exists", "true",
            "--digest", digest,
            "--algorithm", "sha256",
            "--max-file-bytes", "10",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file checksum completed") == true)
    }

    func testWorkflowResumeSuggestsRightStatAfterCompareFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-compare-files-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let leftURL = directory.appendingPathComponent("left.txt")
        let rightURL = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let digest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        let transcript: [String: Any] = [
            "transcriptID": "compare-files-transcript",
            "operation": "compare-files",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "compare",
                    "--path", leftURL.path,
                    "--to", rightURL.path,
                    "--algorithm", "sha256",
                    "--max-file-bytes", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "left": [
                        "path": leftURL.path,
                        "kind": "regularFile"
                    ],
                    "right": [
                        "path": rightURL.path,
                        "kind": "regularFile"
                    ],
                    "algorithm": "sha256",
                    "leftDigest": digest,
                    "rightDigest": digest,
                    "sameSize": true,
                    "sameDigest": true,
                    "matched": true,
                    "maxFileBytes": 10
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "compare-files",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "compare-files")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", rightURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file compare matched") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterInspectFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-inspect-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "inspect-file-transcript",
            "operation": "inspect-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "stat",
                    "--path", fileURL.path
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "root": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "entries": []
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "inspect-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "inspect-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file inspection found") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterReadFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "read-file-transcript",
            "operation": "read-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "read-text",
                    "--path", fileURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Inspect file text"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "text": "hello",
                    "textLength": 5,
                    "textDigest": String(repeating: "c", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "read-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file text read completed") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterTailFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-tail-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "tail-file-transcript",
            "operation": "tail-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "tail-text",
                    "--path", fileURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Inspect file tail text"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "selection": "suffix",
                    "text": "tail",
                    "textLength": 4,
                    "textDigest": String(repeating: "d", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "tail-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "tail-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file tail text read completed") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterReadFileLines() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-file-lines-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "read-file-lines-transcript",
            "operation": "read-file-lines",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "read-lines",
                    "--path", fileURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Inspect file line range"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "startLine": 2,
                    "returnedLineCount": 1,
                    "textDigest": String(repeating: "e", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-file-lines",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "read-file-lines")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file line range read completed") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterReadFileJSON() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-file-json-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("config.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "read-file-json-transcript",
            "operation": "read-file-json",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "read-json",
                    "--path", fileURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Inspect JSON file value"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "found": true,
                    "valueType": "object",
                    "textDigest": String(repeating: "f", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-file-json",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "read-file-json")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("JSON file read completed") == true)
    }

    func testWorkflowResumeSuggestsChecksumAfterReadFilePlist() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-read-file-plist-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("config.plist")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "read-file-plist-transcript",
            "operation": "read-file-plist",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "read-plist",
                    "--path", fileURL.path,
                    "--allow-risk", "medium",
                    "--reason", "Inspect property list file value"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "file": [
                        "path": fileURL.path,
                        "kind": "regularFile",
                        "readable": true
                    ],
                    "found": true,
                    "valueType": "dictionary",
                    "digest": String(repeating: "f", count: 64),
                    "truncated": false
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "read-file-plist",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "read-file-plist")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "checksum-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("property list file read completed") == true)
    }

    func testWorkflowResumeSuggestsStatAfterWriteFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-write-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "write-file-transcript",
            "operation": "write-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "write-text",
                    "--path", fileURL.path,
                    "--text", "hello",
                    "--allow-risk", "medium",
                    "--reason", "write test"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "created": true,
                    "current": [
                        "path": fileURL.path,
                        "kind": "regularFile"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "text_matched"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "write-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "write-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", fileURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file text write completed") == true)
    }

    func testWorkflowResumeSuggestsStatAfterAppendFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-append-file-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "append-file-transcript",
            "operation": "append-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "append-text",
                    "--path", fileURL.path,
                    "--text", "hello",
                    "--allow-risk", "medium",
                    "--reason", "append test"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "ok": true,
                    "created": false,
                    "current": [
                        "path": fileURL.path,
                        "kind": "regularFile"
                    ],
                    "verification": [
                        "ok": true,
                        "code": "text_appended"
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "append-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "append-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", fileURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file text append completed") == true)
    }

    func testWorkflowResumeSuggestsInspectAfterListFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-list-files-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "list-files-transcript",
            "operation": "list-files",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "list",
                    "--path", directory.path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "root": [
                        "path": directory.path,
                        "kind": "directory"
                    ],
                    "entries": [
                        [
                            "path": fileURL.path,
                            "kind": "regularFile"
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
            "--operation", "list-files",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "list-files")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file listing completed") == true)
    }

    func testWorkflowResumeSuggestsInspectAfterSearchFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-search-files-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("alpha.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "search-files-transcript",
            "operation": "search-files",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "search",
                    "--path", directory.path,
                    "--query", "needle",
                    "--depth", "2",
                    "--limit", "10"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "root": [
                        "path": directory.path,
                        "kind": "directory"
                    ],
                    "matches": [
                        [
                            "file": [
                                "path": fileURL.path,
                                "kind": "regularFile",
                                "name": "alpha.txt"
                            ],
                            "matchedName": false,
                            "contentMatches": [
                                [
                                    "lineNumber": 2,
                                    "text": "needle"
                                ]
                            ]
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
            "--operation", "search-files",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "search-files")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "run",
            "--operation", "inspect-file",
            "--path", fileURL.path,
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file search completed") == true)
    }

    func testWorkflowResumeSuggestsFileStatAfterFileWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-file-wait-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let fileURL = directory.appendingPathComponent("report.pdf")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "wait-file-transcript",
            "operation": "wait-file",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "files", "wait",
                    "--path", fileURL.path,
                    "--exists", "true"
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "path": fileURL.path,
                    "expectedExists": true,
                    "matched": true,
                    "file": [
                        "path": fileURL.path,
                        "kind": "file",
                        "sizeBytes": 1024
                    ]
                ]
            ]
        ]
        try writeJSONObjectLine(transcript, to: workflowLog)

        let resume = try runLn1([
            "workflow",
            "resume",
            "--workflow-log", workflowLog.path,
            "--operation", "wait-file",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "wait-file")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "files", "stat",
            "--path", fileURL.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("file wait") == true)
    }

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
            "Ln1", "clipboard", "read-text",
            "--allow-risk", "medium",
            "--max-characters", "4096",
            "--reason", "Describe intent",
            "--pasteboard", "Ln1-test-pasteboard"
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("plain text metadata") == true)
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
            "Ln1", "clipboard", "read-text",
            "--allow-risk", "medium",
            "--max-characters", "4096",
            "--reason", "Describe intent",
            "--pasteboard", pasteboardName
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("clipboard inspection found plain text") == true)
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

    func testSchemaDocumentsStableAccessibilityElementIdentities() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let state = try XCTUnwrap(object["state"] as? [String: Any])
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        let firstWindow = try XCTUnwrap(windows.first)
        let stableIdentity = try XCTUnwrap(firstWindow["stableIdentity"] as? [String: Any])
        let components = try XCTUnwrap(stableIdentity["components"] as? [String: String])
        let reasons = try XCTUnwrap(stableIdentity["reasons"] as? [String])

        XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        XCTAssertEqual(stableIdentity["confidence"] as? String, "high")
        XCTAssertNotNil(stableIdentity["id"] as? String)
        XCTAssertNotNil(stableIdentity["label"] as? String)
        XCTAssertEqual(components["role"], "AXButton")
        XCTAssertEqual(components["title"], "save")
        XCTAssertTrue(reasons.contains("role"))
        XCTAssertTrue(reasons.contains("title"))
    }

    func testSchemaDocumentsIdentityGuardedPerformResults() throws {
        let result = try runLn1(["schema"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let perform = try XCTUnwrap(object["perform"] as? [String: Any])
        let resultObject = try XCTUnwrap(perform["result"] as? [String: Any])
        let stableIdentity = try XCTUnwrap(resultObject["stableIdentity"] as? [String: Any])
        let identityVerification = try XCTUnwrap(resultObject["identityVerification"] as? [String: Any])

        XCTAssertTrue((perform["command"] as? String)?.contains("--expect-identity") == true)
        XCTAssertTrue((perform["command"] as? String)?.contains("--min-identity-confidence medium") == true)
        XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["code"] as? String, "identity_verified")
        XCTAssertEqual(identityVerification["expectedID"] as? String, identityVerification["actualID"] as? String)
        XCTAssertEqual(identityVerification["minimumConfidence"] as? String, "medium")
        XCTAssertEqual(identityVerification["actualConfidence"] as? String, "high")
    }

    func testTaskMemoryRecordsTaskScopedEventsWithSensitiveSummaryRedaction() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-task-memory-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let start = try runLn1([
            "task",
            "start",
            "--title", "Verify download",
            "--summary", "Wait for report.pdf and compare checksum",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(start.status, 0, start.stderr)
        let startObject = try decodeJSONObject(start.stdout)
        let taskID = try XCTUnwrap(startObject["taskID"] as? String)
        let startEvents = try XCTUnwrap(startObject["events"] as? [[String: Any]])
        let started = try XCTUnwrap(startEvents.first)

        XCTAssertEqual(startObject["path"] as? String, memoryLog.path)
        XCTAssertEqual(startObject["status"] as? String, "active")
        XCTAssertEqual(startObject["title"] as? String, "Verify download")
        XCTAssertEqual(startObject["eventCount"] as? Int, 1)
        XCTAssertEqual(started["kind"] as? String, "task.started")
        XCTAssertEqual(started["summary"] as? String, "Wait for report.pdf and compare checksum")
        XCTAssertEqual(started["sensitivity"] as? String, "private")

        let record = try runLn1([
            "task",
            "record",
            "--task-id", taskID,
            "--kind", "verification",
            "--summary", "secret confirmation code 123456",
            "--sensitivity", "sensitive",
            "--related-audit-id", "audit-1",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(record.status, 0, record.stderr)
        let recordObject = try decodeJSONObject(record.stdout)
        let recordEvents = try XCTUnwrap(recordObject["events"] as? [[String: Any]])
        let verification = try XCTUnwrap(recordEvents.last)

        XCTAssertEqual(recordObject["eventCount"] as? Int, 2)
        XCTAssertEqual(verification["kind"] as? String, "task.verification")
        XCTAssertEqual(verification["sensitivity"] as? String, "sensitive")
        XCTAssertEqual(verification["summaryLength"] as? Int, 31)
        XCTAssertEqual(verification["summaryDigest"] as? String, "bfdc69fc2ce532ddd962d2d01bc9a5015890b303334f7c131ff6d5efc1172cae")
        XCTAssertEqual(verification["relatedAuditID"] as? String, "audit-1")
        XCTAssertNil(verification["summary"])

        let finish = try runLn1([
            "task",
            "finish",
            "--task-id", taskID,
            "--status", "completed",
            "--summary", "Download was verified.",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(finish.status, 0, finish.stderr)

        let show = try runLn1([
            "task",
            "show",
            "--task-id", taskID,
            "--limit", "2",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(show.status, 0, show.stderr)
        let showObject = try decodeJSONObject(show.stdout)
        let shownEvents = try XCTUnwrap(showObject["events"] as? [[String: Any]])

        XCTAssertEqual(showObject["status"] as? String, "completed")
        XCTAssertEqual(showObject["eventCount"] as? Int, 3)
        XCTAssertEqual(showObject["limit"] as? Int, 2)
        XCTAssertEqual(shownEvents.count, 2)
        XCTAssertEqual(shownEvents.first?["kind"] as? String, "task.verification")
        XCTAssertEqual(shownEvents.last?["kind"] as? String, "task.finished")
    }

    func testTaskMemoryRequiresMediumRiskBeforePersisting() throws {
        let memoryLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-task-memory-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let rejected = try runLn1([
            "task",
            "start",
            "--title", "Blocked task",
            "--summary", "should not be persisted",
            "--memory-log", memoryLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: memoryLog.path))
    }

    func testBrowserTabsReturnsStructuredDevToolsPageTargets() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-2",
            "type": "page",
            "title": "Second Page",
            "url": "https://example.com/second",
            "description": "",
            "webSocketDebuggerUrl": "ws://127.0.0.1/devtools/page/page-2",
            "devtoolsFrontendUrl": "/devtools/inspector.html?ws=127.0.0.1/page-2",
            "faviconUrl": "https://example.com/favicon.ico",
            "attached": false
          },
          {
            "id": "worker-1",
            "type": "service_worker",
            "title": "Worker",
            "url": "https://example.com/sw.js"
          },
          {
            "id": "page-1",
            "type": "page",
            "title": "First Page",
            "url": "https://example.com/first",
            "attached": true
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "tabs",
            "--endpoint", directory.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tabs = try XCTUnwrap(object["tabs"] as? [[String: Any]])
        let ids = Set(tabs.compactMap { $0["id"] as? String })
        let firstPage = try XCTUnwrap(tabs.first { $0["id"] as? String == "page-1" })
        let firstPageActions = try XCTUnwrap(firstPage["actions"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["includeNonPageTargets"] as? Bool, false)
        XCTAssertEqual(object["count"] as? Int, 2)
        XCTAssertTrue(ids.contains("page-1"))
        XCTAssertTrue(ids.contains("page-2"))
        XCTAssertFalse(ids.contains("worker-1"))
        XCTAssertEqual(firstPage["type"] as? String, "page")
        XCTAssertEqual(firstPage["title"] as? String, "First Page")
        XCTAssertEqual(firstPage["url"] as? String, "https://example.com/first")
        XCTAssertEqual(firstPage["attached"] as? Bool, true)
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.inspectTab"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.readText"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.readDOM"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.fillFormField"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.selectOption"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.setChecked"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.focusElement"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.pressKey"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.clickElement"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.navigate"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitURL"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitSelector"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitCount"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitText"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitElementText"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitValue"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitReady"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitTitle"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitChecked"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitEnabled"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitFocus"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitAttribute"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })

        let tabResult = try runLn1([
            "browser",
            "tab",
            "--endpoint", directory.path,
            "--id", "page-2"
        ])

        XCTAssertEqual(tabResult.status, 0, tabResult.stderr)
        let tabObject = try decodeJSONObject(tabResult.stdout)
        let tab = try XCTUnwrap(tabObject["tab"] as? [String: Any])
        XCTAssertEqual(tab["id"] as? String, "page-2")
        XCTAssertEqual(tab["webSocketDebuggerURL"] as? String, "ws://127.0.0.1/devtools/page/page-2")
        XCTAssertEqual(tab["devtoolsFrontendURL"] as? String, "/devtools/inspector.html?ws=127.0.0.1/page-2")
        XCTAssertEqual(tab["faviconURL"] as? String, "https://example.com/favicon.ico")
    }

    func testBrowserTextReadsPageTextWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-text-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        {
          "id": 1,
          "result": {
            "result": {
              "type": "string",
              "value": "Line one\\nLine two"
            }
          }
        }
        """.write(to: cdpResponse, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Readable Page",
            "url": "https://example.com/readable",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-characters", "11",
            "--audit-log", auditLog.path,
            "--reason", "read visible page text"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.readText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["text"] as? String, "Line one\nLi")
        XCTAssertEqual(object["textLength"] as? Int, 17)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxCharacters"] as? Int, 11)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertNil(object["contents"])

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.text",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.readText")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertNil(deniedBrowserTab["textLength"])
        XCTAssertNil(deniedBrowserTab["textDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.text",
            "--code", "read_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.text")
        XCTAssertEqual(entry["action"] as? String, "browser.readText")
        XCTAssertEqual(entry["reason"] as? String, "read visible page text")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Readable Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/readable")
        XCTAssertEqual(browserTab["textLength"] as? Int, 17)
        XCTAssertNotNil(browserTab["textDigest"])
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_text")
    }

    func testBrowserDOMReadsStructuredPageStateWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-dom-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let domSnapshot: [String: Any] = [
            "url": "https://example.com/form",
            "title": "Example Form",
            "elementCount": 4,
            "truncated": true,
            "elements": [
                [
                    "id": "dom.0",
                    "parentID": NSNull(),
                    "depth": 0,
                    "selector": "body",
                    "tagName": "body",
                    "role": NSNull(),
                    "text": "Welcome Search",
                    "textLength": 14,
                    "attributes": [:],
                    "inputType": NSNull(),
                    "checked": NSNull(),
                    "disabled": NSNull(),
                    "hasValue": NSNull(),
                    "valueLength": NSNull()
                ],
                [
                    "id": "dom.1",
                    "parentID": "dom.0",
                    "depth": 1,
                    "selector": "a[href=\"https://example.com/docs\"]",
                    "tagName": "a",
                    "role": "link",
                    "text": "Docs",
                    "textLength": 4,
                    "attributes": ["href": "https://example.com/docs"],
                    "inputType": NSNull(),
                    "checked": NSNull(),
                    "disabled": NSNull(),
                    "hasValue": NSNull(),
                    "valueLength": NSNull()
                ],
                [
                    "id": "dom.2",
                    "parentID": "dom.0",
                    "depth": 1,
                    "selector": "input[name=\"q\"]",
                    "tagName": "input",
                    "role": "textbox",
                    "text": NSNull(),
                    "textLength": 0,
                    "attributes": ["name": "q", "placeholder": "Search"],
                    "inputType": "search",
                    "checked": false,
                    "disabled": false,
                    "hasValue": true,
                    "valueLength": 6
                ],
                [
                    "id": "dom.3",
                    "parentID": "dom.0",
                    "depth": 1,
                    "selector": "button[aria-controls=\"menu-1\"]",
                    "tagName": "button",
                    "role": "button",
                    "text": "Menu",
                    "textLength": 4,
                    "attributes": [
                        "aria-controls": "menu-1",
                        "aria-expanded": "false",
                        "aria-pressed": "false"
                    ],
                    "inputType": NSNull(),
                    "checked": NSNull(),
                    "disabled": false,
                    "hasValue": NSNull(),
                    "valueLength": NSNull()
                ]
            ]
        ]
        let domData = try JSONSerialization.data(withJSONObject: domSnapshot, options: [.sortedKeys])
        let domJSONString = String(decoding: domData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": domJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "DOM Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "dom",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "dom",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-elements", "4",
            "--max-text-characters", "40",
            "--audit-log", auditLog.path,
            "--reason", "inspect form controls"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let elements = try XCTUnwrap(object["elements"] as? [[String: Any]])
        let link = try XCTUnwrap(elements.first { $0["id"] as? String == "dom.1" })
        let input = try XCTUnwrap(elements.first { $0["id"] as? String == "dom.2" })
        let button = try XCTUnwrap(elements.first { $0["id"] as? String == "dom.3" })
        let linkAttributes = try XCTUnwrap(link["attributes"] as? [String: Any])
        let inputAttributes = try XCTUnwrap(input["attributes"] as? [String: Any])
        let buttonAttributes = try XCTUnwrap(button["attributes"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.readDOM")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["url"] as? String, "https://example.com/form")
        XCTAssertEqual(object["title"] as? String, "Example Form")
        XCTAssertEqual(object["elementCount"] as? Int, 4)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxElements"] as? Int, 4)
        XCTAssertEqual(object["maxTextCharacters"] as? Int, 40)
        XCTAssertNotNil(object["digest"])
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(link["selector"] as? String, "a[href=\"https://example.com/docs\"]")
        XCTAssertEqual(link["role"] as? String, "link")
        XCTAssertEqual(link["text"] as? String, "Docs")
        XCTAssertEqual(linkAttributes["href"] as? String, "https://example.com/docs")
        XCTAssertEqual(input["selector"] as? String, "input[name=\"q\"]")
        XCTAssertEqual(input["role"] as? String, "textbox")
        XCTAssertEqual(input["inputType"] as? String, "search")
        XCTAssertEqual(input["hasValue"] as? Bool, true)
        XCTAssertEqual(input["valueLength"] as? Int, 6)
        XCTAssertNil(input["value"])
        XCTAssertEqual(inputAttributes["placeholder"] as? String, "Search")
        XCTAssertEqual(button["selector"] as? String, "button[aria-controls=\"menu-1\"]")
        XCTAssertEqual(button["role"] as? String, "button")
        XCTAssertEqual(buttonAttributes["aria-controls"] as? String, "menu-1")
        XCTAssertEqual(buttonAttributes["aria-expanded"] as? String, "false")
        XCTAssertEqual(buttonAttributes["aria-pressed"] as? String, "false")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.dom",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.readDOM")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertNil(deniedBrowserTab["domNodeCount"])
        XCTAssertNil(deniedBrowserTab["domDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.dom",
            "--code", "read_dom",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.dom")
        XCTAssertEqual(entry["action"] as? String, "browser.readDOM")
        XCTAssertEqual(entry["reason"] as? String, "inspect form controls")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["domNodeCount"] as? Int, 4)
        XCTAssertNotNil(browserTab["domDigest"])
        XCTAssertNil(browserTab["elements"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_dom")
    }

    func testBrowserFillSetsFormFieldWithPolicyVerificationAndRedactedAudit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-fill-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let fillPayload: [String: Any] = [
            "ok": true,
            "code": "filled",
            "message": "The matched form field was filled and verified.",
            "selector": "input[name='q']",
            "tagName": "input",
            "inputType": "search",
            "disabled": false,
            "readOnly": false,
            "valueLength": 14,
            "matched": true
        ]
        let fillData = try JSONSerialization.data(withJSONObject: fillPayload, options: [.sortedKeys])
        let fillJSONString = String(decoding: fillData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": fillJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Search Page",
            "url": "https://example.com/search",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "fill",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--text", "private search",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "fill",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--text", "private search",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "prepare search query"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.fillFormField")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["selector"] as? String, "input[name='q']")
        XCTAssertEqual(object["textLength"] as? Int, 14)
        XCTAssertEqual(object["textDigest"] as? String, "88fe3ede4a30aa7bf22d1e028e44abff6d94513d5a9f24f415377f0e4b6b6196")
        XCTAssertEqual(object["targetTagName"] as? String, "input")
        XCTAssertEqual(object["targetInputType"] as? String, "search")
        XCTAssertEqual(object["resultingValueLength"] as? Int, 14)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "value_matched")
        XCTAssertNil(object["textValue"])

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.fill",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.fillFormField")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["formSelector"] as? String, "input[name='q']")
        XCTAssertEqual(deniedBrowserTab["formTextLength"] as? Int, 14)
        XCTAssertEqual(deniedBrowserTab["formTextDigest"] as? String, "88fe3ede4a30aa7bf22d1e028e44abff6d94513d5a9f24f415377f0e4b6b6196")
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.fill",
            "--code", "filled",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.fill")
        XCTAssertEqual(entry["action"] as? String, "browser.fillFormField")
        XCTAssertEqual(entry["reason"] as? String, "prepare search query")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Search Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/search")
        XCTAssertEqual(browserTab["formSelector"] as? String, "input[name='q']")
        XCTAssertEqual(browserTab["formTextLength"] as? Int, 14)
        XCTAssertEqual(browserTab["formTextDigest"] as? String, "88fe3ede4a30aa7bf22d1e028e44abff6d94513d5a9f24f415377f0e4b6b6196")
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "value_matched")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "filled")
    }

    func testBrowserSelectSetsOptionWithPolicyVerificationAndRedactedAudit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-select-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let selectPayload: [String: Any] = [
            "ok": true,
            "code": "selected",
            "message": "The requested select option was selected.",
            "selector": "select[name='country']",
            "tagName": "select",
            "disabled": false,
            "optionCount": 3,
            "selectedIndex": 2,
            "selectedValueLength": 2,
            "selectedLabelLength": 6,
            "matched": true
        ]
        let selectData = try JSONSerialization.data(withJSONObject: selectPayload, options: [.sortedKeys])
        let selectJSONString = String(decoding: selectData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": selectJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Profile Page",
            "url": "https://example.com/profile",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "select",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "select[name='country']",
            "--value", "ca",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "select",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "select[name='country']",
            "--value", "ca",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "choose country"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.selectOption")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["selector"] as? String, "select[name='country']")
        XCTAssertEqual(object["requestedValueLength"] as? Int, 2)
        XCTAssertEqual(object["requestedValueDigest"] as? String, "6959097001d10501ac7d54c0bdb8db61420f658f2922cc26e46d536119a31126")
        XCTAssertNil(object["requestedLabelLength"])
        XCTAssertEqual(object["targetTagName"] as? String, "select")
        XCTAssertEqual(object["targetDisabled"] as? Bool, false)
        XCTAssertEqual(object["optionCount"] as? Int, 3)
        XCTAssertEqual(object["selectedIndex"] as? Int, 2)
        XCTAssertEqual(object["selectedValueLength"] as? Int, 2)
        XCTAssertEqual(object["selectedLabelLength"] as? Int, 6)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "option_selected")
        XCTAssertNil(object["value"])
        XCTAssertNil(object["label"])

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.select",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.selectOption")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["formSelector"] as? String, "select[name='country']")
        XCTAssertEqual(deniedBrowserTab["formTextLength"] as? Int, 2)
        XCTAssertEqual(deniedBrowserTab["formTextDigest"] as? String, "6959097001d10501ac7d54c0bdb8db61420f658f2922cc26e46d536119a31126")
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.select",
            "--code", "selected",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.select")
        XCTAssertEqual(entry["action"] as? String, "browser.selectOption")
        XCTAssertEqual(entry["reason"] as? String, "choose country")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Profile Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/profile")
        XCTAssertEqual(browserTab["formSelector"] as? String, "select[name='country']")
        XCTAssertEqual(browserTab["formTextLength"] as? Int, 2)
        XCTAssertEqual(browserTab["formTextDigest"] as? String, "6959097001d10501ac7d54c0bdb8db61420f658f2922cc26e46d536119a31126")
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "option_selected")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "selected")
    }

    func testBrowserCheckSetsCheckedStateWithPolicyVerificationAndAudit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-check-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let checkedPayload: [String: Any] = [
            "ok": true,
            "code": "checked",
            "message": "The requested checked state was applied.",
            "selector": "input[name='subscribe']",
            "tagName": "input",
            "inputType": "checkbox",
            "disabled": false,
            "readOnly": false,
            "requestedChecked": true,
            "currentChecked": true,
            "matched": true
        ]
        let checkedData = try JSONSerialization.data(withJSONObject: checkedPayload, options: [.sortedKeys])
        let checkedJSONString = String(decoding: checkedData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": checkedJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Preferences Page",
            "url": "https://example.com/preferences",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "check",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='subscribe']",
            "--checked", "true",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "check",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='subscribe']",
            "--checked", "true",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "enable subscription"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.setChecked")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["selector"] as? String, "input[name='subscribe']")
        XCTAssertEqual(object["requestedChecked"] as? Bool, true)
        XCTAssertEqual(object["targetTagName"] as? String, "input")
        XCTAssertEqual(object["targetInputType"] as? String, "checkbox")
        XCTAssertEqual(object["targetDisabled"] as? Bool, false)
        XCTAssertEqual(object["targetReadOnly"] as? Bool, false)
        XCTAssertEqual(object["currentChecked"] as? Bool, true)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "checked_matched")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.check",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.setChecked")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["formSelector"] as? String, "input[name='subscribe']")
        XCTAssertEqual(deniedBrowserTab["formChecked"] as? Bool, true)
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.check",
            "--code", "checked",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.check")
        XCTAssertEqual(entry["action"] as? String, "browser.setChecked")
        XCTAssertEqual(entry["reason"] as? String, "enable subscription")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Preferences Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/preferences")
        XCTAssertEqual(browserTab["formSelector"] as? String, "input[name='subscribe']")
        XCTAssertEqual(browserTab["formChecked"] as? Bool, true)
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "checked_matched")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "checked")
    }

    func testBrowserFocusRequiresPolicyVerifiesAndAuditsSelectorOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-focus-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let focusPayload: [String: Any] = [
            "ok": true,
            "code": "focused",
            "message": "The matched element received focus.",
            "selector": "input[name='q']",
            "tagName": "input",
            "inputType": "search",
            "disabled": false,
            "readOnly": false,
            "matched": true
        ]
        let focusData = try JSONSerialization.data(withJSONObject: focusPayload, options: [.sortedKeys])
        let focusJSONString = String(decoding: focusData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": focusJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Focus Page",
            "url": "https://example.com/focus",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "focus",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "focus",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "prepare keyboard input"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.focusElement")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["selector"] as? String, "input[name='q']")
        XCTAssertEqual(object["targetTagName"] as? String, "input")
        XCTAssertEqual(object["targetInputType"] as? String, "search")
        XCTAssertEqual(object["targetDisabled"] as? Bool, false)
        XCTAssertEqual(object["targetReadOnly"] as? Bool, false)
        XCTAssertEqual(object["activeElementMatched"] as? Bool, true)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "element_focused")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.focus",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.focusElement")
        XCTAssertEqual(deniedBrowserTab["focusSelector"] as? String, "input[name='q']")
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.focus",
            "--code", "focused",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.focus")
        XCTAssertEqual(entry["action"] as? String, "browser.focusElement")
        XCTAssertEqual(entry["reason"] as? String, "prepare keyboard input")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Focus Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/focus")
        XCTAssertEqual(browserTab["focusSelector"] as? String, "input[name='q']")
        XCTAssertEqual(browserTab["focusTagName"] as? String, "input")
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "element_focused")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "focused")
    }

    func testBrowserPressKeyRequiresPolicyDispatchesAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-press-key-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("key-response.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let keyPayload: [String: Any] = [
            "ok": true,
            "code": "key_pressed",
            "message": "browser key press dispatched through Chrome DevTools",
            "key": "Enter",
            "modifiers": ["control"],
            "modifierMask": 2,
            "selector": NSNull(),
            "keyDownDispatched": true,
            "keyUpDispatched": true
        ]
        let keyData = try JSONSerialization.data(withJSONObject: keyPayload, options: [.prettyPrinted, .sortedKeys])
        try keyData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Key Page",
            "url": "https://example.com/key",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "press-key",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--key", "Enter",
            "--modifiers", "control",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "press-key",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--key", "Enter",
            "--modifiers", "control",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "submit focused form"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.pressKey")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["key"] as? String, "Enter")
        XCTAssertEqual(object["modifiers"] as? [String], ["control"])
        XCTAssertEqual(object["modifierMask"] as? Int, 2)
        XCTAssertNil(object["selector"])
        XCTAssertNil(object["text"])
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "key_pressed")
        XCTAssertEqual(verification["keyDownDispatched"] as? Bool, true)
        XCTAssertEqual(verification["keyUpDispatched"] as? Bool, true)

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.press-key",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.pressKey")
        XCTAssertEqual(deniedBrowserTab["keyName"] as? String, "Enter")
        XCTAssertEqual(deniedBrowserTab["keyModifiers"] as? [String], ["control"])
        XCTAssertEqual(deniedBrowserTab["keyModifierMask"] as? Int, 2)
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.press-key",
            "--code", "key_pressed",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.press-key")
        XCTAssertEqual(entry["action"] as? String, "browser.pressKey")
        XCTAssertEqual(entry["reason"] as? String, "submit focused form")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Key Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/key")
        XCTAssertEqual(browserTab["keyName"] as? String, "Enter")
        XCTAssertEqual(browserTab["keyModifiers"] as? [String], ["control"])
        XCTAssertEqual(browserTab["keyModifierMask"] as? Int, 2)
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "key_pressed")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "key_pressed")
    }

    func testBrowserClickRequiresPolicyVerifiesAndAuditsSelectorOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-click-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let clickPayload: [String: Any] = [
            "ok": true,
            "code": "clicked",
            "message": "The matched element received a click.",
            "selector": "button[type='submit']",
            "tagName": "button",
            "disabled": false,
            "href": NSNull(),
            "matched": true
        ]
        let clickData = try JSONSerialization.data(withJSONObject: clickPayload, options: [.sortedKeys])
        let clickJSONString = String(decoding: clickData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": clickJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Click Page",
            "url": "https://example.com/click",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "click",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "click",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "submit form"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.clickElement")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["selector"] as? String, "button[type='submit']")
        XCTAssertEqual(object["targetTagName"] as? String, "button")
        XCTAssertEqual(object["targetDisabled"] as? Bool, false)
        XCTAssertNil(object["targetHref"])
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "element_clicked")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.click",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.clickElement")
        XCTAssertEqual(deniedBrowserTab["clickSelector"] as? String, "button[type='submit']")
        XCTAssertNil(deniedBrowserTab["text"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.click",
            "--code", "clicked",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.click")
        XCTAssertEqual(entry["action"] as? String, "browser.clickElement")
        XCTAssertEqual(entry["reason"] as? String, "submit form")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Click Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/click")
        XCTAssertEqual(browserTab["clickSelector"] as? String, "button[type='submit']")
        XCTAssertEqual(browserTab["clickTagName"] as? String, "button")
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "element_clicked")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "clicked")
    }

    func testBrowserClickCanVerifyExpectedURLAfterClick() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-click-url-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let clickPayload: [String: Any] = [
            "ok": true,
            "code": "clicked",
            "message": "The matched element received a click.",
            "selector": "a.next",
            "tagName": "a",
            "disabled": false,
            "href": "https://example.com/done",
            "matched": true
        ]
        let clickData = try JSONSerialization.data(withJSONObject: clickPayload, options: [.sortedKeys])
        let clickJSONString = String(decoding: clickData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": clickJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Done Page",
            "url": "https://example.com/done",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "click",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "a.next",
            "--expect-url", "https://example.com/done",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "follow link"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let urlVerification = try XCTUnwrap(object["urlVerification"] as? [String: Any])

        XCTAssertEqual(object["expectedURL"] as? String, "https://example.com/done")
        XCTAssertEqual(object["match"] as? String, "exact")
        XCTAssertEqual(object["targetHref"] as? String, "https://example.com/done")
        XCTAssertEqual(verification["code"] as? String, "element_clicked")
        XCTAssertEqual(urlVerification["ok"] as? Bool, true)
        XCTAssertEqual(urlVerification["code"] as? String, "url_matched")
        XCTAssertEqual(urlVerification["currentURL"] as? String, "https://example.com/done")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.click",
            "--code", "clicked",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])

        XCTAssertEqual(browserTab["navigationURL"] as? String, "https://example.com/done")
        XCTAssertEqual(browserTab["currentURL"] as? String, "https://example.com/done")
        XCTAssertEqual(browserTab["urlMatched"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "url_matched")
    }

    func testBrowserNavigateRequiresPolicyVerifiesURLAndAudits() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-navigate-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("navigate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        try """
        {
          "ok": true,
          "code": "url_matched",
          "message": "browser tab URL matched expected exact value",
          "requestedURL": "https://example.com/next",
          "expectedURL": "https://example.com/next",
          "currentURL": "https://example.com/next",
          "match": "exact",
          "matched": true
        }
        """.write(to: cdpResponse, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Start Page",
            "url": "https://example.com/start",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "navigate",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--url", "https://example.com/blocked",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "navigate",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--url", "https://example.com/next",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "open next page"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.navigate")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["requestedURL"] as? String, "https://example.com/next")
        XCTAssertEqual(object["expectedURL"] as? String, "https://example.com/next")
        XCTAssertEqual(object["match"] as? String, "exact")
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "url_matched")
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/next")
        XCTAssertEqual(verification["matched"] as? Bool, true)

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.navigate",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.navigate")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["navigationURL"] as? String, "https://example.com/blocked")
        XCTAssertNil(deniedBrowserTab["currentURL"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.navigate",
            "--code", "navigated",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.navigate")
        XCTAssertEqual(entry["action"] as? String, "browser.navigate")
        XCTAssertEqual(entry["reason"] as? String, "open next page")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Start Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/start")
        XCTAssertEqual(browserTab["navigationURL"] as? String, "https://example.com/next")
        XCTAssertEqual(browserTab["currentURL"] as? String, "https://example.com/next")
        XCTAssertEqual(browserTab["urlMatched"] as? Bool, true)
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(auditVerification["code"] as? String, "url_matched")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "navigated")
    }

    func testBrowserWaitURLReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-url-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Wait Page",
            "url": "https://example.com/done"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-url",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--expect-url", "https://example.com/done",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["expectedURL"] as? String, "https://example.com/done")
        XCTAssertEqual(object["match"] as? String, "exact")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "url_matched")
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/done")
    }

    func testBrowserWaitSelectorReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-selector-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let selectorPayload: [String: Any] = [
            "ok": true,
            "code": "selector_matched",
            "message": "The selector reached 'visible' state.",
            "selector": "button[type='submit']",
            "state": "visible",
            "matched": true,
            "currentURL": "https://example.com/form",
            "tagName": "button",
            "disabled": false,
            "href": NSNull(),
            "textLength": 6
        ]
        let selectorData = try JSONSerialization.data(withJSONObject: selectorPayload, options: [.sortedKeys])
        let selectorJSONString = String(decoding: selectorData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": selectorJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Form Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-selector",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--state", "visible",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "button[type='submit']")
        XCTAssertEqual(object["state"] as? String, "visible")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "selector_matched")
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["tagName"] as? String, "button")
        XCTAssertEqual(verification["disabled"] as? Bool, false)
        XCTAssertEqual(verification["textLength"] as? Int, 6)
    }

    func testBrowserWaitSelectorSupportsHiddenAndDetachedStates() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-selector-hidden-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let selectorPayload: [String: Any] = [
            "ok": true,
            "code": "selector_hidden",
            "message": "The selector reached 'hidden' state.",
            "selector": ".loading-overlay",
            "state": "hidden",
            "matched": true,
            "currentURL": "https://example.com/form"
        ]
        let selectorData = try JSONSerialization.data(withJSONObject: selectorPayload, options: [.sortedKeys])
        let selectorJSONString = String(decoding: selectorData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": selectorJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Form Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-selector",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", ".loading-overlay",
            "--state", "hidden",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, ".loading-overlay")
        XCTAssertEqual(object["state"] as? String, "hidden")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "selector_hidden")
        XCTAssertEqual(verification["state"] as? String, "hidden")
        XCTAssertEqual(verification["matched"] as? Bool, true)

        let detachedPayload: [String: Any] = [
            "ok": true,
            "code": "selector_detached",
            "message": "The selector reached 'detached' state.",
            "selector": ".toast",
            "state": "detached",
            "matched": true,
            "currentURL": "https://example.com/form"
        ]
        let detachedData = try JSONSerialization.data(withJSONObject: detachedPayload, options: [.sortedKeys])
        let detachedJSONString = String(decoding: detachedData, as: UTF8.self)
        let detachedCDPPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": detachedJSONString
                ]
            ]
        ]
        let detachedCDPData = try JSONSerialization.data(withJSONObject: detachedCDPPayload, options: [.prettyPrinted, .sortedKeys])
        try detachedCDPData.write(to: cdpResponse)

        let detachedResult = try runLn1([
            "browser",
            "wait-selector",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", ".toast",
            "--state", "detached",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(detachedResult.status, 0, detachedResult.stderr)
        let detachedObject = try decodeJSONObject(detachedResult.stdout)
        let detachedVerification = try XCTUnwrap(detachedObject["verification"] as? [String: Any])

        XCTAssertEqual(detachedObject["selector"] as? String, ".toast")
        XCTAssertEqual(detachedObject["state"] as? String, "detached")
        XCTAssertEqual(detachedVerification["ok"] as? Bool, true)
        XCTAssertEqual(detachedVerification["code"] as? String, "selector_detached")
        XCTAssertEqual(detachedVerification["state"] as? String, "detached")
        XCTAssertEqual(detachedVerification["matched"] as? Bool, true)
    }

    func testBrowserWaitCountReturnsSelectorCountVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-count-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let countPayload: [String: Any] = [
            "ok": true,
            "code": "count_matched",
            "message": "browser selector count matched expected at-least value",
            "selector": ".result-row",
            "expectedCount": 3,
            "currentCount": 5,
            "currentURL": "https://example.com/results",
            "countMatch": "at-least",
            "matched": true
        ]
        let countData = try JSONSerialization.data(withJSONObject: countPayload, options: [.sortedKeys])
        let countJSONString = String(decoding: countData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": countJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Results Page",
            "url": "https://example.com/results",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-count",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", ".result-row",
            "--count", "3",
            "--count-match", "at-least",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, ".result-row")
        XCTAssertEqual(object["expectedCount"] as? Int, 3)
        XCTAssertEqual(object["countMatch"] as? String, "at-least")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "count_matched")
        XCTAssertEqual(verification["selector"] as? String, ".result-row")
        XCTAssertEqual(verification["expectedCount"] as? Int, 3)
        XCTAssertEqual(verification["currentCount"] as? Int, 5)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/results")
        XCTAssertEqual(verification["countMatch"] as? String, "at-least")
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitTextReturnsVerificationWithoutTextContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-text-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        {
          "id": 1,
          "result": {
            "result": {
              "type": "string",
              "value": "Saved successfully\\nNext"
            }
          }
        }
        """.write(to: cdpResponse, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Saved Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["expectedTextLength"] as? Int, 18)
        XCTAssertEqual(object["match"] as? String, "contains")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_matched")
        XCTAssertEqual(verification["expectedTextLength"] as? Int, 18)
        XCTAssertEqual(verification["currentTextLength"] as? Int, 23)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNil(verification["text"])
        XCTAssertNotNil(verification["expectedTextDigest"] as? String)
        XCTAssertNotNil(verification["currentTextDigest"] as? String)
    }

    func testBrowserWaitValueReturnsVerificationWithoutValueContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-value-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let valuePayload: [String: Any] = [
            "ok": true,
            "code": "value_matched",
            "message": "browser field value matched expected exact value",
            "selector": "input[name='q']",
            "currentValue": "bounded text",
            "currentURL": "https://example.com/form",
            "tagName": "input",
            "inputType": "search",
            "disabled": false,
            "readOnly": false,
            "match": "exact",
            "matched": true
        ]
        let valueData = try JSONSerialization.data(withJSONObject: valuePayload, options: [.sortedKeys])
        let valueJSONString = String(decoding: valueData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": valueJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Search Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-value",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--text", "bounded text",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "input[name='q']")
        XCTAssertEqual(object["expectedValueLength"] as? Int, 12)
        XCTAssertEqual(object["match"] as? String, "exact")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["value"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "value_matched")
        XCTAssertEqual(verification["expectedValueLength"] as? Int, 12)
        XCTAssertEqual(verification["currentValueLength"] as? Int, 12)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["tagName"] as? String, "input")
        XCTAssertEqual(verification["inputType"] as? String, "search")
        XCTAssertEqual(verification["disabled"] as? Bool, false)
        XCTAssertEqual(verification["readOnly"] as? Bool, false)
        XCTAssertEqual(verification["match"] as? String, "exact")
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNil(verification["value"])
        XCTAssertNotNil(verification["expectedValueDigest"] as? String)
        XCTAssertNotNil(verification["currentValueDigest"] as? String)
    }

    func testBrowserWaitElementTextReturnsVerificationWithoutTextContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-element-text-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let textPayload: [String: Any] = [
            "ok": true,
            "code": "element_text_matched",
            "message": "browser element text matched expected contains value",
            "selector": "[data-testid='status']",
            "currentText": "Saved successfully",
            "currentURL": "https://example.com/form",
            "tagName": "div",
            "match": "contains",
            "matched": true
        ]
        let textData = try JSONSerialization.data(withJSONObject: textPayload, options: [.sortedKeys])
        let textJSONString = String(decoding: textData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": textJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Saved Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-element-text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "[data-testid='status']",
            "--text", "Saved",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "[data-testid='status']")
        XCTAssertEqual(object["expectedTextLength"] as? Int, 5)
        XCTAssertEqual(object["match"] as? String, "contains")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "element_text_matched")
        XCTAssertEqual(verification["selector"] as? String, "[data-testid='status']")
        XCTAssertEqual(verification["expectedTextLength"] as? Int, 5)
        XCTAssertEqual(verification["currentTextLength"] as? Int, 18)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["tagName"] as? String, "div")
        XCTAssertEqual(verification["match"] as? String, "contains")
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertNil(verification["text"])
        XCTAssertNotNil(verification["expectedTextDigest"] as? String)
        XCTAssertNotNil(verification["currentTextDigest"] as? String)
    }

    func testBrowserWaitReadyReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-ready-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let readyPayload: [String: Any] = [
            "ok": true,
            "code": "ready_state_matched",
            "message": "browser document ready state reached complete",
            "expectedState": "complete",
            "currentState": "complete",
            "currentURL": "https://example.com/form",
            "matched": true
        ]
        let readyData = try JSONSerialization.data(withJSONObject: readyPayload, options: [.sortedKeys])
        let readyJSONString = String(decoding: readyData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": readyJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Ready Page",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-ready",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--state", "complete",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["expectedState"] as? String, "complete")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "ready_state_matched")
        XCTAssertEqual(verification["expectedState"] as? String, "complete")
        XCTAssertEqual(verification["currentState"] as? String, "complete")
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitTitleReturnsVerificationWithoutPageContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-title-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Checkout - Example",
            "url": "https://example.com/checkout"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-title",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--title", "Checkout",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["expectedTitle"] as? String, "Checkout")
        XCTAssertEqual(object["match"] as? String, "contains")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "title_matched")
        XCTAssertEqual(verification["expectedTitle"] as? String, "Checkout")
        XCTAssertEqual(verification["currentTitle"] as? String, "Checkout - Example")
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/checkout")
        XCTAssertEqual(verification["match"] as? String, "contains")
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitCheckedReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-checked-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let checkedPayload: [String: Any] = [
            "ok": true,
            "code": "checked_matched",
            "message": "browser checked state matched expected value",
            "selector": "input[name='subscribe']",
            "expectedChecked": true,
            "currentChecked": true,
            "currentURL": "https://example.com/preferences",
            "tagName": "input",
            "inputType": "checkbox",
            "disabled": false,
            "readOnly": false,
            "matched": true
        ]
        let checkedData = try JSONSerialization.data(withJSONObject: checkedPayload, options: [.sortedKeys])
        let checkedJSONString = String(decoding: checkedData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": checkedJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Preferences",
            "url": "https://example.com/preferences",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-checked",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='subscribe']",
            "--checked", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "input[name='subscribe']")
        XCTAssertEqual(object["expectedChecked"] as? Bool, true)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "checked_matched")
        XCTAssertEqual(verification["selector"] as? String, "input[name='subscribe']")
        XCTAssertEqual(verification["expectedChecked"] as? Bool, true)
        XCTAssertEqual(verification["currentChecked"] as? Bool, true)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/preferences")
        XCTAssertEqual(verification["tagName"] as? String, "input")
        XCTAssertEqual(verification["inputType"] as? String, "checkbox")
        XCTAssertEqual(verification["disabled"] as? Bool, false)
        XCTAssertEqual(verification["readOnly"] as? Bool, false)
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitEnabledReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-enabled-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let enabledPayload: [String: Any] = [
            "ok": true,
            "code": "enabled_matched",
            "message": "browser element enabled state matched expected value",
            "selector": "button[type='submit']",
            "expectedEnabled": true,
            "currentEnabled": true,
            "currentURL": "https://example.com/form",
            "tagName": "button",
            "disabled": false,
            "readOnly": false,
            "matched": true
        ]
        let enabledData = try JSONSerialization.data(withJSONObject: enabledPayload, options: [.sortedKeys])
        let enabledJSONString = String(decoding: enabledData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": enabledJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Form",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-enabled",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--enabled", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "button[type='submit']")
        XCTAssertEqual(object["expectedEnabled"] as? Bool, true)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "enabled_matched")
        XCTAssertEqual(verification["selector"] as? String, "button[type='submit']")
        XCTAssertEqual(verification["expectedEnabled"] as? Bool, true)
        XCTAssertEqual(verification["currentEnabled"] as? Bool, true)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["tagName"] as? String, "button")
        XCTAssertEqual(verification["disabled"] as? Bool, false)
        XCTAssertEqual(verification["readOnly"] as? Bool, false)
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitFocusReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-focus-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let focusPayload: [String: Any] = [
            "ok": true,
            "code": "focus_matched",
            "message": "browser element focus state matched expected value",
            "selector": "input[name='q']",
            "expectedFocused": true,
            "currentFocused": true,
            "currentURL": "https://example.com/form",
            "tagName": "input",
            "inputType": "search",
            "activeTagName": "input",
            "activeInputType": "search",
            "matched": true
        ]
        let focusData = try JSONSerialization.data(withJSONObject: focusPayload, options: [.sortedKeys])
        let focusJSONString = String(decoding: focusData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": focusJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Form",
            "url": "https://example.com/form",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-focus",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "input[name='q']",
            "--focused", "true",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "input[name='q']")
        XCTAssertEqual(object["expectedFocused"] as? Bool, true)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "focus_matched")
        XCTAssertEqual(verification["selector"] as? String, "input[name='q']")
        XCTAssertEqual(verification["expectedFocused"] as? Bool, true)
        XCTAssertEqual(verification["currentFocused"] as? Bool, true)
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/form")
        XCTAssertEqual(verification["tagName"] as? String, "input")
        XCTAssertEqual(verification["inputType"] as? String, "search")
        XCTAssertEqual(verification["activeTagName"] as? String, "input")
        XCTAssertEqual(verification["activeInputType"] as? String, "search")
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testBrowserWaitAttributeReturnsVerificationWithoutAttributeContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-wait-attribute-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let attributePayload: [String: Any] = [
            "ok": true,
            "code": "attribute_matched",
            "message": "browser attribute matched expected exact value",
            "selector": "button[aria-expanded]",
            "attribute": "aria-expanded",
            "currentValue": "true",
            "currentURL": "https://example.com/menu",
            "tagName": "button",
            "match": "exact",
            "matched": true
        ]
        let attributeData = try JSONSerialization.data(withJSONObject: attributePayload, options: [.sortedKeys])
        let attributeJSONString = String(decoding: attributeData, as: UTF8.self)
        let cdpPayload: [String: Any] = [
            "id": 1,
            "result": [
                "result": [
                    "type": "string",
                    "value": attributeJSONString
                ]
            ]
        ]
        let cdpData = try JSONSerialization.data(withJSONObject: cdpPayload, options: [.prettyPrinted, .sortedKeys])
        try cdpData.write(to: cdpResponse)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Menu",
            "url": "https://example.com/menu",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "browser",
            "wait-attribute",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[aria-expanded]",
            "--attribute", "ARIA-EXPANDED",
            "--text", "true",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["tabID"] as? String, "page-1")
        XCTAssertEqual(object["selector"] as? String, "button[aria-expanded]")
        XCTAssertEqual(object["attribute"] as? String, "aria-expanded")
        XCTAssertEqual(object["expectedValueLength"] as? Int, 4)
        XCTAssertNotNil(object["expectedValueDigest"])
        XCTAssertEqual(object["match"] as? String, "exact")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 500)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertNil(object["text"])
        XCTAssertNil(object["value"])
        XCTAssertNil(object["html"])
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "attribute_matched")
        XCTAssertEqual(verification["selector"] as? String, "button[aria-expanded]")
        XCTAssertEqual(verification["attribute"] as? String, "aria-expanded")
        XCTAssertEqual(verification["currentValueLength"] as? Int, 4)
        XCTAssertNotNil(verification["currentValueDigest"])
        XCTAssertNil(verification["currentValue"])
        XCTAssertEqual(verification["currentURL"] as? String, "https://example.com/menu")
        XCTAssertEqual(verification["tagName"] as? String, "button")
        XCTAssertEqual(verification["match"] as? String, "exact")
        XCTAssertEqual(verification["matched"] as? Bool, true)
    }

    func testFilesStatReturnsStructuredMetadataForFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-files-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "stat",
            "--path", file.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let root = try XCTUnwrap(object["root"] as? [String: Any])
        let actions = try XCTUnwrap(root["actions"] as? [[String: Any]])

        XCTAssertEqual(root["path"] as? String, file.path)
        XCTAssertEqual(root["name"] as? String, "note.txt")
        XCTAssertEqual(root["kind"] as? String, "regularFile")
        XCTAssertEqual(root["readable"] as? Bool, true)
        XCTAssertEqual((object["entries"] as? [Any])?.count, 0)
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.stat" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.checksum" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.readText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.tailText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.readLines" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.readJSON" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.readPropertyList" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.writeText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "filesystem.appendText" })
    }

    func testFilesListReturnsDirectoryEntriesWithoutHiddenFilesByDefault() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-files-\(UUID().uuidString)")
        let nested = directory.appendingPathComponent("nested")
        let visible = directory.appendingPathComponent("visible.txt")
        let hidden = directory.appendingPathComponent(".secret")
        let inner = nested.appendingPathComponent("inner.txt")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "visible".write(to: visible, atomically: true, encoding: .utf8)
        try "hidden".write(to: hidden, atomically: true, encoding: .utf8)
        try "inner".write(to: inner, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "list",
            "--path", directory.path,
            "--depth", "2",
            "--limit", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let root = try XCTUnwrap(object["root"] as? [String: Any])
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let names = Set(entries.compactMap { $0["name"] as? String })
        let directoryEntry = try XCTUnwrap(entries.first { $0["name"] as? String == "nested" })
        let directoryActions = try XCTUnwrap(directoryEntry["actions"] as? [[String: Any]])

        XCTAssertEqual(root["kind"] as? String, "directory")
        XCTAssertEqual(object["truncated"] as? Bool, false)
        XCTAssertTrue(names.contains("visible.txt"))
        XCTAssertTrue(names.contains("nested"))
        XCTAssertTrue(names.contains("inner.txt"))
        XCTAssertFalse(names.contains(".secret"))
        XCTAssertTrue(directoryActions.contains { $0["name"] as? String == "filesystem.list" })
    }

    func testFilesSearchReturnsStructuredNameAndContentMatches() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-search-\(UUID().uuidString)")
        let nested = directory.appendingPathComponent("nested")
        let contentMatch = directory.appendingPathComponent("alpha.txt")
        let nameMatch = nested.appendingPathComponent("needle-name.txt")
        let hiddenMatch = directory.appendingPathComponent(".hidden.txt")

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "first line\nThe Needle appears here\nlast line".write(to: contentMatch, atomically: true, encoding: .utf8)
        try "ordinary text".write(to: nameMatch, atomically: true, encoding: .utf8)
        try "needle should be skipped".write(to: hiddenMatch, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "search",
            "--path", directory.path,
            "--query", "needle",
            "--depth", "2",
            "--limit", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let matches = try XCTUnwrap(object["matches"] as? [[String: Any]])
        let names = Set(matches.compactMap { ($0["file"] as? [String: Any])?["name"] as? String })

        XCTAssertEqual(object["query"] as? String, "needle")
        XCTAssertEqual(object["caseSensitive"] as? Bool, false)
        XCTAssertEqual(object["maxMatchesPerFile"] as? Int, 20)
        XCTAssertEqual(object["truncated"] as? Bool, false)
        XCTAssertTrue(names.contains("alpha.txt"))
        XCTAssertTrue(names.contains("needle-name.txt"))
        XCTAssertFalse(names.contains(".hidden.txt"))

        let contentEntry = try XCTUnwrap(matches.first {
            ($0["file"] as? [String: Any])?["name"] as? String == "alpha.txt"
        })
        let contentLines = try XCTUnwrap(contentEntry["contentMatches"] as? [[String: Any]])
        let contentFile = try XCTUnwrap(contentEntry["file"] as? [String: Any])
        let contentActions = try XCTUnwrap(contentFile["actions"] as? [[String: Any]])

        XCTAssertEqual(contentEntry["matchedName"] as? Bool, false)
        XCTAssertEqual(contentLines.first?["lineNumber"] as? Int, 2)
        XCTAssertEqual(contentLines.first?["text"] as? String, "The Needle appears here")
        XCTAssertTrue(contentActions.contains { $0["name"] as? String == "filesystem.search" })

        let nameEntry = try XCTUnwrap(matches.first {
            ($0["file"] as? [String: Any])?["name"] as? String == "needle-name.txt"
        })
        XCTAssertEqual(nameEntry["matchedName"] as? Bool, true)
        XCTAssertEqual((nameEntry["contentMatches"] as? [Any])?.count, 0)
    }

    func testFilesSearchLimitsContentMatchesPerFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-search-limit-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("many.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "needle one\nneedle two\nneedle three".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "search",
            "--path", directory.path,
            "--query", "needle",
            "--max-matches-per-file", "2"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let matches = try XCTUnwrap(object["matches"] as? [[String: Any]])
        let match = try XCTUnwrap(matches.first)
        let lines = try XCTUnwrap(match["contentMatches"] as? [[String: Any]])

        XCTAssertEqual(object["maxMatchesPerFile"] as? Int, 2)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines.first?["lineNumber"] as? Int, 1)
        XCTAssertEqual(lines.last?["lineNumber"] as? Int, 2)
    }

    func testFilesReadTextRequiresMediumRiskAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-read-text-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello file contents".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "read-text",
            "--path", file.path,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "files",
            "read-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path,
            "--reason", "read test file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let resultFile = try XCTUnwrap(object["file"] as? [String: Any])

        XCTAssertEqual(resultFile["path"] as? String, file.path)
        XCTAssertEqual(resultFile["kind"] as? String, "regularFile")
        XCTAssertEqual(object["text"] as? String, "hello")
        XCTAssertEqual(object["selection"] as? String, "prefix")
        XCTAssertEqual(object["textLength"] as? Int, 19)
        XCTAssertEqual(object["byteLength"] as? Int, 19)
        XCTAssertEqual(object["textDigest"] as? String, "cff9e957c7cca67a965799dcca968319fae2fe717f6e83b4519911df53c7331c")
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxCharacters"] as? Int, 5)
        XCTAssertEqual(object["maxFileBytes"] as? Int, 100)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.read-text",
            "--code", "read_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.read-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.readText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "read test file")
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["kind"] as? String, "regularFile")
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, 19)
        XCTAssertNil(entry["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_text")
    }

    func testFilesTailTextRequiresMediumRiskAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-tail-text-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "alpha\nbeta\ngamma".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "tail-text",
            "--path", file.path,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "files",
            "tail-text",
            "--path", file.path,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path,
            "--reason", "tail test file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let resultFile = try XCTUnwrap(object["file"] as? [String: Any])

        XCTAssertEqual(resultFile["path"] as? String, file.path)
        XCTAssertEqual(resultFile["kind"] as? String, "regularFile")
        XCTAssertEqual(object["text"] as? String, "gamma")
        XCTAssertEqual(object["selection"] as? String, "suffix")
        XCTAssertEqual(object["textLength"] as? Int, 16)
        XCTAssertEqual(object["byteLength"] as? Int, 16)
        XCTAssertEqual((object["textDigest"] as? String)?.count, 64)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxCharacters"] as? Int, 5)
        XCTAssertEqual(object["maxFileBytes"] as? Int, 100)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.tail-text",
            "--code", "tail_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.tail-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.tailText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "tail test file")
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["kind"] as? String, "regularFile")
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, 16)
        XCTAssertNil(entry["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "tail_text")
    }

    func testFilesReadLinesReturnsNumberedRangeAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-read-lines-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let contents = "alpha\nbeta line\ncharlie line\nlonger delta line"
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try contents.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "read-lines",
            "--path", file.path,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "files",
            "read-lines",
            "--path", file.path,
            "--allow-risk", "medium",
            "--start-line", "2",
            "--line-count", "2",
            "--max-line-characters", "6",
            "--max-file-bytes", "100",
            "--audit-log", auditLog.path,
            "--reason", "line range test"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let resultFile = try XCTUnwrap(object["file"] as? [String: Any])
        let lines = try XCTUnwrap(object["lines"] as? [[String: Any]])

        XCTAssertEqual(resultFile["path"] as? String, file.path)
        XCTAssertEqual(resultFile["kind"] as? String, "regularFile")
        XCTAssertEqual(object["startLine"] as? Int, 2)
        XCTAssertEqual(object["requestedLineCount"] as? Int, 2)
        XCTAssertEqual(object["returnedLineCount"] as? Int, 2)
        XCTAssertEqual(object["totalLineCount"] as? Int, 4)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0]["lineNumber"] as? Int, 2)
        XCTAssertEqual(lines[0]["text"] as? String, "beta l")
        XCTAssertEqual(lines[1]["lineNumber"] as? Int, 3)
        XCTAssertEqual(lines[1]["text"] as? String, "charli")
        XCTAssertEqual(object["byteLength"] as? Int, contents.utf8.count)
        XCTAssertEqual((object["textDigest"] as? String)?.count, 64)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxLineCharacters"] as? Int, 6)
        XCTAssertEqual(object["maxFileBytes"] as? Int, 100)
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.read-lines",
            "--code", "read_lines",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.read-lines")
        XCTAssertEqual(entry["action"] as? String, "filesystem.readLines")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "line range test")
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["kind"] as? String, "regularFile")
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, contents.utf8.count)
        XCTAssertNil(entry["text"])
        XCTAssertNil(entry["lines"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_lines")
    }

    func testFilesReadJSONReturnsBoundedTypedTreeAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-read-json-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let contents = """
        {"enabled":true,"items":[1,2,3],"nested":{"target":[{"name":"skip"},{"secret":"abcdef","visible":null}]}}
        """
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try contents.write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "read-json",
            "--path", file.path,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "files",
            "read-json",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/nested/target/1",
            "--max-depth", "2",
            "--max-items", "5",
            "--max-string-characters", "4",
            "--max-file-bytes", "200",
            "--audit-log", auditLog.path,
            "--reason", "json config test"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let resultFile = try XCTUnwrap(object["file"] as? [String: Any])
        let value = try XCTUnwrap(object["value"] as? [String: Any])
        let entries = try XCTUnwrap(value["entries"] as? [[String: Any]])
        let secretEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "secret" })
        let secretValue = try XCTUnwrap(secretEntry["value"] as? [String: Any])
        let visibleEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "visible" })
        let visibleValue = try XCTUnwrap(visibleEntry["value"] as? [String: Any])

        XCTAssertEqual(resultFile["path"] as? String, file.path)
        XCTAssertEqual(resultFile["kind"] as? String, "regularFile")
        XCTAssertEqual(object["pointer"] as? String, "/nested/target/1")
        XCTAssertEqual(object["found"] as? Bool, true)
        XCTAssertEqual(object["valueType"] as? String, "object")
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxDepth"] as? Int, 2)
        XCTAssertEqual(object["maxItems"] as? Int, 5)
        XCTAssertEqual(object["maxStringCharacters"] as? Int, 4)
        XCTAssertEqual(object["byteLength"] as? Int, contents.utf8.count)
        XCTAssertEqual((object["textDigest"] as? String)?.count, 64)
        XCTAssertEqual(value["type"] as? String, "object")
        XCTAssertEqual(value["count"] as? Int, 2)
        XCTAssertEqual(secretValue["type"] as? String, "string")
        XCTAssertEqual(secretValue["value"] as? String, "abcd")
        XCTAssertEqual(secretValue["count"] as? Int, 6)
        XCTAssertEqual(secretValue["truncated"] as? Bool, true)
        XCTAssertEqual(visibleValue["type"] as? String, "null")
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.read-json",
            "--code", "read_json",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let auditEntries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(auditEntries.first)
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.read-json")
        XCTAssertEqual(entry["action"] as? String, "filesystem.readJSON")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "json config test")
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["kind"] as? String, "regularFile")
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, contents.utf8.count)
        XCTAssertNil(entry["text"])
        XCTAssertNil(entry["value"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_json")
    }

    func testFilesReadPlistReturnsBoundedTypedTreeAndAuditsMetadataOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-read-plist-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("config.plist")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let plist: [String: Any] = [
            "enabled": true,
            "nested": [
                "target": [
                    ["name": "skip"],
                    [
                        "blob": Data([1, 2, 3]),
                        "secret": "abcdef",
                        "visible": true
                    ]
                ]
            ]
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .binary,
            options: 0
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: file)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "read-plist",
            "--path", file.path,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "files",
            "read-plist",
            "--path", file.path,
            "--allow-risk", "medium",
            "--pointer", "/nested/target/1",
            "--max-depth", "2",
            "--max-items", "5",
            "--max-string-characters", "4",
            "--max-file-bytes", "500",
            "--audit-log", auditLog.path,
            "--reason", "plist config test"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let resultFile = try XCTUnwrap(object["file"] as? [String: Any])
        let value = try XCTUnwrap(object["value"] as? [String: Any])
        let entries = try XCTUnwrap(value["entries"] as? [[String: Any]])
        let blobEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "blob" })
        let blobValue = try XCTUnwrap(blobEntry["value"] as? [String: Any])
        let secretEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "secret" })
        let secretValue = try XCTUnwrap(secretEntry["value"] as? [String: Any])
        let visibleEntry = try XCTUnwrap(entries.first { $0["key"] as? String == "visible" })
        let visibleValue = try XCTUnwrap(visibleEntry["value"] as? [String: Any])

        XCTAssertEqual(resultFile["path"] as? String, file.path)
        XCTAssertEqual(resultFile["kind"] as? String, "regularFile")
        XCTAssertEqual(object["pointer"] as? String, "/nested/target/1")
        XCTAssertEqual(object["found"] as? Bool, true)
        XCTAssertEqual(object["valueType"] as? String, "dictionary")
        XCTAssertEqual(object["format"] as? String, "binary")
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxDepth"] as? Int, 2)
        XCTAssertEqual(object["maxItems"] as? Int, 5)
        XCTAssertEqual(object["maxStringCharacters"] as? Int, 4)
        XCTAssertEqual(object["byteLength"] as? Int, data.count)
        XCTAssertEqual((object["digest"] as? String)?.count, 64)
        XCTAssertEqual(value["type"] as? String, "dictionary")
        XCTAssertEqual(value["count"] as? Int, 3)
        XCTAssertEqual(blobValue["type"] as? String, "data")
        XCTAssertEqual(blobValue["count"] as? Int, 3)
        XCTAssertEqual((blobValue["dataDigest"] as? String)?.count, 64)
        XCTAssertEqual(secretValue["type"] as? String, "string")
        XCTAssertEqual(secretValue["value"] as? String, "abcd")
        XCTAssertEqual(secretValue["count"] as? Int, 6)
        XCTAssertEqual(secretValue["truncated"] as? Bool, true)
        XCTAssertEqual(visibleValue["type"] as? String, "boolean")
        XCTAssertEqual(visibleValue["value"] as? Bool, true)
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.read-plist",
            "--code", "read_plist",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let auditEntries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(auditEntries.first)
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.read-plist")
        XCTAssertEqual(entry["action"] as? String, "filesystem.readPropertyList")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "plist config test")
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["kind"] as? String, "regularFile")
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, data.count)
        XCTAssertNil(entry["text"])
        XCTAssertNil(entry["value"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_plist")
    }

    func testFilesWriteTextCreatesFileWithPolicyAuditAndVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-write-text-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "write-text",
            "--path", file.path,
            "--text", "blocked",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))

        let result = try runLn1([
            "files",
            "write-text",
            "--path", file.path,
            "--text", "hello file",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "create test file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "hello file")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.writeText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["path"] as? String, file.path)
        XCTAssertEqual(object["created"] as? Bool, true)
        XCTAssertEqual(object["overwritten"] as? Bool, false)
        XCTAssertEqual(object["writtenLength"] as? Int, 10)
        XCTAssertEqual(object["writtenBytes"] as? Int, 10)
        XCTAssertEqual((object["writtenDigest"] as? String)?.count, 64)
        XCTAssertEqual(previous["path"] as? String, file.path)
        XCTAssertEqual(previous["exists"] as? Bool, false)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(current["kind"] as? String, "regularFile")
        XCTAssertEqual(current["sizeBytes"] as? Int, 10)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_matched")
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.write-text",
            "--code", "created_text_file",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let fileDestination = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.write-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.writeText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "create test file")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["exists"] as? Bool, false)
        XCTAssertEqual(fileDestination["path"] as? String, file.path)
        XCTAssertEqual(fileDestination["kind"] as? String, "regularFile")
        XCTAssertEqual(fileDestination["sizeBytes"] as? Int, 10)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "created_text_file")
        XCTAssertNil(entry["text"])
    }

    func testFilesWriteTextRequiresOverwriteForExistingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-write-overwrite-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "old".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let refused = try runLn1([
            "files",
            "write-text",
            "--path", file.path,
            "--text", "new",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "missing overwrite"
        ])

        XCTAssertNotEqual(refused.status, 0)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "old")

        let result = try runLn1([
            "files",
            "write-text",
            "--path", file.path,
            "--text", "new",
            "--overwrite",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "overwrite test file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "new")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["created"] as? Bool, false)
        XCTAssertEqual(object["overwritten"] as? Bool, true)
        XCTAssertEqual(object["writtenLength"] as? Int, 3)
        XCTAssertEqual(object["writtenBytes"] as? Int, 3)
        XCTAssertEqual(previous["path"] as? String, file.path)
        XCTAssertEqual(previous["exists"] as? Bool, true)
        XCTAssertEqual(previous["sizeBytes"] as? Int, 3)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(current["sizeBytes"] as? Int, 3)
        XCTAssertEqual(verification["code"] as? String, "text_matched")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.write-text",
            "--code", "overwrote_text_file",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.write-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.writeText")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "overwrote_text_file")
        XCTAssertNil(entry["text"])
    }

    func testFilesAppendTextAppendsWithPolicyAuditAndVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-append-text-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "first".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "append-text",
            "--path", file.path,
            "--text", "\nblocked",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "first")

        let result = try runLn1([
            "files",
            "append-text",
            "--path", file.path,
            "--text", "\nsecond",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "append test file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "first\nsecond")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.appendText")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["path"] as? String, file.path)
        XCTAssertEqual(object["created"] as? Bool, false)
        XCTAssertEqual(object["appendedLength"] as? Int, 7)
        XCTAssertEqual(object["appendedBytes"] as? Int, 7)
        XCTAssertEqual((object["appendedDigest"] as? String)?.count, 64)
        XCTAssertEqual(object["finalBytes"] as? Int, 12)
        XCTAssertEqual(previous["path"] as? String, file.path)
        XCTAssertEqual(previous["exists"] as? Bool, true)
        XCTAssertEqual(previous["sizeBytes"] as? Int, 5)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(current["sizeBytes"] as? Int, 12)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_appended")
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.append-text",
            "--code", "appended_text_file",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let fileSource = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let fileDestination = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.append-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.appendText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "append test file")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(fileSource["path"] as? String, file.path)
        XCTAssertEqual(fileSource["sizeBytes"] as? Int, 5)
        XCTAssertEqual(fileDestination["path"] as? String, file.path)
        XCTAssertEqual(fileDestination["sizeBytes"] as? Int, 12)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "appended_text_file")
        XCTAssertNil(entry["text"])
    }

    func testFilesAppendTextRequiresCreateForMissingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-append-create-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let refused = try runLn1([
            "files",
            "append-text",
            "--path", file.path,
            "--text", "created",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "missing create"
        ])

        XCTAssertNotEqual(refused.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))

        let result = try runLn1([
            "files",
            "append-text",
            "--path", file.path,
            "--text", "created",
            "--create",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "create append file"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "created")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["created"] as? Bool, true)
        XCTAssertEqual(object["appendedLength"] as? Int, 7)
        XCTAssertEqual(object["appendedBytes"] as? Int, 7)
        XCTAssertEqual(object["finalBytes"] as? Int, 7)
        XCTAssertEqual(previous["exists"] as? Bool, false)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(current["sizeBytes"] as? Int, 7)
        XCTAssertEqual(verification["code"] as? String, "text_appended")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.append-text",
            "--code", "created_appended_text_file",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["action"] as? String, "filesystem.appendText")
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "created_appended_text_file")
        XCTAssertNil(entry["text"])
    }

    func testFilesWaitReturnsMatchedExistingFileMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-wait-exists-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("ready.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "ready".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "wait",
            "--path", file.path,
            "--exists", "true",
            "--timeout-ms", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let fileObject = try XCTUnwrap(object["file"] as? [String: Any])

        XCTAssertEqual(object["path"] as? String, file.path)
        XCTAssertEqual(object["expectedExists"] as? Bool, true)
        XCTAssertEqual(object["matched"] as? Bool, true)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(fileObject["path"] as? String, file.path)
        XCTAssertEqual(fileObject["kind"] as? String, "regularFile")
    }

    func testFilesWaitCanMatchExpectedSizeAndDigestWithoutContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-wait-digest-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let digest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        let result = try runLn1([
            "files",
            "wait",
            "--path", file.path,
            "--exists", "true",
            "--size-bytes", "5",
            "--digest", digest.uppercased(),
            "--max-file-bytes", "10",
            "--timeout-ms", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let fileObject = try XCTUnwrap(object["file"] as? [String: Any])

        XCTAssertEqual(object["path"] as? String, file.path)
        XCTAssertEqual(object["expectedExists"] as? Bool, true)
        XCTAssertEqual(object["expectedSizeBytes"] as? Int, 5)
        XCTAssertEqual(object["expectedDigest"] as? String, digest)
        XCTAssertEqual(object["algorithm"] as? String, "sha256")
        XCTAssertEqual(object["maxFileBytes"] as? Int, 10)
        XCTAssertEqual(object["matched"] as? Bool, true)
        XCTAssertEqual(object["sizeMatched"] as? Bool, true)
        XCTAssertEqual(object["digestMatched"] as? Bool, true)
        XCTAssertEqual(object["currentDigest"] as? String, digest)
        XCTAssertEqual(fileObject["path"] as? String, file.path)
        XCTAssertNil(object["contents"])
    }

    func testFilesWaitReportsDigestMismatchWithoutContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-wait-digest-mismatch-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let expectedDigest = String(repeating: "0", count: 64)
        let actualDigest = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        let result = try runLn1([
            "files",
            "wait",
            "--path", file.path,
            "--exists", "true",
            "--digest", expectedDigest,
            "--timeout-ms", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["expectedDigest"] as? String, expectedDigest)
        XCTAssertEqual(object["matched"] as? Bool, false)
        XCTAssertEqual(object["digestMatched"] as? Bool, false)
        XCTAssertEqual(object["currentDigest"] as? String, actualDigest)
        XCTAssertNil(object["contents"])
    }

    func testFilesWaitReturnsMatchedMissingPathWithoutMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-wait-missing-\(UUID().uuidString)")
        let missing = directory.appendingPathComponent("missing.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "wait",
            "--path", missing.path,
            "--exists", "false",
            "--timeout-ms", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["path"] as? String, missing.path)
        XCTAssertEqual(object["expectedExists"] as? Bool, false)
        XCTAssertEqual(object["matched"] as? Bool, true)
        XCTAssertNil(object["file"])
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
    }

    func testFilesWatchReturnsCreatedFileEventWithMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-watch-created-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("created.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            try? "created".write(to: created, atomically: true, encoding: .utf8)
        }

        let result = try runLn1([
            "files",
            "watch",
            "--path", directory.path,
            "--depth", "1",
            "--timeout-ms", "3000",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let root = try XCTUnwrap(object["root"] as? [String: Any])
        let rootActions = try XCTUnwrap(root["actions"] as? [[String: Any]])
        let events = try XCTUnwrap(object["events"] as? [[String: Any]])
        let event = try XCTUnwrap(events.first)
        let current = try XCTUnwrap(event["current"] as? [String: Any])

        XCTAssertEqual(root["path"] as? String, directory.path)
        XCTAssertTrue(rootActions.contains { $0["name"] as? String == "filesystem.watch" })
        XCTAssertEqual(object["matched"] as? Bool, true)
        XCTAssertEqual(object["eventCount"] as? Int, 1)
        XCTAssertEqual(object["beforeCount"] as? Int, 1)
        XCTAssertEqual(object["afterCount"] as? Int, 2)
        XCTAssertEqual(object["maxDepth"] as? Int, 1)
        XCTAssertEqual(object["limit"] as? Int, 200)
        XCTAssertEqual(object["includeHidden"] as? Bool, false)
        XCTAssertEqual(event["type"] as? String, "created")
        XCTAssertTrue((event["path"] as? String)?.hasSuffix("/created.txt") == true)
        XCTAssertNil(event["previous"])
        XCTAssertTrue((current["path"] as? String)?.hasSuffix("/created.txt") == true)
        XCTAssertEqual(current["kind"] as? String, "regularFile")
    }

    func testFilesWatchTimesOutWithoutEvents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-watch-timeout-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "watch",
            "--path", directory.path,
            "--timeout-ms", "0",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let events = try XCTUnwrap(object["events"] as? [[String: Any]])

        XCTAssertEqual(object["matched"] as? Bool, false)
        XCTAssertEqual(object["eventCount"] as? Int, 0)
        XCTAssertEqual(events.count, 0)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
    }

    func testFilesChecksumReturnsBoundedSHA256WithoutContent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-checksum-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "checksum",
            "--path", file.path,
            "--max-file-bytes", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let fileObject = try XCTUnwrap(object["file"] as? [String: Any])

        XCTAssertEqual(fileObject["path"] as? String, file.path)
        XCTAssertEqual(fileObject["kind"] as? String, "regularFile")
        XCTAssertEqual(object["algorithm"] as? String, "sha256")
        XCTAssertEqual(object["digest"] as? String, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertEqual(object["maxFileBytes"] as? Int, 10)
        XCTAssertNil(object["contents"])
    }

    func testFilesCompareReportsMatchingFilesBySizeAndDigest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-compare-match-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "same".write(to: left, atomically: true, encoding: .utf8)
        try "same".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "compare",
            "--path", left.path,
            "--to", right.path,
            "--max-file-bytes", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let leftObject = try XCTUnwrap(object["left"] as? [String: Any])
        let rightObject = try XCTUnwrap(object["right"] as? [String: Any])

        XCTAssertEqual(leftObject["path"] as? String, left.path)
        XCTAssertEqual(rightObject["path"] as? String, right.path)
        XCTAssertEqual(object["algorithm"] as? String, "sha256")
        XCTAssertEqual(object["sameSize"] as? Bool, true)
        XCTAssertEqual(object["sameDigest"] as? Bool, true)
        XCTAssertEqual(object["matched"] as? Bool, true)
        XCTAssertEqual(object["leftDigest"] as? String, object["rightDigest"] as? String)
    }

    func testFilesCompareReportsDifferentFilesByDigest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-compare-different-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "left".write(to: left, atomically: true, encoding: .utf8)
        try "right".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "compare",
            "--path", left.path,
            "--to", right.path,
            "--max-file-bytes", "10"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["sameDigest"] as? Bool, false)
        XCTAssertEqual(object["matched"] as? Bool, false)
        XCTAssertNotEqual(object["leftDigest"] as? String, object["rightDigest"] as? String)
    }

    func testFilesPlanPreflightsMoveWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-plan-move-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "plan me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "plan",
            "--operation", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))

        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let sourceTarget = try XCTUnwrap(object["source"] as? [String: Any])
        let destinationTarget = try XCTUnwrap(object["destination"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])
        let checkByName = Dictionary(uniqueKeysWithValues: checks.compactMap { check -> (String, [String: Any])? in
            guard let name = check["name"] as? String else {
                return nil
            }
            return (name, check)
        })

        XCTAssertEqual(object["operation"] as? String, "move")
        XCTAssertEqual(object["action"] as? String, "filesystem.move")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["actionMutates"] as? Bool, true)
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(object["requiredAllowRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(sourceTarget["path"] as? String, source.path)
        XCTAssertEqual(sourceTarget["exists"] as? Bool, true)
        XCTAssertEqual(destinationTarget["path"] as? String, destination.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, false)
        XCTAssertEqual(checkByName["sourceExists"]?["ok"] as? Bool, true)
        XCTAssertEqual(checkByName["destinationMissing"]?["ok"] as? Bool, true)
        XCTAssertEqual(checkByName["sourceParentWritable"]?["ok"] as? Bool, true)
    }

    func testFilesPlanReportsPolicyDenialWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-plan-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "plan",
            "--operation", "duplicate",
            "--path", source.path,
            "--to", destination.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))

        let object = try decodeJSONObject(result.stdout)
        let policy = try XCTUnwrap(object["policy"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])
        let policyCheck = try XCTUnwrap(checks.first { $0["name"] as? String == "policyAllows" })

        XCTAssertEqual(object["operation"] as? String, "duplicate")
        XCTAssertEqual(object["action"] as? String, "filesystem.duplicate")
        XCTAssertEqual(object["canExecute"] as? Bool, false)
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(policyCheck["ok"] as? Bool, false)
        XCTAssertEqual(policyCheck["code"] as? String, "denied")
    }

    func testFilesPlanPreflightsRollbackWithoutRestoring() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-plan-rollback-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "rollback plan".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "move before rollback plan",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(move.status, 0, move.stderr)
        let moveObject = try decodeJSONObject(move.stdout)
        let moveAuditID = try XCTUnwrap(moveObject["auditID"] as? String)

        let result = try runLn1([
            "files",
            "plan",
            "--operation", "rollback",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))

        let object = try decodeJSONObject(result.stdout)
        let sourceTarget = try XCTUnwrap(object["source"] as? [String: Any])
        let destinationTarget = try XCTUnwrap(object["destination"] as? [String: Any])
        let checks = try XCTUnwrap(object["checks"] as? [[String: Any]])
        let checkByName = Dictionary(uniqueKeysWithValues: checks.compactMap { check -> (String, [String: Any])? in
            guard let name = check["name"] as? String else {
                return nil
            }
            return (name, check)
        })

        XCTAssertEqual(object["operation"] as? String, "rollback")
        XCTAssertEqual(object["action"] as? String, "filesystem.rollbackMove")
        XCTAssertEqual(object["rollbackOfAuditID"] as? String, moveAuditID)
        XCTAssertEqual(object["canExecute"] as? Bool, true)
        XCTAssertEqual(sourceTarget["path"] as? String, destination.path)
        XCTAssertEqual(sourceTarget["exists"] as? Bool, true)
        XCTAssertEqual(destinationTarget["path"] as? String, source.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, false)
        XCTAssertEqual(checkByName["auditRecordFound"]?["ok"] as? Bool, true)
        XCTAssertEqual(checkByName["rollbackSourceMatchesAudit"]?["ok"] as? Bool, true)
        XCTAssertEqual(checkByName["restoreDestinationMissing"]?["ok"] as? Bool, true)
    }

    func testFilesDuplicateCopiesRegularFileWithAuditAndVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-duplicate-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "copy me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "test duplicate",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "copy me")

        let object = try decodeJSONObject(result.stdout)
        let sourceObject = try XCTUnwrap(object["source"] as? [String: Any])
        let destinationObject = try XCTUnwrap(object["destination"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.duplicate")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(sourceObject["path"] as? String, source.path)
        XCTAssertEqual(destinationObject["path"] as? String, destination.path)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "metadata_matched")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.duplicate")
        XCTAssertEqual(entry["action"] as? String, "filesystem.duplicate")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "test duplicate")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "duplicated")
    }

    func testFilesDuplicatePolicyDenialIsAuditedAndDoesNotCopy() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-duplicate-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "do not copy".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", destination.path,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))

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
        let sourceTarget = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let destinationTarget = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.duplicate")
        XCTAssertEqual(entry["action"] as? String, "filesystem.duplicate")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(sourceTarget["path"] as? String, source.path)
        XCTAssertEqual(sourceTarget["exists"] as? Bool, true)
        XCTAssertEqual(destinationTarget["path"] as? String, destination.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testFilesMoveRenamesRegularFileWithAuditAndVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-move-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "move me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "test move",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: destination, encoding: .utf8), "move me")

        let object = try decodeJSONObject(result.stdout)
        let sourceObject = try XCTUnwrap(object["source"] as? [String: Any])
        let destinationObject = try XCTUnwrap(object["destination"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.move")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(sourceObject["path"] as? String, source.path)
        XCTAssertEqual(destinationObject["path"] as? String, destination.path)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "moved_and_metadata_matched")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.move")
        XCTAssertEqual(entry["action"] as? String, "filesystem.move")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "test move")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "moved")
    }

    func testFilesMovePolicyDenialIsAuditedAndDoesNotMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-move-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay put".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))

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
        let sourceTarget = try XCTUnwrap(entry["fileSource"] as? [String: Any])
        let destinationTarget = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.move")
        XCTAssertEqual(entry["action"] as? String, "filesystem.move")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(sourceTarget["path"] as? String, source.path)
        XCTAssertEqual(sourceTarget["exists"] as? Bool, true)
        XCTAssertEqual(destinationTarget["path"] as? String, destination.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testFilesRollbackRestoresAuditedMoveWithVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-rollback-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "restore me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "move before rollback",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(move.status, 0, move.stderr)
        let moveObject = try decodeJSONObject(move.stdout)
        let moveAuditID = try XCTUnwrap(moveObject["auditID"] as? String)

        let rollback = try runLn1([
            "files",
            "rollback",
            "--audit-id", moveAuditID,
            "--allow-risk", "medium",
            "--reason", "undo move",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(rollback.status, 0, rollback.stderr)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertEqual(try String(contentsOf: source, encoding: .utf8), "restore me")

        let object = try decodeJSONObject(rollback.stdout)
        let restoredSource = try XCTUnwrap(object["restoredSource"] as? [String: Any])
        let previousDestination = try XCTUnwrap(object["previousDestination"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.rollbackMove")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["rollbackOfAuditID"] as? String, moveAuditID)
        XCTAssertEqual(restoredSource["path"] as? String, source.path)
        XCTAssertEqual(previousDestination["path"] as? String, destination.path)
        XCTAssertEqual(previousDestination["exists"] as? Bool, false)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "move_restored")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.rollback",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.rollback")
        XCTAssertEqual(entry["action"] as? String, "filesystem.rollbackMove")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "undo move")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "rolled_back_move")
    }

    func testFilesRollbackPolicyDenialIsAuditedAndDoesNotRestoreMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-rollback-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay archived".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runLn1([
            "files",
            "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "move before denied rollback",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(move.status, 0, move.stderr)
        let moveObject = try decodeJSONObject(move.stdout)
        let moveAuditID = try XCTUnwrap(moveObject["auditID"] as? String)

        let rejected = try runLn1([
            "files",
            "rollback",
            "--audit-id", moveAuditID,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.rollback",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.rollback")
        XCTAssertEqual(entry["action"] as? String, "filesystem.rollbackMove")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testFilesMkdirCreatesDirectoryWithAuditAndVerification() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-mkdir-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runLn1([
            "files",
            "mkdir",
            "--path", created.path,
            "--allow-risk", "medium",
            "--reason", "test mkdir",
            "--audit-log", auditLog.path
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: created.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)

        let object = try decodeJSONObject(result.stdout)
        let directoryObject = try XCTUnwrap(object["directory"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.createDirectory")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(directoryObject["path"] as? String, created.path)
        XCTAssertEqual(directoryObject["kind"] as? String, "directory")
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "directory_exists")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let destinationTarget = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.mkdir")
        XCTAssertEqual(entry["action"] as? String, "filesystem.createDirectory")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "test mkdir")
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(destinationTarget["path"] as? String, created.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "created_directory")
    }

    func testFilesMkdirPolicyDenialIsAuditedAndDoesNotCreateDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-mkdir-policy-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "files",
            "mkdir",
            "--path", created.path,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: created.path))

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
        let destinationTarget = try XCTUnwrap(entry["fileDestination"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.mkdir")
        XCTAssertEqual(entry["action"] as? String, "filesystem.createDirectory")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "medium")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(destinationTarget["path"] as? String, created.path)
        XCTAssertEqual(destinationTarget["exists"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    func testAuditCommandReturnsEmptyEntriesForMissingLog() throws {
        let missingLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-missing-\(UUID().uuidString).jsonl")
        let result = try runLn1([
            "audit",
            "--audit-log", missingLog.path,
            "--limit", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        XCTAssertEqual(object["path"] as? String, missingLog.path)
        XCTAssertEqual((object["entries"] as? [Any])?.count, 0)
    }

    func testAuditCommandFiltersByCommandAndOutcomeCodeBeforeLimit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-audit-filter-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "copy".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try runLn1([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", directory.appendingPathComponent("copy.txt").path,
            "--reason", "policy duplicate",
            "--audit-log", auditLog.path
        ])
        _ = try runLn1([
            "files",
            "mkdir",
            "--path", created.path,
            "--allow-risk", "medium",
            "--reason", "allowed mkdir",
            "--audit-log", auditLog.path
        ])

        let commandFiltered = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.mkdir",
            "--limit", "1"
        ])

        XCTAssertEqual(commandFiltered.status, 0, commandFiltered.stderr)
        let commandObject = try decodeJSONObject(commandFiltered.stdout)
        let commandEntries = try XCTUnwrap(commandObject["entries"] as? [[String: Any]])
        let commandEntry = try XCTUnwrap(commandEntries.first)
        let commandOutcome = try XCTUnwrap(commandEntry["outcome"] as? [String: Any])

        XCTAssertEqual(commandObject["command"] as? String, "files.mkdir")
        XCTAssertEqual(commandObject["limit"] as? Int, 1)
        XCTAssertEqual(commandEntries.count, 1)
        XCTAssertEqual(commandEntry["command"] as? String, "files.mkdir")
        XCTAssertEqual(commandOutcome["code"] as? String, "created_directory")

        let codeFiltered = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--code", "policy_denied",
            "--limit", "5"
        ])

        XCTAssertEqual(codeFiltered.status, 0, codeFiltered.stderr)
        let codeObject = try decodeJSONObject(codeFiltered.stdout)
        let codeEntries = try XCTUnwrap(codeObject["entries"] as? [[String: Any]])
        let codeEntry = try XCTUnwrap(codeEntries.first)
        let codeOutcome = try XCTUnwrap(codeEntry["outcome"] as? [String: Any])

        XCTAssertEqual(codeObject["code"] as? String, "policy_denied")
        XCTAssertEqual(codeEntries.count, 1)
        XCTAssertEqual(codeEntry["command"] as? String, "files.duplicate")
        XCTAssertEqual(codeOutcome["code"] as? String, "policy_denied")
    }

    func testClipboardStateReturnsMetadataWithoutTextContents() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer { pasteboard.clearContents() }

        let result = try runLn1([
            "clipboard",
            "state",
            "--pasteboard", pasteboardName
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let actions = try XCTUnwrap(object["actions"] as? [[String: Any]])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["hasString"] as? Bool, true)
        XCTAssertEqual(object["stringLength"] as? Int, 15)
        XCTAssertEqual(object["stringDigest"] as? String, "65b2b576750477c2424fc19794e6c3c5ac6821e29e8464294aed6aa8485304c2")
        XCTAssertNil(object["text"])
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.state" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.wait" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.readText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.writeText" })
    }

    func testClipboardWaitReturnsMetadataWithoutTextContents() throws {
        let pasteboardName = "Ln1-test-wait-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)

        let before = try runLn1([
            "clipboard",
            "state",
            "--pasteboard", pasteboardName
        ])
        XCTAssertEqual(before.status, 0, before.stderr)
        let beforeObject = try decodeJSONObject(before.stdout)
        let beforeChangeCount = try XCTUnwrap(beforeObject["changeCount"] as? Int)

        let write = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "new clipboard",
            "--allow-risk", "medium",
            "--reason", "prepare clipboard wait test"
        ])
        XCTAssertEqual(write.status, 0, write.stderr)
        let writeObject = try decodeJSONObject(write.stdout)
        let writtenDigest = try XCTUnwrap(writeObject["writtenDigest"] as? String)

        let wait = try runLn1([
            "clipboard",
            "wait",
            "--pasteboard", pasteboardName,
            "--changed-from", String(beforeChangeCount),
            "--has-string", "true",
            "--string-digest", writtenDigest.uppercased(),
            "--timeout-ms", "0",
            "--interval-ms", "50"
        ])

        XCTAssertEqual(wait.status, 0, wait.stderr)
        let object = try decodeJSONObject(wait.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [String: Any])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(object["intervalMilliseconds"] as? Int, 50)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "clipboard_matched")
        XCTAssertEqual(verification["changedFrom"] as? Int, beforeChangeCount)
        XCTAssertEqual(verification["expectedHasString"] as? Bool, true)
        XCTAssertEqual(verification["expectedStringDigest"] as? String, writtenDigest)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertEqual(current["hasString"] as? Bool, true)
        XCTAssertEqual(current["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringDigest"] as? String, writtenDigest)
        XCTAssertNil(object["text"])
        XCTAssertNil(verification["text"])
        XCTAssertNil(current["text"])
    }

    func testClipboardReadTextRequiresMediumRiskAndAuditsRead() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-clipboard-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runLn1([
            "clipboard",
            "read-text",
            "--pasteboard", pasteboardName,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "clipboard",
            "read-text",
            "--pasteboard", pasteboardName,
            "--allow-risk", "medium",
            "--max-characters", "5",
            "--audit-log", auditLog.path,
            "--reason", "read test clipboard"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["hasString"] as? Bool, true)
        XCTAssertEqual(object["text"] as? String, "hello")
        XCTAssertEqual(object["stringLength"] as? Int, 15)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxCharacters"] as? Int, 5)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.read-text",
            "--code", "read_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let clipboard = try XCTUnwrap(entry["clipboard"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "clipboard.read-text")
        XCTAssertEqual(entry["action"] as? String, "clipboard.readText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "read test clipboard")
        XCTAssertEqual(clipboard["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(clipboard["stringLength"] as? Int, 15)
        XCTAssertNil(clipboard["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_text")
    }

    func testClipboardWriteTextRequiresMediumRiskVerifiesAndAuditsWithoutText() throws {
        let pasteboardName = "Ln1-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-clipboard-write-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "blocked clipboard",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.write-text",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])
        let deniedBefore = try XCTUnwrap(deniedEntry["clipboardBefore"] as? [String: Any])
        let deniedAfter = try XCTUnwrap(deniedEntry["clipboardAfter"] as? [String: Any])
        let deniedOutcome = try XCTUnwrap(deniedEntry["outcome"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "clipboard.writeText")
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)
        XCTAssertEqual(deniedAfter["stringDigest"] as? String, deniedBefore["stringDigest"] as? String)
        XCTAssertEqual(deniedOutcome["code"] as? String, "policy_denied")

        let result = try runLn1([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "new clipboard",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "write test clipboard"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        XCTAssertEqual(pasteboard.string(forType: .string), "new clipboard")

        let object = try decodeJSONObject(result.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(object["writtenLength"] as? Int, 13)
        XCTAssertEqual(previous["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringLength"] as? Int, 13)
        XCTAssertEqual(current["stringDigest"] as? String, object["writtenDigest"] as? String)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_matched")
        XCTAssertNil(object["text"])

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "clipboard.write-text",
            "--code", "wrote_text",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let before = try XCTUnwrap(entry["clipboardBefore"] as? [String: Any])
        let after = try XCTUnwrap(entry["clipboardAfter"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let auditVerification = try XCTUnwrap(entry["verification"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "clipboard.write-text")
        XCTAssertEqual(entry["action"] as? String, "clipboard.writeText")
        XCTAssertEqual(entry["risk"] as? String, "medium")
        XCTAssertEqual(entry["reason"] as? String, "write test clipboard")
        XCTAssertEqual(before["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(after["pasteboard"] as? String, pasteboardName)
        XCTAssertEqual(after["stringLength"] as? Int, 13)
        XCTAssertNil(after["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(auditVerification["ok"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "wrote_text")
    }

    func testRejectedPerformWritesAuditRecord() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-audit-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "perform",
            "--audit-log", auditLog.path,
            "--reason", "verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let object = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "perform")
        XCTAssertEqual(entry["reason"] as? String, "verification")
        XCTAssertEqual(entry["action"] as? String, "AXPress")
        XCTAssertEqual(entry["risk"] as? String, "low")
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "rejected")
    }

    func testPerformPolicyDenialIsAuditedBeforeAccessibilityTrust() throws {
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runLn1([
            "perform",
            "--audit-log", auditLog.path,
            "--element", "w0",
            "--action", "AXCustomAction",
            "--allow-risk", "low",
            "--reason", "policy verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

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

        XCTAssertEqual(entry["command"] as? String, "perform")
        XCTAssertEqual(entry["reason"] as? String, "policy verification")
        XCTAssertEqual(entry["elementID"] as? String, "w0")
        XCTAssertEqual(entry["action"] as? String, "AXCustomAction")
        XCTAssertEqual(entry["risk"] as? String, "unknown")
        XCTAssertEqual(policy["allowedRisk"] as? String, "low")
        XCTAssertEqual(policy["actionRisk"] as? String, "unknown")
        XCTAssertEqual(policy["allowed"] as? Bool, false)
        XCTAssertEqual(outcome["ok"] as? Bool, false)
        XCTAssertEqual(outcome["code"] as? String, "policy_denied")
    }

    private func runLn1(_ arguments: [String]) throws -> ProcessResult {
        let executable = packageRoot.appendingPathComponent(".build/debug/Ln1")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: executable.path), "Run swift build before swift test.")
        return try runProcess(executable.path, arguments: arguments)
    }

    private func runProcess(_ executable: String, arguments: [String]) throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = packageRoot

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return ProcessResult(
            status: process.terminationStatus,
            stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }

    private func decodeJSONObject(_ string: String) throws -> [String: Any] {
        let data = try XCTUnwrap(string.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    private func decodeJSON(_ string: String) throws -> Any {
        let data = try XCTUnwrap(string.data(using: .utf8))
        return try JSONSerialization.jsonObject(with: data)
    }

    private func writeJSONObjectLine(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let line = String(decoding: data, as: UTF8.self) + "\n"
        try line.write(to: url, atomically: true, encoding: .utf8)
    }

    private var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

private struct ProcessResult {
    let status: Int32
    let stdout: String
    let stderr: String
}
