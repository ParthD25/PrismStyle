import Foundation
import UIKit
import CoreImage

enum ImageScoring {
    // Reuse CIContext for better performance
    private static let context = CIContext(options: nil)
    
    /// A simple focus/clarity score using variance of Laplacian.
    /// Higher is sharper.
    static func sharpnessScore(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CILaplacian")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let output = filter?.outputImage else { return 0 }

        // Downsample for speed.
        let extent = output.extent
        let width = max(1, Int(extent.width / 8.0))
        let height = max(1, Int(extent.height / 8.0))
        let colorSpace = CGColorSpaceCreateDeviceGray()
        var buffer = [UInt8](repeating: 0, count: width * height)
        context.render(output,
                       toBitmap: &buffer,
                       rowBytes: width,
                       bounds: CGRect(x: 0, y: 0, width: width, height: height),
                       format: .R8,
                       colorSpace: colorSpace)

        let mean = buffer.map { Double($0) }.reduce(0, +) / Double(buffer.count)
        let variance = buffer.map { (Double($0) - mean) * (Double($0) - mean) }.reduce(0, +) / Double(buffer.count)
        return variance
    }
    
    /// Calculate image brightness score (0-1, where 0.5 is optimal)
    static func brightnessScore(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.5 }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: "inputExtent")
        
        guard let output = filter?.outputImage else { return 0.5 }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let brightness = (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / (3.0 * 255.0)
        return brightness
    }
    
    /// Calculate image contrast score (0-1, higher is better)
    static func contrastScore(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIAreaHistogram")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: "inputExtent")
        filter?.setValue(256, forKey: "inputCount")
        filter?.setValue(1.0, forKey: "inputScale")
        
        guard let output = filter?.outputImage else { return 0 }
        
        var histogram = [Float](repeating: 0, count: 256)
        context.render(output,
                       toBitmap: &histogram,
                       rowBytes: 256 * MemoryLayout<Float>.size,
                       bounds: CGRect(x: 0, y: 0, width: 256, height: 1),
                       format: .R32F,
                       colorSpace: nil)
        
        // Calculate standard deviation as contrast measure
        let mean = histogram.enumerated().map { Double($0.offset) * Double($0.element) }.reduce(0, +)
        let variance = histogram.enumerated().map { pow(Double($0.offset) - mean, 2) * Double($0.element) }.reduce(0, +)
        let stdDev = sqrt(variance)
        
        // Normalize to 0-1 range
        return min(1.0, stdDev / 128.0)
    }
    
    /// Overall image quality score combining multiple factors with advanced weighting
    /// Considers not just technical quality but also suitability for fashion analysis
    static func overallQualityScore(_ image: UIImage) -> Double {
        let sharpness = sharpnessScore(image)
        let brightness = brightnessScore(image)
        let contrast = contrastScore(image)
        
        // Normalize sharpness (typically 0-1000 range)
        let normalizedSharpness = min(1.0, sharpness / 500.0)
        
        // Brightness preference (0.3-0.7 is good)
        let brightnessPenalty = abs(brightness - 0.5) * 2.0
        let normalizedBrightness = max(0.0, 1.0 - brightnessPenalty)
        
        // Advanced weighting based on image characteristics
        // Sharpness is most important for fashion analysis
        // Contrast helps distinguish clothing details
        // Brightness affects color perception
        let sharpnessWeight: Double = 0.6
        let brightnessWeight: Double = 0.2
        let contrastWeight: Double = 0.2
        
        // Calculate weighted combination
        let technicalQuality = (normalizedSharpness * sharpnessWeight + 
                              normalizedBrightness * brightnessWeight + 
                              contrast * contrastWeight)
        
        // Adjust for fashion suitability
        let fashionSuitability = isLikelyOutfitPhoto(image) ? 1.0 : 0.7
        
        // Final score combines technical quality with fashion suitability
        return technicalQuality * fashionSuitability
    }
    
    /// Detect if image is likely a full-body outfit photo
    static func isLikelyOutfitPhoto(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let aspectRatio = width / height
        
        // Outfit photos are typically vertical/portrait (aspect ratio < 1.0)
        // and have reasonable dimensions
        return aspectRatio < 1.2 && aspectRatio > 0.5 && width > 200 && height > 300
    }
}
