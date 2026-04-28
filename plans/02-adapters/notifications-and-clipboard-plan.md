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

## Relationship To The Product

These signals make the assistant more situationally aware. They should be handled with stricter privacy expectations than ordinary UI state.
