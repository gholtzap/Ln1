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
- DevTools page text extraction: `03 browser text` reads bounded visible page text through a tab's Chrome DevTools WebSocket after medium-risk policy approval and records only tab metadata plus text length/digest in the audit log.
- DevTools DOM snapshot: `03 browser dom` reads bounded structured page state through a tab's Chrome DevTools WebSocket after medium-risk policy approval, returning DOM elements, actionable CSS selectors, inferred roles, safe attributes, links, and form metadata while auditing only element count plus digest.
- DevTools form filling: `03 browser fill` writes one field by CSS selector through a tab's Chrome DevTools WebSocket after medium-risk policy approval, dispatches input/change events, verifies the resulting value length, and audits only selector plus text length/digest.
- DevTools select control: `03 browser select` chooses one `<select>` option by value or label after medium-risk policy approval, dispatches input/change events, verifies the selected option, and audits only selector plus option length/digest.
- DevTools checked-state control: `03 browser check` sets one checkbox or radio input after medium-risk policy approval, dispatches input/change events, verifies checked state, and audits selector plus requested state.
- DevTools element clicking: `03 browser click` clicks one DOM element by CSS selector through a tab's Chrome DevTools WebSocket after medium-risk policy approval, rejecting missing or disabled elements and auditing only selector plus target metadata.
- Verified DevTools clicking: `03 browser click --expect-url ...` waits for an expected post-click tab URL and returns structured URL verification evidence with the click result.
- DevTools navigation: `03 browser navigate` sends a typed tab navigation through Chrome DevTools after medium-risk policy approval, verifies the resulting tab URL from structured DevTools target metadata, and records requested/current URLs plus verification in the audit log.
- DevTools URL waiting: `03 browser wait-url` waits for a tab URL to match expected exact, prefix, or contains criteria using structured DevTools tab metadata.
- DevTools selector waiting: `03 browser wait-selector` waits for a selector to become attached or visible using read-only DevTools runtime evaluation.
- DevTools text waiting: `03 browser wait-text` waits for page text to match while returning only text lengths and digests.
- DevTools ready-state waiting: `03 browser wait-ready` waits for `document.readyState` to reach loading, interactive, or complete before the next inspection or action.
- DevTools title waiting: `03 browser wait-title` waits for tab title metadata to match without reading page contents.

## Relationship To The Product

The browser adapter is likely one of the highest-leverage adapters because it turns web apps from visual surfaces into inspectable software environments.
