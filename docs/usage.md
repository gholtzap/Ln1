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

The policy output lists the default allowed risk level, ordered risk levels, and known typed actions with their domain, risk, and mutation classification. Commands such as `perform`, `set-value`, `apps activate`, `apps launch`, `apps hide`, `apps unhide`, `apps quit`, `desktop minimize-active-window`, `desktop restore-window`, `desktop raise-window`, `desktop close-window`, `desktop set-window-frame`, `open`, `files read-text`, `files tail-text`, `files read-lines`, `files read-json`, `files read-plist`, `files write-text`, `files append-text`, `files duplicate`, `files move`, `files mkdir`, `files rollback`, `clipboard read-text`, `clipboard write-text`, `clipboard rollback`, `browser text`, `browser screenshot`, `browser console`, `browser dialogs`, `browser network`, `browser dom`, `browser fill`, `browser select`, `browser check`, `browser focus`, `browser press-key`, `browser click`, `browser navigate`, workflow transcript status/log reads, and task memory commands use these risk levels when evaluating `--allow-risk`; workflow scenario recipes, system context, running and installed app listing/planning, process metadata reads, accessibility menu and element inspection/waits, desktop metadata reads/waits, browser tab metadata inspection, browser URL/selector/text/attribute waiting, and filesystem watch actions are listed as low-risk, non-mutating reads.

## Inspect System Context

```sh
.build/debug/Ln1 system context
```

`system.context` returns bounded host and runtime metadata: OS version, architecture, processor and memory totals, uptime, host and user names, home and current working directories, shell path, time zone, locale, and the current Ln1 process identity. It does not dump arbitrary environment variables.

## Inspect Real-App Benchmarks

```sh
.build/debug/Ln1 benchmarks matrix
```

`benchmarks.matrix` returns a read-only real-app coverage matrix for repeatable verification. It includes Finder, browsers, Electron apps, Microsoft Office, Xcode, Terminal, System Settings, permission dialogs, file pickers, sheets, and modals, along with the required capabilities and success criteria each scenario should prove.

## Observe The Current Computer State

```sh
.build/debug/Ln1 observe --app-limit 20 --window-limit 20
```

`observe` is the safest first command before acting. It returns Accessibility trust status, the active app, a bounded running-app list, visible desktop windows with stable identities, current blockers, and suggested next typed commands. It does not require Accessibility permission; when Accessibility is not trusted, the snapshot reports that blocker and suggests `Ln1 trust` instead of trying to inspect or control app UI.

## Inspect Scenario Recipes

```sh
.build/debug/Ln1 workflow scenarios
.build/debug/Ln1 workflow scenarios --id desktop-app-qa
.build/debug/Ln1 workflow status --allow-risk medium
```

`workflow scenarios` is a read-only product map for the intended control loop: observe, inspect, preflight, act, verify, and audit. It returns scenario recipes with concrete command sequences, highest expected risk, safety gates, verification signals, and audit artifacts. The built-in scenarios are `desktop-app-qa`, `browser-regression`, `file-export-verification`, and `permission-dialog-triage`.

`workflow status` reads a bounded workflow transcript and reports phase counts, missing loop phases, blockers, the latest entry state, mutation evidence coverage, and the next command from `workflow resume`. Use it after several workflow runs to decide whether the task has enough inspect, preflight, act, verify, and audit evidence before continuing.

## Inspect App Menus

```sh
.build/debug/Ln1 state menu --depth 2 --max-children 80
.build/debug/Ln1 state find --title "Save" --action AXPress --include-menu --limit 20
```

`state menu` returns the target app's macOS Accessibility menu bar as a bounded tree with stable element identities, roles, titles, enabled state, minimized state when exposed by Accessibility, actions, and child paths such as `m0.1.2`. Pass `--pid PID` to inspect a specific running app instead of the frontmost app. This is read-only and useful before selecting a trusted menu action or deciding whether a menu command is present.

`state find` searches the target app's Accessibility windows, and optionally menu bar, by semantic attributes such as role, title, value, help text, action, and enabled state. It returns bounded candidate element IDs with stable identities so the next step can inspect or act on a concrete element without manually scanning a full tree.

## Preflight A Workflow

```sh
.build/debug/Ln1 workflow preflight --operation inspect-active-app
.build/debug/Ln1 workflow preflight --operation inspect-menu --pid 123 --depth 2 --max-children 80
```

Workflow preflight turns an intended task into prerequisites, blockers, risk, mutation status, and the safest next command. Supported operations are `review-audit`, `inspect-active-app`, `inspect-frontmost-app`, `inspect-apps`, `inspect-installed-apps`, `inspect-menu`, `inspect-system`, `inspect-displays`, `inspect-windows`, `inspect-processes`, `start-task`, `record-task`, `finish-task`, `show-task`, `inspect-process`, `inspect-element`, `wait-process`, `wait-active-window`, `wait-window`, `wait-element`, `wait-active-app`, `minimize-active-window`, `restore-window`, `raise-window`, `close-window`, `set-window-frame`, `activate-app`, `launch-app`, `hide-app`, `unhide-app`, `quit-app`, `open-file`, `open-url`, `control-active-app`, `set-element-value`, `read-browser`, `fill-browser`, `select-browser`, `check-browser`, `focus-browser`, `press-browser-key`, `click-browser`, `navigate-browser`, `wait-browser-url`, `wait-browser-selector`, `wait-browser-count`, `wait-browser-text`, `wait-browser-element-text`, `wait-browser-value`, `wait-browser-ready`, `wait-browser-title`, `wait-browser-checked`, `wait-browser-enabled`, `wait-browser-focus`, `wait-browser-attribute`, `wait-clipboard`, `inspect-clipboard`, `read-clipboard`, `write-clipboard`, `inspect-file`, `read-file`, `tail-file`, `read-file-lines`, `read-file-json`, `read-file-plist`, `write-file`, `append-file`, `list-files`, `search-files`, `create-directory`, `duplicate-file`, `move-file`, `rollback-file-move`, `checksum-file`, `compare-files`, `watch-file`, and `wait-file`.

Examples:

```sh
.build/debug/Ln1 workflow preflight --operation inspect-system
.build/debug/Ln1 workflow preflight --operation review-audit --id AUDIT_ID --audit-log /tmp/Ln1-audit.jsonl
.build/debug/Ln1 workflow preflight --operation inspect-frontmost-app
.build/debug/Ln1 workflow preflight --operation inspect-apps --limit 20
.build/debug/Ln1 workflow preflight --operation inspect-installed-apps --name TextEdit --limit 20
.build/debug/Ln1 workflow preflight --operation inspect-menu --pid 123 --depth 2 --max-children 80
.build/debug/Ln1 workflow preflight --operation inspect-displays
.build/debug/Ln1 workflow preflight --operation inspect-active-window
.build/debug/Ln1 workflow preflight --operation inspect-windows --limit 50
.build/debug/Ln1 workflow preflight --operation inspect-processes --name Safari --limit 20
.build/debug/Ln1 workflow preflight --operation start-task --title "Verify report" --summary "Track report download and checksum" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation record-task --task-id TASK_ID --kind verification --summary "checksum matched" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation finish-task --task-id TASK_ID --status completed --summary "Report verified" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation show-task --task-id TASK_ID --allow-risk medium --limit 20
.build/debug/Ln1 workflow preflight --operation control-active-app --element w0.1 --expect-identity accessibilityElement:abc123
.build/debug/Ln1 workflow preflight --operation set-element-value --element w0.4 --expect-identity accessibilityElement:abc123 --value "New title"
.build/debug/Ln1 workflow preflight --operation inspect-process --pid 123
.build/debug/Ln1 workflow preflight --operation find-element --title Save --action AXPress --include-menu --limit 20
.build/debug/Ln1 workflow preflight --operation inspect-element --pid 123 --element w0.3.1 --expect-identity accessibilityElement:abc123
.build/debug/Ln1 workflow preflight --operation wait-process --pid 123 --exists false --wait-timeout-ms 5000
.build/debug/Ln1 workflow preflight --operation wait-active-window --title "Export Complete" --match contains --wait-timeout-ms 30000
.build/debug/Ln1 workflow preflight --operation wait-window --title "Export Complete" --exists true --wait-timeout-ms 30000
.build/debug/Ln1 workflow preflight --operation wait-element --pid 123 --element w0.2 --title "Export Complete" --match contains --wait-timeout-ms 30000
.build/debug/Ln1 workflow preflight --operation wait-active-app --pid 123 --wait-timeout-ms 5000
.build/debug/Ln1 workflow preflight --operation minimize-active-window --allow-risk medium
.build/debug/Ln1 workflow preflight --operation restore-window --pid 123 --element w0 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation raise-window --pid 123 --element w0 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation close-window --pid 123 --element w0 --allow-risk high
.build/debug/Ln1 workflow preflight --operation set-window-frame --pid 123 --element w0 --x 40 --y 80 --width 960 --height 720 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation activate-app --pid 123 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation launch-app --bundle-id com.apple.TextEdit --allow-risk medium
.build/debug/Ln1 workflow preflight --operation hide-app --pid 123 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation unhide-app --pid 123 --allow-risk medium
.build/debug/Ln1 workflow preflight --operation quit-app --pid 123 --allow-risk high
.build/debug/Ln1 workflow preflight --operation open-file --path ~/Downloads/report.pdf --allow-risk medium
.build/debug/Ln1 workflow preflight --operation open-url --url https://example.com/report --allow-risk medium
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
.build/debug/Ln1 workflow preflight --operation read-clipboard --max-characters 4096
.build/debug/Ln1 workflow preflight --operation write-clipboard --text "ready to paste" --allow-risk medium
.build/debug/Ln1 workflow preflight --operation inspect-file --path ~/Desktop/a.txt
.build/debug/Ln1 workflow preflight --operation read-file --path ~/Desktop/a.txt --max-characters 4096
.build/debug/Ln1 workflow preflight --operation tail-file --path ~/Desktop/a.txt --max-characters 4096
.build/debug/Ln1 workflow preflight --operation read-file-lines --path ~/Desktop/a.txt --start-line 40 --line-count 20 --max-line-characters 240
.build/debug/Ln1 workflow preflight --operation read-file-json --path ~/Desktop/config.json --pointer /services/0 --max-depth 3 --max-items 20
.build/debug/Ln1 workflow preflight --operation read-file-plist --path ~/Library/Preferences/com.example.app.plist --pointer /RecentItems/0 --max-depth 3 --max-items 20
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

`workflow run --dry-run true` returns whether the workflow is ready, whether it would execute, the command that would be used, and the embedded preflight evidence. This mode is intentionally non-executing. Browser fill/click/navigation and workspace open workflows are mutating, so dry-run is the safe way to validate tab IDs, selectors, URLs, file paths, policy, and audit-log readiness before running the returned command directly.

Execution mode runs non-mutating workflows directly:

```sh
.build/debug/Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --dry-run false --run-timeout-ms 10000 --max-output-bytes 1048576
```

For non-mutating workflows, `workflow run --dry-run false` executes the next command and captures its exit code, stdout, stderr, byte counts, truncation flags, timeout status, and parsed JSON output when stdout is complete JSON.

Mutating workflow execution is opt-in and still goes through the underlying typed command policy and audit log:

```sh
.build/debug/Ln1 workflow run --operation create-directory --path ~/Desktop/Archive --allow-risk medium --dry-run false --execute-mutating true --reason "Prepare archive folder"
```

Use dry-run first for mutating browser actions, Accessibility value changes, app focus, launch, hide, unhide, quit, desktop window minimization/restoration/raising/closing/framing, workspace open handoffs, and file operations, then run with `--execute-mutating true` and a non-placeholder `--reason` once the command, target, policy, and audit path are correct. `control-active-app` and `set-element-value` target the frontmost app by default, or the app selected by `--pid`, `--bundle-id`, or `--current`. After a successful verified `write-file`, `append-file`, `create-directory`, `duplicate-file`, `move-file`, or `rollback-file-move` workflow, `workflow resume` suggests a `files stat` check for the verified destination or restored source so the next step is grounded in current metadata.

`activate-app` is a mutating workflow operation for bringing one regular GUI app forward by `--pid`, `--bundle-id`, or `--current`. Use `workflow run --operation activate-app --dry-run true` to inspect the exact `apps activate` command, then execute with `--dry-run false --execute-mutating true --reason TEXT` after confirming the target. After a successful activation, `workflow resume` suggests an active-app inspection dry-run.

`launch-app` is a mutating workflow operation for opening an installed `.app` by bundle identifier or app bundle path. It wraps `apps launch` with medium-risk approval, verifies that the app is running and, by default, frontmost, and records the launch target in the audit log. After a successful launch, `workflow resume` suggests an active-app inspection dry-run.

`hide-app` is a mutating workflow operation for moving one running regular GUI app out of view without closing it. It wraps `apps hide` with medium-risk approval, verifies the target becomes hidden within a bounded timeout, records policy and verification evidence in the audit log, and `workflow resume` suggests a running-app inspection dry-run.

`unhide-app` is a mutating workflow operation for making one running regular GUI app visible again without activating or launching it. It wraps `apps unhide` with medium-risk approval, verifies the target is no longer hidden within a bounded timeout, records policy and verification evidence in the audit log, and `workflow resume` suggests a running-app inspection dry-run.

`quit-app` is a high-risk mutating workflow operation for closing one running regular GUI app by PID, bundle identifier, or current target. It wraps `apps quit`, refuses to quit the current Ln1 process, verifies that the target process exits within a bounded timeout, records policy and verification evidence in the audit log, and `workflow resume` suggests a running-app inspection dry-run.

`open-file` and `open-url` are mutating workflow operations for handing one artifact to the macOS default workspace handler. They wrap `Ln1 open --path PATH` or `Ln1 open --url URL` with medium-risk approval, validate readable file metadata or URL shape before execution, include the default handler app when macOS reports one, record target metadata in the audit log, and `workflow resume` suggests active-window inspection after a successful handoff.

`inspect-frontmost-app` is a non-mutating workflow operation for the current frontmost app. It runs `apps active`, captures app name, bundle identifier, and PID without requiring Accessibility permission, and `workflow resume` suggests a dry-run process inspection for that PID.

`inspect-apps` is a non-mutating workflow operation for bounded running app inventory. It runs `apps list`, forwards `--all` and `--limit`, captures app names, bundle identifiers, PIDs, active and hidden flags, truncation, and the active app in the workflow transcript, and `workflow resume` suggests a dry-run active app or process inspection.

`inspect-installed-apps` is a non-mutating workflow operation for installed app bundle discovery. It wraps `apps installed`, captures app names, bundle identifiers, versions, executable paths, and bundle paths in the workflow transcript, and `workflow resume` can suggest a `launch-app` dry-run for the first discovered bundle identifier.

`set-element-value` is a mutating workflow operation for setting one Accessibility element's `AXValue`. It requires `--element` and `--value`, accepts the same stable identity guard as `perform`, wraps `set-value` with explicit medium-risk approval, and only executes through `workflow run --dry-run false --execute-mutating true --reason TEXT`. After `inspect-element` or `wait-element` finds a settable value element, `workflow resume` suggests a dry-run `set-element-value` plan. After a successful value update, `workflow resume` suggests a dry-run element inspection so the next action is grounded in current structured UI state.

`review-audit` is a non-mutating workflow operation for bounded audit-log review by exact audit ID, command, outcome code, and limit. It wraps `audit` so audit evidence can be captured in the workflow transcript. After reviewing a successful `files.move` audit record, `workflow resume` suggests a rollback-file-move preflight using that audit ID.

`inspect-menu` is a non-mutating workflow operation for one app menu bar by `--pid` or the current frontmost app. It runs `state menu`, captures bounded menu item roles, titles, actions, and stable identities in the workflow transcript, and `workflow resume` suggests a fresh app UI state inspection before choosing a trusted action.

`inspect-system` is a non-mutating workflow operation for host and runtime metadata. It runs `system context`, captures bounded OS, shell, working-directory, timezone, locale, memory, uptime, and processor evidence in the workflow transcript, and `workflow resume` suggests a fresh `observe` snapshot.

`inspect-displays` is a non-mutating workflow operation for display topology. It runs `desktop displays`, captures connected display IDs, coordinate bounds, pixel dimensions, scale, rotation, and display flags in the workflow transcript, and `workflow resume` suggests a fresh `observe` snapshot.

`inspect-active-window` is a non-mutating workflow operation for the current frontmost visible desktop window. It runs `desktop active-window`, captures WindowServer owner, title, bounds, layer, active-owner flag, and stable identity metadata without requiring screenshots or Accessibility permission, and `workflow resume` suggests a dry-run process inspection for the owning PID.

`inspect-windows` is a non-mutating workflow operation for visible desktop window inventory. It runs `desktop windows`, forwards window filters such as `--owner-pid`, `--bundle-id`, `--title`, and `--match`, captures WindowServer owner, title, bounds, layer, and stable identity metadata in the workflow transcript, and `workflow resume` suggests active-app or owner-process inspection when the inventory points to a concrete next target.

`inspect-processes` is a non-mutating workflow operation for bounded running process inventory. It runs `processes list`, forwards `--name` and `--limit`, captures process names, PIDs, executable paths, related app names, bundle identifiers, active-app flags, and current-process flags in the workflow transcript, and `workflow resume` suggests a dry-run `inspect-process` step for a concrete PID.

`start-task`, `record-task`, `finish-task`, and `show-task` are workflow operations for task-scoped memory. They wrap `task start`, `task record`, `task finish`, and `task show` with medium-risk policy checks, transcript capture, optional `--memory-log` isolation, and sensitive-summary redaction from the underlying task memory layer. After starting a task, `workflow resume` suggests a dry-run `record-task` step for the concrete task ID; after recording or finishing, it suggests a dry-run `show-task` read so the next step is grounded in persisted task context.

`inspect-process` is a non-mutating workflow operation for one process by `--pid` or `--current`. It runs `processes inspect`, captures structured process metadata in the workflow transcript, and `workflow resume` can suggest a dry-run app activation when the inspected process belongs to a GUI app.

`find-element` is a non-mutating workflow operation for bounded Accessibility element discovery. It runs `state find`, forwards semantic filters such as `--role`, `--title`, `--value`, `--action`, and `--enabled`, captures matching candidate IDs and stable identities in the transcript, and `workflow resume` suggests a dry-run `inspect-element` step for the first candidate.

`inspect-element` is a non-mutating workflow operation for one Accessibility element by path. It runs `state element`, captures the bounded element subtree plus stable identity verification in the workflow transcript, and `workflow resume` suggests a guarded `perform` press when the inspected element is enabled and pressable, a guarded `set-element-value` dry-run when `AXValue` is settable, or a bounded element re-inspection.

`wait-process` is a non-mutating workflow operation for bounded PID existence waiting. It runs `processes wait`, captures structured verification in the workflow transcript, and `workflow resume` suggests process inspection when the PID is confirmed present or a fresh process list when it is confirmed absent.

`wait-active-window` is a non-mutating workflow operation for frontmost window verification. It runs `desktop wait-active-window`, can match by transient window ID, stable identity ID, owner PID, bundle identifier, title, or `--changed-from`, captures the current frontmost window evidence in the transcript, and `workflow resume` suggests owner process inspection when the wait matches.

`wait-window` is a non-mutating workflow operation for bounded desktop window existence waiting. It runs `desktop wait-window`, captures target filters and matching WindowServer metadata in the workflow transcript, and `workflow resume` suggests owner-process or active-app inspection when a window appears, or a fresh desktop window list when a match disappears.

`wait-element` is a non-mutating workflow operation for bounded Accessibility element existence and readiness waiting. It runs `state wait-element`, captures current element identity, title/value/enabled matching, and identity verification in the workflow transcript, and `workflow resume` suggests a guarded `perform` press when the matched element is enabled and pressable, a guarded `set-element-value` dry-run when `AXValue` is settable, or a fresh state inspection.

`wait-active-app` is a non-mutating workflow operation for bounded app focus verification. It runs `apps wait-active`, captures target/current frontmost app evidence, and `workflow resume` suggests active-app inspection when the target becomes frontmost.

`minimize-active-window` is a mutating workflow operation for clearing the current frontmost window without relying on menu clicks. It wraps `desktop minimize-active-window` with medium-risk approval, requires Accessibility trust and a visible active desktop window, verifies the frontmost Accessibility window reports `AXMinimized`, records policy and verification evidence in the audit log, and `workflow resume` suggests a fresh desktop window inventory dry-run.

`restore-window` is a mutating workflow operation for restoring one target app Accessibility window by element ID. It wraps `desktop restore-window` with medium-risk approval, requires Accessibility trust, validates that the target element is an `AXWindow` with settable `AXMinimized`, verifies the window reports `AXMinimized == false`, records policy and verification evidence in the audit log, and `workflow resume` suggests a fresh desktop window inventory dry-run.

`raise-window` is a mutating workflow operation for bringing one target app Accessibility window forward by element ID. It wraps `desktop raise-window` with medium-risk approval, requires Accessibility trust, validates that the target element is an `AXWindow` exposing `AXRaise`, verifies the target app is frontmost with that window focused, records policy and verification evidence in the audit log, and `workflow resume` suggests a fresh active-window inspection dry-run.

`close-window` is a mutating workflow operation for closing one target app Accessibility window by element ID. It wraps `desktop close-window` with high-risk approval, requires Accessibility trust, validates that the target element is an `AXWindow` exposing `AXClose`, verifies the target window is absent from the app's Accessibility window list, records policy and verification evidence in the audit log, and `workflow resume` suggests a fresh desktop window inventory dry-run.

`set-window-frame` is a mutating workflow operation for moving and resizing one target app Accessibility window by element ID. It wraps `desktop set-window-frame` with medium-risk approval, requires Accessibility trust, validates that the target element is an `AXWindow` with settable `AXPosition` and `AXSize`, verifies the resulting frame within a bounded timeout, records policy and verification evidence in the audit log, and `workflow resume` suggests a fresh desktop window inventory dry-run.

`wait-file` is a non-mutating workflow operation for bounded state waiting. The workflow runner's `--run-timeout-ms` can be shorter than the underlying `--wait-timeout-ms` when the outer control loop needs a hard deadline. Pass `--size-bytes N` and/or `--digest SHA256` when the file must exist with specific metadata before the workflow should continue.

`watch-file` is a non-mutating workflow operation for bounded filesystem event waiting. The workflow runner's `--run-timeout-ms` can be shorter than the underlying `--watch-timeout-ms` when the outer control loop needs a hard deadline. After a successful watch, `workflow resume` suggests a metadata or directory-list command for the first observed event.

`checksum-file` is a non-mutating workflow operation for bounded SHA-256 file verification. It validates that the target is a readable regular file within `--max-file-bytes`, then runs `files checksum` without exposing file contents. After a successful checksum, `workflow resume` suggests a digest-based `wait-file` dry-run so the next step can verify the file has not changed.

`compare-files` is a non-mutating workflow operation for bounded file equivalence checks. It validates both paths as readable regular files within `--max-file-bytes`, then runs `files compare` to report size and digest equality without exposing file contents. After a completed compare, `workflow resume` suggests a metadata inspection of the right-side file.

`inspect-file` is a non-mutating workflow operation for current filesystem metadata. It wraps `files stat` in workflow preflight/run logging, then `workflow resume` suggests either listing a directory or dry-running a checksum workflow for a readable regular file.

`read-file` is a medium-risk non-mutating workflow operation for bounded UTF-8 file text. It validates a readable regular file within `--max-file-bytes`, runs `files read-text` with explicit medium-risk approval, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`tail-file` is a medium-risk non-mutating workflow operation for bounded UTF-8 file tail text. It validates a readable regular file within `--max-file-bytes`, runs `files tail-text` with explicit medium-risk approval, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`read-file-lines` is a medium-risk non-mutating workflow operation for bounded, numbered UTF-8 file line ranges. It validates a readable regular file within `--max-file-bytes`, runs `files read-lines` with explicit medium-risk approval and `--start-line`, `--line-count`, and `--max-line-characters` bounds, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`read-file-json` is a medium-risk non-mutating workflow operation for bounded typed JSON reads. It validates a readable regular file within `--max-file-bytes`, runs `files read-json` with explicit medium-risk approval and optional `--pointer`, `--max-depth`, `--max-items`, and `--max-string-characters` bounds, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`read-file-plist` is a medium-risk non-mutating workflow operation for bounded typed property list reads. It validates a readable regular file within `--max-file-bytes`, runs `files read-plist` with explicit medium-risk approval and optional `--pointer`, `--max-depth`, `--max-items`, and `--max-string-characters` bounds, and `workflow resume` suggests a checksum dry-run so subsequent steps can verify the file has not changed.

`write-file` is a medium-risk mutating workflow operation for UTF-8 file text writes. It validates the destination parent directory, requires `--text`, refuses to replace existing files unless `--overwrite` is passed, runs `files write-text` with explicit medium-risk approval and a non-placeholder reason, and `workflow resume` suggests inspecting the written file metadata after verification.

`append-file` is a medium-risk mutating workflow operation for UTF-8 file text appends. It validates the existing writable regular file, requires `--text`, refuses missing paths unless `--create` is passed, runs `files append-text` with explicit medium-risk approval and a non-placeholder reason, and `workflow resume` suggests inspecting the appended file metadata after verification.

`list-files` is a non-mutating workflow operation for bounded directory inventories. It validates that the path is a readable directory, forwards `--depth`, `--limit`, and `--include-hidden`, and `workflow resume` suggests a dry-run `inspect-file` workflow for the first listed path or the empty directory itself.

`search-files` is a non-mutating workflow operation for bounded filename and content search. It validates a readable root and non-empty `--query`, forwards the same search bounds as `files search`, and `workflow resume` suggests a dry-run `inspect-file` workflow for the first matched file or the search root.

`inspect-clipboard` is a non-mutating workflow operation for clipboard metadata snapshots. It wraps `clipboard state` without returning clipboard text, and `workflow resume` suggests either a dry-run `read-clipboard` workflow after explicit medium-risk approval or a metadata wait for future plain text.

`read-clipboard` is a medium-risk non-mutating workflow operation for bounded clipboard text. It wraps `clipboard read-text` with explicit medium-risk approval, optional `--pasteboard`, `--max-characters`, and `--audit-log`, and `workflow resume` suggests a clipboard metadata check so later steps can verify the pasteboard did not change unexpectedly.

`write-clipboard` is a medium-risk mutating workflow operation for plain text pasteboard writes. It requires `--text`, wraps `clipboard write-text` with explicit medium-risk approval, optional `--pasteboard` and `--audit-log`, and only executes through `workflow run --dry-run false --execute-mutating true --reason TEXT`.

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

After a successful `wait-element` transcript, `workflow resume` suggests a guarded `perform` press when the matched Accessibility element is enabled and pressable, a guarded `set-element-value` dry-run when `AXValue` is settable, or a fresh bounded `state` inspection.

After a successful `inspect-element` transcript, `workflow resume` suggests a guarded `perform` press when the inspected Accessibility element is enabled and pressable, a guarded `set-element-value` dry-run when `AXValue` is settable, or a bounded element re-inspection.

After a successful `inspect-menu` transcript, `workflow resume` suggests a fresh bounded app UI state inspection so the next trusted action is grounded in current window state.

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

`workflow resume` reports whether the latest matching workflow is `completed`, `blocked`, `timed_out`, `failed`, `ready`, or `empty`, and returns a conservative next command or argument array. For completed app activation or launch workflows, it suggests a dry-run active-app inspection; for completed app hide, unhide, or quit workflows, it suggests running-app inspection. For completed browser tab listings, it can suggest a dry-run DOM inspection for the first tab; for completed DOM inspections, it can suggest fill, select, check, or click commands from the first actionable selector.

## Inspect Running Apps

```sh
.build/debug/Ln1 apps
```

To inspect just the frontmost app without Accessibility permission:

```sh
.build/debug/Ln1 apps active
```

For workflow capture or bounded app inventories, use the object-shaped list mode:

```sh
.build/debug/Ln1 apps list --limit 20
```

If you are running from a non-interactive shell and want every process macOS exposes:

```sh
.build/debug/Ln1 apps --all
```

Discover installed app bundle identifiers and app bundle paths before launch planning:

```sh
.build/debug/Ln1 apps installed --name TextEdit --limit 20
.build/debug/Ln1 apps installed --bundle-id com.apple.TextEdit
```

`apps.installed` is a low-risk non-mutating inventory of app bundle metadata from standard macOS application locations. It returns app names, bundle identifiers, bundle paths, versions, and executable paths so a caller can choose `apps plan --operation launch` without guessing bundle IDs.

To preview a focus change or app launch without mutating the desktop:

```sh
.build/debug/Ln1 apps plan --operation activate --pid 123 --allow-risk medium
.build/debug/Ln1 apps plan --operation launch --bundle-id com.apple.TextEdit --activate false --allow-risk medium
.build/debug/Ln1 apps plan --operation hide --pid 123 --allow-risk medium
.build/debug/Ln1 apps plan --operation unhide --pid 123 --allow-risk medium
.build/debug/Ln1 apps plan --operation quit --pid 123 --allow-risk high
```

`apps plan` returns the target app or app bundle, current active app, preflight checks, policy decision, and whether the action can execute. This gives an assistant a structured, explainable way to decide whether a focus, visibility, launch, or quit action is safe before acting.

To bring one regular GUI app forward:

```sh
.build/debug/Ln1 apps activate --pid 123 --allow-risk medium --reason "Inspect the target app"
```

`apps.activate` is a medium-risk mutating app action because it changes the active app and can affect subsequent keyboard input. It accepts `--pid`, `--bundle-id`, or `--current`, verifies the requested app becomes frontmost, and writes an audit record with the target app, policy decision, verification result, and outcome.

Launch an installed GUI app by bundle identifier or `.app` path:

```sh
.build/debug/Ln1 apps launch --bundle-id com.apple.TextEdit --allow-risk medium --reason "Open editor"
.build/debug/Ln1 apps launch --path /Applications/TextEdit.app --activate false --allow-risk medium --reason "Start editor in background"
```

`apps.launch` is a medium-risk mutating app action. `--activate` defaults to `true`; when activation is requested, Ln1 verifies the launched app is also frontmost. Each launch audit records the requested bundle/path target, policy decision, verification result, and outcome.

Hide one running regular GUI app without closing it:

```sh
.build/debug/Ln1 apps hide --pid 123 --allow-risk medium --reason "Clear the desktop"
.build/debug/Ln1 apps hide --bundle-id com.example.App --timeout-ms 2000 --allow-risk medium --reason "Move completed app out of view"
```

`apps.hide` is a medium-risk mutating app action because it changes visible desktop state and can affect subsequent observations. It accepts `--pid`, `--bundle-id`, or `--current`, requires a regular GUI app target, verifies that the target becomes hidden, and writes an audit record with policy, target, verification, and outcome metadata.

Make one running regular GUI app visible again:

```sh
.build/debug/Ln1 apps unhide --pid 123 --allow-risk medium --reason "Show target app"
.build/debug/Ln1 apps unhide --bundle-id com.example.App --timeout-ms 2000 --allow-risk medium --reason "Restore app visibility"
```

`apps.unhide` is a medium-risk mutating app action because it changes visible desktop state and can affect subsequent observations. It accepts `--pid`, `--bundle-id`, or `--current`, requires a regular GUI app target, verifies that the target is no longer hidden, and writes an audit record with policy, target, verification, and outcome metadata.

Ask one regular GUI app to quit and verify the process exits:

```sh
.build/debug/Ln1 apps quit --pid 123 --allow-risk high --reason "Close completed app"
.build/debug/Ln1 apps quit --bundle-id com.example.App --force --allow-risk high --reason "Force close unresponsive app"
```

`apps.quit` is a high-risk mutating app action because it can close unsaved work. It accepts `--pid`, `--bundle-id`, or `--current`, refuses to terminate the current Ln1 process, requires a regular GUI app target, sends a normal terminate request unless `--force` is present, waits for the process to exit, and writes an audit record with policy, target, verification, and outcome metadata.

Open one file path or URL with the macOS default handler:

```sh
.build/debug/Ln1 open --path ~/Downloads/report.pdf --allow-risk medium --reason "Review downloaded report"
.build/debug/Ln1 open --url https://example.com/report --allow-risk medium --reason "Open report link"
.build/debug/Ln1 open --path ~/Downloads/report.pdf --plan --allow-risk medium
```

`workspace.open` is a medium-risk mutating workspace action because it can launch or focus another app. `--path` validates that the target file or directory exists and is readable before handoff; `--url` validates an absolute URL and records scheme/host metadata. `--plan` returns the target, policy decision, current active app, and default handler app when LaunchServices reports one without opening the target. Execution records the target and handler metadata, policy decision, macOS open-request verification, audit ID, and active app before and after the handoff.

Wait for one app to become frontmost without changing focus:

```sh
.build/debug/Ln1 apps wait-active --pid 123 --timeout-ms 5000
```

`apps.waitActive` is a low-risk non-mutating app action. It polls the structured frontmost app record until it matches the target PID or bundle identifier, returning target/current app metadata and a verification code instead of relying on fixed sleeps or screenshots.

## Inspect Running Processes

```sh
.build/debug/Ln1 processes --limit 50
```

`processes.list` returns bounded process metadata from macOS process APIs: PID, process name, executable path when available, related app name, bundle identifier, whether the process owns the frontmost app, and whether it is the current Ln1 process. It intentionally does not read command-line arguments.

Filter by process name, app name, or bundle identifier:

```sh
.build/debug/Ln1 processes list --name Safari --limit 20
```

Inspect one process without listing the whole table:

```sh
.build/debug/Ln1 processes inspect --pid 123
.build/debug/Ln1 processes inspect --current
```

Wait for a process to exist or disappear:

```sh
.build/debug/Ln1 processes wait --pid 123 --exists false --timeout-ms 5000
```

`processes.wait` returns a structured verification result with the expected existence state, whether it matched before the timeout, and current process metadata when the PID is still visible.

## Inspect Displays

```sh
.build/debug/Ln1 desktop displays
.build/debug/Ln1 desktop screenshot --allow-risk medium --max-sample-bytes 1048576
```

`desktop.listDisplays` returns connected display metadata from CoreGraphics and AppKit: display ID, user-facing name when available, main/active/online/built-in flags, mirror-set state, coordinate bounds, pixel dimensions, backing scale, rotation, and color space name. This is a low-risk desktop inspection action that does not require screenshots or Accessibility access.

`desktop.screenshot` is a medium-risk visual fallback read because it can inspect visible screen pixels. It returns display image availability, dimensions, byte counts, and a SHA-256 digest over a bounded byte sample instead of dumping raw pixels. If macOS blocks capture, the command returns structured display metadata with `captured: false` so the caller can report that Screen Recording permission is needed.

## Inspect Visible Desktop Windows

```sh
.build/debug/Ln1 desktop active-window
.build/debug/Ln1 desktop minimize-active-window --allow-risk medium --reason "Clear active window"
.build/debug/Ln1 desktop restore-window --pid 123 --element w0 --allow-risk medium --reason "Restore window"
.build/debug/Ln1 desktop raise-window --pid 123 --element w0 --allow-risk medium --reason "Raise window"
.build/debug/Ln1 desktop close-window --pid 123 --element w0 --allow-risk high --reason "Close reviewed window"
.build/debug/Ln1 desktop set-window-frame --pid 123 --element w0 --x 40 --y 80 --width 960 --height 720 --allow-risk medium --reason "Arrange window"
.build/debug/Ln1 desktop windows --limit 50
.build/debug/Ln1 desktop windows --bundle-id com.apple.TextEdit --limit 20
.build/debug/Ln1 desktop windows --title "Export" --match contains --limit 20
```

The output is structured JSON from macOS window metadata: availability, window ID, owner app name and PID, bundle identifier when available, active-owner flag, title when macOS exposes it, layer, bounds, onscreen state, alpha, memory usage, and sharing state. `desktop active-window` returns only the frontmost visible normal-layer window plus current frontmost app metadata; `desktop windows` returns a bounded inventory. These are low-risk desktop inspection actions that do not require screenshots or Accessibility access. If the current process cannot read WindowServer metadata, the command still returns a structured unavailable result instead of falling back to screenshots.

Filter desktop window inventory by transient window ID, stable identity ID, owner PID, bundle identifier, or title with `--match exact|prefix|contains`. The result includes the applied structured `filter` so later workflow steps can verify which target constraints produced the inventory.

Each window includes both a transient WindowServer `id` and a semantic `stableIdentity`. The stable identity is a digest built from durable-ish fields such as owner bundle identifier, title, layer, and coarse bounds when the title is unavailable. It also reports a confidence level, user-readable label, identity components, and reasons so callers can avoid acting when a repeated observation only matches a low-confidence window reference.

By default `desktop windows` reports visible non-desktop, normal-layer windows. Include desktop elements or menu/overlay layers when they are relevant:

```sh
.build/debug/Ln1 desktop windows --include-desktop --all-layers
```

Wait for a desktop window to appear or disappear without relying on a fixed sleep:

```sh
.build/debug/Ln1 desktop wait-active-window --title "Export Complete" --match contains --timeout-ms 30000
.build/debug/Ln1 desktop wait-active-window --changed-from desktopWindow:STABLE_ID --timeout-ms 5000
.build/debug/Ln1 desktop wait-window --bundle-id com.apple.TextEdit --exists true --timeout-ms 5000
.build/debug/Ln1 desktop wait-window --title "Export Complete" --match contains --exists true --timeout-ms 30000
.build/debug/Ln1 desktop wait-window --id desktopWindow:STABLE_ID --exists false --timeout-ms 5000
```

`desktop.waitActiveWindow` polls the same frontmost normal-layer WindowServer metadata as `desktop active-window` and returns structured verification: target filters, whether the current frontmost window was found, whether it changed from a previous transient or stable ID, the current window record, and a matched/timeout code. It can match by transient window ID, semantic `stableIdentity.id`, owner PID, bundle identifier, or title.

`desktop.waitWindow` polls the same WindowServer metadata as `desktop windows` and returns structured verification: the target filters, expected existence state, current matching windows, match count, and a timeout or matched code. It can match by transient window `id`, semantic `stableIdentity.id`, owner PID, bundle identifier, or title with `--match exact|prefix|contains`.

`desktop.minimizeActiveWindow` is a medium-risk mutating desktop action because it changes visible window state and can affect subsequent observations. It targets the frontmost app's focused Accessibility window, can guard against stale targets with `--expect-identity` and `--min-identity-confidence`, sets `AXMinimized`, verifies that `AXMinimized` becomes true within a bounded timeout, and writes an audit record with app, window, policy, identity, verification, and outcome metadata.

`desktop.restoreWindow` is the inverse medium-risk mutating desktop action. It targets one Accessibility window from `Ln1 state` using `--pid`, `--bundle-id`, or `--current` plus `--element wN`, can guard against stale targets with `--expect-identity` and `--min-identity-confidence`, sets `AXMinimized` to false, verifies the restored state within a bounded timeout, and writes app/window/policy/identity/verification metadata to the audit log.

`desktop.raiseWindow` is a medium-risk mutating desktop action for target-specific focus changes. It targets one Accessibility window from `Ln1 state` using `--pid`, `--bundle-id`, or `--current` plus `--element wN`, can guard against stale targets with `--expect-identity` and `--min-identity-confidence`, performs `AXRaise`, verifies the target app is frontmost with that window focused, and writes app/window/policy/identity/verification metadata to the audit log.

`desktop.closeWindow` is a high-risk mutating desktop action for target-specific window closure. It targets one Accessibility window from `Ln1 state` using `--pid`, `--bundle-id`, or `--current` plus `--element wN`, can guard against stale targets with `--expect-identity` and `--min-identity-confidence`, performs `AXClose`, verifies that the target window is absent from the app's Accessibility window list, and writes app/window/policy/identity/verification metadata to the audit log.

`desktop.setWindowFrame` is a medium-risk mutating desktop action for target-specific window arrangement. It targets one Accessibility window from `Ln1 state` using `--pid`, `--bundle-id`, or `--current` plus `--element wN`, requires finite `--x`, `--y`, `--width`, and `--height` values, can guard against stale targets with `--expect-identity` and `--min-identity-confidence`, sets `AXPosition` and `AXSize`, verifies the resulting frame, and writes app/window/policy/identity/verification metadata to the audit log.

## Global Pointer Input

```sh
.build/debug/Ln1 input pointer
.build/debug/Ln1 input move --x 200 --y 160 --allow-risk medium --dry-run true
.build/debug/Ln1 input drag --from-x 200 --from-y 160 --to-x 420 --to-y 160 --allow-risk medium --dry-run true
.build/debug/Ln1 input scroll --dy -600 --allow-risk medium --dry-run true
.build/debug/Ln1 input key --key k --modifiers command,shift --allow-risk medium --dry-run true
.build/debug/Ln1 input type --text "hello" --allow-risk medium --dry-run true
```

`input.pointer` is a low-risk read of the current global pointer coordinates. `input.movePointer`, `input.dragPointer`, `input.scrollWheel`, `input.pressKey`, and `input.typeText` are medium-risk mutating input actions outside Accessibility and browser-specific control paths. They validate finite coordinates, bounded scroll deltas, supported key names, or non-empty text; support dry-run planning; write audit records; and avoid storing typed text contents in command output or audit logs.

## Emit Structured State

```sh
.build/debug/Ln1 state --depth 4 --max-children 120
```

The output is JSON with app metadata, windows, elements, frames, values, available actions, settable Accessibility attributes, `minimized` state when an element exposes `AXMinimized`, and a `valueSettable` shortcut.

Each Accessibility node includes the path-style `id` used by `perform` plus a semantic `stableIdentity`. The stable identity summarizes owner, role, title or help text, actions, and coarse frame when available, then reports a digest, confidence, readable label, components, and reasons. Use the confidence, reasons, `actions`, and `settableAttributes` to decide whether a repeated observation still refers to the same control and whether it supports press-style or value-setting operations before acting. When `--expect-identity` is supplied, guarded element commands re-resolve a stale child-index path by scanning the current bounded UI tree and fail closed unless exactly one element matches that stable identity.

Inspect one known Accessibility element path without walking the full app tree:

```sh
.build/debug/Ln1 state element --pid 123 --element w0.3.1 --expect-identity accessibilityElement:abc123 --min-identity-confidence medium --depth 1 --max-children 20
```

`accessibility.inspectElement` is a low-risk non-mutating read that requires Accessibility trust. It resolves the same path IDs returned by `state`, recomputes the element `stableIdentity`, optionally verifies the expected identity and confidence, and returns a bounded subtree rooted at that element.

Wait for an Accessibility element path to appear or reach a structured state:

```sh
.build/debug/Ln1 state wait-element --pid 123 --element w0.3.1 --expect-identity accessibilityElement:abc123 --min-identity-confidence medium --enabled true --timeout-ms 5000
.build/debug/Ln1 state wait-element --pid 123 --element w0.2 --title "Export Complete" --match contains --exists true --timeout-ms 30000
```

`accessibility.waitElement` is a low-risk non-mutating wait that requires Accessibility trust. It resolves the same path IDs returned by `state`, recomputes the element `stableIdentity`, and polls title, value, enabled state, and identity confidence until the criteria match or the timeout expires.

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

Use an element ID from `state`, `state element`, or `state menu`:

```sh
.build/debug/Ln1 perform --element w0.3.1 --action AXPress --reason "Open the details panel"
.build/debug/Ln1 perform --element m0.1 --action AXShowMenu --reason "Open the File menu"
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
.build/debug/Ln1 perform --pid 456 --element a0.m0.1 --action AXShowMenu --reason "Open the File menu"
```

To target a specific app:

```sh
.build/debug/Ln1 state --pid 123
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open the details panel"
.build/debug/Ln1 state menu --pid 123
.build/debug/Ln1 perform --pid 123 --element m0.1 --action AXShowMenu --reason "Open the File menu"
```

To guard against a stale element path, pass the `stableIdentity.id` from a recent `state` observation and a minimum identity confidence:

```sh
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --expect-identity accessibilityElement:abc123 --min-identity-confidence medium --action AXPress --reason "Open the details panel"
```

When identity constraints are present, `perform` recomputes the target element identity after resolving the path and before invoking the Accessibility action. It refuses to act if the identity digest does not match or if the current confidence is below `low`, `medium`, or `high` as requested.

Every `perform` attempt appends a structured JSONL audit record before returning success or failure. The action result includes the audit record ID and log path, plus the resolved target element ID, stable identity, and identity verification result when available.

## Set An Accessibility Value

Use `set-value` for controls that report `AXValue` in their `settableAttributes`:

```sh
.build/debug/Ln1 set-value --pid 123 --element w0.4 --expect-identity accessibilityElement:abc123 --min-identity-confidence medium --value "New title" --allow-risk medium --reason "Rename selected item"
```

`set-value` is a medium-risk mutating Accessibility action. It checks policy before touching Accessibility APIs, resolves the target element, verifies any supplied stable identity guard, re-resolves stale guarded paths only on a single current identity match, refuses elements that do not expose settable `AXValue`, sets the value, then verifies the current value by length and SHA-256 digest. The result and audit record include value lengths and digests, but not the value text.

By default the audit log is stored at:

```text
~/Library/Application Support/Ln1/audit-log.jsonl
```

Use `--audit-log` to send records to another file during tests or isolated runs:

```sh
.build/debug/Ln1 perform --pid 123 --element w0.3.1 --action AXPress --reason "Open details" --audit-log /tmp/Ln1-audit.jsonl
```

The audit entry records typed intent and outcome: timestamp, risk level, target app, element ID, stable identity, available element actions, settable attribute names, requested action, optional reason, optional identity verification, and result. It intentionally stores only a small element summary and does not store element values.

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
.build/debug/Ln1 audit --command apps.launch --code launched --limit 10
.build/debug/Ln1 audit --id 5B3D2E12-1D75-4C9E-B6DA-FD1F3C9E6A57
```

`--id` matches an exact audit record ID. `--command` matches audit command names such as `perform`, `set-value`, `apps.activate`, `files.read-text`, `files.tail-text`, `files.read-lines`, `files.read-json`, `files.read-plist`, `files.write-text`, `files.append-text`, `files.duplicate`, `files.move`, `files.mkdir`, `files.rollback`, `files.rollback-text`, `clipboard.read-text`, `clipboard.write-text`, `browser.text`, or `browser.dom`. `--code` matches the outcome code, such as `policy_denied`, `set_value`, `activated`, `read_text`, `tail_text`, `read_lines`, `read_json`, `json_pointer_missing`, `read_plist`, `plist_pointer_missing`, `created_text_file`, `appended_text_file`, `duplicated`, `moved`, `created_directory`, `rolled_back_move`, `rolled_back_text_write`, `read_clipboard_text`, `wrote_clipboard_text`, or `read_dom`.

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

The filesystem adapter returns stable-ish file identity, absolute path, kind, size, timestamps, hidden/readable/writable flags, and available typed actions such as `filesystem.stat`, `filesystem.list`, `filesystem.search`, `filesystem.watch`, `filesystem.plan`, `filesystem.readText`, `filesystem.tailText`, `filesystem.readLines`, `filesystem.readJSON`, `filesystem.readPropertyList`, `filesystem.writeText`, `filesystem.appendText`, `filesystem.duplicate`, `filesystem.move`, `filesystem.createDirectory`, `filesystem.rollbackMove`, and `filesystem.rollbackTextWrite`. Search only exposes bounded matching snippets, not full file contents.

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

Read a bounded typed tree from a macOS property list:

```sh
.build/debug/Ln1 files read-plist --path ~/Library/Preferences/com.example.app.plist --pointer /RecentItems/0 --max-depth 3 --max-items 20 --allow-risk medium --reason "Inspect selected preference value"
```

`filesystem.readPropertyList` is a medium-risk non-mutating read for XML, binary, or OpenStep property lists. It refuses directories and files above `--max-file-bytes`, returns typed dictionary/array/scalar nodes capped by `--max-depth`, `--max-items`, and `--max-string-characters`, reports data blobs by byte count and digest, and writes an audit record containing only file metadata and outcome details, not property list values.

Create one UTF-8 text file through policy, audit, and verification:

```sh
.build/debug/Ln1 files write-text --path ~/Documents/agent-note.txt --text "Prepared by Ln1" --allow-risk medium --rollback-snapshot /tmp/ln1-file-rollback.json --reason "Create a structured note"
```

`filesystem.writeText` is a medium-risk mutating action. It creates missing files by default, refuses to replace existing files unless `--overwrite` is passed, requires a writable parent directory, verifies the written file by byte length and SHA-256 digest, and audits only file metadata, policy, rollback snapshot path, and verification details. Pass `--rollback-snapshot PATH` when the write must be reversible; this writes the previous UTF-8 text or missing-file state to a local 0600 snapshot file without storing file text in the audit log.

Append UTF-8 text without replacing the existing file:

```sh
.build/debug/Ln1 files append-text --path ~/Documents/agent-note.txt --text "\nNext step recorded by Ln1" --allow-risk medium --rollback-snapshot /tmp/ln1-file-append-rollback.json --reason "Record agent progress"
```

`filesystem.appendText` is a medium-risk mutating action. It appends to an existing writable regular file, refuses missing paths unless `--create` is passed, verifies the final byte length and tail bytes, and audits only file metadata, policy, rollback snapshot path, appended text length/digest, verification details, and outcome. Pass `--rollback-snapshot PATH` to capture the previous UTF-8 text or missing-file state before appending.

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

Rollback a successful audited text write or append:

```sh
.build/debug/Ln1 files rollback-text --audit-id AUDIT_ID --allow-risk medium --reason "Undo mistaken text write"
```

`filesystem.rollbackTextWrite` is a medium-risk mutating file action. It only supports successful audited `files.write-text` or `files.append-text` records that include a rollback snapshot, verifies that the current file still matches the audited write result, restores the previous UTF-8 text or removes the newly created file, and records rollback metadata without storing file text in the audit log.

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

`clipboard.wait` is a low-risk read action. It polls pasteboard metadata until the change count differs from `--changed-from`, the plain-text availability matches `--has-string`, and/or the text digest matches `--string-digest`; it returns only metadata, lengths, and digests. After a successful `wait-clipboard` workflow, `workflow resume` suggests either a dry-run `read-clipboard` workflow when plain text is available or another metadata-only state check when it is not.

Read bounded plain text from the clipboard only after explicitly allowing medium-risk clipboard access:

```sh
.build/debug/Ln1 clipboard read-text --allow-risk medium --max-characters 4096 --reason "Use copied confirmation code"
```

`clipboard.readText` is a medium-risk read action because clipboard text may contain private transient data. The command writes an audit record containing pasteboard metadata, text length, digest, policy decision, reason, and outcome, but the audit record does not store the clipboard text itself. Use `--pasteboard NAME` to target a named pasteboard for tests or isolated workflows.

Write plain text to the clipboard only after explicitly allowing medium-risk clipboard mutation:

```sh
.build/debug/Ln1 clipboard write-text --text "ready to paste" --allow-risk medium --rollback-snapshot /tmp/ln1-clipboard-rollback.json --reason "Prepare value for the next app"
.build/debug/Ln1 clipboard rollback --audit-id AUDIT_ID --allow-risk medium --reason "Undo clipboard write"
```

`clipboard.writeText` is a medium-risk mutating action because it replaces the current plain-text pasteboard contents. The command records before/after pasteboard metadata, text lengths, digests, policy decision, verification result, reason, and outcome without storing either the previous or new clipboard text in the audit log. The command verifies the write by checking that the clipboard contains text with the requested length and SHA-256 digest. Pass `--rollback-snapshot PATH` when the write must be reversible; this writes the previous plain text to a local 0600 snapshot file and records only that snapshot path in the audit log.

`clipboard.rollbackText` is a medium-risk mutating action for compensating clipboard writes. It only supports successful audited `clipboard.write-text` records that include a rollback snapshot, verifies that the current clipboard still matches the audited write result, restores the previous plain-text state from the snapshot, and records rollback metadata without storing clipboard text in the audit log.

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

Capture browser page image metadata through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser screenshot --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --format png --reason "Inspect canvas state"
```

`browser.captureScreenshot` is a medium-risk read action because page pixels can expose private web-app content. The command captures a screenshot through Chrome DevTools and returns only metadata: format, byte count, SHA-256 digest, and image dimensions when decodable. The audit record stores tab metadata plus screenshot format, byte count, digest, policy decision, reason, and outcome; it does not store image bytes.

Sample browser console and log metadata through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser console --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-entries 100 --sample-ms 1000 --reason "Inspect page console state"
```

`browser.readConsole` is a medium-risk read action because console messages can expose private web-app state. The command enables the Runtime and Log DevTools domains for a bounded sampling window and returns bounded console/log entries with source, level, message text, text length/digest, URL and line metadata when available. The audit record stores only tab metadata plus entry count and digest; it does not store message text.

Sample JavaScript dialog-opening metadata through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser dialogs --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-entries 20 --sample-ms 1000 --reason "Inspect page dialog state"
```

`browser.readDialogs` is a medium-risk read action because alert, confirm, and prompt messages can expose private web-app state. The command enables the Page DevTools domain for a bounded sampling window and returns bounded dialog-opening entries with type, message metadata, URL, frame ID, handler state, and prompt-default length/digest when available. The audit record stores only tab metadata plus entry count and digest; it does not store prompt defaults.

Read bounded browser network timing metadata through the tab's DevTools WebSocket:

```sh
.build/debug/Ln1 browser network --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-entries 100 --reason "Inspect page network activity"
```

`browser.readNetwork` is a medium-risk read action because request URLs can expose private web-app state. The command reads navigation and resource timing entries through the Performance API and returns bounded metadata including URL, entry type, initiator type, timing, transfer sizes, protocol, response status when available, and URL scheme/host. The audit record stores only tab metadata plus entry count and digest; it does not store request URLs.

Read bounded structured page state from the DOM:

```sh
.build/debug/Ln1 browser dom --endpoint http://127.0.0.1:9222 --id TARGET_ID --allow-risk medium --max-elements 200 --max-text-characters 120 --reason "Inspect page controls before acting"
```

`browser.readDOM` is also a medium-risk read action because labels, links, visible text, and form metadata can expose private web-app state. The result includes bounded DOM elements with IDs, parent IDs, depth, actionable CSS selectors, context metadata for the top document, open shadow roots, and same-origin iframes, tag names, inferred roles, bounded text snippets, selected safe attributes, ARIA state attributes such as `aria-expanded` and `aria-selected`, links, and form metadata such as input type, checked/disabled state, and value length. Cross-origin frames are represented by their iframe element and marked inaccessible instead of being silently traversed. It intentionally does not return form values and suppresses value metadata for password and hidden inputs. The audit record stores only tab metadata, DOM element count, DOM digest, policy decision, reason, and outcome; it does not store the DOM payload.

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

This adapter is now using browser-native DevTools metadata, page text, screenshot metadata capture, bounded console/log sampling, bounded network timing metadata, structured DOM snapshots with ARIA state metadata plus open shadow-root and same-origin iframe traversal, typed form filling, typed select-option control, typed checked-state control, typed focus control, typed key presses, typed element clicking, verified navigation, bounded URL waiting, bounded selector readiness checks, bounded selector count checks, bounded text readiness checks, bounded value readiness checks, bounded document readiness checks, bounded title readiness checks, bounded checked-state readiness checks, bounded enabled-state readiness checks, bounded focus-state readiness checks, and bounded attribute-state readiness checks.

## Product Direction

The next step is to add adapters for richer state sources:

- Browser DOM through Chrome DevTools Protocol
- Filesystem document indexes and audited file operations beyond bounded local search
- Notifications
- App-native integrations where available
- A permission/audit log around every action

The model-facing API should stay typed and structured, with macOS Accessibility as the compatibility bridge for apps that do not expose native semantic data.
