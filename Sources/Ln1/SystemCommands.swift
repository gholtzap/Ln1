import Foundation

extension Ln1CLI {
    func system() throws {
        let mode = arguments.dropFirst().first ?? "context"
        switch mode {
        case "context", "info":
            try writeJSON(systemContextState())
        case "--help", "-h", "help":
            printHelp()
        default:
            throw CommandError(description: "unknown system mode '\(mode)'")
        }
    }

    func benchmarks() throws {
        let mode = arguments.dropFirst().first ?? "matrix"
        switch mode {
        case "matrix":
            try writeJSON(realAppBenchmarkMatrix())
        case "--help", "-h", "help":
            printHelp()
        default:
            throw CommandError(description: "unknown benchmarks mode '\(mode)'")
        }
    }

    func systemContextState() -> SystemContextState {
        let processInfo = ProcessInfo.processInfo
        let version = processInfo.operatingSystemVersion
        return SystemContextState(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            hostName: processInfo.hostName,
            userName: NSUserName(),
            homeDirectory: NSHomeDirectory(),
            currentDirectory: FileManager.default.currentDirectoryPath,
            shellPath: processInfo.environment["SHELL"],
            processIdentifier: processInfo.processIdentifier,
            executablePath: Bundle.main.executableURL?.path,
            operatingSystemVersion: "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)",
            operatingSystemVersionString: processInfo.operatingSystemVersionString,
            architecture: systemArchitecture(),
            processorCount: processInfo.processorCount,
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemoryBytes: processInfo.physicalMemory,
            systemUptimeSeconds: processInfo.systemUptime,
            timeZoneIdentifier: TimeZone.current.identifier,
            localeIdentifier: Locale.current.identifier
        )
    }

    func systemArchitecture() -> String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #elseif arch(arm)
        return "arm"
        #elseif arch(i386)
        return "i386"
        #else
        return "unknown"
        #endif
    }

}
