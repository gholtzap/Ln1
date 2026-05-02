# Ln1 macOS Prototype

Ln1, short for Layer negative one, is a small native macOS prototype for an AI-readable computer layer. It uses Accessibility APIs to expose the frontmost app as structured JSON, then lets a caller invoke typed actions such as `AXPress` against element IDs from that JSON.

This is not a new OS. It is the first compatibility layer for the product idea: structured state first, UI automation second, screenshots last.

## Build

```sh
swift build
```

## Grant Accessibility Access

```sh
.build/debug/Ln1 trust
```

macOS will prompt for Accessibility access. Grant access to the terminal app that launched Ln1, then rerun the command.

## Check Readiness

```sh
.build/debug/Ln1 doctor
```

`doctor` checks whether the current shell is ready for computer control. It reports required checks for Accessibility permission, desktop window metadata, audit-log writeability, and clipboard metadata, plus an optional browser DevTools endpoint check. Each check includes `pass`, `warn`, or `fail`, whether it is required, a message, and a remediation command or setup step.

Use a custom audit path or DevTools endpoint when testing a specific setup:

```sh
.build/debug/Ln1 doctor --audit-log /tmp/Ln1-audit.jsonl --endpoint http://127.0.0.1:9222 --timeout-ms 1000
```

## Inspect Action Policy

```sh
.build/debug/Ln1 policy
```

The policy output lists the default allowed risk level, ordered risk levels, and known typed actions with their domain, risk, and mutation classification. Commands such as `perform`, `files read-text`, `files tail-text`, `files read-lines`, `files read-json`, `files write-text`, `files append-text`, `files duplicate`, `files move`, `files mkdir`, `files rollback`, `clipboard read-text`, `clipboard write-text`, `browser text`, `browser dom`, `browser fill`, `browser select`, `browser check`, `browser focus`, `browser press-key`, `browser click`, `browser navigate`, and task memory commands use these risk levels when evaluating `--allow-risk`; browser tab metadata inspection, browser URL/selector/text/attribute waiting, and filesystem watch actions are listed as low-risk, non-mutating reads.

## Observe The Current Computer State

```sh
.build/debug/Ln1 observe --app-limit 20 --window-limit 20
```

`observe` is the safest first command before acting. It returns Accessibility trust status, the active app, a bounded running-app list, visible desktop windows with stable identities, current blockers, and suggested next typed commands. It does not require Accessibility permission; when Accessibility is not trusted, the snapshot reports that blocker and suggests `Ln1 trust` instead of trying to inspect or control app UI.

## Preflight A Workflow

```sh
.build/debug/Ln1 workflow preflight --operation inspect-active-app
```

Workflow preflight turns an intended task into prerequisites, blockers, risk, mutation status, and the safest next command. Supported operations are `inspect-active-app`, `control-active-app`, `read-browser`, `fill-browser`, `select-browser`, `check-browser`, `focus-browser`, `press-browser-key`, `click-browser`, `navigate-browser`, `wait-browser-url`, `wait-browser-selector`, `wait-browser-count`, `wait-browser-text`, `wait-browser-element-text`, `wait-browser-value`, `wait-browser-ready`, `wait-browser-title`, `wait-browser-checked`, `wait-browser-enabled`, `wait-browser-focus`, `wait-browser-attribute`, `wait-clipboard`, `inspect-clipboard`, `inspect-file`, `read-file`, `tail-file`, `read-file-lines`, `write-file`, `append-file`, `list-files`, `search-files`, `create-directory`, `duplicate-file`, `move-file`, `rollback-file-move`, `checksum-file`, `compare-files`, `watch-file`, and `wait-file`.

Examples:

```sh
.build/debug/Ln1 workflow preflight --operation control-active-app --element w0.1 --expect-identity accessibilityElement:abc123
.build/debug/Ln1 workflow preflight --operation read-browser --endpoint http://127.0.0.1:9222
.build/debug/Ln1 workflow preflight --operation click-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]'
.build/debug/Ln1 workflow preflight --operation fill-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --text "search query"
.build/debug/Ln1 workflow preflight --operation select-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'select[name=country]' --value ca
.build/debug/Ln1 workflow preflight --operation check-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=subscribe]' --checked true
.build/debug/Ln1 workflow preflight --operation focus-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]'
.build/debug/Ln1 workflow preflight --operation press-browser-key --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --key Enter
.build/debug/Ln1 workflow preflight --operation navigate-browser --endpoint http://127.0.0.1:9222 --id TARGET_ID --url https://example.com/next --expect-url https://example.com/next --match exact
.build/debug/Ln1 workflow preflight --operation wait-browser-url --endpoint http://127.0.0.1:9222 --id TARGET_ID --expect-url https://example.com/next --match exact
.build/debug/Ln1 workflow preflight --operation wait-browser-selector --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]' --state visible
.build/debug/Ln1 workflow preflight --operation wait-browser-count --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector '.result-row' --count 3 --count-match at-least
.build/debug/Ln1 workflow preflight --operation wait-browser-text --endpoint http://127.0.0.1:9222 --id TARGET_ID --text "Saved successfully" --match contains
.build/debug/Ln1 workflow preflight --operation wait-browser-element-text --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector '[data-testid=status]' --text "Saved successfully" --match contains
.build/debug/Ln1 workflow preflight --operation wait-browser-value --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --text "bounded text" --match exact
.build/debug/Ln1 workflow preflight --operation wait-browser-ready --endpoint http://127.0.0.1:9222 --id TARGET_ID --state complete
.build/debug/Ln1 workflow preflight --operation wait-browser-title --endpoint http://127.0.0.1:9222 --id TARGET_ID --title "Checkout" --match contains
.build/debug/Ln1 workflow preflight --operation wait-browser-checked --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=subscribe]' --checked true
.build/debug/Ln1 workflow preflight --operation wait-browser-enabled --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]' --enabled true
.build/debug/Ln1 workflow preflight --operation wait-browser-focus --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --focused true
.build/debug/Ln1 workflow preflight --operation wait-browser-attribute --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[aria-expanded]' --attribute aria-expanded --text true --match exact
.build/debug/Ln1 workflow preflight --operation wait-clipboard --changed-from 42 --has-string true
.build/debug/Ln1 workflow preflight --operation inspect-clipboard
.build/debug/Ln1 workflow preflight --operation inspect-file --path ~/Desktop/a.txt
.build/debug/Ln1 workflow preflight --operation read-file --path ~/Desktop/a.txt --max-characters 4096
.build/debug/Ln1 workflow preflight --operation tail-file --path ~/Desktop/a.txt --max-characters 4096
.build/debug/Ln1 workflow preflight --operation read-file-lines --path ~/Desktop/a.txt --start-line 40 --line-count 20 --max-line-characters 240
.build/debug/Ln1 workflow preflight --operation write-file --path ~/Desktop/a.txt --text "bounded text" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation append-file --path ~/Desktop/a.txt --text "\nnext note" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation list-files --path ~/Desktop --depth 1 --limit 50
.build/debug/Ln1 workflow preflight --operation search-files --path ~/Documents --query invoice --depth 4 --limit 50
.build/debug/Ln1 workflow preflight --operation create-directory --path ~/Desktop/Archive --allow-risk medium
.build/debug/Ln1 workflow preflight --operation duplicate-file --path ~/Desktop/a.txt --to ~/Desktop/a-copy.txt --allow-risk medium
.build/debug/Ln1 workflow preflight --operation move-file --path ~/Desktop/a.txt --to ~/Desktop/b.txt --allow-risk medium
.build/debug/Ln1 workflow preflight --operation rollback-file-move --audit-id AUDIT_ID --allow-risk medium
.build/debug/Ln1 workflow preflight --operation checksum-file --path ~/Downloads/report.pdf --max-file-bytes 104857600
.build/debug/Ln1 workflow preflight --operation compare-files --path ~/Downloads/report.pdf --to ~/Downloads/report-copy.pdf --max-file-bytes 104857600
.build/debug/Ln1 workflow preflight --operation watch-file --path ~/Downloads --depth 1 --watch-timeout-ms 30000
.build/debug/Ln1 workflow preflight --operation wait-file --path ~/Downloads/report.pdf --exists true --size-bytes 1048576 --digest SHA256_HEX --wait-timeout-ms 5000
```

When an automation loop needs an executable plan, use `workflow next` with the same operation and options:

```sh
.build/debug/Ln1 workflow next --operation create-directory --path ~/Desktop/Archive --allow-risk medium
```

`workflow next` embeds the full preflight result and, when unblocked, returns a structured command with both a display string and an `argv` array. Prefer the `argv` array when launching a follow-up command so paths, selectors, and reason text do not need shell parsing.

For a bounded run decision that still does not execute or mutate anything, use dry-run mode:

```sh
.build/debug/Ln1 workflow run --operation create-directory --path ~/Desktop/Archive --allow-risk medium --dry-run true
```

`workflow run --dry-run true` returns whether the workflow is ready, whether it would execute, the command that would be used, and the embedded preflight evidence. This mode is intentionally non-executing. Browser fill/click/navigation workflows are mutating, so dry-run is the safe way to validate tab IDs, selectors, URLs, policy, and audit-log readiness before running the returned browser command directly.

Execution mode runs non-mutating workflows directly:

```sh
.build/debug/Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --dry-run false --run-timeout-ms 10000 --max-output-bytes 1048576
```

For non-mutating workflows, `workflow run --dry-run false` executes the next command and captures its exit code, stdout, stderr, byte counts, truncation flags, timeout status, and parsed JSON output when stdout is complete JSON.

Mutating workflow execution is opt-in and still goes through the underlying typed command policy and audit log:

```sh
.build/debug/Ln1 workflow run --operation create-directory --path ~/Desktop/Archive --allow-risk medium --dry-run false --execute-mutating true --reason "Prepare archive folder"
```

Use dry-run first for mutating browser actions and file operations, then run with `--execute-mutating true` and a non-placeholder `--reason` once the command, target, policy, and audit path are correct. After a successful verified `write-file`, `append-file`, `create-directory`, `duplicate-file`, `move-file`, or `rollback-file-move` workflow, `workflow resume` suggests a `files stat` check for the verified destination or restored source so the next step is grounded in current metadata.

`wait-file` is a non-mutating workflow operation for bounded state waiting. The workflow runner's `--run-timeout-ms` can be shorter than the underlying `--wait-timeout-ms` when the outer control loop needs a hard deadline. Pass `--size-bytes N` and/or `--digest SHA256` when the file must exist with specific metadata before the workflow should continue.

`watch-file` is a non-mutating workflow operation for bounded filesystem event waiting. The workflow runner's `--run-timeout-ms` can be shorter than the underlying `--watch-timeout-ms` when the outer control loop needs a hard deadline. After a successful watch, `workflow resume` suggests a metadata or directory-list command for the first observed event.

`checksum-file` is a non-mutating workflow operation for bounded SHA-256 file verification. It validates that the target is a readable regular file within `--max-file-bytes`, then runs `files checksum` without exposing file contents. After a successful checksum, `workflow resume` suggests a digest-based `wait-file` dry-run so the next step can verify the file has not changed.

`compare-files` is a non-mutating workflow operation for bounded file equivalence checks. It validates both paths as readable regular files within `--max-file-bytes`, then runs `files compare` to report size and digest equality without exposing file contents. After a completed compare, `workflow resume` suggests a metadata inspection of the right-side file.

`inspect-file` is a non-mutating workflow operation for current filesystem metadata. It wraps `files stat` in workflow preflight/run logging, then `workflow resume` suggests either listing a directory or dry-running a checksum workflow for a readable regular file.

`read-file` is a medium-risk non-mutating workflow operation for bounded UTF-8 file text. It validates a readable regular file within `--max-file-bytes`, runs `files read-text` with explicit medium-risk approval, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`tail-file` is a medium-risk non-mutating workflow operation for bounded UTF-8 file tail text. It validates a readable regular file within `--max-file-bytes`, runs `files tail-text` with explicit medium-risk approval, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`read-file-lines` is a medium-risk non-mutating workflow operation for bounded, numbered UTF-8 file line ranges. It validates a readable regular file within `--max-file-bytes`, runs `files read-lines` with explicit medium-risk approval and `--start-line`, `--line-count`, and `--max-line-characters` bounds, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`write-file` is a medium-risk mutating workflow operation for UTF-8 file text writes. It validates the destination parent directory, requires `--text`, refuses to replace existing files unless `--overwrite` is passed, runs `files write-text` with explicit medium-risk approval and a non-placeholder reason, and `workflow resume` suggests inspecting the written file metadata after verification.

`append-file` is a medium-risk mutating workflow operation for UTF-8 file text appends. It validates the existing writable regular file, requires `--text`, refuses missing paths unless `--create` is passed, runs `files append-text` with explicit medium-risk approval and a non-placeholder reason, and `workflow resume` suggests inspecting the appended file metadata after verification.

`list-files` is a non-mutating workflow operation for bounded directory inventories. It validates that the path is a readable directory, forwards `--depth`, `--limit`, and `--include-hidden`, and `workflow resume` suggests a dry-run `inspect-file` workflow for the first listed path or the empty directory itself.

`search-files` is a non-mutating workflow operation for bounded filename and content search. It validates a readable root and non-empty `--query`, forwards the same search bounds as `files search`, and `workflow resume` suggests a dry-run `inspect-file` workflow for the first matched file or the search root.

`inspect-clipboard` is a non-mutating workflow operation for clipboard metadata snapshots. It wraps `clipboard state` without returning clipboard text, and `workflow resume` suggests either bounded text reading after explicit medium-risk approval or a metadata wait for future plain text.

`wait-clipboard` is a non-mutating workflow operation for bounded clipboard metadata waiting. It can wait for the pasteboard change count to differ from `--changed-from N`, for plain-text availability with `--has-string true|false`, or for a specific text digest with `--string-digest HEX`, without returning clipboard text.

`wait-browser-url` is a non-mutating workflow operation for bounded browser navigation verification after clicks, submissions, or external navigation. It polls structured tab metadata until the URL matches `--expect-url` with `--match exact|prefix|contains`, then returns typed verification evidence.

`wait-browser-selector` is a non-mutating workflow operation for bounded browser UI readiness checks. It polls the tab's DevTools runtime until `--selector` is attached, visible, hidden, or detached with `--state attached|visible|hidden|detached`, then returns selector metadata for the next action.

`wait-browser-count` is a non-mutating workflow operation for bounded collection readiness checks. It polls the tab's DevTools runtime until the number of matching elements satisfies `--count N` with `--count-match exact|at-least|at-most`.

`wait-browser-text` is a non-mutating workflow operation for bounded page text readiness checks. It polls visible page text until `--text` matches with `--match contains|exact`, returning only text lengths and SHA-256 digests rather than page text contents.

`wait-browser-element-text` is a non-mutating workflow operation for bounded element text readiness checks. It polls one selector until `--text` matches with `--match contains|exact`, returning only selector metadata, text lengths, and SHA-256 digests rather than element text contents.

`wait-browser-value` is a non-mutating workflow operation for bounded form value readiness checks. It polls one input, textarea, or select until `--text` matches the field value with `--match exact|contains`, returning only value lengths and SHA-256 digests rather than field contents.

`wait-browser-ready` is a non-mutating workflow operation for bounded page load readiness checks. It polls `document.readyState` until the tab reaches `--state loading|interactive|complete`, defaulting to `complete`.

`wait-browser-title` is a non-mutating workflow operation for bounded browser title checks. It polls structured tab metadata until `--title` matches with `--match contains|exact` without reading page contents.

`wait-browser-checked` is a non-mutating workflow operation for bounded checkbox and radio checks. It polls the tab's DevTools runtime until `--selector` is a checkbox or radio input with the expected `--checked true|false` state.

`wait-browser-enabled` is a non-mutating workflow operation for bounded element readiness checks. It polls the tab's DevTools runtime until `--selector` matches the expected `--enabled true|false` state, accounting for native disabled controls and `aria-disabled="true"`.

`wait-browser-focus` is a non-mutating workflow operation for bounded keyboard focus checks. It polls the tab's DevTools runtime until `--selector` matches the expected `--focused true|false` state.

`wait-browser-attribute` is a non-mutating workflow operation for bounded DOM attribute checks. It polls one selector until `--attribute NAME` matches `--text TEXT` with `--match exact|contains`, returning only attribute value lengths and SHA-256 digests rather than the attribute value itself.

After a successful `wait-browser-url` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the arrived page so the next step can be selected from the new page state.

After a successful `wait-browser-selector` transcript, `workflow resume` suggests a direct fill, select, check, or click command when the selector metadata is clearly actionable, otherwise it suggests a dry-run DOM inspection.

After a successful `wait-browser-count` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched collection state.

After a successful `wait-browser-text` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched page state.

After a successful `wait-browser-element-text` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched element state.

After a successful `wait-browser-value` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched field state.

After a successful `wait-browser-ready` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the loaded page state.

After a successful `wait-browser-title` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched page state.

After a successful `wait-browser-checked` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched form state.

After a successful `wait-browser-enabled` transcript, `workflow resume` suggests a direct fill, select, check, or click command when the now-enabled selector metadata is clearly actionable, otherwise it suggests a dry-run DOM inspection.

After a successful `wait-browser-focus` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the focused element state.

After a successful `wait-browser-attribute` transcript, `workflow resume` suggests a dry-run `read-browser` DOM inspection for the matched element state.

Each workflow run appends a JSONL transcript record containing the preflight, command, execution result, blockers, and transcript ID. Use `--workflow-log PATH` to choose a log path, or inspect the default log with:

```sh
.build/debug/Ln1 workflow log --allow-risk medium --limit 20
```

`workflow log` can filter by `--operation`. It requires `--allow-risk medium` because transcript entries may include captured command output.

To resume after an interruption, ask for a recommendation from the latest transcript entry:

```sh
.build/debug/Ln1 workflow resume --allow-risk medium
```

`workflow resume` reports whether the latest matching workflow is `completed`, `blocked`, `timed_out`, `failed`, `ready`, or `empty`, and returns a conservative next command or argument array. For completed browser tab listings, it can suggest a dry-run DOM inspection for the first tab; for completed DOM inspections, it can suggest fill, select, check, or click commands from the first actionable selector.

## Inspect Running Apps

```sh
.build/debug/Ln1 apps
```

If you are running from a non-interactive shell and want every process macOS exposes:

```sh
.build/debug/Ln1 apps --all
```

## Inspect Visible Desktop Windows

```sh
.build/debug/Ln1 desktop windows --limit 50
```

The output is structured JSON from macOS window metadata: availability, window ID, owner app name and PID, bundle identifier when available, active-owner flag, title when macOS exposes it, layer, bounds, onscreen state, alpha, memory usage, and sharing state. This is a low-risk desktop inspection action that does not require screenshots or Accessibility access. If the current process cannot read WindowServer metadata, the command still returns a structured unavailable result instead of falling back to screenshots.

Each window includes both a transient WindowServer `id` and a semantic `stableIdentity`. The stable identity is a digest built from durable-ish fields such as owner bundle identifier, title, layer, and coarse bounds when the title is unavailable. It also reports a confidence level, user-readable label, identity components, and reasons so callers can avoid acting when a repeated observation only matches a low-confidence window reference.

By default `desktop windows` reports visible non-desktop, normal-layer windows. Include desktop elements or menu/overlay layers when they are relevant:

```sh
.build/debug/Ln1 desktop windows --include-desktop --all-layers
```

## Emit Structured State

```sh
.build/debug/Ln1 state --depth 4 --max-children 120
```

The output is JSON with app metadata, windows, elements, frames, values, and available actions.

Each Accessibility node includes the path-style `id` used by `perform` plus a semantic `stableIdentity`. The stable identity summarizes owner, role, title or help text, actions, and coarse frame when available, then reports a digest, confidence, readable label, components, and reasons. Use the confidence and reasons to decide whether a repeated observation still refers to the same control before acting.

By default this targets the frontmost app. To walk every running GUI app macOS exposes through Accessibility:

```sh
.build/debug/Ln1 state --all --depth 3 --max-children 80
```

To also try background/menu-bar style processes:

```sh
.build/debug/Ln1 state --all --include-background --depth 2 --max-children 50
```

This is still not literally every piece of data on the machine. macOS exposes UI state per app through Accessibility. Files, browser DOM, calendars, mail stores, databases, and notifications need separate adapters.

## Perform An Action

Use an element ID from `state`:

```sh
.build/debug/Ln1 perform --element w0.3.1 --action AXPress --reason "Open the details panel"
```

`perform` applies a conservative action policy before touching Accessibility APIs. By default, only actions classified as `low` risk are allowed. To explicitly permit broader known or unclassified action categories:

```sh
.build/debug/Ln1 perform --element w0.3.1 --action AXConfirm --allow-risk medium --reason "Confirm the selected dialog"
.build/debug/Ln1 perform --element w0.3.1 --action AXCustomAction --allow-risk unknown --reason "Use app-specific action"
```

Policy denials are written to the audit log with the requested action, classified risk, allowed risk threshold, reason, and denial outcome. They do not require Accessibility access because the policy is checked before app inspection or action execution.

For IDs from `state --all`, pass the app PID from that same app record:

```sh
.build/debug/Ln1 perform --pid 456 --element a0.w0.3.1 --action AXPress --reason "Open the details panel"
```

To target a specific app:

```sh
.build/debug/Ln1 state --pid 123
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open the details panel"
```

To guard against a stale element path, pass the `stableIdentity.id` from a recent `state` observation and a minimum identity confidence:

```sh
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --expect-identity accessibilityElement:abc123 --min-identity-confidence medium --action AXPress --reason "Open the details panel"
```

When identity constraints are present, `perform` recomputes the target element identity after resolving the path and before invoking the Accessibility action. It refuses to act if the identity digest does not match or if the current confidence is below `low`, `medium`, or `high` as requested.

Every `perform` attempt appends a structured JSONL audit record before returning success or failure. The action result includes the audit record ID and log path, plus the target stable identity and identity verification result when available.

By default the audit log is stored at:

```text
~/Library/Application Support/Ln1/audit-log.jsonl
```

Use `--audit-log` to send records to another file during tests or isolated runs:

```sh
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open details" --audit-log /tmp/Ln1-audit.jsonl
```

The audit entry records typed intent and outcome: timestamp, risk level, target app, element ID, stable identity, available element actions, requested action, optional reason, optional identity verification, and result. It intentionally stores only a small element summary and does not store element values.

## Review The Audit Log

Read recent audit records:

```sh
.build/debug/Ln1 audit --limit 20
```

Read from a custom audit file:

```sh
.build/debug/Ln1 audit --audit-log /tmp/Ln1-audit.jsonl --limit 5
```

Filter audit records before applying the limit:

```sh
.build/debug/Ln1 audit --command files.move --code moved --limit 10
```

`--command` matches audit command names such as `perform`, `files.read-text`, `files.tail-text`, `files.read-lines`, `files.read-json`, `files.write-text`, `files.append-text`, `files.duplicate`, `files.move`, `files.mkdir`, `files.rollback`, `clipboard.read-text`, `browser.text`, or `browser.dom`. `--code` matches the outcome code, such as `policy_denied`, `read_text`, `tail_text`, `read_lines`, `read_json`, `json_pointer_missing`, `created_text_file`, `appended_text_file`, `duplicated`, `moved`, `created_directory`, `rolled_back_move`, or `read_dom`.

## Track Task Memory

Start a task-scoped memory journal when a workflow needs resumable context:

```sh
.build/debug/Ln1 task start --title "Verify downloaded report" --summary "Wait for report.pdf and compare checksum" --allow-risk medium
```

Task memory is a medium-risk local persistence action because it can store task context. By default it writes JSONL events to:

```text
~/Library/Application Support/Ln1/task-memory.jsonl
```

Use `--memory-log` to isolate tests or a specific workflow:

```sh
.build/debug/Ln1 task start --title "Verify downloaded report" --allow-risk medium --memory-log /tmp/Ln1-task-memory.jsonl
```

Append typed task events as work progresses:

```sh
.build/debug/Ln1 task record --task-id TASK_ID --kind observation --summary "report.pdf appeared in Downloads" --allow-risk medium
.build/debug/Ln1 task record --task-id TASK_ID --kind verification --summary "checksum matched expected digest" --related-audit-id AUDIT_ID --allow-risk medium
```

Supported event kinds are `observation`, `decision`, `action`, `verification`, and `note`. Summaries default to `private` sensitivity. When a summary is marked `sensitive`, the event records only its length and SHA-256 digest, not the summary text:

```sh
.build/debug/Ln1 task record --task-id TASK_ID --kind observation --summary "copied one-time code 123456" --sensitivity sensitive --allow-risk medium
```

Finish and inspect the task:

```sh
.build/debug/Ln1 task finish --task-id TASK_ID --status completed --summary "Downloaded report was verified." --allow-risk medium
.build/debug/Ln1 task show --task-id TASK_ID --limit 20 --allow-risk medium
```

`task show` returns the task title, status, start/update timestamps, event count, and recent events. Reading task memory is also medium-risk because it may reveal persisted private workflow context.

## Inspect Filesystem State

Inspect one file or folder without reading file contents:

```sh
.build/debug/Ln1 files stat --path ~/Documents/Plan.md
```

List a folder as structured metadata:

```sh
.build/debug/Ln1 files list --path ~/Documents --depth 2 --limit 200
```

Hidden files are skipped by default. Include them explicitly when they are relevant:

```sh
.build/debug/Ln1 files list --path ~/Documents --include-hidden --depth 1
```

The filesystem adapter returns stable-ish file identity, absolute path, kind, size, timestamps, hidden/readable/writable flags, and available typed actions such as `filesystem.stat`, `filesystem.list`, `filesystem.search`, `filesystem.watch`, `filesystem.plan`, `filesystem.readText`, `filesystem.tailText`, `filesystem.readLines`, `filesystem.readJSON`, `filesystem.writeText`, `filesystem.appendText`, `filesystem.duplicate`, `filesystem.move`, `filesystem.createDirectory`, and `filesystem.rollbackMove`. Search only exposes bounded matching snippets, not full file contents.

Search file names and bounded UTF-8 text content without using Finder:

```sh
.build/debug/Ln1 files search --path ~/Documents --query invoice --depth 4 --limit 50
```

Search is case-insensitive by default, skips hidden files unless `--include-hidden` is passed, and avoids unbounded reads with `--max-file-bytes`, `--max-snippet-characters`, and `--max-matches-per-file`. Results include file metadata, whether the name matched, matching line numbers, short line snippets, scan counts, and skip counts for unreadable, binary, or oversized files.

Read bounded UTF-8 text from one known regular file:

```sh
.build/debug/Ln1 files read-text --path ~/Documents/Plan.md --allow-risk medium --max-characters 4096 --reason "Inspect selected project notes"
```

`filesystem.readText` is a medium-risk non-mutating read because file contents may be private. It requires explicit policy approval, refuses directories and files above `--max-file-bytes`, returns at most `--max-characters` of UTF-8 text, and writes an audit record containing only file metadata and outcome details, not the text itself.

Read the end of a UTF-8 file through the same policy and audit path:

```sh
.build/debug/Ln1 files tail-text --path ~/Library/Logs/example.log --allow-risk medium --max-characters 4096 --reason "Inspect latest log output"
```

`filesystem.tailText` is a medium-risk non-mutating read for logs and generated files where the newest content is at the end. It uses the same bounds and audit redaction as `filesystem.readText`, but returns the final `--max-characters` instead of the prefix.

Read a bounded, numbered line range from a UTF-8 file:

```sh
.build/debug/Ln1 files read-lines --path ~/Documents/Plan.md --start-line 40 --line-count 20 --allow-risk medium --reason "Inspect relevant plan section"
```

`filesystem.readLines` is a medium-risk non-mutating read for inspecting targeted file ranges without returning the whole file. It uses the same regular-file, UTF-8, size-bound, and audit-redaction rules as `filesystem.readText`, and returns numbered lines capped by `--line-count` and `--max-line-characters`.

Read a bounded typed tree from a JSON file, optionally at a JSON Pointer:

```sh
.build/debug/Ln1 files read-json --path ~/Documents/config.json --pointer /services/0 --max-depth 3 --max-items 20 --allow-risk medium --reason "Inspect selected service config"
```

`filesystem.readJSON` is a medium-risk non-mutating read for structured JSON files. It refuses directories and files above `--max-file-bytes`, parses UTF-8 JSON, returns typed object/array/scalar nodes capped by `--max-depth`, `--max-items`, and `--max-string-characters`, and writes an audit record containing only file metadata and outcome details, not JSON values.

Create one UTF-8 text file through policy, audit, and verification:

```sh
.build/debug/Ln1 files write-text --path ~/Documents/agent-note.txt --text "Prepared by Ln1" --allow-risk medium --reason "Create a structured note"
```

`filesystem.writeText` is a medium-risk mutating action. It creates missing files by default, refuses to replace existing files unless `--overwrite` is passed, requires a writable parent directory, verifies the written file by byte length and SHA-256 digest, and audits only file metadata, policy, and verification details.

Append UTF-8 text without replacing the existing file:

```sh
.build/debug/Ln1 files append-text --path ~/Documents/agent-note.txt --text "\nNext step recorded by Ln1" --allow-risk medium --reason "Record agent progress"
```

`filesystem.appendText` is a medium-risk mutating action. It appends to an existing writable regular file, refuses missing paths unless `--create` is passed, verifies the final byte length and tail bytes, and audits only file metadata, policy, appended text length/digest, verification details, and outcome.

Wait for a path to appear or disappear with bounded polling:

```sh
.build/debug/Ln1 files wait --path ~/Downloads/report.pdf --exists true --timeout-ms 5000 --interval-ms 100
.build/debug/Ln1 files wait --path ~/Downloads/report.pdf --exists true --size-bytes 1048576 --digest SHA256_HEX --timeout-ms 30000
.build/debug/Ln1 files wait --path ~/Downloads/report.part --exists false --timeout-ms 30000
```

`files wait` returns structured evidence about whether the expected existence state and optional size/digest metadata matched before the timeout. When the path exists, the response includes the same file metadata shape used by `files stat`; when `--digest` is provided, it also returns the current SHA-256 digest and whether it matched without exposing file contents. This is useful for downloads, generated files, and verification loops without relying on Finder state. After a successful `wait-file` workflow, `workflow resume` suggests a structured metadata or directory-list command for the matched path instead of requiring log interpretation.

Watch a file or directory for metadata changes:

```sh
.build/debug/Ln1 files watch --path ~/Downloads --depth 1 --timeout-ms 30000 --interval-ms 250
```

`files watch` is a low-risk read action that snapshots file metadata, waits for the first created, deleted, or modified event under the path, then returns normalized event records with previous/current `FileRecord` metadata. It uses `--depth`, `--limit`, and `--include-hidden` to keep directory watches bounded.

Compute a bounded content digest without returning file contents:

```sh
.build/debug/Ln1 files checksum --path ~/Documents/Plan.md --algorithm sha256 --max-file-bytes 104857600
```

`filesystem.checksum` currently supports SHA-256 for regular files. It is a low-risk read action, but still bounded by `--max-file-bytes` so large files are not read accidentally. The response includes file metadata, the algorithm, and the hex digest.

Compare two regular files by size and digest:

```sh
.build/debug/Ln1 files compare --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md --algorithm sha256
```

`filesystem.compare` is a low-risk read action that computes bounded SHA-256 digests for both files and reports `sameSize`, `sameDigest`, and `matched`. This is useful after copy or generation workflows where the assistant needs evidence that two files are identical without reading contents into the prompt.

Preview a mutating file operation before executing it:

```sh
.build/debug/Ln1 files plan --operation move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium
.build/debug/Ln1 files plan --operation duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md
.build/debug/Ln1 files plan --operation mkdir --path ~/Documents/Archive --allow-risk medium
.build/debug/Ln1 files plan --operation rollback --audit-id AUDIT_ID --allow-risk medium
```

`filesystem.plan` is a low-risk read action that makes no filesystem changes. It returns the underlying typed action, action mutation flag, risk, policy decision, source and destination metadata where available, named preflight checks, `canExecute`, and the `requiredAllowRisk` needed by the matching mutation command. This lets a caller explain exactly what will be affected before copying, moving, creating, or rolling back a file operation.

Duplicate one regular file through an audited typed action:

```sh
.build/debug/Ln1 files duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan-copy.md --allow-risk medium --reason "Keep an original before editing"
```

`filesystem.duplicate` is a medium-risk mutating file action. It is denied by the default low-risk policy unless `--allow-risk medium` is supplied. The command refuses to overwrite an existing destination, requires the destination parent directory to already exist, verifies that the copied file exists with the same byte size, and appends an audit record for success, policy denial, preflight failure, or verification failure.

Move or rename one regular file through the same policy and audit path:

```sh
.build/debug/Ln1 files move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium --reason "Archive completed draft"
```

`filesystem.move` is also a medium-risk mutating file action. It refuses to overwrite an existing destination, requires both source and destination parent directories to be writable, verifies that the original source path is gone and the destination has the same byte size, and records the policy decision plus verification result in the audit log.

Rollback a successful audited file move:

```sh
.build/debug/Ln1 files rollback --audit-id AUDIT_ID --allow-risk medium --reason "Undo mistaken move"
```

`filesystem.rollbackMove` is a medium-risk mutating file action. It reads the requested audit record, only supports successful `files.move` records, verifies that the current moved file still matches the recorded destination metadata, refuses to overwrite the original source path, moves the file back, verifies that the original source path is restored and the moved destination is gone, and records the rollback policy decision plus verification result in the audit log.

Create one directory for organization workflows:

```sh
.build/debug/Ln1 files mkdir --path ~/Documents/Archive --allow-risk medium --reason "Create archive folder"
```

`filesystem.createDirectory` is a medium-risk mutating file action. It refuses existing paths, requires the parent directory to exist and be writable, verifies that the directory exists after creation, and records the policy decision plus verification result in the audit log.

## Inspect Clipboard State

Inspect clipboard metadata without returning copied text:

```sh
.build/debug/Ln1 clipboard state
```

`clipboard.state` is a low-risk read action. It returns the pasteboard name, change count, available pasteboard types, whether plain text is available, the text length, and a SHA-256 digest of the text. It intentionally does not return clipboard contents.

Wait for clipboard metadata without returning copied text:

```sh
.build/debug/Ln1 clipboard wait --changed-from 42 --has-string true --timeout-ms 5000
```

`clipboard.wait` is a low-risk read action. It polls pasteboard metadata until the change count differs from `--changed-from`, the plain-text availability matches `--has-string`, and/or the text digest matches `--string-digest`; it returns only metadata, lengths, and digests. After a successful `wait-clipboard` workflow, `workflow resume` suggests either bounded `clipboard read-text` when plain text is available or another metadata-only state check when it is not.

Read bounded plain text from the clipboard only after explicitly allowing medium-risk clipboard access:

```sh
.build/debug/Ln1 clipboard read-text --allow-risk medium --max-characters 4096 --reason "Use copied confirmation code"
```

`clipboard.readText` is a medium-risk read action because clipboard text may contain private transient data. The command writes an audit record containing pasteboard metadata, text length, digest, policy decision, reason, and outcome, but the audit record does not store the clipboard text itself. Use `--pasteboard NAME` to target a named pasteboard for tests or isolated workflows.

Write plain text to the clipboard only after explicitly allowing medium-risk clipboard mutation:

```sh
.build/debug/Ln1 clipboard write-text --text "ready to paste" --allow-risk medium --reason "Prepare value for the next app"
```

`clipboard.writeText` is a medium-risk mutating action because it replaces the current plain-text pasteboard contents. The command records before/after pasteboard metadata, text lengths, digests, policy decision, verification result, reason, and outcome without storing either the previous or new clipboard text in the audit log. The command verifies the write by checking that the clipboard contains text with the requested length and SHA-256 digest.

## Inspect Browser Tabs

Start Chrome or another Chromium browser with a DevTools endpoint, then ask Ln1 for browser-native tab metadata:

```sh
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
.build/debug/Ln1 browser tabs --endpoint http://127.0.0.1:9222
```

`browser.listTabs` is a low-risk read action. It reads `/json/list` from the explicit DevTools endpoint and returns structured tab records with target IDs, type, title, URL, DevTools frontend URL, WebSocket debugger URL, favicon URL, attachment state, and available typed browser actions. Non-page DevTools targets such as service workers are hidden by default; include them when relevant:

```sh
.build/debug/Ln1 browser tabs --endpoint http://127.0.0.1:9222 --include-non-page
```

Inspect one tab from the same structured source:

```sh
.build/debug/Ln1 browser tab --endpoint http://127.0.0.1:9222 --id TARGET_ID
```

Read the visible text from a page through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser text --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-characters 16384 --reason "Extract page text for summarization"
```

`browser.readText` is a medium-risk read action because page text can contain private web-app content. The command returns bounded text to the caller, but its audit record stores only the tab ID, type, title, URL, text length, digest, policy decision, reason, and outcome. It does not click in the browser and does not require Accessibility access.

Read bounded structured page state from the DOM:

```sh
.build/debug/Ln1 browser dom --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-elements 200 --max-text-characters 120 --reason "Inspect page controls before acting"
```

`browser.readDOM` is also a medium-risk read action because labels, links, visible text, and form metadata can expose private web-app state. The result includes bounded DOM elements with IDs, parent IDs, depth, actionable CSS selectors, tag names, inferred roles, bounded text snippets, selected safe attributes, ARIA state attributes such as `aria-expanded` and `aria-selected`, links, and form metadata such as input type, checked/disabled state, and value length. It intentionally does not return form values and suppresses value metadata for password and hidden inputs. The audit record stores only tab metadata, DOM element count, DOM digest, policy decision, reason, and outcome; it does not store the DOM payload.

Fill one browser form field through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser fill --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --text "search query" --allow-risk medium --reason "Prepare search"
```

`browser.fillFormField` is a medium-risk mutating action because it changes page state and may enter private text into a web app. The command targets one CSS selector, refuses disabled, read-only, and unsupported elements, dispatches `input` and `change` events, and verifies that the field contains text with the requested length. The result includes the selector, text length, SHA-256 digest, target metadata, verification, and audit ID. The audit record stores tab metadata, selector, text length, digest, policy decision, reason, verification, and outcome without storing the entered text.

Choose one option in a browser select control through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser select --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'select[name=country]' --value ca --allow-risk medium --reason "Choose country"
```

`browser.selectOption` is a medium-risk mutating action because it changes page state and may affect downstream form behavior. The command targets one `<select>` selector, accepts either `--value` or `--label`, dispatches `input` and `change` events, and verifies the selected option. The result and audit record store selector, option length/digest, target metadata, verification, and outcome without storing option text.

Set one checkbox or radio control through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser check --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=subscribe]' --checked true --allow-risk medium --reason "Set subscription preference"
```

`browser.setChecked` is a medium-risk mutating action because it changes page state and may affect form submission or web-app preferences. The command targets one checkbox or radio selector, defaults `--checked` to `true`, dispatches `input` and `change` events, and verifies the checked state. The audit record stores tab metadata, selector, requested checked state, policy decision, reason, verification, and outcome.

Focus one browser element through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser focus --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --allow-risk medium --reason "Prepare keyboard input"
```

`browser.focusElement` is a medium-risk mutating action because it changes page focus and can affect the next keyboard or form action. The command targets one CSS selector, refuses missing or disabled elements, scrolls it into view, calls `focus`, and verifies that the active element matches the requested selector. The audit record stores tab metadata, selector, target metadata, policy decision, reason, verification, and outcome without storing page text.

Press one key through the tab's DevTools WebSocket, optionally after focusing a selector:

```sh
.build/debug/Ln1 browser press-key --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --key Enter --allow-risk medium --reason "Submit focused form"
```

`browser.pressKey` is a medium-risk mutating action because keyboard events can submit forms, trigger shortcuts, or change page state. The command supports named keys such as `Enter`, `Escape`, `Tab`, arrows, `Home`, `End`, `PageUp`, `PageDown`, `Backspace`, `Delete`, `Space`, `F1` through `F12`, and one ASCII letter or digit. Use `--modifiers shift,control,alt,meta` for shortcuts. The audit record stores tab metadata, optional focus selector, key name, normalized modifiers, policy decision, reason, verification, and outcome without storing page text or field values.

Click one browser element through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser click --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]' --expect-url https://example.com/results --match prefix --allow-risk medium --reason "Submit search"
```

`browser.clickElement` is a medium-risk mutating action because it changes page state and may trigger navigation, form submission, or web-app side effects. The command targets one CSS selector, refuses missing or disabled elements, scrolls the element into view, dispatches a DOM click, and records selector/target metadata plus verification in the audit log. When `--expect-url` is supplied, the command also waits for the tab URL to match `--match exact|prefix|contains` and returns URL verification evidence.

Navigate one browser tab through DevTools and verify the resulting URL from structured tab metadata:

```sh
.build/debug/Ln1 browser navigate --endpoint http://127.0.0.1:9222 --id TARGET_ID --url https://example.com/next --allow-risk medium --reason "Open next page"
```

`browser.navigate` is a medium-risk mutating action because it changes browser state and may contact an external site. The command only accepts absolute HTTP(S) URLs, sends a typed `Page.navigate` command through the tab's DevTools WebSocket, then verifies the resulting URL through DevTools target metadata. By default verification requires an exact match with `--url`; use `--expect-url` with `--match exact|prefix|contains` for redirect-aware workflows. The audit record stores tab metadata, requested URL, verified current URL, policy decision, reason, verification, and outcome.

Wait for one browser tab to reach an expected URL without mutating the page:

```sh
.build/debug/Ln1 browser wait-url --endpoint http://127.0.0.1:9222 --id TARGET_ID --expect-url https://example.com/next --match exact --timeout-ms 5000
```

`browser.waitURL` is a low-risk read action. It polls structured DevTools tab metadata until the current URL matches the expected value, returning the same URL verification shape used by navigation.

Wait for one selector to become ready, hidden, or detached without mutating the page:

```sh
.build/debug/Ln1 browser wait-selector --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]' --state visible --timeout-ms 5000
```

`browser.waitSelector` is a low-risk read action. It polls `document.querySelector` through the tab's DevTools runtime until the selector is attached, visible, hidden, or detached, returning tag, disabled, href, text-length, and current URL metadata when an element is present.

Wait for a selector count without reading element contents:

```sh
.build/debug/Ln1 browser wait-count --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector '.result-row' --count 3 --count-match at-least --timeout-ms 5000
```

`browser.waitCount` is a low-risk read action. It polls `document.querySelectorAll` through the tab's DevTools runtime until the count matches with `--count-match exact|at-least|at-most`, returning only count, selector, URL, and match status.

Wait for visible page text without returning page contents:

```sh
.build/debug/Ln1 browser wait-text --endpoint http://127.0.0.1:9222 --id TARGET_ID --text "Saved successfully" --match contains --timeout-ms 5000
```

`browser.waitText` is a low-risk read action. It polls page inner text until the expected value matches, returning only lengths, digests, URL, and match status.

Wait for one element's text without returning text contents:

```sh
.build/debug/Ln1 browser wait-element-text --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector '[data-testid=status]' --text "Saved successfully" --match contains --timeout-ms 5000
```

`browser.waitElementText` is a low-risk read action. It polls one selector's normalized text until the expected value matches, returning only lengths, digests, URL, target tag, selector, and match status.

Wait for one field value without returning value contents:

```sh
.build/debug/Ln1 browser wait-value --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --text "bounded text" --match exact --timeout-ms 5000
```

`browser.waitValue` is a low-risk read action. It polls an input, textarea, or select value until the expected text matches, returning only lengths, digests, URL, target metadata, and match status. Password inputs are refused.

Wait for one page to reach a document readiness state without mutating the page:

```sh
.build/debug/Ln1 browser wait-ready --endpoint http://127.0.0.1:9222 --id TARGET_ID --state complete --timeout-ms 5000
```

`browser.waitReady` is a low-risk read action. It polls `document.readyState` and treats `complete` as satisfying `interactive`, returning the current state, URL, and match status.

Wait for one tab title to match without mutating the page or reading page contents:

```sh
.build/debug/Ln1 browser wait-title --endpoint http://127.0.0.1:9222 --id TARGET_ID --title "Checkout" --match contains --timeout-ms 5000
```

`browser.waitTitle` is a low-risk read action. It polls structured DevTools tab metadata until the title matches, returning title, URL, and match status.

Wait for one checkbox or radio input to reach a checked state without mutating the page:

```sh
.build/debug/Ln1 browser wait-checked --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=subscribe]' --checked true --timeout-ms 5000
```

`browser.waitChecked` is a low-risk read action. It polls a checkbox or radio input through the tab's DevTools runtime until its checked state matches, returning input metadata, current URL, and match status.

Wait for an element to become enabled or disabled without mutating the page:

```sh
.build/debug/Ln1 browser wait-enabled --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'button[type=submit]' --enabled true --timeout-ms 5000
```

`browser.waitEnabled` is a low-risk read action. It polls one selector through the tab's DevTools runtime until the enabled state matches, returning tag, input type, disabled/read-only metadata, current URL, and match status without clicking the element.

Wait for an element to become focused or unfocused without mutating the page:

```sh
.build/debug/Ln1 browser wait-focus --endpoint http://127.0.0.1:9222 --id TARGET_ID --selector 'input[name=q]' --focused true --timeout-ms 5000
```

`browser.waitFocus` is a low-risk read action. It polls one selector through the tab's DevTools runtime until the focus state matches, returning target and active-element metadata, current URL, and match status without focusing the element.

This adapter is now using browser-native DevTools metadata, page text, structured DOM snapshots with ARIA state metadata, typed form filling, typed select-option control, typed checked-state control, typed focus control, typed key presses, typed element clicking, verified navigation, bounded URL waiting, bounded selector readiness checks, bounded selector count checks, bounded text readiness checks, bounded value readiness checks, bounded document readiness checks, bounded title readiness checks, bounded checked-state readiness checks, bounded enabled-state readiness checks, bounded focus-state readiness checks, and bounded attribute-state readiness checks.

## Product Direction

The next step is to add adapters for richer state sources:

- Browser DOM through Chrome DevTools Protocol
- Filesystem document indexes and audited file operations beyond bounded local search
- Notifications
- App-native integrations where available
- A permission/audit log around every action

The model-facing API should stay typed and structured, with macOS Accessibility as the compatibility bridge for apps that do not expose native semantic data.
