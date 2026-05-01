# Desktop State Plan

## Goal

Create a complete, high-level picture of the active desktop environment so the assistant understands the computer as a whole rather than only the frontmost app.

## Why It Matters

A human does not perceive one app in isolation. They see displays, windows, focus, dialogs, menus, notifications, and spatial relationships. The assistant needs the same context to avoid acting in the wrong place or missing blockers.

## Desired Capability

The system should describe the current desktop in terms of visible apps, windows, focus, display layout, active dialogs, menu state, and interaction targets. It should distinguish between what is visible, what is active, what is blocked, and what is available in the background.

## Success Criteria

- The assistant can identify the active app and active window.
- The assistant can list visible windows across the desktop.
- The assistant can detect modal dialogs, sheets, alerts, and permission prompts.
- The assistant can reason about screen coordinates and window positions when needed.
- The assistant can tell when the desktop state is insufficient and request a richer observation.

## Implemented Increments

- Visible desktop window inventory: `03 desktop windows` lists visible macOS windows as structured owner, title, layer, bounds, and active-owner metadata without requiring screenshots or Accessibility access.
- First-step observation snapshot: `03 observe` combines Accessibility trust status, active app metadata, bounded running-app inventory, visible desktop windows, blockers, and suggested safe next actions into one structured read-only snapshot.

## Relationship To The Product

This is the base map of the computer. Without it, every other capability risks being app-local, brittle, or unaware of desktop-level blockers.
