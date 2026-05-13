import AppKit
import Darwin
import Foundation

extension Ln1CLI {
    func runningProcessRecords() -> [ProcessRecord] {
        let bytesNeeded = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard bytesNeeded > 0 else {
            return []
        }

        let pidCapacity = Int(bytesNeeded) / MemoryLayout<pid_t>.stride
        var pids = [pid_t](repeating: 0, count: pidCapacity)
        let bytesReturned = pids.withUnsafeMutableBytes { buffer in
            proc_listpids(
                UInt32(PROC_ALL_PIDS),
                0,
                buffer.baseAddress,
                Int32(buffer.count)
            )
        }
        guard bytesReturned > 0 else {
            return []
        }

        let returnedCount = min(
            pids.count,
            Int(bytesReturned) / MemoryLayout<pid_t>.stride
        )
        return pids
            .prefix(returnedCount)
            .filter { $0 > 0 }
            .compactMap(processRecord(for:))
            .sorted(by: processRecordPrecedes)
    }

    func processRecord(for pid: pid_t) -> ProcessRecord? {
        let name = processName(for: pid)
        let path = processPath(for: pid)
        let app = NSRunningApplication(processIdentifier: pid)
        if name == nil, path == nil, app == nil {
            return nil
        }

        let activePID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        return ProcessRecord(
            pid: pid,
            name: name,
            executablePath: path,
            bundleIdentifier: app?.bundleIdentifier,
            appName: app?.localizedName,
            activeApp: pid == activePID,
            currentProcess: pid == getpid()
        )
    }

    func processName(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 1_024)
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else {
            return nil
        }
        return stringFromNullTerminatedBuffer(buffer)
    }

    func processPath(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4_096)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else {
            return nil
        }
        return stringFromNullTerminatedBuffer(buffer)
    }

    func processRecordPrecedes(_ lhs: ProcessRecord, _ rhs: ProcessRecord) -> Bool {
        if lhs.currentProcess != rhs.currentProcess {
            return lhs.currentProcess && !rhs.currentProcess
        }
        if lhs.activeApp != rhs.activeApp {
            return lhs.activeApp && !rhs.activeApp
        }
        let lhsGUI = lhs.bundleIdentifier != nil
        let rhsGUI = rhs.bundleIdentifier != nil
        if lhsGUI != rhsGUI {
            return lhsGUI && !rhsGUI
        }
        return lhs.pid < rhs.pid
    }

    func waitForProcess(
        pid: pid_t,
        expectedExists: Bool,
        timeoutMilliseconds: Int,
        intervalMilliseconds: Int
    ) -> ProcessWaitVerification {
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1_000.0)
        var current = processRecord(for: pid)

        while (current != nil) != expectedExists, Date() < deadline {
            let remainingMilliseconds = max(0, Int(deadline.timeIntervalSinceNow * 1_000))
            let sleepMilliseconds = min(intervalMilliseconds, max(10, remainingMilliseconds))
            Thread.sleep(forTimeInterval: Double(sleepMilliseconds) / 1_000.0)
            current = processRecord(for: pid)
        }

        let matched = (current != nil) == expectedExists
        return ProcessWaitVerification(
            ok: matched,
            code: matched ? "process_matched" : "process_timeout",
            message: matched
                ? "process existence matched expected state"
                : "process existence did not match expected state before timeout",
            pid: pid,
            expectedExists: expectedExists,
            current: current,
            matched: matched
        )
    }

    func stringFromNullTerminatedBuffer(_ buffer: [CChar]) -> String? {
        let endIndex = buffer.firstIndex(of: 0) ?? buffer.count
        guard endIndex > 0 else {
            return nil
        }
        let bytes = buffer[..<endIndex].map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    func processes() throws {
        let mode = arguments.dropFirst().first
        switch mode {
        case nil:
            try writeJSON(processListState())
        case let option? where option.hasPrefix("--"):
            try writeJSON(processListState())
        case "list":
            try writeJSON(processListState())
        case "inspect":
            try writeJSON(processInspectState())
        case "wait":
            try writeJSON(processWaitState())
        case "--help", "-h", "help":
            printHelp()
        default:
            throw CommandError(description: "unknown processes mode '\(mode!)'")
        }
    }

    func processListState() throws -> ProcessListState {
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 200)
        let nameFilter = option("--name")?.lowercased()
        var records = runningProcessRecords()
        if let nameFilter, !nameFilter.isEmpty {
            records = records.filter { record in
                (record.name?.lowercased().contains(nameFilter) == true)
                    || (record.appName?.lowercased().contains(nameFilter) == true)
                    || (record.bundleIdentifier?.lowercased().contains(nameFilter) == true)
            }
        }

        let limited = Array(records.prefix(limit))
        return ProcessListState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            limit: limit,
            count: limited.count,
            truncated: records.count > limited.count,
            processes: limited
        )
    }

    func processInspectState() throws -> ProcessInspectState {
        let pid: pid_t
        if flag("--current") {
            pid = getpid()
        } else if let rawPID = option("--pid"), let parsedPID = pid_t(rawPID), parsedPID > 0 {
            pid = parsedPID
        } else {
            throw CommandError(description: "processes inspect requires --pid PID or --current")
        }

        guard let record = processRecord(for: pid) else {
            return ProcessInspectState(
                generatedAt: ISO8601DateFormatter().string(from: Date()),
                platform: "macOS",
                found: false,
                process: nil,
                message: "No running process metadata was available for pid \(pid)."
            )
        }

        return ProcessInspectState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            found: true,
            process: record,
            message: "Read process metadata for pid \(pid)."
        )
    }

    func processWaitState() throws -> ProcessWaitResult {
        guard let rawPID = option("--pid"), let pid = pid_t(rawPID), pid > 0 else {
            throw CommandError(description: "processes wait requires --pid PID")
        }

        let expectedExists = option("--exists").map(parseBool) ?? true
        let timeoutMilliseconds = max(0, option("--timeout-ms").flatMap(Int.init) ?? 5_000)
        let intervalMilliseconds = max(10, option("--interval-ms").flatMap(Int.init) ?? 100)
        let verification = waitForProcess(
            pid: pid,
            expectedExists: expectedExists,
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds
        )

        return ProcessWaitResult(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            timeoutMilliseconds: timeoutMilliseconds,
            intervalMilliseconds: intervalMilliseconds,
            verification: verification,
            message: verification.ok
                ? "Process matched the expected existence state."
                : "Timed out waiting for process existence state."
        )
    }

}
