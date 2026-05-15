import Foundation

extension Ln1CLI {
    func workflowScenarios() throws {
        try requirePolicyAllowed(action: "workflow.scenarios")
        let scenarios = workflowScenarioDefinitions()
        let requestedID = option("--id")
        let selected: [WorkflowScenario]

        if let requestedID {
            selected = scenarios.filter { $0.id == requestedID }
            guard !selected.isEmpty else {
                let knownIDs = scenarios.map(\.id).joined(separator: ", ")
                throw CommandError(description: "unknown workflow scenario '\(requestedID)'. Use one of: \(knownIDs).")
            }
        } else {
            selected = scenarios
        }

        try writeJSON(WorkflowScenarioCatalog(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            platform: "macOS",
            productPromise: "Structured state first, guarded actions second, screenshots last.",
            controlLoop: ["observe", "inspect", "preflight", "act", "verify", "audit"],
            defaultSafetyGates: [
                "Start with read-only observation before choosing a target.",
                "Use workflow preflight or dry-run before every mutating action.",
                "Require explicit --execute-mutating true and a non-placeholder --reason for mutating workflow runs.",
                "Guard Accessibility targets with element IDs and stable identity checks when available.",
                "Resume from workflow transcripts or audit records before choosing the next action."
            ],
            scenarioCount: selected.count,
            scenarios: selected,
            message: requestedID == nil
                ? "Use --id SCENARIO_ID to print one focused recipe."
                : "Scenario recipe selected."
        ))
    }

    private func workflowScenarioDefinitions() -> [WorkflowScenario] {
        [
            WorkflowScenario(
                id: "desktop-app-qa",
                title: "Desktop App QA",
                purpose: "Exercise a native macOS app through structured Accessibility and desktop state instead of coordinate clicks.",
                highestRisk: "high",
                idealFor: [
                    "Smoke-testing local app builds",
                    "Verifying menus, windows, sheets, and dialogs",
                    "Producing reproducible UI failure reports"
                ],
                phases: [
                    WorkflowScenarioPhase(
                        name: "observe",
                        intent: "Capture the active app, visible windows, blockers, and suggested next commands.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "observe desktop",
                                command: "Ln1 observe --app-limit 20 --window-limit 50",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "inspect frontmost app",
                                command: "Ln1 workflow run --operation inspect-frontmost-app --dry-run true",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "inspect",
                        intent: "Find stable app, window, menu, and element targets before acting.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "inspect windows",
                                command: "Ln1 workflow run --operation inspect-windows --limit 50 --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "inspect menu",
                                command: "Ln1 workflow run --operation inspect-menu --pid PID --depth 2 --max-children 80 --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "find element",
                                command: "Ln1 workflow preflight --operation find-element --pid PID --title Save --action AXPress --include-menu --limit 20",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "act",
                        intent: "Run one reviewed mutation with policy, reason, identity, and audit evidence.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "press reviewed element",
                                command: "Ln1 workflow run --operation control-active-app --pid PID --element ELEMENT_ID --expect-identity STABLE_ID --allow-risk medium --dry-run false --execute-mutating true --reason TEXT",
                                risk: "medium",
                                mutates: true
                            ),
                            WorkflowScenarioCommand(
                                name: "close reviewed window",
                                command: "Ln1 workflow run --operation close-window --pid PID --element WINDOW_ID --expect-identity STABLE_ID --allow-risk high --dry-run false --execute-mutating true --reason TEXT",
                                risk: "high",
                                mutates: true
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "verify-audit",
                        intent: "Ground the next step in verified state and inspect the audit trail.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "resume workflow",
                                command: "Ln1 workflow resume --allow-risk medium",
                                risk: "medium",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "review audit",
                                command: "Ln1 workflow run --operation review-audit --id AUDIT_ID --allow-risk medium --dry-run true",
                                risk: "medium",
                                mutates: false
                            )
                        ]
                    )
                ],
                verificationSignals: [
                    "The target app and window identities still match before mutation.",
                    "The post-action window, element, or app state changed as expected.",
                    "workflow resume recommends a read-only next inspection before another action."
                ],
                auditArtifacts: [
                    "workflow transcript JSONL",
                    "action audit JSONL",
                    "stable Accessibility element identity",
                    "post-action verification result"
                ]
            ),
            WorkflowScenario(
                id: "browser-regression",
                title: "Browser Regression",
                purpose: "Drive a browser page through DevTools-backed selectors, waits, console/network inspection, and resumable verification.",
                highestRisk: "medium",
                idealFor: [
                    "Testing local web apps",
                    "Debugging form flows",
                    "Capturing console, dialog, DOM, and network evidence"
                ],
                phases: [
                    WorkflowScenarioPhase(
                        name: "inspect",
                        intent: "Read the page before interacting with it.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "read browser",
                                command: "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "inspect console",
                                command: "Ln1 browser console --endpoint http://127.0.0.1:9222 --id TARGET_ID",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "preflight-act",
                        intent: "Preview selector-based browser mutations, then execute only with explicit approval.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "fill field",
                                command: "Ln1 workflow run --operation fill-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector CSS_SELECTOR --text TEXT --allow-risk medium --dry-run false --execute-mutating true --reason TEXT",
                                risk: "medium",
                                mutates: true
                            ),
                            WorkflowScenarioCommand(
                                name: "click and expect navigation",
                                command: "Ln1 workflow run --operation click-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector CSS_SELECTOR --expect-url URL --match contains --allow-risk medium --dry-run false --execute-mutating true --reason TEXT",
                                risk: "medium",
                                mutates: true
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "verify-audit",
                        intent: "Wait for page state and resume from the transcript before choosing the next browser action.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "wait ready",
                                command: "Ln1 workflow run --operation wait-browser-ready --endpoint http://127.0.0.1:9222 --id TARGET_ID --state complete --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "resume browser workflow",
                                command: "Ln1 workflow resume --operation click-browser --allow-risk medium",
                                risk: "medium",
                                mutates: false
                            )
                        ]
                    )
                ],
                verificationSignals: [
                    "Selectors resolve before mutation.",
                    "URL, text, ready-state, focus, enabled, checked, or attribute waits confirm the expected page state.",
                    "Console, dialogs, and network reads capture debugging evidence."
                ],
                auditArtifacts: [
                    "workflow transcript JSONL",
                    "selector and target tab metadata",
                    "post-action URL or selector verification",
                    "console/network/dialog snapshots"
                ]
            ),
            WorkflowScenario(
                id: "file-export-verification",
                title: "File Export Verification",
                purpose: "Verify app-generated files with filesystem metadata, checksums, and rollback-aware audit trails.",
                highestRisk: "medium",
                idealFor: [
                    "Export and download validation",
                    "Report generation checks",
                    "Moving generated artifacts into review folders"
                ],
                phases: [
                    WorkflowScenarioPhase(
                        name: "watch",
                        intent: "Wait for the artifact to appear with expected metadata before trusting it.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "wait file",
                                command: "Ln1 workflow run --operation wait-file --path PATH --size-bytes N --wait-timeout-ms 30000 --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "checksum file",
                                command: "Ln1 workflow run --operation checksum-file --path PATH --algorithm sha256 --dry-run true",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "organize",
                        intent: "Move or duplicate verified artifacts only after a dry run.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "duplicate artifact",
                                command: "Ln1 workflow run --operation duplicate-file --path PATH --to DESTINATION --allow-risk medium --dry-run false --execute-mutating true --reason TEXT",
                                risk: "medium",
                                mutates: true
                            ),
                            WorkflowScenarioCommand(
                                name: "rollback move",
                                command: "Ln1 workflow run --operation rollback-file-move --audit-id AUDIT_ID --allow-risk medium --dry-run false --execute-mutating true --reason TEXT",
                                risk: "medium",
                                mutates: true
                            )
                        ]
                    )
                ],
                verificationSignals: [
                    "File existence, size, and digest match expectations.",
                    "Move or duplicate operations record verified destination metadata.",
                    "Rollback is available from the successful move audit record."
                ],
                auditArtifacts: [
                    "file metadata snapshot",
                    "checksum result",
                    "move or duplicate audit record",
                    "rollback audit record when used"
                ]
            ),
            WorkflowScenario(
                id: "permission-dialog-triage",
                title: "Permission Dialog Triage",
                purpose: "Detect and document permission blockers before attempting UI control.",
                highestRisk: "low",
                idealFor: [
                    "First-run setup",
                    "Accessibility permission diagnosis",
                    "Explaining why a workflow cannot proceed"
                ],
                phases: [
                    WorkflowScenarioPhase(
                        name: "readiness",
                        intent: "Check host readiness and permission blockers.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "doctor",
                                command: "Ln1 doctor",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "observe blockers",
                                command: "Ln1 observe --app-limit 20 --window-limit 20",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    ),
                    WorkflowScenarioPhase(
                        name: "inspect",
                        intent: "Capture active app, windows, and displays before asking the human to grant permissions.",
                        commands: [
                            WorkflowScenarioCommand(
                                name: "inspect system",
                                command: "Ln1 workflow run --operation inspect-system --dry-run true",
                                risk: "low",
                                mutates: false
                            ),
                            WorkflowScenarioCommand(
                                name: "inspect displays",
                                command: "Ln1 workflow run --operation inspect-displays --dry-run true",
                                risk: "low",
                                mutates: false
                            )
                        ]
                    )
                ],
                verificationSignals: [
                    "doctor reports pass, warn, or fail for each readiness check.",
                    "observe reports blockers and suggested next commands.",
                    "No mutating command is needed to diagnose missing permissions."
                ],
                auditArtifacts: [
                    "doctor report",
                    "observation snapshot",
                    "workflow transcript for read-only inspections"
                ]
            )
        ]
    }
}
