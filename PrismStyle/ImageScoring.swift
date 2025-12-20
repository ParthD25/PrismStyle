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
}
