import Foundation
import XCTest

final class Ln1VisualSmokeTests: Ln1TestCase {
    func testDesktopScreenshotReturnsBoundedVisualSnapshotMetadata() throws {
        let result = try runLn1([
            "desktop",
            "screenshot",
            "--allow-risk", "medium",
            "--max-sample-bytes", "4096",
            "--include-ocr", "true",
            "--max-ocr-characters", "256"
        ])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let displays = try XCTUnwrap(object["displays"] as? [[String: Any]])

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["action"] as? String, "desktop.screenshot")
        XCTAssertEqual(object["risk"] as? String, "medium")
        XCTAssertEqual(object["maxSampleBytes"] as? Int, 4096)
        XCTAssertEqual(object["includeOCR"] as? Bool, true)
        XCTAssertEqual(object["maxOCRCharacters"] as? Int, 256)
        XCTAssertEqual(object["displayCount"] as? Int, displays.count)
        let message = try XCTUnwrap(object["message"] as? String)
        if displays.isEmpty {
            XCTAssertTrue(message.contains("No online displays"), message)
        }

        if let first = displays.first {
            XCTAssertNotNil(first["id"] as? String)
            XCTAssertNotNil(first["displayID"] as? Int)
            XCTAssertNotNil(first["pixelWidth"] as? Int)
            XCTAssertNotNil(first["pixelHeight"] as? Int)
            XCTAssertNotNil(first["captured"] as? Bool)
            XCTAssertNotNil(first["sampleByteCount"] as? Int)
            let ocr = try XCTUnwrap(first["ocr"] as? [String: Any])
            XCTAssertEqual(ocr["requested"] as? Bool, true)
            XCTAssertNotNil(ocr["available"] as? Bool)
            XCTAssertNotNil(ocr["observationCount"] as? Int)
            XCTAssertNotNil(ocr["textLength"] as? Int)
            XCTAssertNotNil(ocr["truncated"] as? Bool)
            XCTAssertNotNil(ocr["message"] as? String)

            if first["captured"] as? Bool == true {
                XCTAssertNotNil(first["imageWidth"] as? Int)
                XCTAssertNotNil(first["imageHeight"] as? Int)
                XCTAssertNotNil(first["sampleDigest"] as? String)
                XCTAssertLessThanOrEqual(try XCTUnwrap(first["sampleByteCount"] as? Int), 4096)
                if let text = ocr["text"] as? String {
                    XCTAssertLessThanOrEqual(text.count, 256)
                }
            }
        }
    }
}
