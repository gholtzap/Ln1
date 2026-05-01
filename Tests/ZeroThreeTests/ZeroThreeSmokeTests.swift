import AppKit
import Foundation
import XCTest

final class ZeroThreeSmokeTests: XCTestCase {
    func testPolicyCommandReturnsKnownActionRiskClassifications() throws {
        let result = try runZeroThree(["policy"])

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
        XCTAssertEqual(actionByName["desktop.listWindows"]?["domain"] as? String, "desktop")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["desktop.listWindows"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.search"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.search"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.watch"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.watch"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.plan"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.plan"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.move"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.move"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.createDirectory"]?["domain"] as? String, "filesystem")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.rollbackMove"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["clipboard.state"]?["domain"] as? String, "clipboard")
        XCTAssertEqual(actionByName["clipboard.state"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["clipboard.state"]?["mutates"] as? Bool, false)
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
        XCTAssertEqual(actionByName["browser.waitText"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitText"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitText"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["browser.waitReady"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.waitReady"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["browser.waitReady"]?["mutates"] as? Bool, false)
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
        let result = try runZeroThree([
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
        let result = try runZeroThree([
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
    }

    func testDoctorReturnsReadinessChecksWithRemediation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-doctor-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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
        let result = try runZeroThree([
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

    func testWorkflowPreflightMoveFileUsesFilesystemPlanChecks() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-workflow-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("destination.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
        XCTAssertTrue((object["nextCommand"] as? String)?.contains("03 files move") == true)
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "03", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue(prerequisites.contains { $0["name"] as? String == "filesystem.sourceExists" && $0["status"] as? String == "pass" })
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowPreflightBrowserActionsReturnTypedCommands() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-workflow-browser-action-\(UUID().uuidString)")
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

        let fill = try runZeroThree([
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
            "03", "browser", "fill",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "search text",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let click = try runZeroThree([
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
            "03", "browser", "click",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let clickWithExpectedURL = try runZeroThree([
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
            "03", "browser", "click",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--expect-url", "https://example.com/results",
            "--match", "prefix",
            "--timeout-ms", "750",
            "--interval-ms", "50",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let navigate = try runZeroThree([
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
            "03", "browser", "navigate",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--url", "https://example.com/next",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])

        let waitURL = try runZeroThree([
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
            "03", "browser", "wait-url",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--expect-url", "https://example.com/next",
            "--match", "exact",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitSelector = try runZeroThree([
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
            "03", "browser", "wait-selector",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--selector", "button[type=\"submit\"]",
            "--state", "visible",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitText = try runZeroThree([
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
            "03", "browser", "wait-text",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--text", "Saved successfully",
            "--match", "contains",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])

        let waitReady = try runZeroThree([
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
            "03", "browser", "wait-ready",
            "--endpoint", directory.standardizedFileURL.absoluteString,
            "--id", "page-1",
            "--state", "interactive",
            "--timeout-ms", "500",
            "--interval-ms", "50"
        ])
    }

    func testWorkflowNextReturnsStructuredArgvWithoutExecutingMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03 workflow next \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            "03", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((command["display"] as? String)?.contains("'") == true)
        XCTAssertTrue((command["display"] as? String)?.contains("source file.txt") == true)
        XCTAssertEqual(command["requiresReason"] as? Bool, true)
        XCTAssertEqual(preflight["canProceed"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testWorkflowRunDryRunReportsWouldExecuteWithoutExecutingMove() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03 workflow run \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            "03", "files", "move",
            "--path", source.path,
            "--to", destination.path,
            "--allow-risk", "medium",
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
            .appendingPathComponent("03-workflow-run-browser-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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

    func testWorkflowRunCapsExecutionOutputAndSkipsTruncatedJSONParsing() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-workflow-run-cap-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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
            .appendingPathComponent("03-workflow-run-timeout-\(UUID().uuidString)")
        let missingPath = directory.appendingPathComponent("missing.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-workflow-log-\(UUID().uuidString)")
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

        let run = try runZeroThree([
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

        let denied = try runZeroThree([
            "workflow",
            "log",
            "--workflow-log", workflowLog.path
        ])

        XCTAssertNotEqual(denied.status, 0)
        XCTAssertTrue(denied.stderr.contains("policy denied"))

        let log = try runZeroThree([
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

        let resume = try runZeroThree([
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
            "03", "workflow", "run",
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
            .appendingPathComponent("03-workflow-dom-resume-\(UUID().uuidString)")
        let fillWorkflowLog = directory.appendingPathComponent("fill-workflow-runs.jsonl")
        let clickWorkflowLog = directory.appendingPathComponent("click-workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let baseExecution: [String: Any] = [
            "argv": [
                "03", "browser", "dom",
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

        let fillResume = try runZeroThree([
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
            "03", "browser", "fill",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "Describe text",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((fillObject["message"] as? String)?.contains("text field") == true)

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

        let clickResume = try runZeroThree([
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
            "03", "browser", "click",
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
            .appendingPathComponent("03-workflow-url-wait-resume-\(UUID().uuidString)")
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
                    "03", "browser", "wait-url",
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

        let resume = try runZeroThree([
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
            "03", "workflow", "run",
            "--operation", "read-browser",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("DOM inspection") == true)
    }

    func testWorkflowResumeSuggestsBrowserActionsAfterSelectorWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-workflow-selector-wait-resume-\(UUID().uuidString)")
        let clickWorkflowLog = directory.appendingPathComponent("click-workflow-runs.jsonl")
        let fillWorkflowLog = directory.appendingPathComponent("fill-workflow-runs.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let endpoint = "file://\(directory.path)/"
        let baseExecution: [String: Any] = [
            "argv": [
                "03", "browser", "wait-selector",
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

        let clickResume = try runZeroThree([
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
            "03", "browser", "click",
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

        let fillResume = try runZeroThree([
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
            "03", "browser", "fill",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--selector", "input[name=\"q\"]",
            "--text", "Describe text",
            "--allow-risk", "medium",
            "--reason", "Describe intent"
        ])
        XCTAssertTrue((fillObject["message"] as? String)?.contains("text field") == true)
    }

    func testWorkflowResumeSuggestsDOMInspectionAfterBrowserTextWait() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-workflow-text-wait-resume-\(UUID().uuidString)")
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
                    "03", "browser", "wait-text",
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

        let resume = try runZeroThree([
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
            "03", "workflow", "run",
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
            .appendingPathComponent("03-workflow-ready-wait-resume-\(UUID().uuidString)")
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
                    "03", "browser", "wait-ready",
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

        let resume = try runZeroThree([
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
            "03", "workflow", "run",
            "--operation", "read-browser",
            "--endpoint", endpoint,
            "--id", "page-1",
            "--dry-run", "true",
            "--workflow-log", workflowLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("DOM inspection") == true)
    }

    func testWorkflowRunRejectsMutatingExecutionMode() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03 workflow run reject \(UUID().uuidString)")
        let source = directory.appendingPathComponent("source file.txt")
        let destination = directory.appendingPathComponent("destination file.txt")
        let auditLog = directory.appendingPathComponent("audit log.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "workflow".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
        XCTAssertTrue(result.stderr.contains("workflow run execution currently supports non-mutating commands only"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testSchemaDocumentsStableAccessibilityElementIdentities() throws {
        let result = try runZeroThree(["schema"])

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
        let result = try runZeroThree(["schema"])

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
            .appendingPathComponent("03-task-memory-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let start = try runZeroThree([
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

        let record = try runZeroThree([
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

        let finish = try runZeroThree([
            "task",
            "finish",
            "--task-id", taskID,
            "--status", "completed",
            "--summary", "Download was verified.",
            "--allow-risk", "medium",
            "--memory-log", memoryLog.path
        ])

        XCTAssertEqual(finish.status, 0, finish.stderr)

        let show = try runZeroThree([
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
            .appendingPathComponent("03-task-memory-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: memoryLog) }

        let rejected = try runZeroThree([
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
            .appendingPathComponent("03-browser-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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
            $0["name"] as? String == "browser.waitText"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.waitReady"
                && $0["risk"] as? String == "low"
                && $0["mutates"] as? Bool == false
        })

        let tabResult = try runZeroThree([
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
            .appendingPathComponent("03-browser-text-\(UUID().uuidString)")
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

        let rejected = try runZeroThree([
            "browser",
            "text",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runZeroThree([
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

        let deniedAudit = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-browser-dom-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)

        let domSnapshot: [String: Any] = [
            "url": "https://example.com/form",
            "title": "Example Form",
            "elementCount": 3,
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

        let rejected = try runZeroThree([
            "browser",
            "dom",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runZeroThree([
            "browser",
            "dom",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-elements", "3",
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
        let linkAttributes = try XCTUnwrap(link["attributes"] as? [String: Any])
        let inputAttributes = try XCTUnwrap(input["attributes"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.readDOM")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["url"] as? String, "https://example.com/form")
        XCTAssertEqual(object["title"] as? String, "Example Form")
        XCTAssertEqual(object["elementCount"] as? Int, 3)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxElements"] as? Int, 3)
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

        let deniedAudit = try runZeroThree([
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

        let audit = try runZeroThree([
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
        XCTAssertEqual(browserTab["domNodeCount"] as? Int, 3)
        XCTAssertNotNil(browserTab["domDigest"])
        XCTAssertNil(browserTab["elements"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_dom")
    }

    func testBrowserFillSetsFormFieldWithPolicyVerificationAndRedactedAudit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-browser-fill-\(UUID().uuidString)")
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

        let rejected = try runZeroThree([
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

        let result = try runZeroThree([
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

        let deniedAudit = try runZeroThree([
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

        let audit = try runZeroThree([
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

    func testBrowserClickRequiresPolicyVerifiesAndAuditsSelectorOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-browser-click-\(UUID().uuidString)")
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

        let rejected = try runZeroThree([
            "browser",
            "click",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--selector", "button[type='submit']",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runZeroThree([
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

        let deniedAudit = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-browser-click-url-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-browser-navigate-\(UUID().uuidString)")
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

        let rejected = try runZeroThree([
            "browser",
            "navigate",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--url", "https://example.com/blocked",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runZeroThree([
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

        let deniedAudit = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-browser-wait-url-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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
            .appendingPathComponent("03-browser-wait-selector-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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

    func testBrowserWaitTextReturnsVerificationWithoutTextContents() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-browser-wait-text-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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

    func testBrowserWaitReadyReturnsVerificationWithoutMutating() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-browser-wait-ready-\(UUID().uuidString)")
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

        let result = try runZeroThree([
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

    func testFilesStatReturnsStructuredMetadataForFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-files-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
    }

    func testFilesListReturnsDirectoryEntriesWithoutHiddenFilesByDefault() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-files-\(UUID().uuidString)")
        let nested = directory.appendingPathComponent("nested")
        let visible = directory.appendingPathComponent("visible.txt")
        let hidden = directory.appendingPathComponent(".secret")
        let inner = nested.appendingPathComponent("inner.txt")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "visible".write(to: visible, atomically: true, encoding: .utf8)
        try "hidden".write(to: hidden, atomically: true, encoding: .utf8)
        try "inner".write(to: inner, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-search-\(UUID().uuidString)")
        let nested = directory.appendingPathComponent("nested")
        let contentMatch = directory.appendingPathComponent("alpha.txt")
        let nameMatch = nested.appendingPathComponent("needle-name.txt")
        let hiddenMatch = directory.appendingPathComponent(".hidden.txt")

        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "first line\nThe Needle appears here\nlast line".write(to: contentMatch, atomically: true, encoding: .utf8)
        try "ordinary text".write(to: nameMatch, atomically: true, encoding: .utf8)
        try "needle should be skipped".write(to: hiddenMatch, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-search-limit-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("many.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "needle one\nneedle two\nneedle three".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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

    func testFilesWaitReturnsMatchedExistingFileMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-wait-exists-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("ready.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "ready".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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

    func testFilesWaitReturnsMatchedMissingPathWithoutMetadata() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-wait-missing-\(UUID().uuidString)")
        let missing = directory.appendingPathComponent("missing.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-watch-created-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("created.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            try? "created".write(to: created, atomically: true, encoding: .utf8)
        }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-watch-timeout-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-checksum-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("hello.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "hello".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-compare-match-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "same".write(to: left, atomically: true, encoding: .utf8)
        try "same".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-compare-different-\(UUID().uuidString)")
        let left = directory.appendingPathComponent("left.txt")
        let right = directory.appendingPathComponent("right.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "left".write(to: left, atomically: true, encoding: .utf8)
        try "right".write(to: right, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-plan-move-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "plan me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-plan-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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
            .appendingPathComponent("03-plan-rollback-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "rollback plan".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runZeroThree([
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

        let result = try runZeroThree([
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
            .appendingPathComponent("03-duplicate-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "copy me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-duplicate-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let destination = directory.appendingPathComponent("copy.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "do not copy".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runZeroThree([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", destination.path,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-move-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "move me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-move-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay put".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-rollback-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "restore me".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runZeroThree([
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

        let rollback = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-rollback-policy-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("draft.txt")
        let destination = directory.appendingPathComponent("archive.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "stay archived".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let move = try runZeroThree([
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

        let rejected = try runZeroThree([
            "files",
            "rollback",
            "--audit-id", moveAuditID,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path))

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-mkdir-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-mkdir-policy-\(UUID().uuidString)")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runZeroThree([
            "files",
            "mkdir",
            "--path", created.path,
            "--reason", "policy test",
            "--audit-log", auditLog.path
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: created.path))

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-missing-\(UUID().uuidString).jsonl")
        let result = try runZeroThree([
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
            .appendingPathComponent("03-audit-filter-\(UUID().uuidString)")
        let source = directory.appendingPathComponent("source.txt")
        let created = directory.appendingPathComponent("archive")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "copy".write(to: source, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try runZeroThree([
            "files",
            "duplicate",
            "--path", source.path,
            "--to", directory.appendingPathComponent("copy.txt").path,
            "--reason", "policy duplicate",
            "--audit-log", auditLog.path
        ])
        _ = try runZeroThree([
            "files",
            "mkdir",
            "--path", created.path,
            "--allow-risk", "medium",
            "--reason", "allowed mkdir",
            "--audit-log", auditLog.path
        ])

        let commandFiltered = try runZeroThree([
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

        let codeFiltered = try runZeroThree([
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
        let pasteboardName = "03-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer { pasteboard.clearContents() }

        let result = try runZeroThree([
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
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.readText" })
        XCTAssertTrue(actions.contains { $0["name"] as? String == "clipboard.writeText" })
    }

    func testClipboardReadTextRequiresMediumRiskAndAuditsRead() throws {
        let pasteboardName = "03-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-clipboard-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("hello clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runZeroThree([
            "clipboard",
            "read-text",
            "--pasteboard", pasteboardName,
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
        let pasteboardName = "03-test-\(UUID().uuidString)"
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(rawValue: pasteboardName))
        let auditLog = FileManager.default.temporaryDirectory
            .appendingPathComponent("03-clipboard-write-\(UUID().uuidString).jsonl")
        pasteboard.clearContents()
        pasteboard.setString("old clipboard", forType: .string)
        defer {
            pasteboard.clearContents()
            try? FileManager.default.removeItem(at: auditLog)
        }

        let rejected = try runZeroThree([
            "clipboard",
            "write-text",
            "--pasteboard", pasteboardName,
            "--text", "blocked clipboard",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)
        XCTAssertEqual(pasteboard.string(forType: .string), "old clipboard")

        let deniedAudit = try runZeroThree([
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

        let result = try runZeroThree([
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

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-audit-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runZeroThree([
            "perform",
            "--audit-log", auditLog.path,
            "--reason", "verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runZeroThree([
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
            .appendingPathComponent("03-policy-\(UUID().uuidString).jsonl")
        defer { try? FileManager.default.removeItem(at: auditLog) }

        let rejected = try runZeroThree([
            "perform",
            "--audit-log", auditLog.path,
            "--element", "w0",
            "--action", "AXCustomAction",
            "--allow-risk", "low",
            "--reason", "policy verification"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let audit = try runZeroThree([
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

    private func runZeroThree(_ arguments: [String]) throws -> ProcessResult {
        let executable = packageRoot.appendingPathComponent(".build/debug/03")
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
