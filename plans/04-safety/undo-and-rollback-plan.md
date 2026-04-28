# Undo And Rollback Plan

## Goal

Give the assistant a practical way to undo or mitigate changes when tasks fail, are canceled, or produce unwanted results.

## Why It Matters

Human users rely on undo, trash, version history, drafts, and backups. An assistant should plan for reversal before taking meaningful actions.

## Desired Capability

The system should understand which actions are reversible, which require backups, which can only be mitigated, and which must require confirmation because they cannot be undone.

## Success Criteria

- The assistant can describe the rollback plan before risky actions.
- The assistant can undo common local changes.
- The assistant avoids irreversible actions without explicit approval.
- The assistant can preserve enough context to repair mistakes.
- The system communicates clearly when rollback is unavailable.

## Implemented Increments

- Audited file move rollback: `03 files rollback --audit-id` restores a successful audited `files.move` operation after policy approval, metadata validation, overwrite prevention, and verification that the original path is restored.
- Rollback preflight: `03 files plan --operation rollback --audit-id` reports whether a move rollback is currently possible without restoring the file.

## Relationship To The Product

Rollback makes delegation safer. It should be considered part of action planning, not only error handling.
