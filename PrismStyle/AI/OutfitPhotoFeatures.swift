import Foundation
import CoreGraphics

struct OutfitPhotoFeatures: Sendable {
    struct DetectedPerson: Sendable {
        let boundingBox: CGRect
        let confidence: Double
    }

    let imageQuality: Double
    let outfitConfidence: Double
    let detectedPeople: [DetectedPerson]
    let dominantColorsHex: [String]

    /// A heuristic score based on how confidently a human pose is detected.
    /// 0 = no reliable pose, 1 = strong pose signal.
    let poseScore: Double

    /// Fraction of pixels that look like foreground (0..1).
    /// Uses iOS 17+ foreground instance masking when available.
    let foregroundCoverage: Double

    /// Optional serialized VNFeaturePrintObservation for similarity.
    /// Stored as Data to remain Sendable.
    let featurePrintData: Data?

    /// A single score for ranking multiple photos as "best outfit photo".
    /// Keep this stable and easy to reason about.
    var rankingScore: Double {
        // Outfit visibility and image quality dominate.
        // Pose/foreground are smaller tie-breakers that help burst selection.
        let oc = max(0.0, min(1.0, outfitConfidence))
        let iq = max(0.0, min(1.0, imageQuality))
        let ps = max(0.0, min(1.0, poseScore))
        let fg = max(0.0, min(1.0, foregroundCoverage))
        return (oc * 0.50) + (iq * 0.35) + (ps * 0.10) + (fg * 0.05)
    }
}
