import SwiftUI

// MARK: - Modern Design System

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color(hex: "6366F1") ?? .indigo      // Indigo
        static let primaryLight = Color(hex: "A5B4FC") ?? .indigo  // Light Indigo
        static let primaryDark = Color(hex: "4338CA") ?? .indigo   // Dark Indigo
        
        // Secondary Colors
        static let secondary = Color(hex: "EC4899") ?? .pink     // Pink
        static let secondaryLight = Color(hex: "FBCFE8") ?? .pink // Light Pink
        static let secondaryDark = Color(hex: "BE185D") ?? .pink  // Dark Pink
        
        // Neutral Colors
        static let background = Color(hex: "FAFAFA") ?? .white    // Off-white
        static let surface = Color(hex: "FFFFFF") ?? .white       // Pure white
        static let surfaceVariant = Color(hex: "F3F4F6") ?? .gray.opacity(0.1) // Light gray
        
        // Text Colors
        static let textPrimary = Color(hex: "1F2937") ?? .primary   // Dark gray
        static let textSecondary = Color(hex: "6B7280") ?? .secondary // Medium gray
        static let textTertiary = Color(hex: "9CA3AF") ?? .secondary.opacity(0.7)  // Light gray
        
        // Semantic Colors
        static let success = Color(hex: "10B981") ?? .green       // Green
        static let warning = Color(hex: "F59E0B") ?? .orange       // Orange
        static let error = Color(hex: "EF4444") ?? .red         // Red
        static let info = Color(hex: "3B82F6") ?? .blue          // Blue
        
        // Fashion Colors
        static let fashion1 = Color(hex: "8B5CF6") ?? .purple      // Purple
        static let fashion2 = Color(hex: "06B6D4") ?? .cyan      // Cyan
        static let fashion3 = Color(hex: "84CC16") ?? .green      // Lime
        static let fashion4 = Color(hex: "F97316") ?? .orange      // Orange
        
        // Gradient Colors
        static let gradientStart = Color(hex: "6366F1") ?? .indigo
        static let gradientEnd = Color(hex: "8B5CF6") ?? .purple
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

// MARK: - View Modifiers
struct ModernButtonStyle: ViewModifier {
    var variant: ButtonVariant = .primary
    var size: ButtonSize = .medium
    @State private var isPressed = false
    
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
            .shadow(color: buttonShadowColor, radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            .brightness(isPressed ? -0.1 : 0)
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
    @State private var pulseAmount: CGFloat = 1.0
    @State private var rotationAngle: Double = 0.0
    @State private var dots = [".", ".", "."]
    @State private var dotIndex = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                // Pulsing circle background
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAmount)
                    .opacity(2.0 - pulseAmount)
                
                // Rotating stars
                ForEach(0..<5) { index in
                    Image(systemName: "star.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(.system(size: 16))
                        .offset(x: 30 * cos(CGFloat(index) * .pi * 2 / 5))
                        .offset(y: 30 * sin(CGFloat(index) * .pi * 2 / 5))
                        .rotationEffect(.degrees(rotationAngle))
                }
                
                // Central wand icon
                Image(systemName: "wand.and.stars")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 32))
            }
            .onAppear {
                withAnimation(.repeatForever(autoreverses: true)) {
                    pulseAmount = 1.5
                }
                
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                // Animate dots
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    dotIndex = (dotIndex + 1) % 4
                    dots = Array(repeating: ".", count: 3)
                    if dotIndex < 3 {
                        dots[dotIndex] = "•"
                    }
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Creating your perfect outfit")
                    .font(DesignSystem.Typography.headlineSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Analyzing style preferences" + dots.joined())
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .modernCardStyle()
    }
}

// MARK: - Empty State View
struct ModernEmptyStateView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
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

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .modernButtonStyle(variant: .primary, size: .medium)
                }
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .modernCardStyle()
    }
}

// MARK: - Modern Toggle Style
struct ModernToggleStyle: ToggleStyle {
    @Namespace private var namespace
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                // Background track
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                    .fill(configuration.isOn ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant)
                    .frame(width: 51, height: 31)
                    .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                
                // Animated thumb with scaling effect
                Circle()
                    .fill(.white)
                    .padding(2)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .scaleEffect(configuration.isOn ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// MARK: - Modern Segmented Control
struct ModernSegmentedControl<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let labelProvider: (T) -> String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    Text(labelProvider(option))
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(selection == option ? .white : DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .frame(maxWidth: .infinity)
                }
                .background(selection == option ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
        }
        .background(DesignSystem.Colors.surfaceVariant)
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Modern Progress View
struct ModernProgressView: View {
    let progress: Double
    let title: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Spacer()
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.surfaceVariant)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.fashion1]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
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

// MARK: - Modern Tag View
struct ModernTagView: View {
    let title: String
    let color: Color
    let onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            Text(title)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(color)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Badge View
struct ModernBadgeView: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.labelSmall)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Modern Rating View
struct ModernRatingView: View {
    let rating: Double
    let maxRating: Double = 5.0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<Int(maxRating)) { index in
                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(index < Int(rating) ? DesignSystem.Colors.warning : DesignSystem.Colors.textTertiary)
            }
            
            Text(String(format: "%.1f", rating))
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
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
            
            // New components preview
            VStack(spacing: 12) {
                Text("New Components")
                    .font(DesignSystem.Typography.headlineSmall)
                
                HStack {
                    ModernBadgeView(title: "New", color: DesignSystem.Colors.error)
                    ModernRatingView(rating: 4.5)
                }
                
                ModernChipView(title: "Selected", isSelected: true, onTap: {})
                ModernChipView(title: "Unselected", isSelected: false, onTap: {})
            )
        }
        .padding()
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

// MARK: - Modern Chip View
struct ModernChipView: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(isSelected ? .white : DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Chip Group
struct ModernChipGroupView: View {
    let options: [String]
    @Binding var selection: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    ModernChipView(
                        title: option,
                        isSelected: selection == option,
                        onTap: { selection = option }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Modern Seasonal Chart View
struct ModernSeasonalChartView: View {
    let seasonalData: [String: Int]
    
    var body: some View {
        // Simple bar chart representation
        HStack(spacing: DesignSystem.Spacing.sm) {
            let maxValue = seasonalData.values.max() ?? 1
            
            ForEach(Array(seasonalData.keys).sorted(), id: \.self) { season in
                let value = seasonalData[season] ?? 0
                let heightFactor = Double(value) / Double(maxValue)
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    // Bar
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(getSeasonColor(season))
                        .frame(width: 20, height: max(4, 50 * heightFactor))
                    
                    // Season label
                    Text(season.prefix(1).uppercased())
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(height: 70)
    }
    
    private func getSeasonColor(_ season: String) -> Color {
        switch season.lowercased() {
        case "spring": return DesignSystem.Colors.fashion3  // Green
        case "summer": return DesignSystem.Colors.fashion2  // Cyan
        case "fall", "autumn": return DesignSystem.Colors.fashion1  // Purple
        case "winter": return DesignSystem.Colors.primary   // Indigo
        default: return DesignSystem.Colors.textSecondary
        }
    }
}