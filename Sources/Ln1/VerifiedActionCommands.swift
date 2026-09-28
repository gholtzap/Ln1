import AppKit
import ApplicationServices
import Darwin
import Foundation

struct VerifiedActionResult: Codable {
    let ok: Bool
    let app: AppRecord?
    let target: ElementNode?
    let action: String
    let expectedWindowTitle: String?
    let expectedValue: String?
    let expectedTargetValue: String?
    let previousWindowTitle: String?
    let observedWindowTitle: String?
    let observedValue: String?
    let observedTargetValue: String?
    let actionError: String?
    let identityVerification: IdentityVerification?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
}

extension Ln1CLI {
    func verifiedAction() throws {
        guard let name = ["--title", "--description", "--identifier", "--value", "--help-text"]
            .compactMap({ option($0) }).first(where: { !$0.isEmpty }) else {
            throw CommandError(description: "provide --title, --description, --identifier, --value, or --help-text to find a control")
        }
        let expectedTitle = option("--expect-window-title")
        let expectedValue = option("--expect-value")
        let expectedTargetValue = option("--expect-target-value")
        guard expectedTitle != nil || expectedValue != nil || expectedTargetValue != nil else {
            throw CommandError(description: "provide --expect-window-title, --expect-value, or --expect-target-value to verify the result")
        }
        let action = option("--action") ?? kAXPressAction as String
        let match = option("--expect-match") ?? "exact"
        guard ["exact", "contains"].contains(match) else {
            throw CommandError(description: "--expect-match must be exact or contains")
        }
        let timeout = max(0, min(30_000, option("--timeout-ms").flatMap(Int.init) ?? 3_000))
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = riskLevel(for: action)
        let policy = policyDecision(actionRisk: risk)
        var appRecord: AppRecord?
        var target: ElementNode?
        var summary: AuditElementSummary?
        var previousTitle: String?
        var observedTitle: String?
        var observedValue: String?
        var observedTargetValue: String?
        var actionError: String?
        var identityVerification: IdentityVerification?

        func finish(_ ok: Bool, _ code: String, _ message: String) throws {
            let verification = FileOperationVerification(ok: ok, code: code, message: message)
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "act",
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: target?.id,
                element: summary,
                action: action,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            try writeJSON(VerifiedActionResult(
                ok: ok,
                app: appRecord,
                target: target,
                action: action,
                expectedWindowTitle: expectedTitle,
                expectedValue: expectedValue,
                expectedTargetValue: expectedTargetValue,
                previousWindowTitle: previousTitle,
                observedWindowTitle: observedTitle,
                observedValue: observedValue,
                observedTargetValue: observedTargetValue,
                actionError: actionError,
                identityVerification: identityVerification,
                verification: verification,
                auditID: auditID,
                auditLogPath: auditURL.path
            ))
            if !ok { exit(1) }
        }

        guard policy.allowed else {
            try finish(false, "policy_denied", policy.message)
            return
        }
        try requireTrusted()
        let app = try targetApp()
        appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )

        let menuPrefix: String?
        if let menuName = option("--menu") {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            let menuBar = accessibilityElement(axApp, kAXMenuBarAttribute)
            let menuIndices = menuBar.map { accessibilityArray($0, kAXChildrenAttribute) } ?? []
            let matchingIndices = menuIndices.enumerated().filter {
                stringValue(stringAttribute($0.element, kAXTitleAttribute), matches: menuName, mode: "exact")
            }
            guard matchingIndices.count == 1, let index = matchingIndices.first?.offset else {
                try finish(false, "menu_ambiguous", "Expected one menu named \(menuName); found \(matchingIndices.count).")
                return
            }
            _ = AXUIElementPerformAction(menuIndices[index], kAXPickAction as CFString)
            menuPrefix = "m0.\(index)."
        } else {
            menuPrefix = nil
        }
        let found = try stateElementFindState(
            depthDefault: 8,
            maxChildrenDefault: 120,
            limitDefault: 100,
            matchDefault: "exact",
            includeMenuDefault: option("--menu") != nil,
            menuOnly: option("--menu") != nil
        )

        var candidates = found.matches.filter { node in
            node.actions.contains(action) && (menuPrefix == nil || node.id.hasPrefix(menuPrefix!))
        }
        if menuPrefix != nil {
            if let minimumDepth = candidates.map({ $0.id.split(separator: ".").count }).min() {
                candidates = candidates.filter { $0.id.split(separator: ".").count == minimumDepth }
            }
        }
        guard !found.truncated, candidates.count == 1, let candidate = candidates.first else {
            let code = found.truncated ? "search_truncated" : "target_ambiguous"
            try finish(false, code, "Expected one actionable element matching \(name); found \(candidates.count). Narrow the search with --menu or --role.")
            return
        }
        target = candidate
        let resolved = try resolveGuardedElement(id: candidate.id, in: app)
        summary = resolved.summary
        identityVerification = IdentityVerification(
            ok: resolved.summary.stableIdentity?.id == candidate.stableIdentity.id,
            code: resolved.summary.stableIdentity?.id == candidate.stableIdentity.id ? "identity_verified" : "identity_mismatch",
            message: "Checked the selected element before acting.",
            expectedID: candidate.stableIdentity.id,
            actualID: resolved.summary.stableIdentity?.id ?? "unavailable",
            minimumConfidence: nil,
            actualConfidence: resolved.summary.stableIdentity?.confidence ?? "low",
            identityMatched: resolved.summary.stableIdentity?.id == candidate.stableIdentity.id,
            confidenceAccepted: nil
        )
        guard resolved.summary.stableIdentity?.id == candidate.stableIdentity.id,
              resolved.summary.role == candidate.role,
              resolved.summary.title == candidate.title,
              resolved.summary.description == candidate.description,
              resolved.summary.identifier == candidate.identifier,
              resolved.summary.actions.contains(action),
              resolved.summary.enabled != false else {
            try finish(false, "target_changed", "The selected element changed or became unavailable before the action.")
            return
        }

        previousTitle = focusedWindowTitle(for: app)
        let valueMatchedBefore = expectedValue.flatMap { matchingFocusedValue(for: app, expected: $0, mode: match) } != nil
        let targetMatchedBefore = expectedTargetValue.map {
            stringValue(stringLikeAttribute(resolved.element, kAXValueAttribute), matches: $0, mode: match)
        } ?? true
        let titleMatchedBefore = expectedTitle.map { stringValue(previousTitle, matches: $0, mode: match) } ?? true
        let actionStatus = AXUIElementPerformAction(resolved.element, action as CFString)
        if actionStatus != .success {
            actionError = "AXUIElementPerformAction returned \(actionStatus)."
        }

        let deadline = Date().addingTimeInterval(Double(timeout) / 1_000)
        repeat {
            observedTitle = focusedWindowTitle(for: app)
            observedValue = expectedValue.flatMap { matchingFocusedValue(for: app, expected: $0, mode: match) }
            observedTargetValue = expectedTargetValue.flatMap { _ in stringLikeAttribute(resolved.element, kAXValueAttribute) }
            let titleMatched = expectedTitle.map { stringValue(observedTitle, matches: $0, mode: match) } ?? true
            let valueMatched = expectedValue == nil || observedValue != nil
            let targetMatched = expectedTargetValue.map { stringValue(observedTargetValue, matches: $0, mode: match) } ?? true
            let alreadyMatched = titleMatchedBefore && (expectedValue == nil || valueMatchedBefore) && targetMatchedBefore
            if titleMatched && valueMatched && targetMatched && (actionError == nil || !alreadyMatched) {
                let code = actionError == nil ? "verified" : "verified_despite_action_error"
                try finish(true, code, "The app matched the expected result.")
                return
            }
            if Date() >= deadline { break }
            Thread.sleep(forTimeInterval: min(0.1, max(0, deadline.timeIntervalSinceNow)))
        } while true

        try finish(false, "verification_failed", "The app did not match the expected result.")
    }

    private func focusedWindowTitle(for app: NSRunningApplication) -> String? {
        focusedWindow(for: app).flatMap { stringAttribute($0, kAXTitleAttribute) }
    }

    private func focusedWindow(for app: NSRunningApplication) -> AXUIElement? {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        return accessibilityElement(axApp, kAXFocusedWindowAttribute)
            ?? accessibilityElement(axApp, kAXMainWindowAttribute)
    }

    private func matchingFocusedValue(for app: NSRunningApplication, expected: String, mode: String) -> String? {
        guard let window = focusedWindow(for: app) else { return nil }
        func find(_ element: AXUIElement, depth: Int) -> String? {
            if let value = stringLikeAttribute(element, kAXValueAttribute),
               stringValue(cleanDisplayValue(value), matches: cleanDisplayValue(expected), mode: mode) {
                return value
            }
            guard depth > 0 else { return nil }
            for child in accessibilityArray(element, kAXChildrenAttribute).prefix(120) {
                if let match = find(child, depth: depth - 1) { return match }
            }
            return nil
        }
        return find(window, depth: 8)
    }

    private func cleanDisplayValue(_ value: String) -> String {
        String(value.unicodeScalars.filter { ![0x200E, 0x200F, 0x2066, 0x2067, 0x2068, 0x2069].contains($0.value) })
    }
}
