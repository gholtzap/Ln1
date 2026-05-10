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
