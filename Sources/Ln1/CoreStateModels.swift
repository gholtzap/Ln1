import Foundation

struct Rect: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

struct AppRecord: Codable {
    let name: String?
    let bundleIdentifier: String?
    let pid: Int32
    let hidden: Bool
}

struct ElementNode: Codable {
    let id: String
    let stableIdentity: StableIdentity
    let role: String?
    let subrole: String?
    let title: String?
    let value: String?
    let help: String?
    let enabled: Bool?
    let minimized: Bool?
    let frame: Rect?
    let actions: [String]
    let settableAttributes: [String]
    let valueSettable: Bool
    let children: [ElementNode]
}

struct ComputerState: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let windows: [ElementNode]
}

struct AccessibilityElementInspectResult: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let element: ElementNode
    let identityVerification: IdentityVerification?
    let depth: Int
    let maxChildren: Int
    let message: String
}

struct AccessibilityElementFindQuery: Codable {
    let role: String?
    let subrole: String?
    let title: String?
    let value: String?
    let help: String?
    let action: String?
    let enabled: Bool?
    let match: String
    let includeMenu: Bool
}

struct AccessibilityElementFindResult: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let query: AccessibilityElementFindQuery
    let depth: Int
    let maxChildren: Int
    let resultDepth: Int
    let resultMaxChildren: Int
    let limit: Int
    let count: Int
    let truncated: Bool
    let matches: [ElementNode]
    let message: String
}

struct AccessibilityElementWaitTarget: Codable {
    let element: String
    let expectedIdentity: String?
    let minimumConfidence: String?
    let title: String?
    let value: String?
    let match: String
    let enabled: Bool?
}

struct AccessibilityElementWaitVerification: Codable {
    let ok: Bool
    let code: String
    let message: String
    let target: AccessibilityElementWaitTarget
    let expectedExists: Bool
    let current: ElementNode?
    let identityVerification: IdentityVerification?
    let titleMatched: Bool?
    let valueMatched: Bool?
    let enabledMatched: Bool?
    let matched: Bool
}

struct AccessibilityElementWaitResult: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let timeoutMilliseconds: Int
    let intervalMilliseconds: Int
    let depth: Int
    let maxChildren: Int
    let verification: AccessibilityElementWaitVerification
    let message: String
}

struct AccessibilityMenuState: Codable {
    let generatedAt: String
    let platform: String
    let app: AppRecord
    let menuBar: ElementNode?
    let depth: Int
    let maxChildren: Int
    let message: String
}

struct AppState: Codable {
    let app: AppRecord
    let windows: [ElementNode]
}

struct AllComputerState: Codable {
    let generatedAt: String
    let platform: String
    let apps: [AppState]
}

struct SystemContextState: Codable {
    let generatedAt: String
    let platform: String
    let hostName: String
    let userName: String
    let homeDirectory: String
    let currentDirectory: String
    let shellPath: String?
    let processIdentifier: Int32
    let executablePath: String?
    let operatingSystemVersion: String
    let operatingSystemVersionString: String
    let architecture: String
    let processorCount: Int
    let activeProcessorCount: Int
    let physicalMemoryBytes: UInt64
    let systemUptimeSeconds: Double
    let timeZoneIdentifier: String
    let localeIdentifier: String
}
