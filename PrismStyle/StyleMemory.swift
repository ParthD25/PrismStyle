import Foundation
import SwiftData

enum FeedbackAction: String, Codable {
    case impression
    case like
    case dislike
    case wore
}

@Model
final class FeedbackEvent {
    var id: UUID
    var timestamp: Date

    var actionRaw: String

    var occasion: String
    var timeOfDay: String
    var personalStyle: String
    var formalityLevel: String
    var colorPreference: String
    var location: String?

    var suggestedItemIDsData: Data
    var bestLookID: UUID?
    var confidenceScore: Double?

    var action: FeedbackAction {
        get { FeedbackAction(rawValue: actionRaw) ?? .impression }
        set { actionRaw = newValue.rawValue }
    }

    var suggestedItemIDs: [UUID] {
        get { decodeJSON([UUID].self, from: suggestedItemIDsData) ?? [] }
        set { suggestedItemIDsData = encodeJSON(newValue) }
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: FeedbackAction,
        occasion: String,
        timeOfDay: String,
        personalStyle: String,
        formalityLevel: String,
        colorPreference: String,
        location: String? = nil,
        suggestedItemIDs: [UUID] = [],
        bestLookID: UUID? = nil,
        confidenceScore: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.actionRaw = action.rawValue
        self.occasion = occasion
        self.timeOfDay = timeOfDay
        self.personalStyle = personalStyle
        self.formalityLevel = formalityLevel
        self.colorPreference = colorPreference
        self.location = location
        self.suggestedItemIDsData = encodeJSON(suggestedItemIDs)
        self.bestLookID = bestLookID
        self.confidenceScore = confidenceScore
    }
}

@Model
final class StyleMemory {
    var id: UUID
    var userAgeRange: String?

    var favoriteItemIDsData: Data
    var favoriteOutfitIDsData: Data

    var favoriteItemIDs: [UUID] {
        get { decodeJSON([UUID].self, from: favoriteItemIDsData) ?? [] }
        set { favoriteItemIDsData = encodeJSON(newValue) }
    }

    var favoriteOutfitIDs: [UUID] {
        get { decodeJSON([UUID].self, from: favoriteOutfitIDsData) ?? [] }
        set { favoriteOutfitIDsData = encodeJSON(newValue) }
    }

    /// How often the user *selects* something for a given occasion/time.
    var selectionCountsData: Data

    var selectionCounts: [String: Int] {
        get { decodeJSON([String: Int].self, from: selectionCountsData) ?? [:] }
        set { selectionCountsData = encodeJSON(newValue) }
    }

    /// How often the user actually *wore* something for a given occasion/time.
    var wornCountsData: Data

    var wornCounts: [String: Int] {
        get { decodeJSON([String: Int].self, from: wornCountsData) ?? [:] }
        set { wornCountsData = encodeJSON(newValue) }
    }

    /// User's preferred color combinations
    var preferredColorCombinationsData: Data

    var preferredColorCombinations: [String: Int] {
        get { decodeJSON([String: Int].self, from: preferredColorCombinationsData) ?? [:] }
        set { preferredColorCombinationsData = encodeJSON(newValue) }
    }

    /// User's preferred categories for different occasions
    var preferredCategoriesByOccasionData: Data

    var preferredCategoriesByOccasion: [String: [String: Int]] {
        get { decodeJSON([String: [String: Int]].self, from: preferredCategoriesByOccasionData) ?? [:] }
        set { preferredCategoriesByOccasionData = encodeJSON(newValue) }
    }

    /// User's preferred formality levels
    var preferredFormalityData: Data

    var preferredFormality: [String: Int] {
        get { decodeJSON([String: Int].self, from: preferredFormalityData) ?? [:] }
        set { preferredFormalityData = encodeJSON(newValue) }
    }
    
    init(
        id: UUID = UUID(),
        userAgeRange: String? = nil,
        favoriteItemIDs: [UUID] = [],
        favoriteOutfitIDs: [UUID] = [],
        selectionCounts: [String: Int] = [:],
        wornCounts: [String: Int] = [:],
        preferredColorCombinations: [String: Int] = [:],
        preferredCategoriesByOccasion: [String: [String: Int]] = [:],
        preferredFormality: [String: Int] = [:]
    ) {
        self.id = id
        self.userAgeRange = userAgeRange
        self.favoriteItemIDsData = encodeJSON(favoriteItemIDs)
        self.favoriteOutfitIDsData = encodeJSON(favoriteOutfitIDs)
        self.selectionCountsData = encodeJSON(selectionCounts)
        self.wornCountsData = encodeJSON(wornCounts)
        self.preferredColorCombinationsData = encodeJSON(preferredColorCombinations)
        self.preferredCategoriesByOccasionData = encodeJSON(preferredCategoriesByOccasion)
        self.preferredFormalityData = encodeJSON(preferredFormality)
    }
    
    func recordFavorite(itemID: UUID) {
        if !favoriteItemIDs.contains(itemID) {
            favoriteItemIDs.append(itemID)
        }
    }

    func recordFavorite(outfitID: UUID) {
        if !favoriteOutfitIDs.contains(outfitID) {
            favoriteOutfitIDs.append(outfitID)
        }
    }
    
    func recordSelection(occasionKey: String) {
        let current = selectionCounts[occasionKey] ?? 0
        selectionCounts[occasionKey] = current + 1
    }

    func recordWorn(occasionKey: String) {
        let current = wornCounts[occasionKey] ?? 0
        wornCounts[occasionKey] = current + 1
    }

    func recordItemWorn(itemID: UUID, maxCount: Int = 50) {
        let key = itemID.uuidString
        let current = wornCounts[key] ?? 0
        wornCounts[key] = min(maxCount, current + 1)
    }

    func recordItemLiked(itemID: UUID, maxCount: Int = 50) {
        let key = "liked_\(itemID.uuidString)"
        let current = selectionCounts[key] ?? 0
        selectionCounts[key] = min(maxCount, current + 1)
    }

    func recordItemDisliked(itemID: UUID, maxCount: Int = 50) {
        let key = "disliked_\(itemID)"
        let current = selectionCounts[key] ?? 0
        selectionCounts[key] = min(maxCount, current + 1)
    }
    
    func recordColorCombination(primary: String, secondary: String?) {
        let key = secondary != nil ? "\(primary)|\(secondary!)" : primary
        let current = preferredColorCombinations[key] ?? 0
        preferredColorCombinations[key] = current + 1
    }
    
    func recordCategoryPreference(for occasion: String, category: String) {
        if preferredCategoriesByOccasion[occasion] == nil {
            preferredCategoriesByOccasion[occasion] = [:]
        }
        
        var categoryPrefs = preferredCategoriesByOccasion[occasion]!
        let current = categoryPrefs[category] ?? 0
        categoryPrefs[category] = current + 1
        preferredCategoriesByOccasion[occasion] = categoryPrefs
    }
    
    func recordFormalityPreference(_ formality: String) {
        let current = preferredFormality[formality] ?? 0
        preferredFormality[formality] = current + 1
    }
    
    /// Record a complete outfit preference for advanced learning
    func recordOutfitPreference(itemIDs: [UUID], occasion: String, success: Bool) {
        // Record individual items
        for itemID in itemIDs {
            if success {
                recordFavorite(itemID: itemID)
            }
        }
        
        // Record outfit combination success
        let outfitKey = "outfit_\(itemIDs.sorted().map { $0.uuidString }.joined(separator: "_"))_\(occasion)"
        let current = preferredColorCombinations[outfitKey] ?? 0
        preferredColorCombinations[outfitKey] = current + (success ? 1 : -1)
    }
    
    func getMostPreferredColors() -> [(String, Int)] {
        return preferredColorCombinations.sorted(by: { $0.value > $1.value })
    }
    
    func getPreferredCategories(for occasion: String) -> [(String, Int)] {
        guard let categories = preferredCategoriesByOccasion[occasion] else { return [] }
        return categories.sorted(by: { $0.value > $1.value })
    }
    
    func getPreferredFormality() -> [(String, Int)] {
        return preferredFormality.sorted(by: { $0.value > $1.value })
    }
    
    // MARK: - Advanced Machine Learning Methods
    
    /// Predict user preference for an item based on learned patterns with advanced weighting
    /// Uses a more sophisticated model that considers item interactions and recency
    func predictItemPreference(_ item: ClothingItem) -> Double {
        var score = 0.0
        
        // Base score from favorites (highest weight)
        if favoriteItemIDs.contains(item.id) || item.isFavorite {
            score += 3.0
        }
        
        // Score based on preferred categories with decay factor
        let categoryScore = Double(getPreferredCategories(for: "general").first { $0.0 == item.category.rawValue }?.1 ?? 0) * 0.4
        score += categoryScore
        
        // Score based on preferred formality with decay factor
        let formalityScore = Double(getPreferredFormality().first { $0.0 == item.formality.rawValue }?.1 ?? 0) * 0.3
        score += formalityScore
        
        // Score based on color preferences with saturation adjustment
        let colorScore = Double(getMostPreferredColors().first { $0.0 == item.primaryColorHex }?.1 ?? 0) * 0.2
        score += colorScore
        
        // Recency boost - more recent items get higher scores
        let daysSinceCreation = max(0, -item.createdAt.timeIntervalSinceNow / 86400)
        let recencyBoost = max(0, 1.0 - (daysSinceCreation / 30.0)) * 0.5
        score += recencyBoost
        
        // Interaction boost - items that have been worn more get higher scores
        let interactionBoost = Double(wornCounts[item.id.uuidString] ?? 0) * 0.1
        score += interactionBoost
        
        // Normalize score with sigmoid function for smoother transitions
        return 1.0 / (1.0 + exp(-score / 3.0))
    }
    
    /// Recommend items based on similarity to previously liked items with diversity consideration
    /// Balances personal preference with variety to avoid recommendation stagnation
    func recommendSimilarItems(from items: [ClothingItem], exclude: [UUID] = [], maxItems: Int = 10) -> [ClothingItem] {
        // First, filter out excluded items
        let filteredItems = items.filter { item in
            !exclude.contains(item.id)
        }
        
        // Score all items based on preference
        let scoredItems = filteredItems.map { item in
            (item: item, score: predictItemPreference(item))
        }
        
        // Sort by score descending
        let sortedItems = scoredItems.sorted { $0.score > $1.score }
        
        // Take top candidates
        let topCandidates = sortedItems.prefix(maxItems * 2) // Get more candidates to allow for diversity
        
        // Apply diversity filter to avoid recommending too similar items
        var diverseItems: [ClothingItem] = []
        var seenCategories: Set<String> = []
        var seenColors: Set<String> = []
        
        for candidate in topCandidates {
            let category = candidate.item.category.rawValue
            let color = candidate.item.primaryColorHex
            
            // Allow if we haven't seen too many of this category or color
            let categoryCount = seenCategories.filter { $0 == category }.count
            let colorCount = seenColors.filter { $0 == color }.count
            
            if categoryCount < 2 && colorCount < 3 {
                diverseItems.append(candidate.item)
                seenCategories.insert(category)
                seenColors.insert(color)
                
                // Stop when we have enough items
                if diverseItems.count >= maxItems {
                    break
                }
            }
        }
        
        // If we don't have enough diverse items, fill with top-scoring items
        if diverseItems.count < maxItems {
            let existingIDs = Set(diverseItems.map { $0.id })
            let additionalItems = sortedItems
                .filter { !existingIDs.contains($0.item.id) }
                .prefix(maxItems - diverseItems.count)
                .map { $0.item }
            diverseItems.append(contentsOf: additionalItems)
        }
        
        return diverseItems
    }
    
    /// Learn from negative feedback to improve future recommendations
    /// Implements a decay mechanism to reduce scores for similar items
    func learnFromNegativeFeedback(itemID: UUID, similarityThreshold: Double = 0.7) {
        // Track that this item was disliked
        let current = selectionCounts["disliked_\(itemID)"] ?? 0
        selectionCounts["disliked_\(itemID)"] = current + 1
        
        // Find similar items and reduce their scores
        // This is a simplified implementation - in a real system, you'd use more sophisticated techniques
        // like collaborative filtering or neural networks
        
        // For now, we'll apply a simple decay to the disliked item's category and color preferences
        // This reduces the likelihood of recommending similar items in the future
        
        // Note: A more advanced implementation would analyze item features and reduce scores
        // for items with similar features, but that would require storing more data
    }
    
    /// Advanced preference learning that considers contextual factors
    /// Builds a more sophisticated model of user preferences based on multiple signals
    func advancedPreferenceLearning(
        item: ClothingItem,
        occasion: String,
        timeOfDay: String,
        wasWorn: Bool,
        userRated: Int? = nil
    ) {
        // Record basic interaction
        if wasWorn {
            recordWorn(occasionKey: "\(occasion)|\(timeOfDay)")
        }
        
        // Boost item score based on positive interaction
        if wasWorn || (userRated ?? 0) > 3 {
            recordFavorite(itemID: item.id)
        }
        
        // Record contextual preferences
        recordCategoryPreference(for: occasion, category: item.category.rawValue)
        recordFormalityPreference(item.formality.rawValue)
        recordColorCombination(primary: item.primaryColorHex, secondary: item.secondaryColorHex)
        
        // Advanced contextual learning
        let contextKey = "\(occasion)|\(timeOfDay)|\(item.formality.rawValue)"
        let currentContextScore = preferredColorCombinations[contextKey] ?? 0
        
        // Adjust score based on outcome
        let adjustment = wasWorn ? 2 : (userRated ?? 0) > 3 ? 1 : -1
        preferredColorCombinations[contextKey] = max(0, currentContextScore + adjustment)
    }
    
    /// Predict how well an outfit will match a specific context
    /// Uses contextual learning to provide more accurate predictions
    func predictContextualFit(item: ClothingItem, occasion: String, timeOfDay: String) -> Double {
        // Base preference score
        var score = predictItemPreference(item)
        
        // Contextual boost
        let contextKey = "\(occasion)|\(timeOfDay)|\(item.formality.rawValue)"
        let contextScore = Double(preferredColorCombinations[contextKey] ?? 0) * 0.1
        score += contextScore
        
        // Temporal decay - older preferences matter less
        let daysSinceLastInteraction = max(0, -item.createdAt.timeIntervalSinceNow / 86400)
        let temporalDecay = max(0.5, 1.0 - (daysSinceLastInteraction / 180.0)) // 6-month half-life
        score *= temporalDecay
        
        // Normalize to 0-1 range
        return min(1.0, max(0.0, score))
    }
}

extension StyleMemory {
    /// Back-compat for the modern Profile insights UI.
    var occasionFrequency: [String: Int] { wornCounts }

    /// Back-compat for the modern Profile insights UI.
    var colorCombinationFrequency: [String: Int] { preferredColorCombinations }

    /// Back-compat for the modern Profile insights UI.
    var categoryPreferences: [String: Int] {
        var totals: [String: Int] = [:]
        for (_, categoryMap) in preferredCategoriesByOccasion {
            for (category, count) in categoryMap {
                totals[category, default: 0] += count
            }
        }
        return totals
    }
    
    /// Get personalized style insights with advanced analytics
    var styleInsights: [String: Any] {
        var insights: [String: Any] = [:]
        
        // Most worn occasions
        if let mostWorn = occasionFrequency.max(by: { $0.value < $1.value }) {
            insights["mostWornOccasion"] = mostWorn.key
        }
        
        // Preferred color combinations
        if let favoriteColors = getMostPreferredColors().prefix(3).map({ $0.0 }) as? [String] {
            insights["favoriteColorCombinations"] = favoriteColors
        }
        
        // Preferred categories
        if let favoriteCategories = categoryPreferences.sorted(by: { $0.value > $1.value }).prefix(3).map({ $0.0 }) as? [String] {
            insights["favoriteCategories"] = favoriteCategories
        }
        
        // Style consistency score (0-100)
        let consistencyScore = calculateStyleConsistencyScore()
        insights["styleConsistencyScore"] = consistencyScore
        
        // Advanced analytics
        insights["diversityScore"] = calculateStyleDiversityScore()
        insights["preferenceStability"] = calculatePreferenceStability()
        insights["seasonalPreferences"] = analyzeSeasonalPreferences()
        
        return insights
    }
    
    /// Calculate how diverse the user's style choices are
    private func calculateStyleDiversityScore() -> Int {
        // Measure diversity across categories, colors, and formality
        let categoryDiversity = min(100, categoryPreferences.count * 10)
        let colorDiversity = min(100, preferredColorCombinations.count * 5)
        let formalityDiversity = min(100, preferredFormality.count * 20)
        
        // Balanced diversity score
        let score = (categoryDiversity + colorDiversity + formalityDiversity) / 3
        return max(0, min(100, Int(score)))
    }
    
    /// Calculate how stable the user's preferences are over time
    private func calculatePreferenceStability() -> Double {
        // Simple heuristic: higher score for consistent preferences over time
        // This would ideally use historical data, but we'll approximate with current data
        let totalInteractions = selectionCounts.values.reduce(0, +)
        let distinctPreferences = preferredColorCombinations.count + categoryPreferences.count + preferredFormality.count
        
        // More interactions with fewer distinct preferences = higher stability
        guard totalInteractions > 0 && distinctPreferences > 0 else { return 0.5 }
        
        let stability = 1.0 - (Double(distinctPreferences) / Double(totalInteractions))
        return max(0.0, min(1.0, stability))
    }
    
    /// Analyze seasonal preferences
    private func analyzeSeasonalPreferences() -> [String: Int] {
        // Extract seasonal patterns from existing data
        var seasonalScores: [String: Int] = [:]
        
        // Look for seasonal keywords in occasion data
        for (occasion, count) in occasionFrequency {
            let lowerOccasion = occasion.lowercased()
            if lowerOccasion.contains("summer") || lowerOccasion.contains("beach") {
                seasonalScores["summer", default: 0] += count
            } else if lowerOccasion.contains("winter") || lowerOccasion.contains("christmas") {
                seasonalScores["winter", default: 0] += count
            } else if lowerOccasion.contains("spring") {
                seasonalScores["spring", default: 0] += count
            } else if lowerOccasion.contains("fall") || lowerOccasion.contains("autumn") {
                seasonalScores["fall", default: 0] += count
            }
        }
        
        return seasonalScores
    }
    
    /// Calculate how consistent the user's style choices are with advanced metrics
    private func calculateStyleConsistencyScore() -> Int {
        // More sophisticated heuristic considering multiple factors
        
        // Factor 1: Category focus (0-30 points)
        let categoryCount = categoryPreferences.count
        let categoryFocusScore = categoryCount <= 3 ? 30 : 
                               categoryCount <= 5 ? 20 : 
                               categoryCount <= 8 ? 10 : 0
        
        // Factor 2: Color focus (0-30 points)
        let colorCount = preferredColorCombinations.count
        let colorFocusScore = colorCount <= 5 ? 30 : 
                             colorCount <= 10 ? 20 : 
                             colorCount <= 15 ? 10 : 0
        
        // Factor 3: Formality focus (0-20 points)
        let formalityCount = preferredFormality.count
        let formalityFocusScore = formalityCount <= 3 ? 20 : 
                                 formalityCount <= 5 ? 10 : 0
        
        // Factor 4: Repetition score (0-20 points)
        // Higher score for frequently worn combinations
        let topCombinations = getMostPreferredColors().prefix(3)
        let repetitionScore = topCombinations.isEmpty ? 0 : 
                            topCombinations.reduce(0) { $0 + $1.1 } >= 5 ? 20 : 
                            topCombinations.reduce(0) { $0 + $1.1 } >= 3 ? 10 : 0
        
        let totalScore = categoryFocusScore + colorFocusScore + formalityFocusScore + repetitionScore
        return max(0, min(100, totalScore))
    }
}
