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
        XCTAssertEqual(actionByName["browser.navigate"]?["domain"] as? String, "browser")
        XCTAssertEqual(actionByName["browser.navigate"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["browser.navigate"]?["mutates"] as? Bool, true)
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
            $0["name"] as? String == "browser.navigate"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == true
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
        XCTAssertEqual(link["role"] as? String, "link")
        XCTAssertEqual(link["text"] as? String, "Docs")
        XCTAssertEqual(linkAttributes["href"] as? String, "https://example.com/docs")
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
