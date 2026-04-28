# Permissions And Policy Plan

## Goal

Create a clear permission and policy system that controls what the assistant may observe, modify, send, delete, or execute.

## Why It Matters

An AI that can operate a computer needs strict boundaries. Users must be able to trust that sensitive data, destructive actions, external communications, and system changes are handled deliberately.

## Desired Capability

The system should classify observations and actions by risk, enforce user-configured policies, request confirmation for sensitive operations, and make denied actions understandable.

## Success Criteria

- The assistant can distinguish low-risk, sensitive, destructive, and externally visible actions.
- The user can approve or deny categories of actions.
- The assistant asks before sending, deleting, purchasing, publishing, or revealing sensitive data.
- Policy decisions are explainable and auditable.
- The system defaults to conservative behavior when uncertain.

## Implemented Increments

- Action risk enforcement: `03 perform` and mutating filesystem actions require `--allow-risk` to meet or exceed the classified action risk.
- Policy inspection: `03 policy` exposes known typed actions, risk levels, mutation classification, and the default allowed risk as structured JSON.
- Preflight policy preview: `03 files plan` reports whether the matching mutating filesystem action would pass the current `--allow-risk` threshold before any mutation is attempted.
- Rollback risk enforcement: `03 files rollback --audit-id` is classified as a medium-risk mutating filesystem action and is denied by default unless the caller explicitly allows medium risk.

## Relationship To The Product

Safety is not a wrapper around the product. It is part of the core action model and necessary for real adoption.
