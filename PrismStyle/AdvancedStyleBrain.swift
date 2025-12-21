import Foundation
import SwiftData

/// Thin wrapper around `EnhancedStyleBrain`.
/// The UI calls this API for the “advanced” recommendation path.
struct AdvancedStyleBrain {
    func generateAdvancedRecommendation(
        occasion: StylePromptBuilder.Occasion,
        items: [ClothingItem],
        looks: [OutfitLook],
        memory: StyleMemory,
        preferFavorites: Bool = true,
        allowMixing: Bool = true,
        stylePreference: String = "any",
        colorPreference: String = "any",
        formalityLevel: String = "auto",
        prioritizeComfort: Bool = false,
        location: String? = nil,
        weather: WeatherData? = nil
    ) async throws -> AdvancedStyleSuggestion {
        _ = weather

        let enhanced = try await EnhancedStyleBrain().suggest(
            occasion: occasion,
            items: items,
            looks: looks,
            memory: memory,
            preferFavorites: preferFavorites,
            allowMixing: allowMixing,
            stylePreference: stylePreference,
            colorPreference: colorPreference,
            formalityLevel: formalityLevel,
            prioritizeComfort: prioritizeComfort,
            location: location
        )

        return AdvancedStyleSuggestion(
            verdict: enhanced.verdict,
            why: enhanced.why,
            detailedSuggestion: enhanced.detailedSuggestion,
            suggestedItemIDs: enhanced.suggestedItemIDs,
            bestLookID: enhanced.bestLookID,
            confidenceScore: enhanced.confidenceScore,
            styleTags: enhanced.styleTags,
            styleBreakdown: enhanced.styleBreakdown,
            alternativeSuggestions: enhanced.alternativeSuggestions
        )
    }
}

// MARK: - SwiftData Models

@Model
final class FashionTrend {
    var id: UUID
    var trendName: String
    var season: String
    var year: Int
    var keyColorsData: Data
    var keyStylesData: Data
    var popularityScore: Double
    var createdAt: Date

    var keyColors: [String] {
        get { decodeJSON([String].self, from: keyColorsData) ?? [] }
        set { keyColorsData = encodeJSON(newValue) }
    }

    var keyStyles: [String] {
        get { decodeJSON([String].self, from: keyStylesData) ?? [] }
        set { keyStylesData = encodeJSON(newValue) }
    }

    init(
        id: UUID = UUID(),
        trendName: String,
        season: String,
        year: Int,
        keyColors: [String],
        keyStyles: [String],
        popularityScore: Double = 0.0
    ) {
        self.id = id
        self.trendName = trendName
        self.season = season
        self.year = year
        self.keyColorsData = encodeJSON(keyColors)
        self.keyStylesData = encodeJSON(keyStyles)
        self.popularityScore = popularityScore
        self.createdAt = Date()
    }
}

extension FashionTrend {
    var name: String { trendName }

    /// UI-facing category label.
    var category: String { keyStyles.first ?? "Trend" }

    /// UI-facing short description.
    var description: String {
        let colors = keyColors.prefix(3).joined(separator: ", ")
        let styles = keyStyles.prefix(3).joined(separator: ", ")

        switch (colors.isEmpty, styles.isEmpty) {
        case (false, false):
            return "Key colors: \(colors). Styles: \(styles)."
        case (false, true):
            return "Key colors: \(colors)."
        case (true, false):
            return "Styles: \(styles)."
        case (true, true):
            return "Seasonal trend highlights."
        }
    }

    /// Used by the Trends UI to match closet items.
    var suggestedCategories: [String] { keyStyles }

    /// Used by the Trends UI to match closet items.
    var suggestedColors: [String] { keyColors }

    var keyElements: [String] {
        (keyStyles + keyColors).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

@Model
final class StyleProfile {
    var id: UUID
    var userName: String
    var bodyType: String
    var colorSeason: String
    var stylePersonality: String
    var lifestyle: String
    var preferredBrandsData: Data
    var budgetRange: String
    var createdAt: Date

    var preferredBrands: [String] {
        get { decodeJSON([String].self, from: preferredBrandsData) ?? [] }
        set { preferredBrandsData = encodeJSON(newValue) }
    }

    init(
        id: UUID = UUID(),
        userName: String,
        bodyType: String,
        colorSeason: String,
        stylePersonality: String,
        lifestyle: String,
        preferredBrands: [String] = [],
        budgetRange: String = "medium"
    ) {
        self.id = id
        self.userName = userName
        self.bodyType = bodyType
        self.colorSeason = colorSeason
        self.stylePersonality = stylePersonality
        self.lifestyle = lifestyle
        self.preferredBrandsData = encodeJSON(preferredBrands)
        self.budgetRange = budgetRange
        self.createdAt = Date()
    }
}

extension StyleProfile {
    /// Back-compat for older UI.
    var name: String { userName }

    /// Back-compat for older UI.
    var preferredStyle: String { stylePersonality }

    /// Back-compat for older UI.
    var stylePreferences: [String] {
        ([lifestyle, colorSeason] + preferredBrands)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

@Model
final class WeatherData {
    var id: UUID
    var temperature: Double
    var condition: String
    var humidity: Double
    var windSpeed: Double
    var uvIndex: Double
    var location: String
    var timestamp: Date

    init(
        id: UUID = UUID(),
        temperature: Double,
        condition: String,
        humidity: Double,
        windSpeed: Double,
        uvIndex: Double,
        location: String
    ) {
        self.id = id
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
        self.location = location
        self.timestamp = Date()
    }
}
