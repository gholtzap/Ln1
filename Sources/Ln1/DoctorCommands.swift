import AppKit
import ApplicationServices
import Foundation

extension Ln1CLI {
    func trust() throws {
        let prompt = option("--prompt").map(parseBool) ?? true
        let options = ["AXTrustedCheckOptionPrompt": prompt] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        try writeJSON(TrustRecord(
            trusted: trusted,
            message: trusted
                ? "Accessibility access is enabled."
                : "Grant Accessibility access to the terminal app running Ln1, then retry."
        ))
    }

    func doctor() throws {
        let endpoint = try? browserEndpoint()
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 1_000)
        let checks = [
            doctorAccessibilityCheck(),
            doctorDesktopMetadataCheck(),
            doctorAuditLogCheck(),
            doctorClipboardCheck(),
            doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        ]
        let hasRequiredFailure = checks.contains { $0.required && $0.status == "fail" }
        let hasWarning = checks.contains { $0.status == "warn" || $0.status == "fail" }
        let status: String
        if hasRequiredFailure {
            status = "blocked"
        } else if hasWarning {
            status = "degraded"
        } else {
            status = "ready"
        }

        try writeJSON(DoctorReport(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            status: status,
            ready: status == "ready",
            checks: checks
        ))
    }

    func doctorAccessibilityCheck() -> DoctorCheck {
        let trusted = AXIsProcessTrusted()
        return DoctorCheck(
            name: "accessibility",
            status: trusted ? "pass" : "fail",
            required: true,
            message: trusted
                ? "Accessibility permission is enabled."
                : "Accessibility permission is not enabled, so Ln1 state and Ln1 perform cannot inspect or operate app UI.",
            remediation: trusted ? nil : "Run `Ln1 trust`, grant Accessibility access to the terminal app, then rerun `Ln1 doctor`."
        )
    }

    func doctorDesktopMetadataCheck() -> DoctorCheck {
        do {
            let desktop = try desktopWindows(limitOverride: 1)
            if !desktop.available {
                return DoctorCheck(
                    name: "desktop.windowMetadata",
                    status: "fail",
                    required: true,
                    message: desktop.message,
                    remediation: "Run `Ln1 desktop windows --limit 5` from an interactive macOS user session."
                )
            }
            if desktop.windows.isEmpty {
                return DoctorCheck(
                    name: "desktop.windowMetadata",
                    status: "warn",
                    required: true,
                    message: "WindowServer metadata is available, but no visible windows matched the current filters.",
                    remediation: "Try `Ln1 desktop windows --include-desktop --all-layers --limit 20`."
                )
            }
            return DoctorCheck(
                name: "desktop.windowMetadata",
                status: "pass",
                required: true,
                message: "WindowServer metadata is available.",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "desktop.windowMetadata",
                status: "fail",
                required: true,
                message: "Could not inspect desktop window metadata: \(error.localizedDescription)",
                remediation: "Run `Ln1 desktop windows --limit 5` to inspect the desktop adapter error."
            )
        }
    }

    func doctorAuditLogCheck() -> DoctorCheck {
        do {
            let auditURL = try auditLogURL()
            let directory = auditURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let probeURL = directory.appendingPathComponent(".Ln1-doctor-\(UUID().uuidString).tmp")
            try "doctor".write(to: probeURL, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(at: probeURL)
            return DoctorCheck(
                name: "auditLog.writeability",
                status: "pass",
                required: true,
                message: "Audit log directory is writable at \(directory.path).",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "auditLog.writeability",
                status: "fail",
                required: true,
                message: "Could not write an audit log probe: \(error.localizedDescription)",
                remediation: "Pass `--audit-log` with a writable path or fix permissions on the default Application Support directory."
            )
        }
    }

    func doctorClipboardCheck() -> DoctorCheck {
        let pasteboard = targetPasteboard()
        let state = clipboardState(for: pasteboard)
        return DoctorCheck(
            name: "clipboard.metadata",
            status: "pass",
            required: true,
            message: "Clipboard metadata is readable from \(state.pasteboard).",
            remediation: nil
        )
    }

    func doctorBrowserDevToolsCheck(endpoint: URL?, timeoutMilliseconds: Int) -> DoctorCheck {
        guard let endpoint else {
            return DoctorCheck(
                name: "browser.devTools",
                status: "warn",
                required: false,
                message: "Browser DevTools endpoint configuration is invalid.",
                remediation: "Use `Ln1 doctor --endpoint http://127.0.0.1:9222` or pass a file path containing a DevTools /json/list fixture."
            )
        }

        do {
            let listURL = browserListURL(for: endpoint)
            let data = try readURLData(from: listURL, timeoutMilliseconds: timeoutMilliseconds)
            let targets = try JSONDecoder().decode([DevToolsTarget].self, from: data)
            let pageCount = targets.filter { ($0.type ?? "page") == "page" }.count
            return DoctorCheck(
                name: "browser.devTools",
                status: "pass",
                required: false,
                message: "Browser DevTools endpoint is reachable with \(pageCount) page target(s).",
                remediation: nil
            )
        } catch {
            return DoctorCheck(
                name: "browser.devTools",
                status: "warn",
                required: false,
                message: "Browser DevTools endpoint is not reachable or did not return valid target JSON: \(error.localizedDescription)",
                remediation: "Start Chromium with `--remote-debugging-port=9222`, then rerun `Ln1 doctor --endpoint http://127.0.0.1:9222`."
            )
        }
    }

}
