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
