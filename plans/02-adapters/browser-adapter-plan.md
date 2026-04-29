# Browser Adapter Plan

## Goal

Expose browser tabs, pages, DOM structure, page text, forms, and browser actions as structured state and typed operations.

## Why It Matters

Many modern workflows happen in web apps. Browser accessibility trees and screenshots are not enough. A browser adapter can provide direct access to page structure, URLs, network state, form fields, and semantic content.

## Desired Capability

The system should understand open tabs, active pages, page content, forms, links, buttons, and navigation state. It should prefer browser-native data and actions before falling back to desktop-level control.

## Success Criteria

- The assistant can list and inspect browser tabs.
- The assistant can extract page text and structured page state.
- The assistant can interact with forms and navigation through browser-aware actions.
- The assistant can verify page changes after interaction.
- The assistant can avoid brittle coordinate-based web automation when DOM access is available.

## Implemented Increments

- DevTools tab discovery: `03 browser tabs` and `03 browser tab` read Chrome DevTools `/json/list` from an explicit endpoint and return structured tab target metadata, filtering non-page targets by default.

## Relationship To The Product

The browser adapter is likely one of the highest-leverage adapters because it turns web apps from visual surfaces into inspectable software environments.
