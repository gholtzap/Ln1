# Agent Loop Plan

## Goal

Create a reliable execution loop that lets the assistant observe, plan, act, wait, verify, and recover across multi-step computer tasks.

## Why It Matters

Single commands are not enough for real computer use. A human acts, watches what happens, adjusts, and confirms the result. The assistant needs the same loop.

## Desired Capability

The system should support task execution as a sequence of observations and actions, with explicit checkpoints, waiting, verification, and recovery paths. It should maintain enough task context to continue coherently without blindly repeating work.

## Success Criteria

- The assistant can complete multi-step tasks across apps.
- The assistant can wait for state changes rather than using fixed delays.
- The assistant can verify that each important step had the expected result.
- The assistant can pause for approval when risk or ambiguity is high.
- The assistant can stop cleanly and explain its current state.

## Implemented Increments

- Initial observation checkpoint: `03 observe` gives the assistant a structured starting snapshot with blockers and suggested next typed actions before choosing an observe-plan-act path.
- Workflow preflight: `03 workflow preflight --operation ...` maps intended tasks to risk, mutation status, prerequisites, blockers, and the safest next command before execution.
- Structured next command: `03 workflow next --operation ...` embeds preflight and returns an executable `argv` array for the next safe command so an automation loop does not need to parse shell text.
- Dry-run workflow runner: `03 workflow run --operation ... --dry-run true` reports whether the next workflow step would execute and includes the exact command plus preflight evidence without performing the action.
- Non-mutating workflow execution: `03 workflow run --operation read-browser --dry-run false` executes safe read-only workflow commands and captures JSON output.
- Explicit mutating workflow execution: `03 workflow run --dry-run false --execute-mutating true --reason ...` can execute preflighted mutating workflows while preserving underlying typed command policy checks and audit records.
- Bounded workflow execution: `03 workflow run ... --run-timeout-ms N --max-output-bytes N` prevents read-only child commands from hanging the control loop or returning unbounded output.
- File wait workflow: `03 workflow run --operation wait-file ...` adds a safe wait primitive for file appearance/disappearance with an outer workflow deadline.
- Clipboard wait workflow: `03 workflow run --operation wait-clipboard ...` adds a safe wait primitive for pasteboard changes or text metadata without returning clipboard contents.
- Workflow transcript: `03 workflow run ...` appends a JSONL record, and `03 workflow log --allow-risk medium` reads recent runs for resume/debug context.
- Workflow resume: `03 workflow resume --allow-risk medium` summarizes the latest transcript status and returns a conservative next command, including browser tab-list-to-DOM-inspection and DOM-selector-to-browser-action follow-ups for fill, select, check, and click controls.
- Browser action preflight: `03 workflow preflight --operation fill-browser|select-browser|check-browser|focus-browser|press-browser-key|click-browser|navigate-browser ...` validates DevTools, audit-log readiness, tab IDs, selectors, text, select option values/labels, checked states, key names, modifiers, URLs, and match modes before returning typed browser action argv arrays.
- Verified click preflight: `03 workflow preflight --operation click-browser --expect-url ...` carries post-click URL expectations into the typed browser click command.
- Browser URL wait workflow: `03 workflow run --operation wait-browser-url ... --dry-run false` waits for a tab URL to match expected exact, prefix, or contains criteria and returns typed verification evidence.
- Browser URL wait resume: after a successful `wait-browser-url` transcript, `03 workflow resume --operation wait-browser-url` suggests a dry-run DOM inspection for the arrived tab.
- Browser selector wait workflow: `03 workflow run --operation wait-browser-selector ... --dry-run false` waits for dynamic DOM readiness or disappearance before the next browser action.
- Browser selector wait resume: after a successful `wait-browser-selector` transcript, `03 workflow resume --operation wait-browser-selector` suggests a direct fill, select, check, or click command when selector metadata is actionable.
- Browser selector count wait workflow: `03 workflow run --operation wait-browser-count ... --dry-run false` waits for result/list/table counts before the next browser action.
- Browser selector count wait resume: after a successful `wait-browser-count` transcript, `03 workflow resume --operation wait-browser-count` suggests a dry-run DOM inspection for the matched collection state.
- Browser text wait workflow: `03 workflow run --operation wait-browser-text ... --dry-run false` waits for success/error text without returning page contents.
- Browser text wait resume: after a successful `wait-browser-text` transcript, `03 workflow resume --operation wait-browser-text` suggests a dry-run DOM inspection for the matched page state.
- Browser value wait workflow: `03 workflow run --operation wait-browser-value ... --dry-run false` waits for a field value without returning value contents.
- Browser value wait resume: after a successful `wait-browser-value` transcript, `03 workflow resume --operation wait-browser-value` suggests a dry-run DOM inspection for the matched field state.
- Browser ready-state wait workflow: `03 workflow run --operation wait-browser-ready ... --dry-run false` waits for document readiness before inspecting or acting.
- Browser ready-state wait resume: after a successful `wait-browser-ready` transcript, `03 workflow resume --operation wait-browser-ready` suggests a dry-run DOM inspection for the loaded page state.
- Browser title wait workflow: `03 workflow run --operation wait-browser-title ... --dry-run false` waits for tab title metadata without reading page contents.
- Browser title wait resume: after a successful `wait-browser-title` transcript, `03 workflow resume --operation wait-browser-title` suggests a dry-run DOM inspection for the matched page state.
- Browser checked-state wait workflow: `03 workflow run --operation wait-browser-checked ... --dry-run false` waits for checkbox or radio state without mutating the page.
- Browser checked-state wait resume: after a successful `wait-browser-checked` transcript, `03 workflow resume --operation wait-browser-checked` suggests a dry-run DOM inspection for the matched form state.
- Browser enabled-state wait workflow: `03 workflow run --operation wait-browser-enabled ... --dry-run false` waits for an element to become enabled or disabled before the next browser action.
- Browser enabled-state wait resume: after a successful `wait-browser-enabled` transcript, `03 workflow resume --operation wait-browser-enabled` suggests a direct action when the enabled element is actionable.
- Browser focus-state wait workflow: `03 workflow run --operation wait-browser-focus ... --dry-run false` waits for an element to become focused or unfocused before inspecting or acting.
- Browser focus-state wait resume: after a successful `wait-browser-focus` transcript, `03 workflow resume --operation wait-browser-focus` suggests a dry-run DOM inspection for the focused element state.

## Relationship To The Product

The agent loop turns adapters and actions into useful work. Without it, 03 is a toolbox; with it, 03 becomes an operating layer.
