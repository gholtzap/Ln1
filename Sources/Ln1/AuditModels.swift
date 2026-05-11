import Foundation

struct AuditPolicyDecision: Codable {
    let allowedRisk: String
    let actionRisk: String
    let allowed: Bool
    let message: String
}

struct FileAuditTarget: Codable {
    let path: String
    let id: String?
    let kind: String?
    let sizeBytes: Int?
    let exists: Bool?
}

struct FileOperationVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
}

struct FilePreflightCheck: Codable {
    let name: String
    let ok: Bool
    let code: String
    let message: String
}

struct FileOperationPreflight: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let source: FileAuditTarget?
    let destination: FileAuditTarget?
    let rollbackOfAuditID: String?
    let checks: [FilePreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct ActionAuditRecord: Codable {
    let id: String
    let timestamp: String
    let command: String
    let risk: String
    let reason: String?
    let app: AppRecord?
    let elementID: String?
    let element: AuditElementSummary?
    let action: String?
    var policy: AuditPolicyDecision? = nil
    var fileSource: FileAuditTarget? = nil
    var fileDestination: FileAuditTarget? = nil
    var fileRollbackSnapshotPath: String? = nil
    var verification: FileOperationVerification? = nil
    var identityVerification: IdentityVerification? = nil
    var clipboard: ClipboardAuditSummary? = nil
    var clipboardBefore: ClipboardAuditSummary? = nil
    var clipboardAfter: ClipboardAuditSummary? = nil
    var clipboardRollbackSnapshotPath: String? = nil
    var rollbackOfAuditID: String? = nil
    var appLaunchTarget: AppLaunchTargetSummary? = nil
    var workspaceOpenTarget: WorkspaceOpenTarget? = nil
    var workspaceOpenHandler: AppLaunchTargetSummary? = nil
    var valueLength: Int? = nil
    var valueDigest: String? = nil
    var currentValueLength: Int? = nil
    var currentValueDigest: String? = nil
    var browserTab: BrowserAuditSummary? = nil
    let outcome: AuditOutcome
}

struct AuditEntries: Codable {
    let path: String
    let id: String?
    let command: String?
    let code: String?
    let limit: Int
    let entries: [ActionAuditRecord]
}
