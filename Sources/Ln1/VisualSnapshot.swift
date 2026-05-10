import AppKit
import CryptoKit
import Foundation

struct VisualSnapshotDisplay: Codable {
    let id: String
    let displayID: UInt32
    let bounds: Rect
    let pixelWidth: Int
    let pixelHeight: Int
    let captured: Bool
    let imageWidth: Int?
    let imageHeight: Int?
    let bitsPerPixel: Int?
    let bytesPerRow: Int?
    let sampleByteCount: Int
    let fullByteCount: Int?
    let sampleDigest: String?
    let message: String
}

struct VisualSnapshotState: Codable {
    let generatedAt: String
    let platform: String
    let action: String
    let risk: String
    let maxSampleBytes: Int
    let targetDisplayID: UInt32?
    let displayCount: Int
    let displays: [VisualSnapshotDisplay]
    let message: String
}

func desktopVisualSnapshot(
    targetDisplayID: UInt32?,
    maxSampleBytes: Int,
    generatedAt: String = ISO8601DateFormatter().string(from: Date())
) -> VisualSnapshotState {
    let displayIDs = onlineDisplayIDs()
    let selectedDisplayIDs: [CGDirectDisplayID]
    if let targetDisplayID {
        selectedDisplayIDs = displayIDs.filter { $0 == CGDirectDisplayID(targetDisplayID) }
    } else {
        selectedDisplayIDs = displayIDs
    }
    let displays = selectedDisplayIDs.map { visualSnapshotDisplay($0, maxSampleBytes: maxSampleBytes) }
    let message: String
    if selectedDisplayIDs.isEmpty {
        message = targetDisplayID == nil
            ? "No online displays were reported by CoreGraphics."
            : "No online display matched the requested display ID."
    } else if displays.contains(where: { !$0.captured }) {
        message = "One or more display images were unavailable. Grant Screen Recording permission if pixel capture is required."
    } else {
        message = "Captured bounded visual display snapshots."
    }

    return VisualSnapshotState(
        generatedAt: generatedAt,
        platform: "macOS",
        action: "desktop.screenshot",
        risk: "medium",
        maxSampleBytes: maxSampleBytes,
        targetDisplayID: targetDisplayID,
        displayCount: displays.count,
        displays: displays,
        message: message
    )
}

private func onlineDisplayIDs() -> [CGDirectDisplayID] {
    let maxDisplays: UInt32 = 32
    var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
    var displayCount: UInt32 = 0
    let result = CGGetOnlineDisplayList(maxDisplays, &displayIDs, &displayCount)
    guard result == .success else {
        return []
    }
    return Array(displayIDs.prefix(Int(displayCount)))
}

private func visualSnapshotDisplay(_ displayID: CGDirectDisplayID, maxSampleBytes: Int) -> VisualSnapshotDisplay {
    let bounds = CGDisplayBounds(displayID)
    let rect = Rect(
        x: bounds.origin.x,
        y: bounds.origin.y,
        width: bounds.size.width,
        height: bounds.size.height
    )
    guard let image = CGDisplayCreateImage(displayID),
          let provider = image.dataProvider,
          let data = provider.data else {
        return VisualSnapshotDisplay(
            id: "display:\(displayID)",
            displayID: displayID,
            bounds: rect,
            pixelWidth: CGDisplayPixelsWide(displayID),
            pixelHeight: CGDisplayPixelsHigh(displayID),
            captured: false,
            imageWidth: nil,
            imageHeight: nil,
            bitsPerPixel: nil,
            bytesPerRow: nil,
            sampleByteCount: 0,
            fullByteCount: nil,
            sampleDigest: nil,
            message: "Display image capture was unavailable."
        )
    }

    let bytes = data as Data
    let sample = bytes.prefix(max(0, maxSampleBytes))
    return VisualSnapshotDisplay(
        id: "display:\(displayID)",
        displayID: displayID,
        bounds: rect,
        pixelWidth: CGDisplayPixelsWide(displayID),
        pixelHeight: CGDisplayPixelsHigh(displayID),
        captured: true,
        imageWidth: image.width,
        imageHeight: image.height,
        bitsPerPixel: image.bitsPerPixel,
        bytesPerRow: image.bytesPerRow,
        sampleByteCount: sample.count,
        fullByteCount: bytes.count,
        sampleDigest: visualSHA256Hex(sample),
        message: "Captured display image metadata and bounded byte-sample digest."
    )
}

private func visualSHA256Hex<D: DataProtocol>(_ data: D) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
