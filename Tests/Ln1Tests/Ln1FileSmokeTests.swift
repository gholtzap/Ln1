import Foundation
import XCTest

final class Ln1FileSmokeTests: Ln1TestCase {
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

    func testFilesRollbackTextRestoresAuditedOverwriteFromSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-file-text-rollback-write-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let snapshot = directory.appendingPathComponent("rollback.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "old text".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let write = try runLn1([
            "files",
            "write-text",
            "--path", file.path,
            "--text", "new text",
            "--overwrite",
            "--allow-risk", "medium",
            "--rollback-snapshot", snapshot.path,
            "--audit-log", auditLog.path,
            "--reason", "write before rollback"
        ])

        XCTAssertEqual(write.status, 0, write.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "new text")
        XCTAssertTrue(FileManager.default.fileExists(atPath: snapshot.path))
        let writeObject = try decodeJSONObject(write.stdout)
        let writeAuditID = try XCTUnwrap(writeObject["auditID"] as? String)
        XCTAssertEqual(writeObject["rollbackSnapshotPath"] as? String, snapshot.path)

        let rollback = try runLn1([
            "files",
            "rollback-text",
            "--audit-id", writeAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "undo write"
        ])

        XCTAssertEqual(rollback.status, 0, rollback.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "old text")
        let object = try decodeJSONObject(rollback.stdout)
        let previous = try XCTUnwrap(object["previous"] as? [String: Any])
        let current = try XCTUnwrap(object["current"] as? [String: Any])
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["ok"] as? Bool, true)
        XCTAssertEqual(object["action"] as? String, "filesystem.rollbackTextWrite")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["rollbackOfAuditID"] as? String, writeAuditID)
        XCTAssertEqual(object["path"] as? String, file.path)
        XCTAssertEqual(previous["path"] as? String, file.path)
        XCTAssertEqual(previous["sizeBytes"] as? Int, 8)
        XCTAssertEqual(current["path"] as? String, file.path)
        XCTAssertEqual(current["kind"] as? String, "regularFile")
        XCTAssertEqual(current["sizeBytes"] as? Int, 8)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_restored")

        let audit = try runLn1([
            "audit",
            "--audit-log", auditLog.path,
            "--command", "files.rollback-text",
            "--code", "rolled_back_text_write",
            "--limit", "1"
        ])

        XCTAssertEqual(audit.status, 0, audit.stderr)
        let auditObject = try decodeJSONObject(audit.stdout)
        let entries = try XCTUnwrap(auditObject["entries"] as? [[String: Any]])
        let entry = try XCTUnwrap(entries.first)
        let outcome = try XCTUnwrap(entry["outcome"] as? [String: Any])

        XCTAssertEqual(entry["command"] as? String, "files.rollback-text")
        XCTAssertEqual(entry["action"] as? String, "filesystem.rollbackTextWrite")
        XCTAssertEqual(entry["fileRollbackSnapshotPath"] as? String, snapshot.path)
        XCTAssertEqual(entry["rollbackOfAuditID"] as? String, writeAuditID)
        XCTAssertEqual(outcome["ok"] as? Bool, true)
        XCTAssertEqual(outcome["code"] as? String, "rolled_back_text_write")
        XCTAssertNil(entry["text"])
        XCTAssertNil(entry["value"])
    }

    func testFilesRollbackTextRestoresAuditedAppendFromSnapshot() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-file-text-rollback-append-\(UUID().uuidString)")
        let file = directory.appendingPathComponent("note.txt")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        let snapshot = directory.appendingPathComponent("rollback.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "first".write(to: file, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: directory) }

        let append = try runLn1([
            "files",
            "append-text",
            "--path", file.path,
            "--text", "\nsecond",
            "--allow-risk", "medium",
            "--rollback-snapshot", snapshot.path,
            "--audit-log", auditLog.path,
            "--reason", "append before rollback"
        ])

        XCTAssertEqual(append.status, 0, append.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "first\nsecond")
        let appendObject = try decodeJSONObject(append.stdout)
        let appendAuditID = try XCTUnwrap(appendObject["auditID"] as? String)
        XCTAssertEqual(appendObject["rollbackSnapshotPath"] as? String, snapshot.path)

        let rollback = try runLn1([
            "files",
            "rollback-text",
            "--audit-id", appendAuditID,
            "--allow-risk", "medium",
            "--audit-log", auditLog.path,
            "--reason", "undo append"
        ])

        XCTAssertEqual(rollback.status, 0, rollback.stderr)
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "first")
        let object = try decodeJSONObject(rollback.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])

        XCTAssertEqual(object["action"] as? String, "filesystem.rollbackTextWrite")
        XCTAssertEqual(object["rollbackOfAuditID"] as? String, appendAuditID)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["code"] as? String, "text_restored")
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

}
