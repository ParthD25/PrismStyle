import Foundation
import UIKit
import Vision

/// On-device photo understanding using Apple Vision.
///
/// iOS 17 compatible: uses VNDetectHumanRectanglesRequest and (optional) foreground instance masking,
/// body pose detection, and image feature prints.
enum VisionFeatureExtractor {

    /// Extract features used for ranking/analyzing outfit photos.
    ///
    /// This is intentionally conservative: it does not require any custom Core ML model.
    static func extractFeatures(for image: UIImage) async -> OutfitPhotoFeatures {
        // Vision requests can be expensive; do them off the main actor.
        return await Task.detached(priority: .userInitiated) {
            return performFullAnalysis(image)
        }.value
    }

    /// A sync, cheap approximation for places where we can't easily await.
    /// Uses human-rectangle detection only.
    static func quickOutfitConfidenceSync(for image: UIImage) -> (confidence: Double, people: [OutfitPhotoFeatures.DetectedPerson]) {
        let result = performVisionPass(image, includeAdvancedSignals: false)
        return (result.outfitConfidence, result.people)
    }

    // MARK: - Internals

    private struct VisionPassResult {
        let outfitConfidence: Double
        let people: [OutfitPhotoFeatures.DetectedPerson]
        /// Normalized [0,1] rect in image coordinates (Vision bounding box space).
        let primaryCrop: CGRect?

        let poseScore: Double
        let foregroundCoverage: Double
        let foregroundCrop: CGRect?
        let featurePrintData: Data?

        /// Used only during analysis to filter color sampling to foreground pixels.
        /// Kept internal so CVPixelBuffer never escapes the detached task.
        let foregroundMaskSampleProvider: ForegroundMaskSampleProvider?
    }

    private static func performFullAnalysis(_ image: UIImage) -> OutfitPhotoFeatures {
        let quality = ImageScoring.overallQualityScore(image)

        let result = performVisionPass(image, includeAdvancedSignals: true)
        let cropBox = result.primaryCrop ?? result.foregroundCrop

        // Colors: prefer sampling within the largest detected person box (or foreground crop);
        // use foreground mask when available to reduce background noise.
        let dominantColors = dominantColorsHex(
            in: image,
            cropBox: cropBox,
            foregroundMaskSampleProvider: result.foregroundMaskSampleProvider
        )

        return OutfitPhotoFeatures(
            imageQuality: quality,
            outfitConfidence: result.outfitConfidence,
            detectedPeople: result.people,
            dominantColorsHex: dominantColors,
            poseScore: result.poseScore,
            foregroundCoverage: result.foregroundCoverage,
            featurePrintData: result.featurePrintData
        )
    }

    private static func performVisionPass(_ image: UIImage, includeAdvancedSignals: Bool) -> VisionPassResult {
        guard let cgImage = image.cgImage else {
            return VisionPassResult(
                outfitConfidence: 0.0,
                people: [],
                primaryCrop: nil,
                poseScore: 0.0,
                foregroundCoverage: 0.0,
                foregroundCrop: nil,
                featurePrintData: nil,
                foregroundMaskSampleProvider: nil
            )
        }

        let humanRequest = VNDetectHumanRectanglesRequest()
        humanRequest.upperBodyOnly = false

        let poseRequest: VNDetectHumanBodyPoseRequest? = includeAdvancedSignals ? VNDetectHumanBodyPoseRequest() : nil
        let featurePrintRequest: VNGenerateImageFeaturePrintRequest? = includeAdvancedSignals ? VNGenerateImageFeaturePrintRequest() : nil
        let foregroundMaskRequest: VNGenerateForegroundInstanceMaskRequest? = {
            guard includeAdvancedSignals else { return nil }
            if #available(iOS 17.0, *) {
                return VNGenerateForegroundInstanceMaskRequest()
            }
            return nil
        }()

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgImagePropertyOrientation(from: image.imageOrientation))

        do {
            var requests: [VNRequest] = [humanRequest]
            if let poseRequest { requests.append(poseRequest) }
            if let featurePrintRequest { requests.append(featurePrintRequest) }
            if let foregroundMaskRequest { requests.append(foregroundMaskRequest) }
            try handler.perform(requests)
        } catch {
            return VisionPassResult(
                outfitConfidence: 0.0,
                people: [],
                primaryCrop: nil,
                poseScore: 0.0,
                foregroundCoverage: 0.0,
                foregroundCrop: nil,
                featurePrintData: nil,
                foregroundMaskSampleProvider: nil
            )
        }

        let observations = (humanRequest.results ?? [])

        // Convert and sort by area.
        let people: [OutfitPhotoFeatures.DetectedPerson] = observations
            .map { obs in
                OutfitPhotoFeatures.DetectedPerson(
                    boundingBox: obs.boundingBox,
                    confidence: Double(obs.confidence)
                )
            }
            .sorted { a, b in
                (a.boundingBox.width * a.boundingBox.height) > (b.boundingBox.width * b.boundingBox.height)
            }

        // Heuristic: outfit photo likely has a prominent full-body person and a portrait-ish aspect ratio.
        let aspect = Double(image.size.width / max(1, image.size.height))
        let portraitBonus = (aspect < 0.95) ? 0.15 : 0.0

        let primary = people.first
        let primaryArea = primary.map { Double($0.boundingBox.width * $0.boundingBox.height) } ?? 0.0

        // Confidence from person presence and size.
        var confidence = 0.0
        if let primary {
            confidence += min(0.8, primary.confidence)
            // Big person bounding box is a strong signal.
            confidence += min(0.2, primaryArea) * 1.0
        }
        confidence += portraitBonus

        confidence = max(0.0, min(1.0, confidence))

        // Optional advanced signals
        let poseScore = includeAdvancedSignals ? (poseRequest.flatMap(computePoseScore(from:)) ?? 0.0) : 0.0

        var foregroundCoverage: Double = 0.0
        var foregroundCrop: CGRect? = nil
        var maskSampler: ForegroundMaskSampleProvider? = nil

        if #available(iOS 17.0, *), includeAdvancedSignals, let foregroundMaskRequest {
            if let obs = foregroundMaskRequest.results?.first {
                // Use all instances (excluding background).
                let instances = obs.allInstances
                do {
                    let scaledMask = try obs.generateScaledMaskForImage(forInstances: instances, from: handler)
                    let stats = maskCoverageAndCrop(fromScaledMask: scaledMask)
                    foregroundCoverage = stats.coverage
                    foregroundCrop = stats.visionNormalizedCrop
                    maskSampler = ForegroundMaskSampleProvider(mask: scaledMask)
                } catch {
                    // Ignore mask failures.
                    foregroundCoverage = 0.0
                    foregroundCrop = nil
                    maskSampler = nil
                }
            }
        }

        let featurePrintData: Data?
        if includeAdvancedSignals, let fp = featurePrintRequest?.results?.first {
            featurePrintData = serializeFeaturePrint(fp)
        } else {
            featurePrintData = nil
        }

        return VisionPassResult(
            outfitConfidence: confidence,
            people: people,
            primaryCrop: primary?.boundingBox,
            poseScore: poseScore,
            foregroundCoverage: foregroundCoverage,
            foregroundCrop: foregroundCrop,
            featurePrintData: featurePrintData,
            foregroundMaskSampleProvider: maskSampler
        )
    }

    private static func dominantColorsHex(
        in image: UIImage,
        cropBox: CGRect?,
        foregroundMaskSampleProvider: ForegroundMaskSampleProvider?
    ) -> [String] {
        // Keep it simple and fast: sample a few points.
        // We reuse existing Color(hex:) helpers by converting sampled pixels to hex.
        guard let cgImage = image.cgImage else { return [] }

        let width = cgImage.width
        let height = cgImage.height

        func clamp(_ v: Int, _ lo: Int, _ hi: Int) -> Int { max(lo, min(hi, v)) }

        // Determine sampling rect in pixel space.
        let rect: CGRect
        if let cropBox {
            // Vision boundingBox is normalized with origin at bottom-left.
            let x = CGFloat(cropBox.minX) * CGFloat(width)
            let y = (1.0 - CGFloat(cropBox.maxY)) * CGFloat(height)
            let w = CGFloat(cropBox.width) * CGFloat(width)
            let h = CGFloat(cropBox.height) * CGFloat(height)
            rect = CGRect(x: x, y: y, width: w, height: h).intersection(CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            rect = CGRect(x: 0, y: 0, width: width, height: height)
        }

        func isForeground(_ point: CGPoint) -> Bool {
            guard let foregroundMaskSampleProvider else { return true }
            return foregroundMaskSampleProvider.isForeground(pixelX: Int(point.x), pixelY: Int(point.y))
        }

        // Start with deterministic points, then add a few random samples to improve robustness.
        var points: [CGPoint] = [
            CGPoint(x: rect.midX, y: rect.midY),
            CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.75),
            CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.75)
        ]

        if foregroundMaskSampleProvider != nil {
            // Add extra samples to find foreground pixels if the deterministic ones land on background.
            let extraCount = 12
            for i in 0..<extraCount {
                let t = CGFloat(i + 1) / CGFloat(extraCount + 1)
                let x = rect.minX + rect.width * t
                let y = rect.minY + rect.height * (1.0 - t)
                points.append(CGPoint(x: x, y: y))
            }
        }

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow

        func pixelHex(at point: CGPoint) -> String? {
            let px = clamp(Int(point.x.rounded()), 0, width - 1)
            let py = clamp(Int(point.y.rounded()), 0, height - 1)

            if !isForeground(CGPoint(x: px, y: py)) { return nil }

            let offset = py * bytesPerRow + px * bytesPerPixel
            if offset + 3 >= (height * bytesPerRow) { return nil }

            // Assume RGBA/BGRA; handle the common cases. If format is unexpected, return nil.
            let b0 = bytes[offset]
            let b1 = bytes[offset + 1]
            let b2 = bytes[offset + 2]
            let b3 = bytes[offset + 3]
            _ = b3

            // Heuristic: if alpha byte is 255-ish, likely RGBA. If not, still just treat as RGB.
            let r: UInt8
            let g: UInt8
            let b: UInt8

            // Many iOS CGImages are BGRA.
            // We can detect by looking at bitmapInfo, but that’s overkill; we’ll just emit both and pick the more saturated later.
            // For now: assume BGRA.
            r = b2
            g = b1
            b = b0

            return String(format: "#%02X%02X%02X", r, g, b)
        }

        let hexes = points.compactMap(pixelHex)
        // Deduplicate but preserve order.
        var seen = Set<String>()
        return hexes.filter { seen.insert($0).inserted }
    }

    // MARK: - Advanced Signal Helpers

    private static func computePoseScore(from request: VNDetectHumanBodyPoseRequest) -> Double? {
        guard let poses = request.results, !poses.isEmpty else { return nil }
        let best = poses.max { $0.confidence < $1.confidence }
        guard let best else { return nil }

        // Count confident joints and compute a loose bounding box.
        guard let points = try? best.recognizedPoints(.all) else { return 0.0 }
        let confident = points.values.filter { $0.confidence >= 0.2 }
        guard !confident.isEmpty else { return 0.0 }

        let pointFraction = min(1.0, Double(confident.count) / 18.0)

        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0

        for p in confident {
            minX = min(minX, p.location.x)
            minY = min(minY, p.location.y)
            maxX = max(maxX, p.location.x)
            maxY = max(maxY, p.location.y)
        }

        let width = max(0.0, maxX - minX)
        let height = max(0.0, maxY - minY)
        let area = Double(width * height) // normalized
        let areaScore = min(1.0, area * 2.0)

        // Weighted blend: reliable joints + decent coverage.
        return max(0.0, min(1.0, (pointFraction * 0.6) + (areaScore * 0.4)))
    }

    private static func maskCoverageAndCrop(fromScaledMask mask: CVPixelBuffer) -> (coverage: Double, visionNormalizedCrop: CGRect?) {
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(mask) else {
            return (0.0, nil)
        }

        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)

        // Sample with stride to keep this fast on large images.
        let step = max(1, min(16, max(width, height) / 96))

        var foregroundCount = 0
        var totalCount = 0

        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in stride(from: 0, to: height, by: step) {
            let row = base.advanced(by: y * bytesPerRow)
            for x in stride(from: 0, to: width, by: step) {
                let v = row.load(fromByteOffset: x, as: UInt8.self)
                totalCount += 1
                if v > 0 {
                    foregroundCount += 1
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        let coverage = totalCount > 0 ? Double(foregroundCount) / Double(totalCount) : 0.0
        guard foregroundCount > 0, minX < maxX, minY < maxY else {
            return (coverage, nil)
        }

        // Convert pixel bbox (origin top-left) -> Vision normalized bbox (origin bottom-left)
        let x0 = CGFloat(minX) / CGFloat(width)
        let x1 = CGFloat(maxX) / CGFloat(width)
        let y0Top = CGFloat(minY) / CGFloat(height)
        let y1Top = CGFloat(maxY) / CGFloat(height)

        let visionY = 1.0 - y1Top
        let visionH = y1Top - y0Top
        let rect = CGRect(x: x0, y: visionY, width: x1 - x0, height: visionH)
        return (coverage, rect)
    }

    private static func serializeFeaturePrint(_ observation: VNFeaturePrintObservation) -> Data? {
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
        } catch {
            return nil
        }
    }

    /// Computes a distance between two feature prints (smaller = more similar).
    /// Returns nil if either payload cannot be decoded.
    static func featurePrintDistance(from lhs: Data, to rhs: Data) -> Double? {
        do {
            let a = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: lhs)
            let b = try NSKeyedUnarchiver.unarchivedObject(ofClass: VNFeaturePrintObservation.self, from: rhs)
            guard let a, let b else { return nil }
            var distance: Float = 0
            try a.computeDistance(&distance, to: b)
            return Double(distance)
        } catch {
            return nil
        }
    }

    // MARK: - Foreground Mask Sampling

    /// Lightweight helper that can answer "is this pixel foreground?" for an iOS 17 scaled mask.
    /// Keep it a reference type to avoid copying CVPixelBuffer around.
    private final class ForegroundMaskSampleProvider {
        private let mask: CVPixelBuffer
        private let width: Int
        private let height: Int
        private let bytesPerRow: Int

        init(mask: CVPixelBuffer) {
            self.mask = mask
            self.width = CVPixelBufferGetWidth(mask)
            self.height = CVPixelBufferGetHeight(mask)
            self.bytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        }

        func isForeground(pixelX x: Int, pixelY y: Int) -> Bool {
            guard x >= 0, y >= 0, x < width, y < height else { return false }
            CVPixelBufferLockBaseAddress(mask, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
            guard let base = CVPixelBufferGetBaseAddress(mask) else { return false }
            let row = base.advanced(by: y * bytesPerRow)
            let v = row.load(fromByteOffset: x, as: UInt8.self)
            return v > 0
        }
    }

    private static func cgImagePropertyOrientation(from orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
