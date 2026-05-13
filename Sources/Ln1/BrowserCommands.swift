import AppKit
import CryptoKit
import Foundation

extension Ln1CLI {
    func browser() throws {
        let mode = arguments.dropFirst().first ?? "tabs"

        switch mode {
        case "launch":
            try writeJSON(browserLaunch())
        case "tabs":
            let includeNonPageTargets = flag("--include-non-page")
            try writeJSON(browserTabs(includeNonPageTargets: includeNonPageTargets))
        case "tab":
            let id = try requiredOption("--id")
            let includeNonPageTargets = flag("--include-non-page")
            try writeJSON(browserTab(id: id, includeNonPageTargets: includeNonPageTargets))
        case "text":
            let id = try requiredOption("--id")
            let maxCharacters = max(0, option("--max-characters").flatMap(Int.init) ?? 16_384)
            try writeJSON(browserText(id: id, maxCharacters: maxCharacters))
        case "screenshot":
            let id = try requiredOption("--id")
            try writeJSON(browserScreenshot(id: id))
        case "console":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 100)
            let maxMessageCharacters = max(0, option("--max-message-characters").flatMap(Int.init) ?? 1_000)
            let sampleMilliseconds = max(0, option("--sample-ms").flatMap(Int.init) ?? 1_000)
            try writeJSON(browserConsole(
                id: id,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            ))
        case "dialogs":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 20)
            let maxMessageCharacters = max(0, option("--max-message-characters").flatMap(Int.init) ?? 1_000)
            let sampleMilliseconds = max(0, option("--sample-ms").flatMap(Int.init) ?? 1_000)
            try writeJSON(browserDialogs(
                id: id,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            ))
        case "network":
            let id = try requiredOption("--id")
            let maxEntries = max(0, option("--max-entries").flatMap(Int.init) ?? 100)
            try writeJSON(browserNetwork(id: id, maxEntries: maxEntries))
        case "dom":
            let id = try requiredOption("--id")
            let maxElements = max(0, option("--max-elements").flatMap(Int.init) ?? 200)
            let maxTextCharacters = max(0, option("--max-text-characters").flatMap(Int.init) ?? 120)
            try writeJSON(browserDOM(id: id, maxElements: maxElements, maxTextCharacters: maxTextCharacters))
        case "fill":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserFill(id: id, selector: selector, text: text))
        case "select":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserSelect(id: id, selector: selector))
        case "upload":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserUpload(id: id, selector: selector))
        case "check":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserCheck(id: id, selector: selector))
        case "focus":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserFocus(id: id, selector: selector))
        case "press-key":
            let id = try requiredOption("--id")
            let key = try requiredOption("--key")
            try writeJSON(browserPressKey(id: id, key: key))
        case "click":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserClick(id: id, selector: selector))
        case "navigate":
            let id = try requiredOption("--id")
            let url = try requiredOption("--url")
            try writeJSON(browserNavigate(id: id, requestedURL: url))
        case "wait-url":
            let id = try requiredOption("--id")
            let expectedURL = try requiredOption("--expect-url")
            try writeJSON(browserWaitURL(id: id, expectedURL: expectedURL))
        case "wait-selector":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitSelector(id: id, selector: selector))
        case "wait-count":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitCount(id: id, selector: selector))
        case "wait-text":
            let id = try requiredOption("--id")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitText(id: id, expectedText: text))
        case "wait-element-text":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitElementText(id: id, selector: selector, expectedText: text))
        case "wait-value":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitValue(id: id, selector: selector, expectedValue: text))
        case "wait-ready":
            let id = try requiredOption("--id")
            try writeJSON(browserWaitReady(id: id))
        case "wait-title":
            let id = try requiredOption("--id")
            let title = try requiredOption("--title")
            try writeJSON(browserWaitTitle(id: id, expectedTitle: title))
        case "wait-checked":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitChecked(id: id, selector: selector))
        case "wait-enabled":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitEnabled(id: id, selector: selector))
        case "wait-focus":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            try writeJSON(browserWaitFocus(id: id, selector: selector))
        case "wait-attribute":
            let id = try requiredOption("--id")
            let selector = try requiredOption("--selector")
            let attribute = try requiredOption("--attribute")
            let text = try requiredOption("--text")
            try writeJSON(browserWaitAttribute(id: id, selector: selector, attribute: attribute, expectedValue: text))
        default:
            throw CommandError(description: "unknown browser mode '\(mode)'")
        }
    }

    func browserLaunch() throws -> BrowserLaunchResult {
        let action = "browser.launch"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        guard policy.allowed else {
            throw CommandError(description: policy.message)
        }

        let browser = option("--browser") ?? "chrome"
        let port = try browserLaunchPort()
        let profileURL = URL(fileURLWithPath: expandedPath(
            option("--profile") ?? FileManager.default.temporaryDirectory
                .appendingPathComponent("Ln1-browser-profile-\(browser)-\(port)")
                .path
        )).standardizedFileURL
        let endpoint = "http://127.0.0.1:\(port)"
        let dryRun = try option("--dry-run").map {
            try booleanOption($0, optionName: "--dry-run")
        } ?? true
        let url = option("--url")
        let browserTarget = browserLaunchTarget(browser: browser)
        let appURL = try browserLaunchAppURL(target: browserTarget)
        let executableURL = try browserLaunchExecutableURL(target: browserTarget, appURL: appURL)
        let launchArguments = browserLaunchArguments(port: port, profileURL: profileURL, url: url)
        let downloadDirectoryURL = option("--download-dir").map {
            URL(fileURLWithPath: expandedPath($0)).standardizedFileURL
        }
        let preferencesURL = downloadDirectoryURL.map { _ in
            profileURL
                .appendingPathComponent("Default")
                .appendingPathComponent("Preferences")
        }
        let preferenceKeys = downloadDirectoryURL == nil
            ? []
            : ["download.default_directory", "download.prompt_for_download"]

        guard !dryRun else {
            return BrowserLaunchResult(
                ok: true,
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                action: action,
                risk: risk,
                browser: browserTarget.name,
                bundleIdentifier: browserTarget.bundleIdentifier,
                appPath: appURL?.path,
                executablePath: executableURL.path,
                profilePath: profileURL.path,
                downloadDirectoryPath: downloadDirectoryURL?.path,
                preferencesPath: preferencesURL?.path,
                preferenceKeys: preferenceKeys,
                endpoint: endpoint,
                remoteDebuggingPort: port,
                url: url,
                dryRun: true,
                launched: false,
                pid: nil,
                arguments: [executableURL.path] + launchArguments,
                message: "Dry run only. Browser launch command was planned with an isolated profile and DevTools endpoint."
            )
        }

        try FileManager.default.createDirectory(at: profileURL, withIntermediateDirectories: true)
        if let downloadDirectoryURL, let preferencesURL {
            try browserWriteDownloadPreferences(
                downloadDirectoryURL: downloadDirectoryURL,
                preferencesURL: preferencesURL
            )
        }
        let process = Process()
        process.executableURL = executableURL
        process.arguments = launchArguments
        try process.run()

        return BrowserLaunchResult(
            ok: true,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            action: action,
            risk: risk,
            browser: browserTarget.name,
            bundleIdentifier: browserTarget.bundleIdentifier,
            appPath: appURL?.path,
            executablePath: executableURL.path,
            profilePath: profileURL.path,
            downloadDirectoryPath: downloadDirectoryURL?.path,
            preferencesPath: preferencesURL?.path,
            preferenceKeys: preferenceKeys,
            endpoint: endpoint,
            remoteDebuggingPort: port,
            url: url,
            dryRun: false,
            launched: true,
            pid: process.processIdentifier,
            arguments: [executableURL.path] + launchArguments,
            message: "Launched browser with an isolated profile and DevTools endpoint."
        )
    }

    struct BrowserLaunchTarget {
        let name: String
        let bundleIdentifier: String?
        let executableName: String?
    }

    func browserLaunchTarget(browser rawBrowser: String) -> BrowserLaunchTarget {
        switch rawBrowser.lowercased() {
        case "chrome", "google-chrome", "google chrome":
            return BrowserLaunchTarget(
                name: "chrome",
                bundleIdentifier: "com.google.Chrome",
                executableName: "Google Chrome"
            )
        case "chrome-canary", "canary":
            return BrowserLaunchTarget(
                name: "chrome-canary",
                bundleIdentifier: "com.google.Chrome.canary",
                executableName: "Google Chrome Canary"
            )
        case "chromium":
            return BrowserLaunchTarget(
                name: "chromium",
                bundleIdentifier: "org.chromium.Chromium",
                executableName: "Chromium"
            )
        case "edge", "microsoft-edge":
            return BrowserLaunchTarget(
                name: "edge",
                bundleIdentifier: "com.microsoft.edgemac",
                executableName: "Microsoft Edge"
            )
        case "brave":
            return BrowserLaunchTarget(
                name: "brave",
                bundleIdentifier: "com.brave.Browser",
                executableName: "Brave Browser"
            )
        default:
            return BrowserLaunchTarget(name: rawBrowser, bundleIdentifier: nil, executableName: nil)
        }
    }

    func browserLaunchPort() throws -> Int {
        let port = option("--remote-debugging-port").flatMap(Int.init) ?? 9_222
        guard (1...65_535).contains(port) else {
            throw CommandError(description: "--remote-debugging-port must be between 1 and 65535")
        }
        return port
    }

    func browserLaunchAppURL(target: BrowserLaunchTarget) throws -> URL? {
        if let appPath = option("--app-path") {
            return URL(fileURLWithPath: expandedPath(appPath)).standardizedFileURL
        }
        guard let bundleIdentifier = target.bundleIdentifier else {
            return nil
        }
        return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    func browserLaunchExecutableURL(target: BrowserLaunchTarget, appURL: URL?) throws -> URL {
        if let executablePath = option("--executable") {
            return URL(fileURLWithPath: expandedPath(executablePath)).standardizedFileURL
        }
        guard let appURL, let executableName = target.executableName else {
            throw CommandError(description: "could not resolve a browser executable; pass --executable PATH or --app-path PATH")
        }
        return appURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("MacOS")
            .appendingPathComponent(executableName)
            .standardizedFileURL
    }

    func browserLaunchArguments(port: Int, profileURL: URL, url: String?) -> [String] {
        var launchArguments = [
            "--remote-debugging-port=\(port)",
            "--user-data-dir=\(profileURL.path)",
            "--no-first-run",
            "--no-default-browser-check"
        ]
        if let url {
            launchArguments.append(url)
        }
        return launchArguments
    }

    func browserWriteDownloadPreferences(downloadDirectoryURL: URL, preferencesURL: URL) throws {
        try FileManager.default.createDirectory(at: downloadDirectoryURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: preferencesURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let preferences: [String: Any] = [
            "download": [
                "default_directory": downloadDirectoryURL.path,
                "prompt_for_download": false
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: preferences, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: preferencesURL, options: .atomic)
    }

    func browserTabs(includeNonPageTargets: Bool) throws -> BrowserTabsState {
        let endpoint = try browserEndpoint()
        let tabs = try fetchBrowserTabs(
            from: endpoint,
            includeNonPageTargets: includeNonPageTargets
        )

        return BrowserTabsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            includeNonPageTargets: includeNonPageTargets,
            count: tabs.count,
            tabs: tabs
        )
    }

    func browserTab(id: String, includeNonPageTargets: Bool) throws -> BrowserTabState {
        let endpoint = try browserEndpoint()
        let tabs = try fetchBrowserTabs(
            from: endpoint,
            includeNonPageTargets: includeNonPageTargets
        )
        guard let tab = tabs.first(where: { $0.id == id }) else {
            throw CommandError(description: "no browser tab found with id \(id)")
        }

        return BrowserTabState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tab: tab
        )
    }

    func fetchBrowserTabs(
        from endpoint: URL,
        includeNonPageTargets: Bool
    ) throws -> [BrowserTab] {
        let listURL = browserListURL(for: endpoint)
        let data: Data
        do {
            data = try Data(contentsOf: listURL)
        } catch {
            throw CommandError(description: "could not read browser DevTools target list at \(listURL.absoluteString): \(error.localizedDescription)")
        }

        let targets: [DevToolsTarget]
        do {
            targets = try JSONDecoder().decode([DevToolsTarget].self, from: data)
        } catch {
            throw CommandError(description: "browser DevTools target list at \(listURL.absoluteString) was not valid JSON: \(error.localizedDescription)")
        }

        return targets
            .filter { includeNonPageTargets || ($0.type ?? "page") == "page" }
            .map(browserTab)
            .sorted { left, right in
                (left.title ?? left.url ?? left.id) < (right.title ?? right.url ?? right.id)
            }
    }

    func browserTab(from target: DevToolsTarget) -> BrowserTab {
        BrowserTab(
            id: target.id,
            type: target.type ?? "page",
            title: target.title,
            url: target.url,
            description: target.description,
            webSocketDebuggerURL: target.webSocketDebuggerUrl,
            devtoolsFrontendURL: target.devtoolsFrontendUrl,
            faviconURL: target.faviconUrl,
            attached: target.attached,
            actions: [
                BrowserAction(
                    name: "browser.inspectTab",
                    risk: browserActionRisk(for: "browser.inspectTab"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readText",
                    risk: browserActionRisk(for: "browser.readText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.captureScreenshot",
                    risk: browserActionRisk(for: "browser.captureScreenshot"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readConsole",
                    risk: browserActionRisk(for: "browser.readConsole"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readDialogs",
                    risk: browserActionRisk(for: "browser.readDialogs"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readNetwork",
                    risk: browserActionRisk(for: "browser.readNetwork"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.readDOM",
                    risk: browserActionRisk(for: "browser.readDOM"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.fillFormField",
                    risk: browserActionRisk(for: "browser.fillFormField"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.selectOption",
                    risk: browserActionRisk(for: "browser.selectOption"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.uploadFiles",
                    risk: browserActionRisk(for: "browser.uploadFiles"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.setChecked",
                    risk: browserActionRisk(for: "browser.setChecked"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.focusElement",
                    risk: browserActionRisk(for: "browser.focusElement"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.pressKey",
                    risk: browserActionRisk(for: "browser.pressKey"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.clickElement",
                    risk: browserActionRisk(for: "browser.clickElement"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.navigate",
                    risk: browserActionRisk(for: "browser.navigate"),
                    mutates: true
                ),
                BrowserAction(
                    name: "browser.waitURL",
                    risk: browserActionRisk(for: "browser.waitURL"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitSelector",
                    risk: browserActionRisk(for: "browser.waitSelector"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitCount",
                    risk: browserActionRisk(for: "browser.waitCount"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitText",
                    risk: browserActionRisk(for: "browser.waitText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitElementText",
                    risk: browserActionRisk(for: "browser.waitElementText"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitValue",
                    risk: browserActionRisk(for: "browser.waitValue"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitReady",
                    risk: browserActionRisk(for: "browser.waitReady"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitTitle",
                    risk: browserActionRisk(for: "browser.waitTitle"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitChecked",
                    risk: browserActionRisk(for: "browser.waitChecked"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitEnabled",
                    risk: browserActionRisk(for: "browser.waitEnabled"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitFocus",
                    risk: browserActionRisk(for: "browser.waitFocus"),
                    mutates: false
                ),
                BrowserAction(
                    name: "browser.waitAttribute",
                    risk: browserActionRisk(for: "browser.waitAttribute"),
                    mutates: false
                )
            ]
        )
    }

    func browserText(id: String, maxCharacters: Int) throws -> BrowserTextResult {
        let action = "browser.readText"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.text",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let text = try readBrowserInnerText(from: webSocketURL)
            let digest = sha256Digest(text)
            let returnedText: String
            let truncated: Bool
            if text.count > maxCharacters {
                returnedText = String(text.prefix(maxCharacters))
                truncated = true
            } else {
                returnedText = text
                truncated = false
            }

            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: text.count,
                textDigest: digest,
                domNodeCount: nil,
                domDigest: nil
            )

            let message = truncated
                ? "Read truncated browser page text from tab \(id)."
                : "Read browser page text from tab \(id)."
            try writeAudit(ok: true, code: "read_text", message: message)

            return BrowserTextResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                text: returnedText,
                textLength: text.count,
                textDigest: digest,
                truncated: truncated,
                maxCharacters: maxCharacters,
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

    func browserScreenshot(id: String) throws -> BrowserScreenshotResult {
        let action = "browser.captureScreenshot"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let format = try browserScreenshotFormat(option("--format") ?? "png")
        let quality = option("--quality").flatMap(Int.init)
        let fromSurface = option("--from-surface").map(parseBool) ?? true
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            screenshotFormat: format
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.screenshot",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                screenshotFormat: format
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let bytes = try captureBrowserScreenshot(
                format: format,
                quality: quality,
                fromSurface: fromSurface,
                at: webSocketURL
            )
            let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            let image = NSImage(data: bytes)
            let width = image.map { Double($0.size.width) }
            let height = image.map { Double($0.size.height) }
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                screenshotFormat: format,
                screenshotByteCount: bytes.count,
                screenshotDigest: digest
            )

            let message = "Captured browser screenshot metadata from tab \(id)."
            try writeAudit(ok: true, code: "captured_screenshot", message: message)

            return BrowserScreenshotResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                format: format,
                byteCount: bytes.count,
                digest: digest,
                imageWidth: width,
                imageHeight: height,
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

    func browserConsole(
        id: String,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserConsoleResult {
        let action = "browser.readConsole"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.console",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try readBrowserConsoleMessages(
                from: webSocketURL,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                consoleEntryCount: payload.entryCount,
                consoleDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser console metadata from tab \(id)."
                : "Read browser console metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_console", message: message)

            return BrowserConsoleResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds,
                entries: payload.entries,
                digest: digest,
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

    func browserDialogs(
        id: String,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserDialogResult {
        let action = "browser.readDialogs"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.dialogs",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try readBrowserDialogEvents(
                from: webSocketURL,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                dialogEntryCount: payload.entryCount,
                dialogDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser dialog metadata from tab \(id)."
                : "Read browser dialog metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_dialogs", message: message)

            return BrowserDialogResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters,
                sampleMilliseconds: sampleMilliseconds,
                entries: payload.entries,
                digest: digest,
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

    func browserNetwork(id: String, maxEntries: Int) throws -> BrowserNetworkResult {
        let action = "browser.readNetwork"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.network",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try readBrowserNetworkActivity(
                from: webSocketURL,
                maxEntries: maxEntries
            )
            let payloadData = try JSONEncoder().encode(payload)
            let digest = sha256Digest(String(decoding: payloadData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                networkEntryCount: payload.entryCount,
                networkDigest: digest
            )

            let message = payload.truncated
                ? "Read truncated browser network timing metadata from tab \(id)."
                : "Read browser network timing metadata from tab \(id)."
            try writeAudit(ok: true, code: "read_network", message: message)

            return BrowserNetworkResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                url: payload.url,
                title: payload.title,
                entryCount: payload.entryCount,
                returnedCount: payload.returnedCount,
                truncated: payload.truncated,
                maxEntries: maxEntries,
                entries: payload.entries,
                digest: digest,
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

    func browserDOM(id: String, maxElements: Int, maxTextCharacters: Int) throws -> BrowserDOMResult {
        let action = "browser.readDOM"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.dom",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
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
                domDigest: nil
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let snapshot = try readBrowserDOMSnapshot(
                from: webSocketURL,
                maxElements: maxElements,
                maxTextCharacters: maxTextCharacters
            )
            let snapshotData = try JSONEncoder().encode(snapshot)
            let digest = sha256Digest(String(decoding: snapshotData, as: UTF8.self))
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: snapshot.elementCount,
                domDigest: digest
            )

            let message = snapshot.truncated
                ? "Read truncated browser DOM snapshot from tab \(id)."
                : "Read browser DOM snapshot from tab \(id)."
            try writeAudit(ok: true, code: "read_dom", message: message)

            return BrowserDOMResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                url: snapshot.url,
                title: snapshot.title,
                elements: snapshot.elements,
                elementCount: snapshot.elementCount,
                truncated: snapshot.truncated,
                maxElements: maxElements,
                maxTextCharacters: maxTextCharacters,
                digest: digest,
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

    func browserFill(id: String, selector: String, text: String) throws -> BrowserFormFillResult {
        let action = "browser.fillFormField"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let textDigest = sha256Digest(text)
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            formSelector: selector,
            formTextLength: text.count,
            formTextDigest: textDigest
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.fill",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                formSelector: selector,
                formTextLength: text.count,
                formTextDigest: textDigest
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try fillBrowserFormField(
                selector: selector,
                text: text,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched && payload.valueLength == text.count,
                code: payload.ok && payload.matched && payload.valueLength == text.count ? "value_matched" : payload.code,
                message: payload.ok && payload.matched && payload.valueLength == text.count
                    ? "browser form field contains text with the requested length"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Filled browser form field matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "filled", message: message, verification: verification)

            return BrowserFormFillResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                textLength: text.count,
                textDigest: textDigest,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                resultingValueLength: payload.valueLength,
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

    func browserSelect(id: String, selector: String) throws -> BrowserSelectOptionResult {
        let action = "browser.selectOption"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let requestedValue: String?
        if let rawValue = option("--value") {
            requestedValue = try validatedBrowserSelectOption(rawValue, optionName: "--value")
        } else {
            requestedValue = nil
        }
        let requestedLabel: String?
        if let rawLabel = option("--label") {
            requestedLabel = try validatedBrowserSelectOption(rawLabel, optionName: "--label")
        } else {
            requestedLabel = nil
        }
        guard requestedValue != nil || requestedLabel != nil else {
            throw CommandError(description: "browser select requires --value or --label")
        }
        guard !(requestedValue != nil && requestedLabel != nil) else {
            throw CommandError(description: "browser select accepts either --value or --label, not both")
        }
        let auditOption = requestedValue ?? requestedLabel ?? ""
        let optionDigest = sha256Digest(auditOption)
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            formSelector: selector,
            formTextLength: auditOption.count,
            formTextDigest: optionDigest
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.select",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                formSelector: selector,
                formTextLength: auditOption.count,
                formTextDigest: optionDigest
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try selectBrowserOption(
                selector: selector,
                requestedValue: requestedValue,
                requestedLabel: requestedLabel,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "option_selected" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser select contains the requested option"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Selected browser option matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "selected", message: message, verification: verification)

            return BrowserSelectOptionResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                requestedValueLength: requestedValue?.count,
                requestedValueDigest: requestedValue.map(sha256Digest),
                requestedLabelLength: requestedLabel?.count,
                requestedLabelDigest: requestedLabel.map(sha256Digest),
                verification: verification,
                targetTagName: payload.tagName,
                targetDisabled: payload.disabled,
                optionCount: payload.optionCount,
                selectedIndex: payload.selectedIndex,
                selectedValueLength: payload.selectedValueLength,
                selectedLabelLength: payload.selectedLabelLength,
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

    func browserUpload(id: String, selector: String) throws -> BrowserFileUploadResult {
        let action = "browser.uploadFiles"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let fileURLs = try browserUploadFileURLs()
        let pathDigest = sha256Digest(fileURLs.map(\.path).joined(separator: "\n"))
        let totalBytes = try fileURLs.reduce(0) { partial, url in
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return partial + ((attributes[.size] as? NSNumber)?.intValue ?? 0)
        }
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            uploadSelector: selector,
            uploadFileCount: fileURLs.count,
            uploadTotalBytes: totalBytes,
            uploadDigest: pathDigest
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.upload",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                uploadSelector: selector,
                uploadFileCount: fileURLs.count,
                uploadTotalBytes: totalBytes,
                uploadDigest: pathDigest
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try setBrowserFileInputFiles(
                selector: selector,
                fileURLs: fileURLs,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched && payload.fileCount == fileURLs.count,
                code: payload.ok && payload.matched && payload.fileCount == fileURLs.count ? "files_uploaded" : payload.code,
                message: payload.ok && payload.matched && payload.fileCount == fileURLs.count
                    ? "browser file input contains the requested number of files"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Uploaded \(fileURLs.count) file(s) to browser file input matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "uploaded", message: message, verification: verification)

            return BrowserFileUploadResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                fileCount: fileURLs.count,
                totalBytes: totalBytes,
                pathDigest: pathDigest,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetMultiple: payload.multiple,
                resultingFileCount: payload.fileCount,
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

    func browserCheck(id: String, selector: String) throws -> BrowserCheckedResult {
        let action = "browser.setChecked"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let requestedChecked = try browserCheckedValue(option("--checked") ?? "true")
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            formSelector: selector,
            formChecked: requestedChecked
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.check",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                formSelector: selector,
                formChecked: requestedChecked
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try setBrowserCheckedState(
                selector: selector,
                checked: requestedChecked,
                at: webSocketURL
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched && payload.currentChecked == requestedChecked,
                code: payload.ok && payload.matched && payload.currentChecked == requestedChecked ? "checked_matched" : payload.code,
                message: payload.ok && payload.matched && payload.currentChecked == requestedChecked
                    ? "browser control checked state matches the requested value"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Set browser checked state matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "checked", message: message, verification: verification)

            return BrowserCheckedResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                requestedChecked: requestedChecked,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                currentChecked: payload.currentChecked,
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

    func browserFocus(id: String, selector: String) throws -> BrowserFocusResult {
        let action = "browser.focusElement"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            focusSelector: selector
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.focus",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                focusSelector: selector
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try focusBrowserElement(selector: selector, at: webSocketURL)
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "element_focused" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser active element matches the requested selector"
                    : payload.message
            )

            tabSummary?.focusTagName = payload.tagName

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            let message = "Focused browser element matching selector '\(selector)' in tab \(id)."
            try writeAudit(ok: true, code: "focused", message: message, verification: verification)

            return BrowserFocusResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                verification: verification,
                targetTagName: payload.tagName,
                targetInputType: payload.inputType,
                targetDisabled: payload.disabled,
                targetReadOnly: payload.readOnly,
                activeElementMatched: payload.matched,
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

    func browserPressKey(id: String, key rawKey: String) throws -> BrowserKeyPressResult {
        let action = "browser.pressKey"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let key = try browserKeyDefinition(for: rawKey)
        let modifierSet = try browserModifierSet(option("--modifiers"))
        let modifierMask = browserModifierMask(for: modifierSet)
        let selector = option("--selector")
        var focusVerification: FileOperationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            focusSelector: selector,
            keyName: key.key,
            keyModifiers: modifierSet,
            keyModifierMask: modifierMask
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.press-key",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
                focusSelector: selector,
                keyName: key.key,
                keyModifiers: modifierSet,
                keyModifierMask: modifierMask
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            if let selector {
                let focusPayload = try focusBrowserElement(selector: selector, at: webSocketURL)
                focusVerification = FileOperationVerification(
                    ok: focusPayload.ok && focusPayload.matched,
                    code: focusPayload.ok && focusPayload.matched ? "element_focused" : focusPayload.code,
                    message: focusPayload.ok && focusPayload.matched
                        ? "browser active element matches the requested selector"
                        : focusPayload.message
                )
                tabSummary?.focusTagName = focusPayload.tagName

                guard focusVerification?.ok == true else {
                    let message = focusVerification?.message ?? focusPayload.message
                    try writeAudit(ok: false, code: focusPayload.code, message: message, verification: focusVerification)
                    throw CommandError(description: message)
                }
            }

            let verification = try dispatchBrowserKey(
                key,
                modifiers: modifierSet,
                modifierMask: modifierMask,
                selector: selector,
                at: webSocketURL
            )

            guard verification.ok else {
                try writeAudit(
                    ok: false,
                    code: verification.code,
                    message: verification.message,
                    verification: FileOperationVerification(ok: verification.ok, code: verification.code, message: verification.message)
                )
                throw CommandError(description: verification.message)
            }

            let message = "Pressed browser key '\(key.key)' in tab \(id)."
            try writeAudit(
                ok: true,
                code: "key_pressed",
                message: message,
                verification: FileOperationVerification(ok: true, code: verification.code, message: verification.message)
            )

            return BrowserKeyPressResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                key: key.key,
                modifiers: modifierSet,
                modifierMask: modifierMask,
                selector: selector,
                focusVerification: focusVerification,
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

    func browserClick(id: String, selector: String) throws -> BrowserClickResult {
        let action = "browser.clickElement"
        let risk = browserActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let endpoint = try browserEndpoint()
        let expectedURL = option("--expect-url")
        let match = try browserURLMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var urlVerification: BrowserNavigationVerification?
        var tabSummary: BrowserAuditSummary? = BrowserAuditSummary(
            id: id,
            type: "unknown",
            title: nil,
            url: nil,
            textLength: nil,
            textDigest: nil,
            domNodeCount: nil,
            domDigest: nil,
            navigationURL: expectedURL,
            currentURL: nil,
            urlMatched: nil,
            clickSelector: selector
        )
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String, verification: FileOperationVerification? = nil) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "browser.click",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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
            let normalizedExpectedURL = try expectedURL.map(validatedBrowserExpectedURL)

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
                navigationURL: normalizedExpectedURL,
                currentURL: tab.url,
                urlMatched: nil,
                clickSelector: selector
            )

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                let message = "browser tab \(id) does not expose a valid webSocketDebuggerURL"
                try writeAudit(ok: false, code: "debugger_url_missing", message: message)
                throw CommandError(description: message)
            }

            let payload = try clickBrowserElement(selector: selector, at: webSocketURL)
            tabSummary = BrowserAuditSummary(
                id: tab.id,
                type: tab.type,
                title: tab.title,
                url: tab.url,
                textLength: nil,
                textDigest: nil,
                domNodeCount: nil,
                domDigest: nil,
                navigationURL: normalizedExpectedURL,
                currentURL: tab.url,
                urlMatched: nil,
                clickSelector: selector,
                clickTagName: payload.tagName
            )
            let verification = FileOperationVerification(
                ok: payload.ok && payload.matched,
                code: payload.ok && payload.matched ? "element_clicked" : payload.code,
                message: payload.ok && payload.matched
                    ? "browser element matched selector and received a click"
                    : payload.message
            )

            guard verification.ok else {
                try writeAudit(ok: false, code: payload.code, message: payload.message, verification: verification)
                throw CommandError(description: payload.message)
            }

            if let normalizedExpectedURL {
                urlVerification = try waitForBrowserURL(
                    tabID: id,
                    requestedURL: normalizedExpectedURL,
                    expectedURL: normalizedExpectedURL,
                    match: match,
                    endpoint: endpoint,
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
                    navigationURL: normalizedExpectedURL,
                    currentURL: urlVerification?.currentURL,
                    urlMatched: urlVerification?.matched,
                    clickSelector: selector,
                    clickTagName: payload.tagName
                )
                guard urlVerification?.ok == true else {
                    let message = urlVerification?.message ?? "browser click URL verification failed"
                    let auditVerification = FileOperationVerification(
                        ok: false,
                        code: urlVerification?.code ?? "url_verification_failed",
                        message: message
                    )
                    try writeAudit(ok: false, code: auditVerification.code, message: message, verification: auditVerification)
                    throw CommandError(description: message)
                }
            }

            let message = normalizedExpectedURL == nil
                ? "Clicked browser element matching selector '\(selector)' in tab \(id)."
                : "Clicked browser element matching selector '\(selector)' in tab \(id) and verified the resulting URL."
            let auditVerification = urlVerification.map {
                FileOperationVerification(ok: $0.ok, code: $0.code, message: $0.message)
            } ?? verification
            try writeAudit(ok: true, code: "clicked", message: message, verification: auditVerification)

            return BrowserClickResult(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                endpoint: endpoint.absoluteString,
                tab: tab,
                action: action,
                risk: risk,
                selector: selector,
                verification: verification,
                targetTagName: payload.tagName,
                targetDisabled: payload.disabled,
                targetHref: payload.href,
                expectedURL: normalizedExpectedURL,
                match: normalizedExpectedURL == nil ? nil : match,
                urlVerification: urlVerification,
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

    func browserWaitSelector(id: String, selector: String) throws -> BrowserSelectorWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let state = try browserSelectorWaitState(option("--state") ?? "attached")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserSelector(
            tabID: id,
            selector: normalizedSelector,
            state: state,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected selector state."
            : "Timed out waiting for browser tab \(id) to reach the expected selector state."
        return BrowserSelectorWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            state: state,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitCount(id: String, selector: String) throws -> BrowserCountWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedCount = try browserSelectorCountValue(try requiredOption("--count"))
        let countMatch = try browserCountMatchMode(option("--count-match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserCount(
            tabID: id,
            selector: normalizedSelector,
            expectedCount: expectedCount,
            countMatch: countMatch,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected selector count."
            : "Timed out waiting for browser tab \(id) to reach the expected selector count."
        return BrowserCountWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedCount: expectedCount,
            countMatch: countMatch,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitText(id: String, expectedText: String) throws -> BrowserTextWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedText = try validatedBrowserExpectedText(expectedText)
        let match = try browserTextMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserText(
            tabID: id,
            expectedText: normalizedExpectedText,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected text state."
            : "Timed out waiting for browser tab \(id) to reach the expected text state."
        return BrowserTextWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedTextLength: normalizedExpectedText.count,
            expectedTextDigest: sha256Digest(normalizedExpectedText),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitElementText(id: String, selector: String, expectedText: String) throws -> BrowserElementTextWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedExpectedText = try validatedBrowserExpectedText(expectedText)
        let match = try browserTextMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserElementText(
            tabID: id,
            selector: normalizedSelector,
            expectedText: normalizedExpectedText,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected element text state."
            : "Timed out waiting for browser tab \(id) to reach the expected element text state."
        return BrowserElementTextWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedTextLength: normalizedExpectedText.count,
            expectedTextDigest: sha256Digest(normalizedExpectedText),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitValue(id: String, selector: String, expectedValue: String) throws -> BrowserValueWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedExpectedValue = try validatedBrowserExpectedText(expectedValue)
        let match = try browserTextMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserValue(
            tabID: id,
            selector: normalizedSelector,
            expectedValue: normalizedExpectedValue,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected field value state."
            : "Timed out waiting for browser tab \(id) to reach the expected field value state."
        return BrowserValueWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedValueLength: normalizedExpectedValue.count,
            expectedValueDigest: sha256Digest(normalizedExpectedValue),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitReady(id: String) throws -> BrowserReadyWaitResult {
        let endpoint = try browserEndpoint()
        let state = try browserReadyState(option("--state") ?? "complete")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserReady(
            tabID: id,
            expectedState: state,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected ready state."
            : "Timed out waiting for browser tab \(id) to reach the expected ready state."
        return BrowserReadyWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedState: state,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitTitle(id: String, expectedTitle: String) throws -> BrowserTitleWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedExpectedTitle = try validatedBrowserExpectedTitle(expectedTitle)
        let match = try browserTitleMatchMode(option("--match") ?? "contains")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserTitle(
            tabID: id,
            expectedTitle: normalizedExpectedTitle,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected title state."
            : "Timed out waiting for browser tab \(id) to reach the expected title state."
        return BrowserTitleWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            expectedTitle: normalizedExpectedTitle,
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitChecked(id: String, selector: String) throws -> BrowserCheckedWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedChecked = try browserCheckedValue(option("--checked") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserChecked(
            tabID: id,
            selector: normalizedSelector,
            expectedChecked: expectedChecked,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected checked state."
            : "Timed out waiting for browser tab \(id) to reach the expected checked state."
        return BrowserCheckedWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedChecked: expectedChecked,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitEnabled(id: String, selector: String) throws -> BrowserEnabledWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedEnabled = try browserEnabledValue(option("--enabled") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserEnabled(
            tabID: id,
            selector: normalizedSelector,
            expectedEnabled: expectedEnabled,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected enabled state."
            : "Timed out waiting for browser tab \(id) to reach the expected enabled state."
        return BrowserEnabledWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedEnabled: expectedEnabled,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitFocus(id: String, selector: String) throws -> BrowserFocusWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let expectedFocused = try browserFocusedValue(option("--focused") ?? "true")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserFocus(
            tabID: id,
            selector: normalizedSelector,
            expectedFocused: expectedFocused,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected focus state."
            : "Timed out waiting for browser tab \(id) to reach the expected focus state."
        return BrowserFocusWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            expectedFocused: expectedFocused,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func browserWaitAttribute(id: String, selector: String, attribute: String, expectedValue: String) throws -> BrowserAttributeWaitResult {
        let endpoint = try browserEndpoint()
        let normalizedSelector = try validatedBrowserSelector(selector)
        let normalizedAttribute = try validatedBrowserAttributeName(attribute)
        let normalizedExpectedValue = try validatedBrowserExpectedText(expectedValue)
        let match = try browserTextMatchMode(option("--match") ?? "exact")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForBrowserAttribute(
            tabID: id,
            selector: normalizedSelector,
            attribute: normalizedAttribute,
            expectedValue: normalizedExpectedValue,
            match: match,
            endpoint: endpoint,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        let message = verification.ok
            ? "Browser tab \(id) reached the expected attribute state."
            : "Timed out waiting for browser tab \(id) to reach the expected attribute state."
        return BrowserAttributeWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            endpoint: endpoint.absoluteString,
            tabID: id,
            selector: normalizedSelector,
            attribute: normalizedAttribute,
            expectedValueLength: normalizedExpectedValue.count,
            expectedValueDigest: sha256Digest(normalizedExpectedValue),
            match: match,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: message
        )
    }

    func readBrowserInnerText(from webSocketURL: URL) throws -> String {
        let expression = """
        (() => {
          const root = document.body || document.documentElement;
          return root ? root.innerText : "";
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        if let value = remoteObject.value {
            return value
        }
        if remoteObject.type == "undefined" {
            return ""
        }
        throw CommandError(description: "Chrome DevTools Runtime.evaluate returned \(remoteObject.type ?? "unknown") instead of string text")
    }

    func readBrowserConsoleMessages(
        from webSocketURL: URL,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserConsolePayload {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try Self.browserConsolePayload(
                fromEventData: data,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters
            )
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { max(0, $0) } ?? max(sampleMilliseconds + 1_000, 2_000)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let entries = BrowserConsoleEntriesBox()
        let semaphore = DispatchSemaphore(value: 0)
        let deadline = Date().addingTimeInterval(Double(sampleMilliseconds) / 1_000.0)

        @Sendable func receiveNext() {
            task.receive { result in
                switch result {
                case .failure(let error):
                    entries.setError(error)
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }
                        if let entry = try Self.browserConsoleEntry(fromEventData: data, maxMessageCharacters: maxMessageCharacters) {
                            entries.append(entry)
                        }
                        if Date() >= deadline {
                            semaphore.signal()
                        } else {
                            receiveNext()
                        }
                    } catch {
                        entries.setError(error)
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        receiveNext()
        try sendBrowserConsoleSetupCommand(id: 1, method: "Runtime.enable", task: task)
        try sendBrowserConsoleSetupCommand(id: 2, method: "Log.enable", task: task)

        if semaphore.wait(timeout: .now() + Double(timeout) / 1_000.0) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools console events")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        let capturedEntries = try entries.snapshot()
        return Self.browserConsolePayload(
            fromEntries: capturedEntries,
            maxEntries: maxEntries
        )
    }

    func sendBrowserConsoleSetupCommand(id: Int, method: String, task: URLSessionWebSocketTask) throws {
        let payload: [String: Any] = [
            "id": id,
            "method": method,
            "params": [:]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        task.send(.data(data)) { _ in }
    }

    private static func browserConsolePayload(
        fromEventData data: Data,
        maxEntries: Int,
        maxMessageCharacters: Int
    ) throws -> BrowserConsolePayload {
        let json = try JSONSerialization.jsonObject(with: data)
        let messages: [[String: Any]]
        if let array = json as? [[String: Any]] {
            messages = array
        } else if let object = json as? [String: Any] {
            messages = [object]
        } else {
            throw CommandError(description: "Chrome DevTools console event fixture was not an object or array")
        }
        let entries = try messages.compactMap { message -> BrowserConsoleEntry? in
            let eventData = try JSONSerialization.data(withJSONObject: message, options: [])
            return try browserConsoleEntry(fromEventData: eventData, maxMessageCharacters: maxMessageCharacters)
        }
        return browserConsolePayload(fromEntries: entries, maxEntries: maxEntries)
    }

    private static func browserConsolePayload(
        fromEntries entries: [BrowserConsoleEntry],
        maxEntries: Int
    ) -> BrowserConsolePayload {
        let selected = maxEntries == 0 ? [] : Array(entries.suffix(maxEntries))
        return BrowserConsolePayload(
            entryCount: entries.count,
            returnedCount: selected.count,
            truncated: entries.count > selected.count,
            entries: selected
        )
    }

    private static func browserConsoleEntry(
        fromEventData data: Data,
        maxMessageCharacters: Int
    ) throws -> BrowserConsoleEntry? {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let object = json as? [String: Any],
              let method = object["method"] as? String,
              let params = object["params"] as? [String: Any] else {
            return nil
        }

        if method == "Runtime.consoleAPICalled" {
            let level = params["type"] as? String ?? "log"
            let args = params["args"] as? [[String: Any]] ?? []
            let text = args.map(browserConsoleArgumentText).joined(separator: " ")
            return browserConsoleEntry(
                source: "runtime",
                level: level,
                text: text,
                maxMessageCharacters: maxMessageCharacters,
                url: nil,
                lineNumber: nil,
                timestamp: params["timestamp"] as? Double
            )
        }

        if method == "Log.entryAdded",
           let entry = params["entry"] as? [String: Any] {
            return browserConsoleEntry(
                source: entry["source"] as? String ?? "log",
                level: entry["level"] as? String ?? "info",
                text: entry["text"] as? String ?? "",
                maxMessageCharacters: maxMessageCharacters,
                url: entry["url"] as? String,
                lineNumber: entry["lineNumber"] as? Int,
                timestamp: entry["timestamp"] as? Double
            )
        }

        return nil
    }

    private static func browserConsoleArgumentText(_ argument: [String: Any]) -> String {
        if let value = argument["value"] {
            return String(describing: value)
        }
        if let description = argument["description"] as? String {
            return description
        }
        return argument["type"] as? String ?? ""
    }

    private static func browserConsoleEntry(
        source: String,
        level: String,
        text: String,
        maxMessageCharacters: Int,
        url: String?,
        lineNumber: Int?,
        timestamp: Double?
    ) -> BrowserConsoleEntry {
        let returnedText = String(text.prefix(maxMessageCharacters))
        return BrowserConsoleEntry(
            source: source,
            level: level,
            text: returnedText,
            textLength: text.count,
            textDigest: SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined(),
            truncated: text.count > returnedText.count,
            url: url,
            lineNumber: lineNumber,
            timestamp: timestamp
        )
    }

    func readBrowserDialogEvents(
        from webSocketURL: URL,
        maxEntries: Int,
        maxMessageCharacters: Int,
        sampleMilliseconds: Int
    ) throws -> BrowserDialogPayload {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try Self.browserDialogPayload(
                fromEventData: data,
                maxEntries: maxEntries,
                maxMessageCharacters: maxMessageCharacters
            )
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { max(0, $0) } ?? max(sampleMilliseconds + 1_000, 2_000)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let entries = BrowserDialogEntriesBox()
        let semaphore = DispatchSemaphore(value: 0)
        let deadline = Date().addingTimeInterval(Double(sampleMilliseconds) / 1_000.0)

        @Sendable func receiveNext() {
            task.receive { result in
                switch result {
                case .failure(let error):
                    entries.setError(error)
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }
                        if let entry = try Self.browserDialogEntry(fromEventData: data, maxMessageCharacters: maxMessageCharacters) {
                            entries.append(entry)
                        }
                        if Date() >= deadline {
                            semaphore.signal()
                        } else {
                            receiveNext()
                        }
                    } catch {
                        entries.setError(error)
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        receiveNext()
        try sendBrowserConsoleSetupCommand(id: 1, method: "Page.enable", task: task)

        if semaphore.wait(timeout: .now() + Double(timeout) / 1_000.0) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools dialog events")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        let capturedEntries = try entries.snapshot()
        return Self.browserDialogPayload(
            fromEntries: capturedEntries,
            maxEntries: maxEntries
        )
    }

    private static func browserDialogPayload(
        fromEventData data: Data,
        maxEntries: Int,
        maxMessageCharacters: Int
    ) throws -> BrowserDialogPayload {
        let json = try JSONSerialization.jsonObject(with: data)
        let messages: [[String: Any]]
        if let array = json as? [[String: Any]] {
            messages = array
        } else if let object = json as? [String: Any] {
            messages = [object]
        } else {
            throw CommandError(description: "Chrome DevTools dialog event fixture was not an object or array")
        }
        let entries = try messages.compactMap { message -> BrowserDialogEntry? in
            let eventData = try JSONSerialization.data(withJSONObject: message, options: [])
            return try browserDialogEntry(fromEventData: eventData, maxMessageCharacters: maxMessageCharacters)
        }
        return browserDialogPayload(fromEntries: entries, maxEntries: maxEntries)
    }

    private static func browserDialogPayload(
        fromEntries entries: [BrowserDialogEntry],
        maxEntries: Int
    ) -> BrowserDialogPayload {
        let selected = maxEntries == 0 ? [] : Array(entries.suffix(maxEntries))
        return BrowserDialogPayload(
            entryCount: entries.count,
            returnedCount: selected.count,
            truncated: entries.count > selected.count,
            entries: selected
        )
    }

    private static func browserDialogEntry(
        fromEventData data: Data,
        maxMessageCharacters: Int
    ) throws -> BrowserDialogEntry? {
        let json = try JSONSerialization.jsonObject(with: data)
        guard let object = json as? [String: Any],
              let method = object["method"] as? String,
              method == "Page.javascriptDialogOpening",
              let params = object["params"] as? [String: Any] else {
            return nil
        }

        let message = params["message"] as? String ?? ""
        let returnedMessage = String(message.prefix(maxMessageCharacters))
        let defaultPrompt = params["defaultPrompt"] as? String
        let defaultPromptDigest = defaultPrompt.map { prompt in
            SHA256.hash(data: Data(prompt.utf8)).map { String(format: "%02x", $0) }.joined()
        }
        return BrowserDialogEntry(
            type: params["type"] as? String ?? "unknown",
            message: returnedMessage,
            messageLength: message.count,
            messageDigest: SHA256.hash(data: Data(message.utf8)).map { String(format: "%02x", $0) }.joined(),
            truncated: message.count > returnedMessage.count,
            url: params["url"] as? String,
            frameID: params["frameId"] as? String,
            hasBrowserHandler: params["hasBrowserHandler"] as? Bool,
            defaultPromptLength: defaultPrompt?.count,
            defaultPromptDigest: defaultPromptDigest
        )
    }

    func readBrowserNetworkActivity(
        from webSocketURL: URL,
        maxEntries: Int
    ) throws -> BrowserNetworkPayload {
        let expression = """
        (() => {
          const maxEntries = \(maxEntries);
          const round = (value) => Number.isFinite(value) ? Math.round(value * 1000) / 1000 : null;
          const finiteInteger = (value) => Number.isFinite(value) ? Math.round(value) : null;
          const urlParts = (name) => {
            try {
              const url = new URL(name, location.href);
              return {
                scheme: url.protocol ? url.protocol.replace(/:$/, "") : null,
                host: url.host || null
              };
            } catch {
              return { scheme: null, host: null };
            }
          };
          const entries = [
            ...performance.getEntriesByType("navigation"),
            ...performance.getEntriesByType("resource")
          ];
          const selected = maxEntries === 0 ? [] : entries.slice(Math.max(0, entries.length - maxEntries));
          const resultEntries = selected.map((entry) => {
            const parts = urlParts(entry.name || "");
            return {
              name: entry.name || "",
              entryType: entry.entryType || "",
              initiatorType: entry.initiatorType || null,
              startTime: round(entry.startTime),
              duration: round(entry.duration),
              transferSize: finiteInteger(entry.transferSize),
              encodedBodySize: finiteInteger(entry.encodedBodySize),
              decodedBodySize: finiteInteger(entry.decodedBodySize),
              nextHopProtocol: entry.nextHopProtocol || null,
              responseStatus: finiteInteger(entry.responseStatus),
              urlScheme: parts.scheme,
              urlHost: parts.host
            };
          });
          return JSON.stringify({
            url: location.href || null,
            title: document.title || null,
            entryCount: entries.length,
            returnedCount: resultEntries.length,
            truncated: entries.length > resultEntries.length,
            entries: resultEntries
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a network timing result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools network timing result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserNetworkPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools network timing result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func readBrowserDOMSnapshot(
        from webSocketURL: URL,
        maxElements: Int,
        maxTextCharacters: Int
    ) throws -> BrowserDOMSnapshotPayload {
        let expression = """
        (() => {
          const maxElements = \(maxElements);
          const maxTextCharacters = \(maxTextCharacters);
          const ignoredTags = new Set(["SCRIPT", "STYLE", "NOSCRIPT", "TEMPLATE"]);
          const attrNames = [
            "id", "class", "name", "aria-label", "placeholder", "title", "href", "type",
            "aria-expanded", "aria-selected", "aria-checked", "aria-pressed", "aria-disabled",
            "aria-current", "aria-controls"
          ];
          const elements = [];
          const ids = new Map();
          const root = document.body || document.documentElement;
          const queue = root ? [{
            element: root,
            depth: 0,
            parentID: null,
            context: "document",
            framePath: "top",
            frameURL: location.href || null,
            frameAccessible: null,
            shadowPath: null
          }] : [];
          const cssEscape = (value) => {
            if (window.CSS && typeof window.CSS.escape === "function") {
              return window.CSS.escape(value);
            }
            return String(value).replace(/[^a-zA-Z0-9_-]/g, (character) => {
              const codePoint = character.codePointAt(0).toString(16);
              return `\\${codePoint} `;
            });
          };
          const cssString = (value) => String(value).replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
          const isUniqueSelector = (selector, rootNode = document) => {
            try {
              return rootNode.querySelectorAll(selector).length === 1;
            } catch {
              return false;
            }
          };
          const selectorFor = (element) => {
            const rootNode = typeof element.getRootNode === "function" ? element.getRootNode() : document;
            const uniqueInRoot = (selector) => isUniqueSelector(selector, rootNode);
            const tag = element.tagName.toLowerCase();
            if (element.id) {
              const candidate = `#${cssEscape(element.id)}`;
              if (uniqueInRoot(candidate)) return candidate;
            }

            for (const name of ["name", "aria-label", "placeholder", "title", "href", "aria-controls", "aria-current"]) {
              const value = element.getAttribute(name);
              if (!value) continue;
              const candidate = `${tag}[${name}="${cssString(value)}"]`;
              if (uniqueInRoot(candidate)) return candidate;
            }

            const parts = [];
            let current = element;
            while (current && current.nodeType === Node.ELEMENT_NODE && current !== rootNode.documentElement) {
              let part = current.tagName.toLowerCase();
              if (current.id) {
                parts.unshift(`#${cssEscape(current.id)}`);
                const candidate = parts.join(" > ");
                if (uniqueInRoot(candidate)) return candidate;
                current = current.parentElement;
                continue;
              }

              let index = 1;
              let sibling = current;
              while ((sibling = sibling.previousElementSibling)) {
                if (sibling.tagName === current.tagName) index += 1;
              }
              part += `:nth-of-type(${index})`;
              parts.unshift(part);

              const candidate = parts.join(" > ");
              if (uniqueInRoot(candidate)) return candidate;
              current = current.parentElement;
            }
            return parts.join(" > ") || tag;
          };

          const normalizedText = (element) => {
            const raw = (element.innerText || element.textContent || "").replace(/\\s+/g, " ").trim();
            return {
              text: raw.length > maxTextCharacters ? raw.slice(0, maxTextCharacters) : raw,
              length: raw.length
            };
          };

          const inferredRole = (element) => {
            const explicit = element.getAttribute("role");
            if (explicit) return explicit;
            const tag = element.tagName.toLowerCase();
            if (tag === "a" && element.href) return "link";
            if (tag === "button") return "button";
            if (tag === "select") return "combobox";
            if (tag === "textarea") return "textbox";
            if (tag === "form") return "form";
            if (/^h[1-6]$/.test(tag)) return "heading";
            if (tag === "nav") return "navigation";
            if (tag === "main") return "main";
            if (tag === "header") return "banner";
            if (tag === "footer") return "contentinfo";
            if (tag === "input") {
              const type = (element.getAttribute("type") || "text").toLowerCase();
              if (type === "checkbox") return "checkbox";
              if (type === "radio") return "radio";
              if (type === "button" || type === "submit" || type === "reset") return "button";
              return "textbox";
            }
            return null;
          };

          while (queue.length && elements.length < maxElements) {
            const {
              element,
              depth,
              parentID,
              context,
              framePath,
              frameURL,
              frameAccessible,
              shadowPath
            } = queue.shift();
            if (!element.tagName || ignoredTags.has(element.tagName)) continue;

            const id = `dom.${elements.length}`;
            ids.set(element, id);
            const attributes = {};
            for (const name of attrNames) {
              let value = element.getAttribute(name);
              if (name === "href" && element.href) value = element.href;
              if (value) attributes[name] = value;
            }

            const text = normalizedText(element);
            const inputType = element.tagName === "INPUT" ? (element.getAttribute("type") || "text").toLowerCase() : null;
            const suppressValueMetadata = inputType === "password" || inputType === "hidden";
            const value = !suppressValueMetadata && "value" in element ? String(element.value || "") : null;
            const tagName = element.tagName.toLowerCase();
            let elementFrameURL = context === "iframe" ? frameURL : null;
            let elementFrameAccessible = frameAccessible;
            if (tagName === "iframe") {
              elementFrameURL = element.src || element.getAttribute("src") || null;
              try {
                elementFrameAccessible = Boolean(element.contentDocument && (element.contentDocument.body || element.contentDocument.documentElement));
              } catch {
                elementFrameAccessible = false;
              }
            }
            elements.push({
              id,
              parentID,
              depth,
              selector: selectorFor(element),
              context,
              framePath,
              frameURL: elementFrameURL,
              frameAccessible: elementFrameAccessible,
              shadowPath,
              tagName,
              role: inferredRole(element),
              text: text.text || null,
              textLength: text.length,
              attributes,
              inputType,
              checked: "checked" in element ? Boolean(element.checked) : null,
              disabled: "disabled" in element ? Boolean(element.disabled) : null,
              hasValue: value === null ? null : value.length > 0,
              valueLength: value === null ? null : value.length
            });

            for (const child of element.children) {
              queue.push({
                element: child,
                depth: depth + 1,
                parentID: id,
                context,
                framePath,
                frameURL,
                frameAccessible,
                shadowPath
              });
            }

            if (element.shadowRoot) {
              const hostSelector = selectorFor(element);
              const nextShadowPath = shadowPath ? `${shadowPath} > ${hostSelector}` : hostSelector;
              for (const child of element.shadowRoot.children) {
                queue.push({
                  element: child,
                  depth: depth + 1,
                  parentID: id,
                  context: "shadow-root",
                  framePath,
                  frameURL,
                  frameAccessible,
                  shadowPath: nextShadowPath
                });
              }
            }

            if (tagName === "iframe") {
              try {
                const frameDocument = element.contentDocument;
                const frameRoot = frameDocument ? (frameDocument.body || frameDocument.documentElement) : null;
                if (frameRoot) {
                  const nextFramePath = `${framePath} > ${selectorFor(element)}`;
                  const nextFrameURL = element.contentWindow?.location?.href || element.src || null;
                  queue.push({
                    element: frameRoot,
                    depth: depth + 1,
                    parentID: id,
                    context: "iframe",
                    framePath: nextFramePath,
                    frameURL: nextFrameURL,
                    frameAccessible: true,
                    shadowPath: null
                  });
                }
              } catch {
                // Cross-origin frames are represented by their iframe element metadata.
              }
            }
          }

          return JSON.stringify({
            url: location.href,
            title: document.title || null,
            elements,
            elementCount: elements.length,
            truncated: queue.length > 0
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a DOM snapshot string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools DOM snapshot was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserDOMSnapshotPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools DOM snapshot was not valid JSON: \(error.localizedDescription)")
        }
    }

    func captureBrowserScreenshot(
        format: String,
        quality: Int?,
        fromSurface: Bool,
        at webSocketURL: URL
    ) throws -> Data {
        var params: [String: Any] = [
            "format": format,
            "fromSurface": fromSurface
        ]
        if format == "jpeg", let quality {
            params["quality"] = min(100, max(0, quality))
        }
        let response = try sendCDPCommand(
            method: "Page.captureScreenshot",
            params: params,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot failed with \(error.code): \(error.message)")
        }
        guard let data = response.result?.data else {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot response did not include screenshot data")
        }
        guard let bytes = Data(base64Encoded: data) else {
            throw CommandError(description: "Chrome DevTools Page.captureScreenshot returned invalid base64 data")
        }
        return bytes
    }

    func fillBrowserFormField(
        selector: String,
        text: String,
        at webSocketURL: URL
    ) throws -> BrowserFormFillPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const text = \(try javascriptStringLiteral(text));
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            valueLength: extra.valueLength ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = Boolean(element.disabled);
          const readOnly = Boolean(element.readOnly);
          const metadata = { tagName, inputType, disabled, readOnly };

          if (disabled) {
            return result(false, "element_disabled", "The matched form field is disabled.", metadata);
          }
          if (readOnly) {
            return result(false, "element_readonly", "The matched form field is read-only.", metadata);
          }
          if (tagName === "input" && ["password", "hidden", "file"].includes(inputType)) {
            return result(false, "unsupported_sensitive_field", "The matched input type is not supported by browser fill.", metadata);
          }

          const setValue = "value" in element;
          const setContentEditable = !setValue && element.isContentEditable;
          if (!setValue && !setContentEditable) {
            return result(false, "unsupported_element", "The matched element does not expose a writable value.", metadata);
          }

          if (setValue) {
            element.focus?.();
            element.value = text;
          } else {
            element.focus?.();
            element.innerText = text;
          }

          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const currentValue = setValue ? String(element.value || "") : String(element.innerText || "");
          return result(true, "filled", "The matched form field was filled and verified.", {
            ...metadata,
            valueLength: currentValue.length,
            matched: currentValue === text
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a form fill result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools form fill result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserFormFillPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools form fill result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func setBrowserFileInputFiles(
        selector: String,
        fileURLs: [URL],
        at webSocketURL: URL
    ) throws -> BrowserFileUploadPayload {
        let timeout = option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        let documentResponse = try sendCDPCommand(
            method: "DOM.getDocument",
            params: ["depth": 0, "pierce": true],
            at: webSocketURL,
            timeout: timeout
        )
        if let error = documentResponse.error {
            throw CommandError(description: "Chrome DevTools DOM.getDocument failed with \(error.code): \(error.message)")
        }
        guard let rootNodeID = documentResponse.result?.root?.nodeId else {
            throw CommandError(description: "Chrome DevTools DOM.getDocument response did not include a root node ID")
        }

        let queryResponse = try sendCDPCommand(
            method: "DOM.querySelector",
            params: ["nodeId": rootNodeID, "selector": selector],
            at: webSocketURL,
            timeout: timeout
        )
        if let error = queryResponse.error {
            throw CommandError(description: "Chrome DevTools DOM.querySelector failed with \(error.code): \(error.message)")
        }
        guard let nodeID = queryResponse.result?.nodeId, nodeID != 0 else {
            return BrowserFileUploadPayload(
                ok: false,
                code: "element_missing",
                message: "No element matches selector '\(selector)'.",
                selector: selector,
                tagName: nil,
                inputType: nil,
                disabled: nil,
                multiple: nil,
                fileCount: 0,
                matched: false
            )
        }

        let setResponse = try sendCDPCommand(
            method: "DOM.setFileInputFiles",
            params: [
                "nodeId": nodeID,
                "files": fileURLs.map(\.path)
            ],
            at: webSocketURL,
            timeout: timeout
        )
        if let error = setResponse.error {
            throw CommandError(description: "Chrome DevTools DOM.setFileInputFiles failed with \(error.code): \(error.message)")
        }

        let expectedCount = fileURLs.count
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedCount = \(expectedCount);
          const element = document.querySelector(selector);
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            multiple: extra.multiple ?? null,
            fileCount: extra.fileCount ?? 0,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }
          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = Boolean(element.disabled);
          const multiple = Boolean(element.multiple);
          const metadata = { tagName, inputType, disabled, multiple };
          if (tagName !== "input" || inputType !== "file") {
            return result(false, "unsupported_element", "The matched element is not a file input.", metadata);
          }
          if (disabled) {
            return result(false, "element_disabled", "The matched file input is disabled.", metadata);
          }
          const fileCount = element.files ? element.files.length : 0;
          return result(fileCount === expectedCount, fileCount === expectedCount ? "uploaded" : "file_count_mismatch", fileCount === expectedCount ? "The matched file input contains the requested files." : "The matched file input file count did not match.", {
            ...metadata,
            fileCount,
            matched: fileCount === expectedCount
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: timeout
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a file upload result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools file upload result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserFileUploadPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools file upload result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func selectBrowserOption(
        selector: String,
        requestedValue: String?,
        requestedLabel: String?,
        at webSocketURL: URL
    ) throws -> BrowserSelectOptionPayload {
        let requestedValueLiteral = try requestedValue.map(javascriptStringLiteral) ?? "null"
        let requestedLabelLiteral = try requestedLabel.map(javascriptStringLiteral) ?? "null"
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const requestedValue = \(requestedValueLiteral);
          const requestedLabel = \(requestedLabelLiteral);
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            disabled: extra.disabled ?? null,
            optionCount: extra.optionCount ?? null,
            selectedIndex: extra.selectedIndex ?? null,
            selectedValueLength: extra.selectedValueLength ?? null,
            selectedLabelLength: extra.selectedLabelLength ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const metadata = {
            tagName,
            disabled: "disabled" in element ? Boolean(element.disabled) : null,
            optionCount: element.options ? element.options.length : null,
            selectedIndex: "selectedIndex" in element ? element.selectedIndex : null
          };

          if (tagName !== "select" || !element.options) {
            return result(false, "unsupported_element", "The matched element is not a select control.", metadata);
          }
          if (element.disabled) {
            return result(false, "element_disabled", "The matched select control is disabled.", metadata);
          }

          const normalizedLabel = (option) => String(option.label || option.textContent || "").replace(/\\s+/g, " ").trim();
          const options = Array.from(element.options);
          const option = options.find((candidate) => {
            if (requestedValue !== null) return candidate.value === requestedValue;
            return normalizedLabel(candidate) === requestedLabel;
          });

          if (!option) {
            return result(false, "option_missing", "No select option matched the requested value or label.", metadata);
          }

          element.value = option.value;
          option.selected = true;
          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const selected = element.options[element.selectedIndex] || null;
          const selectedLabel = selected ? normalizedLabel(selected) : "";
          const matched = selected
            ? (requestedValue !== null ? selected.value === requestedValue : selectedLabel === requestedLabel)
            : false;
          return result(true, "selected", "The requested select option was selected.", {
            ...metadata,
            selectedIndex: element.selectedIndex,
            selectedValueLength: selected ? String(selected.value || "").length : null,
            selectedLabelLength: selectedLabel.length,
            matched
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a select result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools select result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserSelectOptionPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools select result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func setBrowserCheckedState(
        selector: String,
        checked: Bool,
        at webSocketURL: URL
    ) throws -> BrowserCheckedPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const requestedChecked = \(checked ? "true" : "false");
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            requestedChecked,
            currentChecked: extra.currentChecked ?? null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly, currentChecked: "checked" in element ? Boolean(element.checked) : null };

          if (tagName !== "input" || !["checkbox", "radio"].includes(inputType)) {
            return result(false, "unsupported_element", "The matched element is not a checkbox or radio input.", metadata);
          }
          if (disabled) {
            return result(false, "element_disabled", "The matched input is disabled.", metadata);
          }
          if (readOnly) {
            return result(false, "element_readonly", "The matched input is read-only.", metadata);
          }
          if (inputType === "radio" && requestedChecked === false) {
            return result(false, "unsupported_radio_uncheck", "Radio inputs can only be checked by this command.", metadata);
          }

          element.checked = requestedChecked;
          element.dispatchEvent(new Event("input", { bubbles: true }));
          element.dispatchEvent(new Event("change", { bubbles: true }));

          const currentChecked = Boolean(element.checked);
          return result(true, "checked", "The requested checked state was applied.", {
            ...metadata,
            currentChecked,
            matched: currentChecked === requestedChecked
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a checked-state result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools checked-state result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserCheckedPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools checked-state result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserCheckedState(
        selector: String,
        expectedChecked: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserCheckedWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedChecked = \(expectedChecked ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedChecked,
            currentChecked: extra.currentChecked ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const currentChecked = "checked" in element ? Boolean(element.checked) : null;
          const metadata = { tagName, inputType, disabled, readOnly, currentChecked };

          if (tagName !== "input" || !["checkbox", "radio"].includes(inputType)) {
            return result(false, "unsupported_element", "The matched element is not a checkbox or radio input.", metadata);
          }

          const matched = currentChecked === expectedChecked;
          return result(
            matched,
            matched ? "checked_matched" : "checked_mismatch",
            matched
              ? "browser checked state matched expected value"
              : "browser checked state did not match expected value",
            { ...metadata, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a checked-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools checked-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserCheckedWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserCheckedWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedChecked: verification.expectedChecked,
                    currentChecked: verification.currentChecked,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools checked-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserValue(
        selector: String,
        expectedValue: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserValueWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedValue = \(try javascriptStringLiteral(expectedValue));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            currentValue: extra.currentValue ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly };

          if (!["input", "textarea", "select"].includes(tagName)) {
            return result(false, "unsupported_element", "The matched element does not expose a form value.", metadata);
          }
          if (inputType === "password") {
            return result(false, "unsupported_sensitive_input", "Password input values are not inspected by this command.", metadata);
          }

          const currentValue = String(element.value ?? "");
          const matched = match === "exact"
            ? currentValue === expectedValue
            : currentValue.includes(expectedValue);
          return result(
            matched,
            matched ? "value_matched" : "value_mismatch",
            matched
              ? `browser field value matched expected ${match} value`
              : `browser field value did not match expected ${match} value`,
            { ...metadata, currentValue, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a value wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools value wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserValueWaitPayload.self, from: data)
            return BrowserValueWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                expectedValueLength: expectedValue.count,
                expectedValueDigest: sha256Digest(expectedValue),
                currentValueLength: payload.currentValue?.count,
                currentValueDigest: payload.currentValue.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                inputType: payload.inputType,
                disabled: payload.disabled,
                readOnly: payload.readOnly,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools value wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserElementText(
        selector: String,
        expectedText: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserElementTextWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedText = \(try javascriptStringLiteral(expectedText));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            currentText: extra.currentText ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const rawText = "innerText" in element ? element.innerText : element.textContent;
          const currentText = String(rawText || "").replace(/\\s+/g, " ").trim();
          const matched = match === "exact"
            ? currentText === expectedText
            : currentText.includes(expectedText);
          return result(
            matched,
            matched ? "element_text_matched" : "element_text_mismatch",
            matched
              ? `browser element text matched expected ${match} value`
              : `browser element text did not match expected ${match} value`,
            { tagName, currentText, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an element text wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools element text wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserElementTextWaitPayload.self, from: data)
            return BrowserElementTextWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                expectedTextLength: expectedText.count,
                expectedTextDigest: sha256Digest(expectedText),
                currentTextLength: payload.currentText?.count,
                currentTextDigest: payload.currentText.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools element text wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func dispatchBrowserKey(
        _ key: BrowserKeyDefinition,
        modifiers: [String],
        modifierMask: Int,
        selector: String?,
        at webSocketURL: URL
    ) throws -> BrowserKeyPressVerification {
        if webSocketURL.isFileURL {
            let data = try Data(contentsOf: webSocketURL)
            return try JSONDecoder().decode(BrowserKeyPressVerification.self, from: data)
        }

        let timeout = option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        var downParams: [String: Any] = [
            "type": key.text == nil ? "rawKeyDown" : "keyDown",
            "key": key.key,
            "code": key.code,
            "windowsVirtualKeyCode": key.windowsVirtualKeyCode,
            "nativeVirtualKeyCode": key.windowsVirtualKeyCode,
            "modifiers": modifierMask
        ]
        if let text = key.text, modifierMask == 0 {
            downParams["text"] = text
            downParams["unmodifiedText"] = text
        }
        let upParams: [String: Any] = [
            "type": "keyUp",
            "key": key.key,
            "code": key.code,
            "windowsVirtualKeyCode": key.windowsVirtualKeyCode,
            "nativeVirtualKeyCode": key.windowsVirtualKeyCode,
            "modifiers": modifierMask
        ]

        let down = try sendCDPCommand(method: "Input.dispatchKeyEvent", params: downParams, at: webSocketURL, timeout: timeout)
        if let error = down.error {
            throw CommandError(description: "Chrome DevTools Input.dispatchKeyEvent keyDown failed with \(error.code): \(error.message)")
        }
        let up = try sendCDPCommand(method: "Input.dispatchKeyEvent", params: upParams, at: webSocketURL, timeout: timeout)
        if let error = up.error {
            throw CommandError(description: "Chrome DevTools Input.dispatchKeyEvent keyUp failed with \(error.code): \(error.message)")
        }

        return BrowserKeyPressVerification(
            ok: true,
            code: "key_pressed",
            message: "browser key press dispatched through Chrome DevTools",
            key: key.key,
            modifiers: modifiers,
            modifierMask: modifierMask,
            selector: selector,
            keyDownDispatched: true,
            keyUpDispatched: true
        )
    }

    func focusBrowserElement(
        selector: String,
        at webSocketURL: URL
    ) throws -> BrowserFocusPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const metadata = { tagName, inputType, disabled, readOnly };

          if (disabled) {
            return result(false, "element_disabled", "The matched element is disabled.", metadata);
          }
          if (typeof element.focus !== "function") {
            return result(false, "unsupported_element", "The matched element cannot receive focus.", metadata);
          }

          element.scrollIntoView({ block: "center", inline: "center" });
          element.focus({ preventScroll: true });

          const matched = document.activeElement === element;
          return result(
            matched,
            matched ? "focused" : "focus_mismatch",
            matched
              ? "The matched element received focus."
              : "The active element did not match the requested selector after focus.",
            { ...metadata, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a focus result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools focus result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserFocusPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools focus result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func clickBrowserElement(
        selector: String,
        at webSocketURL: URL
    ) throws -> BrowserClickPayload {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const element = document.querySelector(selector);

          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            tagName: extra.tagName || null,
            disabled: extra.disabled ?? null,
            href: extra.href || null,
            matched: extra.matched || false
          });

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const disabled = Boolean(element.disabled);
          const href = element.href || element.getAttribute("href") || null;
          const metadata = { tagName, disabled, href, matched: true };

          if (disabled) {
            return result(false, "element_disabled", "The matched element is disabled.", metadata);
          }

          element.scrollIntoView({ block: "center", inline: "center" });
          element.click();
          return result(true, "clicked", "The matched element received a click.", metadata);
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a click result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools click result was not valid UTF-8")
        }
        do {
            return try JSONDecoder().decode(BrowserClickPayload.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools click result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserSelector(
        selector: String,
        state: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserSelectorWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const state = \(try javascriptStringLiteral(state));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            state,
            matched: extra.matched || false,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            href: extra.href || null,
            textLength: extra.textLength ?? null
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            if (state === "detached" || state === "hidden") {
              return result(true, state === "detached" ? "selector_detached" : "selector_hidden", `The selector reached '${state}' state.`, {
                matched: true
              });
            }
            return result(false, "selector_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const disabled = "disabled" in element ? Boolean(element.disabled) : null;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const href = element.href || element.getAttribute?.("href") || null;
          const text = (element.innerText || element.textContent || "").replace(/\\s+/g, " ").trim();
          const metadata = { tagName, inputType, disabled, readOnly, href, textLength: text.length, matched: true };
          const style = window.getComputedStyle(element);
          const rect = element.getBoundingClientRect();
          const visible = rect.width > 0
            && rect.height > 0
            && style.display !== "none"
            && style.visibility !== "hidden"
            && style.visibility !== "collapse"
            && style.opacity !== "0";

          if (state === "visible") {
            if (!visible) {
              return result(false, "selector_not_visible", "The matched element is not visible.", {
                ...metadata,
                matched: false
              });
            }
          } else if (state === "hidden") {
            if (visible) {
              return result(false, "selector_still_visible", "The matched element is still visible.", {
                ...metadata,
                matched: false
              });
            }
            return result(true, "selector_hidden", "The selector reached 'hidden' state.", metadata);
          } else if (state === "detached") {
            return result(false, "selector_still_attached", "The matched element is still attached.", {
              ...metadata,
              matched: false
            });
          }

          return result(true, "selector_matched", `The selector reached '${state}' state.`, metadata);
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a selector wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools selector wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserSelectorWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserSelectorWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    state: verification.state,
                    matched: verification.matched,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    href: verification.href,
                    textLength: verification.textLength
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools selector wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserCount(
        selector: String,
        expectedCount: Int,
        countMatch: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserCountWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedCount = \(expectedCount);
          const countMatch = \(try javascriptStringLiteral(countMatch));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedCount,
            currentCount: extra.currentCount ?? null,
            currentURL: location.href || null,
            countMatch,
            matched: extra.matched || false
          });

          let elements = null;
          try {
            elements = document.querySelectorAll(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          const currentCount = elements.length;
          const matched = countMatch === "exact"
            ? currentCount === expectedCount
            : countMatch === "at-least"
              ? currentCount >= expectedCount
              : currentCount <= expectedCount;
          return result(
            matched,
            matched ? "count_matched" : "count_mismatch",
            matched
              ? `browser selector count matched expected ${countMatch} value`
              : `browser selector count did not match expected ${countMatch} value`,
            { currentCount, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a selector count wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools selector count wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserCountWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserCountWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedCount: verification.expectedCount,
                    currentCount: verification.currentCount,
                    currentURL: currentURL,
                    countMatch: verification.countMatch,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools selector count wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserEnabledState(
        selector: String,
        expectedEnabled: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserEnabledWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedEnabled = \(expectedEnabled ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedEnabled,
            currentEnabled: extra.currentEnabled ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            disabled: extra.disabled ?? null,
            readOnly: extra.readOnly ?? null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const nativeDisabled = "disabled" in element ? Boolean(element.disabled) : false;
          const ariaDisabled = String(element.getAttribute("aria-disabled") || "").toLowerCase() === "true";
          const disabled = nativeDisabled || ariaDisabled;
          const readOnly = "readOnly" in element ? Boolean(element.readOnly) : null;
          const currentEnabled = !disabled;
          const matched = currentEnabled === expectedEnabled;
          return result(
            matched,
            matched ? "enabled_matched" : "enabled_mismatch",
            matched
              ? "browser element enabled state matched expected value"
              : "browser element enabled state did not match expected value",
            { tagName, inputType, disabled, readOnly, currentEnabled, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an enabled-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools enabled-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserEnabledWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserEnabledWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedEnabled: verification.expectedEnabled,
                    currentEnabled: verification.currentEnabled,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    disabled: verification.disabled,
                    readOnly: verification.readOnly,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools enabled-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserFocusState(
        selector: String,
        expectedFocused: Bool,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserFocusWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const expectedFocused = \(expectedFocused ? "true" : "false");
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            expectedFocused,
            currentFocused: extra.currentFocused ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            inputType: extra.inputType || null,
            activeTagName: extra.activeTagName || null,
            activeInputType: extra.activeInputType || null,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const active = document.activeElement || null;
          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const inputType = tagName === "input" ? (element.getAttribute("type") || "text").toLowerCase() : null;
          const activeTagName = active && active.tagName ? active.tagName.toLowerCase() : null;
          const activeInputType = activeTagName === "input" ? (active.getAttribute("type") || "text").toLowerCase() : null;
          const currentFocused = active === element;
          const matched = currentFocused === expectedFocused;
          return result(
            matched,
            matched ? "focus_matched" : "focus_mismatch",
            matched
              ? "browser element focus state matched expected value"
              : "browser element focus state did not match expected value",
            { tagName, inputType, activeTagName, activeInputType, currentFocused, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a focus-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools focus-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserFocusWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserFocusWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    selector: verification.selector,
                    expectedFocused: verification.expectedFocused,
                    currentFocused: verification.currentFocused,
                    currentURL: currentURL,
                    tagName: verification.tagName,
                    inputType: verification.inputType,
                    activeTagName: verification.activeTagName,
                    activeInputType: verification.activeInputType,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools focus-state wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserAttribute(
        selector: String,
        attribute: String,
        expectedValue: String,
        match: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserAttributeWaitVerification {
        let expression = """
        (() => {
          const selector = \(try javascriptStringLiteral(selector));
          const attribute = \(try javascriptStringLiteral(attribute));
          const expectedValue = \(try javascriptStringLiteral(expectedValue));
          const match = \(try javascriptStringLiteral(match));
          const result = (ok, code, message, extra = {}) => JSON.stringify({
            ok,
            code,
            message,
            selector,
            attribute,
            currentValue: extra.currentValue ?? null,
            currentURL: location.href || null,
            tagName: extra.tagName || null,
            match,
            matched: extra.matched || false
          });

          let element = null;
          try {
            element = document.querySelector(selector);
          } catch {
            return result(false, "selector_invalid", "The CSS selector is invalid.");
          }

          if (!element) {
            return result(false, "element_missing", `No element matches selector '${selector}'.`);
          }

          const currentValue = element.hasAttribute(attribute) ? String(element.getAttribute(attribute) || "") : null;
          const tagName = element.tagName ? element.tagName.toLowerCase() : null;
          const matched = currentValue !== null && (
            match === "exact" ? currentValue === expectedValue : currentValue.includes(expectedValue)
          );
          return result(
            matched,
            matched ? "attribute_matched" : currentValue === null ? "attribute_missing" : "attribute_mismatch",
            matched
              ? `browser attribute matched expected ${match} value`
              : currentValue === null
                ? "browser attribute is missing"
                : `browser attribute did not match expected ${match} value`,
            { tagName, currentValue, matched }
          );
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return an attribute wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools attribute wait result was not valid UTF-8")
        }
        do {
            let payload = try JSONDecoder().decode(BrowserAttributeWaitPayload.self, from: data)
            return BrowserAttributeWaitVerification(
                ok: payload.ok,
                code: payload.code,
                message: payload.message,
                selector: payload.selector,
                attribute: payload.attribute,
                expectedValueLength: expectedValue.count,
                expectedValueDigest: sha256Digest(expectedValue),
                currentValueLength: payload.currentValue?.count,
                currentValueDigest: payload.currentValue.map(sha256Digest),
                currentURL: payload.currentURL ?? currentURL,
                tagName: payload.tagName,
                match: payload.match,
                matched: payload.matched
            )
        } catch {
            throw CommandError(description: "Chrome DevTools attribute wait result was not valid JSON: \(error.localizedDescription)")
        }
    }

    func inspectBrowserReadyState(
        expectedState: String,
        currentURL: String?,
        at webSocketURL: URL
    ) throws -> BrowserReadyWaitVerification {
        let expression = """
        (() => {
          const expectedState = \(try javascriptStringLiteral(expectedState));
          const stateOrder = { loading: 0, interactive: 1, complete: 2 };
          const currentState = document.readyState || null;
          const matched = currentState
            ? stateOrder[currentState] >= stateOrder[expectedState]
            : false;
          return JSON.stringify({
            ok: matched,
            code: matched ? "ready_state_matched" : "ready_state_pending",
            message: matched
              ? `browser document ready state reached ${expectedState}`
              : `browser document ready state has not reached ${expectedState}`,
            expectedState,
            currentState,
            currentURL: location.href || null,
            matched
          });
        })()
        """
        let response = try evaluateCDPRuntimeExpression(
            expression,
            at: webSocketURL,
            timeout: option("--timeout-ms").flatMap(Int.init).map { Double(max(0, $0)) / 1_000.0 } ?? 5.0
        )

        if let error = response.error {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate failed with \(error.code): \(error.message)")
        }
        guard let remoteObject = response.result?.result else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response did not include a result object")
        }
        guard let value = remoteObject.value else {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not return a ready-state wait result string")
        }
        guard let data = value.data(using: .utf8) else {
            throw CommandError(description: "Chrome DevTools ready-state wait result was not valid UTF-8")
        }
        do {
            var verification = try JSONDecoder().decode(BrowserReadyWaitVerification.self, from: data)
            if verification.currentURL == nil, let currentURL {
                verification = BrowserReadyWaitVerification(
                    ok: verification.ok,
                    code: verification.code,
                    message: verification.message,
                    expectedState: verification.expectedState,
                    currentState: verification.currentState,
                    currentURL: currentURL,
                    matched: verification.matched
                )
            }
            return verification
        } catch {
            throw CommandError(description: "Chrome DevTools ready-state wait result was not valid JSON: \(error.localizedDescription)")
        }
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

    func waitForBrowserSelector(
        tabID: String,
        selector: String,
        state: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserSelectorWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserSelectorWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserSelectorWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    state: state,
                    matched: false,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    href: nil,
                    textLength: nil
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserSelector(
                selector: selector,
                state: state,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserSelectorWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "selector_missing",
            message: "browser selector did not reach \(state) state before timeout",
            selector: selector,
            state: state,
            matched: false,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            href: lastVerification?.href,
            textLength: lastVerification?.textLength
        )
    }

    func waitForBrowserCount(
        tabID: String,
        selector: String,
        expectedCount: Int,
        countMatch: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserCountWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserCountWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserCountWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedCount: expectedCount,
                    currentCount: nil,
                    currentURL: nil,
                    countMatch: countMatch,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserCount(
                selector: selector,
                expectedCount: expectedCount,
                countMatch: countMatch,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserCountWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "count_mismatch",
            message: "browser selector count did not match expected \(countMatch) value before timeout",
            selector: selector,
            expectedCount: expectedCount,
            currentCount: lastVerification?.currentCount,
            currentURL: lastVerification?.currentURL,
            countMatch: countMatch,
            matched: false
        )
    }

    func waitForBrowserReady(
        tabID: String,
        expectedState: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserReadyWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserReadyWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserReadyWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    expectedState: expectedState,
                    currentState: nil,
                    currentURL: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserReadyState(
                expectedState: expectedState,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserReadyWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "ready_state_unavailable",
            message: "browser document ready state did not reach \(expectedState) before timeout",
            expectedState: expectedState,
            currentState: lastVerification?.currentState,
            currentURL: lastVerification?.currentURL,
            matched: false
        )
    }

    func waitForBrowserTitle(
        tabID: String,
        expectedTitle: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserTitleWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentTitle: String?
        var currentURL: String?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            if let tab = tabs.first(where: { $0.id == tabID }) {
                currentTitle = tab.title
                currentURL = tab.url
                if browserTitle(currentTitle, matches: expectedTitle, mode: match) {
                    return BrowserTitleWaitVerification(
                        ok: true,
                        code: "title_matched",
                        message: "browser tab title matched expected \(match) value",
                        expectedTitle: expectedTitle,
                        currentTitle: currentTitle,
                        currentURL: currentURL,
                        match: match,
                        matched: true
                    )
                }
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserTitleWaitVerification(
            ok: false,
            code: currentTitle == nil ? "title_unavailable" : "title_mismatch",
            message: "browser tab title did not match expected \(match) value before timeout",
            expectedTitle: expectedTitle,
            currentTitle: currentTitle,
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }

    func waitForBrowserChecked(
        tabID: String,
        selector: String,
        expectedChecked: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserCheckedWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserCheckedWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserCheckedWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedChecked: expectedChecked,
                    currentChecked: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserCheckedState(
                selector: selector,
                expectedChecked: expectedChecked,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" || verification.code == "unsupported_element" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserCheckedWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "checked_mismatch",
            message: "browser checked state did not match expected value before timeout",
            selector: selector,
            expectedChecked: expectedChecked,
            currentChecked: lastVerification?.currentChecked,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            matched: false
        )
    }

    func waitForBrowserEnabled(
        tabID: String,
        selector: String,
        expectedEnabled: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserEnabledWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserEnabledWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserEnabledWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedEnabled: expectedEnabled,
                    currentEnabled: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserEnabledState(
                selector: selector,
                expectedEnabled: expectedEnabled,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserEnabledWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "enabled_mismatch",
            message: "browser enabled state did not match expected value before timeout",
            selector: selector,
            expectedEnabled: expectedEnabled,
            currentEnabled: lastVerification?.currentEnabled,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            matched: false
        )
    }

    func waitForBrowserFocus(
        tabID: String,
        selector: String,
        expectedFocused: Bool,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserFocusWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserFocusWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserFocusWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedFocused: expectedFocused,
                    currentFocused: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    activeTagName: nil,
                    activeInputType: nil,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserFocusState(
                selector: selector,
                expectedFocused: expectedFocused,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserFocusWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "focus_mismatch",
            message: "browser focus state did not match expected value before timeout",
            selector: selector,
            expectedFocused: expectedFocused,
            currentFocused: lastVerification?.currentFocused,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            activeTagName: lastVerification?.activeTagName,
            activeInputType: lastVerification?.activeInputType,
            matched: false
        )
    }

    func waitForBrowserAttribute(
        tabID: String,
        selector: String,
        attribute: String,
        expectedValue: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserAttributeWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserAttributeWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserAttributeWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    attribute: attribute,
                    expectedValueLength: expectedValue.count,
                    expectedValueDigest: sha256Digest(expectedValue),
                    currentValueLength: nil,
                    currentValueDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserAttribute(
                selector: selector,
                attribute: attribute,
                expectedValue: expectedValue,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserAttributeWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "attribute_mismatch",
            message: "browser attribute did not match expected \(match) value before timeout",
            selector: selector,
            attribute: attribute,
            expectedValueLength: expectedValue.count,
            expectedValueDigest: sha256Digest(expectedValue),
            currentValueLength: lastVerification?.currentValueLength,
            currentValueDigest: lastVerification?.currentValueDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            match: match,
            matched: false
        )
    }

    func waitForBrowserValue(
        tabID: String,
        selector: String,
        expectedValue: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserValueWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserValueWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserValueWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedValueLength: expectedValue.count,
                    expectedValueDigest: sha256Digest(expectedValue),
                    currentValueLength: nil,
                    currentValueDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    inputType: nil,
                    disabled: nil,
                    readOnly: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserValue(
                selector: selector,
                expectedValue: expectedValue,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok
                || verification.code == "selector_invalid"
                || verification.code == "unsupported_element"
                || verification.code == "unsupported_sensitive_input" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserValueWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "value_mismatch",
            message: "browser field value did not match expected \(match) value before timeout",
            selector: selector,
            expectedValueLength: expectedValue.count,
            expectedValueDigest: sha256Digest(expectedValue),
            currentValueLength: lastVerification?.currentValueLength,
            currentValueDigest: lastVerification?.currentValueDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            inputType: lastVerification?.inputType,
            disabled: lastVerification?.disabled,
            readOnly: lastVerification?.readOnly,
            match: match,
            matched: false
        )
    }

    func waitForBrowserText(
        tabID: String,
        expectedText: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserTextWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var currentText: String?
        var currentURL: String?
        let expectedDigest = sha256Digest(expectedText)

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            currentURL = tab.url
            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }
            currentText = try readBrowserInnerText(from: webSocketURL)
            if browserText(currentText, matches: expectedText, mode: match) {
                return BrowserTextWaitVerification(
                    ok: true,
                    code: "text_matched",
                    message: "browser tab text matched expected \(match) value",
                    expectedTextLength: expectedText.count,
                    expectedTextDigest: expectedDigest,
                    currentTextLength: currentText?.count,
                    currentTextDigest: currentText.map(sha256Digest),
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

        return BrowserTextWaitVerification(
            ok: false,
            code: currentText == nil ? "text_unavailable" : "text_mismatch",
            message: "browser tab text did not match expected \(match) value before timeout",
            expectedTextLength: expectedText.count,
            expectedTextDigest: expectedDigest,
            currentTextLength: currentText?.count,
            currentTextDigest: currentText.map(sha256Digest),
            currentURL: currentURL,
            match: match,
            matched: false
        )
    }

    func waitForBrowserElementText(
        tabID: String,
        selector: String,
        expectedText: String,
        match: String,
        endpoint: URL,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> BrowserElementTextWaitVerification {
        let start = Date()
        let deadline = start.addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var lastVerification: BrowserElementTextWaitVerification?

        repeat {
            let tabs = try fetchBrowserTabs(from: endpoint, includeNonPageTargets: false)
            guard let tab = tabs.first(where: { $0.id == tabID }) else {
                lastVerification = BrowserElementTextWaitVerification(
                    ok: false,
                    code: "tab_missing",
                    message: "No browser page tab found with id \(tabID).",
                    selector: selector,
                    expectedTextLength: expectedText.count,
                    expectedTextDigest: sha256Digest(expectedText),
                    currentTextLength: nil,
                    currentTextDigest: nil,
                    currentURL: nil,
                    tagName: nil,
                    match: match,
                    matched: false
                )
                if Date() >= deadline {
                    break
                }
                Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
                continue
            }

            guard let webSocketDebuggerURL = tab.webSocketDebuggerURL,
                  let webSocketURL = URL(string: webSocketDebuggerURL) else {
                throw CommandError(description: "browser tab \(tabID) does not expose a valid webSocketDebuggerURL")
            }

            let verification = try inspectBrowserElementText(
                selector: selector,
                expectedText: expectedText,
                match: match,
                currentURL: tab.url,
                at: webSocketURL
            )
            lastVerification = verification
            if verification.ok || verification.code == "selector_invalid" {
                return verification
            }

            if Date() >= deadline {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1_000.0)
        } while true

        return BrowserElementTextWaitVerification(
            ok: false,
            code: lastVerification?.code ?? "element_text_mismatch",
            message: "browser element text did not match expected \(match) value before timeout",
            selector: selector,
            expectedTextLength: expectedText.count,
            expectedTextDigest: sha256Digest(expectedText),
            currentTextLength: lastVerification?.currentTextLength,
            currentTextDigest: lastVerification?.currentTextDigest,
            currentURL: lastVerification?.currentURL,
            tagName: lastVerification?.tagName,
            match: match,
            matched: false
        )
    }

    func browserURL(_ currentURL: String?, matches expectedURL: String, mode: String) -> Bool {
        guard let currentURL else {
            return false
        }

        switch mode {
        case "exact":
            return currentURL == expectedURL
        case "prefix":
            return currentURL.hasPrefix(expectedURL)
        case "contains":
            return currentURL.contains(expectedURL)
        default:
            return false
        }
    }

    func browserText(_ currentText: String?, matches expectedText: String, mode: String) -> Bool {
        stringValue(currentText, matches: expectedText, mode: mode)
    }

    func stringValue(_ currentValue: String?, matches expectedValue: String, mode: String) -> Bool {
        guard let currentValue else {
            return false
        }

        switch mode {
        case "exact":
            return currentValue == expectedValue
        case "contains":
            return currentValue.contains(expectedValue)
        default:
            return false
        }
    }

    func browserTitle(_ currentTitle: String?, matches expectedTitle: String, mode: String) -> Bool {
        guard let currentTitle else {
            return false
        }

        switch mode {
        case "exact":
            return currentTitle == expectedTitle
        case "contains":
            return currentTitle.contains(expectedTitle)
        default:
            return false
        }
    }

    func browserTextMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser text match mode '\(rawMode)'. Use exact or contains.")
        }
    }

    func browserTitleMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser title match mode '\(rawMode)'. Use exact or contains.")
        }
    }

    func browserURLMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "prefix", "contains":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser URL match mode '\(rawMode)'. Use exact, prefix, or contains.")
        }
    }

    func browserSelectorWaitState(_ rawState: String) throws -> String {
        switch rawState {
        case "attached", "visible", "hidden", "detached":
            return rawState
        default:
            throw CommandError(description: "unsupported browser selector wait state '\(rawState)'. Use attached, visible, hidden, or detached.")
        }
    }

    func browserSelectorCountValue(_ rawCount: String) throws -> Int {
        guard let count = Int(rawCount), count >= 0 else {
            throw CommandError(description: "unsupported browser selector count '\(rawCount)'. Use a non-negative integer.")
        }
        return count
    }

    func browserCountMatchMode(_ rawMode: String) throws -> String {
        switch rawMode {
        case "exact", "at-least", "at-most":
            return rawMode
        default:
            throw CommandError(description: "unsupported browser count match mode '\(rawMode)'. Use exact, at-least, or at-most.")
        }
    }

    func browserScreenshotFormat(_ rawFormat: String) throws -> String {
        let format = rawFormat.lowercased()
        switch format {
        case "png", "jpeg":
            return format
        case "jpg":
            return "jpeg"
        default:
            throw CommandError(description: "browser screenshot format must be png or jpeg")
        }
    }

    func browserReadyState(_ rawState: String) throws -> String {
        switch rawState {
        case "loading", "interactive", "complete":
            return rawState
        default:
            throw CommandError(description: "unsupported browser ready state '\(rawState)'. Use loading, interactive, or complete.")
        }
    }

    func browserCheckedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser checked value '\(rawValue)'. Use true or false.")
        }
    }

    func browserEnabledValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser enabled value '\(rawValue)'. Use true or false.")
        }
    }

    func browserFocusedValue(_ rawValue: String) throws -> Bool {
        switch rawValue.lowercased() {
        case "true", "1", "yes", "y":
            return true
        case "false", "0", "no", "n":
            return false
        default:
            throw CommandError(description: "unsupported browser focused value '\(rawValue)'. Use true or false.")
        }
    }

    func browserKeyDefinition(for rawKey: String) throws -> BrowserKeyDefinition {
        let trimmed = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CommandError(description: "browser key must not be empty")
        }

        let namedKeys: [String: BrowserKeyDefinition] = [
            "enter": BrowserKeyDefinition(key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r"),
            "return": BrowserKeyDefinition(key: "Enter", code: "Enter", windowsVirtualKeyCode: 13, text: "\r"),
            "tab": BrowserKeyDefinition(key: "Tab", code: "Tab", windowsVirtualKeyCode: 9, text: "\t"),
            "escape": BrowserKeyDefinition(key: "Escape", code: "Escape", windowsVirtualKeyCode: 27, text: nil),
            "esc": BrowserKeyDefinition(key: "Escape", code: "Escape", windowsVirtualKeyCode: 27, text: nil),
            "backspace": BrowserKeyDefinition(key: "Backspace", code: "Backspace", windowsVirtualKeyCode: 8, text: nil),
            "delete": BrowserKeyDefinition(key: "Delete", code: "Delete", windowsVirtualKeyCode: 46, text: nil),
            "arrowup": BrowserKeyDefinition(key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38, text: nil),
            "up": BrowserKeyDefinition(key: "ArrowUp", code: "ArrowUp", windowsVirtualKeyCode: 38, text: nil),
            "arrowdown": BrowserKeyDefinition(key: "ArrowDown", code: "ArrowDown", windowsVirtualKeyCode: 40, text: nil),
            "down": BrowserKeyDefinition(key: "ArrowDown", code: "ArrowDown", windowsVirtualKeyCode: 40, text: nil),
            "arrowleft": BrowserKeyDefinition(key: "ArrowLeft", code: "ArrowLeft", windowsVirtualKeyCode: 37, text: nil),
            "left": BrowserKeyDefinition(key: "ArrowLeft", code: "ArrowLeft", windowsVirtualKeyCode: 37, text: nil),
            "arrowright": BrowserKeyDefinition(key: "ArrowRight", code: "ArrowRight", windowsVirtualKeyCode: 39, text: nil),
            "right": BrowserKeyDefinition(key: "ArrowRight", code: "ArrowRight", windowsVirtualKeyCode: 39, text: nil),
            "home": BrowserKeyDefinition(key: "Home", code: "Home", windowsVirtualKeyCode: 36, text: nil),
            "end": BrowserKeyDefinition(key: "End", code: "End", windowsVirtualKeyCode: 35, text: nil),
            "pageup": BrowserKeyDefinition(key: "PageUp", code: "PageUp", windowsVirtualKeyCode: 33, text: nil),
            "pagedown": BrowserKeyDefinition(key: "PageDown", code: "PageDown", windowsVirtualKeyCode: 34, text: nil),
            "space": BrowserKeyDefinition(key: " ", code: "Space", windowsVirtualKeyCode: 32, text: " ")
        ]
        if let named = namedKeys[trimmed.lowercased()] {
            return named
        }

        if let functionKey = browserFunctionKeyDefinition(for: trimmed) {
            return functionKey
        }

        guard trimmed.range(of: #"^[A-Za-z0-9]$"#, options: .regularExpression) != nil,
              let scalar = trimmed.uppercased().unicodeScalars.first else {
            throw CommandError(description: "unsupported browser key '\(rawKey)'. Use a named key, function key, or one ASCII letter/digit.")
        }
        let upper = String(scalar)
        let lower = trimmed.lowercased()
        let code = scalar.properties.isAlphabetic ? "Key\(upper)" : "Digit\(upper)"
        return BrowserKeyDefinition(key: lower, code: code, windowsVirtualKeyCode: Int(scalar.value), text: lower)
    }

    func browserFunctionKeyDefinition(for rawKey: String) -> BrowserKeyDefinition? {
        let upper = rawKey.uppercased()
        guard upper.range(of: #"^F([1-9]|1[0-2])$"#, options: .regularExpression) != nil,
              let number = Int(upper.dropFirst()) else {
            return nil
        }
        return BrowserKeyDefinition(key: upper, code: upper, windowsVirtualKeyCode: 111 + number, text: nil)
    }

    func browserModifierSet(_ rawModifiers: String?) throws -> [String] {
        guard let rawModifiers, !rawModifiers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        var normalized: [String] = []
        for rawPart in rawModifiers.split(separator: ",") {
            let part = rawPart.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let modifier: String
            switch part {
            case "shift":
                modifier = "shift"
            case "control", "ctrl":
                modifier = "control"
            case "alt", "option":
                modifier = "alt"
            case "meta", "command", "cmd":
                modifier = "meta"
            default:
                throw CommandError(description: "unsupported browser key modifier '\(part)'. Use shift, control, alt, or meta.")
            }
            if !normalized.contains(modifier) {
                normalized.append(modifier)
            }
        }
        return normalized
    }

    func browserModifierMask(_ rawModifiers: String) throws -> Int {
        browserModifierMask(for: try browserModifierSet(rawModifiers))
    }

    func browserModifierMask(for modifiers: [String]) -> Int {
        var mask = 0
        if modifiers.contains("alt") {
            mask |= 1
        }
        if modifiers.contains("control") {
            mask |= 2
        }
        if modifiers.contains("meta") {
            mask |= 4
        }
        if modifiers.contains("shift") {
            mask |= 8
        }
        return mask
    }

    func validatedBrowserSelector(_ rawSelector: String) throws -> String {
        guard !rawSelector.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommandError(description: "browser selector must not be empty")
        }
        return rawSelector
    }

    func validatedBrowserNavigationURL(_ rawURL: String) throws -> String {
        guard let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else {
            throw CommandError(description: "browser navigation URL must be an absolute http or https URL")
        }
        return url.absoluteString
    }

    func validatedBrowserExpectedURL(_ rawURL: String) throws -> String {
        guard !rawURL.isEmpty else {
            throw CommandError(description: "browser expected URL must not be empty")
        }
        if rawURL.contains("://") {
            return try validatedBrowserNavigationURL(rawURL)
        }
        return rawURL
    }

    func validatedBrowserExpectedText(_ rawText: String) throws -> String {
        guard !rawText.isEmpty else {
            throw CommandError(description: "browser expected text must not be empty")
        }
        return rawText
    }

    func validatedBrowserAttributeName(_ rawName: String) throws -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !name.isEmpty else {
            throw CommandError(description: "browser attribute name must not be empty")
        }
        guard name.range(of: #"^[a-z_:][a-z0-9_:.:-]*$"#, options: .regularExpression) != nil else {
            throw CommandError(description: "browser attribute name '\(rawName)' is not supported")
        }
        return name
    }

    func validatedBrowserExpectedTitle(_ rawTitle: String) throws -> String {
        guard !rawTitle.isEmpty else {
            throw CommandError(description: "browser expected title must not be empty")
        }
        return rawTitle
    }

    func validatedBrowserSelectOption(_ rawOption: String, optionName: String) throws -> String {
        guard !rawOption.isEmpty else {
            throw CommandError(description: "browser select \(optionName) must not be empty")
        }
        return rawOption
    }

    func browserUploadFileURLs() throws -> [URL] {
        var paths: [String] = []
        for (index, argument) in arguments.enumerated() where argument == "--path" {
            let valueIndex = arguments.index(after: index)
            guard valueIndex < arguments.endIndex else {
                throw CommandError(description: "--path requires a file path")
            }
            paths.append(arguments[valueIndex])
        }
        if let singlePath = option("--file") {
            paths.append(singlePath)
        }
        guard !paths.isEmpty else {
            throw CommandError(description: "browser upload requires at least one --path FILE")
        }

        return try paths.map { rawPath in
            let url = URL(fileURLWithPath: expandedPath(rawPath)).standardizedFileURL
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
                throw CommandError(description: "upload file does not exist at \(url.path)")
            }
            guard !isDirectory.boolValue else {
                throw CommandError(description: "upload path must be a regular file, not a directory: \(url.path)")
            }
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                throw CommandError(description: "upload file is not readable at \(url.path)")
            }
            return url
        }
    }

    func evaluateCDPRuntimeExpression(
        _ expression: String,
        at webSocketURL: URL,
        timeout: TimeInterval
    ) throws -> CDPEvaluateResponse {
        if webSocketURL.isFileURL {
            let data = try cdpFixtureData(for: webSocketURL, method: "Runtime.evaluate")
            return try Self.decodeCDPEvaluateResponse(from: data)
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let requestID = 1
        let payload: [String: Any] = [
            "id": requestID,
            "method": "Runtime.evaluate",
            "params": [
                "expression": expression,
                "awaitPromise": true,
                "returnByValue": true
            ]
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let result = CDPResponseBox()

        @Sendable func receiveResponse(remainingMessages: Int) {
            guard remainingMessages > 0 else {
                result.set(.failure(CommandError(description: "Chrome DevTools did not return Runtime.evaluate response")))
                semaphore.signal()
                return
            }

            task.receive { messageResult in
                switch messageResult {
                case .failure(let error):
                    result.set(.failure(error))
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }

                        let response = try Self.decodeCDPEvaluateResponse(from: data)
                        if response.id == requestID {
                            result.set(.success(response))
                            semaphore.signal()
                        } else {
                            receiveResponse(remainingMessages: remainingMessages - 1)
                        }
                    } catch {
                        result.set(.failure(error))
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        task.send(.data(requestData)) { error in
            if let error {
                result.set(.failure(error))
                semaphore.signal()
                return
            }
            receiveResponse(remainingMessages: 20)
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools Runtime.evaluate response")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate did not produce a response")
        }()
    }

    func sendCDPCommand(
        method: String,
        params: [String: Any],
        at webSocketURL: URL,
        timeout: TimeInterval
    ) throws -> CDPCommandResponse {
        if webSocketURL.isFileURL {
            let data = try cdpFixtureData(for: webSocketURL, method: method)
            return try JSONDecoder().decode(CDPCommandResponse.self, from: data)
        }

        guard ["ws", "wss"].contains(webSocketURL.scheme?.lowercased() ?? "") else {
            throw CommandError(description: "unsupported DevTools debugger URL scheme '\(webSocketURL.scheme ?? "")'. Use ws or wss.")
        }

        let requestID = 1
        let payload: [String: Any] = [
            "id": requestID,
            "method": method,
            "params": params
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .ephemeral)
        let task = session.webSocketTask(with: webSocketURL)
        let result = CDPCommandResponseBox()

        @Sendable func receiveResponse(remainingMessages: Int) {
            guard remainingMessages > 0 else {
                result.set(.failure(CommandError(description: "Chrome DevTools did not return \(method) response")))
                semaphore.signal()
                return
            }

            task.receive { messageResult in
                switch messageResult {
                case .failure(let error):
                    result.set(.failure(error))
                    semaphore.signal()
                case .success(let message):
                    do {
                        let data: Data
                        switch message {
                        case .data(let messageData):
                            data = messageData
                        case .string(let string):
                            data = Data(string.utf8)
                        @unknown default:
                            throw CommandError(description: "unsupported WebSocket message from Chrome DevTools")
                        }

                        let response = try JSONDecoder().decode(CDPCommandResponse.self, from: data)
                        if response.id == requestID {
                            result.set(.success(response))
                            semaphore.signal()
                        } else {
                            receiveResponse(remainingMessages: remainingMessages - 1)
                        }
                    } catch {
                        result.set(.failure(error))
                        semaphore.signal()
                    }
                }
            }
        }

        task.resume()
        task.send(.data(requestData)) { error in
            if let error {
                result.set(.failure(error))
                semaphore.signal()
                return
            }
            receiveResponse(remainingMessages: 20)
        }

        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel(with: .goingAway, reason: nil)
            session.invalidateAndCancel()
            throw CommandError(description: "timed out waiting for Chrome DevTools \(method) response")
        }

        task.cancel(with: .normalClosure, reason: nil)
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "Chrome DevTools \(method) did not produce a response")
        }()
    }

    func cdpFixtureData(for fileURL: URL, method: String) throws -> Data {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
            let fileName = method.replacingOccurrences(of: ".", with: "-") + ".json"
            return try Data(contentsOf: fileURL.appendingPathComponent(fileName))
        }
        return try Data(contentsOf: fileURL)
    }

    private static func decodeCDPEvaluateResponse(from data: Data) throws -> CDPEvaluateResponse {
        do {
            return try JSONDecoder().decode(CDPEvaluateResponse.self, from: data)
        } catch {
            throw CommandError(description: "Chrome DevTools Runtime.evaluate response was not valid JSON: \(error.localizedDescription)")
        }
    }

    func browserEndpoint() throws -> URL {
        let rawEndpoint = option("--endpoint") ?? "http://127.0.0.1:9222"
        if let url = URL(string: rawEndpoint), url.scheme != nil {
            guard ["http", "https", "file"].contains(url.scheme?.lowercased() ?? "") else {
                throw CommandError(description: "unsupported browser endpoint scheme '\(url.scheme ?? "")'. Use http, https, or file.")
            }
            return url
        }

        return URL(fileURLWithPath: expandedPath(rawEndpoint)).standardizedFileURL
    }

    func browserListURL(for endpoint: URL) -> URL {
        if endpoint.path.hasSuffix("/json/list") {
            return endpoint
        }
        return endpoint.appendingPathComponent("json/list")
    }

    func readURLData(from url: URL, timeoutMilliseconds: Int) throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Double(timeoutMilliseconds) / 1_000.0
        configuration.timeoutIntervalForResource = Double(timeoutMilliseconds) / 1_000.0
        let session = URLSession(configuration: configuration)
        let semaphore = DispatchSemaphore(value: 0)
        let result = DataResponseBox()
        let task = session.dataTask(with: url) { data, _, error in
            if let error {
                result.set(.failure(error))
            } else if let data {
                result.set(.success(data))
            } else {
                result.set(.failure(CommandError(description: "no response data from \(url.absoluteString)")))
            }
            semaphore.signal()
        }

        task.resume()
        if semaphore.wait(timeout: .now() + Double(timeoutMilliseconds) / 1_000.0) == .timedOut {
            task.cancel()
            session.invalidateAndCancel()
            throw CommandError(description: "timed out reading \(url.absoluteString)")
        }
        session.finishTasksAndInvalidate()
        return try result.get()?.get() ?? {
            throw CommandError(description: "no response from \(url.absoluteString)")
        }()
    }

}
