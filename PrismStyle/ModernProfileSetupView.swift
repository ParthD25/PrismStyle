import SwiftUI
import SwiftData

struct ModernProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var preferredStyle = "classic"
    @State private var favoriteColors: [String] = []
    @State private var stylePreferences: [String] = []
    @State private var bodyType = "average"
    @State private var budgetRange = "mid"
    
    let styleOptions = ["classic", "trendy", "minimalist", "bold", "casual", "professional", "romantic", "edgy"]
    let colorOptions = ["neutral", "warm", "cool", "bright", "dark", "pastels", "earth"]
    let preferenceOptions = ["comfort", "style", "versatility", "quality", "sustainability", "trendy"]
    let bodyTypeOptions = ["petite", "average", "tall", "curvy", "athletic"]
    let budgetOptions = ["budget", "mid", "premium", "luxury"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "person.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primary)
                        
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text("Complete Your Profile")
                                .font(DesignSystem.Typography.displaySmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Help us understand your style for better recommendations")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Basic Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Basic Information")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Name
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Your Name")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Preferred Style
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Preferred Style")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Style", selection: $preferredStyle) {
                                ForEach(styleOptions, id: \.self) { style in
                                    Text(style.capitalized).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Body Type
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Body Type")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Body Type", selection: $bodyType) {
                                ForEach(bodyTypeOptions, id: \.self) { type in
                                    Text(type.capitalized).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Budget Range
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Budget Range")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Budget", selection: $budgetRange) {
                                ForEach(budgetOptions, id: \.self) { budget in
                                    Text(budget.capitalized).tag(budget)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Color Preferences
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Color Preferences")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Select your favorite color palettes")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: DesignSystem.Spacing.sm) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button {
                                    if favoriteColors.contains(color) {
                                        favoriteColors.removeAll { $0 == color }
                                    } else {
                                        favoriteColors.append(color)
                                    }
                                } label: {
                                    HStack {
                                        Text(color.capitalized)
                                            .font(DesignSystem.Typography.bodyMedium)
                                        
                                        Spacer()
                                        
                                        if favoriteColors.contains(color) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(DesignSystem.Colors.primary)
                                        }
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .background(favoriteColors.contains(color) ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surfaceVariant)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                }
                                .foregroundColor(favoriteColors.contains(color) ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Style Preferences
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("What Matters to You?")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Select what you prioritize in your outfits")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: DesignSystem.Spacing.sm) {
                            ForEach(preferenceOptions, id: \.self) { preference in
                                Button {
                                    if stylePreferences.contains(preference) {
                                        stylePreferences.removeAll { $0 == preference }
                                    } else {
                                        stylePreferences.append(preference)
                                    }
                                } label: {
                                    HStack {
                                        Text(preference.capitalized)
                                            .font(DesignSystem.Typography.bodyMedium)
                                        
                                        Spacer()
                                        
                                        if stylePreferences.contains(preference) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(DesignSystem.Colors.primary)
                                        }
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .background(stylePreferences.contains(preference) ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surfaceVariant)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                }
                                .foregroundColor(stylePreferences.contains(preference) ? DesignSystem.Colors.primary : DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Save Button
                    Button {
                        saveProfile()
                    } label: {
                        Label("Complete Profile", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .modernButtonStyle(variant: .primary, size: .large)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .disabled(name.isEmpty)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        let profile = StyleProfile(
            userName: name,
            bodyType: bodyType,
            colorSeason: favoriteColors.first ?? "unknown",
            stylePersonality: preferredStyle,
            lifestyle: stylePreferences.first ?? "general",
            preferredBrands: [],
            budgetRange: budgetRange
        )
        
        modelContext.insert(profile)
        dismiss()
    }
}