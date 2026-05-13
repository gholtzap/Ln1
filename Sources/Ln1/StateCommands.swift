import AppKit
import Foundation

extension Ln1CLI {
    private func stateElementWaitState() throws -> AccessibilityElementWaitResult {
        let target = try accessibilityElementWaitTarget()
        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 0)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )
        let verification = try waitForAccessibilityElement(
            target: target,
            expectedExists: expectedExists,
            app: app,
            depth: depth,
            maxChildren: maxChildren,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return AccessibilityElementWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            depth: depth,
            maxChildren: maxChildren,
            verification: verification,
            message: verification.ok
                ? "Accessibility element matched the expected structured state."
                : verification.message
        )
    }

    private func stateElementInspectState() throws -> AccessibilityElementInspectResult {
        let elementID = try requiredOption("--element")
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )
        let resolved = try resolveGuardedElement(id: elementID, in: app)
        let normalizedID = resolved.id
        let element = resolved.element
        let node = buildNode(
            element,
            id: normalizedID,
            ownerName: app.localizedName,
            ownerBundleIdentifier: app.bundleIdentifier,
            depth: depth,
            maxChildren: maxChildren
        )
        let identityVerification: IdentityVerification?
        if let resolvedVerification = resolved.identityVerification {
            identityVerification = resolvedVerification
        } else {
            identityVerification = try verifyElementIdentity(node.stableIdentity)
        }

        return AccessibilityElementInspectResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            element: node,
            identityVerification: identityVerification,
            depth: depth,
            maxChildren: maxChildren,
            message: identityVerification?.ok == false
                ? identityVerification!.message
                : "Accessibility element state inspected."
        )
    }

    private func stateElementFindState() throws -> AccessibilityElementFindResult {
        let query = try accessibilityElementFindQuery()
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 4)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)
        let resultDepth = max(0, option("--result-depth").flatMap(Int.init) ?? 0)
        let resultMaxChildren = max(0, option("--result-max-children").flatMap(Int.init) ?? 20)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 20)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var matches: [ElementNode] = []
        var visitedCount = 0
        var truncated = false

        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        for (index, window) in windows.prefix(maxChildren).enumerated() {
            collectAccessibilityElementMatches(
                window,
                id: "w\(index)",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                query: query,
                remainingDepth: depth,
                maxChildren: maxChildren,
                resultDepth: resultDepth,
                resultMaxChildren: resultMaxChildren,
                limit: limit,
                matches: &matches,
                visitedCount: &visitedCount,
                truncated: &truncated
            )
            if limit > 0, matches.count >= limit {
                break
            }
        }

        if query.includeMenu,
           (limit == 0 || matches.count < limit),
           let menuBar = accessibilityElement(axApp, kAXMenuBarAttribute) {
            collectAccessibilityElementMatches(
                menuBar,
                id: "m0",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                query: query,
                remainingDepth: depth,
                maxChildren: maxChildren,
                resultDepth: resultDepth,
                resultMaxChildren: resultMaxChildren,
                limit: limit,
                matches: &matches,
                visitedCount: &visitedCount,
                truncated: &truncated
            )
        }

        return AccessibilityElementFindResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            query: query,
            depth: depth,
            maxChildren: maxChildren,
            resultDepth: resultDepth,
            resultMaxChildren: resultMaxChildren,
            limit: limit,
            count: matches.count,
            truncated: truncated || (limit > 0 && matches.count >= limit),
            matches: matches,
            message: matches.isEmpty
                ? "No Accessibility elements matched the query."
                : "Accessibility elements matched the query."
        )
    }

    private func stateMenuState() throws -> AccessibilityMenuState {
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)

        try requireTrusted()
        let app = try targetApp()
        let appRecord = AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let menuBar = accessibilityElement(axApp, kAXMenuBarAttribute).map { menuBar in
            buildNode(
                menuBar,
                id: "m0",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        return AccessibilityMenuState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appRecord,
            menuBar: menuBar,
            depth: depth,
            maxChildren: maxChildren,
            message: menuBar == nil
                ? "No Accessibility menu bar was available for the target app."
                : "Accessibility menu bar state inspected."
        )
    }

    private func accessibilityElementFindQuery() throws -> AccessibilityElementFindQuery {
        let match = option("--match") ?? "contains"
        guard ["exact", "contains"].contains(match) else {
            throw CommandError(description: "state find --match must be exact or contains")
        }
        let enabled = try option("--enabled").map {
            try booleanOption($0, optionName: "--enabled")
        }

        return AccessibilityElementFindQuery(
            role: option("--role"),
            subrole: option("--subrole"),
            title: option("--title"),
            value: option("--value"),
            help: option("--help-text"),
            action: option("--action"),
            enabled: enabled,
            match: match,
            includeMenu: flag("--include-menu")
        )
    }

    private func collectAccessibilityElementMatches(
        _ element: AXUIElement,
        id: String,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        query: AccessibilityElementFindQuery,
        remainingDepth: Int,
        maxChildren: Int,
        resultDepth: Int,
        resultMaxChildren: Int,
        limit: Int,
        matches: inout [ElementNode],
        visitedCount: inout Int,
        truncated: inout Bool
    ) {
        if limit > 0, matches.count >= limit {
            truncated = true
            return
        }

        visitedCount += 1
        if accessibilityElement(element, matches: query) {
            matches.append(buildNode(
                element,
                id: id,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                depth: resultDepth,
                maxChildren: resultMaxChildren
            ))
            if limit > 0, matches.count >= limit {
                truncated = true
                return
            }
        }

        guard remainingDepth > 0 else {
            return
        }

        let children = accessibilityArray(element, kAXChildrenAttribute)
        for (index, child) in children.prefix(maxChildren).enumerated() {
            collectAccessibilityElementMatches(
                child,
                id: "\(id).\(index)",
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                query: query,
                remainingDepth: remainingDepth - 1,
                maxChildren: maxChildren,
                resultDepth: resultDepth,
                resultMaxChildren: resultMaxChildren,
                limit: limit,
                matches: &matches,
                visitedCount: &visitedCount,
                truncated: &truncated
            )
            if limit > 0, matches.count >= limit {
                break
            }
        }
    }

    private func accessibilityElement(
        _ element: AXUIElement,
        matches query: AccessibilityElementFindQuery
    ) -> Bool {
        if let role = query.role,
           !stringValue(stringAttribute(element, kAXRoleAttribute), matches: role, mode: query.match) {
            return false
        }
        if let subrole = query.subrole,
           !stringValue(stringAttribute(element, kAXSubroleAttribute), matches: subrole, mode: query.match) {
            return false
        }
        if let title = query.title,
           !stringValue(stringAttribute(element, kAXTitleAttribute), matches: title, mode: query.match) {
            return false
        }
        if let value = query.value,
           !stringValue(stringLikeAttribute(element, kAXValueAttribute), matches: value, mode: query.match) {
            return false
        }
        if let help = query.help,
           !stringValue(stringAttribute(element, kAXHelpAttribute), matches: help, mode: query.match) {
            return false
        }
        if let action = query.action,
           !actionNames(element).contains(action) {
            return false
        }
        if let enabled = query.enabled,
           boolAttribute(element, kAXEnabledAttribute) != enabled {
            return false
        }
        return true
    }

    private func accessibilityElementWaitTarget() throws -> AccessibilityElementWaitTarget {
        let element = try requiredOption("--element")
        let match = option("--match") ?? "contains"
        guard ["exact", "contains"].contains(match) else {
            throw CommandError(description: "state wait-element --match must be exact or contains")
        }
        let enabled = try option("--enabled").map {
            try booleanOption($0, optionName: "--enabled")
        }

        return AccessibilityElementWaitTarget(
            element: element,
            expectedIdentity: option("--expect-identity"),
            minimumConfidence: option("--min-identity-confidence"),
            title: option("--title"),
            value: option("--value"),
            match: match,
            enabled: enabled
        )
    }

    private func waitForAccessibilityElement(
        target: AccessibilityElementWaitTarget,
        expectedExists: Bool,
        app: NSRunningApplication,
        depth: Int,
        maxChildren: Int,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> AccessibilityElementWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var snapshot = try accessibilityElementWaitSnapshot(
            target: target,
            app: app,
            depth: depth,
            maxChildren: maxChildren
        )

        while snapshot.matches != expectedExists, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            snapshot = try accessibilityElementWaitSnapshot(
                target: target,
                app: app,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        let matched = snapshot.matches == expectedExists
        return AccessibilityElementWaitVerification(
            ok: matched,
            code: matched ? "accessibility_element_matched" : "accessibility_element_timeout",
            message: matched
                ? "accessibility element state matched expected criteria"
                : "accessibility element state did not match expected criteria before timeout",
            target: target,
            expectedExists: expectedExists,
            current: snapshot.node,
            identityVerification: snapshot.identityVerification,
            titleMatched: snapshot.titleMatched,
            valueMatched: snapshot.valueMatched,
            enabledMatched: snapshot.enabledMatched,
            matched: matched
        )
    }

    private struct AccessibilityElementWaitSnapshot {
        let node: ElementNode?
        let identityVerification: IdentityVerification?
        let titleMatched: Bool?
        let valueMatched: Bool?
        let enabledMatched: Bool?
        let matches: Bool
    }

    private func accessibilityElementWaitSnapshot(
        target: AccessibilityElementWaitTarget,
        app: NSRunningApplication,
        depth: Int,
        maxChildren: Int
    ) throws -> AccessibilityElementWaitSnapshot {
        let normalizedID: String
        do {
            normalizedID = try normalizedElementID(target.element)
        } catch {
            throw error
        }

        let resolved: GuardedElementResolution
        do {
            resolved = try resolveGuardedElement(id: normalizedID, in: app)
        } catch let error as CommandError {
            if error.description.contains("out of range") {
                return AccessibilityElementWaitSnapshot(
                    node: nil,
                    identityVerification: nil,
                    titleMatched: target.title == nil ? nil : false,
                    valueMatched: target.value == nil ? nil : false,
                    enabledMatched: target.enabled == nil ? nil : false,
                    matches: false
                )
            }
            throw error
        }

        let node = buildNode(
            resolved.element,
            id: resolved.id,
            ownerName: app.localizedName,
            ownerBundleIdentifier: app.bundleIdentifier,
            depth: depth,
            maxChildren: maxChildren
        )
        let identityVerification: IdentityVerification?
        if let resolvedVerification = resolved.identityVerification {
            identityVerification = resolvedVerification
        } else {
            identityVerification = try verifyElementIdentity(node.stableIdentity)
        }
        let identityMatched = identityVerification?.ok != false
        let titleMatched = target.title.map { expectedTitle in
            stringValue(node.title, matches: expectedTitle, mode: target.match)
        }
        let valueMatched = target.value.map { expectedValue in
            stringValue(node.value, matches: expectedValue, mode: target.match)
        }
        let enabledMatched = target.enabled.map { expectedEnabled in
            node.enabled == expectedEnabled
        }
        let matches = identityMatched
            && (titleMatched ?? true)
            && (valueMatched ?? true)
            && (enabledMatched ?? true)

        return AccessibilityElementWaitSnapshot(
            node: node,
            identityVerification: identityVerification,
            titleMatched: titleMatched,
            valueMatched: valueMatched,
            enabledMatched: enabledMatched,
            matches: matches
        )
    }

    func state() throws {
        if arguments.dropFirst().first == "menu" {
            try writeJSON(stateMenuState())
            return
        }

        if arguments.dropFirst().first == "element" {
            try writeJSON(stateElementInspectState())
            return
        }

        if arguments.dropFirst().first == "find" {
            try writeJSON(stateElementFindState())
            return
        }

        if arguments.dropFirst().first == "wait-element" {
            try writeJSON(stateElementWaitState())
            return
        }

        try requireTrusted()
        let depth = option("--depth").flatMap(Int.init) ?? 4
        let maxChildren = option("--max-children").flatMap(Int.init) ?? 120
        if flag("--all") {
            try allState(depth: depth, maxChildren: maxChildren)
            return
        }

        let app = try targetApp()
        let appState = appState(for: app, idPrefix: "w", depth: depth, maxChildren: maxChildren)

        let state = ComputerState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            app: appState.app,
            windows: appState.windows
        )

        try writeJSON(state)
    }

    private func allState(depth: Int, maxChildren: Int) throws {
        let includeBackground = flag("--include-background")
        let apps = runningApps(includeBackground: includeBackground)
        let states = apps.enumerated().compactMap { appIndex, app -> AppState? in
            let state = appState(
                for: app,
                idPrefix: "a\(appIndex).w",
                depth: depth,
                maxChildren: maxChildren
            )
            return state.windows.isEmpty ? nil : state
        }

        try writeJSON(AllComputerState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            apps: states
        ))
    }

}
