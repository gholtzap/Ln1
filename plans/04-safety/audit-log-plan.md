# Audit Log Plan

## Goal

Record what the assistant observed, decided, and did in a way that users can inspect and trust.

## Why It Matters

If an assistant controls a computer, users need a clear account of its behavior. Auditability helps with trust, debugging, compliance, and recovery.

## Desired Capability

The system should keep a structured history of task intent, actions taken, permissions used, user approvals, state changes, and verification results. Sensitive data should be redacted or summarized where appropriate.

## Success Criteria

- The user can review what happened during a task.
- Each meaningful action has a reason and result.
- User approvals and denials are recorded.
- Sensitive content is not unnecessarily stored.
- Logs can support rollback, debugging, and product improvement.

## Relationship To The Product

The audit log is the product's memory of accountability. It should make powerful automation feel inspectable rather than opaque.
