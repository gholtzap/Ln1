import AppKit
import ApplicationServices
import CryptoKit
import Darwin
import Foundation

let args = Array(CommandLine.arguments.dropFirst())

do {
    let cli = Ln1CLI(arguments: args)
    try cli.run()
} catch let error as CommandError {
    fputs("Ln1: \(error.description)\n", stderr)
    exit(1)
} catch {
    fputs("Ln1: \(error)\n", stderr)
    exit(1)
}

final class Ln1CLI {
    let arguments: [String]
    private let encoder: JSONEncoder

    init(arguments: [String]) {
        self.arguments = arguments
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func run() throws {
        guard let command = arguments.first else {
            printHelp()
            return
        }

        switch command {
        case "trust":
            try trust()
        case "doctor":
            try doctor()
        case "policy":
            try policy()
        case "system":
            try system()
        case "benchmarks":
            try benchmarks()
        case "observe":
            try observe()
        case "workflow":
            try workflow()
        case "open":
            try openWorkspace()
        case "apps":
            try apps()
        case "processes":
            try processes()
        case "desktop":
            try desktop()
        case "input":
            try input()
        case "state":
            try state()
        case "perform":
            try perform()
        case "set-value":
            try setAccessibilityValue()
        case "audit":
            try audit()
        case "task":
            try task()
        case "files":
            try files()
        case "clipboard":
            try clipboard()
        case "browser":
            try browser()
        case "schema":
            schema()
        case "help", "--help", "-h":
            printHelp()
        default:
            throw CommandError(description: "unknown command '\(command)'")
        }
    }

    private func desktop() throws {
        let mode = arguments.dropFirst().first ?? "windows"

        switch mode {
        case "displays":
            try writeJSON(desktopDisplays())
        case "active-window":
            try writeJSON(desktopActiveWindow())
        case "screenshot":
            try writeJSON(desktopScreenshot())
        case "minimize-active-window":
            try writeJSON(desktopMinimizeActiveWindow())
        case "restore-window":
            try writeJSON(desktopRestoreWindow())
        case "raise-window":
            try writeJSON(desktopRaiseWindow())
        case "set-window-frame":
            try writeJSON(desktopSetWindowFrame())
        case "wait-active-window":
            try writeJSON(desktopActiveWindowWaitState())
        case "wait-window":
            try writeJSON(desktopWindowWaitState())
        case "windows":
            try writeJSON(desktopWindows())
        default:
            throw CommandError(description: "unknown desktop mode '\(mode)'")
        }
    }

    private func desktopScreenshot() throws -> VisualSnapshotState {
        let action = "desktop.screenshot"
        let risk = desktopActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        guard policy.allowed else {
            throw CommandError(description: policy.message)
        }
        let displayID = option("--display-id").flatMap(UInt32.init)
        let maxSampleBytes = max(0, option("--max-sample-bytes").flatMap(Int.init) ?? 1_048_576)
        let includeOCR = try option("--include-ocr").map {
            try booleanOption($0, optionName: "--include-ocr")
        } ?? false
        let maxOCRCharacters = max(0, option("--max-ocr-characters").flatMap(Int.init) ?? 4_096)
        return desktopVisualSnapshot(
            targetDisplayID: displayID,
            maxSampleBytes: maxSampleBytes,
            includeOCR: includeOCR,
            maxOCRCharacters: maxOCRCharacters
        )
    }

    private func policy() throws {
        try writeJSON(PolicySnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            defaultAllowedRisk: "low",
            riskLevels: ["low", "medium", "high", "unknown"],
            actions: knownPolicyActions()
        ))
    }

    private func observe() throws {
        let appLimit = max(0, option("--app-limit").flatMap(Int.init) ?? 20)
        let windowLimit = max(0, option("--window-limit").flatMap(Int.init) ?? 20)
        let includeAllApps = flag("--all")
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let allApps = appSummaries(includeAll: includeAllApps, activePid: activePid)
        let limitedApps = Array(allApps.prefix(appLimit))
        let trusted = AXIsProcessTrusted()
        let accessibility = TrustRecord(
            trusted: trusted,
            message: trusted
                ? "Accessibility access is enabled."
                : "Grant Accessibility access to the terminal app running Ln1 before using state or perform."
        )
        let desktop = try desktopWindows(limitOverride: windowLimit)
        let blockers = observationBlockers(accessibility: accessibility, desktop: desktop)

        try writeJSON(ObservationSnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            accessibility: accessibility,
            activeApp: allApps.first(where: \.active),
            appLimit: appLimit,
            appCount: limitedApps.count,
            appsTruncated: allApps.count > limitedApps.count,
            apps: limitedApps,
            desktop: desktop,
            blockers: blockers,
            suggestedActions: observationSuggestedActions(
                accessibilityTrusted: trusted,
                activePid: activePid,
                windowLimit: windowLimit
            )
        ))
    }

    private func workflow() throws {
        let mode = arguments.dropFirst().first ?? "preflight"
        switch mode {
        case "preflight":
            try workflowPreflight()
        case "next":
            try workflowNext()
        case "run":
            try workflowRun()
        case "log":
            try workflowLog()
        case "resume":
            try workflowResume()
        default:
            throw CommandError(description: "unknown workflow mode '\(mode)'")
        }
    }

    private func workflowPreflight() throws {
        let result = try workflowPreflightForOperation()
        try writeJSON(result)
    }

    private func workflowNext() throws {
        let preflight = try workflowPreflightForOperation()
        let command: WorkflowCommand?
        if preflight.canProceed, let argv = preflight.nextArguments {
            command = WorkflowCommand(
                display: workflowDisplayCommand(argv),
                argv: argv,
                risk: preflight.risk,
                mutates: preflight.mutates,
                requiresReason: preflight.mutates
            )
        } else {
            command = nil
        }

        try writeJSON(WorkflowNextPlan(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: preflight.operation,
            ready: command != nil,
            risk: preflight.risk,
            mutates: preflight.mutates,
            blockers: preflight.blockers,
            command: command,
            preflight: preflight,
            message: command == nil
                ? "Workflow is blocked; run the remediation command from preflight before executing."
                : "Workflow is ready; execute the argv array directly or review the display command."
        ))
    }

    private func workflowRun() throws {
        let dryRun = option("--dry-run").map(parseBool) ?? true
        let timeoutMilliseconds = max(100, option("--run-timeout-ms").flatMap(Int.init) ?? 10_000)
        let maxOutputBytes = max(0, option("--max-output-bytes").flatMap(Int.init) ?? 1_048_576)
        let preflight = try workflowPreflightForOperation()
        var command: WorkflowCommand?
        if preflight.canProceed, let argv = preflight.nextArguments {
            command = WorkflowCommand(
                display: workflowDisplayCommand(argv),
                argv: argv,
                risk: preflight.risk,
                mutates: preflight.mutates,
                requiresReason: preflight.mutates
            )
        } else {
            command = nil
        }

        if !dryRun, command?.mutates == true {
            guard option("--execute-mutating").map(parseBool) == true else {
                throw CommandError(description: "workflow run mutating execution requires --execute-mutating true. Use `--dry-run true` to inspect the command first.")
            }
            let reason = try workflowExecutionReason()
            if let currentCommand = command {
                let argv = try workflowArguments(currentCommand.argv, replacingReasonWith: reason)
                command = WorkflowCommand(
                    display: workflowDisplayCommand(argv),
                    argv: argv,
                    risk: currentCommand.risk,
                    mutates: currentCommand.mutates,
                    requiresReason: currentCommand.requiresReason
                )
            }
        }

        let execution: WorkflowExecutionResult?
        if !dryRun, let command {
            execution = try workflowExecute(
                command,
                timeoutMilliseconds: timeoutMilliseconds,
                maxOutputBytes: maxOutputBytes
            )
        } else {
            execution = nil
        }
        let executed = execution != nil
        let transcriptURL = try workflowLogURL()
        let generatedAt = ISO8601DateFormatter().string(from: Date())

        let plan = WorkflowRunPlan(
            transcriptID: UUID().uuidString,
            transcriptPath: transcriptURL.path,
            generatedAt: generatedAt,
            platform: "macOS",
            operation: preflight.operation,
            mode: dryRun ? "dry-run" : "execute",
            dryRun: dryRun,
            ready: command != nil,
            wouldExecute: command != nil,
            executed: executed,
            risk: preflight.risk,
            mutates: preflight.mutates,
            blockers: preflight.blockers,
            command: command,
            execution: execution,
            preflight: preflight,
            message: workflowRunMessage(command: command, dryRun: dryRun, executed: executed)
        )
        try appendWorkflowTranscript(plan, to: transcriptURL)
        try writeJSON(plan)
    }

    private func workflowLog() throws {
        try requirePolicyAllowed(action: "workflow.logRead")
        let workflowURL = try workflowLogURL()
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 20)
        let operation = option("--operation")
        let entries = try readWorkflowTranscriptEntries(
            from: workflowURL,
            limit: limit,
            operation: operation
        )
        try writeJSON(WorkflowLogEntries(
            path: workflowURL.path,
            operation: operation,
            limit: limit,
            count: entries.count,
            entries: entries
        ))
    }

    private func workflowResume() throws {
        try requirePolicyAllowed(action: "workflow.logRead")
        let workflowURL = try workflowLogURL()
        let operation = option("--operation")
        let latest = try readWorkflowTranscriptDictionaries(
            from: workflowURL,
            limit: 1,
            operation: operation
        ).last
        let plan = try workflowResumePlan(
            latest: latest,
            workflowURL: workflowURL,
            operation: operation
        )
        try writeJSON(plan)
    }

    private func workflowPreflightForOperation() throws -> WorkflowPreflight {
        let operation = try requiredOption("--operation")
        switch operation {
        case "review-audit":
            return try workflowPreflightReviewAudit()
        case "inspect-active-app":
            return workflowPreflightInspectActiveApp()
        case "inspect-frontmost-app":
            return workflowPreflightInspectFrontmostApp()
        case "inspect-apps":
            return workflowPreflightInspectApps()
        case "inspect-installed-apps":
            return workflowPreflightInspectInstalledApps()
        case "inspect-menu":
            return workflowPreflightInspectMenu()
        case "inspect-system":
            return workflowPreflightInspectSystem()
        case "inspect-displays":
            return workflowPreflightInspectDisplays()
        case "inspect-active-window":
            return workflowPreflightInspectActiveWindow()
        case "inspect-windows":
            return workflowPreflightInspectWindows()
        case "inspect-processes":
            return workflowPreflightInspectProcesses()
        case "start-task":
            return try workflowPreflightStartTask()
        case "record-task":
            return try workflowPreflightRecordTask()
        case "finish-task":
            return try workflowPreflightFinishTask()
        case "show-task":
            return try workflowPreflightShowTask()
        case "inspect-process":
            return workflowPreflightInspectProcess()
        case "find-element":
            return workflowPreflightFindElement()
        case "inspect-element":
            return workflowPreflightInspectElement()
        case "wait-process":
            return workflowPreflightWaitProcess()
        case "wait-active-window":
            return workflowPreflightWaitActiveWindow()
        case "wait-window":
            return workflowPreflightWaitWindow()
        case "wait-element":
            return workflowPreflightWaitElement()
        case "wait-active-app":
            return workflowPreflightWaitActiveApp()
        case "minimize-active-window":
            return workflowPreflightMinimizeActiveWindow()
        case "restore-window":
            return workflowPreflightRestoreWindow()
        case "raise-window":
            return workflowPreflightRaiseWindow()
        case "set-window-frame":
            return workflowPreflightSetWindowFrame()
        case "activate-app":
            return try workflowPreflightActivateApp()
        case "launch-app":
            return try workflowPreflightLaunchApp()
        case "hide-app":
            return try workflowPreflightHideApp()
        case "unhide-app":
            return try workflowPreflightUnhideApp()
        case "quit-app":
            return try workflowPreflightQuitApp()
        case "open-file":
            return try workflowPreflightOpenFile()
        case "open-url":
            return try workflowPreflightOpenURL()
        case "control-active-app":
            return workflowPreflightControlActiveApp()
        case "set-element-value":
            return workflowPreflightSetElementValue()
        case "read-browser":
            return workflowPreflightReadBrowser()
        case "fill-browser":
            return workflowPreflightBrowserAction(kind: "fill")
        case "select-browser":
            return workflowPreflightBrowserAction(kind: "select")
        case "check-browser":
            return workflowPreflightBrowserAction(kind: "check")
        case "focus-browser":
            return workflowPreflightBrowserAction(kind: "focus")
        case "press-browser-key":
            return workflowPreflightBrowserAction(kind: "press-key")
        case "click-browser":
            return workflowPreflightBrowserAction(kind: "click")
        case "navigate-browser":
            return workflowPreflightBrowserAction(kind: "navigate")
        case "wait-browser-url":
            return workflowPreflightWaitBrowserURL()
        case "wait-browser-selector":
            return workflowPreflightWaitBrowserSelector()
        case "wait-browser-count":
            return workflowPreflightWaitBrowserCount()
        case "wait-browser-text":
            return workflowPreflightWaitBrowserText()
        case "wait-browser-element-text":
            return workflowPreflightWaitBrowserElementText()
        case "wait-browser-value":
            return workflowPreflightWaitBrowserValue()
        case "wait-browser-ready":
            return workflowPreflightWaitBrowserReady()
        case "wait-browser-title":
            return workflowPreflightWaitBrowserTitle()
        case "wait-browser-checked":
            return workflowPreflightWaitBrowserChecked()
        case "wait-browser-enabled":
            return workflowPreflightWaitBrowserEnabled()
        case "wait-browser-focus":
            return workflowPreflightWaitBrowserFocus()
        case "wait-browser-attribute":
            return workflowPreflightWaitBrowserAttribute()
        case "wait-clipboard":
            return workflowPreflightWaitClipboard()
        case "inspect-clipboard":
            return workflowPreflightInspectClipboard()
        case "read-clipboard":
            return workflowPreflightReadClipboard()
        case "write-clipboard":
            return workflowPreflightWriteClipboard()
        case "inspect-file":
            return workflowPreflightInspectFile()
        case "read-file":
            return workflowPreflightReadFile()
        case "tail-file":
            return workflowPreflightTailFile()
        case "read-file-lines":
            return workflowPreflightReadFileLines()
        case "read-file-json":
            return workflowPreflightReadFileJSON()
        case "read-file-plist":
            return workflowPreflightReadFilePropertyList()
        case "write-file":
            return try workflowPreflightWriteFile()
        case "append-file":
            return try workflowPreflightAppendFile()
        case "list-files":
            return workflowPreflightListFiles()
        case "search-files":
            return workflowPreflightSearchFiles()
        case "create-directory":
            return try workflowPreflightCreateDirectory()
        case "duplicate-file":
            return try workflowPreflightDuplicateFile()
        case "move-file":
            return try workflowPreflightMoveFile()
        case "rollback-file-move":
            return try workflowPreflightRollbackFileMove()
        case "checksum-file":
            return workflowPreflightChecksumFile()
        case "compare-files":
            return workflowPreflightCompareFiles()
        case "watch-file":
            return workflowPreflightWatchFile()
        case "wait-file":
            return workflowPreflightWaitFile()
        default:
            throw CommandError(description: "unsupported workflow operation '\(operation)'. Use review-audit, inspect-active-app, inspect-frontmost-app, inspect-apps, inspect-installed-apps, inspect-menu, inspect-system, inspect-displays, inspect-active-window, inspect-windows, inspect-processes, start-task, record-task, finish-task, show-task, inspect-process, find-element, inspect-element, wait-process, wait-active-window, wait-window, wait-element, wait-active-app, minimize-active-window, restore-window, raise-window, set-window-frame, activate-app, launch-app, hide-app, unhide-app, quit-app, open-file, open-url, control-active-app, set-element-value, read-browser, fill-browser, select-browser, check-browser, focus-browser, press-browser-key, click-browser, navigate-browser, wait-browser-url, wait-browser-selector, wait-browser-count, wait-browser-text, wait-browser-element-text, wait-browser-value, wait-browser-ready, wait-browser-title, wait-browser-checked, wait-browser-enabled, wait-browser-focus, wait-browser-attribute, wait-clipboard, inspect-clipboard, read-clipboard, write-clipboard, inspect-file, read-file, tail-file, read-file-lines, read-file-json, read-file-plist, write-file, append-file, list-files, search-files, create-directory, duplicate-file, move-file, rollback-file-move, checksum-file, compare-files, watch-file, or wait-file.")
        }
    }

    private func workflowPreflightReviewAudit() throws -> WorkflowPreflight {
        let auditURL = try auditLogURL()
        let fileManager = FileManager.default
        let prerequisites: [DoctorCheck]
        if fileManager.fileExists(atPath: auditURL.path) {
            let readable = fileManager.isReadableFile(atPath: auditURL.path)
            prerequisites = [
                DoctorCheck(
                    name: "workflow.auditLogReadability",
                    status: readable ? "pass" : "fail",
                    required: true,
                    message: readable
                        ? "Audit log is readable at \(auditURL.path)."
                        : "Audit log is not readable at \(auditURL.path).",
                    remediation: readable ? nil : "Pass `--audit-log` with a readable audit log path."
                )
            ]
        } else {
            prerequisites = [
                DoctorCheck(
                    name: "workflow.auditLogReadability",
                    status: "warn",
                    required: false,
                    message: "Audit log does not exist at \(auditURL.path); review-audit will return an empty entry list.",
                    remediation: nil
                )
            ]
        }

        let blockers = workflowBlockers(from: prerequisites)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? (option("--id") == nil ? 20 : 1))
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "audit",
                "--limit", String(limit)
            ]
            if let id = option("--id") {
                arguments += ["--id", id]
            }
            if let command = option("--command") {
                arguments += ["--command", command]
            }
            if let code = option("--code") {
                arguments += ["--code", code]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "review-audit",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectSystem() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-system",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 system context",
            nextArguments: ["Ln1", "system", "context"]
        )
    }

    private func workflowPreflightInspectDisplays() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-displays",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 desktop displays",
            nextArguments: ["Ln1", "desktop", "displays"]
        )
    }

    private func workflowPreflightInspectActiveWindow() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-active-window",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 desktop active-window",
            nextArguments: ["Ln1", "desktop", "active-window"]
        )
    }

    private func workflowPreflightInspectWindows() -> WorkflowPreflight {
        var arguments = ["Ln1", "desktop", "windows"]
        if let limit = option("--limit") {
            arguments += ["--limit", limit]
        }
        if let id = option("--id") {
            arguments += ["--id", id]
        }
        if let ownerPID = option("--owner-pid") {
            arguments += ["--owner-pid", ownerPID]
        }
        if let bundleIdentifier = option("--bundle-id") {
            arguments += ["--bundle-id", bundleIdentifier]
        }
        if let title = option("--title") {
            arguments += ["--title", title]
        }
        if let match = option("--match") {
            arguments += ["--match", match]
        }
        if flag("--include-desktop") {
            arguments.append("--include-desktop")
        }
        if flag("--all-layers") {
            arguments.append("--all-layers")
        }

        return workflowPreflightResult(
            operation: "inspect-windows",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightInspectProcesses() -> WorkflowPreflight {
        var arguments = ["Ln1", "processes", "list"]
        if let limit = option("--limit") {
            arguments += ["--limit", limit]
        }
        if let name = option("--name") {
            arguments += ["--name", name]
        }

        return workflowPreflightResult(
            operation: "inspect-processes",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightStartTask() throws -> WorkflowPreflight {
        var prerequisites = [workflowPolicyCheck(risk: "medium")]
        let title = option("--title")
        if title == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskTitle",
                status: "fail",
                required: true,
                message: "No task title was provided for start-task.",
                remediation: "Pass `--title TEXT` for the task memory record."
            ))
        }
        workflowAppendTaskSensitivityCheck(to: &prerequisites)

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let title {
            var arguments = [
                "Ln1", "task", "start",
                "--title", title,
                "--allow-risk", "medium"
            ]
            workflowAppendTaskCommonArguments(to: &arguments, includeTaskID: true, includeSummary: true)
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "start-task",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightRecordTask() throws -> WorkflowPreflight {
        var prerequisites = [workflowPolicyCheck(risk: "medium")]
        let taskID = workflowValidateTaskID(operation: "record-task", prerequisites: &prerequisites)
        let kind = option("--kind")
        if let kind {
            do {
                _ = try taskMemoryKind(kind)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.taskKind",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--kind observation`, `decision`, `action`, `verification`, or `note`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskKind",
                status: "fail",
                required: true,
                message: "No task event kind was provided for record-task.",
                remediation: "Pass `--kind observation`, `decision`, `action`, `verification`, or `note`."
            ))
        }
        let summary = option("--summary")
        if summary == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskSummary",
                status: "fail",
                required: true,
                message: "No task summary was provided for record-task.",
                remediation: "Pass `--summary TEXT` for the task memory event."
            ))
        }
        try workflowAppendTaskExistsCheck(taskID: taskID, prerequisites: &prerequisites)
        workflowAppendTaskSensitivityCheck(to: &prerequisites)

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let taskID, let kind, let summary {
            var arguments = [
                "Ln1", "task", "record",
                "--task-id", taskID,
                "--kind", kind,
                "--summary", summary,
                "--allow-risk", "medium"
            ]
            workflowAppendTaskCommonArguments(to: &arguments, includeTaskID: false, includeSummary: false)
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "record-task",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightFinishTask() throws -> WorkflowPreflight {
        var prerequisites = [workflowPolicyCheck(risk: "medium")]
        let taskID = workflowValidateTaskID(operation: "finish-task", prerequisites: &prerequisites)
        let status = option("--status")
        if let status {
            do {
                _ = try taskFinishStatus(status)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.taskStatus",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--status completed`, `blocked`, or `cancelled`."
                ))
            }
        }
        try workflowAppendTaskExistsCheck(taskID: taskID, prerequisites: &prerequisites)
        workflowAppendTaskSensitivityCheck(to: &prerequisites)

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let taskID {
            var arguments = [
                "Ln1", "task", "finish",
                "--task-id", taskID,
                "--status", status ?? "completed",
                "--allow-risk", "medium"
            ]
            workflowAppendTaskCommonArguments(to: &arguments, includeTaskID: false, includeSummary: true)
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "finish-task",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightShowTask() throws -> WorkflowPreflight {
        var prerequisites = [workflowPolicyCheck(risk: "medium")]
        let taskID = workflowValidateTaskID(operation: "show-task", prerequisites: &prerequisites)
        var limit = 50
        if let rawLimit = option("--limit") {
            if let parsed = Int(rawLimit) {
                limit = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.taskLimit",
                    status: "fail",
                    required: true,
                    message: "--limit must be an integer.",
                    remediation: "Pass a non-negative integer with `--limit N`."
                ))
            }
        }
        try workflowAppendTaskExistsCheck(taskID: taskID, prerequisites: &prerequisites)

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let taskID {
            var arguments = [
                "Ln1", "task", "show",
                "--task-id", taskID,
                "--allow-risk", "medium",
                "--limit", String(limit)
            ]
            if let memoryLog = option("--memory-log") {
                arguments += ["--memory-log", memoryLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "show-task",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPolicyCheck(risk: String) -> DoctorCheck {
        let policy = policyDecision(actionRisk: risk)
        return DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk \(risk)` after reviewing the workflow target."
        )
    }

    private func workflowValidateTaskID(
        operation: String,
        prerequisites: inout [DoctorCheck]
    ) -> String? {
        guard let taskID = option("--task-id") else {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskID",
                status: "fail",
                required: true,
                message: "No task ID was provided for \(operation).",
                remediation: "Pass `--task-id ID` from `Ln1 task start` or a previous workflow transcript."
            ))
            return nil
        }
        return taskID
    }

    private func workflowAppendTaskExistsCheck(
        taskID: String?,
        prerequisites: inout [DoctorCheck]
    ) throws {
        guard let taskID else {
            return
        }
        let memoryURL = try taskMemoryURL()
        do {
            try requireTaskExists(taskID: taskID, in: memoryURL)
            prerequisites.append(DoctorCheck(
                name: "workflow.taskMemory",
                status: "pass",
                required: true,
                message: "Task memory exists for id \(taskID).",
                remediation: nil
            ))
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskMemory",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Run `Ln1 workflow run --operation start-task --dry-run false --execute-mutating true --reason TEXT` first, or pass the correct `--memory-log`."
            ))
        }
    }

    private func workflowAppendTaskSensitivityCheck(to prerequisites: inout [DoctorCheck]) {
        guard let sensitivity = option("--sensitivity") else {
            return
        }
        do {
            _ = try taskMemorySensitivity(sensitivity)
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.taskSensitivity",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Use `--sensitivity public`, `private`, or `sensitive`."
            ))
        }
    }

    private func workflowAppendTaskCommonArguments(
        to arguments: inout [String],
        includeTaskID: Bool,
        includeSummary: Bool
    ) {
        if includeTaskID, let taskID = option("--task-id") {
            arguments += ["--task-id", taskID]
        }
        if includeSummary, let summary = option("--summary") {
            arguments += ["--summary", summary]
        }
        if let sensitivity = option("--sensitivity") {
            arguments += ["--sensitivity", sensitivity]
        }
        if let relatedAuditID = option("--related-audit-id") {
            arguments += ["--related-audit-id", relatedAuditID]
        }
        if let memoryLog = option("--memory-log") {
            arguments += ["--memory-log", memoryLog]
        }
    }

    private func workflowPreflightInspectInstalledApps() -> WorkflowPreflight {
        var arguments = ["Ln1", "apps", "installed"]
        if let limit = option("--limit") {
            arguments += ["--limit", limit]
        }
        if let name = option("--name") {
            arguments += ["--name", name]
        }
        if let bundleIdentifier = option("--bundle-id") {
            arguments += ["--bundle-id", bundleIdentifier]
        }

        return workflowPreflightResult(
            operation: "inspect-installed-apps",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightInspectApps() -> WorkflowPreflight {
        var arguments = ["Ln1", "apps", "list"]
        if let limit = option("--limit") {
            arguments += ["--limit", limit]
        }
        if flag("--all") {
            arguments.append("--all")
        }

        return workflowPreflightResult(
            operation: "inspect-apps",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightInspectFrontmostApp() -> WorkflowPreflight {
        workflowPreflightResult(
            operation: "inspect-frontmost-app",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: "Ln1 apps active",
            nextArguments: ["Ln1", "apps", "active"]
        )
    }

    private func workflowPreflightInspectActiveApp() -> WorkflowPreflight {
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let prerequisites = [
            doctorAccessibilityCheck(),
            doctorDesktopMetadataCheck()
        ]
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = ["Ln1", "state"]
            if let activePid {
                arguments += ["--pid", String(activePid)]
            }
            arguments += ["--depth", "3", "--max-children", "80"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }
        let nextCommand = nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites)
        return workflowPreflightResult(
            operation: "inspect-active-app",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectMenu() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let targetPID: pid_t?
        if let pid = option("--pid") {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                targetPID = processIdentifier
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for inspect-menu.",
                    remediation: nil
                ))
            } else {
                targetPID = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        } else if let frontmost = NSWorkspace.shared.frontmostApplication {
            targetPID = frontmost.processIdentifier
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "pass",
                required: true,
                message: "The frontmost app was selected for inspect-menu.",
                remediation: nil
            ))
        } else {
            targetPID = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No frontmost app target was available for inspect-menu.",
                remediation: "Pass `--pid PID` from `Ln1 apps`."
            ))
        }

        let depth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetPID {
            nextArguments = [
                "Ln1", "state", "menu",
                "--pid", String(targetPID),
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-menu",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectProcess() -> WorkflowPreflight {
        let targetArguments: [String]?
        var prerequisites: [DoctorCheck] = []

        if flag("--current") {
            targetArguments = ["--current"]
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "pass",
                required: true,
                message: "Current Ln1 process was selected for inspection.",
                remediation: nil
            ))
        } else if let rawPID = option("--pid"), let pid = pid_t(rawPID), pid > 0 {
            targetArguments = ["--pid", rawPID]
            let found = processRecord(for: pid) != nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: found ? "pass" : "fail",
                required: true,
                message: found
                    ? "Process metadata is available for pid \(pid)."
                    : "No running process metadata was available for pid \(pid).",
                remediation: found ? nil : "Run `Ln1 processes --limit 50` and choose a current pid."
            ))
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "fail",
                required: true,
                message: "No process target was provided for inspect-process.",
                remediation: "Pass `--pid PID` from `Ln1 processes` or use `--current`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        let nextCommand: String?
        if blockers.isEmpty, let targetArguments {
            let arguments = ["Ln1", "processes", "inspect"] + targetArguments
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "inspect-process",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightFindElement() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let pid = option("--pid")

        if let pid {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for find-element.",
                    remediation: nil
                ))
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        } else if NSWorkspace.shared.frontmostApplication != nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "pass",
                required: true,
                message: "The frontmost app was selected for find-element.",
                remediation: nil
            ))
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No frontmost app target was available for find-element.",
                remediation: "Pass `--pid PID` from `Ln1 apps`."
            ))
        }

        let match = option("--match") ?? "contains"
        if !["exact", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.elementQuery",
                status: "fail",
                required: true,
                message: "Element query match mode must be exact or contains.",
                remediation: "Pass `--match exact` or `--match contains`."
            ))
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.elementQuery",
                status: "pass",
                required: false,
                message: "Element query filters are syntactically valid.",
                remediation: nil
            ))
        }

        if let enabled = option("--enabled") {
            do {
                _ = try booleanOption(enabled, optionName: "--enabled")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.elementQuery",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass `--enabled true` or `--enabled false`."
                ))
            }
        }

        let depth = max(0, option("--depth").flatMap(Int.init) ?? 4)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 80)
        let resultDepth = max(0, option("--result-depth").flatMap(Int.init) ?? 0)
        let resultMaxChildren = max(0, option("--result-max-children").flatMap(Int.init) ?? 20)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 20)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = ["Ln1", "state", "find"]
            if let pid {
                arguments += ["--pid", pid]
            }
            for optionName in ["--role", "--subrole", "--title", "--value", "--help-text", "--action", "--enabled"] {
                if let value = option(optionName) {
                    arguments += [optionName, value]
                }
            }
            arguments += [
                "--match", match,
                "--depth", String(depth),
                "--max-children", String(maxChildren),
                "--result-depth", String(resultDepth),
                "--result-max-children", String(resultMaxChildren),
                "--limit", String(limit)
            ]
            if flag("--include-menu") {
                arguments.append("--include-menu")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "find-element",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectElement() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let element = option("--element")
        let pid = option("--pid")

        if let element {
            do {
                _ = try normalizedElementID(element)
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "pass",
                    required: true,
                    message: "An Accessibility element path is available for inspect-element.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass an element ID like `w0.1.2`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No Accessibility element path was provided for inspect-element.",
                remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass `--element ID`."
            ))
        }

        if let pid {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for inspect-element.",
                    remediation: nil
                ))
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        }

        if let minimumConfidence = option("--min-identity-confidence"),
           identityConfidenceRank(minimumConfidence) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.identityConfidence",
                status: "fail",
                required: true,
                message: "Invalid minimum stable identity confidence '\(minimumConfidence)'.",
                remediation: "Use `--min-identity-confidence low`, `medium`, or `high`."
            ))
        }

        let depth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["Ln1", "state", "element"]
            if let pid {
                arguments += ["--pid", pid]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            arguments += [
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-element",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitProcess() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let rawPID = option("--pid")
        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)

        if let rawPID, let pid = pid_t(rawPID), pid > 0 {
            let found = processRecord(for: pid) != nil
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "pass",
                required: true,
                message: found
                    ? "Process metadata is currently available for pid \(pid)."
                    : "Process metadata is not currently available for pid \(pid); wait-process can wait for this state to change.",
                remediation: nil
            ))
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.processTarget",
                status: "fail",
                required: true,
                message: "No process pid was provided for wait-process.",
                remediation: "Pass `--pid PID` from `Ln1 processes`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let rawPID {
            nextArguments = [
                "Ln1", "processes", "wait",
                "--pid", rawPID,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-process",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitActiveWindow() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        var targetArguments: [String] = []
        if let id = option("--id") {
            targetArguments += ["--id", id]
        }
        if let ownerPID = option("--owner-pid") {
            if Int32(ownerPID).map({ $0 > 0 }) == true {
                targetArguments += ["--owner-pid", ownerPID]
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.activeWindowTarget",
                    status: "fail",
                    required: true,
                    message: "Active window owner pid must be a positive integer.",
                    remediation: "Pass `--owner-pid PID` from `Ln1 desktop active-window`."
                ))
            }
        }
        if let bundleIdentifier = option("--bundle-id") {
            targetArguments += ["--bundle-id", bundleIdentifier]
        }
        if let title = option("--title") {
            targetArguments += ["--title", title]
        }
        if let changedFrom = option("--changed-from") {
            targetArguments += ["--changed-from", changedFrom]
        }

        if prerequisites.isEmpty {
            prerequisites.append(DoctorCheck(
                name: "workflow.activeWindowTarget",
                status: "pass",
                required: false,
                message: targetArguments.isEmpty
                    ? "No active window target filter was provided; wait-active-window will wait for any frontmost visible window."
                    : "An active window target filter is available for wait-active-window.",
                remediation: nil
            ))
        }

        let match = option("--match") ?? "contains"
        if !["exact", "prefix", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.activeWindowMatch",
                status: "fail",
                required: true,
                message: "Active window title match mode must be exact, prefix, or contains.",
                remediation: "Pass `--match exact`, `--match prefix`, or `--match contains`."
            ))
        }

        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            nextArguments = [
                "Ln1", "desktop", "wait-active-window"
            ] + targetArguments + [
                "--match", match,
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-active-window",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitWindow() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        var targetArguments: [String] = []
        if let id = option("--id") {
            targetArguments += ["--id", id]
        }
        if let ownerPID = option("--owner-pid") {
            if Int32(ownerPID).map({ $0 > 0 }) == true {
                targetArguments += ["--owner-pid", ownerPID]
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowTarget",
                    status: "fail",
                    required: true,
                    message: "Window owner pid must be a positive integer.",
                    remediation: "Pass `--owner-pid PID` from `Ln1 desktop windows`."
                ))
            }
        }
        if let bundleIdentifier = option("--bundle-id") {
            targetArguments += ["--bundle-id", bundleIdentifier]
        }
        if let title = option("--title") {
            targetArguments += ["--title", title]
        }

        if targetArguments.isEmpty && prerequisites.isEmpty {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowTarget",
                status: "fail",
                required: true,
                message: "No desktop window target was provided for wait-window.",
                remediation: "Pass `--id ID`, `--owner-pid PID`, `--bundle-id BUNDLE_ID`, or `--title TEXT` from `Ln1 desktop windows`."
            ))
        } else if prerequisites.isEmpty {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowTarget",
                status: "pass",
                required: true,
                message: "A desktop window target filter is available for wait-window.",
                remediation: nil
            ))
        }

        let match = option("--match") ?? "contains"
        if !["exact", "prefix", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowMatch",
                status: "fail",
                required: true,
                message: "Window title match mode must be exact, prefix, or contains.",
                remediation: "Pass `--match exact`, `--match prefix`, or `--match contains`."
            ))
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let limit = max(1, option("--limit").flatMap(Int.init) ?? 200)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "desktop", "wait-window"
            ] + targetArguments + [
                "--match", match,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--limit", String(limit)
            ]
            if flag("--include-desktop") {
                arguments.append("--include-desktop")
            }
            if flag("--all-layers") {
                arguments.append("--all-layers")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-window",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitElement() -> WorkflowPreflight {
        var prerequisites = [doctorAccessibilityCheck()]
        let element = option("--element")
        let match = option("--match") ?? "contains"
        let pid = option("--pid")

        if let element {
            do {
                _ = try normalizedElementID(element)
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "pass",
                    required: true,
                    message: "An Accessibility element path is available for wait-element.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass an element ID like `w0.1.2`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No Accessibility element path was provided for wait-element.",
                remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass `--element ID`."
            ))
        }

        if let pid {
            if let processIdentifier = pid_t(pid),
               NSRunningApplication(processIdentifier: processIdentifier) != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for wait-element.",
                    remediation: nil
                ))
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: "No running app was found for pid \(pid).",
                    remediation: "Run `Ln1 apps` and choose a running GUI app pid."
                ))
            }
        }

        if !["exact", "contains"].contains(match) {
            prerequisites.append(DoctorCheck(
                name: "workflow.elementMatch",
                status: "fail",
                required: true,
                message: "Accessibility element text match mode must be exact or contains.",
                remediation: "Use `--match exact` or `--match contains`."
            ))
        }

        if let minimumConfidence = option("--min-identity-confidence"),
           identityConfidenceRank(minimumConfidence) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.identityConfidence",
                status: "fail",
                required: true,
                message: "Invalid minimum stable identity confidence '\(minimumConfidence)'.",
                remediation: "Use `--min-identity-confidence low`, `medium`, or `high`."
            ))
        }

        if let enabled = option("--enabled") {
            do {
                _ = try booleanOption(enabled, optionName: "--enabled")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.elementEnabled",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--enabled true` or `--enabled false`."
                ))
            }
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let depth = max(0, option("--depth").flatMap(Int.init) ?? 0)
        let maxChildren = max(0, option("--max-children").flatMap(Int.init) ?? 20)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["Ln1", "state", "wait-element"]
            if let pid {
                arguments += ["--pid", pid]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            if let title = option("--title") {
                arguments += ["--title", title]
            }
            if let value = option("--value") {
                arguments += ["--value", value]
            }
            arguments += [
                "--match", match,
                "--exists", String(expectedExists)
            ]
            if let enabled = option("--enabled") {
                arguments += ["--enabled", enabled]
            }
            arguments += [
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--depth", String(depth),
                "--max-children", String(maxChildren)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-element",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitActiveApp() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for wait-active-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                _ = try targetRunningApplicationForAppCommand()
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for wait-active-app.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments {
            nextArguments = [
                "Ln1", "apps", "wait-active"
            ] + targetArguments + [
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-active-app",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightMinimizeActiveWindow() -> WorkflowPreflight {
        let action = "desktop.minimizeActiveWindow"
        let risk = desktopActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        do {
            let state = try desktopActiveWindow()
            prerequisites.append(DoctorCheck(
                name: "workflow.activeWindow",
                status: state.found ? "pass" : "fail",
                required: true,
                message: state.found
                    ? "A frontmost visible desktop window is available for minimize-active-window."
                    : state.message,
                remediation: state.found ? nil : "Bring a regular app window to the front, then retry."
            ))
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.activeWindow",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Run `Ln1 desktop active-window` and bring a regular app window to the front."
            ))
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the active window target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "desktop", "minimize-active-window",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "minimize-active-window",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightRestoreWindow() -> WorkflowPreflight {
        let action = "desktop.restoreWindow"
        let risk = desktopActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for restore-window.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current` with a window element ID."
            ))
        }

        let element = option("--element")
        if let element {
            do {
                let normalized = try normalizedElementID(element)
                if normalized.first == "w" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "pass",
                        required: true,
                        message: "A window element path is available for restore-window.",
                        remediation: nil
                    ))
                } else {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "fail",
                        required: true,
                        message: "restore-window requires an Accessibility window element path.",
                        remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowElement",
                status: "fail",
                required: true,
                message: "No window element was provided for restore-window.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--element wN`."
            ))
        }

        if targetArguments != nil, let element, AXIsProcessTrusted() {
            do {
                let app = try targetRunningApplicationForAppCommand()
                let normalized = try normalizedElementID(element)
                let axElement = try resolveElement(id: normalized, in: app.processIdentifier)
                let role = stringAttribute(axElement, kAXRoleAttribute)
                let writableAttributes = settableAttributes(axElement)
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowRole",
                    status: role == (kAXWindowRole as String) ? "pass" : "fail",
                    required: true,
                    message: role == (kAXWindowRole as String)
                        ? "The target element is an Accessibility window."
                        : "The target element role is \(role ?? "unavailable"), not AXWindow.",
                    remediation: role == (kAXWindowRole as String) ? nil : "Choose a window element such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowMinimizedSettable",
                    status: writableAttributes.contains(kAXMinimizedAttribute as String) ? "pass" : "fail",
                    required: true,
                    message: writableAttributes.contains(kAXMinimizedAttribute as String)
                        ? "The target window exposes settable AXMinimized."
                        : "The target window does not expose settable AXMinimized.",
                    remediation: writableAttributes.contains(kAXMinimizedAttribute as String) ? nil : "Choose a restorable Accessibility window that exposes AXMinimized."
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 0 --max-children 0` for the target app and choose a current window element."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the restore-window target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments, let element {
            var arguments = ["Ln1", "desktop", "restore-window"] + targetArguments
            arguments += [
                "--element", element,
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "restore-window",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightRaiseWindow() -> WorkflowPreflight {
        let action = "desktop.raiseWindow"
        let risk = desktopActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for raise-window.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current` with a window element ID."
            ))
        }

        let element = option("--element")
        if let element {
            do {
                let normalized = try normalizedElementID(element)
                if normalized.first == "w" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "pass",
                        required: true,
                        message: "A window element path is available for raise-window.",
                        remediation: nil
                    ))
                } else {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "fail",
                        required: true,
                        message: "raise-window requires an Accessibility window element path.",
                        remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowElement",
                status: "fail",
                required: true,
                message: "No window element was provided for raise-window.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--element wN`."
            ))
        }

        if targetArguments != nil, let element, AXIsProcessTrusted() {
            do {
                let app = try targetRunningApplicationForAppCommand()
                let normalized = try normalizedElementID(element)
                let axElement = try resolveElement(id: normalized, in: app.processIdentifier)
                let role = stringAttribute(axElement, kAXRoleAttribute)
                let actions = actionNames(axElement)
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowRole",
                    status: role == (kAXWindowRole as String) ? "pass" : "fail",
                    required: true,
                    message: role == (kAXWindowRole as String)
                        ? "The target element is an Accessibility window."
                        : "The target element role is \(role ?? "unavailable"), not AXWindow.",
                    remediation: role == (kAXWindowRole as String) ? nil : "Choose a window element such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowRaiseAction",
                    status: actions.contains(kAXRaiseAction as String) ? "pass" : "fail",
                    required: true,
                    message: actions.contains(kAXRaiseAction as String)
                        ? "The target window exposes AXRaise."
                        : "The target window does not expose AXRaise.",
                    remediation: actions.contains(kAXRaiseAction as String) ? nil : "Choose a raisable Accessibility window that exposes AXRaise."
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 0 --max-children 0` for the target app and choose a current window element."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the raise-window target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments, let element {
            var arguments = ["Ln1", "desktop", "raise-window"] + targetArguments
            arguments += [
                "--element", element,
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "raise-window",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightSetWindowFrame() -> WorkflowPreflight {
        let action = "desktop.setWindowFrame"
        let risk = desktopActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for set-window-frame.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current` with a window element ID."
            ))
        }

        let element = option("--element")
        if let element {
            do {
                let normalized = try normalizedElementID(element)
                if normalized.first == "w" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "pass",
                        required: true,
                        message: "A window element path is available for set-window-frame.",
                        remediation: nil
                    ))
                } else {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.windowElement",
                        status: "fail",
                        required: true,
                        message: "set-window-frame requires an Accessibility window element path.",
                        remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a window element ID such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.windowElement",
                status: "fail",
                required: true,
                message: "No window element was provided for set-window-frame.",
                remediation: "Run `Ln1 state --depth 0 --max-children 0` and pass `--element wN`."
            ))
        }

        let requestedFrame: Rect?
        do {
            requestedFrame = try requestedWindowFrame()
            prerequisites.append(DoctorCheck(
                name: "workflow.windowFrame",
                status: "pass",
                required: true,
                message: "A finite positive window frame was provided.",
                remediation: nil
            ))
        } catch {
            requestedFrame = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.windowFrame",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Pass finite `--x`, `--y`, `--width`, and `--height` values, with positive width and height."
            ))
        }

        if targetArguments != nil, let element, AXIsProcessTrusted() {
            do {
                let app = try targetRunningApplicationForAppCommand()
                let normalized = try normalizedElementID(element)
                let axElement = try resolveElement(id: normalized, in: app.processIdentifier)
                let role = stringAttribute(axElement, kAXRoleAttribute)
                let writableAttributes = settableAttributes(axElement)
                let frameAvailable = frame(axElement) != nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowRole",
                    status: role == (kAXWindowRole as String) ? "pass" : "fail",
                    required: true,
                    message: role == (kAXWindowRole as String)
                        ? "The target element is an Accessibility window."
                        : "The target element role is \(role ?? "unavailable"), not AXWindow.",
                    remediation: role == (kAXWindowRole as String) ? nil : "Choose a window element such as `w0` from `Ln1 state --depth 0 --max-children 0`."
                ))
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowPositionSettable",
                    status: writableAttributes.contains(kAXPositionAttribute as String) ? "pass" : "fail",
                    required: true,
                    message: writableAttributes.contains(kAXPositionAttribute as String)
                        ? "The target window exposes settable AXPosition."
                        : "The target window does not expose settable AXPosition.",
                    remediation: writableAttributes.contains(kAXPositionAttribute as String) ? nil : "Choose a movable Accessibility window that exposes AXPosition."
                ))
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowSizeSettable",
                    status: writableAttributes.contains(kAXSizeAttribute as String) ? "pass" : "fail",
                    required: true,
                    message: writableAttributes.contains(kAXSizeAttribute as String)
                        ? "The target window exposes settable AXSize."
                        : "The target window does not expose settable AXSize.",
                    remediation: writableAttributes.contains(kAXSizeAttribute as String) ? nil : "Choose a resizable Accessibility window that exposes AXSize."
                ))
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowFrameReadable",
                    status: frameAvailable ? "pass" : "fail",
                    required: true,
                    message: frameAvailable
                        ? "The target window frame can be read for verification."
                        : "The target window frame cannot be read for verification.",
                    remediation: frameAvailable ? nil : "Choose a window that exposes AXPosition and AXSize."
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.windowElement",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 0 --max-children 0` for the target app and choose a current window element."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the set-window-frame target and requested geometry."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments, let element, let requestedFrame {
            var arguments = ["Ln1", "desktop", "set-window-frame"] + targetArguments
            arguments += [
                "--element", element,
                "--x", String(requestedFrame.x),
                "--y", String(requestedFrame.y),
                "--width", String(requestedFrame.width),
                "--height", String(requestedFrame.height),
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            if let minimumConfidence = option("--min-identity-confidence") {
                arguments += ["--min-identity-confidence", minimumConfidence]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "set-window-frame",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightActivateApp() throws -> WorkflowPreflight {
        let action = "apps.activate"
        let risk = appActionRisk(for: action)
        var prerequisites = [
            doctorAuditLogCheck()
        ]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for activate-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                let target = try targetRunningApplicationForAppCommand()
                prerequisites += appActivationChecks(target: target).map { check in
                    DoctorCheck(
                        name: check.name,
                        status: check.ok ? "pass" : "fail",
                        required: true,
                        message: check.message,
                        remediation: check.ok ? nil : "Choose a running regular GUI app from `Ln1 apps`."
                    )
                }
            } catch {
                let message = (error as? CommandError)?.description ?? error.localizedDescription
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: message,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the app activation target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        let nextCommand: String?
        if blockers.isEmpty, let targetArguments {
            var arguments = ["Ln1", "apps", "activate"] + targetArguments
            arguments += [
                "--allow-risk", risk,
                "--audit-log", try auditLogURL().path,
                "--reason", "Describe intent"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "activate-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightLaunchApp() throws -> WorkflowPreflight {
        let action = "apps.launch"
        let risk = appActionRisk(for: action)
        let activate = option("--activate").map(parseBool) ?? true
        var prerequisites = [doctorAuditLogCheck()]

        let target: (url: URL, summary: AppLaunchTargetSummary)?
        do {
            target = try appLaunchTargetForAppCommand()
            prerequisites.append(DoctorCheck(
                name: "workflow.appLaunchTarget",
                status: "pass",
                required: true,
                message: "An installed app target is available for launch-app.",
                remediation: nil
            ))
        } catch {
            target = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appLaunchTarget",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Pass `--bundle-id BUNDLE_ID` for an installed app or `--path /Applications/App.app`."
            ))
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the app launch target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let target {
            var arguments = ["Ln1", "apps", "launch"]
            if let bundleIdentifier = option("--bundle-id") ?? target.summary.bundleIdentifier {
                arguments += ["--bundle-id", bundleIdentifier]
            } else {
                arguments += ["--path", target.summary.path]
            }
            arguments += [
                "--activate", String(activate),
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "launch-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightHideApp() throws -> WorkflowPreflight {
        let action = "apps.hide"
        let risk = appActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [doctorAuditLogCheck()]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for hide-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                let target = try targetRunningApplicationForAppCommand()
                prerequisites += appHideChecks(target: target).map { check in
                    DoctorCheck(
                        name: check.name,
                        status: check.ok ? "pass" : "fail",
                        required: true,
                        message: check.message,
                        remediation: check.ok ? nil : "Choose a running regular GUI app from `Ln1 apps`."
                    )
                }
            } catch {
                let message = (error as? CommandError)?.description ?? error.localizedDescription
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: message,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the app hide target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments {
            var arguments = ["Ln1", "apps", "hide"] + targetArguments
            arguments += [
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "hide-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightUnhideApp() throws -> WorkflowPreflight {
        let action = "apps.unhide"
        let risk = appActionRisk(for: action)
        let timeoutMilliseconds = max(0, option("--wait-timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [doctorAuditLogCheck()]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for unhide-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                let target = try targetRunningApplicationForAppCommand()
                prerequisites += appHideChecks(target: target).map { check in
                    DoctorCheck(
                        name: check.name,
                        status: check.ok ? "pass" : "fail",
                        required: true,
                        message: check.message,
                        remediation: check.ok ? nil : "Choose a running regular GUI app from `Ln1 apps`."
                    )
                }
            } catch {
                let message = (error as? CommandError)?.description ?? error.localizedDescription
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: message,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the app unhide target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments {
            var arguments = ["Ln1", "apps", "unhide"] + targetArguments
            arguments += [
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "unhide-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightQuitApp() throws -> WorkflowPreflight {
        let action = "apps.quit"
        let risk = appActionRisk(for: action)
        let force = flag("--force")
        let timeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var prerequisites = [doctorAuditLogCheck()]

        let targetArguments: [String]?
        if flag("--current") {
            targetArguments = ["--current"]
        } else if let pid = option("--pid") {
            targetArguments = ["--pid", pid]
        } else if let bundleIdentifier = option("--bundle-id") {
            targetArguments = ["--bundle-id", bundleIdentifier]
        } else {
            targetArguments = nil
            prerequisites.append(DoctorCheck(
                name: "workflow.appTarget",
                status: "fail",
                required: true,
                message: "No app target was provided for quit-app.",
                remediation: "Run `Ln1 apps` and pass `--pid PID`, `--bundle-id BUNDLE_ID`, or `--current`."
            ))
        }

        if targetArguments != nil {
            do {
                let target = try targetRunningApplicationForAppCommand()
                prerequisites += appQuitChecks(target: target).map { check in
                    DoctorCheck(
                        name: check.name,
                        status: check.ok ? "pass" : "fail",
                        required: true,
                        message: check.message,
                        remediation: check.ok ? nil : "Choose a running regular GUI app that is not the current Ln1 process."
                    )
                }
            } catch {
                let message = (error as? CommandError)?.description ?? error.localizedDescription
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: message,
                    remediation: "Run `Ln1 apps` and choose a current running app target."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk high` after reviewing the app quit target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetArguments {
            var arguments = ["Ln1", "apps", "quit"] + targetArguments
            if force {
                arguments.append("--force")
            }
            arguments += [
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds),
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "quit-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightOpenFile() throws -> WorkflowPreflight {
        try workflowPreflightWorkspaceOpen(operation: "open-file", targetOption: "--path")
    }

    private func workflowPreflightOpenURL() throws -> WorkflowPreflight {
        try workflowPreflightWorkspaceOpen(operation: "open-url", targetOption: "--url")
    }

    private func workflowPreflightWorkspaceOpen(operation: String, targetOption: String) throws -> WorkflowPreflight {
        let action = "workspace.open"
        let risk = workspaceActionRisk(for: action)
        var prerequisites = [doctorAuditLogCheck()]

        let targetValue = option(targetOption)
        if targetValue == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.workspaceOpenTarget",
                status: "fail",
                required: true,
                message: "No \(targetOption == "--path" ? "file path" : "URL") target was provided for \(operation).",
                remediation: "Pass `\(targetOption) \(targetOption == "--path" ? "PATH" : "URL")`."
            ))
        } else {
            do {
                _ = try workspaceOpenTargetForCommand()
                prerequisites.append(DoctorCheck(
                    name: "workflow.workspaceOpenTarget",
                    status: "pass",
                    required: true,
                    message: "A workspace open target is available for \(operation).",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.workspaceOpenTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: targetOption == "--path"
                        ? "Pass `--path PATH` for an existing readable file or directory."
                        : "Pass `--url URL` with a valid scheme."
                ))
            }
        }

        let policy = policyDecision(actionRisk: risk)
        prerequisites.append(DoctorCheck(
            name: "workflow.policy",
            status: policy.allowed ? "pass" : "fail",
            required: true,
            message: policy.message,
            remediation: policy.allowed ? nil : "Pass `--allow-risk medium` after reviewing the open target."
        ))

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let targetValue {
            var arguments = [
                "Ln1", "open",
                targetOption, targetValue,
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: operation,
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightControlActiveApp() -> WorkflowPreflight {
        let action = option("--action") ?? kAXPressAction as String
        let risk = riskLevel(for: action)
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        var targetPid = activePid
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        if option("--pid") != nil || option("--bundle-id") != nil || flag("--current") {
            do {
                let target = try targetRunningApplicationForAppCommand()
                targetPid = target.processIdentifier
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for control-active-app.",
                    remediation: nil
                ))
            } catch {
                targetPid = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 apps` and choose a running app target, or omit app targeting to use the frontmost app."
                ))
            }
        }

        let element = option("--element")
        if element == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No target element was provided for control-active-app.",
                remediation: "Run `Ln1 state\(targetPid.map { " --pid \($0)" } ?? "") --depth 3 --max-children 80` and choose an element ID plus stableIdentity."
            ))
        }

        if option("--expect-identity") == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.expectedIdentity",
                status: "warn",
                required: false,
                message: "No expected stable identity was provided, so perform cannot guard against stale element paths.",
                remediation: "Pass `--expect-identity` from the element's stableIdentity.id and `--min-identity-confidence medium`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let element {
            var arguments = ["Ln1", "perform"]
            if let targetPid {
                arguments += ["--pid", String(targetPid)]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            arguments += ["--min-identity-confidence", option("--min-identity-confidence") ?? "medium"]
            arguments += ["--action", action, "--allow-risk", risk, "--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "control-active-app",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightSetElementValue() -> WorkflowPreflight {
        let risk = accessibilityActionRisk(for: "accessibility.setValue")
        let activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier
        var targetPid = activePid
        var prerequisites = [
            doctorAccessibilityCheck(),
            doctorAuditLogCheck()
        ]

        if option("--pid") != nil || option("--bundle-id") != nil || flag("--current") {
            do {
                let target = try targetRunningApplicationForAppCommand()
                targetPid = target.processIdentifier
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "pass",
                    required: true,
                    message: "A running app target is available for set-element-value.",
                    remediation: nil
                ))
            } catch {
                targetPid = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.appTarget",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 apps` and choose a running app target, or omit app targeting to use the frontmost app."
                ))
            }
        }

        let element = option("--element")
        if let element {
            do {
                _ = try normalizedElementID(element)
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "pass",
                    required: true,
                    message: "An Accessibility element path is available for set-element-value.",
                    remediation: nil
                ))
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.element",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Run `Ln1 state --depth 3 --max-children 80` and pass an element ID whose settableAttributes include AXValue."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.element",
                status: "fail",
                required: true,
                message: "No target element was provided for set-element-value.",
                remediation: "Run `Ln1 state --depth 3 --max-children 80` and choose an element ID whose settableAttributes include AXValue."
            ))
        }

        let value = option("--value")
        if value == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.value",
                status: "fail",
                required: true,
                message: "No value was provided for set-element-value.",
                remediation: "Pass `--value TEXT` for the target element."
            ))
        }

        if option("--expect-identity") == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.expectedIdentity",
                status: "warn",
                required: false,
                message: "No expected stable identity was provided, so set-value cannot guard against stale element paths.",
                remediation: "Pass `--expect-identity` from the element's stableIdentity.id and `--min-identity-confidence medium`."
            ))
        }

        if let minimumConfidence = option("--min-identity-confidence"),
           identityConfidenceRank(minimumConfidence) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.identityConfidence",
                status: "fail",
                required: true,
                message: "Invalid minimum stable identity confidence '\(minimumConfidence)'.",
                remediation: "Use `--min-identity-confidence low`, `medium`, or `high`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let element, let value {
            var arguments = ["Ln1", "set-value"]
            if let targetPid {
                arguments += ["--pid", String(targetPid)]
            }
            arguments += ["--element", element]
            if let expectedIdentity = option("--expect-identity") {
                arguments += ["--expect-identity", expectedIdentity]
            }
            arguments += ["--min-identity-confidence", option("--min-identity-confidence") ?? "medium"]
            arguments += [
                "--value", value,
                "--allow-risk", risk
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "set-element-value",
            risk: risk,
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadBrowser() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 1_000)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        let prerequisites = [requiredBrowserCheck]
        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let id = option("--id") {
            var arguments = ["Ln1", "browser", "dom"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--allow-risk", "medium",
                "--max-elements", "200",
                "--max-text-characters", "120",
                "--reason", "Inspect browser state"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if blockers.isEmpty {
            let arguments = ["Ln1", "browser", "tabs", "--endpoint", endpoint?.absoluteString ?? "http://127.0.0.1:9222"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "read-browser",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightBrowserAction(kind: String) -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 1_000)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [
            requiredBrowserCheck,
            doctorAuditLogCheck()
        ]

        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let value = option("--value")
        let label = option("--label")
        let checked = option("--checked")
        let url = option("--url")
        let expectedURL = option("--expect-url")
        let match = option("--match")
        let key = option("--key")
        let modifiers = option("--modifiers")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for \(kind)-browser.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if kind == "fill" || kind == "select" || kind == "check" || kind == "focus" || kind == "click", selector == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for \(kind)-browser.",
                remediation: "Run `Ln1 workflow run --operation read-browser --id TARGET_ID --dry-run false --allow-risk medium` and choose an element selector."
            ))
        }
        if kind == "press-key" {
            if let key {
                do {
                    _ = try browserKeyDefinition(for: key)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserKey",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a supported key with `--key Enter`, `--key Escape`, `--key Tab`, an arrow key, a function key, or one ASCII letter/digit."
                    ))
                }
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserKey",
                    status: "fail",
                    required: true,
                    message: "No key was provided for press-browser-key.",
                    remediation: "Pass `--key Enter`, `--key Escape`, `--key Tab`, an arrow key, a function key, or one ASCII letter/digit."
                ))
            }
            if let modifiers {
                do {
                    _ = try browserModifierMask(modifiers)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserModifiers",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use comma-separated modifiers from shift, control, alt, or meta."
                    ))
                }
            }
        }
        if kind == "fill", text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No text was provided for fill-browser.",
                remediation: "Pass `--text TEXT` for the target field."
            ))
        }
        if kind == "select" {
            if value == nil && label == nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectOption",
                    status: "fail",
                    required: true,
                    message: "No option value or label was provided for select-browser.",
                    remediation: "Pass `--value VALUE` or `--label LABEL` for the target option."
                ))
            }
            if value != nil && label != nil {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectOption",
                    status: "fail",
                    required: true,
                    message: "select-browser accepts either --value or --label, not both.",
                    remediation: "Pass only one of `--value VALUE` or `--label LABEL`."
                ))
            }
            if let value {
                do {
                    _ = try validatedBrowserSelectOption(value, optionName: "--value")
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserSelectOption",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty option value with `--value VALUE`."
                    ))
                }
            }
            if let label {
                do {
                    _ = try validatedBrowserSelectOption(label, optionName: "--label")
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserSelectOption",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty option label with `--label LABEL`."
                    ))
                }
            }
        }
        if kind == "check", let checked {
            do {
                _ = try browserCheckedValue(checked)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserChecked",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--checked true` or `--checked false`."
                ))
            }
        }
        let normalizedURL: String?
        if kind == "navigate" {
            if let url {
                do {
                    normalizedURL = try validatedBrowserNavigationURL(url)
                } catch {
                    normalizedURL = nil
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass an absolute HTTP(S) URL with `--url URL`."
                    ))
                }
            } else {
                normalizedURL = nil
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserURL",
                    status: "fail",
                    required: true,
                    message: "No URL was provided for navigate-browser.",
                    remediation: "Pass `--url URL` for the target navigation."
                ))
            }
            if let expectedURL {
                do {
                    _ = try validatedBrowserExpectedURL(expectedURL)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserExpectedURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                    ))
                }
            }
            if let match {
                do {
                    _ = try browserURLMatchMode(match)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURLMatch",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                    ))
                }
            }
        } else if kind == "click" {
            normalizedURL = nil
            if let expectedURL {
                do {
                    _ = try validatedBrowserExpectedURL(expectedURL)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserExpectedURL",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                    ))
                }
            }
            if let match {
                do {
                    _ = try browserURLMatchMode(match)
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.browserURLMatch",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                    ))
                }
            }
        } else {
            normalizedURL = nil
        }

        let blockers = workflowBlockers(from: prerequisites)
        let operation = kind == "press-key" ? "press-browser-key" : "\(kind)-browser"
        let nextArguments: [String]?
        if blockers.isEmpty, kind == "navigate", let id, let normalizedURL {
            var arguments = ["Ln1", "browser", "navigate"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--url", normalizedURL]
            if let expectedURL {
                arguments += ["--expect-url", expectedURL]
            }
            if let match {
                arguments += ["--match", match]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else if blockers.isEmpty, kind == "press-key", let id, let key {
            var arguments = ["Ln1", "browser", "press-key"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--key", key]
            if let selector {
                arguments += ["--selector", selector]
            }
            if let modifiers {
                arguments += ["--modifiers", modifiers]
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", kind]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += ["--id", id, "--selector", selector]
            if kind == "fill", let text {
                arguments += ["--text", text]
            }
            if kind == "select" {
                if let value {
                    arguments += ["--value", value]
                }
                if let label {
                    arguments += ["--label", label]
                }
            }
            if kind == "check" {
                arguments += ["--checked", checked ?? "true"]
            }
            if kind == "click", let expectedURL {
                arguments += ["--expect-url", expectedURL, "--match", match ?? "exact"]
                if let timeout = option("--timeout-ms") {
                    arguments += ["--timeout-ms", timeout]
                }
                if let interval = option("--interval-ms") {
                    arguments += ["--interval-ms", interval]
                }
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--allow-risk", "medium", "--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: operation,
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserURL() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let expectedURL = option("--expect-url")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-url.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let expectedURL {
            do {
                _ = try validatedBrowserExpectedURL(expectedURL)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserExpectedURL",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty URL or text fragment with `--expect-url VALUE`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserExpectedURL",
                status: "fail",
                required: true,
                message: "No expected URL was provided for wait-browser-url.",
                remediation: "Pass `--expect-url VALUE` for the target URL."
            ))
        }
        if let match {
            do {
                _ = try browserURLMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserURLMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact`, `--match prefix`, or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let expectedURL {
            var arguments = ["Ln1", "browser", "wait-url"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--expect-url", expectedURL,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-url",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserSelector() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let state = option("--state")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-selector.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-selector.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let state {
            do {
                _ = try browserSelectorWaitState(state)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelectorState",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--state attached`, `--state visible`, `--state hidden`, or `--state detached`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-selector"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--state", state ?? "attached",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-selector",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserCount() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let count = option("--count")
        let countMatch = option("--count-match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-count.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-count.",
                remediation: "Pass `--selector CSS_SELECTOR` for the repeated elements."
            ))
        }
        if let count {
            do {
                _ = try browserSelectorCountValue(count)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserCount",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--count N`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserCount",
                status: "fail",
                required: true,
                message: "No expected selector count was provided for wait-browser-count.",
                remediation: "Pass `--count N` for the expected selector count."
            ))
        }
        if let countMatch {
            do {
                _ = try browserCountMatchMode(countMatch)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserCountMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--count-match exact`, `--count-match at-least`, or `--count-match at-most`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let count {
            var arguments = ["Ln1", "browser", "wait-count"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--count", count,
                "--count-match", countMatch ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-count",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserText() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-text.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected text was provided for wait-browser-text.",
                remediation: "Pass `--text TEXT` for the expected page text."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTextMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match contains` or `--match exact`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let text {
            var arguments = ["Ln1", "browser", "wait-text"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--text", text,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-text",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserElementText() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-element-text.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-element-text.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected element text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected element text was provided for wait-browser-element-text.",
                remediation: "Pass `--text TEXT` for the expected element text."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserElementTextMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let text {
            var arguments = ["Ln1", "browser", "wait-element-text"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--text", text,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-element-text",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserValue() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-value.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-value.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target input, textarea, or select."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected value text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected value text was provided for wait-browser-value.",
                remediation: "Pass `--text TEXT` for the expected field value."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserValueMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let text {
            var arguments = ["Ln1", "browser", "wait-value"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--text", text,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-value",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserReady() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let state = option("--state")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-ready.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let state {
            do {
                _ = try browserReadyState(state)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserReadyState",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--state loading`, `--state interactive`, or `--state complete`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id {
            var arguments = ["Ln1", "browser", "wait-ready"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--state", state ?? "complete",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-ready",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserTitle() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let title = option("--title")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-title.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let title {
            do {
                _ = try validatedBrowserExpectedTitle(title)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTitle",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected title with `--title TITLE`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTitle",
                status: "fail",
                required: true,
                message: "No expected title was provided for wait-browser-title.",
                remediation: "Pass `--title TITLE` for the expected page title."
            ))
        }
        if let match {
            do {
                _ = try browserTitleMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserTitleMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match contains` or `--match exact`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let title {
            var arguments = ["Ln1", "browser", "wait-title"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--title", title,
                "--match", match ?? "contains",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-title",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserChecked() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let checked = option("--checked")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-checked.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-checked.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target checkbox or radio input."
            ))
        }
        if let checked {
            do {
                _ = try browserCheckedValue(checked)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserChecked",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--checked true` or `--checked false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-checked"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--checked", checked ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-checked",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserEnabled() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let enabled = option("--enabled")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-enabled.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-enabled.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let enabled {
            do {
                _ = try browserEnabledValue(enabled)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserEnabled",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--enabled true` or `--enabled false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-enabled"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--enabled", enabled ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-enabled",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserFocus() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let focused = option("--focused")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-focus.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-focus.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let focused {
            do {
                _ = try browserFocusedValue(focused)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserFocused",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--focused true` or `--focused false`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector {
            var arguments = ["Ln1", "browser", "wait-focus"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--focused", focused ?? "true",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-focus",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitBrowserAttribute() -> WorkflowPreflight {
        let timeoutMilliseconds = max(100, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let endpoint = try? browserEndpoint()
        let browserCheck = doctorBrowserDevToolsCheck(endpoint: endpoint, timeoutMilliseconds: timeoutMilliseconds)
        let requiredBrowserCheck = DoctorCheck(
            name: browserCheck.name,
            status: browserCheck.status == "pass" ? "pass" : "fail",
            required: true,
            message: browserCheck.message,
            remediation: browserCheck.status == "pass" ? nil : browserCheck.remediation
        )
        var prerequisites = [requiredBrowserCheck]
        let id = option("--id")
        let selector = option("--selector")
        let attribute = option("--attribute")
        let text = option("--text")
        let match = option("--match")
        if id == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserTabID",
                status: "fail",
                required: true,
                message: "No browser tab ID was provided for wait-browser-attribute.",
                remediation: "Run `Ln1 workflow run --operation read-browser --dry-run false` and choose a tab ID."
            ))
        }
        if let selector {
            do {
                _ = try validatedBrowserSelector(selector)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserSelector",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-empty CSS selector with `--selector CSS_SELECTOR`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserSelector",
                status: "fail",
                required: true,
                message: "No CSS selector was provided for wait-browser-attribute.",
                remediation: "Pass `--selector CSS_SELECTOR` for the target element."
            ))
        }
        if let attribute {
            do {
                _ = try validatedBrowserAttributeName(attribute)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserAttribute",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a safe attribute name such as `aria-expanded`, `data-state`, `href`, or `class`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserAttribute",
                status: "fail",
                required: true,
                message: "No attribute name was provided for wait-browser-attribute.",
                remediation: "Pass `--attribute NAME` for the target element attribute."
            ))
        }
        if let text {
            do {
                _ = try validatedBrowserExpectedText(text)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserText",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass non-empty expected attribute text with `--text TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.browserText",
                status: "fail",
                required: true,
                message: "No expected attribute text was provided for wait-browser-attribute.",
                remediation: "Pass `--text TEXT` for the expected attribute value."
            ))
        }
        if let match {
            do {
                _ = try browserTextMatchMode(match)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.browserAttributeMatch",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--match exact` or `--match contains`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let id, let selector, let attribute, let text {
            var arguments = ["Ln1", "browser", "wait-attribute"]
            if let endpoint {
                arguments += ["--endpoint", endpoint.absoluteString]
            }
            arguments += [
                "--id", id,
                "--selector", selector,
                "--attribute", attribute,
                "--text", text,
                "--match", match ?? "exact",
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-browser-attribute",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightDuplicateFile() throws -> WorkflowPreflight {
        try workflowPreflightCopyLikeFile(
            workflowOperation: "duplicate-file",
            fileOperation: "duplicate",
            fileCommand: "duplicate",
            missingSourceMessage: "No source path was provided for duplicate-file.",
            missingDestinationMessage: "No destination path was provided for duplicate-file.",
            blockedRemediation: "Resolve filesystem preflight check %@ before duplicating."
        )
    }

    private func workflowPreflightCreateDirectory() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.directoryPath",
                status: "fail",
                required: true,
                message: "No directory path was provided for create-directory.",
                remediation: "Pass `--path DIRECTORY`."
            ))
        }

        if path != nil {
            let preflight = try fileOperationPreflight(operation: "mkdir")
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : "Resolve filesystem preflight check \(check.name) before creating the directory."
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "mkdir",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if let path {
            let arguments = [
                "Ln1", "files", "plan",
                "--operation", "mkdir",
                "--path", path,
                "--allow-risk", "medium"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "create-directory",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightMoveFile() throws -> WorkflowPreflight {
        try workflowPreflightCopyLikeFile(
            workflowOperation: "move-file",
            fileOperation: "move",
            fileCommand: "move",
            missingSourceMessage: "No source path was provided for move-file.",
            missingDestinationMessage: "No destination path was provided for move-file.",
            blockedRemediation: "Resolve filesystem preflight check %@ before moving."
        )
    }

    private func workflowPreflightRollbackFileMove() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let auditID = option("--audit-id")
        if auditID == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.auditID",
                status: "fail",
                required: true,
                message: "No move audit ID was provided for rollback-file-move.",
                remediation: "Pass `--audit-id AUDIT_ID` from a successful files.move audit record."
            ))
        }

        if auditID != nil {
            let preflight = try fileOperationPreflight(operation: "rollback")
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : "Resolve filesystem preflight check \(check.name) before rolling back the move."
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let auditID {
            var arguments = [
                "Ln1", "files", "rollback",
                "--audit-id", auditID,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if let auditID {
            var arguments = [
                "Ln1", "files", "plan",
                "--operation", "rollback",
                "--audit-id", auditID,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: "rollback-file-move",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if !FileManager.default.fileExists(atPath: expandedURL.path) {
                prerequisites.append(DoctorCheck(
                    name: "workflow.inspectPath",
                    status: "fail",
                    required: true,
                    message: "File path does not exist at \(expandedURL.path).",
                    remediation: "Pass an existing file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for inspect-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            nextArguments = [
                "Ln1", "files", "stat",
                "--path", path
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "inspect-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFile() -> WorkflowPreflight {
        workflowPreflightFileText(
            operation: "read-file",
            command: "read-text",
            supportDescription: "read-file",
            missingPathMessage: "No path was provided for read-file.",
            reason: "Inspect file text"
        )
    }

    private func workflowPreflightTailFile() -> WorkflowPreflight {
        workflowPreflightFileText(
            operation: "tail-file",
            command: "tail-text",
            supportDescription: "tail-file",
            missingPathMessage: "No path was provided for tail-file.",
            reason: "Inspect file tail text"
        )
    }

    private func workflowPreflightReadFileLines() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        var startLine = 1
        var lineCount = 80
        var maxLineCharacters = 240
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawStartLine = option("--start-line") {
            if let parsed = Int(rawStartLine) {
                startLine = max(1, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileStartLine",
                    status: "fail",
                    required: true,
                    message: "--start-line must be an integer.",
                    remediation: "Pass a positive integer with `--start-line N`."
                ))
            }
        }

        if let rawLineCount = option("--line-count") {
            if let parsed = Int(rawLineCount) {
                lineCount = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileLineCount",
                    status: "fail",
                    required: true,
                    message: "--line-count must be an integer.",
                    remediation: "Pass a non-negative integer with `--line-count N`."
                ))
            }
        }

        if let rawMaxLineCharacters = option("--max-line-characters") {
            if let parsed = Int(rawMaxLineCharacters) {
                maxLineCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxLineCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-line-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-line-characters N`."
                ))
            }
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-lines supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-lines.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-lines",
                "--path", path,
                "--allow-risk", "medium",
                "--start-line", String(startLine),
                "--line-count", String(lineCount),
                "--max-line-characters", String(maxLineCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect file line range"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-lines",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFileJSON() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let pointer = option("--pointer")
        var maxDepth = 4
        var maxItems = 50
        var maxStringCharacters = 1_024
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxDepth = option("--max-depth") {
            if let parsed = Int(rawMaxDepth) {
                maxDepth = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxDepth",
                    status: "fail",
                    required: true,
                    message: "--max-depth must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-depth N`."
                ))
            }
        }

        if let rawMaxItems = option("--max-items") {
            if let parsed = Int(rawMaxItems) {
                maxItems = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxItems",
                    status: "fail",
                    required: true,
                    message: "--max-items must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-items N`."
                ))
            }
        }

        if let rawMaxStringCharacters = option("--max-string-characters") {
            if let parsed = Int(rawMaxStringCharacters) {
                maxStringCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileJSONMaxStringCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-string-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-string-characters N`."
                ))
            }
        }

        if let rawPointer = pointer, !rawPointer.isEmpty, !rawPointer.hasPrefix("/") {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileJSONPointer",
                status: "fail",
                required: true,
                message: "--pointer must be an empty string or a JSON Pointer starting with '/'.",
                remediation: "Pass a valid JSON Pointer such as `/items/0`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-json supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 JSON file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 JSON file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-json.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-json",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let pointer {
                arguments += ["--pointer", pointer]
            }
            arguments += [
                "--max-depth", String(maxDepth),
                "--max-items", String(maxItems),
                "--max-string-characters", String(maxStringCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect JSON file value"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-json",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightReadFilePropertyList() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let pointer = option("--pointer")
        var maxDepth = 4
        var maxItems = 50
        var maxStringCharacters = 1_024
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxDepth = option("--max-depth") {
            if let parsed = Int(rawMaxDepth) {
                maxDepth = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxDepth",
                    status: "fail",
                    required: true,
                    message: "--max-depth must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-depth N`."
                ))
            }
        }

        if let rawMaxItems = option("--max-items") {
            if let parsed = Int(rawMaxItems) {
                maxItems = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxItems",
                    status: "fail",
                    required: true,
                    message: "--max-items must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-items N`."
                ))
            }
        }

        if let rawMaxStringCharacters = option("--max-string-characters") {
            if let parsed = Int(rawMaxStringCharacters) {
                maxStringCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.filePropertyListMaxStringCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-string-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-string-characters N`."
                ))
            }
        }

        if let rawPointer = pointer, !rawPointer.isEmpty, !rawPointer.hasPrefix("/") {
            prerequisites.append(DoctorCheck(
                name: "workflow.filePropertyListPointer",
                status: "fail",
                required: true,
                message: "--pointer must be an empty string or a pointer starting with '/'.",
                remediation: "Pass a valid pointer such as `/items/0`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "read-file-plist supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular property list file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular property list file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for read-file-plist.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "read-plist",
                "--path", path,
                "--allow-risk", "medium"
            ]
            if let pointer {
                arguments += ["--pointer", pointer]
            }
            arguments += [
                "--max-depth", String(maxDepth),
                "--max-items", String(maxItems),
                "--max-string-characters", String(maxStringCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", "Inspect property list file value"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-file-plist",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightFileText(
        operation: String,
        command: String,
        supportDescription: String,
        missingPathMessage: String,
        reason: String
    ) -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        var maxCharacters = 16_384
        var maxFileBytes = 1_048_576
        var parsedMaxFileBytes = true

        if let rawMaxCharacters = option("--max-characters") {
            if let parsed = Int(rawMaxCharacters) {
                maxCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-characters N`."
                ))
            }
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readRegularFile",
                        status: "fail",
                        required: true,
                        message: "\(supportDescription) supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular UTF-8 file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.readMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.readPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular UTF-8 file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: missingPathMessage,
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", command,
                "--path", path,
                "--allow-risk", "medium",
                "--max-characters", String(maxCharacters),
                "--max-file-bytes", String(maxFileBytes),
                "--reason", reason
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: operation,
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWriteFile() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        let text = option("--text")
        let overwrite = flag("--overwrite")

        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for write-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        if text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.text",
                status: "fail",
                required: true,
                message: "No text was provided for write-file.",
                remediation: "Pass `--text TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            let parentURL = expandedURL.deletingLastPathComponent()
            prerequisites.append(directoryExistsDoctorCheck(name: "workflow.destinationParentExists", url: parentURL))
            prerequisites.append(writableDirectoryDoctorCheck(name: "workflow.destinationParentWritable", url: parentURL))

            if FileManager.default.fileExists(atPath: expandedURL.path) {
                do {
                    let record = try fileRecord(for: expandedURL)
                    if !overwrite {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationOverwrite",
                            status: "fail",
                            required: true,
                            message: "Destination already exists at \(expandedURL.path).",
                            remediation: "Pass `--overwrite` only when replacing the existing file is intended."
                        ))
                    }
                    if record.kind != "regularFile" {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationRegularFile",
                            status: "fail",
                            required: true,
                            message: "write-file can overwrite regular files only; \(expandedURL.path) is \(record.kind).",
                            remediation: "Choose a regular file path or a missing path."
                        ))
                    }
                    if !record.writable {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationWritable",
                            status: "fail",
                            required: true,
                            message: "Destination file is not writable at \(expandedURL.path).",
                            remediation: "Choose a writable file or adjust filesystem permissions."
                        ))
                    }
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationReadable",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Choose a writable regular file or a missing path."
                    ))
                }
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let text {
            var arguments = [
                "Ln1", "files", "write-text",
                "--path", path,
                "--text", text,
                "--allow-risk", "medium"
            ]
            if overwrite {
                arguments.append("--overwrite")
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "write-file",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightAppendFile() throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let path = option("--path")
        let text = option("--text")
        let create = flag("--create")

        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for append-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        if text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.text",
                status: "fail",
                required: true,
                message: "No text was provided for append-file.",
                remediation: "Pass `--text TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if FileManager.default.fileExists(atPath: expandedURL.path) {
                do {
                    let record = try fileRecord(for: expandedURL)
                    if record.kind != "regularFile" {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationRegularFile",
                            status: "fail",
                            required: true,
                            message: "append-file supports regular files only; \(expandedURL.path) is \(record.kind).",
                            remediation: "Choose a writable regular file or a missing path with `--create`."
                        ))
                    }
                    if !record.writable {
                        prerequisites.append(DoctorCheck(
                            name: "workflow.destinationWritable",
                            status: "fail",
                            required: true,
                            message: "Destination file is not writable at \(expandedURL.path).",
                            remediation: "Choose a writable file or adjust filesystem permissions."
                        ))
                    }
                } catch {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationReadable",
                        status: "fail",
                        required: true,
                        message: (error as? CommandError)?.description ?? error.localizedDescription,
                        remediation: "Choose a writable regular file or a missing path with `--create`."
                    ))
                }
            } else {
                if !create {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.destinationCreate",
                        status: "fail",
                        required: true,
                        message: "Destination does not exist at \(expandedURL.path).",
                        remediation: "Pass `--create` only when creating the file before appending is intended."
                    ))
                }
                let parentURL = expandedURL.deletingLastPathComponent()
                prerequisites.append(directoryExistsDoctorCheck(name: "workflow.destinationParentExists", url: parentURL))
                prerequisites.append(writableDirectoryDoctorCheck(name: "workflow.destinationParentWritable", url: parentURL))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let text {
            var arguments = [
                "Ln1", "files", "append-text",
                "--path", path,
                "--text", text,
                "--allow-risk", "medium"
            ]
            if create {
                arguments.append("--create")
            }
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "append-file",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightListFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 2)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "directory" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.listDirectory",
                        status: "fail",
                        required: true,
                        message: "list-files requires a directory; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a directory with `--path PATH`, or use `inspect-file` for one file."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.listReadable",
                        status: "fail",
                        required: true,
                        message: "Directory is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable directory or adjust filesystem permissions."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.listPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing readable directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for list-files.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "list",
                "--path", path,
                "--depth", String(maxDepth),
                "--limit", String(limit)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "list-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightSearchFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let query = option("--query")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 4)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
        let maxFileBytes = max(0, option("--max-file-bytes").flatMap(Int.init) ?? 1_048_576)
        let maxSnippetCharacters = max(20, option("--max-snippet-characters").flatMap(Int.init) ?? 240)
        let maxMatchesPerFile = max(1, option("--max-matches-per-file").flatMap(Int.init) ?? 20)

        if let query {
            if query.isEmpty {
                prerequisites.append(DoctorCheck(
                    name: "workflow.searchQuery",
                    status: "fail",
                    required: true,
                    message: "search-files requires a non-empty query.",
                    remediation: "Pass non-empty text with `--query TEXT`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.searchQuery",
                status: "fail",
                required: true,
                message: "No query was provided for search-files.",
                remediation: "Pass `--query TEXT`."
            ))
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.searchReadable",
                        status: "fail",
                        required: true,
                        message: "Search root is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or directory, or adjust filesystem permissions."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.searchPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing readable file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for search-files.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path, let query {
            var arguments = [
                "Ln1", "files", "search",
                "--path", path,
                "--query", query,
                "--depth", String(maxDepth),
                "--limit", String(limit),
                "--max-file-bytes", String(maxFileBytes),
                "--max-snippet-characters", String(maxSnippetCharacters),
                "--max-matches-per-file", String(maxMatchesPerFile)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            if flag("--case-sensitive") {
                arguments.append("--case-sensitive")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "search-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWatchFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let maxDepth = max(0, option("--depth").flatMap(Int.init) ?? 1)
        let limit = max(1, option("--limit").flatMap(Int.init) ?? 200)
        let watchTimeoutMilliseconds = max(0, option("--watch-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            if !FileManager.default.fileExists(atPath: expandedURL.path) {
                prerequisites.append(DoctorCheck(
                    name: "workflow.watchRoot",
                    status: "fail",
                    required: true,
                    message: "Watch root does not exist at \(expandedURL.path).",
                    remediation: "Pass an existing file or directory with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for watch-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "watch",
                "--path", path,
                "--depth", String(maxDepth),
                "--limit", String(limit),
                "--timeout-ms", String(watchTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            if flag("--include-hidden") {
                arguments.append("--include-hidden")
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "watch-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightChecksumFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let algorithm = option("--algorithm") ?? "sha256"
        var normalizedAlgorithm = "sha256"
        var maxFileBytes = 104_857_600
        var parsedMaxFileBytes = true

        do {
            normalizedAlgorithm = try normalizedChecksumAlgorithm(algorithm)
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigestAlgorithm",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Use `--algorithm sha256`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        if let path {
            let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
            do {
                let record = try fileRecord(for: expandedURL)
                if record.kind != "regularFile" {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumRegularFile",
                        status: "fail",
                        required: true,
                        message: "checksum-file supports regular files only; \(expandedURL.path) is \(record.kind).",
                        remediation: "Pass a regular file with `--path PATH`."
                    ))
                }
                if !record.readable {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumReadable",
                        status: "fail",
                        required: true,
                        message: "File is not readable at \(expandedURL.path).",
                        remediation: "Choose a readable file or adjust filesystem permissions."
                    ))
                }
                if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                    prerequisites.append(DoctorCheck(
                        name: "workflow.checksumMaxBytes",
                        status: "fail",
                        required: true,
                        message: "File size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                        remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                    ))
                }
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.checksumPath",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass an existing regular file with `--path PATH`."
                ))
            }
        } else {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for checksum-file.",
                remediation: "Pass `--path PATH`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            nextArguments = [
                "Ln1", "files", "checksum",
                "--path", path,
                "--algorithm", normalizedAlgorithm,
                "--max-file-bytes", String(maxFileBytes)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "checksum-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightCompareFiles() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let leftPath = option("--path")
        let rightPath = option("--to")
        let algorithm = option("--algorithm") ?? "sha256"
        var normalizedAlgorithm = "sha256"
        var maxFileBytes = 104_857_600
        var parsedMaxFileBytes = true

        do {
            normalizedAlgorithm = try normalizedChecksumAlgorithm(algorithm)
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigestAlgorithm",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Use `--algorithm sha256`."
            ))
        }

        if let rawMaxFileBytes = option("--max-file-bytes") {
            do {
                maxFileBytes = try fileMaxBytes(rawMaxFileBytes, optionName: "--max-file-bytes")
            } catch {
                parsedMaxFileBytes = false
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }

        workflowAppendComparableFileChecks(
            path: leftPath,
            role: "left",
            missingName: "workflow.leftPath",
            missingMessage: "No left path was provided for compare-files.",
            maxFileBytes: maxFileBytes,
            parsedMaxFileBytes: parsedMaxFileBytes,
            prerequisites: &prerequisites
        )
        workflowAppendComparableFileChecks(
            path: rightPath,
            role: "right",
            missingName: "workflow.rightPath",
            missingMessage: "No right path was provided for compare-files.",
            maxFileBytes: maxFileBytes,
            parsedMaxFileBytes: parsedMaxFileBytes,
            prerequisites: &prerequisites
        )

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let leftPath, let rightPath {
            nextArguments = [
                "Ln1", "files", "compare",
                "--path", leftPath,
                "--to", rightPath,
                "--algorithm", normalizedAlgorithm,
                "--max-file-bytes", String(maxFileBytes)
            ]
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "compare-files",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowAppendComparableFileChecks(
        path: String?,
        role: String,
        missingName: String,
        missingMessage: String,
        maxFileBytes: Int,
        parsedMaxFileBytes: Bool,
        prerequisites: inout [DoctorCheck]
    ) {
        guard let path else {
            prerequisites.append(DoctorCheck(
                name: missingName,
                status: "fail",
                required: true,
                message: missingMessage,
                remediation: "Pass `--path LEFT` and `--to RIGHT`."
            ))
            return
        }

        let expandedURL = URL(fileURLWithPath: expandedPath(path)).standardizedFileURL
        do {
            let record = try fileRecord(for: expandedURL)
            if record.kind != "regularFile" {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)RegularFile",
                    status: "fail",
                    required: true,
                    message: "compare-files supports regular files only; \(expandedURL.path) is \(record.kind).",
                    remediation: "Pass a regular file for the \(role) path."
                ))
            }
            if !record.readable {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)Readable",
                    status: "fail",
                    required: true,
                    message: "The \(role) file is not readable at \(expandedURL.path).",
                    remediation: "Choose a readable file or adjust filesystem permissions."
                ))
            }
            if parsedMaxFileBytes, let size = record.sizeBytes, size > maxFileBytes {
                prerequisites.append(DoctorCheck(
                    name: "workflow.\(role)MaxBytes",
                    status: "fail",
                    required: true,
                    message: "The \(role) file size \(size) exceeds --max-file-bytes \(maxFileBytes).",
                    remediation: "Raise `--max-file-bytes` intentionally or choose a smaller file."
                ))
            }
        } catch {
            prerequisites.append(DoctorCheck(
                name: "workflow.\(role)Path",
                status: "fail",
                required: true,
                message: (error as? CommandError)?.description ?? error.localizedDescription,
                remediation: "Pass an existing regular file for the \(role) path."
            ))
        }
    }

    private func workflowPreflightCopyLikeFile(
        workflowOperation: String,
        fileOperation: String,
        fileCommand: String,
        missingSourceMessage: String,
        missingDestinationMessage: String,
        blockedRemediation: String
    ) throws -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let sourcePath = option("--path")
        let destinationPath = option("--to")
        if sourcePath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.sourcePath",
                status: "fail",
                required: true,
                message: missingSourceMessage,
                remediation: "Pass `--path SOURCE`."
            ))
        }
        if destinationPath == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.destinationPath",
                status: "fail",
                required: true,
                message: missingDestinationMessage,
                remediation: "Pass `--to DESTINATION`."
            ))
        }

        if sourcePath != nil, destinationPath != nil {
            let preflight = try fileOperationPreflight(operation: fileOperation)
            prerequisites.append(contentsOf: preflight.checks.map { check in
                DoctorCheck(
                    name: "filesystem.\(check.name)",
                    status: check.ok ? "pass" : "fail",
                    required: true,
                    message: check.message,
                    remediation: check.ok ? nil : String(format: blockedRemediation, check.name)
                )
            })
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextCommand: String?
        let nextArguments: [String]?
        if blockers.isEmpty, let sourcePath, let destinationPath {
            var arguments = [
                "Ln1", "files", fileCommand,
                "--path", sourcePath,
                "--to", destinationPath,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else if sourcePath != nil, destinationPath != nil {
            let arguments = [
                "Ln1", "files", "plan",
                "--operation", fileOperation,
                "--path", sourcePath!,
                "--to", destinationPath!,
                "--allow-risk", "medium"
            ]
            nextArguments = arguments
            nextCommand = workflowDisplayCommand(arguments)
        } else {
            nextArguments = nil
            nextCommand = workflowRemediationCommand(for: prerequisites)
        }

        return workflowPreflightResult(
            operation: workflowOperation,
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitFile() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let path = option("--path")
        let expectedExists = option("--exists").map(parseBool) ?? true
        let expectedSizeBytes = option("--size-bytes")
        let expectedDigest = option("--digest")
        let algorithm = option("--algorithm")
        let maxFileBytes = option("--max-file-bytes")
        if path == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.path",
                status: "fail",
                required: true,
                message: "No path was provided for wait-file.",
                remediation: "Pass `--path PATH`."
            ))
        }
        if let expectedSizeBytes {
            do {
                _ = try fileExpectedSizeBytes(expectedSizeBytes)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileSize",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--size-bytes N`."
                ))
            }
        }
        if let expectedDigest, !isSHA256HexDigest(expectedDigest) {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileDigest",
                status: "fail",
                required: true,
                message: "file digest must be a 64-character SHA-256 hex digest",
                remediation: "Pass a digest from `Ln1 files checksum --path PATH` with `--digest HEX`."
            ))
        }
        if let algorithm {
            do {
                _ = try normalizedChecksumAlgorithm(algorithm)
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileDigestAlgorithm",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--algorithm sha256`."
                ))
            }
        }
        if let maxFileBytes {
            do {
                _ = try fileMaxBytes(maxFileBytes, optionName: "--max-file-bytes")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.fileMaxBytes",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Pass a non-negative integer with `--max-file-bytes N`."
                ))
            }
        }
        if expectedExists == false && (expectedSizeBytes != nil || expectedDigest != nil) {
            prerequisites.append(DoctorCheck(
                name: "workflow.fileMetadataExpectation",
                status: "fail",
                required: true,
                message: "wait-file cannot verify size or digest while expecting the path to be missing.",
                remediation: "Use `--exists true` with metadata expectations, or remove `--size-bytes` and `--digest`."
            ))
        }

        let waitTimeoutMilliseconds = max(100, option("--wait-timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(50, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let path {
            var arguments = [
                "Ln1", "files", "wait",
                "--path", path,
                "--exists", String(expectedExists),
                "--timeout-ms", String(waitTimeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            if let expectedSizeBytes {
                arguments += ["--size-bytes", expectedSizeBytes]
            }
            if let expectedDigest {
                arguments += ["--digest", expectedDigest.lowercased()]
                arguments += ["--algorithm", algorithm ?? "sha256"]
                if let maxFileBytes {
                    arguments += ["--max-file-bytes", maxFileBytes]
                }
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-file",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWaitClipboard() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        let changedFrom = option("--changed-from")
        let hasString = option("--has-string")
        let stringDigest = option("--string-digest")

        if changedFrom == nil && hasString == nil && stringDigest == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardExpectation",
                status: "fail",
                required: true,
                message: "No clipboard wait expectation was provided.",
                remediation: "Pass `--changed-from N`, `--has-string true|false`, or `--string-digest SHA256`."
            ))
        }
        if let changedFrom, Int(changedFrom) == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardChangeCount",
                status: "fail",
                required: true,
                message: "Clipboard changed-from value must be an integer.",
                remediation: "Pass the previous clipboard change count with `--changed-from N`."
            ))
        }
        if let hasString {
            do {
                _ = try booleanOption(hasString, optionName: "--has-string")
            } catch {
                prerequisites.append(DoctorCheck(
                    name: "workflow.clipboardHasString",
                    status: "fail",
                    required: true,
                    message: (error as? CommandError)?.description ?? error.localizedDescription,
                    remediation: "Use `--has-string true` or `--has-string false`."
                ))
            }
        }
        if let stringDigest, !isSHA256HexDigest(stringDigest) {
            prerequisites.append(DoctorCheck(
                name: "workflow.clipboardDigest",
                status: "fail",
                required: true,
                message: "Clipboard string digest must be a 64-character SHA-256 hex digest.",
                remediation: "Pass a digest from `Ln1 clipboard state` with `--string-digest HEX`."
            ))
        }

        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = ["Ln1", "clipboard", "wait"]
            if let pasteboard = option("--pasteboard") {
                arguments += ["--pasteboard", pasteboard]
            }
            if let changedFrom {
                arguments += ["--changed-from", changedFrom]
            }
            if let hasString {
                arguments += ["--has-string", hasString]
            }
            if let stringDigest {
                arguments += ["--string-digest", stringDigest.lowercased()]
            }
            arguments += [
                "--timeout-ms", String(timeoutMilliseconds),
                "--interval-ms", String(intervalMilliseconds)
            ]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "wait-clipboard",
            risk: "low",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightInspectClipboard() -> WorkflowPreflight {
        var arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard = option("--pasteboard") {
            arguments += ["--pasteboard", pasteboard]
        }

        return workflowPreflightResult(
            operation: "inspect-clipboard",
            risk: "low",
            mutates: false,
            prerequisites: [],
            blockers: [],
            nextCommand: workflowDisplayCommand(arguments),
            nextArguments: arguments
        )
    }

    private func workflowPreflightReadClipboard() -> WorkflowPreflight {
        var prerequisites: [DoctorCheck] = []
        var maxCharacters = 4_096

        if let rawMaxCharacters = option("--max-characters") {
            if let parsed = Int(rawMaxCharacters) {
                maxCharacters = max(0, parsed)
            } else {
                prerequisites.append(DoctorCheck(
                    name: "workflow.clipboardMaxCharacters",
                    status: "fail",
                    required: true,
                    message: "--max-characters must be an integer.",
                    remediation: "Pass a non-negative integer with `--max-characters N`."
                ))
            }
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty {
            var arguments = [
                "Ln1", "clipboard", "read-text",
                "--allow-risk", "medium",
                "--max-characters", String(maxCharacters),
                "--reason", "Inspect clipboard text"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            if let pasteboard = option("--pasteboard") {
                arguments += ["--pasteboard", pasteboard]
            }
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "read-clipboard",
            risk: "medium",
            mutates: false,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightWriteClipboard() -> WorkflowPreflight {
        var prerequisites = [doctorAuditLogCheck()]
        let text = option("--text")

        if text == nil {
            prerequisites.append(DoctorCheck(
                name: "workflow.text",
                status: "fail",
                required: true,
                message: "No text was provided for write-clipboard.",
                remediation: "Pass `--text TEXT`."
            ))
        }

        let blockers = workflowBlockers(from: prerequisites)
        let nextArguments: [String]?
        if blockers.isEmpty, let text {
            var arguments = [
                "Ln1", "clipboard", "write-text",
                "--text", text,
                "--allow-risk", "medium"
            ]
            if let auditLog = option("--audit-log") {
                arguments += ["--audit-log", auditLog]
            }
            if let pasteboard = option("--pasteboard") {
                arguments += ["--pasteboard", pasteboard]
            }
            arguments += ["--reason", "Describe intent"]
            nextArguments = arguments
        } else {
            nextArguments = nil
        }

        return workflowPreflightResult(
            operation: "write-clipboard",
            risk: "medium",
            mutates: true,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextArguments.map(workflowDisplayCommand) ?? workflowRemediationCommand(for: prerequisites),
            nextArguments: nextArguments
        )
    }

    private func workflowPreflightResult(
        operation: String,
        risk: String,
        mutates: Bool,
        prerequisites: [DoctorCheck],
        blockers: [String],
        nextCommand: String?,
        nextArguments: [String]?
    ) -> WorkflowPreflight {
        WorkflowPreflight(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            operation: operation,
            risk: risk,
            mutates: mutates,
            canProceed: blockers.isEmpty,
            prerequisites: prerequisites,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments,
            message: blockers.isEmpty
                ? "\(operation) can proceed with the suggested command."
                : "\(operation) is blocked; resolve required prerequisites first."
        )
    }

    private func workflowBlockers(from prerequisites: [DoctorCheck]) -> [String] {
        prerequisites
            .filter { $0.required && $0.status != "pass" }
            .map(\.name)
    }

    private func workflowRemediationCommand(for prerequisites: [DoctorCheck]) -> String? {
        prerequisites.first { $0.required && $0.status != "pass" }?.remediation
    }

    private func workflowResumePlan(
        latest: [String: Any]?,
        workflowURL: URL,
        operation: String?
    ) throws -> WorkflowResumePlan {
        guard let latest else {
            let nextArguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
            return WorkflowResumePlan(
                path: workflowURL.path,
                operation: operation,
                status: "empty",
                transcriptID: nil,
                latestOperation: nil,
                blockers: [],
                nextCommand: workflowDisplayCommand(nextArguments),
                nextArguments: nextArguments,
                latest: nil,
                message: "No workflow transcript entries matched; start with a fresh observation."
            )
        }

        let transcriptID = latest["transcriptID"] as? String
        let latestOperation = latest["operation"] as? String
        let blockers = latest["blockers"] as? [String] ?? []
        let preflight = latest["preflight"] as? [String: Any]
        let command = latest["command"] as? [String: Any]
        let execution = latest["execution"] as? [String: Any]
        let executed = latest["executed"] as? Bool ?? false
        let wouldExecute = latest["wouldExecute"] as? Bool ?? false
        let timedOut = execution?["timedOut"] as? Bool ?? false
        let exitCode = execution?["exitCode"] as? Int

        let status: String
        let nextCommand: String?
        let nextArguments: [String]?
        let message: String

        if !blockers.isEmpty {
            status = "blocked"
            nextCommand = preflight?["nextCommand"] as? String
            nextArguments = preflight?["nextArguments"] as? [String]
            message = "Latest workflow is blocked; resolve prerequisites before rerunning."
        } else if timedOut {
            status = "timed_out"
            nextArguments = workflowDryRunArguments(for: latestOperation)
            nextCommand = nextArguments.map(workflowDisplayCommand)
            message = "Latest workflow timed out; inspect the dry-run plan or rerun with a larger --run-timeout-ms."
        } else if executed, exitCode == 0 {
            status = "completed"
            if let recommendation = workflowCompletedRecommendation(
                for: latest,
                workflowURL: workflowURL
            ) {
                nextArguments = recommendation.arguments
                nextCommand = workflowDisplayCommand(recommendation.arguments)
                message = recommendation.message
            } else {
                nextArguments = [
                    "Ln1", "workflow", "log",
                    "--workflow-log", workflowURL.path,
                    "--allow-risk", "medium",
                    "--limit", "5"
                ]
                nextCommand = workflowDisplayCommand(nextArguments!)
                message = "Latest workflow completed; inspect recent transcript context before choosing the next operation."
            }
        } else if executed {
            status = "failed"
            nextArguments = workflowDryRunArguments(for: latestOperation)
            nextCommand = nextArguments.map(workflowDisplayCommand)
            message = "Latest workflow executed but returned a nonzero exit code; inspect the dry-run plan before retrying."
        } else if wouldExecute {
            status = "ready"
            nextCommand = command?["display"] as? String
            nextArguments = command?["argv"] as? [String]
            message = "Latest workflow was ready but not executed; review or execute the suggested command."
        } else {
            status = "not_ready"
            nextCommand = preflight?["nextCommand"] as? String
            nextArguments = preflight?["nextArguments"] as? [String]
            message = "Latest workflow was not ready; inspect blockers and preflight output."
        }

        return WorkflowResumePlan(
            path: workflowURL.path,
            operation: operation,
            status: status,
            transcriptID: transcriptID,
            latestOperation: latestOperation,
            blockers: blockers,
            nextCommand: nextCommand,
            nextArguments: nextArguments,
            latest: try JSONValue(any: latest),
            message: message
        )
    }

    private func workflowCompletedRecommendation(
        for latest: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let latestOperation = latest["operation"] as? String
        guard let execution = latest["execution"] as? [String: Any],
              let outputJSON = execution["outputJSON"] as? [String: Any] else {
            return nil
        }

        let endpoint = outputJSON["endpoint"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--endpoint")
            ?? "http://127.0.0.1:9222"

        if latestOperation == "wait-browser-url" {
            return workflowBrowserURLWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-selector" {
            return workflowBrowserSelectorWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-count" {
            return workflowBrowserCountWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-text" {
            return workflowBrowserTextWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-element-text" {
            return workflowBrowserElementTextWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-value" {
            return workflowBrowserValueWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-ready" {
            return workflowBrowserReadyWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-title" {
            return workflowBrowserTitleWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-checked" {
            return workflowBrowserCheckedWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-enabled" {
            return workflowBrowserEnabledWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-focus" {
            return workflowBrowserFocusWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-browser-attribute" {
            return workflowBrowserAttributeWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                endpoint: endpoint,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "review-audit" {
            return workflowAuditReviewRecommendation(outputJSON: outputJSON)
        }
        if latestOperation == "find-element" {
            return workflowAccessibilityElementFindRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-element" {
            return workflowAccessibilityElementInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-menu" {
            return workflowAccessibilityMenuInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "create-directory" {
            return workflowCreateDirectoryRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "duplicate-file" {
            return workflowDestinationFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file duplicate completed and verified; inspect destination metadata before further file operations."
            )
        }
        if latestOperation == "move-file" {
            return workflowDestinationFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file move completed and verified; inspect destination metadata before further file operations."
            )
        }
        if latestOperation == "rollback-file-move" {
            return workflowRollbackFileMoveRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-file" {
            return workflowFileInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "read-file" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file text read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "tail-file" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file tail text read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-lines" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest file line range read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-json" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest JSON file read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "read-file-plist" {
            return workflowFileReadRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL,
                successMessage: "Latest property list file read completed; dry-run a checksum workflow before depending on unchanged contents."
            )
        }
        if latestOperation == "write-file" {
            return workflowWrittenFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file text write completed and verified; inspect current metadata before further file operations."
            )
        }
        if latestOperation == "append-file" {
            return workflowWrittenFileRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                successMessage: "Latest file text append completed and verified; inspect current metadata before further file operations."
            )
        }
        if latestOperation == "list-files" {
            return workflowFileListRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "search-files" {
            return workflowFileSearchRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "checksum-file" {
            return workflowFileChecksumRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "compare-files" {
            return workflowFileCompareRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "watch-file" {
            return workflowFileWatchRecommendation(outputJSON: outputJSON)
        }
        if latestOperation == "wait-file" {
            return workflowFileWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "wait-clipboard" {
            return workflowClipboardWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-process" {
            return workflowProcessWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-window" {
            return workflowWindowWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-active-window" {
            return workflowActiveWindowWaitRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-element" {
            return workflowAccessibilityElementWaitRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-system" {
            let arguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
            return (
                arguments,
                "Latest system context inspection completed; observe current app, process, and desktop state before choosing the next action."
            )
        }
        if latestOperation == "inspect-displays" {
            let arguments = ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"]
            return (
                arguments,
                "Latest display topology inspection completed; observe current app, process, and desktop state before choosing the next action."
            )
        }
        if latestOperation == "inspect-active-window" {
            return workflowActiveDesktopWindowRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-windows" {
            return workflowDesktopWindowsRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-processes" {
            return workflowProcessListRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-apps" {
            return workflowRunningAppsRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-frontmost-app" {
            return workflowFrontmostAppRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "start-task" {
            return workflowTaskStartRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "record-task" || latestOperation == "finish-task" {
            return workflowTaskMemoryRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "wait-active-app" {
            return workflowActiveAppWaitRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "open-file" || latestOperation == "open-url" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-window",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest workspace open completed; inspect the active desktop window before choosing the next action."
            )
        }
        if latestOperation == "minimize-active-window" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-windows",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest active window minimize completed and verified; dry-run desktop window inventory before choosing the next action."
            )
        }
        if latestOperation == "restore-window" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-windows",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest window restore completed and verified; dry-run desktop window inventory before choosing the next action."
            )
        }
        if latestOperation == "raise-window" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-window",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest window raise completed and verified; dry-run active window inspection before choosing the next action."
            )
        }
        if latestOperation == "set-window-frame" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-windows",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest window frame change completed and verified; dry-run desktop window inventory before choosing the next action."
            )
        }
        if latestOperation == "inspect-clipboard" {
            return workflowClipboardInspectRecommendation(
                outputJSON: outputJSON,
                execution: execution,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "read-clipboard" {
            return workflowClipboardReadRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "write-clipboard" {
            return workflowClipboardWriteRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "set-element-value" {
            return workflowSetElementValueRecommendation(
                outputJSON: outputJSON,
                execution: execution
            )
        }
        if latestOperation == "inspect-process" {
            return workflowProcessInspectRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "inspect-installed-apps" {
            return workflowInstalledAppsRecommendation(
                outputJSON: outputJSON,
                workflowURL: workflowURL
            )
        }
        if latestOperation == "activate-app" || latestOperation == "launch-app" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            let action = latestOperation == "launch-app" ? "launch" : "activation"
            return (
                arguments,
                "Latest app \(action) completed and verified; dry-run active app inspection before choosing the next UI action."
            )
        }
        if latestOperation == "hide-app" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-apps",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest app hide completed and verified; dry-run running app inspection before choosing the next action."
            )
        }
        if latestOperation == "unhide-app" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-apps",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest app unhide completed and verified; dry-run running app inspection before choosing the next action."
            )
        }
        if latestOperation == "quit-app" {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-apps",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest app quit completed and verified; dry-run running app inspection before choosing the next action."
            )
        }

        guard latestOperation == "read-browser" else {
            return nil
        }

        if let domRecommendation = workflowBrowserDOMRecommendation(
            outputJSON: outputJSON,
            execution: execution,
            endpoint: endpoint
        ) {
            return domRecommendation
        }

        guard
              let tabs = outputJSON["tabs"] as? [[String: Any]],
              let firstTab = tabs.first,
              let tabID = firstTab["id"] as? String else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
        )
    }

    private func workflowAuditReviewRecommendation(
        outputJSON: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard let entries = outputJSON["entries"] as? [[String: Any]],
              let entry = entries.first,
              let auditID = entry["id"] as? String,
              entry["command"] as? String == "files.move",
              let outcome = entry["outcome"] as? [String: Any],
              outcome["ok"] as? Bool == true,
              outcome["code"] as? String == "moved" else {
            return nil
        }

        var arguments = [
            "Ln1", "workflow", "preflight",
            "--operation", "rollback-file-move",
            "--audit-id", auditID
        ]
        if let auditLogPath = outputJSON["path"] as? String {
            arguments += ["--audit-log", auditLogPath]
        }

        return (
            arguments: arguments,
            message: "Latest audit review found a successful file move; dry-run rollback preflight before deciding whether to restore it."
        )
    }

    private func workflowTaskStartRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let taskID = outputJSON["taskID"] as? String else {
            return nil
        }

        var arguments = [
            "Ln1", "workflow", "run",
            "--operation", "record-task",
            "--task-id", taskID,
            "--kind", "observation",
            "--summary", "Describe next observation",
            "--allow-risk", "medium",
            "--dry-run", "true",
            "--workflow-log", workflowURL.path
        ]
        if let memoryLog = outputJSON["path"] as? String {
            arguments += ["--memory-log", memoryLog]
        }

        return (
            arguments,
            "Latest task memory start completed; dry-run recording the next observation against the concrete task ID."
        )
    }

    private func workflowRunningAppsRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let activeApp = outputJSON["activeApp"] as? [String: Any]
        let apps = outputJSON["apps"] as? [[String: Any]] ?? []
        let selected = activeApp ?? apps.first

        if selected?["active"] as? Bool == true {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-active-app",
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest running app inventory found the active app; dry-run active app inspection before choosing the next UI action."
            )
        }

        if let pid = selected?["pid"] as? Int {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(pid),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest running app inventory completed; dry-run process inspection for a concrete app pid before choosing the next action."
            )
        }

        return nil
    }

    private func workflowFrontmostAppRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["found"] as? Bool == true,
              let app = outputJSON["app"] as? [String: Any],
              let pid = app["pid"] as? Int else {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-apps",
                    "--limit", "20",
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest frontmost app inspection found no active app; dry-run running app inventory before choosing the next step."
            )
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-process",
                "--pid", String(pid),
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest frontmost app inspection completed; dry-run process inspection before choosing UI or app actions."
        )
    }

    private func workflowTaskMemoryRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let taskID = outputJSON["taskID"] as? String else {
            return nil
        }

        var arguments = [
            "Ln1", "workflow", "run",
            "--operation", "show-task",
            "--task-id", taskID,
            "--allow-risk", "medium",
            "--limit", "20",
            "--dry-run", "true",
            "--workflow-log", workflowURL.path
        ]
        if let memoryLog = outputJSON["path"] as? String {
            arguments += ["--memory-log", memoryLog]
        }

        return (
            arguments,
            "Latest task memory update completed; dry-run reading the task memory so the next step is grounded in persisted context."
        )
    }

    private func workflowFileInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let root = outputJSON["root"] as? [String: Any],
              let path = root["path"] as? String
                ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        if root["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file inspection found a directory; list immediate children before acting."
            )
        }

        if root["kind"] as? String == "regularFile", root["readable"] as? Bool == true {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "checksum-file",
                    "--path", path,
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest file inspection found a readable file; dry-run a checksum workflow before depending on contents."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file inspection completed; re-check metadata before choosing a mutating operation."
        )
    }

    private func workflowFileListRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let entries = outputJSON["entries"] as? [[String: Any]]
        let root = outputJSON["root"] as? [String: Any]
        let selectedPath = entries?.first?["path"] as? String
            ?? root?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path")
        guard let selectedPath else {
            return nil
        }

        let message = entries?.isEmpty == false
            ? "Latest file listing completed; dry-run inspection for the first listed path."
            : "Latest file listing was empty; dry-run inspection for the listed directory."
        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-file",
                "--path", selectedPath,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: message
        )
    }

    private func workflowFileReadRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL,
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        let file = outputJSON["file"] as? [String: Any]
        guard let path = file?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "checksum-file",
                "--path", path,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: successMessage
        )
    }

    private func workflowWrittenFileRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let current = outputJSON["current"] as? [String: Any]
        guard let path = current?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: successMessage
        )
    }

    private func workflowFileSearchRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let matches = outputJSON["matches"] as? [[String: Any]]
        let firstFile = matches?.first?["file"] as? [String: Any]
        let root = outputJSON["root"] as? [String: Any]
        guard let selectedPath = firstFile?["path"] as? String
            ?? root?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-file",
                "--path", selectedPath,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: matches?.isEmpty == false
                ? "Latest file search completed; dry-run inspection for the first matched file."
                : "Latest file search found no matches; dry-run inspection for the search root."
        )
    }

    private func workflowFileChecksumRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let file = outputJSON["file"] as? [String: Any]
        guard let path = file?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path"),
              let digest = outputJSON["digest"] as? String,
              isSHA256HexDigest(digest) else {
            return nil
        }

        let algorithm = outputJSON["algorithm"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--algorithm")
            ?? "sha256"
        let maxFileBytes = (outputJSON["maxFileBytes"] as? Int).map(String.init)
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--max-file-bytes")
            ?? "104857600"

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "wait-file",
                "--path", path,
                "--exists", "true",
                "--digest", digest.lowercased(),
                "--algorithm", algorithm,
                "--max-file-bytes", maxFileBytes,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest file checksum completed; dry-run a digest wait before depending on this file state."
        )
    }

    private func workflowFileCompareRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let right = outputJSON["right"] as? [String: Any]
        guard let rightPath = right?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--to") else {
            return nil
        }

        let matched = outputJSON["matched"] as? Bool == true
        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", rightPath
            ],
            message: matched
                ? "Latest file compare matched; inspect right-side metadata before depending on the file."
                : "Latest file compare found a difference; inspect right-side metadata before choosing the next file operation."
        )
    }

    private func workflowFileWatchRecommendation(
        outputJSON: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["matched"] as? Bool == true,
              let events = outputJSON["events"] as? [[String: Any]],
              let event = events.first,
              let eventType = event["type"] as? String,
              let path = event["path"] as? String else {
            return nil
        }

        if eventType == "deleted" {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", parent,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file watch observed a deletion; list the parent directory before choosing the next file operation."
            )
        }

        let current = event["current"] as? [String: Any]
        if current?["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file watch observed a directory event; list immediate children before acting."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file watch observed a file event; inspect current metadata before acting."
        )
    }

    private func workflowRollbackFileMoveRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let restoredSource = outputJSON["restoredSource"] as? [String: Any]
        guard let restoredPath = restoredSource?["path"] as? String else {
            return nil
        }
        let arguments = [
            "Ln1", "files", "stat",
            "--path", restoredPath
        ]

        return (
            arguments: arguments,
            message: "Latest file move rollback completed and verified; inspect restored source metadata before further file operations."
        )
    }

    private func workflowCreateDirectoryRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let directory = outputJSON["directory"] as? [String: Any]
        guard let directoryPath = directory?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", directoryPath
            ],
            message: "Latest directory creation completed and verified; inspect directory metadata before further file operations."
        )
    }

    private func workflowDestinationFileRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        successMessage: String
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["ok"] as? Bool == true else {
            return nil
        }
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        let destination = outputJSON["destination"] as? [String: Any]
        guard let destinationPath = destination?["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--to") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", destinationPath
            ],
            message: successMessage
        )
    }

    private func workflowFileWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["matched"] as? Bool == true else {
            return nil
        }
        guard let path = outputJSON["path"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--path") else {
            return nil
        }

        let expectedExists = outputJSON["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true

        if !expectedExists {
            let parent = URL(fileURLWithPath: path).deletingLastPathComponent().path
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", parent,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file wait confirmed the path is absent; list the parent directory to choose the next file operation."
            )
        }

        let file = outputJSON["file"] as? [String: Any]
        if file?["kind"] as? String == "directory" {
            return (
                arguments: [
                    "Ln1", "files", "list",
                    "--path", path,
                    "--depth", "1",
                    "--limit", "50"
                ],
                message: "Latest file wait found the expected directory; list immediate children before acting."
            )
        }

        return (
            arguments: [
                "Ln1", "files", "stat",
                "--path", path
            ],
            message: "Latest file wait found the expected path and metadata; inspect current file metadata before acting."
        )
    }

    private func workflowClipboardInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let pasteboard = outputJSON["pasteboard"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        let hasString = outputJSON["hasString"] as? Bool

        if hasString == true {
            var arguments = [
                "Ln1", "workflow", "run",
                "--operation", "read-clipboard",
                "--max-characters", "4096",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            if let pasteboard, pasteboard != "general" {
                arguments += ["--pasteboard", pasteboard]
            }
            return (
                arguments: arguments,
                message: "Latest clipboard inspection found plain text metadata; dry-run bounded clipboard text reading before using clipboard contents."
            )
        }

        var arguments = [
            "Ln1", "clipboard", "wait",
            "--has-string", "true",
            "--timeout-ms", "5000",
            "--interval-ms", "100"
        ]
        if let changeCount = outputJSON["changeCount"] as? Int {
            arguments += ["--changed-from", String(changeCount)]
        }
        if let pasteboard, pasteboard != "general" {
            arguments += ["--pasteboard", pasteboard]
        }
        return (
            arguments: arguments,
            message: "Latest clipboard inspection found no plain text; wait for text metadata before reading."
        )
    }

    private func workflowClipboardWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        let pasteboard = workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        let current = verification["current"] as? [String: Any]
        let hasString = current?["hasString"] as? Bool
        var arguments: [String]

        if hasString == true {
            arguments = [
                "Ln1", "workflow", "run",
                "--operation", "read-clipboard",
                "--max-characters", "4096",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            if let pasteboard {
                arguments.append(contentsOf: ["--pasteboard", pasteboard])
            }
            return (
                arguments: arguments,
                message: "Latest clipboard wait found plain text metadata; dry-run bounded clipboard text reading before using clipboard contents."
            )
        }

        arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard {
            arguments.append(contentsOf: ["--pasteboard", pasteboard])
        }
        return (
            arguments: arguments,
            message: "Latest clipboard wait completed without plain text; inspect clipboard metadata before choosing the next operation."
        )
    }

    private func workflowClipboardReadRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let pasteboard = outputJSON["pasteboard"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        var arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard, pasteboard != "general" {
            arguments += ["--pasteboard", pasteboard]
        }
        return (
            arguments: arguments,
            message: "Latest clipboard text read completed; inspect clipboard metadata before depending on unchanged contents."
        )
    }

    private func workflowClipboardWriteRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let pasteboard = outputJSON["pasteboard"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pasteboard")
        var arguments = ["Ln1", "clipboard", "state"]
        if let pasteboard, pasteboard != "general" {
            arguments += ["--pasteboard", pasteboard]
        }
        return (
            arguments: arguments,
            message: "Latest clipboard write completed and verified; inspect clipboard metadata before using the pasted value."
        )
    }

    private func workflowBrowserURLWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let verification = outputJSON["verification"] as? [String: Any]
        guard verification?["ok"] as? Bool == true else {
            return nil
        }

        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser URL wait completed; dry-run DOM inspection for the arrived page."
        )
    }

    private func workflowBrowserSelectorWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }
        guard let selector = outputJSON["selector"] as? String
            ?? verification["selector"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--selector") else {
            return nil
        }

        if workflowSelectorWaitAcceptsText(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "fill",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--text", "Describe text",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready text field; fill it by selector after replacing the text and reason."
            )
        }

        if workflowSelectorWaitAcceptsSelect(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "select",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--value", "Describe value",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready select control; choose an option by value after replacing the value and reason."
            )
        }

        if workflowSelectorWaitAcceptsCheckedState(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "check",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--checked", "true",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready checkbox or radio input; set its checked state after confirming intent."
            )
        }

        if workflowSelectorWaitCanClick(verification) {
            return (
                arguments: [
                    "Ln1", "browser", "click",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser selector wait found a ready actionable element; click it by selector after confirming intent."
            )
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser selector wait completed; dry-run DOM inspection to choose the next action."
        )
    }

    private func workflowBrowserCountWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser count wait completed; dry-run DOM inspection for the matched collection state."
        )
    }

    private func workflowBrowserTextWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser text wait completed; dry-run DOM inspection for the matched page state."
        )
    }

    private func workflowBrowserElementTextWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser element text wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowBrowserValueWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser value wait completed; dry-run DOM inspection for the matched field state."
        )
    }

    private func workflowBrowserReadyWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser ready-state wait completed; dry-run DOM inspection for the loaded page state."
        )
    }

    private func workflowBrowserTitleWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser title wait completed; dry-run DOM inspection for the matched page."
        )
    }

    private func workflowBrowserCheckedWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser checked-state wait completed; dry-run DOM inspection for the matched form state."
        )
    }

    private func workflowBrowserEnabledWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }
        guard let selector = outputJSON["selector"] as? String
            ?? verification["selector"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--selector") else {
            return nil
        }

        if verification["currentEnabled"] as? Bool == true {
            if workflowSelectorWaitAcceptsText(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "fill",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--text", "Describe text",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled text field; fill it by selector after replacing the text and reason."
                )
            }

            if workflowSelectorWaitAcceptsSelect(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "select",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--value", "Describe value",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled select control; choose an option by value after replacing the value and reason."
                )
            }

            if workflowSelectorWaitAcceptsCheckedState(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "check",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--checked", "true",
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled checkbox or radio input; set its checked state after confirming intent."
                )
            }

            if workflowSelectorWaitCanClick(verification) {
                return (
                    arguments: [
                        "Ln1", "browser", "click",
                        "--endpoint", endpoint,
                        "--id", tabID,
                        "--selector", selector,
                        "--allow-risk", "medium",
                        "--reason", "Describe intent"
                    ],
                    message: "Latest browser enabled-state wait found an enabled actionable element; click it by selector after confirming intent."
                )
            }
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser enabled-state wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowBrowserFocusWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser focus wait completed; dry-run DOM inspection for the focused element state."
        )
    }

    private func workflowBrowserAttributeWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String,
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true else {
            return nil
        }
        guard let tabID = outputJSON["tabID"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "read-browser",
                "--endpoint", endpoint,
                "--id", tabID,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest browser attribute wait completed; dry-run DOM inspection for the matched element state."
        )
    }

    private func workflowInstalledAppsRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let apps = outputJSON["apps"] as? [[String: Any]],
              let firstApp = apps.first,
              let bundleIdentifier = firstApp["bundleIdentifier"] as? String else {
            return nil
        }

        return (
            [
                "Ln1", "workflow", "run",
                "--operation", "launch-app",
                "--bundle-id", bundleIdentifier,
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            "Latest installed app inventory completed; dry-run launch planning for the first discovered app."
        )
    }

    private func workflowProcessInspectRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard outputJSON["found"] as? Bool == true,
              let process = outputJSON["process"] as? [String: Any] else {
            return (
                ["Ln1", "processes", "--limit", "50"],
                "Latest process inspection found no process; list current process metadata before choosing the next step."
            )
        }

        if process["activeApp"] as? Bool == true {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest process inspection is the active app process; dry-run active app inspection before choosing a UI action."
            )
        }

        if let bundleIdentifier = process["bundleIdentifier"] as? String {
            let arguments = [
                "Ln1", "workflow", "run",
                "--operation", "activate-app",
                "--bundle-id", bundleIdentifier,
                "--allow-risk", "medium",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ]
            return (
                arguments,
                "Latest process inspection found a GUI app process; dry-run activation before inspecting or controlling it."
            )
        }

        return (
            ["Ln1", "processes", "--limit", "50"],
            "Latest process inspection completed; list process metadata before selecting another structured action."
        )
    }

    private func workflowProcessWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any] else {
            return nil
        }

        let pid = verification["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true
        let matched = verification["matched"] as? Bool == true
        let ok = verification["ok"] as? Bool == true

        if ok, matched, expectedExists, let pid {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(pid),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest process wait confirmed the pid exists; dry-run process inspection before choosing the next app or process action."
            )
        }

        if ok, matched, !expectedExists {
            return (
                arguments: ["Ln1", "processes", "--limit", "50"],
                message: "Latest process wait confirmed the pid is absent; list current process metadata before choosing the next step."
            )
        }

        if let pid {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "wait-process",
                    "--pid", String(pid),
                    "--exists", String(expectedExists),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest process wait completed without matching; dry-run another bounded wait before retrying."
            )
        }

        return nil
    }

    private func workflowWindowWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any] else {
            return nil
        }

        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true
        let matched = verification["matched"] as? Bool == true
        let ok = verification["ok"] as? Bool == true
        let current = verification["current"] as? [[String: Any]] ?? []

        if ok, matched, expectedExists, let window = current.first {
            if window["active"] as? Bool == true {
                return (
                    arguments: [
                        "Ln1", "workflow", "run",
                        "--operation", "inspect-active-app",
                        "--dry-run", "true",
                        "--workflow-log", workflowURL.path
                    ],
                    message: "Latest desktop window wait found a window owned by the active app; dry-run active app inspection before choosing a UI action."
                )
            }

            if let ownerPID = window["ownerPID"] as? Int {
                return (
                    arguments: [
                        "Ln1", "workflow", "run",
                        "--operation", "inspect-process",
                        "--pid", String(ownerPID),
                        "--dry-run", "true",
                        "--workflow-log", workflowURL.path
                    ],
                    message: "Latest desktop window wait found a visible window; dry-run owner process inspection before choosing the next app or UI action."
                )
            }
        }

        if ok, matched, !expectedExists {
            return (
                arguments: ["Ln1", "desktop", "windows", "--limit", "50"],
                message: "Latest desktop window wait confirmed the matching window is absent; list current desktop windows before choosing the next step."
            )
        }

        let retryArguments = workflowWindowWaitRetryArguments(from: execution["argv"] as? [String], workflowURL: workflowURL)
        if let retryArguments {
            return (
                arguments: retryArguments,
                message: "Latest desktop window wait completed without matching; dry-run another bounded wait before retrying."
            )
        }

        return (
            arguments: ["Ln1", "desktop", "windows", "--limit", "50"],
            message: "Latest desktop window wait completed; list current desktop windows before choosing the next step."
        )
    }

    private func workflowDesktopWindowsRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let windows = outputJSON["windows"] as? [[String: Any]] ?? []

        if windows.contains(where: { $0["active"] as? Bool == true }) {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-active-app",
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest desktop window inventory found an active-owner window; dry-run active app inspection before choosing a UI action."
            )
        }

        if let firstWindow = windows.first,
           let ownerPID = firstWindow["ownerPID"] as? Int {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(ownerPID),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest desktop window inventory found visible windows; dry-run owner process inspection before choosing the next app or UI action."
            )
        }

        return (
            arguments: ["Ln1", "observe", "--app-limit", "20", "--window-limit", "20"],
            message: "Latest desktop window inventory completed without visible windows; observe current app, process, and desktop state before choosing the next action."
        )
    }

    private func workflowActiveDesktopWindowRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        if outputJSON["found"] as? Bool == true,
           let window = outputJSON["window"] as? [String: Any],
           let ownerPID = window["ownerPID"] as? Int {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(ownerPID),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest active window inspection found a frontmost window; dry-run owner process inspection before choosing UI or app actions."
            )
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-windows",
                "--limit", "20",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest active window inspection found no frontmost window; dry-run visible window inventory before choosing the next step."
        )
    }

    private func workflowActiveWindowWaitRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let verification = outputJSON["verification"] as? [String: Any]
        let matched = verification?["matched"] as? Bool ?? false
        if matched,
           let current = verification?["current"] as? [String: Any],
           let ownerPID = current["ownerPID"] as? Int {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-process",
                    "--pid", String(ownerPID),
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest active window wait matched; dry-run owner process inspection before choosing UI or app actions."
            )
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-window",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest active window wait did not match; dry-run frontmost window inspection before retrying or choosing another target."
        )
    }

    private func workflowProcessListRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let processes = outputJSON["processes"] as? [[String: Any]] ?? []
        let target = processes.first { $0["activeApp"] as? Bool == true } ?? processes.first
        guard let pid = target?["pid"] as? Int else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-process",
                "--pid", String(pid),
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest process inventory completed; dry-run inspection of a concrete process before choosing the next app, window, or UI action."
        )
    }

    private func workflowWindowWaitRetryArguments(from arguments: [String]?, workflowURL: URL) -> [String]? {
        guard let arguments else {
            return nil
        }

        var retry = ["Ln1", "workflow", "run", "--operation", "wait-window"]
        for optionName in ["--id", "--owner-pid", "--bundle-id", "--title", "--match", "--exists", "--limit"] {
            guard let value = workflowArgumentValue(in: arguments, for: optionName) else {
                continue
            }
            retry += [optionName, value]
        }
        if let timeout = workflowArgumentValue(in: arguments, for: "--timeout-ms") {
            retry += ["--wait-timeout-ms", timeout]
        }
        if let interval = workflowArgumentValue(in: arguments, for: "--interval-ms") {
            retry += ["--interval-ms", interval]
        }
        if arguments.contains("--include-desktop") {
            retry.append("--include-desktop")
        }
        if arguments.contains("--all-layers") {
            retry.append("--all-layers")
        }
        retry += ["--dry-run", "true", "--workflow-log", workflowURL.path]
        return retry
    }

    private func workflowAccessibilityElementWaitRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let expectedExists = verification["expectedExists"] as? Bool
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--exists").map(parseBool)
            ?? true

        guard expectedExists else {
            var arguments = ["Ln1", "state", "--depth", "2", "--max-children", "80"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            return (
                arguments: arguments,
                message: "Latest Accessibility element wait confirmed the matching state is absent; inspect current UI state before choosing the next action."
            )
        }

        guard let current = verification["current"] as? [String: Any],
              let elementID = current["id"] as? String else {
            return nil
        }

        let stableIdentity = current["stableIdentity"] as? [String: Any]
        let expectedIdentity = stableIdentity?["id"] as? String
        let enabled = current["enabled"] as? Bool
        let actions = current["actions"] as? [String] ?? []
        let settableAttributes = current["settableAttributes"] as? [String] ?? []
        if enabled != false, actions.contains(kAXPressAction as String) {
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", kAXPressAction as String,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element wait matched an enabled pressable element; perform a guarded press after replacing the reason."
            )
        }
        if enabled != false, settableAttributes.contains(kAXValueAttribute as String) || current["valueSettable"] as? Bool == true {
            var arguments = ["Ln1", "workflow", "run", "--operation", "set-element-value"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--value", "Replace value",
                "--dry-run", "true"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element wait matched a settable value element; dry-run a guarded value update after replacing the value."
            )
        }

        var arguments = ["Ln1", "state", "--depth", "2", "--max-children", "80"]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        return (
            arguments: arguments,
            message: "Latest Accessibility element wait matched; inspect current UI state before choosing the next action."
        )
    }

    private func workflowAccessibilityElementInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        guard let element = outputJSON["element"] as? [String: Any],
              let elementID = element["id"] as? String else {
            return nil
        }

        let stableIdentity = element["stableIdentity"] as? [String: Any]
        let expectedIdentity = stableIdentity?["id"] as? String
        let enabled = element["enabled"] as? Bool
        let actions = element["actions"] as? [String] ?? []
        let settableAttributes = element["settableAttributes"] as? [String] ?? []
        if enabled != false, actions.contains(kAXPressAction as String) {
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", kAXPressAction as String,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element inspection found an enabled pressable element; perform a guarded press after replacing the reason."
            )
        }
        if enabled != false, settableAttributes.contains(kAXValueAttribute as String) || element["valueSettable"] as? Bool == true {
            var arguments = ["Ln1", "workflow", "run", "--operation", "set-element-value"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--value", "Replace value",
                "--dry-run", "true"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility element inspection found a settable value element; dry-run a guarded value update after replacing the value."
            )
        }

        var arguments = ["Ln1", "state", "element", "--element", elementID, "--depth", "1", "--max-children", "20"]
        if let pid {
            arguments.insert(contentsOf: ["--pid", String(pid)], at: 3)
        }
        return (
            arguments: arguments,
            message: "Latest Accessibility element inspection completed; re-inspect the element or inspect broader UI state before choosing the next action."
        )
    }

    private func workflowAccessibilityElementFindRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
        let matches = outputJSON["matches"] as? [[String: Any]] ?? []
        guard let first = matches.first,
              let elementID = first["id"] as? String else {
            return (
                arguments: [
                    "Ln1", "workflow", "run",
                    "--operation", "inspect-active-app",
                    "--dry-run", "true",
                    "--workflow-log", workflowURL.path
                ],
                message: "Latest Accessibility element search found no matches; dry-run active app inspection before refining the query."
            )
        }

        var arguments = [
            "Ln1", "workflow", "run",
            "--operation", "inspect-element"
        ]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        arguments += ["--element", elementID]
        if let stableIdentity = first["stableIdentity"] as? [String: Any],
           let expectedIdentity = stableIdentity["id"] as? String {
            arguments += [
                "--expect-identity", expectedIdentity,
                "--min-identity-confidence", "medium"
            ]
        }
        arguments += [
            "--depth", "1",
            "--max-children", "20",
            "--dry-run", "true",
            "--workflow-log", workflowURL.path
        ]

        return (
            arguments: arguments,
            message: "Latest Accessibility element search found a candidate; dry-run element inspection before choosing a guarded action."
        )
    }

    private func workflowAccessibilityMenuInspectRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let app = outputJSON["app"] as? [String: Any]
        let pid = app?["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        let menuBar = outputJSON["menuBar"] as? [String: Any]
        let hasMenuChildren = (menuBar?["children"] as? [[String: Any]])?.isEmpty == false

        if let menuBar,
           let candidate = workflowAccessibilityActionCandidate(
                in: menuBar,
                preferredActions: [
                    kAXShowMenuAction as String,
                    kAXPressAction as String
                ]
           ),
           let elementID = candidate.element["id"] as? String {
            let stableIdentity = candidate.element["stableIdentity"] as? [String: Any]
            let expectedIdentity = stableIdentity?["id"] as? String
            var arguments = ["Ln1", "perform"]
            if let pid {
                arguments += ["--pid", String(pid)]
            }
            arguments += ["--element", elementID]
            if let expectedIdentity {
                arguments += [
                    "--expect-identity", expectedIdentity,
                    "--min-identity-confidence", "medium"
                ]
            }
            arguments += [
                "--action", candidate.action,
                "--allow-risk", "low",
                "--reason", "Describe intent"
            ]
            return (
                arguments: arguments,
                message: "Latest Accessibility menu inspection found an enabled actionable menu element; perform a guarded menu action after replacing the reason."
            )
        }

        var arguments = ["Ln1", "state", "--depth", "3", "--max-children", "80"]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        return (
            arguments: arguments,
            message: hasMenuChildren
                ? "Latest Accessibility menu inspection found menu items; inspect the target app UI state before choosing a trusted action."
                : "Latest Accessibility menu inspection completed without menu items; inspect the target app UI state before choosing the next action."
        )
    }

    private func workflowSetElementValueRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any]
    ) -> (arguments: [String], message: String)? {
        let pid = outputJSON["pid"] as? Int
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--pid").flatMap(Int.init)
        guard let elementID = outputJSON["element"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--element") else {
            return nil
        }

        let stableIdentity = outputJSON["stableIdentity"] as? [String: Any]
        let expectedIdentity = stableIdentity?["id"] as? String

        var arguments = ["Ln1", "workflow", "run", "--operation", "inspect-element"]
        if let pid {
            arguments += ["--pid", String(pid)]
        }
        arguments += ["--element", elementID]
        if let expectedIdentity {
            arguments += [
                "--expect-identity", expectedIdentity,
                "--min-identity-confidence", "medium"
            ]
        }
        arguments += [
            "--depth", "1",
            "--max-children", "20",
            "--dry-run", "true"
        ]

        return (
            arguments: arguments,
            message: "Latest Accessibility value update completed and verified; dry-run element inspection before choosing the next UI action."
        )
    }

    private func workflowAccessibilityActionCandidate(
        in element: [String: Any],
        preferredActions: [String]
    ) -> (element: [String: Any], action: String)? {
        let enabled = element["enabled"] as? Bool
        let actions = element["actions"] as? [String] ?? []
        if enabled != false {
            for action in preferredActions where actions.contains(action) {
                return (element: element, action: action)
            }
        }

        let children = element["children"] as? [[String: Any]] ?? []
        for child in children {
            if let candidate = workflowAccessibilityActionCandidate(
                in: child,
                preferredActions: preferredActions
            ) {
                return candidate
            }
        }

        return nil
    }

    private func workflowActiveAppWaitRecommendation(
        outputJSON: [String: Any],
        workflowURL: URL
    ) -> (arguments: [String], message: String)? {
        guard let verification = outputJSON["verification"] as? [String: Any],
              verification["ok"] as? Bool == true,
              verification["matched"] as? Bool == true else {
            return nil
        }

        return (
            arguments: [
                "Ln1", "workflow", "run",
                "--operation", "inspect-active-app",
                "--dry-run", "true",
                "--workflow-log", workflowURL.path
            ],
            message: "Latest active app wait matched; dry-run active app inspection before choosing the next UI action."
        )
    }

    private func workflowBrowserDOMRecommendation(
        outputJSON: [String: Any],
        execution: [String: Any],
        endpoint: String
    ) -> (arguments: [String], message: String)? {
        guard let elements = outputJSON["elements"] as? [[String: Any]], !elements.isEmpty else {
            return nil
        }
        let tab = outputJSON["tab"] as? [String: Any]
        guard let tabID = tab?["id"] as? String
            ?? workflowArgumentValue(in: execution["argv"] as? [String], for: "--id") else {
            return nil
        }

        if let fillTarget = elements.first(where: workflowDOMElementAcceptsText),
           let selector = fillTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "fill",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--text", "Describe text",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a text field; fill it by selector after replacing the text and reason."
            )
        }

        if let selectTarget = elements.first(where: workflowDOMElementAcceptsSelect),
           let selector = selectTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "select",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--value", "Describe value",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a select control; choose an option by value after replacing the value and reason."
            )
        }

        if let checkedTarget = elements.first(where: workflowDOMElementAcceptsCheckedState),
           let selector = checkedTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "check",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--checked", "true",
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found a checkbox or radio input; set its checked state after confirming intent."
            )
        }

        if let clickTarget = elements.first(where: workflowDOMElementCanClick),
           let selector = clickTarget["selector"] as? String {
            return (
                arguments: [
                    "Ln1", "browser", "click",
                    "--endpoint", endpoint,
                    "--id", tabID,
                    "--selector", selector,
                    "--allow-risk", "medium",
                    "--reason", "Describe intent"
                ],
                message: "Latest browser DOM inspection found an actionable element; click it by selector after confirming intent."
            )
        }

        return nil
    }

    private func workflowDOMElementAcceptsText(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        let tagName = element["tagName"] as? String
        let role = element["role"] as? String
        let inputType = element["inputType"] as? String
        if tagName == "textarea" || role == "textbox" {
            return workflowInputTypeAcceptsText(inputType)
        }
        return tagName == "input" && workflowInputTypeAcceptsText(inputType)
    }

    private func workflowDOMElementAcceptsSelect(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        return element["tagName"] as? String == "select"
    }

    private func workflowDOMElementAcceptsCheckedState(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        guard element["tagName"] as? String == "input" else {
            return false
        }
        let inputType = element["inputType"] as? String
        return inputType == "checkbox" || inputType == "radio"
    }

    private func workflowInputTypeAcceptsText(_ inputType: String?) -> Bool {
        guard let inputType else {
            return true
        }
        switch inputType {
        case "text", "search", "email", "url", "tel", "number":
            return true
        default:
            return false
        }
    }

    private func workflowDOMElementCanClick(_ element: [String: Any]) -> Bool {
        guard let selector = element["selector"] as? String, !selector.isEmpty else {
            return false
        }
        if element["disabled"] as? Bool == true {
            return false
        }
        let tagName = element["tagName"] as? String
        let role = element["role"] as? String
        let attributes = element["attributes"] as? [String: Any]
        return role == "button"
            || role == "link"
            || tagName == "button"
            || tagName == "a"
            || attributes?["href"] != nil
    }

    private func workflowSelectorWaitAcceptsText(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true || verification["readOnly"] as? Bool == true {
            return false
        }
        let tagName = verification["tagName"] as? String
        let inputType = verification["inputType"] as? String
        if tagName == "textarea" {
            return true
        }
        return tagName == "input" && workflowInputTypeAcceptsText(inputType)
    }

    private func workflowSelectorWaitAcceptsSelect(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true {
            return false
        }
        return verification["tagName"] as? String == "select"
    }

    private func workflowSelectorWaitAcceptsCheckedState(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true || verification["readOnly"] as? Bool == true {
            return false
        }
        guard verification["tagName"] as? String == "input" else {
            return false
        }
        let inputType = verification["inputType"] as? String
        return inputType == "checkbox" || inputType == "radio"
    }

    private func workflowSelectorWaitCanClick(_ verification: [String: Any]) -> Bool {
        if verification["disabled"] as? Bool == true {
            return false
        }
        let tagName = verification["tagName"] as? String
        return tagName == "button"
            || tagName == "a"
            || verification["href"] as? String != nil
    }

    private func workflowArgumentValue(in arguments: [String]?, for option: String) -> String? {
        guard let arguments,
              let index = arguments.firstIndex(of: option) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }
        return arguments[valueIndex]
    }

    private func workflowDryRunArguments(for operation: String?) -> [String]? {
        guard let operation else {
            return nil
        }
        return ["Ln1", "workflow", "run", "--operation", operation, "--dry-run", "true"]
    }

    private func workflowExecutionReason() throws -> String {
        guard let reason = option("--reason")?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reason.isEmpty,
              reason != "Describe intent" else {
            throw CommandError(description: "workflow run mutating execution requires a non-placeholder --reason.")
        }
        return reason
    }

    private func workflowArguments(_ arguments: [String], replacingReasonWith reason: String) throws -> [String] {
        guard let reasonIndex = arguments.firstIndex(of: "--reason") else {
            return arguments + ["--reason", reason]
        }
        let valueIndex = arguments.index(after: reasonIndex)
        guard arguments.indices.contains(valueIndex) else {
            throw CommandError(description: "workflow command argv includes --reason without a value")
        }
        var updatedArguments = arguments
        updatedArguments[valueIndex] = reason
        return updatedArguments
    }

    private func workflowExecute(
        _ command: WorkflowCommand,
        timeoutMilliseconds: Int,
        maxOutputBytes: Int
    ) throws -> WorkflowExecutionResult {
        var childArguments = command.argv
        guard !childArguments.isEmpty else {
            throw CommandError(description: "workflow command argv was empty")
        }
        childArguments.removeFirst()

        let process = Process()
        process.executableURL = try workflowExecutableURL()
        process.arguments = childArguments
        process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        let stdoutCapture = WorkflowOutputCapture(maxOutputBytes: maxOutputBytes)
        let stderrCapture = WorkflowOutputCapture(maxOutputBytes: maxOutputBytes)

        stdout.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            stdoutCapture.append(chunk)
        }
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            stderrCapture.append(chunk)
        }

        let termination = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            termination.signal()
        }

        try process.run()
        let timedOut = termination.wait(timeout: .now() + .milliseconds(timeoutMilliseconds)) == .timedOut
        if timedOut {
            process.terminate()
            if termination.wait(timeout: .now() + .milliseconds(1_000)) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                process.waitUntilExit()
            }
        }

        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        let remainingStdout = stdout.fileHandleForReading.readDataToEndOfFile()
        let remainingStderr = stderr.fileHandleForReading.readDataToEndOfFile()
        stdoutCapture.append(remainingStdout)
        stderrCapture.append(remainingStderr)
        let stdoutSnapshot = stdoutCapture.snapshot()
        let stderrSnapshot = stderrCapture.snapshot()
        let stdoutText = String(data: stdoutSnapshot.data, encoding: .utf8) ?? ""
        let stderrText = String(data: stderrSnapshot.data, encoding: .utf8) ?? ""
        let capturedStdoutBytes = stdoutSnapshot.totalBytes
        let capturedStderrBytes = stderrSnapshot.totalBytes
        let capturedStdoutTruncated = stdoutSnapshot.truncated
        let capturedStderrTruncated = stderrSnapshot.truncated
        let jsonOutput = capturedStdoutTruncated ? nil : try workflowJSONOutput(from: stdoutText)

        return WorkflowExecutionResult(
            argv: command.argv,
            exitCode: process.terminationStatus,
            timeoutMilliseconds: timeoutMilliseconds,
            timedOut: timedOut,
            maxOutputBytes: maxOutputBytes,
            stdout: stdoutText,
            stdoutBytes: capturedStdoutBytes,
            stdoutTruncated: capturedStdoutTruncated,
            stderr: stderrText,
            stderrBytes: capturedStderrBytes,
            stderrTruncated: capturedStderrTruncated,
            outputJSON: jsonOutput
        )
    }

    private func workflowExecutableURL() throws -> URL {
        if let executableURL = Bundle.main.executableURL {
            return executableURL
        }

        let rawPath = CommandLine.arguments.first ?? "Ln1"
        if rawPath.hasPrefix("/") {
            return URL(fileURLWithPath: rawPath)
        }

        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(rawPath)
    }

    private func workflowJSONOutput(from stdout: String) throws -> JSONValue? {
        guard let data = stdout.data(using: .utf8), !data.isEmpty else {
            return nil
        }
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            return try JSONValue(any: object)
        } catch {
            return nil
        }
    }

    private func workflowRunMessage(command: WorkflowCommand?, dryRun: Bool, executed: Bool) -> String {
        guard let command else {
            return "Workflow run is blocked; resolve required prerequisites before execution."
        }
        if dryRun && command.mutates {
            return "Dry run only. This workflow is ready but mutating; review the argv array and provide an explicit reason before executing it outside dry-run mode."
        }
        if dryRun {
            return "Dry run only. This non-mutating workflow is ready to execute with `--dry-run false`."
        }
        if executed {
            return command.mutates
                ? "Workflow executed a mutating command after explicit approval and captured its output."
                : "Workflow executed a non-mutating command and captured its output."
        }
        return "Workflow did not execute."
    }

    private func workflowDisplayCommand(_ arguments: [String]) -> String {
        arguments.map(shellQuotedArgument).joined(separator: " ")
    }

    private func shellQuotedArgument(_ argument: String) -> String {
        if argument.isEmpty {
            return "''"
        }
        if argument.range(of: #"^[A-Za-z0-9_@%+=:,./-]+$"#, options: .regularExpression) != nil {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }

    private func observationBlockers(
        accessibility: TrustRecord,
        desktop: DesktopWindowsState
    ) -> [String] {
        var blockers: [String] = []
        if !accessibility.trusted {
            blockers.append("accessibility_not_trusted")
        }
        if !desktop.available {
            blockers.append("desktop_window_metadata_unavailable")
        }
        if desktop.windows.isEmpty {
            blockers.append("no_visible_windows_reported")
        }
        return blockers
    }

    private func observationSuggestedActions(
        accessibilityTrusted: Bool,
        activePid: pid_t?,
        windowLimit: Int
    ) -> [ObservationAction] {
        var actions = [
            ObservationAction(
                name: "system.context",
                command: "Ln1 system context",
                risk: systemActionRisk(for: "system.context"),
                mutates: false,
                reason: "Inspect OS, host, shell, working directory, and runtime metadata."
            ),
            ObservationAction(
                name: "desktop.listWindows",
                command: "Ln1 desktop windows --limit \(windowLimit)",
                risk: desktopActionRisk(for: "desktop.listWindows"),
                mutates: false,
                reason: "Refresh visible window metadata and stable desktop identities."
            ),
            ObservationAction(
                name: "desktop.activeWindow",
                command: "Ln1 desktop active-window",
                risk: desktopActionRisk(for: "desktop.activeWindow"),
                mutates: false,
                reason: "Inspect the frontmost visible window without screenshots or Accessibility permission."
            ),
            ObservationAction(
                name: "desktop.waitActiveWindow",
                command: "Ln1 desktop wait-active-window --timeout-ms 5000",
                risk: desktopActionRisk(for: "desktop.waitActiveWindow"),
                mutates: false,
                reason: "Wait for the frontmost visible window to match expected structured metadata."
            ),
            ObservationAction(
                name: "desktop.waitWindow",
                command: activePid.map { "Ln1 desktop wait-window --owner-pid \($0) --exists true --timeout-ms 5000" }
                    ?? "Ln1 desktop wait-window --title TITLE --exists true --timeout-ms 5000",
                risk: desktopActionRisk(for: "desktop.waitWindow"),
                mutates: false,
                reason: "Wait for a visible desktop window to appear or disappear using structured metadata."
            ),
            ObservationAction(
                name: "desktop.listDisplays",
                command: "Ln1 desktop displays",
                risk: desktopActionRisk(for: "desktop.listDisplays"),
                mutates: false,
                reason: "Inspect connected display topology, coordinate bounds, scale, and rotation."
            ),
            ObservationAction(
                name: "apps.list",
                command: "Ln1 apps",
                risk: appActionRisk(for: "apps.list"),
                mutates: false,
                reason: "List running GUI apps and identify the active process."
            ),
            ObservationAction(
                name: "apps.active",
                command: "Ln1 apps active",
                risk: appActionRisk(for: "apps.active"),
                mutates: false,
                reason: "Inspect the current frontmost app without Accessibility permission."
            ),
            ObservationAction(
                name: "apps.installed",
                command: "Ln1 apps installed --limit 50",
                risk: appActionRisk(for: "apps.installed"),
                mutates: false,
                reason: "Discover installed app bundle identifiers and paths before launch planning."
            ),
            ObservationAction(
                name: "processes.list",
                command: "Ln1 processes --limit 50",
                risk: processActionRisk(for: "processes.list"),
                mutates: false,
                reason: "List running process metadata without reading command-line arguments."
            ),
            ObservationAction(
                name: "clipboard.state",
                command: "Ln1 clipboard state",
                risk: clipboardActionRisk(for: "clipboard.state"),
                mutates: false,
                reason: "Inspect clipboard metadata without reading clipboard text."
            ),
            ObservationAction(
                name: "clipboard.wait",
                command: "Ln1 clipboard wait --has-string true --timeout-ms 5000",
                risk: clipboardActionRisk(for: "clipboard.wait"),
                mutates: false,
                reason: "Wait for copied text metadata without reading clipboard text."
            ),
            ObservationAction(
                name: "audit.review",
                command: "Ln1 audit --limit 20",
                risk: "low",
                mutates: false,
                reason: "Review recent audited actions and verification outcomes."
            )
        ]

        if accessibilityTrusted {
            let pidArgument = activePid.map { " --pid \($0)" } ?? ""
            actions.append(ObservationAction(
                name: "accessibility.inspectState",
                command: "Ln1 state\(pidArgument) --depth 3 --max-children 80",
                risk: "low",
                mutates: false,
                reason: "Inspect the active app's UI tree with stable element identities."
            ))
            actions.append(ObservationAction(
                name: "accessibility.findElement",
                command: "Ln1 state find\(pidArgument) --title TEXT --limit 20",
                risk: "low",
                mutates: false,
                reason: "Find candidate Accessibility elements by semantic attributes before choosing an action."
            ))
        } else {
            actions.append(ObservationAction(
                name: "accessibility.requestTrust",
                command: "Ln1 trust",
                risk: "low",
                mutates: false,
                reason: "Enable Accessibility inspection before using state or perform."
            ))
        }

        actions.append(ObservationAction(
            name: "browser.listTabs",
            command: "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
            risk: browserActionRisk(for: "browser.listTabs"),
            mutates: false,
            reason: "Inspect browser tabs if a Chromium DevTools endpoint is running."
        ))

        return actions
    }

    private func perform() throws {
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        var appRecord: AppRecord?
        var elementSummary: AuditElementSummary?
        var elementID: String?
        var action: String?
        var policy: AuditPolicyDecision?
        var identityVerification: IdentityVerification?
        var auditWritten = false

        do {
            action = option("--action") ?? kAXPressAction as String
            policy = policyDecision(actionRisk: riskLevel(for: action!))
            guard policy?.allowed == true else {
                let message = policy?.message ?? "policy denied action"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: nil,
                    elementID: option("--element"),
                    element: nil,
                    action: action,
                    policy: policy,
                    outcome: AuditOutcome(ok: false, code: "policy_denied", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            elementID = try requiredOption("--element")
            try requireTrusted()
            let app = try targetApp()
            appRecord = AppRecord(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                pid: app.processIdentifier,
                hidden: app.isHidden
            )
            let resolution = try resolveGuardedElement(id: elementID!, in: app)
            let element = resolution.element
            elementID = resolution.id
            elementSummary = resolution.summary
            identityVerification = resolution.identityVerification

            let available = elementSummary?.actions ?? actionNames(element)
            guard available.contains(action!) else {
                let message = "element \(elementID!) does not expose action \(action!). Available: \(available.joined(separator: ", "))"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID,
                    element: elementSummary,
                    action: action,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "action_unavailable", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            let result = AXUIElementPerformAction(element, action! as CFString)
            guard result == .success else {
                let message = "AXUIElementPerformAction failed with \(result)"
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: riskLevel(for: action!),
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID,
                    element: elementSummary,
                    action: action,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "action_failed", message: message)
                ), to: auditURL)
                auditWritten = true
                throw CommandError(description: message)
            }

            let message = "Performed \(action!) on \(elementID!)."
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "perform",
                risk: riskLevel(for: action!),
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: action,
                policy: policy,
                identityVerification: identityVerification,
                outcome: AuditOutcome(ok: true, code: "performed", message: message)
            ), to: auditURL)
            auditWritten = true

            try writeJSON(ActionResult(
                ok: true,
                pid: app.processIdentifier,
                element: elementID!,
                stableIdentity: elementSummary?.stableIdentity,
                action: action!,
                identityVerification: identityVerification,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            ))
        } catch let error as CommandError {
            if !auditWritten {
                try appendAuditRecord(ActionAuditRecord(
                    id: auditID,
                    timestamp: ISO8601DateFormatter().string(from: Date()),
                    command: "perform",
                    risk: action.map(riskLevel) ?? "unknown",
                    reason: option("--reason"),
                    app: appRecord,
                    elementID: elementID ?? option("--element"),
                    element: elementSummary,
                    action: action ?? option("--action") ?? kAXPressAction as String,
                    policy: policy,
                    identityVerification: identityVerification,
                    outcome: AuditOutcome(ok: false, code: "rejected", message: error.description)
                ), to: auditURL)
            }
            throw error
        }
    }

    private func setAccessibilityValue() throws {
        let commandName = "set-value"
        let actionName = "accessibility.setValue"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = accessibilityActionRisk(for: actionName)
        var appRecord: AppRecord?
        var elementSummary: AuditElementSummary?
        var elementID: String?
        var policy: AuditPolicyDecision?
        var identityVerification: IdentityVerification?
        var verification: FileOperationVerification?
        var valueLength: Int?
        var valueDigest: String?
        var currentValueLength: Int?
        var currentValueDigest: String?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: commandName,
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID ?? option("--element"),
                element: elementSummary,
                action: actionName,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
                valueLength: valueLength,
                valueDigest: valueDigest,
                currentValueLength: currentValueLength,
                currentValueDigest: currentValueDigest,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            policy = policyDecision(actionRisk: risk)
            guard policy?.allowed == true else {
                let message = policy?.message ?? "policy denied action"
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            let value = try requiredOption("--value")
            valueLength = value.count
            valueDigest = sha256Digest(value)
            elementID = try requiredOption("--element")
            try requireTrusted()
            let app = try targetApp()
            appRecord = AppRecord(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                pid: app.processIdentifier,
                hidden: app.isHidden
            )
            let resolution = try resolveGuardedElement(id: elementID!, in: app)
            let element = resolution.element
            elementID = resolution.id
            elementSummary = resolution.summary
            identityVerification = resolution.identityVerification

            let writableAttributes = elementSummary?.settableAttributes ?? settableAttributes(element)
            guard writableAttributes.contains(kAXValueAttribute as String) else {
                let message = "element \(elementID!) does not expose settable AXValue"
                try writeAudit(ok: false, code: "value_not_settable", message: message)
                throw CommandError(description: message)
            }

            let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, value as CFTypeRef)
            guard result == .success else {
                let message = "AXUIElementSetAttributeValue failed with \(result)"
                try writeAudit(ok: false, code: "set_value_failed", message: message)
                throw CommandError(description: message)
            }

            let currentValue = stringLikeAttribute(element, kAXValueAttribute)
            currentValueLength = currentValue?.count
            currentValueDigest = currentValue.map(sha256Digest)
            let matched = currentValue == value
            verification = FileOperationVerification(
                ok: matched,
                code: matched ? "value_verified" : "value_mismatch",
                message: matched
                    ? "element AXValue contains text with the requested length and digest"
                    : "element AXValue did not match requested text after setting"
            )
            guard matched else {
                let message = verification?.message ?? "element value verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Set AXValue on \(elementID!)."
            try writeAudit(ok: true, code: "set_value", message: message)

            try writeJSON(AccessibilityValueSetResult(
                ok: true,
                pid: app.processIdentifier,
                element: elementID!,
                stableIdentity: elementSummary?.stableIdentity,
                action: actionName,
                risk: risk,
                valueLength: valueLength ?? 0,
                valueDigest: valueDigest ?? "",
                currentValueLength: currentValueLength,
                currentValueDigest: currentValueDigest,
                verification: verification!,
                identityVerification: identityVerification,
                message: message,
                auditID: auditID,
                auditLogPath: auditURL.path
            ))
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func auditSummary(
        _ element: AXUIElement,
        pathID: String,
        ownerName: String?,
        ownerBundleIdentifier: String?
    ) -> AuditElementSummary {
        let role = stringAttribute(element, kAXRoleAttribute)
        let subrole = stringAttribute(element, kAXSubroleAttribute)
        let title = stringAttribute(element, kAXTitleAttribute)
        let help = stringAttribute(element, kAXHelpAttribute)
        let elementFrame = frame(element)
        let actions = actionNames(element)
        let writableAttributes = settableAttributes(element)

        return AuditElementSummary(
            stableIdentity: accessibilityElementStableIdentity(
                pathID: pathID,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                role: role,
                subrole: subrole,
                title: title,
                help: help,
                frame: elementFrame,
                actions: actions
            ),
            role: role,
            subrole: subrole,
            title: title,
            help: help,
            enabled: boolAttribute(element, kAXEnabledAttribute),
            actions: actions,
            settableAttributes: writableAttributes,
            valueSettable: writableAttributes.contains(kAXValueAttribute as String)
        )
    }

    func verifyElementIdentity(_ stableIdentity: StableIdentity?) throws -> IdentityVerification? {
        let expectedID = option("--expect-identity")
        let minimumConfidence = option("--min-identity-confidence")
        guard expectedID != nil || minimumConfidence != nil else {
            return nil
        }

        guard let stableIdentity else {
            return IdentityVerification(
                ok: false,
                code: "identity_unavailable",
                message: "element identity is unavailable",
                expectedID: expectedID,
                actualID: "unavailable",
                minimumConfidence: minimumConfidence,
                actualConfidence: "unknown",
                identityMatched: expectedID == nil ? nil : false,
                confidenceAccepted: minimumConfidence == nil ? nil : false
            )
        }

        let identityMatched = expectedID.map { $0 == stableIdentity.id }
        let confidenceAccepted: Bool?
        if let minimumConfidence {
            guard let minimumRank = identityConfidenceRank(minimumConfidence) else {
                throw CommandError(description: "invalid --min-identity-confidence '\(minimumConfidence)'. Use low, medium, or high.")
            }
            let actualRank = identityConfidenceRank(stableIdentity.confidence) ?? -1
            confidenceAccepted = actualRank >= minimumRank
        } else {
            confidenceAccepted = nil
        }

        if identityMatched == false {
            return IdentityVerification(
                ok: false,
                code: "identity_mismatch",
                message: "element identity \(stableIdentity.id) did not match expected identity \(expectedID!)",
                expectedID: expectedID,
                actualID: stableIdentity.id,
                minimumConfidence: minimumConfidence,
                actualConfidence: stableIdentity.confidence,
                identityMatched: identityMatched,
                confidenceAccepted: confidenceAccepted
            )
        }

        if confidenceAccepted == false {
            return IdentityVerification(
                ok: false,
                code: "identity_confidence_too_low",
                message: "element identity confidence \(stableIdentity.confidence) is below required \(minimumConfidence!)",
                expectedID: expectedID,
                actualID: stableIdentity.id,
                minimumConfidence: minimumConfidence,
                actualConfidence: stableIdentity.confidence,
                identityMatched: identityMatched,
                confidenceAccepted: confidenceAccepted
            )
        }

        return IdentityVerification(
            ok: true,
            code: "identity_verified",
            message: "element identity matched requested constraints",
            expectedID: expectedID,
            actualID: stableIdentity.id,
            minimumConfidence: minimumConfidence,
            actualConfidence: stableIdentity.confidence,
            identityMatched: identityMatched,
            confidenceAccepted: confidenceAccepted
        )
    }

    func browserActionRisk(for action: String) -> String {
        switch action {
        case "browser.listTabs", "browser.inspectTab", "browser.waitURL", "browser.waitSelector", "browser.waitCount", "browser.waitText", "browser.waitElementText", "browser.waitValue", "browser.waitReady", "browser.waitTitle", "browser.waitChecked", "browser.waitEnabled", "browser.waitFocus", "browser.waitAttribute":
            return "low"
        case "browser.launch", "browser.readText", "browser.captureScreenshot", "browser.readConsole", "browser.readDialogs", "browser.readNetwork", "browser.readDOM", "browser.fillFormField", "browser.selectOption", "browser.uploadFiles", "browser.setChecked", "browser.focusElement", "browser.pressKey", "browser.clickElement", "browser.navigate", "browser.rollbackNavigation":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func desktopActionRisk(for action: String) -> String {
        switch action {
        case "desktop.activeWindow", "desktop.listDisplays", "desktop.listWindows", "desktop.waitActiveWindow", "desktop.waitWindow":
            return "low"
        case "desktop.screenshot":
            return "medium"
        case "desktop.minimizeActiveWindow", "desktop.restoreWindow", "desktop.raiseWindow", "desktop.setWindowFrame":
            return "medium"
        default:
            return "unknown"
        }
    }

    func inputActionRisk(for action: String) -> String {
        switch action {
        case "input.pointer":
            return "low"
        case "input.movePointer", "input.dragPointer", "input.scrollWheel", "input.pressKey", "input.typeText":
            return "medium"
        default:
            return "unknown"
        }
    }

    private func systemActionRisk(for action: String) -> String {
        switch action {
        case "system.context":
            return "low"
        default:
            return "unknown"
        }
    }

    private func benchmarkActionRisk(for action: String) -> String {
        switch action {
        case "benchmarks.matrix":
            return "low"
        default:
            return "unknown"
        }
    }

    func workspaceActionRisk(for action: String) -> String {
        switch action {
        case "workspace.open":
            return "medium"
        default:
            return "unknown"
        }
    }

    func appActionRisk(for action: String) -> String {
        switch action {
        case "apps.active", "apps.list", "apps.installed", "apps.plan", "apps.waitActive":
            return "low"
        case "apps.activate", "apps.launch", "apps.hide", "apps.unhide":
            return "medium"
        case "apps.quit":
            return "high"
        default:
            return "unknown"
        }
    }

    private func processActionRisk(for action: String) -> String {
        switch action {
        case "processes.list", "processes.inspect", "processes.wait":
            return "low"
        default:
            return "unknown"
        }
    }

    private func workflowActionRisk(for action: String) -> String {
        switch action {
        case "workflow.logRead":
            return "medium"
        default:
            return "unknown"
        }
    }

    func requirePolicyAllowed(action: String) throws {
        let risk: String
        if action.hasPrefix("task.") {
            risk = taskMemoryActionRisk(for: action)
        } else if action.hasPrefix("workflow.") {
            risk = workflowActionRisk(for: action)
        } else {
            risk = "unknown"
        }
        let policy = policyDecision(actionRisk: risk)
        guard policy.allowed else {
            throw CommandError(description: policy.message)
        }
    }

    private func knownPolicyActions() -> [PolicyActionRecord] {
        [
            PolicyActionRecord(name: kAXPressAction as String, domain: "accessibility", risk: "low", mutates: true),
            PolicyActionRecord(name: kAXShowMenuAction as String, domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: kAXConfirmAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: kAXPickAction as String, domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: "accessibility.inspectMenu", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.inspectElement", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.findElement", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.waitElement", domain: "accessibility", risk: "low", mutates: false),
            PolicyActionRecord(name: "accessibility.setValue", domain: "accessibility", risk: "medium", mutates: true),
            PolicyActionRecord(name: "apps.list", domain: "apps", risk: appActionRisk(for: "apps.list"), mutates: false),
            PolicyActionRecord(name: "apps.active", domain: "apps", risk: appActionRisk(for: "apps.active"), mutates: false),
            PolicyActionRecord(name: "apps.installed", domain: "apps", risk: appActionRisk(for: "apps.installed"), mutates: false),
            PolicyActionRecord(name: "apps.plan", domain: "apps", risk: appActionRisk(for: "apps.plan"), mutates: false),
            PolicyActionRecord(name: "apps.waitActive", domain: "apps", risk: appActionRisk(for: "apps.waitActive"), mutates: false),
            PolicyActionRecord(name: "apps.activate", domain: "apps", risk: appActionRisk(for: "apps.activate"), mutates: true),
            PolicyActionRecord(name: "apps.launch", domain: "apps", risk: appActionRisk(for: "apps.launch"), mutates: true),
            PolicyActionRecord(name: "apps.hide", domain: "apps", risk: appActionRisk(for: "apps.hide"), mutates: true),
            PolicyActionRecord(name: "apps.unhide", domain: "apps", risk: appActionRisk(for: "apps.unhide"), mutates: true),
            PolicyActionRecord(name: "apps.quit", domain: "apps", risk: appActionRisk(for: "apps.quit"), mutates: true),
            PolicyActionRecord(name: "processes.list", domain: "processes", risk: processActionRisk(for: "processes.list"), mutates: false),
            PolicyActionRecord(name: "processes.inspect", domain: "processes", risk: processActionRisk(for: "processes.inspect"), mutates: false),
            PolicyActionRecord(name: "processes.wait", domain: "processes", risk: processActionRisk(for: "processes.wait"), mutates: false),
            PolicyActionRecord(name: "system.context", domain: "system", risk: systemActionRisk(for: "system.context"), mutates: false),
            PolicyActionRecord(name: "benchmarks.matrix", domain: "benchmarks", risk: benchmarkActionRisk(for: "benchmarks.matrix"), mutates: false),
            PolicyActionRecord(name: "workspace.open", domain: "workspace", risk: workspaceActionRisk(for: "workspace.open"), mutates: true),
            PolicyActionRecord(name: "desktop.listDisplays", domain: "desktop", risk: desktopActionRisk(for: "desktop.listDisplays"), mutates: false),
            PolicyActionRecord(name: "desktop.activeWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.activeWindow"), mutates: false),
            PolicyActionRecord(name: "desktop.screenshot", domain: "desktop", risk: desktopActionRisk(for: "desktop.screenshot"), mutates: false),
            PolicyActionRecord(name: "desktop.listWindows", domain: "desktop", risk: desktopActionRisk(for: "desktop.listWindows"), mutates: false),
            PolicyActionRecord(name: "desktop.waitActiveWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.waitActiveWindow"), mutates: false),
            PolicyActionRecord(name: "desktop.waitWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.waitWindow"), mutates: false),
            PolicyActionRecord(name: "desktop.minimizeActiveWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.minimizeActiveWindow"), mutates: true),
            PolicyActionRecord(name: "desktop.restoreWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.restoreWindow"), mutates: true),
            PolicyActionRecord(name: "desktop.raiseWindow", domain: "desktop", risk: desktopActionRisk(for: "desktop.raiseWindow"), mutates: true),
            PolicyActionRecord(name: "desktop.setWindowFrame", domain: "desktop", risk: desktopActionRisk(for: "desktop.setWindowFrame"), mutates: true),
            PolicyActionRecord(name: "input.pointer", domain: "input", risk: inputActionRisk(for: "input.pointer"), mutates: false),
            PolicyActionRecord(name: "input.movePointer", domain: "input", risk: inputActionRisk(for: "input.movePointer"), mutates: true),
            PolicyActionRecord(name: "input.dragPointer", domain: "input", risk: inputActionRisk(for: "input.dragPointer"), mutates: true),
            PolicyActionRecord(name: "input.scrollWheel", domain: "input", risk: inputActionRisk(for: "input.scrollWheel"), mutates: true),
            PolicyActionRecord(name: "input.pressKey", domain: "input", risk: inputActionRisk(for: "input.pressKey"), mutates: true),
            PolicyActionRecord(name: "input.typeText", domain: "input", risk: inputActionRisk(for: "input.typeText"), mutates: true),
            PolicyActionRecord(name: "filesystem.stat", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.list", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.search", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.wait", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.watch", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.checksum", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.compare", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.plan", domain: "filesystem", risk: "low", mutates: false),
            PolicyActionRecord(name: "filesystem.readText", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.tailText", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readLines", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readJSON", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.readPropertyList", domain: "filesystem", risk: "medium", mutates: false),
            PolicyActionRecord(name: "filesystem.writeText", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.appendText", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.duplicate", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.move", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.createDirectory", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.rollbackMove", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "filesystem.rollbackTextWrite", domain: "filesystem", risk: "medium", mutates: true),
            PolicyActionRecord(name: "clipboard.state", domain: "clipboard", risk: "low", mutates: false),
            PolicyActionRecord(name: "clipboard.wait", domain: "clipboard", risk: "low", mutates: false),
            PolicyActionRecord(name: "clipboard.readText", domain: "clipboard", risk: "medium", mutates: false),
            PolicyActionRecord(name: "clipboard.writeText", domain: "clipboard", risk: "medium", mutates: true),
            PolicyActionRecord(name: "clipboard.rollbackText", domain: "clipboard", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.listTabs", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.launch", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.inspectTab", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.readText", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.captureScreenshot", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readConsole", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readDialogs", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readNetwork", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.readDOM", domain: "browser", risk: "medium", mutates: false),
            PolicyActionRecord(name: "browser.fillFormField", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.selectOption", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.uploadFiles", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.setChecked", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.focusElement", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.pressKey", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.clickElement", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.navigate", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.rollbackNavigation", domain: "browser", risk: "medium", mutates: true),
            PolicyActionRecord(name: "browser.waitURL", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitSelector", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitCount", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitText", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitElementText", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitValue", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitReady", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitTitle", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitChecked", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitEnabled", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitFocus", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "browser.waitAttribute", domain: "browser", risk: "low", mutates: false),
            PolicyActionRecord(name: "task.memoryStart", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryRecord", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryFinish", domain: "task", risk: "medium", mutates: true),
            PolicyActionRecord(name: "task.memoryShow", domain: "task", risk: "medium", mutates: false),
            PolicyActionRecord(name: "workflow.logRead", domain: "workflow", risk: "medium", mutates: false)
        ]
    }

    func policyDecision(actionRisk: String) -> AuditPolicyDecision {
        let allowedRisk = option("--allow-risk") ?? "low"
        guard let allowedRank = riskRank(allowedRisk) else {
            return AuditPolicyDecision(
                allowedRisk: allowedRisk,
                actionRisk: actionRisk,
                allowed: false,
                message: "invalid --allow-risk '\(allowedRisk)'. Use low, medium, high, or unknown."
            )
        }

        let actionRank = riskRank(actionRisk) ?? riskRank("unknown")!
        let allowed = actionRank <= allowedRank
        let message = allowed
            ? "policy allowed \(actionRisk) action with --allow-risk \(allowedRisk)"
            : "policy denied \(actionRisk) action because --allow-risk is \(allowedRisk)"

        return AuditPolicyDecision(
            allowedRisk: allowedRisk,
            actionRisk: actionRisk,
            allowed: allowed,
            message: message
        )
    }

    private func riskRank(_ risk: String) -> Int? {
        switch risk {
        case "low":
            return 0
        case "medium":
            return 1
        case "high":
            return 2
        case "unknown":
            return 3
        default:
            return nil
        }
    }

    private func identityConfidenceRank(_ confidence: String) -> Int? {
        switch confidence {
        case "low":
            return 0
        case "medium":
            return 1
        case "high":
            return 2
        default:
            return nil
        }
    }

    func printHelp() {
        print("""
        Ln1: macOS semantic computer substrate prototype

        Usage:
          Ln1 trust [--prompt true|false]
          Ln1 doctor [--timeout-ms N] [--endpoint URL_OR_PATH] [--audit-log PATH] [--pasteboard NAME]
          Ln1 policy
          Ln1 system [context|info]
          Ln1 benchmarks [matrix]
          Ln1 observe [--app-limit N] [--window-limit N] [--all] [--include-desktop] [--all-layers]
          Ln1 workflow preflight --operation review-audit|inspect-active-app|inspect-frontmost-app|inspect-apps|inspect-installed-apps|inspect-menu|inspect-system|inspect-displays|inspect-active-window|inspect-windows|inspect-processes|start-task|record-task|finish-task|show-task|inspect-process|find-element|inspect-element|wait-process|wait-active-window|wait-window|wait-element|wait-active-app|minimize-active-window|restore-window|raise-window|set-window-frame|activate-app|launch-app|hide-app|unhide-app|quit-app|open-file|open-url|control-active-app|set-element-value|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|write-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file [--pid PID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--name TEXT] [--current] [--task-id ID] [--kind observation|decision|action|verification|note] [--status completed|blocked|cancelled] [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID_OR_AUDIT_ID] [--command NAME] [--code OUTCOME_CODE] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--x N] [--y N] [--width N] [--height N] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete]
          Ln1 workflow next --operation review-audit|inspect-active-app|inspect-frontmost-app|inspect-apps|inspect-installed-apps|inspect-menu|inspect-system|inspect-displays|inspect-active-window|inspect-windows|inspect-processes|start-task|record-task|finish-task|show-task|inspect-process|find-element|inspect-element|wait-process|wait-active-window|wait-window|wait-element|wait-active-app|minimize-active-window|restore-window|raise-window|set-window-frame|activate-app|launch-app|hide-app|unhide-app|quit-app|open-file|open-url|control-active-app|set-element-value|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|write-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file [--pid PID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--name TEXT] [--current] [--task-id ID] [--kind observation|decision|action|verification|note] [--status completed|blocked|cancelled] [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID_OR_AUDIT_ID] [--command NAME] [--code OUTCOME_CODE] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--x N] [--y N] [--width N] [--height N] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete]
          Ln1 workflow run --operation review-audit|inspect-active-app|inspect-frontmost-app|inspect-apps|inspect-installed-apps|inspect-menu|inspect-system|inspect-displays|inspect-active-window|inspect-windows|inspect-processes|show-task|inspect-process|find-element|inspect-element|wait-process|wait-active-window|wait-window|wait-element|wait-active-app|read-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|list-files|search-files|checksum-file|compare-files|watch-file|wait-file --dry-run false [--pid PID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--name TEXT] [--current] [--task-id ID] [--memory-log PATH] [--endpoint URL_OR_PATH] [--id TARGET_ID_OR_AUDIT_ID] [--command NAME] [--code OUTCOME_CODE] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--path PATH] [--to PATH] [--query TEXT] [--exists true|false] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--case-sensitive] [--watch-timeout-ms N] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--expect-url URL_OR_TEXT] [--selector CSS_SELECTOR] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--value VALUE] [--attribute NAME] [--title TITLE] [--checked true|false] [--enabled true|false] [--focused true|false] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow run --operation start-task|record-task|finish-task|minimize-active-window|restore-window|raise-window|set-window-frame|activate-app|launch-app|hide-app|unhide-app|quit-app|open-file|open-url|control-active-app|set-element-value|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|write-clipboard|write-file|append-file|create-directory|duplicate-file|move-file|rollback-file-move --dry-run false --execute-mutating true --reason TEXT [--pid PID] [--bundle-id BUNDLE_ID] [--current] [--task-id ID] [--kind observation|decision|action|verification|note] [--status completed|blocked|cancelled] [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--id TARGET_ID] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--text TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--overwrite] [--create] [--x N] [--y N] [--width N] [--height N] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow run --operation review-audit|inspect-active-app|inspect-frontmost-app|inspect-apps|inspect-installed-apps|inspect-menu|inspect-system|inspect-displays|inspect-active-window|inspect-windows|inspect-processes|inspect-process|find-element|inspect-element|wait-process|wait-active-window|wait-window|wait-element|wait-active-app|minimize-active-window|restore-window|raise-window|set-window-frame|activate-app|launch-app|hide-app|unhide-app|quit-app|open-file|open-url|control-active-app|set-element-value|read-browser|fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser|wait-browser-url|wait-browser-selector|wait-browser-count|wait-browser-text|wait-browser-element-text|wait-browser-value|wait-browser-ready|wait-browser-title|wait-browser-checked|wait-browser-enabled|wait-browser-focus|wait-browser-attribute|wait-clipboard|inspect-clipboard|read-clipboard|write-clipboard|inspect-file|read-file|tail-file|read-file-lines|read-file-json|read-file-plist|write-file|append-file|list-files|search-files|create-directory|duplicate-file|move-file|rollback-file-move|checksum-file|compare-files|watch-file|wait-file --dry-run true [--pid PID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--name TEXT] [--current] [--path PATH] [--to PATH] [--audit-id AUDIT_ID] [--element ID] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--id TARGET_ID_OR_AUDIT_ID] [--command NAME] [--code OUTCOME_CODE] [--selector CSS_SELECTOR] [--key KEY] [--modifiers shift,control,alt,meta] [--count N] [--count-match exact|at-least|at-most] [--text TEXT] [--query TEXT] [--value VALUE] [--label LABEL] [--checked true|false] [--enabled true|false] [--focused true|false] [--attribute NAME] [--changed-from N] [--has-string true|false] [--string-digest HEX] [--pasteboard NAME] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--max-characters N] [--start-line N] [--line-count N] [--max-line-characters N] [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-snippet-characters N] [--max-matches-per-file N] [--depth N] [--max-children N] [--limit N] [--include-hidden] [--overwrite] [--create] [--case-sensitive] [--x N] [--y N] [--width N] [--height N] [--title TITLE] [--url URL] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--state attached|visible|hidden|detached|loading|interactive|complete] [--run-timeout-ms N] [--max-output-bytes N]
          Ln1 workflow log --allow-risk medium [--workflow-log PATH] [--operation NAME] [--limit N]
          Ln1 workflow resume --allow-risk medium [--workflow-log PATH] [--operation NAME]
          Ln1 apps [--all]
          Ln1 apps active
          Ln1 apps list [--all] [--limit N]
          Ln1 apps installed [--limit N] [--name TEXT] [--bundle-id BUNDLE_ID]
          Ln1 apps plan --operation activate|launch|hide|unhide|quit (--pid PID|--bundle-id BUNDLE_ID|--current|--path APP_BUNDLE) [--activate true|false] [--allow-risk low|medium|high|unknown]
          Ln1 apps activate (--pid PID|--bundle-id BUNDLE_ID|--current) --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 apps launch (--bundle-id BUNDLE_ID|--path APP_BUNDLE) --allow-risk medium [--activate true|false] [--reason TEXT] [--audit-log PATH]
          Ln1 apps hide (--pid PID|--bundle-id BUNDLE_ID|--current) --allow-risk medium [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 apps unhide (--pid PID|--bundle-id BUNDLE_ID|--current) --allow-risk medium [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 apps quit (--pid PID|--bundle-id BUNDLE_ID|--current) --allow-risk high [--force] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 apps wait-active (--pid PID|--bundle-id BUNDLE_ID|--current) [--timeout-ms N] [--interval-ms N]
          Ln1 open (--path PATH|--url URL) --allow-risk medium [--plan] [--reason TEXT] [--audit-log PATH]
          Ln1 processes [list] [--limit N] [--name TEXT]
          Ln1 processes inspect (--pid PID|--current)
          Ln1 processes wait --pid PID [--exists true|false] [--timeout-ms N] [--interval-ms N]
          Ln1 desktop displays
          Ln1 desktop active-window
          Ln1 desktop screenshot --allow-risk medium [--display-id ID] [--max-sample-bytes N] [--include-ocr true|false] [--max-ocr-characters N]
          Ln1 desktop minimize-active-window --allow-risk medium [--timeout-ms N] [--interval-ms N] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--reason TEXT] [--audit-log PATH]
          Ln1 desktop restore-window (--pid PID|--bundle-id BUNDLE_ID|--current) --element WINDOW_ID --allow-risk medium [--timeout-ms N] [--interval-ms N] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--reason TEXT] [--audit-log PATH]
          Ln1 desktop raise-window (--pid PID|--bundle-id BUNDLE_ID|--current) --element WINDOW_ID --allow-risk medium [--timeout-ms N] [--interval-ms N] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--reason TEXT] [--audit-log PATH]
          Ln1 desktop set-window-frame (--pid PID|--bundle-id BUNDLE_ID|--current) --element WINDOW_ID --x N --y N --width N --height N --allow-risk medium [--timeout-ms N] [--interval-ms N] [--expect-identity ID] [--min-identity-confidence low|medium|high] [--reason TEXT] [--audit-log PATH]
          Ln1 desktop wait-active-window [--id ID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--title TEXT] [--match exact|prefix|contains] [--changed-from WINDOW_ID_OR_STABLE_ID] [--timeout-ms N] [--interval-ms N]
          Ln1 desktop windows [--limit N] [--id ID] [--owner-pid PID] [--bundle-id BUNDLE_ID] [--title TEXT] [--match exact|prefix|contains] [--include-desktop] [--all-layers]
          Ln1 desktop wait-window (--id ID|--owner-pid PID|--bundle-id BUNDLE_ID|--title TEXT) [--match exact|prefix|contains] [--exists true|false] [--timeout-ms N] [--interval-ms N] [--limit N] [--include-desktop] [--all-layers]
          Ln1 input pointer
          Ln1 input move --x N --y N --allow-risk medium [--dry-run true|false] [--tolerance N] [--reason TEXT] [--audit-log PATH]
          Ln1 input drag --from-x N --from-y N --to-x N --to-y N --allow-risk medium [--dry-run true|false] [--steps N] [--tolerance N] [--reason TEXT] [--audit-log PATH]
          Ln1 input scroll (--dx N|--dy N) --allow-risk medium [--dry-run true|false] [--reason TEXT] [--audit-log PATH]
          Ln1 input key --key KEY --allow-risk medium [--modifiers shift,control,alt,meta] [--dry-run true|false] [--reason TEXT] [--audit-log PATH]
          Ln1 input type --text TEXT --allow-risk medium [--dry-run true|false] [--reason TEXT] [--audit-log PATH]
          Ln1 state [--pid PID] [--all] [--include-background] [--depth N] [--max-children N]
          Ln1 state menu [--pid PID] [--depth N] [--max-children N]
          Ln1 state find [--pid PID] [--role ROLE] [--subrole SUBROLE] [--title TEXT] [--value TEXT] [--help-text TEXT] [--action ACTION] [--enabled true|false] [--match exact|contains] [--include-menu] [--depth N] [--max-children N] [--result-depth N] [--result-max-children N] [--limit N]
          Ln1 state element [--pid PID] --element ID [--expect-identity ID] [--min-identity-confidence low|medium|high] [--depth N] [--max-children N]
          Ln1 state wait-element [--pid PID] --element ID [--expect-identity ID] [--min-identity-confidence low|medium|high] [--title TEXT] [--value TEXT] [--match exact|contains] [--enabled true|false] [--exists true|false] [--timeout-ms N] [--interval-ms N] [--depth N] [--max-children N]
          Ln1 perform [--pid PID] --element w0.1.2|m0.1|a0.w0.1.2|a0.m0.1 [--action AXPress] [--allow-risk low|medium|high|unknown] [--reason TEXT] [--audit-log PATH]
          Ln1 set-value [--pid PID] --element w0.1.2|a0.w0.1.2 --value TEXT --allow-risk medium [--expect-identity ID] [--min-identity-confidence low|medium|high] [--reason TEXT] [--audit-log PATH]
          Ln1 audit [--limit N] [--id AUDIT_ID] [--command NAME] [--code OUTCOME_CODE] [--audit-log PATH]
          Ln1 task start --title TEXT [--summary TEXT] --allow-risk medium [--sensitivity public|private|sensitive] [--task-id ID] [--memory-log PATH]
          Ln1 task record --task-id ID --kind observation|decision|action|verification|note --summary TEXT --allow-risk medium [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          Ln1 task finish --task-id ID [--status completed|blocked|cancelled] --allow-risk medium [--summary TEXT] [--sensitivity public|private|sensitive] [--related-audit-id ID] [--memory-log PATH]
          Ln1 task show --task-id ID --allow-risk medium [--limit N] [--memory-log PATH]
          Ln1 files stat --path PATH
          Ln1 files list --path PATH [--depth N] [--limit N] [--include-hidden]
          Ln1 files search --path PATH --query TEXT [--depth N] [--limit N] [--include-hidden] [--case-sensitive] [--max-file-bytes N] [--max-characters N] [--max-snippet-characters N] [--max-matches-per-file N]
          Ln1 files read-text --path PATH --allow-risk medium [--max-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files tail-text --path PATH --allow-risk medium [--max-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-lines --path PATH --allow-risk medium [--start-line N] [--line-count N] [--max-line-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-json --path PATH --allow-risk medium [--pointer JSON_POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files read-plist --path PATH --allow-risk medium [--pointer POINTER] [--max-depth N] [--max-items N] [--max-string-characters N] [--max-file-bytes N] [--reason TEXT] [--audit-log PATH]
          Ln1 files write-text --path PATH --text TEXT --allow-risk medium [--overwrite] [--reason TEXT] [--audit-log PATH] [--rollback-snapshot PATH]
          Ln1 files append-text --path PATH --text TEXT --allow-risk medium [--create] [--reason TEXT] [--audit-log PATH] [--rollback-snapshot PATH]
          Ln1 files wait --path PATH [--exists true|false] [--size-bytes N] [--digest SHA256] [--algorithm sha256] [--max-file-bytes N] [--timeout-ms N] [--interval-ms N]
          Ln1 files watch --path PATH [--depth N] [--limit N] [--include-hidden] [--timeout-ms N] [--interval-ms N]
          Ln1 files checksum --path PATH [--algorithm sha256] [--max-file-bytes N]
          Ln1 files compare --path LEFT --to RIGHT [--algorithm sha256] [--max-file-bytes N]
          Ln1 files plan --operation duplicate|move --path SOURCE --to DESTINATION [--allow-risk low|medium|high|unknown]
          Ln1 files plan --operation mkdir --path PATH [--allow-risk low|medium|high|unknown]
          Ln1 files plan --operation rollback --audit-id AUDIT_ID [--allow-risk low|medium|high|unknown] [--audit-log PATH]
          Ln1 files duplicate --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files move --path SOURCE --to DESTINATION --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files mkdir --path PATH --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files rollback --audit-id AUDIT_ID --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 files rollback-text --audit-id AUDIT_ID --allow-risk medium [--reason TEXT] [--audit-log PATH]
          Ln1 clipboard state [--pasteboard NAME]
          Ln1 clipboard wait [--changed-from N] [--has-string true|false] [--string-digest HEX] [--timeout-ms N] [--interval-ms N] [--pasteboard NAME]
          Ln1 clipboard read-text --allow-risk medium [--max-characters N] [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          Ln1 clipboard write-text --text TEXT --allow-risk medium [--reason TEXT] [--audit-log PATH] [--pasteboard NAME] [--rollback-snapshot PATH]
          Ln1 clipboard rollback --audit-id AUDIT_ID --allow-risk medium [--reason TEXT] [--audit-log PATH] [--pasteboard NAME]
          Ln1 browser launch --allow-risk medium [--browser chrome|chrome-canary|chromium|edge|brave] [--remote-debugging-port N] [--profile PATH] [--download-dir PATH] [--app-path PATH] [--executable PATH] [--url URL] [--dry-run true|false]
          Ln1 browser tabs [--endpoint URL_OR_PATH] [--include-non-page]
          Ln1 browser tab --id TARGET_ID [--endpoint URL_OR_PATH] [--include-non-page]
          Ln1 browser text --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser screenshot --id TARGET_ID --allow-risk medium [--format png|jpeg] [--quality N] [--from-surface true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser console --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-entries N] [--max-message-characters N] [--sample-ms N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser dialogs --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-entries N] [--max-message-characters N] [--sample-ms N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser network --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-entries N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser dom --id TARGET_ID --allow-risk medium [--endpoint URL_OR_PATH] [--max-elements N] [--max-text-characters N] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser fill --id TARGET_ID --selector CSS_SELECTOR --text TEXT --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser select --id TARGET_ID --selector CSS_SELECTOR (--value VALUE|--label LABEL) --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser upload --id TARGET_ID --selector CSS_SELECTOR --path FILE [--path FILE ...] --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser check --id TARGET_ID --selector CSS_SELECTOR [--checked true|false] --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser focus --id TARGET_ID --selector CSS_SELECTOR --allow-risk medium [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser press-key --id TARGET_ID --key KEY --allow-risk medium [--selector CSS_SELECTOR] [--modifiers shift,control,alt,meta] [--endpoint URL_OR_PATH] [--timeout-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser click --id TARGET_ID --selector CSS_SELECTOR --allow-risk medium [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser navigate --id TARGET_ID --url URL --allow-risk medium [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser back --id TARGET_ID --allow-risk medium [--steps N] [--endpoint URL_OR_PATH] [--expect-url URL_OR_TEXT] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N] [--reason TEXT] [--audit-log PATH]
          Ln1 browser wait-url --id TARGET_ID --expect-url URL_OR_TEXT [--endpoint URL_OR_PATH] [--match exact|prefix|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-selector --id TARGET_ID --selector CSS_SELECTOR [--endpoint URL_OR_PATH] [--state attached|visible|hidden|detached] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-count --id TARGET_ID --selector CSS_SELECTOR --count N [--endpoint URL_OR_PATH] [--count-match exact|at-least|at-most] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-text --id TARGET_ID --text TEXT [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-element-text --id TARGET_ID --selector CSS_SELECTOR --text TEXT [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-value --id TARGET_ID --selector CSS_SELECTOR --text TEXT [--endpoint URL_OR_PATH] [--match exact|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-ready --id TARGET_ID [--endpoint URL_OR_PATH] [--state loading|interactive|complete] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-title --id TARGET_ID --title TITLE [--endpoint URL_OR_PATH] [--match contains|exact] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-checked --id TARGET_ID --selector CSS_SELECTOR [--checked true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-enabled --id TARGET_ID --selector CSS_SELECTOR [--enabled true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-focus --id TARGET_ID --selector CSS_SELECTOR [--focused true|false] [--endpoint URL_OR_PATH] [--timeout-ms N] [--interval-ms N]
          Ln1 browser wait-attribute --id TARGET_ID --selector CSS_SELECTOR --attribute NAME --text TEXT [--endpoint URL_OR_PATH] [--match exact|contains] [--timeout-ms N] [--interval-ms N]
          Ln1 schema

        Notes:
          - Run `Ln1 trust` before Accessibility-backed `state`, `perform`, or `set-value` commands.
          - `policy` describes known action risk levels and mutation behavior.
          - `system context` reports bounded host, OS, shell, working directory, and runtime metadata.
          - `benchmarks matrix` returns the planned real-app coverage matrix for repeatable verification.
          - `apps active` returns frontmost app metadata without requiring Accessibility permission.
          - `apps list` returns bounded running app metadata in a transcript-friendly object shape.
          - `apps installed` lists installed app bundle identifiers and paths for launch planning.
          - `apps plan` previews app activation, launch, hide, unhide, or quit with policy and target checks without mutating apps.
          - `apps activate` brings one regular GUI app forward after medium-risk approval and writes an audit record.
          - `apps launch` opens an installed `.app` by bundle ID or path after medium-risk approval and verifies running/frontmost state.
          - `apps hide` hides one regular GUI app after medium-risk approval and verifies hidden state.
          - `apps unhide` makes one regular GUI app visible again after medium-risk approval and verifies it is no longer hidden.
          - `apps quit` asks one regular GUI app to terminate after high-risk approval and verifies process exit.
          - `apps wait-active` waits for the frontmost app to match a target without changing focus.
          - `open` opens one file path or URL through the macOS default handler after medium-risk approval and audits the handoff metadata.
          - `processes` lists and inspects bounded process metadata without reading command-line arguments.
          - `desktop displays` lists connected display topology, bounds, scale, and rotation without screenshots.
          - `desktop active-window` returns the frontmost visible window with stable identity metadata without screenshots.
          - `desktop screenshot` captures display image metadata and a bounded SHA-256 byte-sample digest after medium-risk approval, with opt-in bounded OCR text metadata for visual fallback.
          - `desktop minimize-active-window` minimizes the frontmost Accessibility window after medium-risk approval and verifies AXMinimized.
          - `desktop restore-window` restores one target app Accessibility window after medium-risk approval and verifies AXMinimized is false.
          - `desktop raise-window` raises one target app Accessibility window after medium-risk approval and verifies it is focused in the frontmost app.
          - `desktop set-window-frame` moves and resizes one target app Accessibility window after medium-risk approval and verifies AXPosition and AXSize.
          - `desktop wait-active-window` waits for the frontmost visible window to match target metadata or change identity.
          - `desktop windows` lists or filters visible desktop windows from macOS window metadata without requiring screenshots.
          - `desktop wait-window` waits for visible desktop window metadata to appear or disappear without fixed sleeps.
          - `input pointer`, `input move`, `input drag`, `input scroll`, `input key`, and `input type` provide a global input layer outside AX and browser targets, with policy/audit/verification for mutating input.
          - `state` emits structured JSON from macOS Accessibility APIs.
          - `state menu` inspects the target app menu bar as a bounded Accessibility tree.
          - `state find` searches Accessibility elements by semantic attributes and returns bounded candidate IDs.
          - `state element` inspects one Accessibility element path with optional stable identity verification and re-resolves a stale path by identity when exactly one current element matches.
          - `state wait-element` waits for an Accessibility element path and optional identity, text, or enabled-state criteria.
          - `state --all` walks every running GUI app macOS exposes to this process.
          - Element IDs are child-index paths. Use window IDs from `state` and menu IDs from `state menu` with `perform`; guarded element commands fail closed unless a supplied stable identity verifies or re-resolves to exactly one current element.
          - `perform` defaults to `--allow-risk low`; medium, high, and unknown actions require explicit allowance.
          - `perform` appends a structured JSONL audit record before returning success or failure.
          - `set-value` sets one element's AXValue only after medium-risk approval, verifies length and digest, and audits metadata without storing text.
          - `audit` can filter records by exact audit ID, command name, and outcome code before applying the limit.
          - `task` stores and reads task-scoped memory as medium-risk local persistence with sensitive-summary redaction.
          - `files` emits read-only filesystem metadata, bounded search evidence, and available typed file actions.
          - `files read-text` returns bounded UTF-8 text from the start of one regular file only after medium-risk approval and audits metadata without storing text.
          - `files tail-text` returns bounded UTF-8 text from the end of one regular file only after medium-risk approval and audits metadata without storing text.
          - `files read-lines` returns bounded, numbered UTF-8 lines from one regular file only after medium-risk approval and audits metadata without storing text.
          - `files read-json` returns a bounded typed JSON tree, optionally at a JSON Pointer, from one regular file only after medium-risk approval and audits metadata without storing JSON values.
          - `files read-plist` returns a bounded typed property list tree, optionally at a pointer, from one regular file only after medium-risk approval and audits metadata without storing property list values.
          - `files write-text` creates one UTF-8 text file, or overwrites with `--overwrite`, after medium-risk approval and verifies by length/digest without storing text in audit logs; pass `--rollback-snapshot` to store a local 0600 compensating undo token.
          - `files append-text` appends UTF-8 text to one regular file, or creates it with `--create`, after medium-risk approval and verifies by size/tail bytes without storing text in audit logs; pass `--rollback-snapshot` to store a local 0600 compensating undo token.
          - `files wait` waits for a path to exist, disappear, or match expected size/digest metadata.
          - `files watch` waits for created, deleted, or modified file metadata events under a path and returns normalized event records.
          - `files checksum` returns a bounded SHA-256 digest for a regular file without exposing file contents.
          - `files compare` compares two regular files by bounded SHA-256 digest and size.
          - `files plan` previews mutating file operations with policy, target metadata, and preflight checks without changing files.
          - `files duplicate` copies one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files move` moves one regular file to a new path, refuses overwrites, verifies the result, and writes an audit record.
          - `files mkdir` creates one directory, refuses existing paths, verifies the result, and writes an audit record.
          - `files rollback` restores a successful audited file move after validating current filesystem metadata.
          - `files rollback-text` restores a successful audited text write or append from its rollback snapshot after validating current filesystem metadata.
          - `clipboard state` reports pasteboard metadata and text digest without returning clipboard text.
          - `clipboard wait` waits for pasteboard metadata changes without returning clipboard text.
          - `clipboard read-text` returns bounded text only after medium-risk policy approval and audits metadata without storing text.
          - `clipboard write-text` writes plain text only after medium-risk policy approval, verifies by length and digest, and audits metadata without storing text; pass `--rollback-snapshot` to store a local 0600 compensating undo token.
          - `clipboard rollback` restores a successful audited clipboard write from its rollback snapshot after medium-risk policy approval and fails closed if current clipboard metadata no longer matches the write result.
          - `browser launch` plans or starts a Chromium-family browser with an isolated profile directory, optional download directory preferences, and explicit DevTools endpoint.
          - `browser tabs` reads Chrome DevTools target metadata from an explicit endpoint and returns structured tab records.
          - `browser tab` inspects one DevTools target by id from the same structured browser source.
          - `browser text` reads page text through Chrome DevTools only after medium-risk policy approval and audits length/digest without storing text.
          - `browser screenshot` captures page image metadata through Chrome DevTools only after medium-risk policy approval and audits byte count/digest without storing image bytes.
          - `browser console` samples bounded console/log events through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing message text.
          - `browser dialogs` samples bounded JavaScript dialog-opening metadata through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing prompt defaults.
          - `browser network` reads bounded Performance API navigation/resource timing metadata through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing request URLs.
          - `browser dom` reads bounded structured page state through Chrome DevTools only after medium-risk policy approval and audits count/digest without storing the DOM payload.
          - `browser fill` writes one form field through Chrome DevTools only after medium-risk policy approval, verifies by length, and audits selector plus text length/digest without storing text.
          - `browser select` chooses one select option through Chrome DevTools only after medium-risk policy approval, verifies the selection, and audits selector plus option length/digest without storing option text.
          - `browser upload` attaches readable local files to one file input through Chrome DevTools only after medium-risk policy approval, verifies file count, and audits selector plus file count/size/path digest without storing file contents.
          - `browser check` sets one checkbox or radio input through Chrome DevTools only after medium-risk policy approval and audits selector plus requested checked state.
          - `browser focus` focuses one DOM element by CSS selector through Chrome DevTools only after medium-risk policy approval and audits selector/target metadata.
          - `browser press-key` dispatches one key press through Chrome DevTools only after medium-risk policy approval and audits key/modifier metadata.
          - `browser click` clicks one DOM element by CSS selector through Chrome DevTools only after medium-risk policy approval, optionally waits for an expected resulting URL, and audits selector/target metadata plus URL verification when requested.
          - `browser navigate` navigates one tab through Chrome DevTools only after medium-risk policy approval, verifies the resulting URL from structured tab metadata, and audits the requested/current URLs.
          - `browser back` rolls a tab back through DevTools navigation history only after medium-risk policy approval, verifies the resulting URL, and audits target entry metadata.
          - `browser wait-url` waits for one tab URL to match exact, prefix, or contains criteria without mutating the page.
          - `browser wait-selector` waits for one DOM selector to become attached, visible, hidden, or detached without mutating the page.
          - `browser wait-count` waits for a selector count to match exact, at-least, or at-most criteria without mutating the page.
          - `browser wait-text` waits for page text to match without returning page text contents.
          - `browser wait-element-text` waits for one element's text to match without returning text contents.
          - `browser wait-value` waits for one input, textarea, or select value without returning value contents.
          - `browser wait-ready` waits for one tab document readiness state without mutating the page.
          - `browser wait-title` waits for one tab title to match without reading page contents.
          - `browser wait-checked` waits for one checkbox or radio checked state without mutating the page.
          - `browser wait-enabled` waits for one element enabled or disabled state without mutating the page.
          - `browser wait-focus` waits for one element focused or unfocused state without mutating the page.
          - `browser wait-attribute` waits for one element attribute to match without returning attribute contents.
          - Workflow review-audit reads bounded audit records into the workflow transcript and can lead to rollback preflight for successful file moves.
          - Workflow inspect-frontmost-app captures the current frontmost app before choosing process or UI inspection.
          - Workflow inspect-apps captures bounded running app inventory before choosing an active-app or process inspection.
          - Workflow fill-browser, select-browser, check-browser, focus-browser, press-browser-key, click-browser, and navigate-browser preflight browser actions before returning typed mutating browser argv arrays for review.
          - Workflow mutating execution requires --execute-mutating true and a non-placeholder --reason before running the underlying audited command.
          - Workflow inspect-menu inspects one app menu bar before choosing a trusted UI action.
          - Workflow inspect-windows captures visible desktop window inventory before choosing an app or process target.
          - Workflow inspect-processes captures bounded process inventory before choosing a PID-specific action.
          - Workflow find-element searches Accessibility elements before inspecting or acting on a candidate.
          - Workflow start-task, record-task, finish-task, and show-task preflight task-scoped memory persistence and reads.
          - Workflow inspect-element inspects one Accessibility element before choosing a guarded UI action.
          - Workflow set-element-value preflights a guarded AXValue update and executes it only through mutating workflow approval.
          - Workflow read-clipboard reads bounded clipboard text through workflow preflight, transcript capture, and audit logging.
          - Workflow write-clipboard writes clipboard text only through mutating workflow approval and verifies by length and digest.
          - Workflow wait-active-window waits for frontmost window metadata before inspecting owner process state.
          - Workflow wait-window waits for desktop window appearance or disappearance before inspecting owner process or active app state.
          - Workflow wait-element waits for Accessibility element appearance or readiness before guarded UI actions.
          - Workflow wait-browser-url waits for post-action browser URL verification without fixed sleeps.
          - Workflow wait-browser-selector waits for dynamic page UI readiness or disappearance before the next browser action.
          - Workflow wait-browser-count waits for dynamic collection sizes before inspecting or acting.
          - Workflow wait-browser-text waits for page text readiness without fixed sleeps.
          - Workflow wait-browser-element-text waits for one element's text readiness without fixed sleeps.
          - Workflow wait-browser-value waits for field value readiness without exposing value contents.
          - Workflow wait-browser-ready waits for document readiness before inspecting or acting.
          - Workflow wait-browser-title waits for title changes before inspecting or acting.
          - Workflow wait-browser-checked waits for checkbox or radio state before inspecting or acting.
          - Workflow wait-browser-enabled waits for an element to become enabled or disabled before inspecting or acting.
          - Workflow wait-browser-focus waits for focus state before inspecting or acting.
          - Workflow wait-browser-attribute waits for DOM attribute state before inspecting or acting.
        """)
    }

    private func desktopMinimizeActiveWindow() throws -> DesktopMinimizeWindowResult {
        let commandName = "desktop.minimize-active-window"
        let actionName = "desktop.minimizeActiveWindow"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = desktopActionRisk(for: actionName)
        let policy = policyDecision(actionRisk: risk)
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var appRecord: AppRecord?
        var elementID: String?
        var elementSummary: AuditElementSummary?
        var identityVerification: IdentityVerification?
        var verification: FileOperationVerification?
        var minimizedBefore: Bool?
        var minimizedAfter: Bool?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: commandName,
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: actionName,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
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

            try requireTrusted()
            guard let app = NSWorkspace.shared.frontmostApplication else {
                let message = "no frontmost app is available for desktop minimize-active-window"
                try writeAudit(ok: false, code: "frontmost_app_missing", message: message)
                throw CommandError(description: message)
            }
            appRecord = self.appRecord(for: app)

            let activeWindow = try activeAccessibilityWindow(for: app)
            elementID = activeWindow.elementID
            elementSummary = auditSummary(
                activeWindow.element,
                pathID: activeWindow.elementID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )

            identityVerification = try verifyElementIdentity(elementSummary?.stableIdentity)
            guard identityVerification?.ok != false else {
                let message = identityVerification?.message ?? "window identity verification failed"
                try writeAudit(ok: false, code: identityVerification?.code ?? "identity_rejected", message: message)
                throw CommandError(description: message)
            }

            let writableAttributes = elementSummary?.settableAttributes ?? settableAttributes(activeWindow.element)
            guard writableAttributes.contains(kAXMinimizedAttribute as String) else {
                let message = "active window does not expose settable AXMinimized"
                try writeAudit(ok: false, code: "minimized_not_settable", message: message)
                throw CommandError(description: message)
            }

            minimizedBefore = boolAttribute(activeWindow.element, kAXMinimizedAttribute)
            let requested: Bool
            if minimizedBefore == true {
                requested = true
            } else {
                let result = AXUIElementSetAttributeValue(
                    activeWindow.element,
                    kAXMinimizedAttribute as CFString,
                    kCFBooleanTrue
                )
                requested = result == .success
                if !requested {
                    let message = "AXUIElementSetAttributeValue AXMinimized failed with \(result)"
                    verification = FileOperationVerification(
                        ok: false,
                        code: "minimize_request_failed",
                        message: message
                    )
                    try writeAudit(ok: false, code: "minimize_request_failed", message: message)
                    throw CommandError(description: message)
                }
            }

            verification = verifyAccessibilityWindowMinimized(
                activeWindow.element,
                expectedMinimized: true,
                requested: requested,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            minimizedAfter = boolAttribute(activeWindow.element, kAXMinimizedAttribute)
            guard verification?.ok == true else {
                let message = verification?.message ?? "active window minimize verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Minimized the active window for \(appDisplayName(appRecord!))."
            try writeAudit(ok: true, code: "minimized", message: message)

            return DesktopMinimizeWindowResult(
                ok: true,
                action: actionName,
                risk: risk,
                app: appRecord!,
                elementID: elementID!,
                window: elementSummary!,
                minimizedBefore: minimizedBefore,
                minimizedAfter: minimizedAfter,
                verification: verification!,
                identityVerification: identityVerification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func desktopRestoreWindow() throws -> DesktopMinimizeWindowResult {
        let commandName = "desktop.restore-window"
        let actionName = "desktop.restoreWindow"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = desktopActionRisk(for: actionName)
        let policy = policyDecision(actionRisk: risk)
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var appRecord: AppRecord?
        var elementID: String?
        var elementSummary: AuditElementSummary?
        var identityVerification: IdentityVerification?
        var verification: FileOperationVerification?
        var minimizedBefore: Bool?
        var minimizedAfter: Bool?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: commandName,
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: actionName,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
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

            let requestedElementID = try normalizedElementID(try requiredOption("--element"))
            guard requestedElementID.first == "w" else {
                let message = "desktop restore-window requires a window element id like w0"
                try writeAudit(ok: false, code: "invalid_window_element", message: message)
                throw CommandError(description: message)
            }
            elementID = requestedElementID

            try requireTrusted()
            let app = try targetRunningApplicationForAppCommand()
            appRecord = self.appRecord(for: app)
            let window = try resolveElement(id: requestedElementID, in: app.processIdentifier)
            elementSummary = auditSummary(
                window,
                pathID: requestedElementID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )

            guard elementSummary?.role == (kAXWindowRole as String) else {
                let message = "target element role is \(elementSummary?.role ?? "unavailable"), not AXWindow"
                try writeAudit(ok: false, code: "target_not_window", message: message)
                throw CommandError(description: message)
            }

            identityVerification = try verifyElementIdentity(elementSummary?.stableIdentity)
            guard identityVerification?.ok != false else {
                let message = identityVerification?.message ?? "window identity verification failed"
                try writeAudit(ok: false, code: identityVerification?.code ?? "identity_rejected", message: message)
                throw CommandError(description: message)
            }

            let writableAttributes = elementSummary?.settableAttributes ?? settableAttributes(window)
            guard writableAttributes.contains(kAXMinimizedAttribute as String) else {
                let message = "target window does not expose settable AXMinimized"
                try writeAudit(ok: false, code: "minimized_not_settable", message: message)
                throw CommandError(description: message)
            }

            minimizedBefore = boolAttribute(window, kAXMinimizedAttribute)
            let requested: Bool
            if minimizedBefore == false {
                requested = true
            } else {
                let result = AXUIElementSetAttributeValue(
                    window,
                    kAXMinimizedAttribute as CFString,
                    kCFBooleanFalse
                )
                requested = result == .success
                if !requested {
                    let message = "AXUIElementSetAttributeValue AXMinimized failed with \(result)"
                    verification = FileOperationVerification(
                        ok: false,
                        code: "restore_request_failed",
                        message: message
                    )
                    try writeAudit(ok: false, code: "restore_request_failed", message: message)
                    throw CommandError(description: message)
                }
            }

            verification = verifyAccessibilityWindowMinimized(
                window,
                expectedMinimized: false,
                requested: requested,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            minimizedAfter = boolAttribute(window, kAXMinimizedAttribute)
            guard verification?.ok == true else {
                let message = verification?.message ?? "window restore verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Restored window \(requestedElementID) for \(appDisplayName(appRecord!))."
            try writeAudit(ok: true, code: "restored", message: message)

            return DesktopMinimizeWindowResult(
                ok: true,
                action: actionName,
                risk: risk,
                app: appRecord!,
                elementID: requestedElementID,
                window: elementSummary!,
                minimizedBefore: minimizedBefore,
                minimizedAfter: minimizedAfter,
                verification: verification!,
                identityVerification: identityVerification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func desktopRaiseWindow() throws -> DesktopRaiseWindowResult {
        let commandName = "desktop.raise-window"
        let actionName = "desktop.raiseWindow"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = desktopActionRisk(for: actionName)
        let policy = policyDecision(actionRisk: risk)
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var appRecord: AppRecord?
        var elementID: String?
        var elementSummary: AuditElementSummary?
        var identityVerification: IdentityVerification?
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: commandName,
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: actionName,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
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

            let requestedElementID = try normalizedElementID(try requiredOption("--element"))
            guard requestedElementID.first == "w" else {
                let message = "desktop raise-window requires a window element id like w0"
                try writeAudit(ok: false, code: "invalid_window_element", message: message)
                throw CommandError(description: message)
            }
            elementID = requestedElementID

            try requireTrusted()
            let app = try targetRunningApplicationForAppCommand()
            appRecord = self.appRecord(for: app)
            let window = try resolveElement(id: requestedElementID, in: app.processIdentifier)
            elementSummary = auditSummary(
                window,
                pathID: requestedElementID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )

            guard elementSummary?.role == (kAXWindowRole as String) else {
                let message = "target element role is \(elementSummary?.role ?? "unavailable"), not AXWindow"
                try writeAudit(ok: false, code: "target_not_window", message: message)
                throw CommandError(description: message)
            }

            identityVerification = try verifyElementIdentity(elementSummary?.stableIdentity)
            guard identityVerification?.ok != false else {
                let message = identityVerification?.message ?? "window identity verification failed"
                try writeAudit(ok: false, code: identityVerification?.code ?? "identity_rejected", message: message)
                throw CommandError(description: message)
            }

            let availableActions = elementSummary?.actions ?? actionNames(window)
            guard availableActions.contains(kAXRaiseAction as String) else {
                let message = "target window does not expose AXRaise"
                try writeAudit(ok: false, code: "raise_unavailable", message: message)
                throw CommandError(description: message)
            }

            _ = app.activate(options: [])
            let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            guard result == .success else {
                let message = "AXUIElementPerformAction AXRaise failed with \(result)"
                verification = FileOperationVerification(
                    ok: false,
                    code: "raise_request_failed",
                    message: message
                )
                try writeAudit(ok: false, code: "raise_request_failed", message: message)
                throw CommandError(description: message)
            }

            verification = verifyAccessibilityWindowRaised(
                window,
                app: app,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            guard verification?.ok == true else {
                let message = verification?.message ?? "window raise verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Raised window \(requestedElementID) for \(appDisplayName(appRecord!))."
            try writeAudit(ok: true, code: "raised", message: message)

            return DesktopRaiseWindowResult(
                ok: true,
                action: actionName,
                risk: risk,
                app: appRecord!,
                elementID: requestedElementID,
                window: elementSummary!,
                verification: verification!,
                identityVerification: identityVerification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func desktopSetWindowFrame() throws -> DesktopSetWindowFrameResult {
        let commandName = "desktop.set-window-frame"
        let actionName = "desktop.setWindowFrame"
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let risk = desktopActionRisk(for: actionName)
        let policy = policyDecision(actionRisk: risk)
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 2_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        var appRecord: AppRecord?
        var elementID: String?
        var elementSummary: AuditElementSummary?
        var identityVerification: IdentityVerification?
        var requestedFrame: Rect?
        var frameBefore: Rect?
        var frameAfter: Rect?
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: commandName,
                risk: risk,
                reason: option("--reason"),
                app: appRecord,
                elementID: elementID,
                element: elementSummary,
                action: actionName,
                policy: policy,
                verification: verification,
                identityVerification: identityVerification,
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

            requestedFrame = try self.requestedWindowFrame()
            let targetFrame = requestedFrame!

            let requestedElementID = try normalizedElementID(try requiredOption("--element"))
            guard requestedElementID.first == "w" else {
                let message = "desktop set-window-frame requires a window element id like w0"
                try writeAudit(ok: false, code: "invalid_window_element", message: message)
                throw CommandError(description: message)
            }
            elementID = requestedElementID

            try requireTrusted()
            let app = try targetRunningApplicationForAppCommand()
            appRecord = self.appRecord(for: app)
            let window = try resolveElement(id: requestedElementID, in: app.processIdentifier)
            elementSummary = auditSummary(
                window,
                pathID: requestedElementID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )

            guard elementSummary?.role == (kAXWindowRole as String) else {
                let message = "target element role is \(elementSummary?.role ?? "unavailable"), not AXWindow"
                try writeAudit(ok: false, code: "target_not_window", message: message)
                throw CommandError(description: message)
            }

            identityVerification = try verifyElementIdentity(elementSummary?.stableIdentity)
            guard identityVerification?.ok != false else {
                let message = identityVerification?.message ?? "window identity verification failed"
                try writeAudit(ok: false, code: identityVerification?.code ?? "identity_rejected", message: message)
                throw CommandError(description: message)
            }

            let writableAttributes = elementSummary?.settableAttributes ?? settableAttributes(window)
            guard writableAttributes.contains(kAXPositionAttribute as String) else {
                let message = "target window does not expose settable AXPosition"
                try writeAudit(ok: false, code: "position_not_settable", message: message)
                throw CommandError(description: message)
            }
            guard writableAttributes.contains(kAXSizeAttribute as String) else {
                let message = "target window does not expose settable AXSize"
                try writeAudit(ok: false, code: "size_not_settable", message: message)
                throw CommandError(description: message)
            }

            frameBefore = frame(window)

            var targetPosition = CGPoint(x: targetFrame.x, y: targetFrame.y)
            guard let positionValue = AXValueCreate(.cgPoint, &targetPosition) else {
                let message = "failed to encode requested AXPosition"
                try writeAudit(ok: false, code: "position_encode_failed", message: message)
                throw CommandError(description: message)
            }
            let positionResult = AXUIElementSetAttributeValue(
                window,
                kAXPositionAttribute as CFString,
                positionValue
            )
            guard positionResult == .success else {
                let message = "AXUIElementSetAttributeValue AXPosition failed with \(positionResult)"
                verification = FileOperationVerification(
                    ok: false,
                    code: "position_request_failed",
                    message: message
                )
                try writeAudit(ok: false, code: "position_request_failed", message: message)
                throw CommandError(description: message)
            }

            var targetSize = CGSize(width: targetFrame.width, height: targetFrame.height)
            guard let sizeValue = AXValueCreate(.cgSize, &targetSize) else {
                let message = "failed to encode requested AXSize"
                try writeAudit(ok: false, code: "size_encode_failed", message: message)
                throw CommandError(description: message)
            }
            let sizeResult = AXUIElementSetAttributeValue(
                window,
                kAXSizeAttribute as CFString,
                sizeValue
            )
            guard sizeResult == .success else {
                let message = "AXUIElementSetAttributeValue AXSize failed with \(sizeResult)"
                verification = FileOperationVerification(
                    ok: false,
                    code: "size_request_failed",
                    message: message
                )
                try writeAudit(ok: false, code: "size_request_failed", message: message)
                throw CommandError(description: message)
            }

            verification = verifyAccessibilityWindowFrame(
                window,
                requestedFrame: targetFrame,
                timeoutMilliseconds: timeoutMilliseconds,
                intervalMilliseconds: intervalMilliseconds
            )
            frameAfter = frame(window)
            guard verification?.ok == true else {
                let message = verification?.message ?? "window frame verification failed"
                try writeAudit(ok: false, code: "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Set window \(requestedElementID) frame for \(appDisplayName(appRecord!))."
            try writeAudit(ok: true, code: "frame_set", message: message)

            return DesktopSetWindowFrameResult(
                ok: true,
                action: actionName,
                risk: risk,
                app: appRecord!,
                elementID: requestedElementID,
                window: elementSummary!,
                requestedFrame: targetFrame,
                frameBefore: frameBefore,
                frameAfter: frameAfter,
                verification: verification!,
                identityVerification: identityVerification,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
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

    private func activeAccessibilityWindow(for app: NSRunningApplication) throws -> (element: AXUIElement, elementID: String) {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        if let focusedWindow = accessibilityElement(axApp, kAXFocusedWindowAttribute) {
            if let index = windows.firstIndex(where: { CFEqual($0, focusedWindow) }) {
                return (focusedWindow, "w\(index)")
            }
            return (focusedWindow, "focused-window")
        }

        guard let firstWindow = windows.first else {
            throw CommandError(description: "frontmost app has no Accessibility windows")
        }
        return (firstWindow, "w0")
    }

    private func verifyAccessibilityWindowMinimized(
        _ window: AXUIElement,
        expectedMinimized: Bool,
        requested: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        guard requested else {
            return FileOperationVerification(
                ok: false,
                code: "minimize_request_failed",
                message: "macOS did not accept the active window minimize request"
            )
        }

        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000.0)
        repeat {
            if boolAttribute(window, kAXMinimizedAttribute) == expectedMinimized {
                return FileOperationVerification(
                    ok: true,
                    code: expectedMinimized ? "window_minimized" : "window_restored",
                    message: expectedMinimized
                        ? "active window AXMinimized attribute is true"
                        : "window AXMinimized attribute is false"
                )
            }
            if timeoutMilliseconds == 0 {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1000.0)
        } while Date() < deadline

        return FileOperationVerification(
            ok: false,
            code: expectedMinimized ? "window_not_minimized" : "window_still_minimized",
            message: expectedMinimized
                ? "active window was not minimized after the timeout"
                : "window was still minimized after the restore timeout"
        )
    }

    private func verifyAccessibilityWindowRaised(
        _ window: AXUIElement,
        app: NSRunningApplication,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000.0)
        repeat {
            let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            let focusedWindow = accessibilityElement(axApp, kAXFocusedWindowAttribute)
            if frontmostPID == app.processIdentifier,
               let focusedWindow,
               CFEqual(focusedWindow, window) {
                return FileOperationVerification(
                    ok: true,
                    code: "window_raised",
                    message: "target window is focused in the frontmost app"
                )
            }
            if timeoutMilliseconds == 0 {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1000.0)
        } while Date() < deadline

        return FileOperationVerification(
            ok: false,
            code: "window_not_raised",
            message: "target window was not focused in the frontmost app after the timeout"
        )
    }

    private func verifyAccessibilityWindowFrame(
        _ window: AXUIElement,
        requestedFrame: Rect,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> FileOperationVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000.0)
        repeat {
            if let current = frame(window),
               windowFrameMatches(current, requestedFrame, tolerance: 1.0) {
                return FileOperationVerification(
                    ok: true,
                    code: "window_frame_set",
                    message: "target window frame matched the requested geometry"
                )
            }
            if timeoutMilliseconds == 0 {
                break
            }
            Thread.sleep(forTimeInterval: Double(intervalMilliseconds) / 1000.0)
        } while Date() < deadline

        return FileOperationVerification(
            ok: false,
            code: "window_frame_mismatch",
            message: "target window frame did not match the requested geometry after the timeout"
        )
    }

    private func desktopDisplays() -> DesktopDisplaysState {
        var screenByDisplayID: [CGDirectDisplayID: NSScreen] = [:]
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            screenByDisplayID[CGDirectDisplayID(screenNumber.uint32Value)] = screen
        }

        let maxDisplays: UInt32 = 32
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        var displayCount: UInt32 = 0
        let result = CGGetOnlineDisplayList(maxDisplays, &displayIDs, &displayCount)
        guard result == .success else {
            return DesktopDisplaysState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                available: false,
                message: "Display metadata is unavailable from this process.",
                count: 0,
                displays: []
            )
        }

        var resolvedDisplayIDs = Array(displayIDs.prefix(Int(displayCount)))
        if resolvedDisplayIDs.isEmpty {
            resolvedDisplayIDs = screenByDisplayID.keys.sorted()
        }
        let mainDisplayID = CGMainDisplayID()
        if resolvedDisplayIDs.isEmpty, mainDisplayID != 0 {
            resolvedDisplayIDs = [mainDisplayID]
        }

        let displays = resolvedDisplayIDs.map { displayID -> DesktopDisplayRecord in
            let bounds = CGDisplayBounds(displayID)
            let screen = screenByDisplayID[displayID]
            return DesktopDisplayRecord(
                id: "display:\(displayID)",
                displayID: displayID,
                name: screen?.localizedName,
                main: CGDisplayIsMain(displayID) != 0,
                active: CGDisplayIsActive(displayID) != 0,
                online: CGDisplayIsOnline(displayID) != 0,
                builtin: CGDisplayIsBuiltin(displayID) != 0,
                inMirrorSet: CGDisplayIsInMirrorSet(displayID) != 0,
                bounds: Rect(
                    x: Double(bounds.origin.x),
                    y: Double(bounds.origin.y),
                    width: Double(bounds.size.width),
                    height: Double(bounds.size.height)
                ),
                pixelWidth: CGDisplayPixelsWide(displayID),
                pixelHeight: CGDisplayPixelsHigh(displayID),
                scaleFactor: screen.map { Double($0.backingScaleFactor) },
                rotationDegrees: CGDisplayRotation(displayID),
                colorSpaceName: screen?.colorSpace?.localizedName
            )
        }
        .sorted { left, right in
            if left.main != right.main {
                return left.main && !right.main
            }
            if left.active != right.active {
                return left.active && !right.active
            }
            return left.displayID < right.displayID
        }

        return DesktopDisplaysState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            available: true,
            message: displays.isEmpty
                ? "No online displays were reported."
                : "Read connected display metadata.",
            count: displays.count,
            displays: displays
        )
    }

    private func desktopWindowWaitState() throws -> DesktopWindowWaitResult {
        let target = try desktopWindowWaitTarget()
        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
        let verification = try waitForDesktopWindow(
            target: target,
            expectedExists: expectedExists,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            limit: limit
        )

        return DesktopWindowWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            includeDesktop: flag("--include-desktop"),
            includeAllLayers: flag("--all-layers"),
            limit: limit,
            verification: verification,
            message: verification.ok
                ? "Desktop window metadata matched the expected state."
                : verification.message
        )
    }

    private func desktopActiveWindowWaitState() throws -> DesktopActiveWindowWaitResult {
        let target = try desktopActiveWindowWaitTarget(commandName: "desktop wait-active-window")
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = try waitForDesktopActiveWindow(
            target: target,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return DesktopActiveWindowWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Active desktop window metadata matched the expected state."
                : verification.message
        )
    }

    private func desktopActiveWindowWaitTarget(commandName: String) throws -> DesktopActiveWindowWaitTarget {
        let id = option("--id")
        let ownerPID = try option("--owner-pid").map { rawValue -> Int32 in
            guard let pid = Int32(rawValue), pid > 0 else {
                throw CommandError(description: "\(commandName) --owner-pid must be a positive integer")
            }
            return pid
        }
        let bundleIdentifier = option("--bundle-id")
        let title = option("--title")
        let titleMatch = option("--match") ?? "contains"
        guard ["exact", "prefix", "contains"].contains(titleMatch) else {
            throw CommandError(description: "\(commandName) --match must be exact, prefix, or contains")
        }

        return DesktopActiveWindowWaitTarget(
            id: id,
            ownerPID: ownerPID,
            bundleIdentifier: bundleIdentifier,
            title: title,
            titleMatch: titleMatch,
            changedFrom: option("--changed-from")
        )
    }

    private func desktopWindowWaitTarget() throws -> DesktopWindowWaitTarget {
        let id = option("--id")
        let ownerPID = try option("--owner-pid").map { rawValue -> Int32 in
            guard let pid = Int32(rawValue), pid > 0 else {
                throw CommandError(description: "desktop wait-window --owner-pid must be a positive integer")
            }
            return pid
        }
        let bundleIdentifier = option("--bundle-id")
        let title = option("--title")
        let titleMatch = option("--match") ?? "contains"
        guard ["exact", "prefix", "contains"].contains(titleMatch) else {
            throw CommandError(description: "desktop wait-window --match must be exact, prefix, or contains")
        }
        guard id != nil || ownerPID != nil || bundleIdentifier != nil || title != nil else {
            throw CommandError(description: "desktop wait-window requires --id, --owner-pid, --bundle-id, or --title")
        }

        return DesktopWindowWaitTarget(
            id: id,
            ownerPID: ownerPID,
            bundleIdentifier: bundleIdentifier,
            title: title,
            titleMatch: titleMatch
        )
    }

    private func desktopWindowFilterTarget() throws -> DesktopWindowWaitTarget? {
        let id = option("--id")
        let ownerPID = try option("--owner-pid").map { rawValue -> Int32 in
            guard let pid = Int32(rawValue), pid > 0 else {
                throw CommandError(description: "desktop windows --owner-pid must be a positive integer")
            }
            return pid
        }
        let bundleIdentifier = option("--bundle-id")
        let title = option("--title")
        let titleMatch = option("--match") ?? "contains"
        guard ["exact", "prefix", "contains"].contains(titleMatch) else {
            throw CommandError(description: "desktop windows --match must be exact, prefix, or contains")
        }
        guard id != nil || ownerPID != nil || bundleIdentifier != nil || title != nil else {
            return nil
        }

        return DesktopWindowWaitTarget(
            id: id,
            ownerPID: ownerPID,
            bundleIdentifier: bundleIdentifier,
            title: title,
            titleMatch: titleMatch
        )
    }

    private func waitForDesktopWindow(
        target: DesktopWindowWaitTarget,
        expectedExists: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int,
        limit: Int
    ) throws -> DesktopWindowWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var state = try desktopWindows(limitOverride: limit)
        var current = desktopWindowMatches(in: state, target: target)

        while state.available && (current.isEmpty != !expectedExists), Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            state = try desktopWindows(limitOverride: limit)
            current = desktopWindowMatches(in: state, target: target)
        }

        guard state.available else {
            return DesktopWindowWaitVerification(
                ok: false,
                code: "desktop_window_metadata_unavailable",
                message: state.message,
                target: target,
                expectedExists: expectedExists,
                currentCount: 0,
                current: [],
                matched: false
            )
        }

        let matched = current.isEmpty == !expectedExists
        return DesktopWindowWaitVerification(
            ok: matched,
            code: matched ? "desktop_window_matched" : "desktop_window_timeout",
            message: matched
                ? "desktop window state matched expected existence"
                : "desktop window state did not match expected existence before timeout",
            target: target,
            expectedExists: expectedExists,
            currentCount: current.count,
            current: current,
            matched: matched
        )
    }

    private func waitForDesktopActiveWindow(
        target: DesktopActiveWindowWaitTarget,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) throws -> DesktopActiveWindowWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var state = try desktopActiveWindow()
        var matched = desktopActiveWindow(state.window, matches: target)

        while state.available && !matched, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            state = try desktopActiveWindow()
            matched = desktopActiveWindow(state.window, matches: target)
        }

        guard state.available else {
            return DesktopActiveWindowWaitVerification(
                ok: false,
                code: "desktop_window_metadata_unavailable",
                message: state.message,
                target: target,
                current: nil,
                found: false,
                changed: false,
                matched: false
            )
        }

        let changed = desktopActiveWindowChanged(state.window, from: target.changedFrom)
        return DesktopActiveWindowWaitVerification(
            ok: matched,
            code: matched ? "active_desktop_window_matched" : "active_desktop_window_timeout",
            message: matched
                ? "active desktop window matched expected state"
                : "active desktop window did not match expected state before timeout",
            target: target,
            current: state.window,
            found: state.window != nil,
            changed: changed,
            matched: matched
        )
    }

    private func desktopWindowMatches(
        in state: DesktopWindowsState,
        target: DesktopWindowWaitTarget
    ) -> [DesktopWindowRecord] {
        state.windows.filter { desktopWindow($0, matches: target) }
    }

    private func desktopActiveWindow(
        _ window: DesktopWindowRecord?,
        matches target: DesktopActiveWindowWaitTarget
    ) -> Bool {
        guard let window else {
            return false
        }
        if let id = target.id,
           window.id != id && window.stableIdentity.id != id {
            return false
        }
        if let ownerPID = target.ownerPID, window.ownerPID != ownerPID {
            return false
        }
        if let bundleIdentifier = target.bundleIdentifier,
           window.ownerBundleIdentifier != bundleIdentifier {
            return false
        }
        if let title = target.title,
           !desktopWindowTitle(window.title, matches: title, mode: target.titleMatch) {
            return false
        }
        if target.changedFrom != nil && !desktopActiveWindowChanged(window, from: target.changedFrom) {
            return false
        }
        return true
    }

    private func desktopActiveWindowChanged(_ window: DesktopWindowRecord?, from previousID: String?) -> Bool {
        guard let previousID else {
            return false
        }
        guard let window else {
            return false
        }
        return window.id != previousID && window.stableIdentity.id != previousID
    }

    private func desktopWindow(
        _ window: DesktopWindowRecord,
        matches target: DesktopWindowWaitTarget
    ) -> Bool {
        if let id = target.id,
           window.id != id && window.stableIdentity.id != id {
            return false
        }
        if let ownerPID = target.ownerPID, window.ownerPID != ownerPID {
            return false
        }
        if let bundleIdentifier = target.bundleIdentifier,
           window.ownerBundleIdentifier != bundleIdentifier {
            return false
        }
        if let title = target.title,
           !desktopWindowTitle(window.title, matches: title, mode: target.titleMatch) {
            return false
        }
        return true
    }

    private func desktopWindowTitle(_ currentTitle: String?, matches expectedTitle: String, mode: String) -> Bool {
        guard let currentTitle else {
            return false
        }

        switch mode {
        case "exact":
            return currentTitle == expectedTitle
        case "prefix":
            return currentTitle.hasPrefix(expectedTitle)
        case "contains":
            return currentTitle.contains(expectedTitle)
        default:
            return false
        }
    }

    private func desktopActiveWindow() throws -> DesktopActiveWindowState {
        let activeApp = activeAppRecord()
        let activePID = activeApp?.pid ?? NSWorkspace.shared.frontmostApplication?.processIdentifier
        let bundleIdentifierByPID = runningAppBundleIdentifiersByPID()
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]

        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return DesktopActiveWindowState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                available: false,
                found: false,
                message: "Desktop window metadata is unavailable from this process.",
                activePID: activePID,
                app: activeApp,
                window: nil
            )
        }

        let window = rawWindows.compactMap { rawWindow in
            desktopWindowRecord(
                rawWindow,
                activePID: activePID,
                bundleIdentifierByPID: bundleIdentifierByPID,
                includeAllLayers: false
            )
        }.first

        return DesktopActiveWindowState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            available: true,
            found: window != nil,
            message: window == nil
                ? "No frontmost visible desktop window was reported."
                : "Read frontmost visible desktop window metadata.",
            activePID: activePID,
            app: activeApp,
            window: window
        )
    }

    func desktopWindows(limitOverride: Int? = nil) throws -> DesktopWindowsState {
        let includeDesktop = flag("--include-desktop")
        let includeAllLayers = flag("--all-layers")
        let filter = try desktopWindowFilterTarget()
        let limit = limitOverride ?? max(0, option("--limit").flatMap(Int.init) ?? 200)
        let activePID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let bundleIdentifierByPID = runningAppBundleIdentifiersByPID()
        var options: CGWindowListOption = [.optionOnScreenOnly]
        if !includeDesktop {
            options.insert(.excludeDesktopElements)
        }

        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return DesktopWindowsState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                available: false,
                message: "Desktop window metadata is unavailable from this process.",
                activePID: activePID,
                includeDesktop: includeDesktop,
                includeAllLayers: includeAllLayers,
                filter: filter,
                limit: limit,
                count: 0,
                truncated: false,
                windows: []
            )
        }

        let records = rawWindows.compactMap { window -> DesktopWindowRecord? in
            desktopWindowRecord(
                window,
                activePID: activePID,
                bundleIdentifierByPID: bundleIdentifierByPID,
                includeAllLayers: includeAllLayers
            )
        }
        .filter { record in
            guard let filter else {
                return true
            }
            return desktopWindow(record, matches: filter)
        }
        .sorted { left, right in
            if left.active != right.active {
                return left.active && !right.active
            }
            if left.layer != right.layer {
                return left.layer < right.layer
            }
            let leftName = left.ownerName ?? left.ownerBundleIdentifier ?? "\(left.ownerPID)"
            let rightName = right.ownerName ?? right.ownerBundleIdentifier ?? "\(right.ownerPID)"
            if leftName != rightName {
                return leftName < rightName
            }
            return left.windowNumber < right.windowNumber
        }

        let limitedRecords = Array(records.prefix(limit))
        return DesktopWindowsState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            available: true,
            message: records.isEmpty
                ? (filter == nil
                    ? "No matching visible desktop windows were reported."
                    : "No visible desktop windows matched the target filters.")
                : "Read visible desktop window metadata.",
            activePID: activePID,
            includeDesktop: includeDesktop,
            includeAllLayers: includeAllLayers,
            filter: filter,
            limit: limit,
            count: limitedRecords.count,
            truncated: records.count > limitedRecords.count,
            windows: limitedRecords
        )
    }

    private func runningAppBundleIdentifiersByPID() -> [Int32: String] {
        Dictionary(
            uniqueKeysWithValues: NSWorkspace.shared.runningApplications.compactMap { app in
                app.bundleIdentifier.map { (app.processIdentifier, $0) }
            }
        )
    }

    private func desktopWindowRecord(
        _ window: [String: Any],
        activePID: Int32?,
        bundleIdentifierByPID: [Int32: String],
        includeAllLayers: Bool
    ) -> DesktopWindowRecord? {
        guard let windowNumber = uint32Value(window[kCGWindowNumber as String]),
              let ownerPID = int32Value(window[kCGWindowOwnerPID as String]) else {
            return nil
        }

        let layer = intValue(window[kCGWindowLayer as String]) ?? 0
        if !includeAllLayers, layer != 0 {
            return nil
        }

        let ownerName = window[kCGWindowOwnerName as String] as? String
        let ownerBundleIdentifier = bundleIdentifierByPID[ownerPID]
        let title = window[kCGWindowName as String] as? String
        let bounds = rectValue(window[kCGWindowBounds as String])

        return DesktopWindowRecord(
            id: "window:\(windowNumber)",
            stableIdentity: desktopWindowStableIdentity(
                windowNumber: windowNumber,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                ownerPID: ownerPID,
                title: title,
                layer: layer,
                bounds: bounds
            ),
            windowNumber: windowNumber,
            ownerName: ownerName,
            ownerBundleIdentifier: ownerBundleIdentifier,
            ownerPID: ownerPID,
            active: ownerPID == activePID,
            title: title,
            layer: layer,
            bounds: bounds,
            onscreen: boolValue(window[kCGWindowIsOnscreen as String]),
            alpha: doubleValue(window[kCGWindowAlpha as String]),
            memoryUsageBytes: intValue(window[kCGWindowMemoryUsage as String]),
            sharingState: intValue(window[kCGWindowSharingState as String])
        )
    }

    private func uint32Value(_ value: Any?) -> UInt32? {
        if let number = value as? NSNumber {
            return number.uint32Value
        }
        if let value = value as? UInt32 {
            return value
        }
        if let value = value as? Int, value >= 0 {
            return UInt32(value)
        }
        return nil
    }

    private func int32Value(_ value: Any?) -> Int32? {
        if let number = value as? NSNumber {
            return number.int32Value
        }
        if let value = value as? Int32 {
            return value
        }
        if let value = value as? Int {
            return Int32(value)
        }
        return nil
    }

    private func intValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        return value as? Int
    }

    private func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double
    }

    private func boolValue(_ value: Any?) -> Bool? {
        if let number = value as? NSNumber {
            return number.boolValue
        }
        return value as? Bool
    }

    private func rectValue(_ value: Any?) -> Rect? {
        guard let dictionary = value as? NSDictionary,
              let cgRect = CGRect(dictionaryRepresentation: dictionary) else {
            return nil
        }

        return Rect(
            x: Double(cgRect.origin.x),
            y: Double(cgRect.origin.y),
            width: Double(cgRect.width),
            height: Double(cgRect.height)
        )
    }

    private func desktopWindowStableIdentity(
        windowNumber: UInt32,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        ownerPID: Int32,
        title: String?,
        layer: Int,
        bounds: Rect?
    ) -> StableIdentity {
        let normalizedOwnerName = normalizedIdentityText(ownerName)
        let normalizedTitle = normalizedIdentityText(title)
        let owner = ownerBundleIdentifier.flatMap(normalizedIdentityText)
            ?? normalizedOwnerName
            ?? "pid:\(ownerPID)"
        let readableOwner = cleanIdentityText(ownerName)
            ?? ownerBundleIdentifier
            ?? "PID \(ownerPID)"

        var components = [
            "owner": owner,
            "layer": String(layer)
        ]
        var reasons = owner.hasPrefix("pid:")
            ? ["owner process identifier fallback"]
            : ["owner bundle identifier or name"]
        var fingerprintParts = [
            "desktopWindow",
            "owner:\(owner)",
            "layer:\(layer)"
        ]

        if let normalizedTitle {
            components["title"] = normalizedTitle
            reasons.append("window title")
            fingerprintParts.append("title:\(normalizedTitle)")
        } else if let bounds {
            let coarseBounds = coarseBoundsIdentityComponent(bounds)
            components["coarseBounds"] = coarseBounds
            reasons.append("coarse window bounds fallback")
            fingerprintParts.append("bounds:\(coarseBounds)")
        } else {
            components["windowNumberFallback"] = String(windowNumber)
            reasons.append("volatile window number fallback")
            fingerprintParts.append("windowNumber:\(windowNumber)")
        }

        let confidence: String
        if ownerBundleIdentifier != nil, normalizedTitle != nil {
            confidence = "high"
        } else if normalizedOwnerName != nil, normalizedTitle != nil {
            confidence = "medium"
        } else if ownerBundleIdentifier != nil, bounds != nil {
            confidence = "medium"
        } else {
            confidence = "low"
        }

        let label: String
        if let title = cleanIdentityText(title) {
            label = "\(title) window in \(readableOwner)"
        } else if let bounds {
            label = "\(readableOwner) window near \(Int(bounds.x)),\(Int(bounds.y))"
        } else {
            label = "\(readableOwner) window \(windowNumber)"
        }

        let digest = String(sha256Digest(fingerprintParts.joined(separator: "|")).prefix(24))
        return StableIdentity(
            id: "desktopWindow:\(digest)",
            kind: "desktopWindow",
            confidence: confidence,
            label: label,
            components: components,
            reasons: reasons
        )
    }

    private func normalizedIdentityText(_ text: String?) -> String? {
        guard let cleaned = cleanIdentityText(text) else {
            return nil
        }
        return cleaned.lowercased()
    }

    private func cleanIdentityText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func coarseBoundsIdentityComponent(_ bounds: Rect) -> String {
        let width = Int((bounds.width / 50.0).rounded() * 50.0)
        let height = Int((bounds.height / 50.0).rounded() * 50.0)
        let x = Int((bounds.x / 100.0).rounded() * 100.0)
        let y = Int((bounds.y / 100.0).rounded() * 100.0)
        return "x\(x)-y\(y)-w\(width)-h\(height)"
    }

    func runningApps(includeBackground: Bool) -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { app in
                !app.isTerminated
                    && app.processIdentifier > 0
                    && (includeBackground || app.activationPolicy == .regular)
            }
            .sorted { lhs, rhs in
                let lhsName = lhs.localizedName ?? lhs.bundleIdentifier ?? "\(lhs.processIdentifier)"
                let rhsName = rhs.localizedName ?? rhs.bundleIdentifier ?? "\(rhs.processIdentifier)"
                return lhsName < rhsName
            }
    }

    func appState(for app: NSRunningApplication, idPrefix: String, depth: Int, maxChildren: Int) -> AppState {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        let nodes = windows.enumerated().map { index, window in
            buildNode(
                window,
                id: "\(idPrefix)\(index)",
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier,
                depth: depth,
                maxChildren: maxChildren
            )
        }

        return AppState(
            app: AppRecord(
                name: app.localizedName,
                bundleIdentifier: app.bundleIdentifier,
                pid: app.processIdentifier,
                hidden: app.isHidden
            ),
            windows: nodes
        )
    }

    func targetApp() throws -> NSRunningApplication {
        if let pidString = option("--pid"), let pid = pid_t(pidString) {
            if let app = NSRunningApplication(processIdentifier: pid) {
                return app
            }
            throw CommandError(description: "no running app with pid \(pid)")
        }

        guard let app = NSWorkspace.shared.frontmostApplication else {
            throw CommandError(description: "no frontmost application found")
        }

        return app
    }

    func requireTrusted() throws {
        guard AXIsProcessTrusted() else {
            throw CommandError(description: "Accessibility access is not enabled. Run `Ln1 trust` first.")
        }
    }

    func windowOwnerSummaries(activePid: pid_t?) -> [AppSummary] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var byPid: [Int32: AppSummary] = [:]
        for window in rawWindows {
            guard let pid = window[kCGWindowOwnerPID as String] as? Int32 else {
                continue
            }

            let name = window[kCGWindowOwnerName as String] as? String
            byPid[pid] = AppSummary(
                name: name,
                bundleIdentifier: nil,
                pid: pid,
                active: pid == activePid,
                hidden: false
            )
        }

        return byPid.values.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    struct GuardedElementResolution {
        let element: AXUIElement
        let id: String
        let summary: AuditElementSummary
        let identityVerification: IdentityVerification?
    }

    func resolveGuardedElement(id requestedID: String, in app: NSRunningApplication) throws -> GuardedElementResolution {
        let normalizedID = try normalizedElementID(requestedID)
        let expectedIdentity = option("--expect-identity")
        var pathError: CommandError?

        do {
            let element = try resolveElement(id: normalizedID, in: app.processIdentifier)
            let summary = auditSummary(
                element,
                pathID: normalizedID,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )
            let verification = try verifyElementIdentity(summary.stableIdentity)
            if verification?.ok != false {
                return GuardedElementResolution(
                    element: element,
                    id: normalizedID,
                    summary: summary,
                    identityVerification: verification
                )
            }

            pathError = CommandError(description: verification?.message ?? "element identity verification failed")
        } catch let error as CommandError {
            pathError = error
        }

        guard let expectedIdentity else {
            throw pathError ?? CommandError(description: "element path \(normalizedID) could not be resolved")
        }

        let matches = try findAccessibilityElements(
            matchingStableIdentity: expectedIdentity,
            in: app,
            maxDepth: 8,
            maxChildren: 120,
            maxMatches: 2
        )
        guard matches.count == 1, let match = matches.first else {
            let countDescription = matches.isEmpty ? "no current element" : "\(matches.count) current elements"
            throw CommandError(description: "requested element path \(normalizedID) did not verify and \(countDescription) matched expected identity \(expectedIdentity); refusing to guess")
        }

        return match
    }

    private func findAccessibilityElements(
        matchingStableIdentity expectedIdentity: String,
        in app: NSRunningApplication,
        maxDepth: Int,
        maxChildren: Int,
        maxMatches: Int
    ) throws -> [GuardedElementResolution] {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var matches: [GuardedElementResolution] = []

        func visit(_ element: AXUIElement, id: String, remainingDepth: Int) throws {
            guard matches.count < maxMatches else {
                return
            }

            let summary = auditSummary(
                element,
                pathID: id,
                ownerName: app.localizedName,
                ownerBundleIdentifier: app.bundleIdentifier
            )
            if let stableIdentity = summary.stableIdentity, stableIdentity.id == expectedIdentity {
                let verification = try verifyElementIdentity(stableIdentity)
                if verification?.ok != false {
                    matches.append(GuardedElementResolution(
                        element: element,
                        id: id,
                        summary: summary,
                        identityVerification: verification
                    ))
                }
            }

            guard remainingDepth > 0 else {
                return
            }
            for (index, child) in accessibilityArray(element, kAXChildrenAttribute).prefix(maxChildren).enumerated() {
                try visit(child, id: "\(id).\(index)", remainingDepth: remainingDepth - 1)
                if matches.count >= maxMatches {
                    return
                }
            }
        }

        for (index, window) in accessibilityArray(axApp, kAXWindowsAttribute).prefix(maxChildren).enumerated() {
            try visit(window, id: "w\(index)", remainingDepth: maxDepth)
            if matches.count >= maxMatches {
                return matches
            }
        }

        if let menuBar = accessibilityElement(axApp, kAXMenuBarAttribute), matches.count < maxMatches {
            try visit(menuBar, id: "m0", remainingDepth: maxDepth)
        }

        return matches
    }

    private func resolveElement(id: String, in pid: pid_t) throws -> AXUIElement {
        let id = try normalizedElementID(id)
        let axApp = AXUIElementCreateApplication(pid)

        if id.first == "m" {
            let parts = id.dropFirst().split(separator: ".").map(String.init)
            guard let menuIndexString = parts.first, let menuIndex = Int(menuIndexString) else {
                throw CommandError(description: "invalid menu path in element id \(id)")
            }
            guard menuIndex == 0 else {
                throw CommandError(description: "menu bar index \(menuIndex) is out of range")
            }
            guard var current = accessibilityElement(axApp, kAXMenuBarAttribute) else {
                throw CommandError(description: "menu bar is unavailable")
            }
            for childIndexString in parts.dropFirst() {
                current = try childElement(
                    of: current,
                    childIndexString: childIndexString,
                    in: id
                )
            }
            return current
        }

        guard id.first == "w" else {
            throw CommandError(description: "element id must start with a window path like w0 or menu path like m0")
        }

        let parts = id.dropFirst().split(separator: ".").map(String.init)
        guard let windowIndexString = parts.first, let windowIndex = Int(windowIndexString) else {
            throw CommandError(description: "invalid window path in element id \(id)")
        }

        let windows = accessibilityArray(axApp, kAXWindowsAttribute)
        guard windows.indices.contains(windowIndex) else {
            throw CommandError(description: "window index \(windowIndex) is out of range")
        }

        var current = windows[windowIndex]
        for childIndexString in parts.dropFirst() {
            current = try childElement(
                of: current,
                childIndexString: childIndexString,
                in: id
            )
        }

        return current
    }

    private func childElement(
        of element: AXUIElement,
        childIndexString: String,
        in id: String
    ) throws -> AXUIElement {
        guard let childIndex = Int(childIndexString) else {
            throw CommandError(description: "invalid child index '\(childIndexString)' in \(id)")
        }

        let children = accessibilityArray(element, kAXChildrenAttribute)
        guard children.indices.contains(childIndex) else {
            throw CommandError(description: "child index \(childIndex) is out of range in \(id)")
        }
        return children[childIndex]
    }

    func normalizedElementID(_ id: String) throws -> String {
        if id.first == "w" || id.first == "m" {
            return id
        }

        let parts = id.split(separator: ".").map(String.init)
        if parts.count >= 2,
           parts[0].first == "a",
           (parts[1].first == "w" || parts[1].first == "m") {
            return parts.dropFirst().joined(separator: ".")
        }

        throw CommandError(description: "element id must look like w0.1.2, m0.1.2, a0.w0.1.2, or a0.m0.1.2")
    }

    func buildNode(_ element: AXUIElement, id: String, depth: Int, maxChildren: Int) -> ElementNode {
        buildNode(
            element,
            id: id,
            ownerName: nil,
            ownerBundleIdentifier: nil,
            depth: depth,
            maxChildren: maxChildren
        )
    }

    func buildNode(
        _ element: AXUIElement,
        id: String,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        depth: Int,
        maxChildren: Int
    ) -> ElementNode {
        let role = stringAttribute(element, kAXRoleAttribute)
        let subrole = stringAttribute(element, kAXSubroleAttribute)
        let title = stringAttribute(element, kAXTitleAttribute)
        let value = stringLikeAttribute(element, kAXValueAttribute)
        let help = stringAttribute(element, kAXHelpAttribute)
        let enabled = boolAttribute(element, kAXEnabledAttribute)
        let minimized = boolAttribute(element, kAXMinimizedAttribute)
        let elementFrame = frame(element)
        let actions = actionNames(element)
        let writableAttributes = settableAttributes(element)
        let children: [ElementNode]
        if depth > 0 {
            children = accessibilityArray(element, kAXChildrenAttribute)
                .prefix(maxChildren)
                .enumerated()
                .map { index, child in
                    buildNode(
                        child,
                        id: "\(id).\(index)",
                        ownerName: ownerName,
                        ownerBundleIdentifier: ownerBundleIdentifier,
                        depth: depth - 1,
                        maxChildren: maxChildren
                    )
                }
        } else {
            children = []
        }

        return ElementNode(
            id: id,
            stableIdentity: accessibilityElementStableIdentity(
                pathID: id,
                ownerName: ownerName,
                ownerBundleIdentifier: ownerBundleIdentifier,
                role: role,
                subrole: subrole,
                title: title,
                help: help,
                frame: elementFrame,
                actions: actions
            ),
            role: role,
            subrole: subrole,
            title: title,
            value: value,
            help: help,
            enabled: enabled,
            minimized: minimized,
            frame: elementFrame,
            actions: actions,
            settableAttributes: writableAttributes,
            valueSettable: writableAttributes.contains(kAXValueAttribute as String),
            children: children
        )
    }

    private func accessibilityElementStableIdentity(
        pathID: String,
        ownerName: String?,
        ownerBundleIdentifier: String?,
        role: String?,
        subrole: String?,
        title: String?,
        help: String?,
        frame: Rect?,
        actions: [String]
    ) -> StableIdentity {
        let normalizedOwnerName = normalizedIdentityText(ownerName)
        let owner = ownerBundleIdentifier.flatMap(normalizedIdentityText)
            ?? normalizedOwnerName
            ?? "unknown-owner"
        let readableOwner = cleanIdentityText(ownerName)
            ?? ownerBundleIdentifier
            ?? "unknown app"
        var components = ["owner": owner]
        var reasons = owner == "unknown-owner"
            ? ["owner unavailable"]
            : ["owner bundle identifier or name"]
        var fingerprintParts = [
            "accessibilityElement",
            "owner:\(owner)"
        ]

        if let role {
            components["role"] = role
            reasons.append("role")
            fingerprintParts.append("role:\(role)")
        }
        if let subrole {
            components["subrole"] = subrole
            reasons.append("subrole")
            fingerprintParts.append("subrole:\(subrole)")
        }
        if let normalizedTitle = normalizedIdentityText(title) {
            components["title"] = normalizedTitle
            reasons.append("title")
            fingerprintParts.append("title:\(normalizedTitle)")
        } else if let normalizedHelp = normalizedIdentityText(help) {
            components["help"] = normalizedHelp
            reasons.append("help")
            fingerprintParts.append("help:\(normalizedHelp)")
        }

        if !actions.isEmpty {
            let joinedActions = actions.joined(separator: ",")
            components["actions"] = joinedActions
            reasons.append("available actions")
            fingerprintParts.append("actions:\(joinedActions)")
        }

        if let frame {
            let coarseFrame = coarseBoundsIdentityComponent(frame)
            components["coarseFrame"] = coarseFrame
            reasons.append("coarse frame")
            fingerprintParts.append("frame:\(coarseFrame)")
        } else if components["title"] == nil, components["help"] == nil {
            components["pathFallback"] = pathID
            reasons.append("path fallback")
            fingerprintParts.append("path:\(pathID)")
        }

        let hasOwner = owner != "unknown-owner"
        let hasRole = role != nil
        let hasSemanticLabel = components["title"] != nil || components["help"] != nil
        let confidence: String
        if hasOwner, hasRole, hasSemanticLabel, frame != nil {
            confidence = "high"
        } else if hasOwner, hasRole, hasSemanticLabel || frame != nil {
            confidence = "medium"
        } else {
            confidence = "low"
        }

        let label: String
        if let title = cleanIdentityText(title) {
            label = "\(title) \(role ?? "element") in \(readableOwner)"
        } else if let help = cleanIdentityText(help) {
            label = "\(help) \(role ?? "element") in \(readableOwner)"
        } else if let frame {
            label = "\(role ?? "element") in \(readableOwner) near \(Int(frame.x)),\(Int(frame.y))"
        } else {
            label = "\(role ?? "element") at \(pathID) in \(readableOwner)"
        }

        let digest = String(sha256Digest(fingerprintParts.joined(separator: "|")).prefix(24))
        return StableIdentity(
            id: "accessibilityElement:\(digest)",
            kind: "accessibilityElement",
            confidence: confidence,
            label: label,
            components: components,
            reasons: reasons
        )
    }

    func accessibilityArray(_ element: AXUIElement, _ attribute: String) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let array = value as? [AXUIElement] else {
            return []
        }
        return array
    }

    func accessibilityElement(_ element: AXUIElement, _ attribute: String) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }

    func actionNames(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(element, &names) == .success,
              let names = names as? [String] else {
            return []
        }
        return names.sorted()
    }

    private func settableAttributes(_ element: AXUIElement) -> [String] {
        var names: CFArray?
        guard AXUIElementCopyAttributeNames(element, &names) == .success,
              let names = names as? [String] else {
            return []
        }
        return names
            .filter { isAttributeSettable($0, on: element) }
            .sorted()
    }

    private func isAttributeSettable(_ attribute: String, on element: AXUIElement) -> Bool {
        var settable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute as CFString, &settable)
        return result == .success && settable.boolValue
    }

    func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    func stringLikeAttribute(_ element: AXUIElement, _ attribute: String) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let value else {
            return nil
        }

        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    func boolAttribute(_ element: AXUIElement, _ attribute: String) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let number = value as? NSNumber else {
            return nil
        }
        return number.boolValue
    }

    private func frame(_ element: AXUIElement) -> Rect? {
        guard let position = pointAttribute(element, kAXPositionAttribute),
              let size = sizeAttribute(element, kAXSizeAttribute) else {
            return nil
        }

        return Rect(
            x: Double(position.x),
            y: Double(position.y),
            width: Double(size.width),
            height: Double(size.height)
        )
    }

    private func requestedWindowFrame() throws -> Rect {
        let x = try finiteDoubleOption("--x")
        let y = try finiteDoubleOption("--y")
        let width = try finiteDoubleOption("--width")
        let height = try finiteDoubleOption("--height")
        guard width > 0, height > 0 else {
            throw CommandError(description: "window frame width and height must be greater than zero")
        }
        return Rect(x: x, y: y, width: width, height: height)
    }

    private func finiteDoubleOption(_ name: String) throws -> Double {
        let rawValue = try requiredOption(name)
        guard let value = Double(rawValue), value.isFinite else {
            throw CommandError(description: "\(name) must be a finite number")
        }
        return value
    }

    private func windowFrameMatches(_ lhs: Rect, _ rhs: Rect, tolerance: Double) -> Bool {
        abs(lhs.x - rhs.x) <= tolerance
            && abs(lhs.y - rhs.y) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }

    private func pointAttribute(_ element: AXUIElement, _ attribute: String) -> CGPoint? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        guard AXValueGetType(axValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        AXValueGetValue(axValue, .cgPoint, &point)
        return point
    }

    private func sizeAttribute(_ element: AXUIElement, _ attribute: String) -> CGSize? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success,
              let rawValue = value,
              CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = rawValue as! AXValue
        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        AXValueGetValue(axValue, .cgSize, &size)
        return size
    }

    func writeJSON<T: Encodable>(_ value: T) throws {
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw CommandError(description: "failed to encode JSON")
        }
        print(string)
    }

    func option(_ name: String) -> String? {
        guard let index = arguments.firstIndex(of: name) else {
            return nil
        }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }
        return arguments[valueIndex]
    }

    func flag(_ name: String) -> Bool {
        arguments.contains(name)
    }

    func requiredOption(_ name: String) throws -> String {
        guard let value = option(name), !value.isEmpty else {
            throw CommandError(description: "missing required option \(name)")
        }
        return value
    }

    func requiredDoubleOption(_ name: String) throws -> Double {
        let value = try requiredOption(name)
        guard let number = Double(value), number.isFinite else {
            throw CommandError(description: "option \(name) must be a finite number")
        }
        return number
    }

    func optionalInt32Option(_ name: String) throws -> Int32? {
        guard let value = option(name) else {
            return nil
        }
        guard let number = Int32(value) else {
            throw CommandError(description: "option \(name) must be a 32-bit integer")
        }
        return number
    }

    func parseBool(_ value: String) -> Bool {
        switch value.lowercased() {
        case "1", "true", "yes", "y":
            return true
        default:
            return false
        }
    }
}
