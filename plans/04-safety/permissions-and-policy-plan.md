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
- Desktop window inspection classification: `03 desktop windows` is classified as a low-risk, non-mutating desktop metadata read.
- Preflight policy preview: `03 files plan` reports whether the matching mutating filesystem action would pass the current `--allow-risk` threshold before any mutation is attempted.
- Rollback risk enforcement: `03 files rollback --audit-id` is classified as a medium-risk mutating filesystem action and is denied by default unless the caller explicitly allows medium risk.
- Clipboard privacy enforcement: `03 clipboard read-text` is classified as a medium-risk read action and is denied by default unless the caller explicitly allows medium risk.
- Clipboard mutation enforcement: `03 clipboard write-text` is classified as a medium-risk mutating clipboard action and is denied by default unless the caller explicitly allows medium risk.
- Browser tab read classification: `03 browser tabs` and `03 browser tab` expose DevTools tab metadata as low-risk, non-mutating browser inspection actions.
- Browser page text privacy enforcement: `03 browser text` is classified as a medium-risk read action because page contents may include private web-app data.
- Browser DOM privacy enforcement: `03 browser dom` is classified as a medium-risk read action because structured page text, links, labels, and form metadata may expose private web-app state.
- Task memory privacy enforcement: `03 task start`, `03 task record`, `03 task finish`, and `03 task show` are classified as medium-risk task memory actions because they persist or reveal private workflow context.

## Relationship To The Product

Safety is not a wrapper around the product. It is part of the core action model and necessary for real adoption.
