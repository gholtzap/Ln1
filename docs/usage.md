# 03 macOS Prototype

03 is a small native macOS prototype for an AI-readable computer layer. It uses Accessibility APIs to expose the frontmost app as structured JSON, then lets a caller invoke typed actions such as `AXPress` against element IDs from that JSON.

This is not a new OS. It is the first compatibility layer for the product idea: structured state first, UI automation second, screenshots last.

## Build

```sh
swift build
```

## Grant Accessibility Access

```sh
.build/debug/03 trust
```

macOS will prompt for Accessibility access. Grant access to the terminal app that launched 03, then rerun the command.

## Inspect Running Apps

```sh
.build/debug/03 apps
```

If you are running from a non-interactive shell and want every process macOS exposes:

```sh
.build/debug/03 apps --all
```

## Emit Structured State

```sh
.build/debug/03 state --depth 4 --max-children 120
```

The output is JSON with app metadata, windows, elements, frames, values, and available actions.

By default this targets the frontmost app. To walk every running GUI app macOS exposes through Accessibility:

```sh
.build/debug/03 state --all --depth 3 --max-children 80
```

To also try background/menu-bar style processes:

```sh
.build/debug/03 state --all --include-background --depth 2 --max-children 50
```

This is still not literally every piece of data on the machine. macOS exposes UI state per app through Accessibility. Files, browser DOM, calendars, mail stores, databases, and notifications need separate adapters.

## Perform An Action

Use an element ID from `state`:

```sh
.build/debug/03 perform --element w0.3.1 --action AXPress --reason "Open the details panel"
```

For IDs from `state --all`, pass the app PID from that same app record:

```sh
.build/debug/03 perform --pid 456 --element a0.w0.3.1 --action AXPress --reason "Open the details panel"
```

To target a specific app:

```sh
.build/debug/03 state --pid 123
.build/debug/03 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open the details panel"
```

Every `perform` attempt appends a structured JSONL audit record before returning success or failure. The action result includes the audit record ID and log path.

By default the audit log is stored at:

```text
~/Library/Application Support/03/audit-log.jsonl
```

Use `--audit-log` to send records to another file during tests or isolated runs:

```sh
.build/debug/03 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open details" --audit-log /tmp/03-audit.jsonl
```

The audit entry records typed intent and outcome: timestamp, risk level, target app, element ID, available element actions, requested action, optional reason, and result. It intentionally stores only a small element summary and does not store element values.

## Review The Audit Log

Read recent audit records:

```sh
.build/debug/03 audit --limit 20
```

Read from a custom audit file:

```sh
.build/debug/03 audit --audit-log /tmp/03-audit.jsonl --limit 5
```

## Inspect Filesystem State

Inspect one file or folder without reading file contents:

```sh
.build/debug/03 files stat --path ~/Documents/Plan.md
```

List a folder as structured metadata:

```sh
.build/debug/03 files list --path ~/Documents --depth 2 --limit 200
```

Hidden files are skipped by default. Include them explicitly when they are relevant:

```sh
.build/debug/03 files list --path ~/Documents --include-hidden --depth 1
```

The filesystem adapter returns stable-ish file identity, absolute path, kind, size, timestamps, hidden/readable/writable flags, and available typed actions such as `filesystem.stat` and `filesystem.list`. It is intentionally read-only in this increment and does not capture file contents.

## Product Direction

The next step is to add adapters for richer state sources:

- Browser DOM through Chrome DevTools Protocol
- Filesystem document indexes and audited file operations
- Clipboard and notifications
- App-native integrations where available
- A permission/audit log around every action

The model-facing API should stay typed and structured, with macOS Accessibility as the compatibility bridge for apps that do not expose native semantic data.
