import AppKit
import Darwin
import Foundation

extension Ln1CLI {
    func appSummaries(includeAll: Bool, activePid: pid_t?) -> [AppSummary] {
        var records = NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated && (includeAll || $0.activationPolicy == .regular) }
            .map {
                AppSummary(
                    name: $0.localizedName,
                    bundleIdentifier: $0.bundleIdentifier,
                    pid: $0.processIdentifier,
                    active: $0.processIdentifier == activePid,
                    hidden: $0.isHidden
                )
            }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }

        if records.isEmpty {
            records = windowOwnerSummaries(activePid: activePid)
        }

        return records
    }

    func runningAppsState() -> RunningAppsState {
        let includeAll = flag("--all")
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let records = appSummaries(includeAll: includeAll, activePid: activePid)
        let limitedApps = Array(records.prefix(limit))

        return RunningAppsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            includeAll: includeAll,
            limit: limit,
            count: limitedApps.count,
            truncated: records.count > limitedApps.count,
            activeApp: records.first(where: \.active),
            apps: limitedApps,
            message: "Read bounded running app metadata."
        )
    }

    func activeAppState() -> ActiveAppState {
        let app = activeAppRecord()
        return ActiveAppState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            found: app != nil,
            app: app,
            message: app == nil
                ? "No frontmost app was available."
                : "Read frontmost app metadata."
        )
    }

    func installedAppsState() -> InstalledAppsState {
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
        let nameFilter = option("--name")?.lowercased()
        let bundleIdentifierFilter = option("--bundle-id")?.lowercased()
        let searchRoots = installedAppSearchRoots()
        var records: [InstalledAppRecord] = []
        var seenPaths = Set<String>()

        for root in searchRoots {
            guard FileManager.default.fileExists(atPath: root.path) else {
                continue
            }
            collectInstalledApps(
                under: root,
                nameFilter: nameFilter,
                bundleIdentifierFilter: bundleIdentifierFilter,
                seenPaths: &seenPaths,
                records: &records
            )
        }

        records.sort {
            let leftName = $0.name.localizedCaseInsensitiveCompare($1.name)
            if leftName != .orderedSame {
                return leftName == .orderedAscending
            }
            return $0.path < $1.path
        }

        let limited = Array(records.prefix(limit))
        return InstalledAppsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            searchRoots: searchRoots.map(\.path),
            limit: limit,
            count: limited.count,
            truncated: records.count > limited.count,
            apps: limited,
            message: "Read installed app bundle metadata."
        )
    }

    func installedAppSearchRoots() -> [URL] {
        [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Library/CoreServices"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications")
        ].map(\.standardizedFileURL)
    }

    func collectInstalledApps(
        under root: URL,
        nameFilter: String?,
        bundleIdentifierFilter: String?,
        seenPaths: inout Set<String>,
        records: inout [InstalledAppRecord]
    ) {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }

        for case let url as URL in enumerator {
            guard url.pathExtension == "app" else {
                continue
            }
            enumerator.skipDescendants()

            let standardizedURL = url.standardizedFileURL
            guard seenPaths.insert(standardizedURL.path).inserted,
                  let record = installedAppRecord(for: standardizedURL) else {
                continue
            }
            if let nameFilter,
               !record.name.lowercased().contains(nameFilter) {
                continue
            }
            if let bundleIdentifierFilter,
               record.bundleIdentifier?.lowercased() != bundleIdentifierFilter {
                continue
            }
            records.append(record)
        }
    }

    func installedAppRecord(for url: URL) -> InstalledAppRecord? {
        guard let bundle = Bundle(url: url) else {
            return nil
        }

        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        return InstalledAppRecord(
            name: name,
            bundleIdentifier: bundle.bundleIdentifier,
            path: url.path,
            version: version,
            executablePath: bundle.executableURL?.path
        )
    }

    func targetRunningApplicationForAppCommand() throws -> NSRunningApplication {
        if flag("--current") {
            return .current
        }

        if let pidValue = option("--pid") {
            guard let pid = pid_t(pidValue),
                  let app = NSRunningApplication(processIdentifier: pid),
                  !app.isTerminated else {
                throw CommandError(description: "no running app found for --pid \(pidValue)")
            }
            return app
        }

        if let bundleIdentifier = option("--bundle-id") {
            let matches = NSWorkspace.shared.runningApplications
                .filter { !$0.isTerminated && $0.bundleIdentifier == bundleIdentifier }
                .sorted { lhs, rhs in
                    let lhsRegular = lhs.activationPolicy == .regular
                    let rhsRegular = rhs.activationPolicy == .regular
                    if lhsRegular != rhsRegular {
                        return lhsRegular && !rhsRegular
                    }
                    return lhs.processIdentifier < rhs.processIdentifier
                }
            guard let app = matches.first else {
                throw CommandError(description: "no running app found for --bundle-id \(bundleIdentifier)")
            }
            return app
        }

        throw CommandError(description: "app target selection requires --pid PID, --bundle-id BUNDLE_ID, or --current")
    }

    func appLaunchTargetForAppCommand() throws -> (url: URL, summary: AppLaunchTargetSummary) {
        if let bundleIdentifier = option("--bundle-id") {
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
                throw CommandError(description: "no installed application was found for --bundle-id \(bundleIdentifier)")
            }
            return (
                url,
                AppLaunchTargetSummary(
                    name: Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? url.deletingPathExtension().lastPathComponent,
                    bundleIdentifier: Bundle(url: url)?.bundleIdentifier ?? bundleIdentifier,
                    path: url.path
                )
            )
        }

        if let rawPath = option("--path") {
            let url = URL(fileURLWithPath: expandedPath(rawPath)).standardizedFileURL
            var isDirectory = ObjCBool(false)
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  url.pathExtension == "app" else {
                throw CommandError(description: "apps launch --path requires an existing .app bundle path")
            }
            let bundle = Bundle(url: url)
            return (
                url,
                AppLaunchTargetSummary(
                    name: bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? url.deletingPathExtension().lastPathComponent,
                    bundleIdentifier: bundle?.bundleIdentifier,
                    path: url.path
                )
            )
        }

        throw CommandError(description: "apps launch requires --bundle-id BUNDLE_ID or --path APP_BUNDLE")
    }

    func workspaceOpenTargetForCommand() throws -> (url: URL, summary: WorkspaceOpenTarget) {
        let path = option("--path")
        let rawURL = option("--url")
        guard (path == nil) != (rawURL == nil) else {
            throw CommandError(description: "open requires exactly one of --path PATH or --url URL")
        }

        if let path {
            let url = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            let record = try fileRecord(for: url)
            guard record.readable else {
                throw CommandError(description: "open --path requires a readable file or directory at \(url.path)")
            }
            return (
                url,
                WorkspaceOpenTarget(
                    kind: "file",
                    path: url.path,
                    url: url.absoluteString,
                    scheme: "file",
                    host: nil,
                    file: fileAuditTarget(record: record, exists: true)
                )
            )
        }

        let url = try validatedWorkspaceOpenURL(try requiredOption("--url"))
        let fileTarget: FileAuditTarget?
        let kind: String
        let pathValue: String?
        if url.isFileURL {
            let record = try fileRecord(for: url.standardizedFileURL)
            guard record.readable else {
                throw CommandError(description: "open --url file requires a readable file or directory at \(url.path)")
            }
            fileTarget = fileAuditTarget(record: record, exists: true)
            kind = "file"
            pathValue = record.path
        } else {
            fileTarget = nil
            kind = "url"
            pathValue = nil
        }

        return (
            url,
            WorkspaceOpenTarget(
                kind: kind,
                path: pathValue,
                url: url.absoluteString,
                scheme: url.scheme ?? "",
                host: url.host,
                file: fileTarget
            )
        )
    }

    func validatedWorkspaceOpenURL(_ rawURL: String) throws -> URL {
        guard let components = URLComponents(string: rawURL),
              let scheme = components.scheme,
              !scheme.isEmpty,
              let url = components.url else {
            throw CommandError(description: "open --url requires a valid absolute URL with a scheme")
        }

        let lowercasedScheme = scheme.lowercased()
        if ["http", "https"].contains(lowercasedScheme),
           (components.host ?? "").isEmpty {
            throw CommandError(description: "open --url \(lowercasedScheme) URL requires a host")
        }

        return url
    }

    func appActivationChecks(target: NSRunningApplication) -> [AppPreflightCheck] {
        [
            AppPreflightCheck(
                name: "apps.targetRunning",
                ok: !target.isTerminated,
                code: target.isTerminated ? "terminated" : "running",
                message: target.isTerminated
                    ? "target app is terminated"
                    : "target app is running"
            ),
            AppPreflightCheck(
                name: "apps.targetActivatable",
                ok: target.activationPolicy == .regular,
                code: target.activationPolicy == .regular ? "regular" : "not_regular",
                message: target.activationPolicy == .regular
                    ? "target app has regular activation policy"
                    : "target app is not a regular GUI application"
            )
        ]
    }

    func appQuitChecks(target: NSRunningApplication) -> [AppPreflightCheck] {
        [
            AppPreflightCheck(
                name: "apps.targetRunning",
                ok: !target.isTerminated,
                code: target.isTerminated ? "terminated" : "running",
                message: target.isTerminated
                    ? "target app is terminated"
                    : "target app is running"
            ),
            AppPreflightCheck(
                name: "apps.targetNotCurrentProcess",
                ok: target.processIdentifier != getpid(),
                code: target.processIdentifier == getpid() ? "current_process" : "separate_process",
                message: target.processIdentifier == getpid()
                    ? "refusing to quit the current Ln1 process"
                    : "target app is not the current Ln1 process"
            ),
            AppPreflightCheck(
                name: "apps.targetGUI",
                ok: target.activationPolicy == .regular,
                code: target.activationPolicy == .regular ? "regular" : "not_regular",
                message: target.activationPolicy == .regular
                    ? "target app has regular activation policy"
                    : "target app is not a regular GUI application"
            )
        ]
    }

    func appHideChecks(target: NSRunningApplication) -> [AppPreflightCheck] {
        [
            AppPreflightCheck(
                name: "apps.targetRunning",
                ok: !target.isTerminated,
                code: target.isTerminated ? "terminated" : "running",
                message: target.isTerminated
                    ? "target app is terminated"
                    : "target app is running"
            ),
            AppPreflightCheck(
                name: "apps.targetGUI",
                ok: target.activationPolicy == .regular,
                code: target.activationPolicy == .regular ? "regular" : "not_regular",
                message: target.activationPolicy == .regular
                    ? "target app has regular activation policy"
                    : "target app is not a regular GUI application"
            )
        ]
    }

    func verifyAppActivation(
        target: NSRunningApplication,
        requested: Bool,
        activeAfter: AppRecord?
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "activation_request_failed",
                message: "macOS did not accept the app activation request"
            )
        }

        guard activeAfter?.pid == target.processIdentifier else {
            return FileOperationVerification(
                ok: false,
                code: "active_app_mismatch",
                message: "frontmost app did not match the requested app after activation"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: "active_app_matched",
            message: "frontmost app matches the requested app"
        )
    }

    func verifyAppLaunch(
        target: AppLaunchTargetSummary,
        launched: NSRunningApplication?,
        activeAfter: AppRecord?,
        activate: Bool
    ) -> FileOperationVerification {
        guard let launched, !launched.isTerminated else {
            return FileOperationVerification(
                ok: false,
                code: "app_not_running",
                message: "launched application was not running after launch request"
            )
        }

        if let bundleIdentifier = target.bundleIdentifier,
           launched.bundleIdentifier != bundleIdentifier {
            return FileOperationVerification(
                ok: false,
                code: "bundle_mismatch",
                message: "running app bundle identifier did not match requested launch target"
            )
        }

        if activate, activeAfter?.pid != launched.processIdentifier {
            return FileOperationVerification(
                ok: false,
                code: "active_app_mismatch",
                message: "frontmost app did not match the launched app after activation"
            )
        }

        return FileOperationVerification(
            ok: true,
            code: activate ? "launched_active_app" : "app_running",
            message: activate
                ? "launched app is running and frontmost"
                : "launched app is running"
        )
    }

    func verifyAppQuit(
        requested: Bool,
        pid: pid_t,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "quit_request_failed",
                message: "macOS did not accept the app quit request"
            )
        }

        let processVerification = waitForProcess(
            pid: pid,
            expectedExists: false,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )
        return FileOperationVerification(
            ok: processVerification.ok,
            code: processVerification.ok ? "app_exited" : "app_still_running",
            message: processVerification.ok
                ? "target app process exited"
                : "target app process was still running after the quit timeout"
        )
    }

    func verifyAppHidden(
        target: NSRunningApplication,
        requested: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "hide_request_failed",
                message: "macOS did not accept the app hide request"
            )
        }

        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000.0)
        repeat {
            if !target.isTerminated && target.isHidden {
                return FileOperationVerification(
                    ok: true,
                    code: "app_hidden",
                    message: "target app is hidden"
                )
            }
            if timeoutMilliseconds == 0 {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1000.0)
        } while Date() < deadline

        return FileOperationVerification(
            ok: false,
            code: "app_not_hidden",
            message: "target app was not hidden after the hide timeout"
        )
    }

    func verifyAppUnhidden(
        target: NSRunningApplication,
        requested: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "unhide_request_failed",
                message: "macOS did not accept the app unhide request"
            )
        }

        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000.0)
        repeat {
            if !target.isTerminated && !target.isHidden {
                return FileOperationVerification(
                    ok: true,
                    code: "app_unhidden",
                    message: "target app is not hidden"
                )
            }
            if timeoutMilliseconds == 0 {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1000.0)
        } while Date() < deadline

        return FileOperationVerification(
            ok: false,
            code: "app_still_hidden",
            message: "target app was still hidden after the unhide timeout"
        )
    }

    func workspaceOpenVerification(accepted: Bool) -> FileOperationVerification {
        FileOperationVerification(
            ok: accepted,
            code: accepted ? "open_request_accepted" : "open_request_failed",
            message: accepted
                ? "macOS accepted the workspace open request"
                : "macOS did not accept the workspace open request"
        )
    }

    func workspaceOpenTargetDisplayName(_ target: WorkspaceOpenTarget) -> String {
        target.path ?? target.url
    }

    func workspaceOpenHandler(for url: URL) -> AppLaunchTargetSummary? {
        guard let handlerURL = NSWorkspace.shared.urlForApplication(toOpen: url) else {
            return nil
        }
        return appBundleSummary(for: handlerURL.standardizedFileURL)
    }

    func appBundleSummary(for url: URL) -> AppLaunchTargetSummary {
        let bundle = Bundle(url: url)
        return AppLaunchTargetSummary(
            name: bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? url.deletingPathExtension().lastPathComponent,
            bundleIdentifier: bundle?.bundleIdentifier,
            path: url.path
        )
    }

    func runningApp(for target: AppLaunchTargetSummary) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { app in
            if let bundleIdentifier = target.bundleIdentifier,
               app.bundleIdentifier == bundleIdentifier {
                return true
            }
            return app.bundleURL?.standardizedFileURL.path == target.path
        }
    }

    func openApplication(at url: URL, activate: Bool) throws -> NSRunningApplication {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = activate

        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var openedApp: NSRunningApplication?
        nonisolated(unsafe) var openError: Error?

        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            openedApp = app
            openError = error
            semaphore.signal()
        }

        semaphore.wait()

        if let openError {
            throw CommandError(description: openError.localizedDescription)
        }
        guard let openedApp else {
            throw CommandError(description: "macOS did not return a running app for launch target \(url.path)")
        }
        return openedApp
    }

    func waitForActiveApp(
        target: AppRecord,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> AppActiveWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var current = activeAppRecord()

        while current?.pid != target.pid, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            current = activeAppRecord()
        }

        let matched = current?.pid == target.pid
        return AppActiveWaitVerification(
            ok: matched,
            code: matched ? "active_app_matched" : "active_app_timeout",
            message: matched
                ? "frontmost app matched the expected target"
                : "frontmost app did not match the expected target before timeout",
            target: target,
            current: current,
            matched: matched
        )
    }

    func activeAppRecord() -> AppRecord? {
        NSWorkspace.shared.frontmostApplication.map(appRecord(for:))
    }

    func appRecord(for app: NSRunningApplication) -> AppRecord {
        AppRecord(
            name: app.localizedName,
            bundleIdentifier: app.bundleIdentifier,
            pid: app.processIdentifier,
            hidden: app.isHidden
        )
    }

    func appDisplayName(_ app: AppRecord) -> String {
        app.name ?? app.bundleIdentifier ?? "pid \(app.pid)"
    }

    func apps() throws {
        let mode = arguments.dropFirst().first
        switch mode {
        case nil:
            let includeAll = flag("--all")
            let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            try writeJSON(appSummaries(includeAll: includeAll, activePid: activePid))
        case "--help", "-h", "help":
            printHelp()
        case let option? where option.hasPrefix("--"):
            let includeAll = flag("--all")
            let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
            try writeJSON(appSummaries(includeAll: includeAll, activePid: activePid))
        case "active":
            try writeJSON(activeAppState())
        case "list":
            try writeJSON(runningAppsState())
        case "plan":
            try appsPlan()
        case "installed":
            try writeJSON(installedAppsState())
        case "activate":
            try writeJSON(activateApp())
        case "launch":
            try writeJSON(launchApp())
        case "hide":
            try writeJSON(hideApp())
        case "unhide":
            try writeJSON(unhideApp())
        case "quit":
            try writeJSON(quitApp())
        case "wait-active":
            try writeJSON(appActiveWaitState())
        default:
            throw CommandError(description: "unknown apps mode '\(mode!)'")
        }
    }

    func appsPlan() throws {
        let operation = option("--operation") ?? "activate"
        switch operation {
        case "activate":
            try writeJSON(appActivationPlan(operation: operation))
        case "launch":
            try writeJSON(appLaunchPlan(operation: operation))
        case "hide":
            try writeJSON(appHidePlan(operation: operation))
        case "unhide":
            try writeJSON(appUnhidePlan(operation: operation))
        case "quit":
            try writeJSON(appQuitPlan(operation: operation))
        default:
            throw CommandError(description: "unsupported apps plan operation '\(operation)'. Use activate, launch, hide, unhide, or quit.")
        }
    }

    func appActivationPlan(operation: String = "activate") throws -> AppActivationPlan {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let checks = appActivationChecks(target: target)
        let canExecute = policy.allowed && checks.allSatisfy(\.ok)
        let targetRecord = appRecord(for: target)

        return AppActivationPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: targetRecord,
            activeBefore: activeBefore,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Activation preflight passed for \(appDisplayName(targetRecord))."
                : "Activation preflight did not pass for \(appDisplayName(targetRecord))."
        )
    }

    func appLaunchPlan(operation: String = "launch") throws -> AppLaunchPlan {
        let target = try appLaunchTargetForAppCommand()
        let action = "apps.launch"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let existingApp = runningApp(for: target.summary).map(appRecord)
        let activate = option("--activate").map(parseBool) ?? true
        let checks = [
            AppPreflightCheck(
                name: "apps.launchTarget",
                ok: true,
                code: "launch_target_found",
                message: "Launch target app bundle is installed at \(target.summary.path)."
            )
        ]
        let canExecute = policy.allowed

        return AppLaunchPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: target.summary,
            activeBefore: activeBefore,
            runningApp: existingApp,
            activate: activate,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Launch preflight passed for \(target.summary.name ?? target.summary.bundleIdentifier ?? target.summary.path)."
                : "Launch preflight did not pass for \(target.summary.name ?? target.summary.bundleIdentifier ?? target.summary.path)."
        )
    }

    func appHidePlan(operation: String = "hide") throws -> AppHidePlan {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.hide"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let checks = appHideChecks(target: target)
        let canExecute = policy.allowed && checks.allSatisfy(\.ok)
        let targetRecord = appRecord(for: target)

        return AppHidePlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: targetRecord,
            activeBefore: activeBefore,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Hide preflight passed for \(appDisplayName(targetRecord))."
                : "Hide preflight did not pass for \(appDisplayName(targetRecord))."
        )
    }

    func appUnhidePlan(operation: String = "unhide") throws -> AppUnhidePlan {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.unhide"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let checks = appHideChecks(target: target)
        let canExecute = policy.allowed && checks.allSatisfy(\.ok)
        let targetRecord = appRecord(for: target)

        return AppUnhidePlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: targetRecord,
            activeBefore: activeBefore,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Unhide preflight passed for \(appDisplayName(targetRecord))."
                : "Unhide preflight did not pass for \(appDisplayName(targetRecord))."
        )
    }

    func appQuitPlan(operation: String = "quit") throws -> AppQuitPlan {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.quit"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let activeBefore = activeAppRecord()
        let force = flag("--force")
        let checks = appQuitChecks(target: target)
        let canExecute = policy.allowed && checks.allSatisfy(\.ok)
        let targetRecord = appRecord(for: target)

        return AppQuitPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: targetRecord,
            activeBefore: activeBefore,
            force: force,
            checks: checks,
            canExecute: canExecute,
            requiredAllowRisk: risk,
            message: canExecute
                ? "Quit preflight passed for \(appDisplayName(targetRecord))."
                : "Quit preflight did not pass for \(appDisplayName(targetRecord))."
        )
    }

    func activateApp() throws -> AppActivationResult {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let targetRecord = appRecord(for: target)
        let activeBefore = activeAppRecord()
        let checks = appActivationChecks(target: target)
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.activate",
                risk: risk,
                reason: option("--reason"),
                app: targetRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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

            if let failedCheck = checks.first(where: { !$0.ok }) {
                let message = failedCheck.message
                verification = FileOperationVerification(ok: false, code: failedCheck.code, message: message)
                try writeAudit(ok: false, code: "preflight_failed", message: message)
                throw CommandError(description: message)
            }

            let requested = target.activate(options: [])
            Thread.sleep(forTimeInterval: 0.10)
            activeAfter = activeAppRecord()
            verification = verifyAppActivation(target: target, requested: requested, activeAfter: activeAfter)

            guard verification?.ok == true else {
                let message = verification?.message ?? "app activation verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Activated \(appDisplayName(targetRecord))."
            try writeAudit(ok: true, code: "activated", message: message)

            return AppActivationResult(
                ok: true,
                action: action,
                risk: risk,
                target: targetRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                verification: verification!,
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

    func launchApp() throws -> AppLaunchResult {
        let target = try appLaunchTargetForAppCommand()
        let action = "apps.launch"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let activate = option("--activate").map(parseBool) ?? true
        let activeBefore = activeAppRecord()
        var launchedApp: NSRunningApplication?
        var launchedRecord: AppRecord?
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.launch",
                risk: risk,
                reason: option("--reason"),
                app: launchedRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                appLaunchTarget: target.summary,
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

            launchedApp = try openApplication(at: target.url, activate: activate)
            Thread.sleep(forTimeInterval: 0.15)
            if let launchedApp {
                launchedRecord = appRecord(for: launchedApp)
            }
            activeAfter = activeAppRecord()
            verification = verifyAppLaunch(
                target: target.summary,
                launched: launchedApp,
                activeAfter: activeAfter,
                activate: activate
            )

            guard verification?.ok == true else {
                let message = verification?.message ?? "app launch verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Launched \(target.summary.name ?? target.summary.bundleIdentifier ?? target.summary.path)."
            try writeAudit(ok: true, code: "launched", message: message)

            return AppLaunchResult(
                ok: true,
                action: action,
                risk: risk,
                target: target.summary,
                app: launchedRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                activate: activate,
                verification: verification!,
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

    func hideApp() throws -> AppHideResult {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.hide"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let targetRecord = appRecord(for: target)
        let activeBefore = activeAppRecord()
        let hiddenBefore = target.isHidden
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let checks = appHideChecks(target: target)
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.hide",
                risk: risk,
                reason: option("--reason"),
                app: targetRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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

            if let failedCheck = checks.first(where: { !$0.ok }) {
                let message = failedCheck.message
                verification = FileOperationVerification(ok: false, code: failedCheck.code, message: message)
                try writeAudit(ok: false, code: "preflight_failed", message: message)
                throw CommandError(description: message)
            }

            let requested = target.isHidden || target.hide()
            verification = verifyAppHidden(
                target: target,
                requested: requested,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            activeAfter = activeAppRecord()

            guard verification?.ok == true else {
                let message = verification?.message ?? "app hide verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let hiddenAfter = target.isHidden
            let message = "Hid \(appDisplayName(targetRecord))."
            try writeAudit(ok: true, code: "hidden", message: message)

            return AppHideResult(
                ok: true,
                action: action,
                risk: risk,
                target: targetRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                hiddenBefore: hiddenBefore,
                hiddenAfter: hiddenAfter,
                verification: verification!,
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

    func unhideApp() throws -> AppUnhideResult {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.unhide"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let targetRecord = appRecord(for: target)
        let activeBefore = activeAppRecord()
        let hiddenBefore = target.isHidden
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let checks = appHideChecks(target: target)
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.unhide",
                risk: risk,
                reason: option("--reason"),
                app: targetRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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

            if let failedCheck = checks.first(where: { !$0.ok }) {
                let message = failedCheck.message
                verification = FileOperationVerification(ok: false, code: failedCheck.code, message: message)
                try writeAudit(ok: false, code: "preflight_failed", message: message)
                throw CommandError(description: message)
            }

            let requested = !target.isHidden || target.unhide()
            verification = verifyAppUnhidden(
                target: target,
                requested: requested,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            activeAfter = activeAppRecord()

            guard verification?.ok == true else {
                let message = verification?.message ?? "app unhide verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let hiddenAfter = target.isHidden
            let message = "Unhid \(appDisplayName(targetRecord))."
            try writeAudit(ok: true, code: "unhidden", message: message)

            return AppUnhideResult(
                ok: true,
                action: action,
                risk: risk,
                target: targetRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                hiddenBefore: hiddenBefore,
                hiddenAfter: hiddenAfter,
                verification: verification!,
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

    func quitApp() throws -> AppQuitResult {
        let target = try targetRunningApplicationForAppCommand()
        let action = "apps.quit"
        let risk = appActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let targetRecord = appRecord(for: target)
        let targetPID = target.processIdentifier
        let activeBefore = activeAppRecord()
        let force = flag("--force")
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let checks = appQuitChecks(target: target)
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "apps.quit",
                risk: risk,
                reason: option("--reason"),
                app: targetRecord,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
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

            if let failedCheck = checks.first(where: { !$0.ok }) {
                let message = failedCheck.message
                verification = FileOperationVerification(ok: false, code: failedCheck.code, message: message)
                try writeAudit(ok: false, code: "preflight_failed", message: message)
                throw CommandError(description: message)
            }

            let requested = force ? target.forceTerminate() : target.terminate()
            verification = verifyAppQuit(
                requested: requested,
                pid: targetPID,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            activeAfter = activeAppRecord()

            guard verification?.ok == true else {
                let message = verification?.message ?? "app quit verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Quit \(appDisplayName(targetRecord))."
            try writeAudit(ok: true, code: "quit", message: message)

            return AppQuitResult(
                ok: true,
                action: action,
                risk: risk,
                target: targetRecord,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                force: force,
                verification: verification!,
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

    func openWorkspace() throws {
        if flag("--plan") {
            try writeJSON(workspaceOpenPlan())
        } else {
            try writeJSON(openWorkspaceTarget())
        }
    }

    func workspaceOpenPlan() throws -> WorkspaceOpenPlan {
        let target = try workspaceOpenTargetForCommand()
        let action = "workspace.open"
        let risk = workspaceActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let handler = workspaceOpenHandler(for: target.url)
        let activeBefore = activeAppRecord()

        return WorkspaceOpenPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            action: action,
            risk: risk,
            actionMutates: true,
            policy: policy,
            target: target.summary,
            handler: handler,
            activeBefore: activeBefore,
            canExecute: policy.allowed,
            requiredAllowRisk: risk,
            message: policy.allowed
                ? "Workspace open preflight passed for \(workspaceOpenTargetDisplayName(target.summary))\(handler.map { " with default handler \($0.name ?? $0.bundleIdentifier ?? $0.path)" } ?? "")."
                : "Workspace open preflight did not pass for \(workspaceOpenTargetDisplayName(target.summary))."
        )
    }

    func openWorkspaceTarget() throws -> WorkspaceOpenResult {
        let target = try workspaceOpenTargetForCommand()
        let action = "workspace.open"
        let risk = workspaceActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let handler = workspaceOpenHandler(for: target.url)
        let activeBefore = activeAppRecord()
        var activeAfter = activeBefore
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "open",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                workspaceOpenTarget: target.summary,
                workspaceOpenHandler: handler,
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

            let accepted = NSWorkspace.shared.open(target.url)
            Thread.sleep(forTimeInterval: 0.15)
            activeAfter = activeAppRecord()
            verification = workspaceOpenVerification(accepted: accepted)

            guard verification?.ok == true else {
                let message = verification?.message ?? "workspace open verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Opened \(workspaceOpenTargetDisplayName(target.summary)) through the default workspace handler."
            try writeAudit(ok: true, code: "opened", message: message)

            return WorkspaceOpenResult(
                ok: true,
                action: action,
                risk: risk,
                target: target.summary,
                handler: handler,
                activeBefore: activeBefore,
                activeAfter: activeAfter,
                verification: verification!,
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

    func appActiveWaitState() throws -> AppActiveWaitResult {
        let target = appRecord(for: try targetRunningApplicationForAppCommand())
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = waitForActiveApp(
            target: target,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return AppActiveWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Frontmost app matched the expected target."
                : "Timed out waiting for frontmost app target."
        )
    }

}
