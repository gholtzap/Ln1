# App-Specific Adapters Plan

## Goal

Add focused integrations for important apps where generic accessibility or visual control is not enough.

## Why It Matters

Apps like Mail, Calendar, Notes, Reminders, Finder, Terminal, Slack, and design tools contain domain-specific data and actions. A generic UI tree may show controls but miss the real objects users care about.

## Desired Capability

The system should support app-specific views of data and actions where they provide meaningfully better control, safety, or reliability than generic UI automation.

## Success Criteria

- The assistant can access important app data in a structured way.
- The assistant can perform common app workflows without brittle clicking.
- The assistant can respect app-specific permissions and user expectations.
- The assistant can fall back to generic adapters when specific support is missing.
- New app adapters can be added without changing the overall product model.

## Relationship To The Product

App-specific adapters make the system feel deeply useful for real workflows. They should be added based on user value, not simply because an app exists.
