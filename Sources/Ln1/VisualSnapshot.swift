import AppKit
import CryptoKit
import Foundation
#if canImport(Vision)
import Vision
#endif

struct VisualSnapshotOCR: Codable {
    let requested: Bool
    let available: Bool
    let observationCount: Int
    let textLength: Int
    let text: String?
    let textDigest: String?
    let truncated: Bool
    let message: String
}

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
    let ocr: VisualSnapshotOCR?
    let message: String
}

struct VisualSnapshotState: Codable {
    let generatedAt: String
    let platform: String
    let action: String
    let risk: String
    let maxSampleBytes: Int
    let includeOCR: Bool
    let maxOCRCharacters: Int
    let targetDisplayID: UInt32?
    let displayCount: Int
    let displays: [VisualSnapshotDisplay]
    let message: String
}

func desktopVisualSnapshot(
    targetDisplayID: UInt32?,
    maxSampleBytes: Int,
    includeOCR: Bool = false,
    maxOCRCharacters: Int = 4_096,
    generatedAt: String = ISO8601DateFormatter().string(from: Date())
) -> VisualSnapshotState {
    let displayIDs = onlineDisplayIDs()
    let selectedDisplayIDs: [CGDirectDisplayID]
    if let targetDisplayID {
        selectedDisplayIDs = displayIDs.filter { $0 == CGDirectDisplayID(targetDisplayID) }
    } else {
        selectedDisplayIDs = displayIDs
    }
    let displays = selectedDisplayIDs.map {
        visualSnapshotDisplay(
            $0,
            maxSampleBytes: maxSampleBytes,
            includeOCR: includeOCR,
            maxOCRCharacters: maxOCRCharacters
        )
    }
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
        includeOCR: includeOCR,
        maxOCRCharacters: maxOCRCharacters,
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

private func visualSnapshotDisplay(
    _ displayID: CGDirectDisplayID,
    maxSampleBytes: Int,
    includeOCR: Bool,
    maxOCRCharacters: Int
) -> VisualSnapshotDisplay {
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
            ocr: includeOCR ? VisualSnapshotOCR(
                requested: true,
                available: false,
                observationCount: 0,
                textLength: 0,
                text: nil,
                textDigest: nil,
                truncated: false,
                message: "OCR was unavailable because display image capture was unavailable."
            ) : nil,
            message: "Display image capture was unavailable."
        )
    }

    let bytes = data as Data
    let sample = bytes.prefix(max(0, maxSampleBytes))
    let ocr = visualOCRSnapshot(from: image, requested: includeOCR, maxCharacters: maxOCRCharacters)
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
        ocr: ocr,
        message: includeOCR
            ? "Captured display image metadata, bounded byte-sample digest, and bounded OCR metadata."
            : "Captured display image metadata and bounded byte-sample digest."
    )
}

private func visualOCRSnapshot(
    from image: CGImage,
    requested: Bool,
    maxCharacters: Int
) -> VisualSnapshotOCR? {
    guard requested else {
        return nil
    }

    #if canImport(Vision)
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .fast
    request.usesLanguageCorrection = false

    do {
        try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])
        let strings = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .filter { !$0.isEmpty }
        let combined = strings.joined(separator: "\n")
        let limit = max(0, maxCharacters)
        let text = String(combined.prefix(limit))
        let textData = Data(combined.utf8)

        return VisualSnapshotOCR(
            requested: true,
            available: true,
            observationCount: strings.count,
            textLength: combined.count,
            text: text.isEmpty ? nil : text,
            textDigest: textData.isEmpty ? nil : visualSHA256Hex(textData),
            truncated: combined.count > text.count,
            message: strings.isEmpty
                ? "OCR completed without recognized text."
                : "OCR completed with bounded recognized text."
        )
    } catch {
        return VisualSnapshotOCR(
            requested: true,
            available: false,
            observationCount: 0,
            textLength: 0,
            text: nil,
            textDigest: nil,
            truncated: false,
            message: "OCR failed: \(error.localizedDescription)"
        )
    }
    #else
    return VisualSnapshotOCR(
        requested: true,
        available: false,
        observationCount: 0,
        textLength: 0,
        text: nil,
        textDigest: nil,
        truncated: false,
        message: "OCR is unavailable because the Vision framework is not available."
    )
    #endif
}

private func visualSHA256Hex<D: DataProtocol>(_ data: D) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}
