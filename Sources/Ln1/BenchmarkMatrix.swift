import Foundation

struct BenchmarkScenario: Codable {
    let id: String
    let app: String
    let category: String
    let bundleIdentifiers: [String]
    let surfaces: [String]
    let requiredCapabilities: [String]
    let successCriteria: [String]
    let knownRisks: [String]
    let priority: String
}

struct BenchmarkMatrix: Codable {
    let generatedAt: String
    let platform: String
    let goal: String
    let status: String
    let scenarioCount: Int
    let scenarios: [BenchmarkScenario]
    let message: String
}

func realAppBenchmarkMatrix(generatedAt: String = ISO8601DateFormatter().string(from: Date())) -> BenchmarkMatrix {
    let scenarios = [
        BenchmarkScenario(
            id: "finder-file-lifecycle",
            app: "Finder",
            category: "file-management",
            bundleIdentifiers: ["com.apple.finder"],
            surfaces: ["windows", "toolbar", "sidebar", "context menus", "file pickers"],
            requiredCapabilities: ["desktop metadata", "Accessibility tree", "menu inspection", "file metadata", "rollback"],
            successCriteria: [
                "Locate a visible file by structured state.",
                "Open, rename, duplicate, move, and restore a test file with audit evidence.",
                "Recover when a file picker sheet is frontmost."
            ],
            knownRisks: ["Finder labels and sidebar items may expose weak titles.", "File picker sheets can shift element paths."],
            priority: "critical"
        ),
        BenchmarkScenario(
            id: "browser-checkout-form",
            app: "Browser",
            category: "web",
            bundleIdentifiers: ["com.apple.Safari", "com.google.Chrome", "com.microsoft.edgemac"],
            surfaces: ["tabs", "forms", "downloads", "uploads", "dialogs", "iframes", "shadow DOM"],
            requiredCapabilities: ["DevTools tab metadata", "DOM inspection", "form fill", "click", "keyboard", "download verification"],
            successCriteria: [
                "Complete a multi-step form without fixed sleeps.",
                "Handle a file upload control and verify the downloaded artifact.",
                "Capture enough console or network evidence to debug a failed interaction."
            ],
            knownRisks: ["DevTools coverage varies by browser.", "Native file chooser handoff leaves the DOM control plane."],
            priority: "critical"
        ),
        BenchmarkScenario(
            id: "electron-custom-controls",
            app: "Electron apps",
            category: "desktop-web-hybrid",
            bundleIdentifiers: ["com.tinyspeck.slackmacgap", "com.microsoft.VSCode", "com.github.GitHubClient"],
            surfaces: ["custom controls", "webviews", "command palettes", "modals"],
            requiredCapabilities: ["Accessibility tree", "stable identity guards", "keyboard shortcuts", "visual fallback"],
            successCriteria: [
                "Find and invoke a command-palette action.",
                "Read visible status after an action.",
                "Fall back cleanly when Accessibility exposes generic groups only."
            ],
            knownRisks: ["Electron trees often contain low-signal nested groups.", "Canvas-like widgets may require screenshots."],
            priority: "high"
        ),
        BenchmarkScenario(
            id: "office-document-edit",
            app: "Microsoft Office",
            category: "productivity",
            bundleIdentifiers: ["com.microsoft.Word", "com.microsoft.Excel", "com.microsoft.Powerpoint"],
            surfaces: ["ribbon", "document canvas", "sheets", "dialogs", "save prompts"],
            requiredCapabilities: ["Accessibility tree", "menu inspection", "keyboard shortcuts", "clipboard", "visual verification"],
            successCriteria: [
                "Open a document, edit bounded content, save, and verify file metadata.",
                "Dismiss or satisfy a save prompt without losing work.",
                "Recognize document canvas state when structured text is unavailable."
            ],
            knownRisks: ["Document canvas content may not be fully accessible.", "Ribbon controls can change by mode."],
            priority: "high"
        ),
        BenchmarkScenario(
            id: "xcode-build-debug",
            app: "Xcode",
            category: "developer-tools",
            bundleIdentifiers: ["com.apple.dt.Xcode"],
            surfaces: ["navigator", "editor", "toolbar", "issues pane", "sheets"],
            requiredCapabilities: ["Accessibility tree", "process wait", "file watch", "keyboard shortcuts", "window metadata"],
            successCriteria: [
                "Open a project and start a build.",
                "Detect build completion or failure from structured UI or file/process signals.",
                "Navigate to an issue without relying on screenshots first."
            ],
            knownRisks: ["Build state can appear in transient panes.", "Editor content may require file-system correlation."],
            priority: "high"
        ),
        BenchmarkScenario(
            id: "terminal-command-session",
            app: "Terminal",
            category: "shell",
            bundleIdentifiers: ["com.apple.Terminal", "com.googlecode.iterm2"],
            surfaces: ["terminal buffer", "tabs", "shell prompts", "password prompts"],
            requiredCapabilities: ["window metadata", "keyboard input", "clipboard", "process inspection", "secret handling"],
            successCriteria: [
                "Run a harmless command and verify output.",
                "Detect command completion without corrupting interactive input.",
                "Refuse to echo or persist sensitive prompt text."
            ],
            knownRisks: ["Terminal buffer text can be large or unavailable through Accessibility.", "Password prompts require explicit safety policy."],
            priority: "critical"
        ),
        BenchmarkScenario(
            id: "system-settings-permission-flow",
            app: "System Settings",
            category: "permissions",
            bundleIdentifiers: ["com.apple.systempreferences"],
            surfaces: ["permission panes", "alerts", "toggles", "authorization sheets"],
            requiredCapabilities: ["Accessibility tree", "window wait", "stable identity guards", "audit", "human handoff"],
            successCriteria: [
                "Locate a named privacy permission pane.",
                "Report the exact blocker when automation cannot proceed.",
                "Avoid changing sensitive settings without explicit high-confidence approval."
            ],
            knownRisks: ["macOS privacy panes change across OS versions.", "Some authorization sheets intentionally resist automation."],
            priority: "critical"
        ),
        BenchmarkScenario(
            id: "modal-sheet-recovery",
            app: "Cross-app modal and sheet flows",
            category: "system-ui",
            bundleIdentifiers: [],
            surfaces: ["permission dialogs", "file pickers", "save sheets", "confirmation modals", "sheets", "modals"],
            requiredCapabilities: ["active window detection", "Accessibility tree", "menu inspection", "waits", "safe cancellation"],
            successCriteria: [
                "Detect when a modal blocks the intended app.",
                "Classify whether the modal is safe to accept, cancel, or needs handoff.",
                "Resume the original workflow after the modal is resolved."
            ],
            knownRisks: ["Modal ownership can differ from the app that triggered it.", "Buttons may expose generic labels."],
            priority: "critical"
        )
    ]

    return BenchmarkMatrix(
        generatedAt: generatedAt,
        platform: "macOS",
        goal: "Real-app coverage matrix for flawless computer-use workflows.",
        status: "planned",
        scenarioCount: scenarios.count,
        scenarios: scenarios,
        message: "Use this matrix to drive repeatable real-app verification beyond unit-level command coverage."
    )
}
