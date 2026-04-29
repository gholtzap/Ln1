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

## Inspect Action Policy

```sh
.build/debug/03 policy
```

The policy output lists the default allowed risk level, ordered risk levels, and known typed actions with their domain, risk, and mutation classification. Commands such as `perform`, `files duplicate`, `files move`, `files mkdir`, `files rollback`, `clipboard read-text`, `clipboard write-text`, `browser text`, `browser dom`, `browser fill`, and task memory commands use these risk levels when evaluating `--allow-risk`; browser tab metadata inspection actions are listed as low-risk, non-mutating reads.

## Inspect Running Apps

```sh
.build/debug/03 apps
```

If you are running from a non-interactive shell and want every process macOS exposes:

```sh
.build/debug/03 apps --all
```

## Inspect Visible Desktop Windows

```sh
.build/debug/03 desktop windows --limit 50
```

The output is structured JSON from macOS window metadata: availability, window ID, owner app name and PID, bundle identifier when available, active-owner flag, title when macOS exposes it, layer, bounds, onscreen state, alpha, memory usage, and sharing state. This is a low-risk desktop inspection action that does not require screenshots or Accessibility access. If the current process cannot read WindowServer metadata, the command still returns a structured unavailable result instead of falling back to screenshots.

By default `desktop windows` reports visible non-desktop, normal-layer windows. Include desktop elements or menu/overlay layers when they are relevant:

```sh
.build/debug/03 desktop windows --include-desktop --all-layers
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

`perform` applies a conservative action policy before touching Accessibility APIs. By default, only actions classified as `low` risk are allowed. To explicitly permit broader known or unclassified action categories:

```sh
.build/debug/03 perform --element w0.3.1 --action AXConfirm --allow-risk medium --reason "Confirm the selected dialog"
.build/debug/03 perform --element w0.3.1 --action AXCustomAction --allow-risk unknown --reason "Use app-specific action"
```

Policy denials are written to the audit log with the requested action, classified risk, allowed risk threshold, reason, and denial outcome. They do not require Accessibility access because the policy is checked before app inspection or action execution.

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

Filter audit records before applying the limit:

```sh
.build/debug/03 audit --command files.move --code moved --limit 10
```

`--command` matches audit command names such as `perform`, `files.duplicate`, `files.move`, `files.mkdir`, `files.rollback`, `clipboard.read-text`, `browser.text`, or `browser.dom`. `--code` matches the outcome code, such as `policy_denied`, `duplicated`, `moved`, `created_directory`, `rolled_back_move`, `read_text`, or `read_dom`.

## Track Task Memory

Start a task-scoped memory journal when a workflow needs resumable context:

```sh
.build/debug/03 task start --title "Verify downloaded report" --summary "Wait for report.pdf and compare checksum" --allow-risk medium
```

Task memory is a medium-risk local persistence action because it can store task context. By default it writes JSONL events to:

```text
~/Library/Application Support/03/task-memory.jsonl
```

Use `--memory-log` to isolate tests or a specific workflow:

```sh
.build/debug/03 task start --title "Verify downloaded report" --allow-risk medium --memory-log /tmp/03-task-memory.jsonl
```

Append typed task events as work progresses:

```sh
.build/debug/03 task record --task-id TASK_ID --kind observation --summary "report.pdf appeared in Downloads" --allow-risk medium
.build/debug/03 task record --task-id TASK_ID --kind verification --summary "checksum matched expected digest" --related-audit-id AUDIT_ID --allow-risk medium
```

Supported event kinds are `observation`, `decision`, `action`, `verification`, and `note`. Summaries default to `private` sensitivity. When a summary is marked `sensitive`, the event records only its length and SHA-256 digest, not the summary text:

```sh
.build/debug/03 task record --task-id TASK_ID --kind observation --summary "copied one-time code 123456" --sensitivity sensitive --allow-risk medium
```

Finish and inspect the task:

```sh
.build/debug/03 task finish --task-id TASK_ID --status completed --summary "Downloaded report was verified." --allow-risk medium
.build/debug/03 task show --task-id TASK_ID --limit 20 --allow-risk medium
```

`task show` returns the task title, status, start/update timestamps, event count, and recent events. Reading task memory is also medium-risk because it may reveal persisted private workflow context.

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

The filesystem adapter returns stable-ish file identity, absolute path, kind, size, timestamps, hidden/readable/writable flags, and available typed actions such as `filesystem.stat`, `filesystem.list`, `filesystem.search`, `filesystem.plan`, `filesystem.duplicate`, `filesystem.move`, `filesystem.createDirectory`, and `filesystem.rollbackMove`. Search only exposes bounded matching snippets, not full file contents.

Search file names and bounded UTF-8 text content without using Finder:

```sh
.build/debug/03 files search --path ~/Documents --query invoice --depth 4 --limit 50
```

Search is case-insensitive by default, skips hidden files unless `--include-hidden` is passed, and avoids unbounded reads with `--max-file-bytes`, `--max-snippet-characters`, and `--max-matches-per-file`. Results include file metadata, whether the name matched, matching line numbers, short line snippets, scan counts, and skip counts for unreadable, binary, or oversized files.

Wait for a path to appear or disappear with bounded polling:

```sh
.build/debug/03 files wait --path ~/Downloads/report.pdf --exists true --timeout-ms 5000 --interval-ms 100
.build/debug/03 files wait --path ~/Downloads/report.part --exists false --timeout-ms 30000
```

`files wait` returns structured evidence about whether the expected existence state matched before the timeout. When the path exists, the response includes the same file metadata shape used by `files stat`. This is useful for downloads, generated files, and verification loops without relying on Finder state.

Compute a bounded content digest without returning file contents:

```sh
.build/debug/03 files checksum --path ~/Documents/Plan.md --algorithm sha256 --max-file-bytes 104857600
```

`filesystem.checksum` currently supports SHA-256 for regular files. It is a low-risk read action, but still bounded by `--max-file-bytes` so large files are not read accidentally. The response includes file metadata, the algorithm, and the hex digest.

Compare two regular files by size and digest:

```sh
.build/debug/03 files compare --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md --algorithm sha256
```

`filesystem.compare` is a low-risk read action that computes bounded SHA-256 digests for both files and reports `sameSize`, `sameDigest`, and `matched`. This is useful after copy or generation workflows where the assistant needs evidence that two files are identical without reading contents into the prompt.

Preview a mutating file operation before executing it:

```sh
.build/debug/03 files plan --operation move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium
.build/debug/03 files plan --operation duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md
.build/debug/03 files plan --operation mkdir --path ~/Documents/Archive --allow-risk medium
.build/debug/03 files plan --operation rollback --audit-id AUDIT_ID --allow-risk medium
```

`filesystem.plan` is a low-risk read action that makes no filesystem changes. It returns the underlying typed action, action mutation flag, risk, policy decision, source and destination metadata where available, named preflight checks, `canExecute`, and the `requiredAllowRisk` needed by the matching mutation command. This lets a caller explain exactly what will be affected before copying, moving, creating, or rolling back a file operation.

Duplicate one regular file through an audited typed action:

```sh
.build/debug/03 files duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md --allow-risk medium --reason "Keep an original before editing"
```

`filesystem.duplicate` is a medium-risk mutating file action. It is denied by the default low-risk policy unless `--allow-risk medium` is supplied. The command refuses to overwrite an existing destination, requires the destination parent directory to already exist, verifies that the copied file exists with the same byte size, and appends an audit record for success, policy denial, preflight failure, or verification failure.

Move or rename one regular file through the same policy and audit path:

```sh
.build/debug/03 files move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium --reason "Archive completed draft"
```

`filesystem.move` is also a medium-risk mutating file action. It refuses to overwrite an existing destination, requires both source and destination parent directories to be writable, verifies that the original source path is gone and the destination has the same byte size, and records the policy decision plus verification result in the audit log.

Rollback a successful audited file move:

```sh
.build/debug/03 files rollback --audit-id AUDIT_ID --allow-risk medium --reason "Undo mistaken move"
```

`filesystem.rollbackMove` is a medium-risk mutating file action. It reads the requested audit record, only supports successful `files.move` records, verifies that the current moved file still matches the recorded destination metadata, refuses to overwrite the original source path, moves the file back, verifies that the original source path is restored and the moved destination is gone, and records the rollback policy decision plus verification result in the audit log.

Create one directory for organization workflows:

```sh
.build/debug/03 files mkdir --path ~/Documents/Archive --allow-risk medium --reason "Create archive folder"
```

`filesystem.createDirectory` is a medium-risk mutating file action. It refuses existing paths, requires the parent directory to exist and be writable, verifies that the directory exists after creation, and records the policy decision plus verification result in the audit log.

## Inspect Clipboard State

Inspect clipboard metadata without returning copied text:

```sh
.build/debug/03 clipboard state
```

`clipboard.state` is a low-risk read action. It returns the pasteboard name, change count, available pasteboard types, whether plain text is available, the text length, and a SHA-256 digest of the text. It intentionally does not return clipboard contents.

Read bounded plain text from the clipboard only after explicitly allowing medium-risk clipboard access:

```sh
.build/debug/03 clipboard read-text --allow-risk medium --max-characters 4096 --reason "Use copied confirmation code"
```

`clipboard.readText` is a medium-risk read action because clipboard text may contain private transient data. The command writes an audit record containing pasteboard metadata, text length, digest, policy decision, reason, and outcome, but the audit record does not store the clipboard text itself. Use `--pasteboard NAME` to target a named pasteboard for tests or isolated workflows.

Write plain text to the clipboard only after explicitly allowing medium-risk clipboard mutation:

```sh
.build/debug/03 clipboard write-text --text "ready to paste" --allow-risk medium --reason "Prepare value for the next app"
```

`clipboard.writeText` is a medium-risk mutating action because it replaces the current plain-text pasteboard contents. The command records before/after pasteboard metadata, text lengths, digests, policy decision, verification result, reason, and outcome without storing either the previous or new clipboard text in the audit log. The command verifies the write by checking that the clipboard contains text with the requested length and SHA-256 digest.

## Inspect Browser Tabs

Start Chrome or another Chromium browser with a DevTools endpoint, then ask 03 for browser-native tab metadata:

```sh
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
.build/debug/03 browser tabs --endpoint http://127.0.0.1:9222
```

`browser.listTabs` is a low-risk read action. It reads `/json/list` from the explicit DevTools endpoint and returns structured tab records with target IDs, type, title, URL, DevTools frontend URL, WebSocket debugger URL, favicon URL, attachment state, and available typed browser actions. Non-page DevTools targets such as service workers are hidden by default; include them when relevant:

```sh
.build/debug/03 browser tabs --endpoint http://127.0.0.1:9222 --include-non-page
```

Inspect one tab from the same structured source:

```sh
.build/debug/03 browser tab --endpoint http://127.0.0.1:9222 --id TARGET_ID
```

Read the visible text from a page through the tab's DevTools WebSocket:

```sh
.build/debug/03 browser text --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-characters 16384 --reason "Extract page text for summarization"
```

`browser.readText` is a medium-risk read action because page text can contain private web-app content. The command returns bounded text to the caller, but its audit record stores only the tab ID, type, title, URL, text length, digest, policy decision, reason, and outcome. It does not click in the browser and does not require Accessibility access.

Read bounded structured page state from the DOM:

```sh
.build/debug/03 browser dom --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-elements 200 --max-text-characters 120 --reason "Inspect page controls before acting"
```

`browser.readDOM` is also a medium-risk read action because labels, links, visible text, and form metadata can expose private web-app state. The result includes bounded DOM elements with IDs, parent IDs, depth, tag names, inferred roles, bounded text snippets, selected safe attributes, links, and form metadata such as input type, checked/disabled state, and value length. It intentionally does not return form values and suppresses value metadata for password and hidden inputs. The audit record stores only tab metadata, DOM element count, DOM digest, policy decision, reason, and outcome; it does not store the DOM payload.

Fill one browser form field through the tab's DevTools WebSocket:

```sh
.build/debug/03 browser fill --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --text "search query" --allow-risk medium --reason "Prepare search"
```

`browser.fillFormField` is a medium-risk mutating action because it changes page state and may enter private text into a web app. The command targets one CSS selector, refuses disabled, read-only, and unsupported elements, dispatches `input` and `change` events, and verifies that the field contains text with the requested length. The result includes the selector, text length, SHA-256 digest, target metadata, verification, and audit ID. The audit record stores tab metadata, selector, text length, digest, policy decision, reason, verification, and outcome without storing the entered text.

This adapter is now using browser-native DevTools metadata, page text, structured DOM snapshots, and typed form filling. Navigation verification still needs follow-on work through the tab's DevTools WebSocket.

## Product Direction

The next step is to add adapters for richer state sources:

- Browser DOM through Chrome DevTools Protocol
- Filesystem document indexes and audited file operations beyond bounded local search
- Notifications
- App-native integrations where available
- A permission/audit log around every action

The model-facing API should stay typed and structured, with macOS Accessibility as the compatibility bridge for apps that do not expose native semantic data.
