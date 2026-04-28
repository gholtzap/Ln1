# Overall Product Goal

## Goal

Build an AI-native computer layer that lets an assistant understand, operate, and verify work across a personal computer through structured state and trusted actions instead of relying primarily on screenshots and fragile clicking.

## Vision

The software should make the computer legible to AI. Apps, files, browser tabs, windows, documents, notifications, and system services should appear as structured, inspectable state. Actions should be expressed as clear operations with known intent, expected effect, risk level, and audit history.

The product should feel less like a chatbot beside the computer and more like an operating layer woven through the machine. It should be able to answer what is open, what data is available, what actions are possible, what has changed, and whether a requested task was completed correctly.

## Product Principles

- Prefer real data and typed actions over pixels and mouse movements.
- Use UI automation as a compatibility bridge, not as the primary abstraction.
- Make every meaningful action observable, auditable, and reversible where possible.
- Keep the user in control of sensitive, destructive, or externally visible actions.
- Design for imperfect apps by combining multiple state sources.
- Treat verification as part of task execution, not an optional afterthought.

## Success Criteria

- The assistant can build a useful model of the current computer state.
- The assistant can operate across multiple apps without assuming the current foreground app is the whole world.
- The assistant can choose the safest available action path for a task.
- The assistant can explain what it is about to do and what it already did.
- The assistant can detect when an action failed or when the computer changed unexpectedly.
- The system can grow through adapters without requiring a new operating system.
