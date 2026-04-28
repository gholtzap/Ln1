# Input Control Plan

## Goal

Give the assistant a reliable set of human-like input abilities for situations where direct structured actions are unavailable.

## Why It Matters

Many apps do not expose complete semantic actions. A human can still operate them through clicks, typing, scrolling, keyboard shortcuts, menus, and drag-and-drop. The assistant needs these as fallback tools.

## Desired Capability

The system should support basic interaction with the graphical desktop, including pointer movement, clicking, scrolling, typing, keyboard shortcuts, clipboard-assisted input, app activation, and window management. These controls should be used intentionally and logged clearly.

## Success Criteria

- The assistant can interact with apps that expose incomplete structured APIs.
- The assistant can combine typed input with observation and verification.
- The assistant can avoid unnecessary mouse movement when a safer direct action exists.
- The assistant can recover from focus mistakes before continuing.
- The assistant can explain which input fallback it used and why.

## Relationship To The Product

Input control is the compatibility layer. It should make the product work across real apps while the system gradually learns richer, safer paths.
