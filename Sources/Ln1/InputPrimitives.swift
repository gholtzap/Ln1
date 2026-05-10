import ApplicationServices
import Foundation

struct InputPoint: Codable {
    let x: Double
    let y: Double
}

struct InputPointerState: Codable {
    let generatedAt: String
    let platform: String
    let action: String
    let position: InputPoint?
    let available: Bool
    let message: String
}

struct InputMoveResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let dryRun: Bool
    let from: InputPoint?
    let to: InputPoint
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct InputDragResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let dryRun: Bool
    let from: InputPoint
    let to: InputPoint
    let steps: Int
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct InputScrollResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let dryRun: Bool
    let deltaX: Int32
    let deltaY: Int32
    let position: InputPoint?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct InputKeyResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let dryRun: Bool
    let key: String
    let keyCode: UInt16
    let modifiers: [String]
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct InputTextResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let dryRun: Bool
    let textLength: Int
    let textDigest: String
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

func currentPointerInputPoint() -> InputPoint? {
    guard let point = CGEvent(source: nil)?.location else {
        return nil
    }
    return InputPoint(x: point.x, y: point.y)
}

func pointerInputState(generatedAt: String = ISO8601DateFormatter().string(from: Date())) -> InputPointerState {
    let position = currentPointerInputPoint()
    return InputPointerState(
        generatedAt: generatedAt,
        platform: "macOS",
        action: "input.pointer",
        position: position,
        available: position != nil,
        message: position == nil
            ? "Pointer location was unavailable."
            : "Read current global pointer position."
    )
}

func warpPointerInput(to point: InputPoint) -> CGError {
    CGWarpMouseCursorPosition(CGPoint(x: point.x, y: point.y))
}

func dragPointerInput(from start: InputPoint, to end: InputPoint, steps: Int) -> Bool {
    let stepCount = max(1, steps)
    guard let down = CGEvent(
        mouseEventSource: nil,
        mouseType: .leftMouseDown,
        mouseCursorPosition: CGPoint(x: start.x, y: start.y),
        mouseButton: .left
    ) else {
        return false
    }
    down.post(tap: .cghidEventTap)

    for index in 1...stepCount {
        let progress = Double(index) / Double(stepCount)
        let point = CGPoint(
            x: start.x + ((end.x - start.x) * progress),
            y: start.y + ((end.y - start.y) * progress)
        )
        guard let drag = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDragged,
            mouseCursorPosition: point,
            mouseButton: .left
        ) else {
            return false
        }
        drag.post(tap: .cghidEventTap)
    }

    guard let up = CGEvent(
        mouseEventSource: nil,
        mouseType: .leftMouseUp,
        mouseCursorPosition: CGPoint(x: end.x, y: end.y),
        mouseButton: .left
    ) else {
        return false
    }
    up.post(tap: .cghidEventTap)
    return true
}

func scrollPointerInput(deltaX: Int32, deltaY: Int32) -> Bool {
    guard let event = CGEvent(
        scrollWheelEvent2Source: nil,
        units: .pixel,
        wheelCount: 2,
        wheel1: deltaY,
        wheel2: deltaX,
        wheel3: 0
    ) else {
        return false
    }
    event.post(tap: .cghidEventTap)
    return true
}

func inputKeyboardFlags(for modifiers: [String]) -> CGEventFlags {
    var flags = CGEventFlags()
    if modifiers.contains("shift") {
        flags.insert(.maskShift)
    }
    if modifiers.contains("control") {
        flags.insert(.maskControl)
    }
    if modifiers.contains("alt") {
        flags.insert(.maskAlternate)
    }
    if modifiers.contains("meta") {
        flags.insert(.maskCommand)
    }
    return flags
}

func postKeyInput(keyCode: CGKeyCode, modifiers: [String]) -> Bool {
    let flags = inputKeyboardFlags(for: modifiers)
    guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
          let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
        return false
    }
    down.flags = flags
    up.flags = flags
    down.post(tap: .cghidEventTap)
    up.post(tap: .cghidEventTap)
    return true
}

func postTextInput(_ text: String) -> Bool {
    for character in text {
        var units = Array(String(character).utf16)
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return false
        }
        down.keyboardSetUnicodeString(stringLength: units.count, unicodeString: &units)
        up.keyboardSetUnicodeString(stringLength: units.count, unicodeString: &units)
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
    return true
}

func inputKeyCode(for rawKey: String) -> CGKeyCode? {
    let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if key.count == 1, let scalar = key.unicodeScalars.first {
        switch scalar {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "=": return 24
        case "9": return 25
        case "7": return 26
        case "-": return 27
        case "8": return 28
        case "0": return 29
        case "]": return 30
        case "o": return 31
        case "u": return 32
        case "[": return 33
        case "i": return 34
        case "p": return 35
        case "l": return 37
        case "j": return 38
        case "'": return 39
        case "k": return 40
        case ";": return 41
        case "\\": return 42
        case ",": return 43
        case "/": return 44
        case "n": return 45
        case "m": return 46
        case ".": return 47
        case "`": return 50
        default: break
        }
    }

    switch key {
    case "return", "enter": return 36
    case "tab": return 48
    case "space": return 49
    case "delete", "backspace": return 51
    case "escape", "esc": return 53
    case "left": return 123
    case "right": return 124
    case "down": return 125
    case "up": return 126
    case "home": return 115
    case "end": return 119
    case "pageup", "page-up": return 116
    case "pagedown", "page-down": return 121
    case "f1": return 122
    case "f2": return 120
    case "f3": return 99
    case "f4": return 118
    case "f5": return 96
    case "f6": return 97
    case "f7": return 98
    case "f8": return 100
    case "f9": return 101
    case "f10": return 109
    case "f11": return 103
    case "f12": return 111
    default: return nil
    }
}

func pointerInputVerification(target: InputPoint, tolerance: Double) -> FileOperationVerification {
    guard let current = currentPointerInputPoint() else {
        return FileOperationVerification(
            ok: false,
            code: "pointer_unavailable",
            message: "pointer location was unavailable after move"
        )
    }

    let deltaX = abs(current.x - target.x)
    let deltaY = abs(current.y - target.y)
    if deltaX <= tolerance && deltaY <= tolerance {
        return FileOperationVerification(
            ok: true,
            code: "pointer_moved",
            message: "pointer location matched requested coordinates"
        )
    }

    return FileOperationVerification(
        ok: false,
        code: "pointer_mismatch",
        message: "pointer location did not match requested coordinates"
    )
}
