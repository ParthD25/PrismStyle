import SwiftUI

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let red = Float(components[0])
        let green = Float(components[1])
        let blue = Float(components[2])
        var alpha = Float(1.0)
        
        if components.count >= 4 {
            alpha = Float(components[3])
        }
        
        if alpha != 1.0 {
            return String(format: "#%02lX%02lX%02lX%02lX",
                         lroundf(red * 255),
                         lroundf(green * 255),
                         lroundf(blue * 255),
                         lroundf(alpha * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX",
                         lroundf(red * 255),
                         lroundf(green * 255),
                         lroundf(blue * 255))
        }
    }
    
    /// Convert RGB to HSL
    func toHSL() -> (h: Double, s: Double, l: Double) {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return (0, 0, 0)
        }
        
        let r = Double(components[0])
        let g = Double(components[1])
        let b = Double(components[2])
        
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal
        
        var h: Double = 0
        var s: Double = 0
        let l = (maxVal + minVal) / 2
        
        if delta != 0 {
            s = l < 0.5 ? delta / (maxVal + minVal) : delta / (2 - maxVal - minVal)
            
            if maxVal == r {
                h = ((g - b) / delta) + (g < b ? 6 : 0)
            } else if maxVal == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            
            h *= 60
        }
        
        return (h, s, l)
    }
}

extension Color {
    init(hue: Double, saturation: Double, lightness: Double) {
        // Convert HSL to RGB
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        
        var r: Double, g: Double, b: Double
        
        if hue < 1/6 {
            r = c; g = x; b = 0
        } else if hue < 2/6 {
            r = x; g = c; b = 0
        } else if hue < 3/6 {
            r = 0; g = c; b = x
        } else if hue < 4/6 {
            r = 0; g = x; b = c
        } else if hue < 5/6 {
            r = x; g = 0; b = c
        } else {
            r = c; g = 0; b = x
        }
        
        self.init(red: r + m, green: g + m, blue: b + m)
    }
}