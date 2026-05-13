import Foundation

extension Ln1CLI {
    func schema() {
        print("""
        {
          "policy": {
            "command": "Ln1 policy",
            "defaultAllowedRisk": "low",
            "riskLevels": ["low", "medium", "high", "unknown"],
            "actions": [
              { "name": "filesystem.move", "domain": "filesystem", "risk": "medium", "mutates": true }
            ]
          },
          "doctor": {
            "command": "Ln1 doctor --timeout-ms 1000",
            "result": {
              "status": "ready|degraded|blocked",
              "ready": true,
              "checks": [
                {
                  "name": "accessibility",
                  "status": "pass",
                  "required": true,
                  "message": "Accessibility permission is enabled.",
                  "remediation": null
                },
                {
                  "name": "browser.devTools",
                  "status": "warn",
                  "required": false,
                  "message": "Browser DevTools endpoint is not reachable.",
                  "remediation": "Start Chromium with --remote-debugging-port=9222."
                }
              ]
            }
          },
          "workflowPreflight": {
            "command": "Ln1 workflow preflight --operation inspect-active-app",
            "result": {
              "operation": "inspect-active-app",
              "risk": "low",
              "mutates": false,
              "canProceed": true,
              "prerequisites": [
                {
                  "name": "accessibility",
                  "status": "pass",
                  "required": true,
                  "message": "Accessibility permission is enabled."
                }
              ],
              "blockers": [],
              "nextCommand": "Ln1 state --pid 123 --depth 3 --max-children 80",
              "nextArguments": ["Ln1", "state", "--pid", "123", "--depth", "3", "--max-children", "80"],
              "message": "inspect-active-app can proceed with the suggested command."
            }
          },
          "workflowNext": {
            "command": "Ln1 workflow next --operation duplicate-file --path ~/Desktop/a.txt --to ~/Desktop/a-copy.txt --allow-risk medium",
            "result": {
              "operation": "duplicate-file",
              "ready": true,
              "risk": "medium",
              "mutates": true,
              "blockers": [],
              "command": {
                "display": "Ln1 files duplicate --path ~/Desktop/a.txt --to ~/Desktop/a-copy.txt --allow-risk medium --reason 'Describe intent'",
                "argv": ["Ln1", "files", "duplicate", "--path", "~/Desktop/a.txt", "--to", "~/Desktop/a-copy.txt", "--allow-risk", "medium", "--reason", "Describe intent"],
                "risk": "medium",
                "mutates": true,
                "requiresReason": true
              }
            }
          },
          "workflowBrowserAction": {
            "command": "Ln1 workflow preflight --operation navigate-browser --endpoint http://127.0.0.1:9222 --id page-id --url https://example.com/next --expect-url https://example.com/next --match exact",
            "result": {
              "operation": "navigate-browser",
              "risk": "medium",
              "mutates": true,
              "canProceed": true,
              "prerequisites": [
                {
                  "name": "browser.devTools",
                  "status": "pass",
                  "required": true,
                  "message": "Browser DevTools endpoint is reachable with 1 page target(s)."
                },
                {
                  "name": "auditLog",
                  "status": "pass",
                  "required": true,
                  "message": "Audit log path is writable."
                }
              ],
              "blockers": [],
              "nextCommand": "Ln1 browser navigate --endpoint http://127.0.0.1:9222 --id page-id --url https://example.com/next --expect-url https://example.com/next --match exact --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "navigate", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--url", "https://example.com/next", "--expect-url", "https://example.com/next", "--match", "exact", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "navigate-browser can proceed with the suggested command."
            }
          },
          "workflowRun": {
            "command": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --dry-run false",
            "result": {
              "transcriptID": "UUID",
              "transcriptPath": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "read-browser",
              "mode": "execute",
              "dryRun": false,
              "ready": true,
              "wouldExecute": true,
              "executed": true,
              "risk": "medium",
              "mutates": false,
              "blockers": [],
              "command": {
                "display": "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
                "argv": ["Ln1", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
                "risk": "medium",
                "mutates": false,
                "requiresReason": false
              },
              "execution": {
                "argv": ["Ln1", "browser", "tabs", "--endpoint", "http://127.0.0.1:9222"],
                "exitCode": 0,
                "timeoutMilliseconds": 10000,
                "timedOut": false,
                "maxOutputBytes": 1048576,
                "stdout": "{...}",
                "stdoutBytes": 128,
                "stdoutTruncated": false,
                "stderr": "",
                "stderrBytes": 0,
                "stderrTruncated": false,
                "outputJSON": {
                  "count": 1,
                  "tabs": []
                }
              },
              "message": "Workflow executed a non-mutating command and captured its output."
            }
          },
          "workflowLog": {
            "command": "Ln1 workflow log --allow-risk medium --limit 20",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": null,
              "limit": 20,
              "count": 1,
              "entries": [
                {
                  "transcriptID": "UUID",
                  "operation": "read-browser",
                  "executed": true,
                  "blockers": []
                }
              ]
            }
          },
          "workflowResume": {
            "command": "Ln1 workflow resume --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": null,
              "status": "completed|blocked|timed_out|failed|ready|empty",
              "transcriptID": "UUID",
              "latestOperation": "read-browser",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser tab listing completed; dry-run DOM inspection for the first tab."
            }
          },
          "workflowResumeDOM": {
            "command": "Ln1 workflow resume --allow-risk medium --operation read-browser",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "read-browser",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "read-browser",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser DOM inspection found an actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitURL": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-url",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-url",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-url",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser URL wait completed; dry-run DOM inspection for the arrived page."
            }
          },
          "workflowWaitFile": {
            "command": "Ln1 workflow run --operation wait-file --path ~/Downloads/report.pdf --exists true --wait-timeout-ms 5000 --dry-run false --run-timeout-ms 1000",
            "result": {
              "operation": "wait-file",
              "risk": "low",
              "mutates": false,
              "command": {
                "argv": ["Ln1", "files", "wait", "--path", "~/Downloads/report.pdf", "--exists", "true", "--timeout-ms", "5000", "--interval-ms", "100"]
              },
              "execution": {
                "timedOut": true,
                "timeoutMilliseconds": 1000,
                "stdoutTruncated": false,
                "stderrTruncated": false
              }
            }
          },
          "observe": {
            "command": "Ln1 observe --app-limit 20 --window-limit 20",
            "result": {
              "accessibility": {
                "trusted": true,
                "message": "Accessibility access is enabled."
              },
              "activeApp": { "name": "Terminal", "bundleIdentifier": "com.apple.Terminal", "pid": 123, "active": true },
              "appCount": 3,
              "appsTruncated": false,
              "desktop": {
                "available": true,
                "count": 2,
                "windows": [
                  { "id": "window:456", "stableIdentity": { "id": "desktopWindow:stable-semantic-digest" } }
                ]
              },
              "blockers": [],
              "suggestedActions": [
                {
                  "name": "accessibility.inspectState",
                  "command": "Ln1 state --pid 123 --depth 3 --max-children 80",
                  "risk": "low",
                  "mutates": false,
                  "reason": "Inspect the active app's UI tree with stable element identities."
                }
              ]
            }
          },
          "appsInstalled": {
            "command": "Ln1 apps installed --name TextEdit --limit 20",
            "result": {
              "generatedAt": "ISO-8601 timestamp",
              "platform": "macOS",
              "searchRoots": ["/Applications", "/System/Applications"],
              "limit": 20,
              "count": 1,
              "truncated": false,
              "apps": [
                {
                  "name": "TextEdit",
                  "bundleIdentifier": "com.apple.TextEdit",
                  "path": "/System/Applications/TextEdit.app",
                  "version": "1.18",
                  "executablePath": "/System/Applications/TextEdit.app/Contents/MacOS/TextEdit"
                }
              ],
              "message": "Read installed app bundle metadata."
            }
          },
          "appsLaunchPlan": {
            "command": "Ln1 apps plan --operation launch --bundle-id com.apple.TextEdit --activate false --allow-risk medium",
            "result": {
              "operation": "launch",
              "action": "apps.launch",
              "risk": "medium",
              "actionMutates": true,
              "policy": {
                "allowedRisk": "medium",
                "actionRisk": "medium",
                "allowed": true
              },
              "target": {
                "name": "TextEdit",
                "bundleIdentifier": "com.apple.TextEdit",
                "path": "/System/Applications/TextEdit.app"
              },
              "activeBefore": { "name": "Terminal", "bundleIdentifier": "com.apple.Terminal", "pid": 123 },
              "runningApp": null,
              "activate": false,
              "checks": [
                {
                  "name": "apps.launchTarget",
                  "ok": true,
                  "code": "launch_target_found",
                  "message": "Launch target app bundle is installed at /System/Applications/TextEdit.app."
                }
              ],
              "canExecute": true,
              "requiredAllowRisk": "medium"
            }
          },
          "appsLaunch": {
            "command": "Ln1 apps launch --bundle-id com.apple.TextEdit --activate true --allow-risk medium --reason 'Open editor'",
            "result": {
              "ok": true,
              "action": "apps.launch",
              "risk": "medium",
              "target": {
                "name": "TextEdit",
                "bundleIdentifier": "com.apple.TextEdit",
                "path": "/System/Applications/TextEdit.app"
              },
              "app": { "name": "TextEdit", "bundleIdentifier": "com.apple.TextEdit", "pid": 456 },
              "activeBefore": { "name": "Terminal", "bundleIdentifier": "com.apple.Terminal", "pid": 123 },
              "activeAfter": { "name": "TextEdit", "bundleIdentifier": "com.apple.TextEdit", "pid": 456 },
              "activate": true,
              "verification": {
                "ok": true,
                "code": "launched_active_app",
                "message": "launched app is running and frontmost"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl",
              "message": "Launched TextEdit."
            }
          },
          "state": {
            "generatedAt": "ISO-8601 timestamp",
            "platform": "macOS",
            "app": {
              "name": "frontmost or requested app name",
              "bundleIdentifier": "com.example.App",
              "pid": 123
            },
            "windows": [
              {
                "id": "w0.3.1",
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "high",
                  "label": "Save AXButton in com.example.App",
                  "components": {
                    "owner": "com.example.app",
                    "role": "AXButton",
                    "title": "save"
                  },
                  "reasons": ["owner bundle identifier or name", "role", "title"]
                },
                "role": "AXButton",
                "subrole": null,
                "title": "Save",
                "value": null,
                "help": null,
                "enabled": true,
                "frame": { "x": 10, "y": 20, "width": 80, "height": 32 },
                "actions": ["AXPress"],
                "settableAttributes": [],
                "valueSettable": false,
                "children": []
              }
            ]
          },
          "stateMenu": {
            "command": "Ln1 state menu --depth 2 --max-children 80",
            "result": {
              "generatedAt": "ISO-8601 timestamp",
              "platform": "macOS",
              "app": {
                "name": "frontmost or requested app name",
                "bundleIdentifier": "com.example.App",
                "pid": 123
              },
              "menuBar": {
                "id": "m0",
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "medium",
                  "label": "AXMenuBar in com.example.App"
                },
                "role": "AXMenuBar",
                "title": null,
                "actions": [],
                "settableAttributes": [],
                "valueSettable": false,
                "children": [
                  {
                    "id": "m0.0",
                    "role": "AXMenuBarItem",
                    "title": "File",
                    "settableAttributes": [],
                    "valueSettable": false,
                    "children": []
                  }
                ]
              },
              "depth": 2,
              "maxChildren": 80,
              "message": "Accessibility menu bar state inspected."
            }
          },
          "stateAll": {
            "generatedAt": "ISO-8601 timestamp",
            "platform": "macOS",
            "apps": [
              {
                "app": { "name": "Finder", "bundleIdentifier": "com.apple.finder", "pid": 456 },
                "windows": [
                  {
                    "id": "a0.w0.3.1",
                    "stableIdentity": {
                      "id": "accessibilityElement:stable-semantic-digest",
                      "kind": "accessibilityElement",
                      "confidence": "high",
                      "label": "Save AXButton in Finder",
                      "components": {
                        "owner": "com.apple.finder",
                        "role": "AXButton",
                        "title": "save"
                      },
                      "reasons": ["owner bundle identifier or name", "role", "title"]
                    },
                    "role": "AXButton",
                    "actions": ["AXPress"],
                    "settableAttributes": [],
                    "valueSettable": false,
                    "children": []
                  }
                ]
              }
            ]
          },
          "desktopWindows": {
            "command": "Ln1 desktop windows --limit 50",
            "result": {
              "available": true,
              "message": "Read visible desktop window metadata.",
              "activePID": 123,
              "includeDesktop": false,
              "includeAllLayers": false,
              "count": 1,
              "windows": [
                {
                  "id": "window:456",
                  "stableIdentity": {
                    "id": "desktopWindow:stable-semantic-digest",
                    "kind": "desktopWindow",
                    "confidence": "high",
                    "label": "Documents window in Finder",
                    "components": {
                      "owner": "com.apple.finder",
                      "title": "documents",
                      "layer": "0"
                    },
                    "reasons": ["owner bundle identifier or name", "window title"]
                  },
                  "windowNumber": 456,
                  "ownerName": "Finder",
                  "ownerBundleIdentifier": "com.apple.finder",
                  "ownerPID": 123,
                  "active": true,
                  "title": "Documents",
                  "layer": 0,
                  "bounds": { "x": 0, "y": 25, "width": 900, "height": 700 },
                  "onscreen": true
                }
              ]
            }
          },
          "perform": {
            "command": "Ln1 perform --pid 456 --element a0.w0.3.1|a0.m0.1 --expect-identity accessibilityElement:stable-semantic-digest --min-identity-confidence medium --action AXPress --allow-risk low --reason 'Open details'",
            "result": {
              "ok": true,
              "stableIdentity": {
                "id": "accessibilityElement:stable-semantic-digest",
                "kind": "accessibilityElement",
                "confidence": "high"
              },
              "identityVerification": {
                "ok": true,
                "code": "identity_verified",
                "expectedID": "accessibilityElement:stable-semantic-digest",
                "actualID": "accessibilityElement:stable-semantic-digest",
                "minimumConfidence": "medium",
                "actualConfidence": "high"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "setValue": {
            "command": "Ln1 set-value --pid 456 --element a0.w0.4 --expect-identity accessibilityElement:stable-semantic-digest --min-identity-confidence medium --value 'new text' --allow-risk medium --reason 'Update field'",
            "result": {
              "ok": true,
              "pid": 456,
              "element": "a0.w0.4",
              "stableIdentity": {
                "id": "accessibilityElement:stable-semantic-digest",
                "kind": "accessibilityElement",
                "confidence": "high"
              },
              "action": "accessibility.setValue",
              "risk": "medium",
              "valueLength": 8,
              "valueDigest": "hex encoded SHA-256 digest",
              "currentValueLength": 8,
              "currentValueDigest": "hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "value_verified",
                "message": "element AXValue contains text with the requested length and digest"
              },
              "identityVerification": {
                "ok": true,
                "code": "identity_verified",
                "expectedID": "accessibilityElement:stable-semantic-digest",
                "actualID": "accessibilityElement:stable-semantic-digest",
                "minimumConfidence": "medium",
                "actualConfidence": "high"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "audit": {
            "command": "Ln1 audit --id UUID --command files.move --code moved --limit 20",
            "entry": {
              "id": "UUID",
              "timestamp": "ISO-8601 timestamp",
              "command": "perform",
              "risk": "low|medium|high|unknown",
              "reason": "caller supplied intent",
              "app": { "name": "Finder", "bundleIdentifier": "com.apple.finder", "pid": 456 },
              "elementID": "w0.3.1",
              "element": {
                "stableIdentity": {
                  "id": "accessibilityElement:stable-semantic-digest",
                  "kind": "accessibilityElement",
                  "confidence": "high"
                },
                "role": "AXButton",
                "title": "Save",
                "enabled": true,
                "actions": ["AXPress"],
                "settableAttributes": [],
                "valueSettable": false
              },
              "action": "AXPress",
              "policy": {
                "allowedRisk": "low",
                "actionRisk": "low",
                "allowed": true,
                "message": "policy allowed low action with --allow-risk low"
              },
              "identityVerification": {
                "ok": true,
                "code": "identity_verified",
                "expectedID": "accessibilityElement:stable-semantic-digest",
                "actualID": "accessibilityElement:stable-semantic-digest",
                "minimumConfidence": "medium",
                "actualConfidence": "high"
              },
              "outcome": { "ok": true, "code": "performed", "message": "Performed AXPress on w0.3.1." }
            }
          },
          "taskMemory": {
            "command": "Ln1 task record --task-id UUID --kind verification --summary 'download matched expected digest' --allow-risk medium",
            "result": {
              "path": "~/Library/Application Support/Ln1/task-memory.jsonl",
              "taskID": "UUID",
              "status": "active|completed|blocked|cancelled",
              "title": "Verify downloaded report",
              "eventCount": 2,
              "events": [
                {
                  "kind": "task.verification",
                  "summary": "download matched expected digest",
                  "summaryLength": 31,
                  "summaryDigest": "hex encoded SHA-256 digest",
                  "sensitivity": "private",
                  "relatedAuditID": "UUID"
                }
              ]
            }
          },
          "clipboardState": {
            "command": "Ln1 clipboard state",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "types": ["public.utf8-plain-text"],
              "hasString": true,
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "actions": [
                { "name": "clipboard.state", "risk": "low", "mutates": false },
                { "name": "clipboard.wait", "risk": "low", "mutates": false },
                { "name": "clipboard.readText", "risk": "medium", "mutates": false },
                { "name": "clipboard.writeText", "risk": "medium", "mutates": true }
              ]
            }
          },
          "clipboardWait": {
            "command": "Ln1 clipboard wait --changed-from 12 --has-string true --timeout-ms 5000",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "clipboard_matched",
                "message": "clipboard metadata matched expected state",
                "changedFrom": 12,
                "expectedHasString": true,
                "current": {
                  "pasteboard": "Apple CFPasteboard general",
                  "changeCount": 13,
                  "types": ["public.utf8-plain-text"],
                  "hasString": true,
                  "stringLength": 42,
                  "stringDigest": "hex encoded SHA-256 digest"
                },
                "matched": true
              }
            }
          },
          "clipboardText": {
            "command": "Ln1 clipboard read-text --allow-risk medium --max-characters 4096 --reason 'Use copied value'",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "changeCount": 12,
              "hasString": true,
              "text": "bounded clipboard text",
              "stringLength": 42,
              "stringDigest": "hex encoded SHA-256 digest",
              "truncated": false,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "clipboardWrite": {
            "command": "Ln1 clipboard write-text --allow-risk medium --text 'bounded clipboard text' --reason 'Prepare value for paste'",
            "result": {
              "pasteboard": "Apple CFPasteboard general",
              "previous": {
                "changeCount": 12,
                "stringLength": 42,
                "stringDigest": "previous hex encoded SHA-256 digest"
              },
              "current": {
                "changeCount": 14,
                "stringLength": 22,
                "stringDigest": "new hex encoded SHA-256 digest"
              },
              "writtenLength": 22,
              "writtenDigest": "new hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "text_matched",
                "message": "clipboard contains text with the requested length and digest"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserTabs": {
            "command": "Ln1 browser tabs --endpoint http://127.0.0.1:9222",
            "result": {
              "endpoint": "http://127.0.0.1:9222",
              "includeNonPageTargets": false,
              "count": 1,
              "tabs": [
                {
                  "id": "devtools-target-id",
                  "type": "page",
                  "title": "Page title",
                  "url": "https://example.com",
                  "webSocketDebuggerURL": "ws://127.0.0.1:9222/devtools/page/devtools-target-id",
                  "actions": [
                    { "name": "browser.inspectTab", "risk": "low", "mutates": false },
                    { "name": "browser.readText", "risk": "medium", "mutates": false },
                    { "name": "browser.readDOM", "risk": "medium", "mutates": false },
                    { "name": "browser.fillFormField", "risk": "medium", "mutates": true },
                    { "name": "browser.selectOption", "risk": "medium", "mutates": true },
                    { "name": "browser.setChecked", "risk": "medium", "mutates": true },
                    { "name": "browser.focusElement", "risk": "medium", "mutates": true },
                    { "name": "browser.pressKey", "risk": "medium", "mutates": true },
                    { "name": "browser.clickElement", "risk": "medium", "mutates": true },
                    { "name": "browser.navigate", "risk": "medium", "mutates": true },
                    { "name": "browser.waitURL", "risk": "low", "mutates": false },
                    { "name": "browser.waitSelector", "risk": "low", "mutates": false },
                    { "name": "browser.waitCount", "risk": "low", "mutates": false },
                    { "name": "browser.waitText", "risk": "low", "mutates": false },
                    { "name": "browser.waitElementText", "risk": "low", "mutates": false },
                    { "name": "browser.waitValue", "risk": "low", "mutates": false },
                    { "name": "browser.waitReady", "risk": "low", "mutates": false },
                    { "name": "browser.waitTitle", "risk": "low", "mutates": false },
                    { "name": "browser.waitChecked", "risk": "low", "mutates": false },
                    { "name": "browser.waitEnabled", "risk": "low", "mutates": false },
                    { "name": "browser.waitFocus", "risk": "low", "mutates": false },
                    { "name": "browser.waitAttribute", "risk": "low", "mutates": false }
                  ]
                }
              ]
            }
          },
          "browserTab": {
            "command": "Ln1 browser tab --endpoint http://127.0.0.1:9222 --id devtools-target-id",
            "result": {
              "tab": {
                "id": "devtools-target-id",
                "title": "Page title",
                "url": "https://example.com"
              }
            }
          },
          "browserDOM": {
            "command": "Ln1 browser dom --endpoint http://127.0.0.1:9222 --id devtools-target-id --allow-risk medium --max-elements 200 --max-text-characters 120",
            "result": {
              "action": "browser.readDOM",
              "risk": "medium",
              "elementCount": 2,
              "truncated": false,
              "elements": [
                {
                  "id": "dom.0",
                  "parentID": null,
                  "depth": 0,
                  "selector": "body",
                  "tagName": "body",
                  "role": null,
                  "text": "Visible page text",
                  "textLength": 17,
                  "attributes": {},
                  "inputType": null,
                  "checked": null,
                  "disabled": null,
                  "hasValue": null,
                  "valueLength": null
                },
                {
                  "id": "dom.1",
                  "parentID": "dom.0",
                  "depth": 1,
                  "selector": "input[name=\\"q\\"]",
                  "tagName": "input",
                  "role": "textbox",
                  "text": null,
                  "textLength": 0,
                  "attributes": { "name": "q", "placeholder": "Search" },
                  "inputType": "search",
                  "checked": false,
                  "disabled": false,
                  "hasValue": true,
                  "valueLength": 6
                }
              ]
            }
          },
          "browserFill": {
            "command": "Ln1 browser fill --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --text 'bounded text' --allow-risk medium",
            "result": {
              "action": "browser.fillFormField",
              "risk": "medium",
              "selector": "input[name=q]",
              "textLength": 12,
              "textDigest": "hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "value_matched",
                "message": "browser form field contains text with the requested length"
              },
              "targetTagName": "input",
              "targetInputType": "text",
              "resultingValueLength": 12,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserSelect": {
            "command": "Ln1 browser select --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'select[name=country]' --value ca --allow-risk medium",
            "result": {
              "action": "browser.selectOption",
              "risk": "medium",
              "selector": "select[name=country]",
              "requestedValueLength": 2,
              "requestedValueDigest": "hex encoded SHA-256 digest",
              "verification": {
                "ok": true,
                "code": "option_selected",
                "message": "browser select contains the requested option"
              },
              "targetTagName": "select",
              "targetDisabled": false,
              "optionCount": 3,
              "selectedIndex": 2,
              "selectedValueLength": 2,
              "selectedLabelLength": 6,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserCheck": {
            "command": "Ln1 browser check --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=subscribe]' --checked true --allow-risk medium",
            "result": {
              "action": "browser.setChecked",
              "risk": "medium",
              "selector": "input[name=subscribe]",
              "requestedChecked": true,
              "verification": {
                "ok": true,
                "code": "checked_matched",
                "message": "browser control checked state matches the requested value"
              },
              "targetTagName": "input",
              "targetInputType": "checkbox",
              "targetDisabled": false,
              "targetReadOnly": false,
              "currentChecked": true,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserFocus": {
            "command": "Ln1 browser focus --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --allow-risk medium",
            "result": {
              "action": "browser.focusElement",
              "risk": "medium",
              "selector": "input[name=q]",
              "verification": {
                "ok": true,
                "code": "element_focused",
                "message": "browser active element matches the requested selector"
              },
              "targetTagName": "input",
              "targetInputType": "text",
              "targetDisabled": false,
              "targetReadOnly": false,
              "activeElementMatched": true,
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserPressKey": {
            "command": "Ln1 browser press-key --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --key Enter --allow-risk medium",
            "result": {
              "action": "browser.pressKey",
              "risk": "medium",
              "key": "Enter",
              "modifiers": [],
              "modifierMask": 0,
              "selector": "input[name=q]",
              "focusVerification": {
                "ok": true,
                "code": "element_focused",
                "message": "browser active element matches the requested selector"
              },
              "verification": {
                "ok": true,
                "code": "key_pressed",
                "message": "browser key press dispatched through Chrome DevTools",
                "keyDownDispatched": true,
                "keyUpDispatched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserClick": {
            "command": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --expect-url https://example.com/next --match exact --allow-risk medium",
            "result": {
              "action": "browser.clickElement",
              "risk": "medium",
              "selector": "button[type=submit]",
              "verification": {
                "ok": true,
                "code": "element_clicked",
                "message": "browser element matched selector and received a click"
              },
              "targetTagName": "button",
              "targetDisabled": false,
              "targetHref": null,
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "urlVerification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserNavigate": {
            "command": "Ln1 browser navigate --endpoint http://127.0.0.1:9222 --id devtools-target-id --url https://example.com/next --allow-risk medium",
            "result": {
              "action": "browser.navigate",
              "risk": "medium",
              "requestedURL": "https://example.com/next",
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "verification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "browserWaitURL": {
            "command": "Ln1 browser wait-url --endpoint http://127.0.0.1:9222 --id devtools-target-id --expect-url https://example.com/next --match exact --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedURL": "https://example.com/next",
              "match": "exact",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "url_matched",
                "message": "browser tab URL matched expected exact value",
                "currentURL": "https://example.com/next",
                "matched": true
              }
            }
          },
          "browserWaitSelector": {
            "command": "Ln1 browser wait-selector --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --state visible --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "button[type=submit]",
              "state": "visible",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "selector_matched",
                "message": "The selector reached 'visible' state.",
                "currentURL": "https://example.com/form",
                "tagName": "button",
                "matched": true
              }
            }
          },
          "browserWaitCount": {
            "command": "Ln1 browser wait-count --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector '.result-row' --count 3 --count-match at-least --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": ".result-row",
              "expectedCount": 3,
              "countMatch": "at-least",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "count_matched",
                "message": "browser selector count matched expected at-least value",
                "currentCount": 5,
                "currentURL": "https://example.com/results",
                "matched": true
              }
            }
          },
          "browserWaitText": {
            "command": "Ln1 browser wait-text --endpoint http://127.0.0.1:9222 --id devtools-target-id --text 'Saved successfully' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedTextLength": 18,
              "expectedTextDigest": "hex encoded SHA-256 digest",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "text_matched",
                "message": "browser tab text matched expected contains value",
                "currentTextLength": 120,
                "currentTextDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "matched": true
              }
            }
          },
          "browserWaitElementText": {
            "command": "Ln1 browser wait-element-text --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector '[data-testid=status]' --text 'Saved successfully' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "[data-testid=status]",
              "expectedTextLength": 18,
              "expectedTextDigest": "hex encoded SHA-256 digest",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "element_text_matched",
                "message": "browser element text matched expected contains value",
                "currentTextLength": 18,
                "currentTextDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "tagName": "div",
                "matched": true
              }
            }
          },
          "browserWaitValue": {
            "command": "Ln1 browser wait-value --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --text 'bounded text' --match exact --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=q]",
              "expectedValueLength": 12,
              "expectedValueDigest": "hex encoded SHA-256 digest",
              "match": "exact",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "value_matched",
                "message": "browser field value matched expected exact value",
                "currentValueLength": 12,
                "currentValueDigest": "hex encoded SHA-256 digest",
                "currentURL": "https://example.com/form",
                "tagName": "input",
                "inputType": "text",
                "matched": true
              }
            }
          },
          "browserWaitReady": {
            "command": "Ln1 browser wait-ready --endpoint http://127.0.0.1:9222 --id devtools-target-id --state complete --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedState": "complete",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "ready_state_matched",
                "message": "browser document ready state reached complete",
                "currentState": "complete",
                "currentURL": "https://example.com/form",
                "matched": true
              }
            }
          },
          "browserWaitTitle": {
            "command": "Ln1 browser wait-title --endpoint http://127.0.0.1:9222 --id devtools-target-id --title 'Checkout' --match contains --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "expectedTitle": "Checkout",
              "match": "contains",
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "title_matched",
                "message": "browser tab title matched expected contains value",
                "currentTitle": "Checkout - Example",
                "currentURL": "https://example.com/checkout",
                "matched": true
              }
            }
          },
          "browserWaitChecked": {
            "command": "Ln1 browser wait-checked --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=subscribe]' --checked true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=subscribe]",
              "expectedChecked": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "checked_matched",
                "message": "browser checked state matched expected value",
                "currentChecked": true,
                "currentURL": "https://example.com/preferences",
                "tagName": "input",
                "inputType": "checkbox",
                "matched": true
              }
            }
          },
          "browserWaitEnabled": {
            "command": "Ln1 browser wait-enabled --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'button[type=submit]' --enabled true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "button[type=submit]",
              "expectedEnabled": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "enabled_matched",
                "message": "browser element enabled state matched expected value",
                "currentEnabled": true,
                "currentURL": "https://example.com/form",
                "tagName": "button",
                "disabled": false,
                "matched": true
              }
            }
          },
          "browserWaitFocus": {
            "command": "Ln1 browser wait-focus --endpoint http://127.0.0.1:9222 --id devtools-target-id --selector 'input[name=q]' --focused true --timeout-ms 5000",
            "result": {
              "tabID": "devtools-target-id",
              "selector": "input[name=q]",
              "expectedFocused": true,
              "timeoutMilliseconds": 5000,
              "intervalMilliseconds": 100,
              "verification": {
                "ok": true,
                "code": "focus_matched",
                "message": "browser element focus state matched expected value",
                "currentFocused": true,
                "currentURL": "https://example.com/form",
                "tagName": "input",
                "inputType": "text",
                "activeTagName": "input",
                "activeInputType": "text",
                "matched": true
              }
            }
          },
          "workflowResumeWaitSelector": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-selector",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-selector",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-selector",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser selector wait found a ready actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitCount": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-count",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-count",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-count",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser count wait completed; dry-run DOM inspection for the matched collection state."
            }
          },
          "workflowResumeWaitEnabled": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-enabled",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-enabled",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-enabled",
              "blockers": [],
              "nextCommand": "Ln1 browser click --endpoint http://127.0.0.1:9222 --id page-id --selector 'button[type=submit]' --allow-risk medium --reason 'Describe intent'",
              "nextArguments": ["Ln1", "browser", "click", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--selector", "button[type=submit]", "--allow-risk", "medium", "--reason", "Describe intent"],
              "message": "Latest browser enabled-state wait found an enabled actionable element; click it by selector after confirming intent."
            }
          },
          "workflowResumeWaitFocus": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-focus",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-focus",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-focus",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser focus wait completed; dry-run DOM inspection for the focused element state."
            }
          },
          "workflowResumeWaitText": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-text",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-text",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-text",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser text wait completed; dry-run DOM inspection for the matched page state."
            }
          },
          "workflowResumeWaitElementText": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-element-text",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-element-text",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-element-text",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser element text wait completed; dry-run DOM inspection for the matched element state."
            }
          },
          "workflowResumeWaitValue": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-value",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-value",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-value",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser value wait completed; dry-run DOM inspection for the matched field state."
            }
          },
          "workflowResumeWaitReady": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-ready",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-ready",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-ready",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser ready-state wait completed; dry-run DOM inspection for the loaded page state."
            }
          },
          "workflowResumeWaitTitle": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-title",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-title",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-title",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser title wait completed; dry-run DOM inspection for the matched page."
            }
          },
          "workflowResumeWaitChecked": {
            "command": "Ln1 workflow resume --allow-risk medium --operation wait-browser-checked",
            "result": {
              "path": "~/Library/Application Support/Ln1/workflow-runs.jsonl",
              "operation": "wait-browser-checked",
              "status": "completed",
              "transcriptID": "UUID",
              "latestOperation": "wait-browser-checked",
              "blockers": [],
              "nextCommand": "Ln1 workflow run --operation read-browser --endpoint http://127.0.0.1:9222 --id page-id --dry-run true --workflow-log '~/Library/Application Support/Ln1/workflow-runs.jsonl'",
              "nextArguments": ["Ln1", "workflow", "run", "--operation", "read-browser", "--endpoint", "http://127.0.0.1:9222", "--id", "page-id", "--dry-run", "true", "--workflow-log", "~/Library/Application Support/Ln1/workflow-runs.jsonl"],
              "message": "Latest browser checked-state wait completed; dry-run DOM inspection for the matched form state."
            }
          },
          "files": {
            "command": "Ln1 files list --path ~/Documents --depth 2 --limit 200",
            "entry": {
              "id": "file:stable-resource-identifier",
              "path": "/Users/example/Documents/Plan.md",
              "name": "Plan.md",
              "kind": "regularFile|directory|symbolicLink|other",
              "sizeBytes": 1234,
              "createdAt": "ISO-8601 timestamp",
              "modifiedAt": "ISO-8601 timestamp",
              "hidden": false,
              "readable": true,
              "writable": true,
              "actions": [
                { "name": "filesystem.stat", "risk": "low", "mutates": false }
              ]
            }
          },
          "fileSearch": {
            "command": "Ln1 files search --path ~/Documents --query invoice --depth 4 --limit 50",
            "maxMatchesPerFile": 20,
            "match": {
              "file": {
                "path": "/Users/example/Documents/Invoice.txt",
                "kind": "regularFile",
                "actions": [
                  { "name": "filesystem.stat", "risk": "low", "mutates": false },
                  { "name": "filesystem.search", "risk": "low", "mutates": false }
                ]
              },
              "matchedName": true,
              "contentMatches": [
                { "lineNumber": 4, "text": "bounded matching line snippet" }
              ]
            }
          },
          "fileWait": {
            "command": "Ln1 files wait --path ~/Downloads/report.pdf --exists true --size-bytes 1048576 --digest 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824 --timeout-ms 5000 --interval-ms 100",
            "result": {
              "path": "/Users/example/Downloads/report.pdf",
              "expectedExists": true,
              "expectedSizeBytes": 1048576,
              "expectedDigest": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
              "algorithm": "sha256",
              "matched": true,
              "sizeMatched": true,
              "digestMatched": true,
              "currentDigest": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
              "elapsedMilliseconds": 100,
              "file": { "path": "/Users/example/Downloads/report.pdf", "kind": "regularFile" },
              "message": "Path exists at /Users/example/Downloads/report.pdf and matched expected metadata."
            }
          },
          "fileWatch": {
            "command": "Ln1 files watch --path ~/Downloads --depth 1 --timeout-ms 30000 --interval-ms 250",
            "result": {
              "root": { "path": "/Users/example/Downloads", "kind": "directory" },
              "matched": true,
              "events": [
                {
                  "id": "fileEvent:hex encoded SHA-256 digest",
                  "type": "created",
                  "path": "/Users/example/Downloads/report.pdf",
                  "previous": null,
                  "current": { "path": "/Users/example/Downloads/report.pdf", "kind": "regularFile" }
                }
              ],
              "eventCount": 1,
              "beforeCount": 4,
              "afterCount": 5
            }
          },
          "fileChecksum": {
            "command": "Ln1 files checksum --path ~/Documents/Plan.md --algorithm sha256 --max-file-bytes 104857600",
            "result": {
              "file": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "algorithm": "sha256",
              "digest": "hex encoded SHA-256 digest",
              "maxFileBytes": 104857600
            }
          },
          "fileCompare": {
            "command": "Ln1 files compare --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --algorithm sha256 --max-file-bytes 104857600",
            "result": {
              "left": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "right": { "path": "/Users/example/Documents/Plan copy.md", "kind": "regularFile" },
              "algorithm": "sha256",
              "sameSize": true,
              "sameDigest": true,
              "matched": true
            }
          },
          "filePlan": {
            "command": "Ln1 files plan --operation move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium",
            "result": {
              "operation": "move",
              "action": "filesystem.move",
              "risk": "medium",
              "actionMutates": true,
              "policy": {
                "allowedRisk": "medium",
                "actionRisk": "medium",
                "allowed": true
              },
              "source": { "path": "/Users/example/Documents/Draft.md", "exists": true },
              "destination": { "path": "/Users/example/Documents/Archive/Draft.md", "exists": false },
              "checks": [
                { "name": "destinationMissing", "ok": true, "code": "missing" }
              ],
              "canExecute": true,
              "requiredAllowRisk": "medium"
            }
          },
          "fileDuplicate": {
            "command": "Ln1 files duplicate --path ~/Documents/Plan.md --to ~/Documents/Plan copy.md --allow-risk medium --reason 'Preserve original before editing'",
            "result": {
              "ok": true,
              "action": "filesystem.duplicate",
              "risk": "medium",
              "source": { "path": "/Users/example/Documents/Plan.md", "kind": "regularFile" },
              "destination": { "path": "/Users/example/Documents/Plan copy.md", "kind": "regularFile" },
              "verification": {
                "ok": true,
                "code": "metadata_matched",
                "message": "destination exists and size matches source"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "fileMove": {
            "command": "Ln1 files move --path ~/Documents/Draft.md --to ~/Documents/Archive/Draft.md --allow-risk medium --reason 'Organize completed draft'",
            "result": {
              "ok": true,
              "action": "filesystem.move",
              "risk": "medium",
              "source": { "path": "/Users/example/Documents/Draft.md", "kind": "regularFile" },
              "destination": { "path": "/Users/example/Documents/Archive/Draft.md", "kind": "regularFile" },
              "verification": {
                "ok": true,
                "code": "moved_and_metadata_matched",
                "message": "source path is gone, destination exists, and size matches original source"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "directoryCreate": {
            "command": "Ln1 files mkdir --path ~/Documents/Archive --allow-risk medium --reason 'Create archive folder'",
            "result": {
              "ok": true,
              "action": "filesystem.createDirectory",
              "risk": "medium",
              "directory": { "path": "/Users/example/Documents/Archive", "kind": "directory" },
              "verification": {
                "ok": true,
                "code": "directory_exists",
                "message": "directory exists at requested path"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          },
          "fileRollback": {
            "command": "Ln1 files rollback --audit-id UUID --allow-risk medium --reason 'Undo mistaken move'",
            "result": {
              "ok": true,
              "action": "filesystem.rollbackMove",
              "risk": "medium",
              "rollbackOfAuditID": "UUID",
              "restoredSource": { "path": "/Users/example/Documents/Draft.md", "kind": "regularFile" },
              "previousDestination": { "path": "/Users/example/Documents/Archive/Draft.md", "exists": false },
              "verification": {
                "ok": true,
                "code": "move_restored",
                "message": "original source path is restored and moved destination is gone"
              },
              "auditID": "UUID",
              "auditLogPath": "~/Library/Application Support/Ln1/audit-log.jsonl"
            }
          }
        }
        """)
    }

}
