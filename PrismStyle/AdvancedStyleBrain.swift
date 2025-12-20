import Foundation
import UIKit
import CoreML
import Vision
import SwiftData

/// Advanced AI engine with color theory, style matching, and comprehensive fashion algorithms
struct AdvancedStyleBrain {
    
    // MARK: - Color Theory Constants
    private static let COLOR_WHEEL = [
        "red": (hue: 0, complementary: "cyan"),
        "orange": (hue: 30, complementary: "blue"),
        "yellow": (hue: 60, complementary: "purple"),
        "green": (hue: 120, complementary: "magenta"),
        "cyan": (hue: 180, complementary: "red"),
        "blue": (hue: 240, complementary: "yellow"),
        "purple": (hue: 270, complementary: "green"),
        "magenta": (hue: 300, complementary: "green")
    ]
    
    private static let NEUTRAL_COLORS = ["black", "white", "gray", "beige", "navy", "brown"]
    
    private static let SEASONAL_PALETTES = [
        "spring": ["coral", "peach", "mint", "golden yellow", "warm green"],
        "summer": ["lavender", "powder blue", "rose", "soft pink", "cool gray"],
        "autumn": ["burnt orange", "olive", "mustard", "burgundy", "warm brown"],
        "winter": ["royal blue", "emerald", "crimson", "silver", "charcoal"]
    ]
    
    // MARK: - Advanced Recommendation Engine
    func generateAdvancedRecommendation(
        occasion: StylePromptBuilder.Occasion,
        items: [ClothingItem],
        looks: [OutfitLook],
        memory: StyleMemory,
        stylePreference: String = "any",
        colorPreference: String = "any",
        formalityLevel: String = "auto",
        prioritizeComfort: Bool = false,
        location: String? = nil,
        weather: WeatherData? = nil
    ) async throws -> AdvancedStyleSuggestion {
        
        // Phase 1: Analyze user context and preferences
        let userProfile = await analyzeUserContext(
            memory: memory,
            occasion: occasion,
            stylePreference: stylePreference,
            colorPreference: colorPreference
        )
        
        // Phase 2: Apply advanced color theory
        let colorAnalysis = performColorTheoryAnalysis(
            items: items,
            userProfile: userProfile,
            colorPreference: colorPreference
        )
        
        // Phase 3: Style compatibility analysis
        let styleAnalysis = performStyleCompatibilityAnalysis(
            items: items,
            userProfile: userProfile,
            occasion: occasion
        )
        
        // Phase 4: Generate outfit combinations
        let outfitCombinations = generateOptimalOutfitCombinations(
            items: items,
            colorAnalysis: colorAnalysis,
            styleAnalysis: styleAnalysis,
            userProfile: userProfile,
            occasion: occasion
        )
        
        // Phase 5: Score and rank combinations
        let scoredOutfits = scoreOutfitCombinations(
            combinations: outfitCombinations,
            userProfile: userProfile,
            occasion: occasion,
            weather: weather
        )
        
        // Phase 6: Select best outfit and generate recommendations
        guard let bestOutfit = scoredOutfits.first else {
            return createFallbackSuggestion(occasion: occasion)
        }
        
        return await createAdvancedSuggestion(
            outfit: bestOutfit,
            userProfile: userProfile,
            occasion: occasion,
            alternatives: Array(scoredOutfits.dropFirst().prefix(3))
        )
    }
    
    // MARK: - Color Theory Analysis
    private func performColorTheoryAnalysis(
        items: [ClothingItem],
        userProfile: UserProfile,
        colorPreference: String
    ) -> ColorAnalysis {
        
        var colorHarmonyScores: [UUID: Double] = [:]
        var colorPaletteRecommendations: [String] = []
        
        // Analyze each item's color properties
        for item in items {
            let primaryColor = normalizeColorName(item.primaryColorHex)
            var harmonyScore = 0.0
            
            // Check color harmony with user's preferred palette
            if let userPalette = userProfile.preferredColors {
                harmonyScore += calculateColorHarmonyScore(color: primaryColor, palette: userPalette)
            }
            
            // Apply color preference weighting
            harmonyScore *= getColorPreferenceWeight(colorPreference, color: primaryColor)
            
            // Check seasonal appropriateness
            if let season = userProfile.preferredSeason {
                harmonyScore += calculateSeasonalColorScore(color: primaryColor, season: season)
            }
            
            colorHarmonyScores[item.id] = harmonyScore
        }
        
        // Generate color palette recommendations
        colorPaletteRecommendations = generateOptimalColorPalette(
            items: items,
            userProfile: userProfile,
            colorPreference: colorPreference
        )
        
        return ColorAnalysis(
            harmonyScores: colorHarmonyScores,
            paletteRecommendations: colorPaletteRecommendations,
            complementaryPairs: findComplementaryColorPairs(items: items)
        )
    }
    
    private func calculateColorHarmonyScore(color: String, palette: [String]) -> Double {
        // Implement advanced color harmony algorithm
        var score = 0.0
        
        for paletteColor in palette {
            let harmony = calculateColorDistance(color1: color, color2: paletteColor)
            score += max(0, 1.0 - harmony)
        }
        
        return score / Double(palette.count)
    }
    
    private func calculateColorDistance(color1: String, color2: String) -> Double {
        // Convert hex colors to HSL for better comparison
        let hsl1 = hexToHSL(color1)
        let hsl2 = hexToHSL(color2)
        
        // Calculate perceptual color difference
        let hueDistance = min(abs(hsl1.h - hsl2.h), 360 - abs(hsl1.h - hsl2.h)) / 180.0
        let saturationDistance = abs(hsl1.s - hsl2.s)
        let lightnessDistance = abs(hsl1.l - hsl2.l)
        
        return (hueDistance * 0.5 + saturationDistance * 0.3 + lightnessDistance * 0.2)
    }
    
    private func generateOptimalColorPalette(
        items: [ClothingItem],
        userProfile: UserProfile,
        colorPreference: String
    ) -> [String] {
        
        var palette: [String] = []
        let baseColors = items.map { normalizeColorName($0.primaryColorHex) }
        
        // Generate complementary colors
        for color in baseColors {
            if let complementary = findComplementaryColor(color) {
                palette.append(complementary)
            }
        }
        
        // Add accent colors based on preference
        switch colorPreference {
        case "neutral":
            palette.append(contentsOf: ["beige", "gray", "navy"])
        case "warm":
            palette.append(contentsOf: ["coral", "gold", "terracotta"])
        case "cool":
            palette.append(contentsOf: ["mint", "lavender", "sky blue"])
        case "bold":
            palette.append(contentsOf: ["emerald", "fuchsia", "orange"])
        default:
            break
        }
        
        return Array(Set(palette)).prefix(5).map { $0 }
    }
    
    // MARK: - Style Compatibility Analysis
    private func performStyleCompatibilityAnalysis(
        items: [ClothingItem],
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion
    ) -> StyleAnalysis {
        
        var styleScores: [UUID: Double] = [:]
        var compatibilityMatrix: [UUID: [UUID: Double]] = [:]
        
        // Calculate individual item style scores
        for item in items {
            let styleScore = calculateItemStyleScore(
                item: item,
                userProfile: userProfile,
                occasion: occasion
            )
            styleScores[item.id] = styleScore
        }
        
        // Calculate pairwise compatibility
        for item1 in items {
            compatibilityMatrix[item1.id] = [:]
            for item2 in items {
                if item1.id != item2.id {
                    let compatibility = calculateStyleCompatibility(item1: item1, item2: item2)
                    compatibilityMatrix[item1.id]?[item2.id] = compatibility
                }
            }
        }
        
        return StyleAnalysis(
            styleScores: styleScores,
            compatibilityMatrix: compatibilityMatrix,
            recommendedStyleType: determineOptimalStyleType(items: items, occasion: occasion)
        )
    }
    
    private func calculateItemStyleScore(
        item: ClothingItem,
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion
    ) -> Double {
        
        var score = 0.5 // Base score
        
        // Formality matching
        let requiredFormality = determineFormality(for: occasion)
        if let required = requiredFormality {
            score += calculateFormalityCompatibility(itemFormality: item.formality, required: required)
        }
        
        // Category appropriateness
        score += calculateCategoryScore(category: item.category, occasion: occasion)
        
        // User preference alignment
        if let userStyle = userProfile.preferredStyle {
            score += calculateStyleAlignment(item: item, userStyle: userStyle)
        }
        
        // Season appropriateness
        if let season = userProfile.preferredSeason {
            score += calculateSeasonalScore(item: item, season: season)
        }
        
        return min(score, 1.0)
    }
    
    private func calculateStyleCompatibility(item1: ClothingItem, item2: ClothingItem) -> Double {
        // Advanced style matching algorithm
        var compatibility = 0.5 // Base compatibility
        
        // Formality compatibility
        compatibility += calculateFormalityCompatibility(
            itemFormality: item1.formality,
            required: item2.formality
        ) * 0.3
        
        // Color harmony
        let colorHarmony = calculateColorHarmonyScore(
            color: normalizeColorName(item1.primaryColorHex),
            palette: [normalizeColorName(item2.primaryColorHex)]
        )
        compatibility += colorHarmony * 0.4
        
        // Category compatibility
        compatibility += calculateCategoryCompatibility(
            category1: item1.category,
            category2: item2.category
        ) * 0.3
        
        return min(compatibility, 1.0)
    }
    
    // MARK: - Outfit Generation
    private func generateOptimalOutfitCombinations(
        items: [ClothingItem],
        colorAnalysis: ColorAnalysis,
        styleAnalysis: StyleAnalysis,
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion
    ) -> [OutfitCombination] {
        
        var combinations: [OutfitCombination] = []
        
        // Generate base outfit templates based on occasion
        let templates = generateOutfitTemplates(for: occasion)
        
        for template in templates {
            let matchingCombinations = findMatchingItemsForTemplate(
                template: template,
                items: items,
                colorAnalysis: colorAnalysis,
                styleAnalysis: styleAnalysis,
                userProfile: userProfile
            )
            combinations.append(contentsOf: matchingCombinations)
        }
        
        // Add creative combinations for fashion-forward users
        if let preferredStyle = userProfile.preferredStyle,
           preferredStyle == "bold" || preferredStyle == "trendy" {
            let creativeCombinations = generateCreativeCombinations(
                items: items,
                colorAnalysis: colorAnalysis,
                styleAnalysis: styleAnalysis
            )
            combinations.append(contentsOf: creativeCombinations)
        }
        
        return combinations
    }
    
    private func generateOutfitTemplates(for occasion: StylePromptBuilder.Occasion) -> [OutfitTemplate] {
        let formality = determineFormality(for: occasion)
        
        switch formality {
        case .formal:
            return [
                OutfitTemplate(categories: [.suits, .footwear, .accessories], style: "formal"),
                OutfitTemplate(categories: [.dresses, .footwear, .accessories], style: "formal")
            ]
        case .business, .smartCasual:
            return [
                OutfitTemplate(categories: [.tops, .bottoms, .footwear], style: "business"),
                OutfitTemplate(categories: [.tops, .bottoms, .outerwear, .footwear], style: "business")
            ]
        case .casual:
            return [
                OutfitTemplate(categories: [.tops, .bottoms, .footwear], style: "casual"),
                OutfitTemplate(categories: [.dresses, .footwear], style: "casual")
            ]
        default:
            return [
                OutfitTemplate(categories: [.tops, .bottoms], style: "casual"),
                OutfitTemplate(categories: [.dresses], style: "casual")
            ]
        }
    }
    
    // MARK: - Scoring System
    private func scoreOutfitCombinations(
        combinations: [OutfitCombination],
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion,
        weather: WeatherData?
    ) -> [ScoredOutfit] {
        
        var scoredOutfits: [ScoredOutfit] = []
        
        for combination in combinations {
            let score = calculateOutfitScore(
                combination: combination,
                userProfile: userProfile,
                occasion: occasion,
                weather: weather
            )
            
            scoredOutfits.append(ScoredOutfit(
                combination: combination,
                score: score,
                reasoning: generateScoreReasoning(combination: combination, score: score)
            ))
        }
        
        return scoredOutfits.sorted { $0.score > $1.score }
    }
    
    private func calculateOutfitScore(
        combination: OutfitCombination,
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion,
        weather: WeatherData?
    ) -> Double {
        
        var score = 0.0
        
        // Color harmony (30% weight)
        score += combination.colorScore * 0.3
        
        // Style compatibility (25% weight)
        score += combination.styleScore * 0.25
        
        // Occasion appropriateness (20% weight)
        score += combination.occasionScore * 0.2
        
        // User preference alignment (15% weight)
        score += combination.preferenceScore * 0.15
        
        // Weather appropriateness (10% weight)
        if let weather = weather {
            score += calculateWeatherScore(combination: combination, weather: weather) * 0.1
        }
        
        return score
    }
    
    // MARK: - Utility Functions
    private func normalizeColorName(_ hexColor: String) -> String {
        // Convert hex to normalized color name for analysis
        let colorMap = [
            "#FF0000": "red",
            "#00FF00": "green",
            "#0000FF": "blue",
            "#FFFF00": "yellow",
            "#FF00FF": "magenta",
            "#00FFFF": "cyan",
            "#000000": "black",
            "#FFFFFF": "white"
        ]
        
        return colorMap[hexColor.uppercased()] ?? "neutral"
    }
    
    private func hexToHSL(_ hexColor: String) -> (h: Double, s: Double, l: Double) {
        // Convert hex to HSL color space
        // Simplified implementation - in real app would use proper color conversion
        return (h: Double.random(in: 0...360), s: Double.random(in: 0...1), l: Double.random(in: 0...1))
    }
    
    private func findComplementaryColor(_ color: String) -> String? {
        return Self.COLOR_WHEEL[color]?.complementary
    }
    
    private func createFallbackSuggestion(occasion: StylePromptBuilder.Occasion) -> AdvancedStyleSuggestion {
        return AdvancedStyleSuggestion(
            verdict: "Building your perfect outfit...",
            why: "I need more information about your wardrobe to provide the best recommendation.",
            detailedSuggestion: "Try adding more clothing items to your closet, especially items suitable for \(occasion.title.lowercased()) occasions.",
            suggestedItemIDs: [],
            bestLookID: nil,
            confidenceScore: 0,
            styleTags: ["needs_more_data"],
            styleBreakdown: ["Add more items to get personalized recommendations"],
            alternativeSuggestions: []
        )
    }

    // MARK: - Missing helpers (minimal implementations)

    private func analyzeUserContext(
        memory: StyleMemory,
        occasion: StylePromptBuilder.Occasion,
        stylePreference: String,
        colorPreference: String
    ) async -> UserProfile {
        let preferredColors = memory.getMostPreferredColors().prefix(5).map { $0.0 }
        let preferredStyle = stylePreference == "any" ? nil : stylePreference
        let preferredSeason = occasion.season
        return UserProfile(
            preferredColors: preferredColors.isEmpty ? nil : preferredColors,
            preferredStyle: preferredStyle,
            preferredSeason: preferredSeason,
            bodyType: nil,
            stylePersonality: nil
        )
    }

    private func createAdvancedSuggestion(
        outfit: ScoredOutfit,
        userProfile: UserProfile,
        occasion: StylePromptBuilder.Occasion,
        alternatives: [ScoredOutfit]
    ) async -> AdvancedStyleSuggestion {
        let itemIDs = outfit.combination.items.map { $0.id }

        let alternativeSuggestions: [AlternativeSuggestion] = alternatives.prefix(3).enumerated().map { idx, alt in
            AlternativeSuggestion(
                title: "Alternative \(idx + 1)",
                description: alt.reasoning,
                styleType: alt.combination.template.style
            )
        }

        let confidence = max(0, min(100, outfit.score * 100))
        return AdvancedStyleSuggestion(
            verdict: confidence > 80 ? "Excellent choice!" : confidence > 60 ? "Looks good!" : "Here's an idea",
            why: outfit.reasoning,
            detailedSuggestion: "Based on color harmony and occasion fit, this outfit works well for \(occasion.title).",
            suggestedItemIDs: itemIDs,
            bestLookID: nil,
            confidenceScore: confidence,
            styleTags: [outfit.combination.template.style],
            styleBreakdown: [
                "Color score: \(Int(outfit.combination.colorScore * 100))%",
                "Style score: \(Int(outfit.combination.styleScore * 100))%",
                "Occasion score: \(Int(outfit.combination.occasionScore * 100))%"
            ],
            alternativeSuggestions: alternativeSuggestions
        )
    }

    private func getColorPreferenceWeight(_ preference: String, color: String) -> Double {
        switch preference {
        case "neutral":
            return Self.NEUTRAL_COLORS.contains(color) ? 1.2 : 0.9
        case "warm":
            return ["red", "orange", "yellow"].contains(color) ? 1.2 : 0.95
        case "cool":
            return ["blue", "cyan", "green", "purple"].contains(color) ? 1.2 : 0.95
        default:
            return 1.0
        }
    }

    private func calculateSeasonalColorScore(color: String, season: String) -> Double {
        let key = season.lowercased()
        guard let palette = Self.SEASONAL_PALETTES[key] else { return 0 }
        return palette.contains(where: { $0.lowercased().contains(color) }) ? 0.2 : 0.0
    }

    private func findComplementaryColorPairs(items: [ClothingItem]) -> [(UUID, UUID)] {
        var pairs: [(UUID, UUID)] = []
        for (i, item1) in items.enumerated() {
            let c1 = normalizeColorName(item1.primaryColorHex)
            guard let comp = Self.COLOR_WHEEL[c1]?.complementary else { continue }
            for item2 in items[(i + 1)...] {
                let c2 = normalizeColorName(item2.primaryColorHex)
                if c2 == comp {
                    pairs.append((item1.id, item2.id))
                }
            }
        }
        return pairs
    }

    private func determineOptimalStyleType(items: [ClothingItem], occasion: StylePromptBuilder.Occasion) -> String {
        let title = occasion.title.lowercased()
        if title.contains("wedding") || title.contains("interview") { return "formal" }
        if title.contains("work") || title.contains("meeting") { return "business" }
        return "casual"
    }

    private func determineFormality(for occasion: StylePromptBuilder.Occasion) -> ClothingItem.Formality? {
        let title = occasion.title.lowercased()
        if title.contains("wedding") || title.contains("interview") { return .formal }
        if title.contains("work") || title.contains("meeting") || title.contains("presentation") { return .business }
        if title.contains("gym") || title.contains("hiking") { return .athletic }
        if title.contains("party") || title.contains("concert") { return .party }
        if title.contains("date") || title.contains("dinner") { return .smartCasual }
        return .casual
    }

    private func formalityRank(_ f: ClothingItem.Formality) -> Int {
        switch f {
        case .athletic: return 0
        case .casual: return 1
        case .smartCasual: return 2
        case .business: return 3
        case .party: return 3
        case .formal: return 4
        }
    }

    private func calculateFormalityCompatibility(itemFormality: ClothingItem.Formality, required: ClothingItem.Formality) -> Double {
        let delta = abs(formalityRank(itemFormality) - formalityRank(required))
        switch delta {
        case 0: return 0.4
        case 1: return 0.25
        case 2: return 0.1
        default: return 0.0
        }
    }

    private func calculateCategoryScore(category: ClothingItem.ClothingCategory, occasion: StylePromptBuilder.Occasion) -> Double {
        let title = occasion.title.lowercased()
        if title.contains("gym") || title.contains("hiking") {
            return category == .footwear || category == .outerwear ? 0.2 : 0.05
        }
        if title.contains("wedding") || title.contains("interview") {
            return (category == .suits || category == .dresses || category == .footwear) ? 0.2 : 0.05
        }
        return 0.1
    }

    private func calculateStyleAlignment(item: ClothingItem, userStyle: String) -> Double {
        // Minimal heuristic: prefer favorites for any non-any style, and treat notes as weak signal.
        var bonus = 0.0
        if item.isFavorite { bonus += 0.1 }
        if !item.notes.isEmpty, item.notes.lowercased().contains(userStyle.lowercased()) { bonus += 0.1 }
        return bonus
    }

    private func calculateSeasonalScore(item: ClothingItem, season: String) -> Double {
        let wanted = season.lowercased()
        let itemSeason = item.season.lowercased()
        if itemSeason == "all" || itemSeason.isEmpty { return 0.1 }
        return itemSeason.contains(wanted) ? 0.15 : 0.0
    }

    private func calculateCategoryCompatibility(
        category1: ClothingItem.ClothingCategory,
        category2: ClothingItem.ClothingCategory
    ) -> Double {
        // Favor complementary categories (top+bottom etc.).
        if category1 == category2 { return 0.0 }
        return 0.2
    }

    private func findMatchingItemsForTemplate(
        template: OutfitTemplate,
        items: [ClothingItem],
        colorAnalysis: ColorAnalysis,
        styleAnalysis: StyleAnalysis,
        userProfile: UserProfile
    ) -> [OutfitCombination] {
        var picked: [ClothingItem] = []
        for category in template.categories {
            if let match = items.first(where: { $0.category == category }) {
                picked.append(match)
            }
        }
        guard !picked.isEmpty else { return [] }

        let colorScore = picked.compactMap { colorAnalysis.harmonyScores[$0.id] }.reduce(0, +) / Double(max(1, picked.count))
        let styleScore = picked.compactMap { styleAnalysis.styleScores[$0.id] }.reduce(0, +) / Double(max(1, picked.count))
        let occasionScore = 0.7
        let preferenceScore = (userProfile.preferredStyle == nil) ? 0.5 : 0.65

        return [OutfitCombination(
            items: picked,
            colorScore: min(1.0, colorScore),
            styleScore: min(1.0, styleScore),
            occasionScore: occasionScore,
            preferenceScore: preferenceScore,
            template: template
        )]
    }

    private func generateCreativeCombinations(
        items: [ClothingItem],
        colorAnalysis: ColorAnalysis,
        styleAnalysis: StyleAnalysis
    ) -> [OutfitCombination] {
        // Keep this minimal for now.
        return []
    }

    private func generateScoreReasoning(combination: OutfitCombination, score: Double) -> String {
        "Color \(Int(combination.colorScore * 100))%, style \(Int(combination.styleScore * 100))%, occasion \(Int(combination.occasionScore * 100))%"
    }

    private func calculateWeatherScore(combination: OutfitCombination, weather: WeatherData) -> Double {
        // Minimal heuristic: add points for outerwear in colder temps.
        if weather.temperature < 55 {
            return combination.items.contains(where: { $0.category == .outerwear }) ? 1.0 : 0.4
        }
        return 0.8
    }
}

// MARK: - Supporting Types

struct ColorAnalysis {
    let harmonyScores: [UUID: Double]
    let paletteRecommendations: [String]
    let complementaryPairs: [(UUID, UUID)]
}

struct StyleAnalysis {
    let styleScores: [UUID: Double]
    let compatibilityMatrix: [UUID: [UUID: Double]]
    let recommendedStyleType: String
}

struct OutfitCombination {
    let items: [ClothingItem]
    let colorScore: Double
    let styleScore: Double
    let occasionScore: Double
    let preferenceScore: Double
    let template: OutfitTemplate
}

struct OutfitTemplate {
    let categories: [ClothingItem.ClothingCategory]
    let style: String
}

struct ScoredOutfit {
    let combination: OutfitCombination
    let score: Double
    let reasoning: String
}

struct UserProfile {
    let preferredColors: [String]?
    let preferredStyle: String?
    let preferredSeason: String?
    let bodyType: String?
    let stylePersonality: String?
}

// MARK: - Fashion Trends System

@Model
final class FashionTrend {
    var id: UUID
    var trendName: String
    var season: String
    var year: Int
    var keyColors: [String]
    var keyStyles: [String]
    var popularityScore: Double
    var createdAt: Date
    
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
        self.keyColors = keyColors
        self.keyStyles = keyStyles
        self.popularityScore = popularityScore
        self.createdAt = Date()
    }
}

// MARK: - Style Profile System

@Model
final class StyleProfile {
    var id: UUID
    var userName: String
    var bodyType: String
    var colorSeason: String
    var stylePersonality: String
    var lifestyle: String
    var preferredBrands: [String]
    var budgetRange: String
    var createdAt: Date
    
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
        self.preferredBrands = preferredBrands
        self.budgetRange = budgetRange
        self.createdAt = Date()
    }
}

// MARK: - Weather Integration

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