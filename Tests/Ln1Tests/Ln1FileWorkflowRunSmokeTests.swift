import Foundation
import XCTest

final class Ln1FileWorkflowRunSmokeTests: Ln1TestCase {
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
