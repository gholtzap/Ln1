import Foundation

struct AppSummary: Codable {
    let name: String?
    let bundleIdentifier: String?
    let pid: Int32
    let active: Bool
    let hidden: Bool
}

struct RunningAppsState: Codable {
    let generatedAt: String
    let platform: String
    let includeAll: Bool
    let limit: Int
    let count: Int
    let truncated: Bool
    let activeApp: AppSummary?
    let apps: [AppSummary]
    let message: String
}

struct ActiveAppState: Codable {
    let generatedAt: String
    let platform: String
    let found: Bool
    let app: AppRecord?
    let message: String
}

struct InstalledAppRecord: Codable {
    let name: String
    let bundleIdentifier: String?
    let path: String
    let version: String?
    let executablePath: String?
}

struct InstalledAppsState: Codable {
    let generatedAt: String
    let platform: String
    let searchRoots: [String]
    let limit: Int
    let count: Int
    let truncated: Bool
    let apps: [InstalledAppRecord]
    let message: String
}

struct AppPreflightCheck: Codable {
    let name: String
    let ok: Bool
    let code: String
    let message: String
}

struct AppLaunchTargetSummary: Codable {
    let name: String?
    let bundleIdentifier: String?
    let path: String
}

struct AppActivationPlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppRecord
    let activeBefore: AppRecord?
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppLaunchPlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppLaunchTargetSummary
    let activeBefore: AppRecord?
    let runningApp: AppRecord?
    let activate: Bool
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppHidePlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppRecord
    let activeBefore: AppRecord?
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppQuitPlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppRecord
    let activeBefore: AppRecord?
    let force: Bool
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppLaunchResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppLaunchTargetSummary
    let app: AppRecord?
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let activate: Bool
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppHideResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppRecord
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let hiddenBefore: Bool
    let hiddenAfter: Bool
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppUnhidePlan: Codable {
    let generatedAt: String
    let platform: String
    let operation: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: AppRecord
    let activeBefore: AppRecord?
    let checks: [AppPreflightCheck]
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct AppUnhideResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppRecord
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let hiddenBefore: Bool
    let hiddenAfter: Bool
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppQuitResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppRecord
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let force: Bool
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct WorkspaceOpenTarget: Codable {
    let kind: String
    let path: String?
    let url: String
    let scheme: String
    let host: String?
    let file: FileAuditTarget?
}

struct WorkspaceOpenPlan: Codable {
    let generatedAt: String
    let platform: String
    let action: String
    let risk: String
    let actionMutates: Bool
    let policy: AuditPolicyDecision
    let target: WorkspaceOpenTarget
    let handler: AppLaunchTargetSummary?
    let activeBefore: AppRecord?
    let canExecute: Bool
    let requiredAllowRisk: String
    let message: String
}

struct WorkspaceOpenResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: WorkspaceOpenTarget
    let handler: AppLaunchTargetSummary?
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppActivationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let target: AppRecord
    let activeBefore: AppRecord?
    let activeAfter: AppRecord?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct AppActiveWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: AppRecord
    let current: AppRecord?
    let matched: Bool
}

struct AppActiveWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: AppActiveWaitVerification
    let message: String
}
