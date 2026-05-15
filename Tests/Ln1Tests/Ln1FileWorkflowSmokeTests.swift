import Foundation
import XCTest

final class Ln1FileWorkflowSmokeTests: Ln1TestCase {
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

    func testWorkflowResumeSuggestsRollbackPreflightAfterSuccessfulMoveAuditReview() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Ln1-workflow-audit-review-resume-\(UUID().uuidString)")
        let workflowLog = directory.appendingPathComponent("workflow-runs.jsonl")
        let auditLog = directory.appendingPathComponent("audit.jsonl")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let transcript: [String: Any] = [
            "transcriptID": "audit-review-transcript",
            "operation": "review-audit",
            "blockers": [],
            "executed": true,
            "wouldExecute": true,
            "execution": [
                "argv": [
                    "Ln1", "audit",
                    "--id", "move-audit-id",
                    "--audit-log", auditLog.path
                ],
                "exitCode": 0,
                "timedOut": false,
                "outputJSON": [
                    "path": auditLog.path,
                    "id": "move-audit-id",
                    "limit": 1,
                    "entries": [
                        [
                            "id": "move-audit-id",
                            "command": "files.move",
                            "outcome": [
                                "ok": true,
                                "code": "moved",
                                "message": "Moved file."
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
            "--operation", "review-audit",
            "--allow-risk", "medium"
        ])

        XCTAssertEqual(resume.status, 0, resume.stderr)
        let object = try decodeJSONObject(resume.stdout)
        XCTAssertEqual(object["status"] as? String, "completed")
        XCTAssertEqual(object["latestOperation"] as? String, "review-audit")
        XCTAssertEqual(object["nextArguments"] as? [String], [
            "Ln1", "workflow", "preflight",
            "--operation", "rollback-file-move",
            "--audit-id", "move-audit-id",
            "--audit-log", auditLog.path
        ])
        XCTAssertTrue((object["message"] as? String)?.contains("rollback preflight") == true)
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

}
