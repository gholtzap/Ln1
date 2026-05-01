# Stable Identity Plan

## Goal

Create durable identities for apps, windows, UI elements, documents, and data objects so the assistant can refer to the same thing across observations.

## Why It Matters

Child-index paths and transient UI positions are fragile. A small layout change can make an old reference point to the wrong element. Human users rely on labels, visual context, location, and meaning. The assistant needs similarly stable references.

## Desired Capability

The system should identify objects using a combination of semantic labels, roles, ownership, location, neighboring context, visual cues, and historical continuity. References should remain useful when the UI shifts slightly.

## Success Criteria

- The assistant can refer to the same window or element across repeated observations.
- The assistant can detect when an identity is uncertain.
- The assistant can avoid acting when a reference may have drifted.
- The assistant can present object references in user-readable language.
- The system can reconcile structured and visual observations of the same object.

## Implemented Increments

- Desktop window semantic identity: `03 desktop windows` includes a `stableIdentity` for each visible window with a semantic digest, confidence, user-readable label, components, and reasons alongside the transient WindowServer ID.

## Relationship To The Product

Stable identity turns raw observations into a coherent world model. It is essential for multi-step tasks, verification, and safe action execution.
