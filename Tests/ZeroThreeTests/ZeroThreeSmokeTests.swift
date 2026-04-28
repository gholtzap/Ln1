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
        XCTAssertEqual(actionByName["filesystem.search"]?["risk"] as? String, "low")
        XCTAssertEqual(actionByName["filesystem.search"]?["mutates"] as? Bool, false)
        XCTAssertEqual(actionByName["filesystem.move"]?["risk"] as? String, "medium")
        XCTAssertEqual(actionByName["filesystem.move"]?["mutates"] as? Bool, true)
        XCTAssertEqual(actionByName["filesystem.createDirectory"]?["domain"] as? String, "filesystem")
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
