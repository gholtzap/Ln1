import Foundation
import XCTest

final class Ln1BrowserSmokeTests: Ln1TestCase {
    func testBrowserLaunchPlansIsolatedProfileAndDevToolsEndpoint() throws {
        let profile = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-profile-\(UUID().uuidString)")
        let downloads = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-downloads-\(UUID().uuidString)")
        let executable = FileManager.default.temporaryDirectory
            .appendingPathComponent("Fake Chromium")

        let result = try runLn1([
            "browser",
            "launch",
            "--browser", "chromium",
            "--executable", executable.path,
            "--profile", profile.path,
            "--download-dir", downloads.path,
            "--remote-debugging-port", "9333",
            "--url", "https://example.com/start",
            "--allow-risk", "medium",
            "--dry-run", "true"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let arguments = try XCTUnwrap(object["arguments"] as? [String])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["action"] as? String, "browser.launch")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["browser"] as? String, "chromium")
        XCTAssertEqual(object["executablePath"] as? String, executable.path)
        XCTAssertEqual(object["profilePath"] as? String, profile.path)
        XCTAssertEqual(object["downloadDirectoryPath"] as? String, downloads.path)
        XCTAssertEqual(
            object["preferencesPath"] as? String,
            profile.appendingPathComponent("Default").appendingPathComponent("Preferences").path
        )
        XCTAssertEqual(
            object["preferenceKeys"] as? [String],
            ["download.default_directory", "download.prompt_for_download"]
        )
        XCTAssertEqual(object["endpoint"] as? String, "http://127.0.0.1:9333")
        XCTAssertEqual(object["remoteDebuggingPort"] as? Int, 9333)
        XCTAssertEqual(object["url"] as? String, "https://example.com/start")
        XCTAssertEqual(object["dryRun"] as? Bool, true)
        XCTAssertEqual(object["launched"] as? Bool, false)
        XCTAssertNil(object["pid"])
        XCTAssertEqual(arguments.first, executable.path)
        XCTAssertTrue(arguments.contains("--remote-debugging-port=9333"))
        XCTAssertTrue(arguments.contains("--user-data-dir=\(profile.path)"))
        XCTAssertTrue(arguments.contains("--no-first-run"))
        XCTAssertTrue(arguments.contains("--no-default-browser-check"))
        XCTAssertEqual(arguments.last, "https://example.com/start")
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
            $0["name"] as? String == "browser.captureScreenshot"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.readConsole"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.readDialogs"
                && $0["risk"] as? String == "medium"
                && $0["mutates"] as? Bool == false
        })
        XCTAssertTrue(firstPageActions.contains {
            $0["name"] as? String == "browser.readNetwork"
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

    func testBrowserScreenshotCapturesMetadataWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-screenshot-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("capture-screenshot.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let pngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        {
          "id": 1,
          "result": {
            "data": "\(pngBase64)"
          }
        }
        """.write(to: cdpResponse, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Canvas Page",
            "url": "https://example.com/canvas",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "screenshot",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "screenshot",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--format", "png",
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "capture canvas state"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let digest = try XCTUnwrap(object["digest"] as? String)

        XCTAssertEqual(object["action"] as? String, "browser.captureScreenshot")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["format"] as? String, "png")
        XCTAssertGreaterThan(object["byteCount"] as? Int ?? 0, 0)
        XCTAssertEqual(digest.count, 64)
        XCTAssertEqual(tab["id"] as? String, "page-1")
        XCTAssertNil(object["data"])
        XCTAssertNil(object["image"])

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.screenshot",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.captureScreenshot")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertEqual(deniedBrowserTab["screenshotFormat"] as? String, "png")
        XCTAssertNil(deniedBrowserTab["screenshotByteCount"])
        XCTAssertNil(deniedBrowserTab["screenshotDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.screenshot",
            "--code", "captured_screenshot",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.screenshot")
        XCTAssertEqual(entry["action"] as? String, "browser.captureScreenshot")
        XCTAssertEqual(entry["reason"] as? String, "capture canvas state")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Canvas Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/canvas")
        XCTAssertEqual(browserTab["screenshotFormat"] as? String, "png")
        XCTAssertEqual(browserTab["screenshotByteCount"] as? Int, object["byteCount"] as? Int)
        XCTAssertEqual(browserTab["screenshotDigest"] as? String, digest)
        XCTAssertNil(browserTab["data"])
        XCTAssertNil(browserTab["image"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "captured_screenshot")
    }

    func testBrowserConsoleReadsEventsWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-console-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpEvents = directory.appendingPathComponent("console-events.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "method": "Runtime.consoleAPICalled",
            "params": {
              "type": "error",
              "timestamp": 1234.5,
              "args": [
                { "type": "string", "value": "first issue" },
                { "type": "number", "value": 42 }
              ]
            }
          },
          {
            "method": "Log.entryAdded",
            "params": {
              "entry": {
                "source": "network",
                "level": "warning",
                "text": "request warning",
                "url": "https://example.com/app.js",
                "lineNumber": 12,
                "timestamp": 1235.25
              }
            }
          }
        ]
        """.write(to: cdpEvents, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Console Page",
            "url": "https://example.com/console",
            "webSocketDebuggerUrl": "\(cdpEvents.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "console",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "console",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-entries", "2",
            "--max-message-characters", "10",
            "--sample-ms", "1",
            "--audit-log", auditLog.path,
            "--reason", "inspect console metadata"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let digest = try XCTUnwrap(object["digest"] as? String)
        let first = try XCTUnwrap(entries.first)
        let second = try XCTUnwrap(entries.last)

        XCTAssertEqual(object["action"] as? String, "browser.readConsole")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["entryCount"] as? Int, 2)
        XCTAssertEqual(object["returnedCount"] as? Int, 2)
        XCTAssertEqual(object["truncated"] as? Bool, false)
        XCTAssertEqual(object["maxEntries"] as? Int, 2)
        XCTAssertEqual(object["maxMessageCharacters"] as? Int, 10)
        XCTAssertEqual(object["sampleMilliseconds"] as? Int, 1)
        XCTAssertEqual(first["source"] as? String, "runtime")
        XCTAssertEqual(first["level"] as? String, "error")
        XCTAssertEqual(first["text"] as? String, "first issu")
        XCTAssertEqual(first["textLength"] as? Int, 14)
        XCTAssertEqual(first["truncated"] as? Bool, true)
        XCTAssertNotNil(first["textDigest"])
        XCTAssertEqual(second["source"] as? String, "network")
        XCTAssertEqual(second["url"] as? String, "https://example.com/app.js")
        XCTAssertEqual(second["lineNumber"] as? Int, 12)
        XCTAssertEqual(digest.count, 64)
        XCTAssertEqual(tab["id"] as? String, "page-1")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.console",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.readConsole")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertNil(deniedBrowserTab["consoleEntryCount"])
        XCTAssertNil(deniedBrowserTab["consoleDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.console",
            "--code", "read_console",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let auditEntries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(auditEntries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.console")
        XCTAssertEqual(entry["action"] as? String, "browser.readConsole")
        XCTAssertEqual(entry["reason"] as? String, "inspect console metadata")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Console Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/console")
        XCTAssertEqual(browserTab["consoleEntryCount"] as? Int, 2)
        XCTAssertEqual(browserTab["consoleDigest"] as? String, digest)
        XCTAssertNil(browserTab["entries"])
        XCTAssertNil(browserTab["text"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_console")
    }

    func testBrowserDialogsReadsEventsWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-dialogs-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpEvents = directory.appendingPathComponent("dialog-events.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        [
          {
            "method": "Page.javascriptDialogOpening",
            "params": {
              "url": "https://example.com/dialog",
              "frameId": "frame-1",
              "message": "dangerous confirmation",
              "type": "confirm",
              "hasBrowserHandler": true,
              "defaultPrompt": "private default"
            }
          },
          {
            "method": "Page.javascriptDialogClosed",
            "params": {
              "result": true,
              "userInput": "do not capture"
            }
          }
        ]
        """.write(to: cdpEvents, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Dialog Page",
            "url": "https://example.com/dialog",
            "webSocketDebuggerUrl": "\(cdpEvents.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "dialogs",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "dialogs",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-entries", "1",
            "--max-message-characters", "9",
            "--sample-ms", "1",
            "--audit-log", auditLog.path,
            "--reason", "inspect dialog metadata"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let digest = try XCTUnwrap(object["digest"] as? String)

        XCTAssertEqual(object["action"] as? String, "browser.readDialogs")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["entryCount"] as? Int, 1)
        XCTAssertEqual(object["returnedCount"] as? Int, 1)
        XCTAssertEqual(object["truncated"] as? Bool, false)
        XCTAssertEqual(object["maxEntries"] as? Int, 1)
        XCTAssertEqual(object["maxMessageCharacters"] as? Int, 9)
        XCTAssertEqual(object["sampleMilliseconds"] as? Int, 1)
        XCTAssertEqual(entry["type"] as? String, "confirm")
        XCTAssertEqual(entry["message"] as? String, "dangerous")
        XCTAssertEqual(entry["messageLength"] as? Int, 22)
        XCTAssertEqual(entry["truncated"] as? Bool, true)
        XCTAssertEqual(entry["url"] as? String, "https://example.com/dialog")
        XCTAssertEqual(entry["frameID"] as? String, "frame-1")
        XCTAssertEqual(entry["hasBrowserHandler"] as? Bool, true)
        XCTAssertEqual(entry["defaultPromptLength"] as? Int, 15)
        XCTAssertNotNil(entry["defaultPromptDigest"])
        XCTAssertNil(entry["defaultPrompt"])
        XCTAssertNil(entry["userInput"])
        XCTAssertEqual(digest.count, 64)
        XCTAssertEqual(tab["id"] as? String, "page-1")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.dialogs",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.readDialogs")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertNil(deniedBrowserTab["dialogEntryCount"])
        XCTAssertNil(deniedBrowserTab["dialogDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.dialogs",
            "--code", "read_dialogs",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let auditEntries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let auditEntry = try XCTUnwrap(auditEntries.first)
        let browserTab = try XCTUnwrap(auditEntry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(auditEntry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(auditEntry["outcome"] as? [String: Any])

        XCTAssertEqual(auditEntry["command"] as? String, "browser.dialogs")
        XCTAssertEqual(auditEntry["action"] as? String, "browser.readDialogs")
        XCTAssertEqual(auditEntry["reason"] as? String, "inspect dialog metadata")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Dialog Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/dialog")
        XCTAssertEqual(browserTab["dialogEntryCount"] as? Int, 1)
        XCTAssertEqual(browserTab["dialogDigest"] as? String, digest)
        XCTAssertNil(browserTab["entries"])
        XCTAssertNil(browserTab["message"])
        XCTAssertNil(browserTab["defaultPrompt"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_dialogs")
    }

    func testBrowserNetworkReadsTimingMetadataWithPolicyAndAuditsSummaryOnly() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-browser-network-\(UUID().uuidString)")
        let jsonDirectory = directory.appendingPathComponent("json")
        let targetList = jsonDirectory.appendingPathComponent("list")
        let cdpResponse = directory.appendingPathComponent("runtime-evaluate.json")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let networkPayload = """
        {
          "url": "https://example.com/app",
          "title": "Network Page",
          "entryCount": 3,
          "returnedCount": 2,
          "truncated": true,
          "entries": [
            {
              "name": "https://example.com/app",
              "entryType": "navigation",
              "initiatorType": "navigation",
              "startTime": 0,
              "duration": 42.5,
              "transferSize": 2048,
              "encodedBodySize": 1024,
              "decodedBodySize": 4096,
              "nextHopProtocol": "h2",
              "responseStatus": 200,
              "urlScheme": "https",
              "urlHost": "example.com"
            },
            {
              "name": "https://cdn.example.com/app.js",
              "entryType": "resource",
              "initiatorType": "script",
              "startTime": 12.25,
              "duration": 7.75,
              "transferSize": 512,
              "encodedBodySize": 400,
              "decodedBodySize": 900,
              "nextHopProtocol": "h3",
              "responseStatus": 200,
              "urlScheme": "https",
              "urlHost": "cdn.example.com"
            }
          ]
        }
        """
        let encodedPayload = try XCTUnwrap(String(data: JSONEncoder().encode(networkPayload), encoding: .utf8))
        try FileManager.default.createDirectory(at: jsonDirectory, withIntermediateDirectories: true)
        try """
        {
          "id": 1,
          "result": {
            "result": {
              "type": "string",
              "value": \(encodedPayload)
            }
          }
        }
        """.write(to: cdpResponse, atomically: true, encoding: .utf8)
        try """
        [
          {
            "id": "page-1",
            "type": "page",
            "title": "Network Page",
            "url": "https://example.com/app",
            "webSocketDebuggerUrl": "\(cdpResponse.absoluteString)"
          }
        ]
        """.write(to: targetList, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let rejected = try runLn1([
            "browser",
            "network",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--audit-log", auditLog.path,
            "--reason", "policy test"
        ])

        XCTAssertNotEqual(rejected.status, 0)

        let result = try runLn1([
            "browser",
            "network",
            "--endpoint", directory.path,
            "--id", "page-1",
            "--allow-risk", "medium",
            "--max-entries", "2",
            "--audit-log", auditLog.path,
            "--reason", "inspect network metadata"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let tab = try XCTUnwrap(object["tab"] as? [String: Any])
        let entries = try XCTUnwrap(object["entries"] as? [[String: Any]])
        let digest = try XCTUnwrap(object["digest"] as? String)

        XCTAssertEqual(object["action"] as? String, "browser.readNetwork")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["url"] as? String, "https://example.com/app")
        XCTAssertEqual(object["entryCount"] as? Int, 3)
        XCTAssertEqual(object["returnedCount"] as? Int, 2)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxEntries"] as? Int, 2)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.last?["entryType"] as? String, "resource")
        XCTAssertEqual(entries.last?["urlHost"] as? String, "cdn.example.com")
        XCTAssertEqual(entries.last?["transferSize"] as? Int, 512)
        XCTAssertEqual(digest.count, 64)
        XCTAssertEqual(tab["id"] as? String, "page-1")

        let deniedAudit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.network",
            "--code", "policy_denied",
            "--limit", "1"
        ])

        XCTAssertEqual(deniedAudit.status, 0, deniedAudit.stderr)
        let deniedAuditObject = try decodeJSONObject(deniedAudit.stdout)
        let deniedEntries = try XCTUnwrap(deniedAuditObject["entries"] as? [[String: Any]])
        let deniedEntry = try XCTUnwrap(deniedEntries.first)
        let deniedBrowserTab = try XCTUnwrap(deniedEntry["browserTab"] as? [String: Any])
        let deniedPolicy = try XCTUnwrap(deniedEntry["policy"] as? [String: Any])

        XCTAssertEqual(deniedEntry["action"] as? String, "browser.readNetwork")
        XCTAssertEqual(deniedEntry["risk"] as? String, "medium")
        XCTAssertEqual(deniedBrowserTab["id"] as? String, "page-1")
        XCTAssertNil(deniedBrowserTab["networkEntryCount"])
        XCTAssertNil(deniedBrowserTab["networkDigest"])
        XCTAssertEqual(deniedPolicy["allowed"] as? Bool, false)

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "browser.network",
            "--code", "read_network",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let auditEntries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(auditEntries.first)
        let browserTab = try XCTUnwrap(entry["browserTab"] as? [String: Any])
        let policy = try XCTUnwrap(entry["policy"] as? [String: Any])
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "browser.network")
        XCTAssertEqual(entry["action"] as? String, "browser.readNetwork")
        XCTAssertEqual(entry["reason"] as? String, "inspect network metadata")
        XCTAssertEqual(browserTab["id"] as? String, "page-1")
        XCTAssertEqual(browserTab["title"] as? String, "Network Page")
        XCTAssertEqual(browserTab["url"] as? String, "https://example.com/app")
        XCTAssertEqual(browserTab["networkEntryCount"] as? Int, 3)
        XCTAssertEqual(browserTab["networkDigest"] as? String, digest)
        XCTAssertNil(browserTab["entries"])
        XCTAssertNil(browserTab["name"])
        XCTAssertEqual(policy["allowed"] as? Bool, true)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "read_network")
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
            "elementCount": 6,
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
                ],
                [
                    "id": "dom.4",
                    "parentID": "dom.3",
                    "depth": 2,
                    "selector": "#shadow-action",
                    "context": "shadow-root",
                    "framePath": "top",
                    "frameURL": NSNull(),
                    "frameAccessible": NSNull(),
                    "shadowPath": "button[aria-controls=\"menu-1\"]",
                    "tagName": "button",
                    "role": "button",
                    "text": "Shadow Action",
                    "textLength": 13,
                    "attributes": ["id": "shadow-action"],
                    "inputType": NSNull(),
                    "checked": NSNull(),
                    "disabled": false,
                    "hasValue": NSNull(),
                    "valueLength": NSNull()
                ],
                [
                    "id": "dom.5",
                    "parentID": "dom.0",
                    "depth": 1,
                    "selector": "iframe[name=\"checkout\"]",
                    "context": "document",
                    "framePath": "top",
                    "frameURL": "https://payments.example/checkout",
                    "frameAccessible": false,
                    "shadowPath": NSNull(),
                    "tagName": "iframe",
                    "role": NSNull(),
                    "text": NSNull(),
                    "textLength": 0,
                    "attributes": [
                        "name": "checkout",
                        "title": "Payment"
                    ],
                    "inputType": NSNull(),
                    "checked": NSNull(),
                    "disabled": NSNull(),
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
            "--max-elements", "6",
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
        let shadowButton = try XCTUnwrap(elements.first { $0["id"] as? String == "dom.4" })
        let iframe = try XCTUnwrap(elements.first { $0["id"] as? String == "dom.5" })
        let linkAttributes = try XCTUnwrap(link["attributes"] as? [String: Any])
        let inputAttributes = try XCTUnwrap(input["attributes"] as? [String: Any])
        let buttonAttributes = try XCTUnwrap(button["attributes"] as? [String: Any])
        let iframeAttributes = try XCTUnwrap(iframe["attributes"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "browser.readDOM")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["url"] as? String, "https://example.com/form")
        XCTAssertEqual(object["title"] as? String, "Example Form")
        XCTAssertEqual(object["elementCount"] as? Int, 6)
        XCTAssertEqual(object["truncated"] as? Bool, true)
        XCTAssertEqual(object["maxElements"] as? Int, 6)
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
        XCTAssertEqual(shadowButton["context"] as? String, "shadow-root")
        XCTAssertEqual(shadowButton["parentID"] as? String, "dom.3")
        XCTAssertEqual(shadowButton["shadowPath"] as? String, "button[aria-controls=\"menu-1\"]")
        XCTAssertEqual(shadowButton["selector"] as? String, "#shadow-action")
        XCTAssertEqual(iframe["context"] as? String, "document")
        XCTAssertEqual(iframe["framePath"] as? String, "top")
        XCTAssertEqual(iframe["frameURL"] as? String, "https://payments.example/checkout")
        XCTAssertEqual(iframe["frameAccessible"] as? Bool, false)
        XCTAssertEqual(iframeAttributes["title"] as? String, "Payment")

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
        XCTAssertEqual(browserTab["domNodeCount"] as? Int, 6)
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

}
