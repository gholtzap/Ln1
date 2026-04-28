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

## Relationship To The Product

Rollback makes delegation safer. It should be considered part of action planning, not only error handling.
