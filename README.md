# Ln1 (Layer negative one)

Ln1 is a macOS semantic computer substrate for AI-readable, auditable, verified computer control.

The goal is to make computer use safer, more structured, less screenshot- and coordinate-dependent, and genuinely useful for autonomous agents.

## Useful Commands

Build the CLI:

```sh
swift build
```

Run tests:

```sh
swift test
```

Grant Accessibility access:

```sh
.build/debug/Ln1 trust
```

Check whether the current shell is ready for computer control:

```sh
.build/debug/Ln1 doctor
```

Observe the current computer state:

```sh
.build/debug/Ln1 observe --app-limit 20 --window-limit 20
```

Inspect the frontmost app as structured JSON:

```sh
.build/debug/Ln1 state --depth 4 --max-children 120
```

List the action policy and risk levels:

```sh
.build/debug/Ln1 policy
```

Inspect visible desktop windows:

```sh
.build/debug/Ln1 desktop windows --limit 50
```

Inspect browser tabs through a Chromium DevTools endpoint:

```sh
.build/debug/Ln1 browser tabs --endpoint http://127.0.0.1:9222
```

Preflight a workflow before taking action:

```sh
.build/debug/Ln1 workflow preflight --operation inspect-active-app
```

Review recent audit records:

```sh
.build/debug/Ln1 audit --allow-risk medium --limit 20
```
