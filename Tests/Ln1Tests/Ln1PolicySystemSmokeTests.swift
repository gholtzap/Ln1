import Foundation
import XCTest

final class Ln1PolicySystemSmokeTests: Ln1TestCase {
    func testSystemContextReturnsBoundedHostRuntimeMetadata() throws {
        let result = try runLn1(["system", "context"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertNotNil(object["hostName"] as? String)
        XCTAssertNotNil(object["userName"] as? String)
        XCTAssertNotNil(object["homeDirectory"] as? String)
        XCTAssertEqual(object["currentDirectory"] as? String, packageRoot.path)
        XCTAssertNotNil(object["processIdentifier"] as? Int)
        XCTAssertNotNil(object["operatingSystemVersion"] as? String)
        XCTAssertNotNil(object["operatingSystemVersionString"] as? String)
        XCTAssertNotNil(object["architecture"] as? String)
        XCTAssertNotNil(object["processorCount"] as? Int)
        XCTAssertNotNil(object["activeProcessorCount"] as? Int)
        XCTAssertNotNil(object["physicalMemoryBytes"] as? Int)
        XCTAssertNotNil(object["systemUptimeSeconds"] as? Double)
        XCTAssertNotNil(object["timeZoneIdentifier"] as? String)
        XCTAssertNotNil(object["localeIdentifier"] as? String)
        XCTAssertNil(object["environment"])
    }

    func testBenchmarksMatrixReturnsRealAppCoverageTargets() throws {
        let result = try runLn1(["benchmarks", "matrix"])

        XCTAssertEqual(result.status, 0, result.stderr)
        let object = try decodeJSONObject(result.stdout)
        let scenarios = try XCTUnwrap(object["scenarios"] as? [[String: Any]])
        let apps = Set(scenarios.compactMap { $0["app"] as? String })
        let allSurfaces = scenarios
            .compactMap { $0["surfaces"] as? [String] }
            .flatMap { $0 }
        let allCapabilities = scenarios
            .compactMap { $0["requiredCapabilities"] as? [String] }
            .flatMap { $0 }
        let allVerificationCommands = scenarios
            .compactMap { $0["verificationCommands"] as? [String] }
            .flatMap { $0 }

        XCTAssertEqual(object["platform"] as? String, "macOS")
        XCTAssertEqual(object["status"] as? String, "planned")
        XCTAssertEqual(object["scenarioCount"] as? Int, scenarios.count)
        XCTAssertTrue(scenarios.allSatisfy { scenario in
            guard let commands = scenario["verificationCommands"] as? [String] else {
                return false
            }
            return !commands.isEmpty && commands.allSatisfy { $0.hasPrefix("Ln1 ") }
        })
        XCTAssertTrue(apps.contains("Finder"))
        XCTAssertTrue(apps.contains("Browser"))
        XCTAssertTrue(apps.contains("Electron apps"))
        XCTAssertTrue(apps.contains("Microsoft Office"))
        XCTAssertTrue(apps.contains("Xcode"))
        XCTAssertTrue(apps.contains("Terminal"))
        XCTAssertTrue(apps.contains("System Settings"))
        XCTAssertTrue(apps.contains("Cross-app modal and sheet flows"))
        XCTAssertTrue(allSurfaces.contains("permission dialogs"))
        XCTAssertTrue(allSurfaces.contains("file pickers"))
        XCTAssertTrue(allSurfaces.contains("sheets"))
        XCTAssertTrue(allSurfaces.contains("modals"))
        XCTAssertTrue(allCapabilities.contains("visual fallback"))
        XCTAssertTrue(allCapabilities.contains("keyboard input"))
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("browser console") })
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("browser network") })
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("desktop screenshot") })
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("processes wait") })
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("state wait-element") })
        XCTAssertTrue(allVerificationCommands.contains { $0.contains("files checksum") })
    }
}
