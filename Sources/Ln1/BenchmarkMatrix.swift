import Foundation

struct BenchmarkScenario: Codable {
    let id: String
    let app: String
    let category: String
    let bundleIdentifiers: [String]
    let surfaces: [String]
    let requiredCapabilities: [String]
    let successCriteria: [String]
    let verificationCommands: [String]
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
            verificationCommands: [
                "Ln1 apps list --name Finder",
                "Ln1 desktop windows --bundle-id com.apple.finder",
                "Ln1 workflow preflight --operation inspect-windows --bundle-id com.apple.finder",
                "Ln1 files stat --path PATH"
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
            verificationCommands: [
                "Ln1 browser tabs --endpoint ENDPOINT",
                "Ln1 browser dom --endpoint ENDPOINT --id TARGET_ID --selector SELECTOR",
                "Ln1 browser console --endpoint ENDPOINT --id TARGET_ID",
                "Ln1 browser network --endpoint ENDPOINT --id TARGET_ID",
                "Ln1 files wait --path DOWNLOAD_PATH --exists true"
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
            verificationCommands: [
                "Ln1 state --pid PID --depth 4 --max-children 80",
                "Ln1 state element --pid PID --element ELEMENT_ID --expect-identity STABLE_ID",
                "Ln1 desktop screenshot --include-ocr true --max-ocr-characters 512",
                "Ln1 input key --key p --modifiers meta,shift"
            ],
            knownRisks: ["Electron trees often contain low-signal nested groups.", "Canvas-like widgets may require screenshots."],
            priority: "high"
        ),
        BenchmarkScenario(
            id: "visual-fallback-stress",
            app: "Visual fallback stress apps",
            category: "visual-only",
            bundleIdentifiers: [],
            surfaces: ["canvas apps", "custom controls", "video players", "maps", "games", "broken Accessibility trees"],
            requiredCapabilities: ["desktop screenshot", "browser screenshot", "OCR", "image metadata", "safe fallback when Accessibility trees fail"],
            successCriteria: [
                "Capture bounded screenshot metadata when structured UI trees are missing or misleading.",
                "Use OCR evidence to locate visible text without exposing full screen contents by default.",
                "Fail closed when visual evidence is insufficient to identify a safe target."
            ],
            verificationCommands: [
                "Ln1 desktop screenshot --allow-risk medium --include-ocr true --max-ocr-characters 512",
                "Ln1 browser screenshot --id TARGET_ID --allow-risk medium --endpoint ENDPOINT",
                "Ln1 state --pid PID --depth 2 --max-children 40",
                "Ln1 workflow preflight --operation inspect-active-window"
            ],
            knownRisks: ["Screenshots can include private visible content.", "Canvas, video, map, and game state may not expose semantic targets."],
            priority: "critical"
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
            verificationCommands: [
                "Ln1 apps list --name Word",
                "Ln1 state --pid PID --depth 4 --max-children 80",
                "Ln1 desktop screenshot --include-ocr true --max-ocr-characters 512",
                "Ln1 files checksum --path DOCUMENT_PATH"
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
            verificationCommands: [
                "Ln1 apps list --bundle-id com.apple.dt.Xcode",
                "Ln1 state --pid PID --depth 4 --max-children 80",
                "Ln1 processes wait --pid BUILD_PID --exists false",
                "Ln1 files watch --path DERIVED_DATA_OR_LOG_PATH"
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
            verificationCommands: [
                "Ln1 apps active",
                "Ln1 desktop active-window",
                "Ln1 input text --text TEXT",
                "Ln1 processes inspect --pid PID"
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
            verificationCommands: [
                "Ln1 apps list --bundle-id com.apple.systempreferences",
                "Ln1 desktop wait-window --bundle-id com.apple.systempreferences --title Privacy",
                "Ln1 state --pid PID --depth 4 --max-children 80",
                "Ln1 workflow preflight --operation inspect-active-window"
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
            verificationCommands: [
                "Ln1 desktop active-window",
                "Ln1 desktop windows --include-desktop",
                "Ln1 state wait-element --pid PID --element ELEMENT_ID --exists true",
                "Ln1 workflow next --operation wait-active-window"
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
