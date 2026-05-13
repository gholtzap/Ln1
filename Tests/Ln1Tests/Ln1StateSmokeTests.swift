import AppKit
import ApplicationServices
import Foundation
import XCTest

final class Ln1StateSmokeTests: Ln1TestCase {
    func testStateWaitElementRequiresElementBeforeAccessibilityTrust() throws {
        let result = try runLn1([
            "state",
            "wait-element",
            "--exists", "false",
            "--timeout-ms", "0"
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.stderr.contains("missing required option --element"), result.stderr)
    }

    func testStateElementRequiresElementBeforeAccessibilityTrust() throws {
        let result = try runLn1([
            "state",
            "element",
            "--depth", "0"
        ])

        XCTAssertNotEqual(result.status, 0)
        XCTAssertTrue(result.stderr.contains("missing required option --element"), result.stderr)
    }

    func testStateMenuReturnsBoundedStructuredMenuBar() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let result = try runLn1([
            "state",
            "menu",
            "--depth", "1",
            "--max-children", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let app = try XCTUnwrap(object["app"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(app["pid"] as? Int)
        XCTAssertEqual(object["depth"] as? Int, 1)
        XCTAssertEqual(object["maxChildren"] as? Int, 5)
        XCTAssertTrue((object["message"] as? String)?.contains("menu bar") == true)
        if let menuBar = object["menuBar"] as? [String: Any] {
            let stableIdentity = try XCTUnwrap(menuBar["stableIdentity"] as? [String: Any])
            let children = try XCTUnwrap(menuBar["children"] as? [[String: Any]])
            XCTAssertEqual(menuBar["id"] as? String, "m0")
            XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
            XCTAssertNotNil(menuBar["settableAttributes"] as? [String])
            XCTAssertNotNil(menuBar["valueSettable"] as? Bool)
            XCTAssertLessThanOrEqual(children.count, 5)
        } else {
            XCTAssertTrue((object["message"] as? String)?.contains("No Accessibility menu bar") == true)
        }
    }

    func testStateElementCanInspectMenuBarPathWhenAvailable() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let menuResult = try runLn1([
            "state",
            "menu",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(menuResult.status, 0, menuResult.stderr)
        let menuState = try decodeJSONObject(menuResult.stdout)
        let app = try XCTUnwrap(menuState["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        guard menuState["menuBar"] is [String: Any] else {
            throw XCTSkip("No Accessibility menu bar was available for the frontmost app.")
        }

        let result = try runLn1([
            "state",
            "element",
            "--pid", "\(pid)",
            "--element", "m0",
            "--min-identity-confidence", "low",
            "--depth", "0",
            "--max-children", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let element = try XCTUnwrap(object["element"] as? [String: Any])
        let identityVerification = try XCTUnwrap(object["identityVerification"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(element["id"] as? String, "m0")
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["minimumConfidence"] as? String, "low")
        XCTAssertEqual(identityVerification["confidenceAccepted"] as? Bool, true)
        XCTAssertNotNil(element["settableAttributes"] as? [String])
        XCTAssertNotNil(element["valueSettable"] as? Bool)
    }

    func testStateFindReturnsBoundedElementCandidates() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let result = try runLn1([
            "state",
            "find",
            "--role", "AXWindow",
            "--match", "exact",
            "--depth", "0",
            "--max-children", "10",
            "--limit", "5"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let query = try XCTUnwrap(object["query"] as? [String: Any])
        let matches = try XCTUnwrap(object["matches"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["depth"] as? Int, 0)
        XCTAssertEqual(object["maxChildren"] as? Int, 10)
        XCTAssertEqual(object["limit"] as? Int, 5)
        XCTAssertEqual(object["count"] as? Int, matches.count)
        XCTAssertLessThanOrEqual(matches.count, 5)
        XCTAssertEqual(query["role"] as? String, "AXWindow")
        XCTAssertEqual(query["match"] as? String, "exact")
        XCTAssertEqual(query["includeMenu"] as? Bool, false)

        if let first = matches.first {
            let stableIdentity = try XCTUnwrap(first["stableIdentity"] as? [String: Any])
            XCTAssertNotNil(first["id"] as? String)
            XCTAssertEqual(first["role"] as? String, "AXWindow")
            XCTAssertNotNil(first["minimized"] as? Bool)
            XCTAssertEqual(stableIdentity["kind"] as? String, "accessibilityElement")
        }
    }

    func testStateElementReturnsBoundedStructuredElement() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for the frontmost app.")
        }

        let result = try runLn1([
            "state",
            "element",
            "--pid", "\(pid)",
            "--element", elementID,
            "--min-identity-confidence", "low",
            "--depth", "0",
            "--max-children", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let element = try XCTUnwrap(object["element"] as? [String: Any])
        let identityVerification = try XCTUnwrap(object["identityVerification"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["depth"] as? Int, 0)
        XCTAssertEqual(object["maxChildren"] as? Int, 0)
        XCTAssertEqual(element["id"] as? String, elementID)
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["minimumConfidence"] as? String, "low")
        XCTAssertEqual(identityVerification["confidenceAccepted"] as? Bool, true)
        XCTAssertNotNil(identityVerification["actualID"] as? String)
        XCTAssertNotNil(element["settableAttributes"] as? [String])
        XCTAssertNotNil(element["valueSettable"] as? Bool)
        XCTAssertNotNil(element["minimized"] as? Bool)
    }

    func testStateElementReResolvesStalePathByStableIdentity() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "3",
            "--max-children", "60"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let app = try XCTUnwrap(state["app"] as? [String: Any])
        let pid = try XCTUnwrap(app["pid"] as? Int)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        var candidatesByIdentity: [String: [[String: Any]]] = [:]

        func collect(_ element: [String: Any]) {
            if let stableIdentity = element["stableIdentity"] as? [String: Any],
               let identityID = stableIdentity["id"] as? String {
                candidatesByIdentity[identityID, default: []].append(element)
            }
            for child in element["children"] as? [[String: Any]] ?? [] {
                collect(child)
            }
        }

        for window in windows {
            collect(window)
        }

        guard let unique = candidatesByIdentity.values
            .compactMap({ $0.count == 1 ? $0[0] : nil })
            .first(where: { ($0["id"] as? String)?.first == "w" }),
              let elementID = unique["id"] as? String,
              let stableIdentity = unique["stableIdentity"] as? [String: Any],
              let identityID = stableIdentity["id"] as? String else {
            throw XCTSkip("No uniquely identifiable Accessibility element was available for the frontmost app.")
        }

        let result = try runLn1([
            "state",
            "element",
            "--pid", "\(pid)",
            "--element", "w999",
            "--expect-identity", identityID,
            "--min-identity-confidence", "low",
            "--depth", "0",
            "--max-children", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let element = try XCTUnwrap(object["element"] as? [String: Any])
        let identityVerification = try XCTUnwrap(object["identityVerification"] as? [String: Any])

        XCTAssertEqual(element["id"] as? String, elementID)
        XCTAssertEqual(identityVerification["ok"] as? Bool, true)
        XCTAssertEqual(identityVerification["expectedID"] as? String, identityID)
        XCTAssertEqual(identityVerification["actualID"] as? String, identityID)
    }

    func testStateWaitElementReturnsStructuredVerificationForCurrentWindow() throws {
        guard AXIsProcessTrusted() else {
            throw XCTSkip("Accessibility trust is not enabled.")
        }

        let stateResult = try runLn1([
            "state",
            "--depth", "0",
            "--max-children", "0"
        ])
        XCTAssertEqual(stateResult.status, 0, stateResult.stderr)
        let state = try decodeJSONObject(stateResult.stdout)
        let windows = try XCTUnwrap(state["windows"] as? [[String: Any]])
        guard let firstWindow = windows.first,
              let elementID = firstWindow["id"] as? String else {
            throw XCTSkip("No Accessibility window was available for the frontmost app.")
        }

        let result = try runLn1([
            "state",
            "wait-element",
            "--element", elementID,
            "--exists", "true",
            "--timeout-ms", "0",
            "--depth", "0",
            "--max-children", "0"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let verification = try XCTUnwrap(object["verification"] as? [String: Any])
        let target = try XCTUnwrap(verification["target"] as? [String: Any])
        let current = try XCTUnwrap(verification["current"] as? [String: Any])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["timeoutMilliseconds"] as? Int, 0)
        XCTAssertEqual(object["depth"] as? Int, 0)
        XCTAssertEqual(object["maxChildren"] as? Int, 0)
        XCTAssertEqual(target["element"] as? String, elementID)
        XCTAssertEqual(verification["expectedExists"] as? Bool, true)
        XCTAssertEqual(verification["ok"] as? Bool, true)
        XCTAssertEqual(verification["matched"] as? Bool, true)
        XCTAssertEqual(current["id"] as? String, elementID)
    }

}
