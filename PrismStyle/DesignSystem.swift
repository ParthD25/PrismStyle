import SwiftUI

// MARK: - Modern Design System

struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color(hex: "6366F1")      // Indigo
        static let primaryLight = Color(hex: "A5B4FC")  // Light Indigo
        static let primaryDark = Color(hex: "4338CA")   // Dark Indigo
        
        // Secondary Colors
        static let secondary = Color(hex: "EC4899")     // Pink
        static let secondaryLight = Color(hex: "FBCFE8") // Light Pink
        static let secondaryDark = Color(hex: "BE185D")  // Dark Pink
        
        // Neutral Colors
        static let background = Color(hex: "FAFAFA")    // Off-white
        static let surface = Color(hex: "FFFFFF")       // Pure white
        static let surfaceVariant = Color(hex: "F3F4F6") // Light gray
        
        // Text Colors
        static let textPrimary = Color(hex: "1F2937")   // Dark gray
        static let textSecondary = Color(hex: "6B7280") // Medium gray
        static let textTertiary = Color(hex: "9CA3AF")  // Light gray
        
        // Semantic Colors
        static let success = Color(hex: "10B981")       // Green
        static let warning = Color(hex: "F59E0B")       // Orange
        static let error = Color(hex: "EF4444")         // Red
        static let info = Color(hex: "3B82F6")          // Blue
        
        // Fashion Colors
        static let fashion1 = Color(hex: "8B5CF6")      // Purple
        static let fashion2 = Color(hex: "06B6D4")      // Cyan
        static let fashion3 = Color(hex: "84CC16")      // Lime
        static let fashion4 = Color(hex: "F97316")      // Orange
    }
    
    // MARK: - Typography
    struct Typography {
        // Display Fonts
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
        
        // Headline Fonts
        static let headlineLarge = Font.system(size: 32, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 28, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
        
        // Title Fonts
        static let titleLarge = Font.system(size: 22, weight: .medium, design: .rounded)
        static let titleMedium = Font.system(size: 20, weight: .medium, design: .rounded)
        static let titleSmall = Font.system(size: 18, weight: .medium, design: .rounded)
        
        // Body Fonts
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .rounded)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .rounded)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .rounded)
        
        // Label Fonts
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .rounded)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .rounded)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let sm = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let md = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let lg = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - View Modifiers
struct ModernButtonStyle: ViewModifier {
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .medium
    
    enum ButtonVariant {
        case primary, secondary, tertiary, destructive
    }
    
    enum ButtonSize {
        case small, medium, large
    }
    
    func body(content: Content) -> some View {
        content
            .font(buttonFont)
            .foregroundColor(buttonForegroundColor)
            .frame(minWidth: buttonMinWidth, minHeight: buttonMinHeight)
            .padding(.horizontal, buttonHorizontalPadding)
            .background(buttonBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius))
            .shadow(color: buttonShadowColor, radius: 4, x: 0, y: 2)
    }
    
    private var buttonFont: Font {
        switch size {
        case .small: return DesignSystem.Typography.labelMedium
        case .medium: return DesignSystem.Typography.labelLarge
        case .large: return DesignSystem.Typography.titleSmall
        }
    }
    
    private var buttonForegroundColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return DesignSystem.Colors.primary
        case .tertiary: return DesignSystem.Colors.textPrimary
        case .destructive: return .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch variant {
        case .primary: return DesignSystem.Colors.primary
        case .secondary: return DesignSystem.Colors.surface
        case .tertiary: return Color.clear
        case .destructive: return DesignSystem.Colors.error
        }
    }
    
    private var buttonMinWidth: CGFloat {
        switch size {
        case .small: return 80
        case .medium: return 120
        case .large: return 160
        }
    }
    
    private var buttonMinHeight: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        }
    }
    
    private var buttonHorizontalPadding: CGFloat {
        switch size {
        case .small: return DesignSystem.Spacing.sm
        case .medium: return DesignSystem.Spacing.md
        case .large: return DesignSystem.Spacing.lg
        }
    }
    
    private var buttonCornerRadius: CGFloat {
        switch size {
        case .small: return DesignSystem.CornerRadius.sm
        case .medium: return DesignSystem.CornerRadius.md
        case .large: return DesignSystem.CornerRadius.lg
        }
    }
    
    private var buttonShadowColor: Color {
        switch variant {
        case .primary: return DesignSystem.Colors.primary.opacity(0.3)
        case .secondary: return DesignSystem.Colors.textPrimary.opacity(0.1)
        case .tertiary: return Color.clear
        case .destructive: return DesignSystem.Colors.error.opacity(0.3)
        }
    }
}

extension View {
    func modernButtonStyle(variant: ModernButtonStyle.ButtonVariant = .primary, size: ModernButtonStyle.ButtonSize = .medium) -> some View {
        modifier(ModernButtonStyle(variant: variant, size: size))
    }
}

// MARK: - Card Style
struct ModernCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .stroke(DesignSystem.Colors.surfaceVariant, lineWidth: 1)
            )
    }
}

extension View {
    func modernCardStyle() -> some View {
        modifier(ModernCardStyle())
    }
}

// MARK: - Loading View
struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Creating your perfect outfit...")
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
        .modernCardStyle()
    }
}

// MARK: - Empty State View
struct ModernEmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(title)
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(message)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: action) {
                Text(actionTitle)
                    .modernButtonStyle(variant: .primary, size: .medium)
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .modernCardStyle()
    }
}

// MARK: - Modern Toggle Style
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                .fill(configuration.isOn ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant)
                .frame(width: 51, height: 31)
                .overlay(
                    Circle()
                        .fill(.white)
                        .padding(2)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Modern Text Field Style
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.surfaceVariant, lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        VStack(spacing: 12) {
            Text("Modern Button Styles")
                .font(DesignSystem.Typography.headlineSmall)
            
            HStack(spacing: 12) {
                Button("Primary") {}
                    .modernButtonStyle(variant: .primary, size: .medium)
                
                Button("Secondary") {}
                    .modernButtonStyle(variant: .secondary, size: .medium)
                
                Button("Tertiary") {}
                    .modernButtonStyle(variant: .tertiary, size: .medium)
            }
            
            HStack(spacing: 12) {
                Button("Small") {}
                    .modernButtonStyle(variant: .primary, size: .small)
                
                Button("Medium") {}
                    .modernButtonStyle(variant: .primary, size: .medium)
                
                Button("Large") {}
                    .modernButtonStyle(variant: .primary, size: .large)
            }
        }
        .padding()
        .modernCardStyle()
        
        VStack(spacing: 12) {
            Text("Modern Components")
                .font(DesignSystem.Typography.headlineSmall)
            
            ModernLoadingView()
            
            ModernEmptyStateView(
                title: "No Outfits Yet",
                message: "Start by adding your first outfit to get AI recommendations",
                actionTitle: "Add Outfit",
                action: {}
            )
        }
        .padding()
    }
    .padding()
    .background(DesignSystem.Colors.background)
}