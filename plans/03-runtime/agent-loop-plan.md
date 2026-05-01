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
- Non-mutating workflow execution: `03 workflow run --operation read-browser --dry-run false` executes safe read-only workflow commands and captures JSON output while continuing to reject mutating workflow execution.
- Bounded workflow execution: `03 workflow run ... --run-timeout-ms N --max-output-bytes N` prevents read-only child commands from hanging the control loop or returning unbounded output.
- File wait workflow: `03 workflow run --operation wait-file ...` adds a safe wait primitive for file appearance/disappearance with an outer workflow deadline.
- Workflow transcript: `03 workflow run ...` appends a JSONL record, and `03 workflow log --allow-risk medium` reads recent runs for resume/debug context.
- Workflow resume: `03 workflow resume --allow-risk medium` summarizes the latest transcript status and returns a conservative next command, including browser tab-list-to-DOM-inspection and DOM-selector-to-browser-action follow-ups.
- Browser action preflight: `03 workflow preflight --operation fill-browser|click-browser ...` validates DevTools, audit-log readiness, tab IDs, selectors, and text before returning typed browser action argv arrays.

## Relationship To The Product

The agent loop turns adapters and actions into useful work. Without it, 03 is a toolbox; with it, 03 becomes an operating layer.
