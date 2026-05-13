import Foundation

extension Ln1CLI {
    func audit() throws {
        let auditURL = try auditLogURL()
        let limit = option("--limit").flatMap(Int.init) ?? 20
        let id = option("--id")
        let command = option("--command")
        let code = option("--code")
        let records = try readAuditRecords(
            from: auditURL,
            limit: max(0, limit),
            id: id,
            command: command,
            code: code
        )
        try writeJSON(AuditEntries(
            path: auditURL.path,
            id: id,
            command: command,
            code: code,
            limit: max(0, limit),
            entries: records
        ))
    }

    func task() throws {
        let mode = arguments.dropFirst().first ?? "show"

        switch mode {
        case "start":
            try requirePolicyAllowed(action: "task.memoryStart")
            let title = try requiredOption("--title")
            let taskID = option("--task-id") ?? UUID().uuidString
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: "task.started",
                status: "active",
                title: title,
                summary: option("--summary"),
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "record":
            try requirePolicyAllowed(action: "task.memoryRecord")
            let taskID = try requiredOption("--task-id")
            let kind = try taskMemoryKind(try requiredOption("--kind"))
            let summary = try requiredOption("--summary")
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: kind,
                status: nil,
                title: nil,
                summary: summary,
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "finish":
            try requirePolicyAllowed(action: "task.memoryFinish")
            let taskID = try requiredOption("--task-id")
            let status = try taskFinishStatus(option("--status") ?? "completed")
            let event = try taskMemoryEvent(
                taskID: taskID,
                kind: "task.finished",
                status: status,
                title: nil,
                summary: option("--summary"),
                relatedAuditID: option("--related-audit-id")
            )
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try appendTaskMemoryEvent(event, to: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: 50))
        case "show":
            try requirePolicyAllowed(action: "task.memoryShow")
            let taskID = try requiredOption("--task-id")
            let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
            let memoryURL = try taskMemoryURL()
            try requireTaskExists(taskID: taskID, in: memoryURL)
            try writeJSON(try taskMemoryResult(taskID: taskID, from: memoryURL, limit: limit))
        default:
            throw CommandError(description: "unknown task mode '\(mode)'")
        }
    }

    func taskMemoryActionRisk(for action: String) -> String {
        switch action {
        case "task.memoryStart", "task.memoryRecord", "task.memoryFinish", "task.memoryShow":
            return "medium"
        default:
            return "unknown"
        }
    }

}
