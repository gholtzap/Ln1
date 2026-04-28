# Accessibility Adapter Plan

## Goal

Use the operating system accessibility layer as the primary compatibility source for app UI structure and basic UI actions.

## Why It Matters

Accessibility APIs expose roles, labels, values, windows, focus, and supported actions for many apps. They are more structured than screenshots and more broadly available than app-specific integrations.

## Desired Capability

The system should inspect accessible UI hierarchy across running apps, understand common control types, detect actionable elements, and perform supported accessibility actions when appropriate.

## Success Criteria

- The assistant can inspect multiple running apps through accessibility state.
- The assistant can identify common controls such as buttons, text fields, lists, tables, windows, and dialogs.
- The assistant can perform safe accessibility actions on target elements.
- The assistant can recognize when an app exposes poor or incomplete accessibility data.
- The adapter can feed a normalized state model used by the rest of the product.

## Relationship To The Product

This adapter is the first bridge between existing macOS apps and the AI-readable computer layer. It gives immediate coverage without requiring apps to adopt a new protocol.
