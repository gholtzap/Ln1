# Verification And Recovery Plan

## Goal

Make the assistant prove that important actions worked and recover safely when they did not.

## Why It Matters

Computer control is unreliable without verification. Apps can lag, fail, open unexpected dialogs, lose focus, or reject input. A human checks outcomes before moving on. The assistant should too.

## Desired Capability

The system should define expected outcomes for actions, observe whether those outcomes happened, detect common failure modes, and choose safe recovery strategies.

## Success Criteria

- The assistant can tell whether an action changed the expected state.
- The assistant can detect when nothing happened.
- The assistant can identify blockers such as alerts, disabled controls, missing files, or lost focus.
- The assistant can retry only when retrying is safe.
- The assistant can escalate to the user when the outcome is ambiguous or risky.

## Implemented Increments

- Filesystem existence verification: `03 files wait` provides bounded, typed evidence that a path appeared or disappeared before a workflow proceeds.
- Filesystem change verification: `03 files watch` provides bounded, typed evidence that file metadata changed, including normalized created, deleted, and modified events.
- Filesystem content identity verification: `03 files checksum` provides a bounded SHA-256 digest for comparing regular files without storing their contents.
- Filesystem equality verification: `03 files compare` reports whether two regular files match by size and SHA-256 digest without exposing file contents.
- Filesystem move rollback verification: `03 files rollback --audit-id` validates audit metadata before restoring a moved file and verifies that the original path exists while the moved destination is gone afterward.
- Browser form fill verification: `03 browser fill` verifies that the targeted form field contains text with the requested length after dispatching input/change events.
- Browser navigation verification: `03 browser navigate` verifies that the tab reaches the expected URL after a DevTools navigation, with exact, prefix, or contains matching for redirect-aware workflows.
- Browser enabled-state verification: `03 browser wait-enabled` provides bounded evidence that a target selector is enabled or disabled before the assistant tries to click, fill, or choose it.
- Browser focus-state verification: `03 browser wait-focus` provides bounded evidence that a target selector is focused or unfocused before the assistant sends keyboard input or inspects follow-up state.
- Browser attribute verification: `03 browser wait-attribute` provides bounded evidence that a target selector's DOM attribute reached an expected value without exposing the value contents.
- Accessibility target identity verification: `03 perform --expect-identity --min-identity-confidence` verifies the resolved element's current stable identity before invoking an Accessibility action, preventing stale path IDs from acting on a different control.

## Relationship To The Product

Verification is what separates a serious computer-control product from a demo. It should be built into every nontrivial workflow.
