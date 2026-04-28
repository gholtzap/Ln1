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

The policy output lists the default allowed risk level, ordered risk levels, and known typed actions with their domain, risk, and mutation classification. Commands such as `perform`, `files duplicate`, `files move`, `files mkdir`, and `files rollback` use these risk levels when evaluating `--allow-risk`.

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

`--command` matches audit command names such as `perform`, `files.duplicate`, `files.move`, `files.mkdir`, or `files.rollback`. `--code` matches the outcome code, such as `policy_denied`, `duplicated`, `moved`, `created_directory`, or `rolled_back_move`.

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

The filesystem adapter returns stable-ish file identity, absolute path, kind, size, timestamps, hidden/readable/writable flags, and available typed actions such as `filesystem.stat`, `filesystem.list`, `filesystem.search`, `filesystem.duplicate`, `filesystem.move`, `filesystem.createDirectory`, and `filesystem.rollbackMove`. Search only exposes bounded matching snippets, not full file contents.

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

## Product Direction

The next step is to add adapters for richer state sources:

- Browser DOM through Chrome DevTools Protocol
- Filesystem document indexes and audited file operations beyond bounded local search
- Clipboard and notifications
- App-native integrations where available
- A permission/audit log around every action

The model-facing API should stay typed and structured, with macOS Accessibility as the compatibility bridge for apps that do not expose native semantic data.
