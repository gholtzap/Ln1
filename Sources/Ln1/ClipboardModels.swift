import Foundation

struct ClipboardAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct ClipboardState: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let changeCount: Int
    let types: [String]
    let hasString: Bool
    let stringLength: Int?
    let stringDigest: String?
    let actions: [ClipboardAction]
}

struct ClipboardTextResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let changeCount: Int
    let hasString: Bool
    let text: String?
    let stringLength: Int?
    let stringDigest: String?
    let truncated: Bool
    let maxCharacters: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct ClipboardWriteResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let previous: ClipboardAuditSummary
    let current: ClipboardAuditSummary
    let writtenLength: Int
    let writtenDigest: String
    let rollbackSnapshotPath: String?
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct ClipboardRollbackResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let pasteboard: String
    let rollbackOfAuditID: String
    let previous: ClipboardAuditSummary
    let current: ClipboardAuditSummary
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct ClipboardRollbackSnapshot: Codable {
    let version: Int
    let auditID: String
    let savedAt: String
    let pasteboard: String
    let previousHadString: Bool
    let previousTextLength: Int?
    let previousTextDigest: String?
    let previousTextBase64: String?
}

struct ClipboardWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let changedFrom: Int?
    let expectedHasString: Bool?
    let expectedStringDigest: String?
    let current: ClipboardAuditSummary
    let matched: Bool
}

struct ClipboardWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let pasteboard: String
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let verification: ClipboardWaitVerification
    let message: String
}

struct ClipboardAuditSummary: Codable {
    let pasteboard: String
    let changeCount: Int
    let types: [String]
    let hasString: Bool
    let stringLength: Int?
    let stringDigest: String?
}
