import Foundation

extension Ln1CLI {
    func workflowStatus() throws {
        try requirePolicyAllowed(action: "workflow.status")
        let workflowURL = try workflowLogURL()
        let limit = max(0, option("--limit").flatMap(Int.init) ?? 50)
        let operation = option("--operation")
        let entries = try readWorkflowTranscriptDictionaries(
            from: workflowURL,
            limit: limit,
            operation: operation
        )
        let latest = entries.last
        let latestStatus = workflowStatusLatest(from: latest)
        let blockers = Array(Set(entries.flatMap { $0["blockers"] as? [String] ?? [] })).sorted()
        let mutationSummary = workflowMutationSummary(from: entries)
        let phaseCounts = workflowPhaseCounts(from: entries)
        let presentPhases = Set(phaseCounts.filter { $0.count > 0 }.map(\.phase))
        let transcriptPhases = ["inspect", "preflight", "act", "verify", "audit"]
        let missingTranscriptPhases = transcriptPhases.filter { !presentPhases.contains($0) }
        let resumePlan = try workflowResumePlan(
            latest: latest,
            workflowURL: workflowURL,
            operation: operation
        )

        let status: String
        if entries.isEmpty {
            status = "empty"
        } else if !blockers.isEmpty {
            status = "blocked"
        } else if mutationSummary.gaps.isEmpty {
            status = "ready"
        } else {
            status = "needs_review"
        }

        try writeJSON(WorkflowStatusReport(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            path: workflowURL.path,
            operation: operation,
            limit: limit,
            count: entries.count,
            status: status,
            controlLoop: ["observe", "inspect", "preflight", "act", "verify", "audit"],
            phaseCounts: phaseCounts,
            missingTranscriptPhases: missingTranscriptPhases,
            latest: latestStatus,
            blockers: blockers,
            mutationSummary: mutationSummary,
            nextCommand: resumePlan.nextCommand,
            nextArguments: resumePlan.nextArguments,
            message: workflowStatusMessage(
                entries: entries,
                status: status,
                mutationSummary: mutationSummary,
                missingTranscriptPhases: missingTranscriptPhases
            )
        ))
    }

    private func workflowStatusLatest(from latest: [String: Any]?) -> WorkflowStatusLatest? {
        guard let latest else {
            return nil
        }
        let execution = latest["execution"] as? [String: Any]
        return WorkflowStatusLatest(
            transcriptID: latest["transcriptID"] as? String,
            operation: latest["operation"] as? String,
            phase: workflowPhase(for: latest),
            status: workflowEntryStatus(latest),
            risk: latest["risk"] as? String,
            mutates: latest["mutates"] as? Bool ?? false,
            dryRun: latest["dryRun"] as? Bool ?? false,
            executed: latest["executed"] as? Bool ?? false,
            exitCode: execution?["exitCode"] as? Int,
            timedOut: execution?["timedOut"] as? Bool ?? false
        )
    }

    private func workflowPhaseCounts(from entries: [[String: Any]]) -> [WorkflowPhaseCount] {
        let phases = ["inspect", "preflight", "act", "verify", "audit"]
        let counts = Dictionary(grouping: entries, by: workflowPhase(for:))
            .mapValues(\.count)
        return phases.map { phase in
            WorkflowPhaseCount(phase: phase, count: counts[phase] ?? 0)
        }
    }

    private func workflowPhase(for entry: [String: Any]) -> String {
        if entry["dryRun"] as? Bool == true {
            return "preflight"
        }
        let operation = entry["operation"] as? String ?? ""
        if operation == "review-audit" {
            return "audit"
        }
        if entry["mutates"] as? Bool == true {
            return "act"
        }
        if operation.hasPrefix("wait-")
            || operation == "checksum-file"
            || operation == "compare-files"
            || operation == "inspect-clipboard"
            || operation == "inspect-file" {
            return "verify"
        }
        return "inspect"
    }

    private func workflowEntryStatus(_ entry: [String: Any]) -> String {
        let blockers = entry["blockers"] as? [String] ?? []
        if !blockers.isEmpty {
            return "blocked"
        }
        let execution = entry["execution"] as? [String: Any]
        if execution?["timedOut"] as? Bool == true {
            return "timed_out"
        }
        if entry["executed"] as? Bool == true {
            return (execution?["exitCode"] as? Int) == 0 ? "completed" : "failed"
        }
        if entry["dryRun"] as? Bool == true {
            return "planned"
        }
        return "not_executed"
    }

    private func workflowMutationSummary(from entries: [[String: Any]]) -> WorkflowMutationSummary {
        let mutatingEntries = entries.filter { $0["mutates"] as? Bool == true }
        let executedEntries = mutatingEntries.filter { $0["executed"] as? Bool == true }
        var withReason = 0
        var withAuditEvidence = 0
        var withVerificationEvidence = 0
        var gaps: [WorkflowMutationGap] = []

        for entry in executedEntries {
            let evidence = workflowMutationEvidence(entry)
            if evidence.reason {
                withReason += 1
            }
            if evidence.audit {
                withAuditEvidence += 1
            }
            if evidence.verification {
                withVerificationEvidence += 1
            }

            var missing: [String] = []
            if !evidence.reason {
                missing.append("reason")
            }
            if !evidence.audit {
                missing.append("audit")
            }
            if !evidence.verification {
                missing.append("verification")
            }
            if !missing.isEmpty {
                gaps.append(WorkflowMutationGap(
                    transcriptID: entry["transcriptID"] as? String,
                    operation: entry["operation"] as? String,
                    missing: missing
                ))
            }
        }

        return WorkflowMutationSummary(
            planned: mutatingEntries.count,
            executed: executedEntries.count,
            withReason: withReason,
            withAuditEvidence: withAuditEvidence,
            withVerificationEvidence: withVerificationEvidence,
            gaps: gaps
        )
    }

    private func workflowMutationEvidence(_ entry: [String: Any]) -> (reason: Bool, audit: Bool, verification: Bool) {
        let command = entry["command"] as? [String: Any]
        let argv = command?["argv"] as? [String]
            ?? (entry["execution"] as? [String: Any])?["argv"] as? [String]
            ?? []
        let reason = workflowArgumentValue(in: argv, for: "--reason")
            .map { !$0.isEmpty && $0 != "Describe intent" } ?? false
        let outputJSON = (entry["execution"] as? [String: Any])?["outputJSON"] as? [String: Any]
        let audit = outputJSON?["auditID"] as? String != nil
            || outputJSON?["auditLogPath"] as? String != nil
            || workflowArgumentValue(in: argv, for: "--audit-log") != nil
        let verification = (outputJSON?["verification"] as? [String: Any])?["ok"] != nil
            || outputJSON?["urlVerification"] as? [String: Any] != nil
        return (reason, audit, verification)
    }

    private func workflowStatusMessage(
        entries: [[String: Any]],
        status: String,
        mutationSummary: WorkflowMutationSummary,
        missingTranscriptPhases: [String]
    ) -> String {
        if entries.isEmpty {
            return "No workflow transcript entries matched; start with observe, then use workflow scenarios or preflight."
        }
        if status == "blocked" {
            return "Workflow transcript contains blockers; resolve prerequisites before executing another action."
        }
        if !mutationSummary.gaps.isEmpty {
            return "Workflow transcript has mutating executions missing reason, audit, or verification evidence."
        }
        if !missingTranscriptPhases.isEmpty {
            return "Workflow transcript is healthy so far; continue through the missing loop phases before treating the task as complete."
        }
        return "Workflow transcript covers inspect, preflight, act, verify, and audit phases with mutation evidence."
    }
}
