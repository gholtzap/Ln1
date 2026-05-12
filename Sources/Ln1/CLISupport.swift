import Foundation

struct CommandError: Error, CustomStringConvertible {
    let description: String
}

struct WorkflowOutputSnapshot {
    let data: Data
    let totalBytes: Int
    let truncated: Bool
}

final class WorkflowOutputCapture: @unchecked Sendable {
    private let lock = NSLock()
    private let maxOutputBytes: Int
    private var data = Data()
    private var totalBytes = 0
    private var truncated = false

    init(maxOutputBytes: Int) {
        self.maxOutputBytes = maxOutputBytes
    }

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else {
            return
        }

        lock.lock()
        defer { lock.unlock() }

        totalBytes += chunk.count
        let remainingBytes = maxOutputBytes - data.count
        if remainingBytes <= 0 {
            truncated = true
            return
        }
        if chunk.count <= remainingBytes {
            data.append(chunk)
        } else {
            data.append(chunk.prefix(remainingBytes))
            truncated = true
        }
    }

    func snapshot() -> WorkflowOutputSnapshot {
        lock.lock()
        defer { lock.unlock() }

        return WorkflowOutputSnapshot(
            data: data,
            totalBytes: totalBytes,
            truncated: truncated
        )
    }
}
