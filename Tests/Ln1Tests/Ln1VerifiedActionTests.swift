import AppKit
import ApplicationServices
import XCTest

final class Ln1VerifiedActionTests: Ln1TestCase {
    func testDeniedActionReturnsStructuredFailureAndAudit() throws {
        let auditURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: auditURL) }
        let result = try runLn1([
            "act", "--title", "Applications", "--expect-window-title", "Applications",
            "--allow-risk", "invalid", "--audit-log", auditURL.path
        ])
        XCTAssertNotEqual(result.status, 0)
        let output = try decodeJSONObject(result.stdout)
        XCTAssertEqual(output["ok"] as? Bool, false)
        let verification = try XCTUnwrap(output["verification"] as? [String: Any])
        XCTAssertEqual(verification["code"] as? String, "policy_denied")
        let audit = try String(contentsOf: auditURL, encoding: .utf8)
        XCTAssertTrue(audit.contains("policy_denied"))
    }

    func testCalculatorControlCanBeFoundByDescription() throws {
        guard AXIsProcessTrusted(),
              !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.calculator").isEmpty else {
            throw XCTSkip("Calculator is not running with Accessibility access.")
        }
        let result = try runLn1([
            "state", "find", "--bundle-id", "com.apple.calculator",
            "--description", "7", "--role", "AXButton", "--match", "exact",
            "--depth", "8", "--max-children", "120"
        ])
        XCTAssertEqual(result.status, 0, result.stderr)
        let output = try decodeJSONObject(result.stdout)
        let matches = try XCTUnwrap(output["matches"] as? [[String: Any]])
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0]["identifier"] as? String, "Seven")
        XCTAssertTrue((matches[0]["actions"] as? [String])?.contains("AXPress") == true)
    }

    func testNotesToolbarSearchDoesNotScanNoteList() throws {
        guard AXIsProcessTrusted(),
              !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Notes").isEmpty else {
            throw XCTSkip("Notes is not running with Accessibility access.")
        }
        let result = try runLn1([
            "state", "find", "--bundle-id", "com.apple.Notes",
            "--description", "Gallery View", "--role", "AXRadioButton",
            "--within-role", "AXToolbar", "--depth", "5"
        ])
        XCTAssertEqual(result.status, 0, result.stderr)
        let output = try decodeJSONObject(result.stdout)
        XCTAssertEqual(output["truncated"] as? Bool, false)
        let matches = try XCTUnwrap(output["matches"] as? [[String: Any]])
        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches[0]["description"] as? String, "Gallery View")
    }
}
