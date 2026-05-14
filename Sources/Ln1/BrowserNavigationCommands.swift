import Foundation

extension Ln1CLI {
    func browserNavigate(id: String, requestedURL: String) throws -> BrowserNavigationResult {
        let action = "browser.navigate"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let expectedURL = option("--expect-url") ?? requestedURL
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var verification: BrowserNavigationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            navigationURL: requestedURL,
            currentURL: nil,
            urlMatched: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.navigate",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification.map {
                    FileOperationVerification(ok: $0.ok, code: $0.code, message: $0.message)
                },
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            let normalizedRequestedURL = try validatedBrowserNavigationURL(requestedURL)
            let normalizedExpectedURL = try validatedBrowserExpectedURL(expectedURL)

            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedRequestedURL,
                currentURL: tab.url,
                urlMatched: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            verification = try navigateBrowserPage(
                tabID: id,
                requestedURL: normalizedRequestedURL,
                expectedURL: normalizedExpectedURL,
                match: match,
                endpoint: endpoint,
                webSocketURL: webSocketURL,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedRequestedURL,
                currentURL: verification?.currentURL,
                urlMatched: verification?.matched
            )

            guard let verification, verification.ok else {
                let message = verification?.message ?? "browser navigation verification failed"
                try writeAudit(ok: false, code: verification?.code ?? "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Navigated browser tab \(id) and verified the resulting URL."
            try writeAudit(ok: true, code: "navigated", message: message)

            return BrowserNavigationResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                requestedURL: normalizedRequestedURL,
                expectedURL: normalizedExpectedURL,
                match: match,
                verification: verification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func browserBack(id: String) throws -> BrowserNavigationRollbackResult {
        let action = "browser.rollbackNavigation"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let steps = max(1, option("--steps").flatMap(Int.init) ?? 1)
        let explicitExpectedURL = try option("--expect-url").map(validatedBrowserExpectedURL)
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var verification: BrowserNavigationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            navigationURL: nil,
            currentURL: nil,
            urlMatched: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.back",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification.map {
                    FileOperationVerification(ok: $0.ok, code: $0.code, message: $0.message)
                },
                browserTab: tabSummary,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == id }) else {
                let message = "no browser page tab found with id \(id)"
                try writeAudit(ok: false, code: "tab_missing", message: message)
                throw CommandError(description: message)
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: nil,
                currentURL: tab.url,
                urlMatched: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let rollback = try rollbackBrowserNavigation(
                tabID: id,
                steps: steps,
                expectedURL: explicitExpectedURL,
                match: match,
                endpoint: endpoint,
                webSocketURL: webSocketURL,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            verification = rollback.verification

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: rollback.targetURL,
                currentURL: rollback.verification.currentURL,
                urlMatched: rollback.verification.matched,
                rollbackFromURL: rollback.historyTarget.currentEntry?.url,
                rollbackEntryID: rollback.historyTarget.targetEntry.id,
                rollbackSteps: steps
            )

            guard rollback.verification.ok else {
                let message = rollback.verification.message
                try writeAudit(ok: false, code: rollback.verification.code, message: message)
                throw CommandError(description: message)
            }

            let message = "Navigated browser tab \(id) back \(steps) history entry and verified the resulting URL."
            try writeAudit(ok: true, code: "navigation_rolled_back", message: message)

            return BrowserNavigationRollbackResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                steps: steps,
                fromURL: rollback.historyTarget.currentEntry?.url,
                targetEntryID: rollback.historyTarget.targetEntry.id,
                targetURL: rollback.targetURL,
                expectedURL: rollback.verification.expectedURL,
                match: match,
                verification: rollback.verification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                let message = error.description
                try writeAudit(ok: false, code: "rejected", message: message)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func browserWaitURL(id: String, expectedURL: String) throws -> BrowserURLWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedURL = try validatedBrowserExpectedURL(expectedURL)
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserURL(
            tabID: id,
            requestedURL: normalizedExpectedURL,
            expectedURL: normalizedExpectedURL,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected URL."
            : "Timed out waiting for browser tab \(id) to reach the expected URL."
        return BrowserURLWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedURL: normalizedExpectedURL,
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func navigateBrowserPage(
        tabID: String,
        requestedURL: String,
        expectedURL: String,
        match: String,
        endpoint: URL,
        webSocketURL: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserNavigationVerification {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try JSONDecoder().decode(BrowserNavigationVerification.self, from: data)
        }

        let response = try sendCDPCommand(
            method: "Page.navigate",
            params: ["url": requestedURL],
            at: webSocketURL,
            timeout: Double(timeoutMilliseconds) / 1_000.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Page.navigate failed with \(error.code): \(error.message)")
        }

        return try waitForBrowserURL(
            tabID: tabID,
            requestedURL: requestedURL,
            expectedURL: expectedURL,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
    }

    struct BrowserNavigationRollbackExecution {
        let historyTarget: BrowserNavigationHistoryTarget
        let targetURL: String
        let verification: BrowserNavigationVerification
    }

    func rollbackBrowserNavigation(
        tabID: String,
        steps: Int,
        expectedURL explicitExpectedURL: String?,
        match: String,
        endpoint: URL,
        webSocketURL: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserNavigationRollbackExecution {
        let historyResponse = try sendCDPCommand(
            method: "Page.getNavigationHistory",
            params: [:],
            at: webSocketURL,
            timeout: Double(timeoutMilliseconds) / 1_000.0
        )
        if let error = historyResponse.error {
            throw CommandError(description: "Chrome DevTools Page.getNavigationHistory failed with \(error.code): \(error.message)")
        }
        guard let history = historyResponse.result,
              let currentIndex = history.currentIndex,
              let entries = history.entries else {
            throw CommandError(description: "Chrome DevTools Page.getNavigationHistory did not return navigation entries")
        }

        let targetIndex = currentIndex - steps
        guard entries.indices.contains(currentIndex) else {
            throw CommandError(description: "browser navigation history current index \(currentIndex) is not available")
        }
        guard entries.indices.contains(targetIndex) else {
            throw CommandError(description: "browser tab \(tabID) cannot go back \(steps) history entr\(steps == 1 ? "y" : "ies")")
        }

        let currentEntry = entries[currentIndex]
        let targetEntry = entries[targetIndex]
        guard let rawTargetURL = targetEntry.url, !rawTargetURL.isEmpty else {
            throw CommandError(description: "browser navigation history target entry has no URL")
        }
        let targetURL = try validatedBrowserExpectedURL(rawTargetURL)
        let expectedURL = explicitExpectedURL ?? targetURL
        let historyTarget = BrowserNavigationHistoryTarget(
            currentIndex: currentIndex,
            targetIndex: targetIndex,
            currentEntry: currentEntry,
            targetEntry: targetEntry
        )

        let navigateResponse = try sendCDPCommand(
            method: "Page.navigateToHistoryEntry",
            params: ["entryId": targetEntry.id],
            at: webSocketURL,
            timeout: Double(timeoutMilliseconds) / 1_000.0
        )
        if let error = navigateResponse.error {
            throw CommandError(description: "Chrome DevTools Page.navigateToHistoryEntry failed with \(error.code): \(error.message)")
        }

        let verification = try waitForBrowserURL(
            tabID: tabID,
            requestedURL: targetURL,
            expectedURL: expectedURL,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return BrowserNavigationRollbackExecution(
            historyTarget: historyTarget,
            targetURL: targetURL,
            verification: verification
        )
    }

    func waitForBrowserURL(
        tabID: String,
        requestedURL: String,
        expectedURL: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserNavigationVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentURL: String?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            currentURL = tabs.first(where: { $0.id == tabID })?.url
            if browserURL(currentURL, matches: expectedURL, mode: match) {
                return BrowserNavigationVerification(
                    ok: true,
                    code: "url_matched",
                    message: "browser tab URL matched expected \(match) value",
                    requestedURL: requestedURL,
                    expectedURL: expectedURL,
                    currentURL: currentURL,
                    match: match,
                    matched: true
                )
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserNavigationVerification(
            ok: false,
            code: "url_mismatch",
            message: "browser tab URL did not match expected \(match) value before timeout",
            requestedURL: requestedURL,
            expectedURL: expectedURL,
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }
}
