import Foundation
import XCTest

class Ln1TestCase: XCTestCase {
    func runLn1(_ arguments: [String]) throws -> ProcessResult {
        let executable = packageRoot.appendingPathComponent(".build/debug/Ln1")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: executable.path), "Run swift build before swift test.")
        return try runProcess(executable.path, arguments: arguments)
    }

    func runProcess(_ executable: String, arguments: [String]) throws -> ProcessResult {
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

    func decodeJSONObject(_ string: String) throws -> [String: Any] {
        let data = try XCTUnwrap(string.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(object as? [String: Any])
    }

    func decodeJSON(_ string: String) throws -> Any {
        let data = try XCTUnwrap(string.data(using: .utf8))
        return try JSONSerialization.jsonObject(with: data)
    }

    func writeJSONObjectLine(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        let line = String(decoding: data, as: UTF8.self) + "\n"
        try line.write(to: url, atomically: true, encoding: .utf8)
    }

    var packageRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

struct ProcessResult {
    let status: Int32
    let stdout: String
    let stderr: String
}
