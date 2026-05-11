import Foundation

struct FileAction: Codable {
    let name: String
    let risk: String
    let mutates: Bool
}

struct FileRecord: Codable {
    let id: String
    let path: String
    let name: String
    let kind: String
    let sizeBytes: Int?
    let createdAt: String?
    let modifiedAt: String?
    let hidden: Bool
    let readable: Bool
    let writable: Bool
    let actions: [FileAction]
}

struct FilesystemState: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let entries: [FileRecord]
    let maxDepth: Int
    let limit: Int
    let truncated: Bool
}

struct FileLineMatch: Codable {
    let lineNumber: Int
    let text: String
}

struct FileSearchMatch: Codable {
    let file: FileRecord
    let matchedName: Bool
    let contentMatches: [FileLineMatch]
}

struct FilesystemSearchResult: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let query: String
    let caseSensitive: Bool
    let maxDepth: Int
    let limit: Int
    let includeHidden: Bool
    let maxFileBytes: Int
    let maxSnippetCharacters: Int
    let maxMatchesPerFile: Int
    let matches: [FileSearchMatch]
    let scannedFiles: Int
    let skippedUnreadable: Int
    let skippedBinary: Int
    let skippedTooLarge: Int
    let truncated: Bool
}

struct FilesystemTextResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let text: String
    let selection: String
    let textLength: Int
    let textDigest: String
    let byteLength: Int
    let truncated: Bool
    let maxCharacters: Int
    let maxFileBytes: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct FilesystemLinesResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let startLine: Int
    let requestedLineCount: Int
    let returnedLineCount: Int
    let totalLineCount: Int
    let lines: [FileLineMatch]
    let truncated: Bool
    let maxLineCharacters: Int
    let maxFileBytes: Int
    let textDigest: String
    let byteLength: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BoundedJSONProperty: Encodable {
    let key: String
    let value: BoundedJSONNode
}

struct BoundedJSONNode: Encodable {
    let type: String
    let value: JSONValue?
    let entries: [BoundedJSONProperty]?
    let items: [BoundedJSONNode]?
    let count: Int?
    let truncated: Bool
}

struct FilesystemJSONResult: Encodable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let pointer: String?
    let found: Bool
    let valueType: String?
    let value: BoundedJSONNode?
    let truncated: Bool
    let maxDepth: Int
    let maxItems: Int
    let maxStringCharacters: Int
    let maxFileBytes: Int
    let textDigest: String
    let byteLength: Int
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct BoundedPropertyListProperty: Encodable {
    let key: String
    let value: BoundedPropertyListNode
}

struct BoundedPropertyListNode: Encodable {
    let type: String
    let value: JSONValue?
    let entries: [BoundedPropertyListProperty]?
    let items: [BoundedPropertyListNode]?
    let count: Int?
    let dataDigest: String?
    let truncated: Bool
}

struct FilesystemPropertyListResult: Encodable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let pointer: String?
    let found: Bool
    let valueType: String?
    let value: BoundedPropertyListNode?
    let truncated: Bool
    let maxDepth: Int
    let maxItems: Int
    let maxStringCharacters: Int
    let maxFileBytes: Int
    let format: String
    let byteLength: Int
    let digest: String
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct FilesystemWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let path: String
    let expectedExists: Bool
    let expectedSizeBytes: Int?
    let expectedDigest: String?
    let algorithm: String?
    let maxFileBytes: Int?
    let matched: Bool
    let sizeMatched: Bool?
    let digestMatched: Bool?
    let currentDigest: String?
    let elapsedMilliseconds: Int
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let file: FileRecord?
    let message: String
}

struct FileWatchEvent: Codable {
    let id: String
    let type: String
    let path: String
    let previous: FileRecord?
    let current: FileRecord?
}

struct FilesystemWatchResult: Codable {
    let generatedAt: String
    let platform: String
    let root: FileRecord
    let maxDepth: Int
    let limit: Int
    let includeHidden: Bool
    let matched: Bool
    let events: [FileWatchEvent]
    let eventCount: Int
    let beforeCount: Int
    let afterCount: Int
    let beforeTruncated: Bool
    let afterTruncated: Bool
    let elapsedMilliseconds: Int
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let message: String
}

struct FilesystemChecksumResult: Codable {
    let generatedAt: String
    let platform: String
    let file: FileRecord
    let algorithm: String
    let digest: String
    let maxFileBytes: Int
}

struct FilesystemCompareResult: Codable {
    let generatedAt: String
    let platform: String
    let left: FileRecord
    let right: FileRecord
    let algorithm: String
    let leftDigest: String
    let rightDigest: String
    let sameSize: Bool
    let sameDigest: Bool
    let matched: Bool
    let maxFileBytes: Int
}

struct FileOperationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let source: FileRecord
    let destination: FileRecord
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileTextWriteResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let path: String
    let created: Bool
    let overwritten: Bool
    let previous: FileAuditTarget
    let current: FileRecord
    let writtenLength: Int
    let writtenBytes: Int
    let writtenDigest: String
    let rollbackSnapshotPath: String?
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileTextAppendResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let path: String
    let created: Bool
    let previous: FileAuditTarget
    let current: FileRecord
    let appendedLength: Int
    let appendedBytes: Int
    let appendedDigest: String
    let finalBytes: Int
    let rollbackSnapshotPath: String?
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileTextRollbackResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let rollbackOfAuditID: String
    let path: String
    let previous: FileAuditTarget
    let current: FileAuditTarget
    let verification: FileOperationVerification
    let auditID: String
    let auditLogPath: String
    let message: String
}

struct FileTextRollbackSnapshot: Codable {
    let version: Int
    let auditID: String
    let savedAt: String
    let path: String
    let previousExists: Bool
    let previousTextLength: Int?
    let previousTextDigest: String?
    let previousTextBase64: String?
}

struct DirectoryOperationResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let directory: FileRecord
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}

struct FileRollbackResult: Codable {
    let ok: Bool
    let action: String
    let risk: String
    let rollbackOfAuditID: String
    let restoredSource: FileRecord
    let previousDestination: FileAuditTarget
    let verification: FileOperationVerification
    let message: String
    let auditID: String
    let auditLogPath: String
}
