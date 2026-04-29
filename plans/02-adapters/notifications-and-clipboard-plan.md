# Notifications And Clipboard Plan

## Goal

Represent notifications and clipboard state as first-class computer context while preserving user privacy and control.

## Why It Matters

Notifications and clipboard contents often explain what the user is doing or what just changed. Humans use them constantly. The assistant should understand them carefully without treating private transient data as unrestricted memory.

## Desired Capability

The system should observe relevant notifications, inspect clipboard state when permitted, support clipboard-assisted workflows, and connect these signals to active tasks.

## Success Criteria

- The assistant can notice task-relevant notifications.
- The assistant can use clipboard state with explicit privacy boundaries.
- The assistant can explain when clipboard use is part of an action.
- The assistant can avoid silently retaining sensitive copied data.
- Notification and clipboard context can improve task verification.

## Implemented Increments

- Clipboard metadata state: `03 clipboard state` reports pasteboard name, change count, types, text availability, text length, and a SHA-256 digest without returning clipboard contents.
- Audited clipboard text read: `03 clipboard read-text` is a medium-risk read action that requires explicit policy allowance, returns bounded text to the caller, and records only clipboard metadata, digest, reason, policy decision, and outcome in the audit log.

## Relationship To The Product

These signals make the assistant more situationally aware. They should be handled with stricter privacy expectations than ordinary UI state.
