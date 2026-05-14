import ApplicationServices
import Foundation

extension Ln1CLI {
    func input() throws {
        let mode = arguments.dropFirst().first ?? "pointer"

        switch mode {
        case "pointer", "position":
            try writeJSON(pointerInputState())
        case "move":
            try writeJSON(inputMovePointer())
        case "drag":
            try writeJSON(inputDragPointer())
        case "scroll":
            try writeJSON(inputScrollWheel())
        case "key", "hotkey":
            try writeJSON(inputPressKey())
        case "undo":
            try writeJSON(inputUndo())
        case "type", "text":
            try writeJSON(inputTypeText())
        default:
            throw CommandError(description: "unknown input mode '\(mode)'")
        }
    }

    func inputMovePointer() throws -> InputMoveResult {
        let action = "input.movePointer"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let target = InputPoint(
            x: try requiredDoubleOption("--x"),
            y: try requiredDoubleOption("--y")
        )
        let from = currentPointerInputPoint()
        let dryRun = option("--dry-run").map(parseBool) ?? false
        let tolerance = max(0, option("--tolerance").flatMap(Double.init) ?? 2.0)
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.move",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "pointer move was validated without moving the cursor"
                )
                let message = "Validated pointer move to (\(target.x), \(target.y)) without moving the cursor."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputMoveResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    from: from,
                    to: target,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            let result = warpPointerInput(to: target)
            guard result == .success else {
                let message = "CGWarpMouseCursorPosition failed with \(result)"
                verification = FileOperationVerification(ok: false, code: "move_failed", message: message)
                try writeAudit(ok: false, code: "move_failed", message: message)
                throw CommandError(description: message)
            }

            verification = pointerInputVerification(target: target, tolerance: tolerance)
            guard verification?.ok == true else {
                let message = verification?.message ?? "pointer move verification failed"
                try writeAudit(ok: false, code: verification?.code ?? "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Moved pointer to (\(target.x), \(target.y))."
            try writeAudit(ok: true, code: "pointer_moved", message: message)
            return InputMoveResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                from: from,
                to: target,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func inputDragPointer() throws -> InputDragResult {
        let action = "input.dragPointer"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let start = InputPoint(
            x: try requiredDoubleOption("--from-x"),
            y: try requiredDoubleOption("--from-y")
        )
        let target = InputPoint(
            x: try requiredDoubleOption("--to-x"),
            y: try requiredDoubleOption("--to-y")
        )
        let dryRun = option("--dry-run").map(parseBool) ?? false
        let steps = min(240, max(1, option("--steps").flatMap(Int.init) ?? 16))
        let tolerance = max(0, option("--tolerance").flatMap(Double.init) ?? 2.0)
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.drag",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "pointer drag was validated without posting input events"
                )
                let message = "Validated pointer drag from (\(start.x), \(start.y)) to (\(target.x), \(target.y)) without posting input events."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputDragResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    from: start,
                    to: target,
                    steps: steps,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            let warpResult = warpPointerInput(to: start)
            guard warpResult == .success else {
                let message = "CGWarpMouseCursorPosition failed with \(warpResult)"
                verification = FileOperationVerification(ok: false, code: "move_failed", message: message)
                try writeAudit(ok: false, code: "move_failed", message: message)
                throw CommandError(description: message)
            }

            guard dragPointerInput(from: start, to: target, steps: steps) else {
                let message = "failed to create pointer drag events"
                verification = FileOperationVerification(ok: false, code: "drag_failed", message: message)
                try writeAudit(ok: false, code: "drag_failed", message: message)
                throw CommandError(description: message)
            }

            verification = pointerInputVerification(target: target, tolerance: tolerance)
            guard verification?.ok == true else {
                let message = verification?.message ?? "pointer drag verification failed"
                try writeAudit(ok: false, code: verification?.code ?? "verification_failed", message: message)
                throw CommandError(description: message)
            }

            let message = "Dragged pointer from (\(start.x), \(start.y)) to (\(target.x), \(target.y))."
            try writeAudit(ok: true, code: "pointer_dragged", message: message)
            return InputDragResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                from: start,
                to: target,
                steps: steps,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func inputScrollWheel() throws -> InputScrollResult {
        let action = "input.scrollWheel"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let deltaX = try optionalInt32Option("--dx") ?? 0
        let deltaY = try optionalInt32Option("--dy") ?? 0
        let position = currentPointerInputPoint()
        let dryRun = option("--dry-run").map(parseBool) ?? false
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.scroll",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }
            guard deltaX != 0 || deltaY != 0 else {
                let message = "input scroll requires a non-zero --dx or --dy"
                try writeAudit(ok: false, code: "zero_delta", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "scroll input was validated without posting input events"
                )
                let message = "Validated scroll delta (\(deltaX), \(deltaY)) without posting input events."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputScrollResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    deltaX: deltaX,
                    deltaY: deltaY,
                    position: position,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            guard scrollPointerInput(deltaX: deltaX, deltaY: deltaY) else {
                let message = "failed to create scroll input event"
                verification = FileOperationVerification(ok: false, code: "scroll_failed", message: message)
                try writeAudit(ok: false, code: "scroll_failed", message: message)
                throw CommandError(description: message)
            }

            verification = FileOperationVerification(
                ok: true,
                code: "scroll_posted",
                message: "scroll input event was posted"
            )
            let message = "Posted scroll delta (\(deltaX), \(deltaY))."
            try writeAudit(ok: true, code: "scroll_posted", message: message)
            return InputScrollResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                deltaX: deltaX,
                deltaY: deltaY,
                position: position,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func inputPressKey() throws -> InputKeyResult {
        let action = "input.pressKey"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let key = try requiredOption("--key")
        guard let keyCode = inputKeyCode(for: key) else {
            throw CommandError(description: "unsupported input key '\(key)'")
        }
        let modifierSet = try browserModifierSet(option("--modifiers"))
        let dryRun = option("--dry-run").map(parseBool) ?? false
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.key",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "keyboard input was validated without posting input events"
                )
                let message = "Validated key input '\(key)' without posting input events."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputKeyResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    key: key,
                    keyCode: keyCode,
                    modifiers: modifierSet,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            guard postKeyInput(keyCode: keyCode, modifiers: modifierSet) else {
                let message = "failed to create keyboard input event"
                verification = FileOperationVerification(ok: false, code: "key_failed", message: message)
                try writeAudit(ok: false, code: "key_failed", message: message)
                throw CommandError(description: message)
            }

            verification = FileOperationVerification(ok: true, code: "key_posted", message: "keyboard input event was posted")
            let message = "Posted key input '\(key)'."
            try writeAudit(ok: true, code: "key_posted", message: message)
            return InputKeyResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                key: key,
                keyCode: keyCode,
                modifiers: modifierSet,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func inputUndo() throws -> InputKeyResult {
        let action = "input.undo"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let key = "z"
        guard let keyCode = inputKeyCode(for: key) else {
            throw CommandError(description: "unsupported input undo key '\(key)'")
        }
        let modifierSet = ["meta"]
        let dryRun = option("--dry-run").map(parseBool) ?? false
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.undo",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "undo input was validated without posting input events"
                )
                let message = "Validated undo input without posting input events."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputKeyResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    key: key,
                    keyCode: keyCode,
                    modifiers: modifierSet,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            guard postKeyInput(keyCode: keyCode, modifiers: modifierSet) else {
                let message = "failed to create undo input event"
                verification = FileOperationVerification(ok: false, code: "undo_failed", message: message)
                try writeAudit(ok: false, code: "undo_failed", message: message)
                throw CommandError(description: message)
            }

            verification = FileOperationVerification(ok: true, code: "undo_posted", message: "undo input event was posted")
            let message = "Posted undo input."
            try writeAudit(ok: true, code: "undo_posted", message: message)
            return InputKeyResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                key: key,
                keyCode: keyCode,
                modifiers: modifierSet,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

    func inputTypeText() throws -> InputTextResult {
        let action = "input.typeText"
        let risk = inputActionRisk(for: action)
        let policy = policyDecision(actionRisk: risk)
        let auditID = UUID().uuidString
        let auditURL = try auditLogURL()
        let text = try requiredOption("--text")
        let dryRun = option("--dry-run").map(parseBool) ?? false
        let textLength = text.count
        let textDigest = sha256Digest(text)
        var verification: FileOperationVerification?
        var auditWritten = false

        func writeAudit(ok: Bool, code: String, message: String) throws {
            try appendAuditRecord(ActionAuditRecord(
                id: auditID,
                timestamp: ISO8601DateFormatter().string(from: Date()),
                command: "input.type",
                risk: risk,
                reason: option("--reason"),
                app: nil,
                elementID: nil,
                element: nil,
                action: action,
                policy: policy,
                verification: verification,
                outcome: AuditOutcome(ok: ok, code: code, message: message)
            ), to: auditURL)
            auditWritten = true
        }

        do {
            guard policy.allowed else {
                let message = policy.message
                try writeAudit(ok: false, code: "policy_denied", message: message)
                throw CommandError(description: message)
            }
            guard !text.isEmpty else {
                let message = "input type requires non-empty --text"
                try writeAudit(ok: false, code: "empty_text", message: message)
                throw CommandError(description: message)
            }

            if dryRun {
                verification = FileOperationVerification(
                    ok: true,
                    code: "dry_run",
                    message: "text input was validated without posting input events"
                )
                let message = "Validated text input of \(textLength) characters without posting input events."
                try writeAudit(ok: true, code: "dry_run", message: message)
                return InputTextResult(
                    ok: true,
                    action: action,
                    risk: risk,
                    dryRun: true,
                    textLength: textLength,
                    textDigest: textDigest,
                    verification: verification!,
                    auditID: auditID,
                    auditLogPath: auditURL.path,
                    message: message
                )
            }

            guard postTextInput(text) else {
                let message = "failed to create text input events"
                verification = FileOperationVerification(ok: false, code: "type_failed", message: message)
                try writeAudit(ok: false, code: "type_failed", message: message)
                throw CommandError(description: message)
            }

            verification = FileOperationVerification(ok: true, code: "text_posted", message: "text input events were posted")
            let message = "Posted text input of \(textLength) characters."
            try writeAudit(ok: true, code: "text_posted", message: message)
            return InputTextResult(
                ok: true,
                action: action,
                risk: risk,
                dryRun: false,
                textLength: textLength,
                textDigest: textDigest,
                verification: verification!,
                auditID: auditID,
                auditLogPath: auditURL.path,
                message: message
            )
        } catch let error as CommandError {
            if !auditWritten {
                try writeAudit(ok: false, code: "rejected", message: error.description)
            }
            throw error
        } catch {
            let message = error.localizedDescription
            if !auditWritten {
                try writeAudit(ok: false, code: "failed", message: message)
            }
            throw CommandError(description: message)
        }
    }

}
