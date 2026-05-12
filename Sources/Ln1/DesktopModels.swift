import Foundation

struct DesktopWindowRecord: Codable {
    let id: String
    let stableIdentity: StableIdentity
    let windowNumber: UInt32
    let ownerName: String?
    let ownerBundleIdentifier: String?
    let ownerPID: Int32
    let active: Bool
    let title: String?
    let layer: Int
    let bounds: Rect?
    let onscreen: Bool?
    let alpha: Double?
    let memoryUsageBytes: Int?
    let sharingState: Int?
}

struct StableIdentity: Codable {
    let id: String
    let kind: String
    let confidence: String
    let label: String
    let components: [String: String]
    let reasons: [String]
}

struct DesktopWindowsState: Codable {
    let generatedAt: String
    let platform: String
    let available: Bool
    let message: String
    let activePID: Int32?
    let includeDesktop: Bool
    let includeAllLayers: Bool
    let filter: DesktopWindowWaitTarget?
    let limit: Int
    let count: Int
    let truncated: Bool
    let windows: [DesktopWindowRecord]
}

struct DesktopActiveWindowState: Codable {
    let generatedAt: String
    let platform: String
    let available: Bool
    let found: Bool
    let message: String
    let activePID: Int32?
    let app: AppRecord?
    let window: DesktopWindowRecord?
}

struct DesktopWindowWaitTarget: Codable {
    let id: String?
    let ownerPID: Int32?
    let bundleIdentifier: String?
    let title: String?
    let titleMatch: String
}

struct DesktopWindowWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: DesktopWindowWaitTarget
    let expectedExists: Bool
    let currentCount: Int
    let current: [DesktopWindowRecord]
    let matched: Bool
}

struct DesktopWindowWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let includeDesktop: Bool
    let includeAllLayers: Bool
    let limit: Int
    let verification: DesktopWindowWaitVerification
    let message: String
}

struct DesktopActiveWindowWaitTarget: Codable {
    let id: String?
    let ownerPID: Int32?
    let bundleIdentifier: String?
    let title: String?
    let titleMatch: String
    let changedFrom: String?
}

struct DesktopActiveWindowWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: DesktopActiveWindowWaitTarget
    let current: DesktopWindowRecord?
    let found: Bool
    let changed: Bool
    let matched: Bool
}

struct DesktopActiveWindowWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: DesktopActiveWindowWaitVerification
    let message: String
}

struct DesktopMinimizeWindowResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let app: AppRecord
    let elementID: String
    let window: AuditElementSummary
    let minimizedBefore: Bool?
    let minimizedAfter: Bool?
    let verification: FileOperationVerification
    let identityVerification: IdentityVerification?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct DesktopRaiseWindowResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let app: AppRecord
    let elementID: String
    let window: AuditElementSummary
    let verification: FileOperationVerification
    let identityVerification: IdentityVerification?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct DesktopSetWindowFrameResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let app: AppRecord
    let elementID: String
    let window: AuditElementSummary
    let requestedFrame: Rect
    let frameBefore: Rect?
    let frameAfter: Rect?
    let verification: FileOperationVerification
    let identityVerification: IdentityVerification?
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct DesktopDisplayRecord: Codable {
    let id: String
    let displayID: UInt32
    let name: String?
    let main: Bool
    let active: Bool
    let online: Bool
    let builtin: Bool
    let inMirrorSet: Bool
    let bounds: Rect
    let pixelWidth: Int
    let pixelHeight: Int
    let scaleFactor: Double?
    let rotationDegrees: Double
    let colorSpaceName: String?
}

struct DesktopDisplaysState: Codable {
    let generatedAt: String
    let platform: String
    let available: Bool
    let message: String
    let count: Int
    let displays: [DesktopDisplayRecord]
}
