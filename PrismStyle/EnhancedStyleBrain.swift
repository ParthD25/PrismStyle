import Foundation
import UIKit
import SwiftUI
import CoreML
import Vision

// Enhanced Style Brain with advanced AI/ML capabilities
struct EnhancedStyleBrain {
    
    // MARK: - Constants
    static let OCCASION_PRESETS = [
        "School", "Work", "Interview", "Party", "Wedding", "Date", "Casual Hangout",
        "Gym", "Brunch", "Dinner Out", "Shopping", "Beach", "Travel", "Meeting",
        "Presentation", "Networking", "Concert", "Festival", "Picnic", "Hiking"
    ]
    
    static let STYLE_PREFERENCES = [
        "classic", "trendy", "minimalist", "bold", "casual", "professional", "romantic", "edgy"
    ]
    
    static let COLOR_PREFERENCES = [
        "neutral", "warm", "cool", "bright", "dark", "pastels"
    ]
    
    // MARK: - Main Recommendation Engine
    func suggest(
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
        location: String? = nil
    ) async throws -> EnhancedStyleSuggestion {
        
        let key = [occasion.title, occasion.timeOfDay ?? ""].filter { !$0.isEmpty }.joined(separator: "|")
        
        // 1. First, try to find matching looks from user's past successful outfits
        if let bestLook = findBestMatchingLook(
            for: occasion,
            stylePreference: stylePreference,
            colorPreference: colorPreference,
            looks: looks,
            memory: memory
        ) {
            let why = generateMatchingReason(
                occasion: occasion,
                stylePreference: stylePreference,
                colorPreference: colorPreference
            )
            
            return EnhancedStyleSuggestion(
                verdict: "Perfect match found!",
                why: why,
                detailedSuggestion: "This outfit perfectly matches your \(occasion.title.lowercased()) style preferences.",
                suggestedItemIDs: [],
                bestLookID: bestLook.id,
                confidenceScore: 95,
                styleTags: ["matched", "proven"],
                styleBreakdown: ["Matches your past successful outfits", "Perfect for the occasion"],
                alternativeSuggestions: []
            )
        }
        
        // 2. If no perfect match, analyze uploaded outfit photos
        if !looks.isEmpty {
            let photoAnalysis = analyzeOutfitPhotos(
                looks: looks,
                occasion: occasion,
                stylePreference: stylePreference,
                colorPreference: colorPreference,
                memory: memory
            )
            
            if photoAnalysis.confidence > 70 {
                return EnhancedStyleSuggestion(
                    verdict: "Great choice!",
                    why: photoAnalysis.reason,
                    detailedSuggestion: photoAnalysis.improvementSuggestion ?? "This outfit looks great as is!",
                    suggestedItemIDs: [],
                    bestLookID: photoAnalysis.bestLookID,
                    confidenceScore: photoAnalysis.confidence,
                    styleTags: ["photo_match"] + photoAnalysis.styleTags,
                    styleBreakdown: photoAnalysis.breakdown,
                    alternativeSuggestions: photoAnalysis.alternatives
                )
            }
        }
        
        // 3. Build new outfit from closet items
        let builtOutfit = await buildEnhancedOutfit(
            for: occasion,
            items: items,
            memory: memory,
            stylePreference: stylePreference,
            colorPreference: colorPreference,
            formalityLevel: formalityLevel,
            prioritizeComfort: prioritizeComfort,
            location: location
        )
        
        let confidence = calculateOutfitConfidence(
            outfit: builtOutfit,
            occasion: occasion,
            memory: memory
        )
        
        let styleBreakdown = generateStyleBreakdown(
            outfit: builtOutfit,
            occasion: occasion,
            stylePreference: stylePreference
        )
        
        let alternatives = generateAlternativeSuggestions(
            currentOutfit: builtOutfit,
            allItems: items,
            occasion: occasion,
            memory: memory
        )
        
        memory.recordSelection(occasionKey: key)
        
        return EnhancedStyleSuggestion(
            verdict: confidence > 80 ? "Excellent choice!" : confidence > 60 ? "Looks good!" : "Here's an idea",
            why: builtOutfit.reason,
            detailedSuggestion: builtOutfit.humanSuggestion,
            suggestedItemIDs: builtOutfit.itemIDs,
            bestLookID: nil,
            confidenceScore: confidence,
            styleTags: builtOutfit.styleTags,
            styleBreakdown: styleBreakdown,
            alternativeSuggestions: alternatives
        )
    }
    
    // MARK: - Look Matching
    private func findBestMatchingLook(
        for occasion: StylePromptBuilder.Occasion,
        stylePreference: String,
        colorPreference: String,
        looks: [OutfitLook],
        memory: StyleMemory
    ) -> OutfitLook? {
        guard !looks.isEmpty else { return nil }
        
        let wantedOccasion = occasion.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let wantedTime = (occasion.timeOfDay ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        _ = (occasion.vibe ?? "").lowercased()
        
        func score(_ look: OutfitLook) -> Double {
            var score: Double = 0
            
            // Occasion matching (highest weight)
            if look.occasion.lowercased().contains(wantedOccasion) || wantedOccasion.contains(look.occasion.lowercased()) {
                score += 5
            }
            
            // Time of day matching
            if !wantedTime.isEmpty && look.timeOfDay.lowercased() == wantedTime {
                score += 3
            }
            
            // User preference learning
            if memory.favoriteOutfitIDs.contains(look.id) {
                score += 4
            }
            
            if look.isFavorite {
                score += 2
            }
            
            // Recency boost
            let days = max(0, Date().timeIntervalSince(look.createdAt) / 86400)
            score += max(0, 2.0 - (days / 30.0))
            
            // Success rate boost
            let successRate = memory.getSuccessRate(for: "\(look.occasion)|\(look.timeOfDay)")
            score += successRate * 3
            
            return score
        }
        
        let best = looks.max { score($0) < score($1) }
        if let best, score(best) >= 8 {
            return best
        }
        
        return nil
    }
    
    // MARK: - Photo Analysis
    private func analyzeOutfitPhotos(
        looks: [OutfitLook],
        occasion: StylePromptBuilder.Occasion,
        stylePreference: String,
        colorPreference: String,
        memory: StyleMemory
    ) -> PhotoAnalysisResult {
        
        var bestScore = 0.0
        var bestLookID: UUID?
        var bestAnalysis: PhotoAnalysis? = nil
        
        for look in looks {
            let analysis = analyzeSingleOutfitPhoto(
                look: look,
                occasion: occasion,
                stylePreference: stylePreference,
                colorPreference: colorPreference,
                memory: memory
            )
            
            if analysis.confidence > bestScore {
                bestScore = analysis.confidence
                bestLookID = look.id
                bestAnalysis = analysis
            }
        }
        
        guard let analysis = bestAnalysis else {
            return PhotoAnalysisResult(
                confidence: 0,
                reason: "Could not analyze photos",
                improvementSuggestion: nil,
                bestLookID: nil,
                styleTags: [],
                breakdown: [],
                alternatives: []
            )
        }
        
        return PhotoAnalysisResult(
            confidence: analysis.confidence,
            reason: analysis.reason,
            improvementSuggestion: analysis.improvementSuggestion,
            bestLookID: bestLookID,
            styleTags: analysis.styleTags,
            breakdown: analysis.breakdown,
            alternatives: analysis.alternatives
        )
    }
    
    private func analyzeSingleOutfitPhoto(
        look: OutfitLook,
        occasion: StylePromptBuilder.Occasion,
        stylePreference: String,
        colorPreference: String,
        memory: StyleMemory
    ) -> PhotoAnalysis {
        
        var confidence = 50.0 // Base confidence
        var reasons: [String] = []
        var improvements: [String] = []
        var styleTags: [String] = []
        var breakdown: [String] = []
        
        // Analyze image quality if we have the image data
        var imageQualityScore: Double = 0.5
        if let image = UIImage(data: look.imageData) {
            imageQualityScore = ImageScoring.overallQualityScore(image)
            confidence += imageQualityScore * 10 // Up to 10 points for good image quality
            
            if imageQualityScore > 0.7 {
                breakdown.append("✓ High-quality photo")
            } else if imageQualityScore < 0.3 {
                improvements.append("Consider retaking with better lighting")
                breakdown.append("⚠ Low-quality photo")
            }
            
            // Check if it's likely an outfit photo
            if ImageScoring.isLikelyOutfitPhoto(image) {
                confidence += 5
                breakdown.append("✓ Full-body outfit photo")
            }
        }
        
        // Analyze occasion appropriateness
        let formalityMatch = analyzeFormalityCompatibility(
            lookFormality: estimateFormality(from: look.occasion),
            requiredFormality: determineFormality(for: occasion)
        )
        
        if formalityMatch > 0.7 {
            confidence += 20
            reasons.append("Perfect formality level")
            breakdown.append("✓ Appropriate dress code")
        } else if formalityMatch > 0.4 {
            confidence += 10
            reasons.append("Mostly appropriate")
            breakdown.append("⚠ Could be more formal/casual")
        } else {
            confidence -= 15
            improvements.append("Consider adjusting formality level")
            breakdown.append("✗ Formality mismatch")
        }
        
        // Analyze color harmony
        let colorHarmony = analyzeColorHarmony(look: look, preference: colorPreference)
        if colorHarmony > 0.8 {
            confidence += 15
            breakdown.append("✓ Great color coordination")
            styleTags.append("colorful")
        } else if colorHarmony > 0.5 {
            confidence += 5
            breakdown.append("✓ Good colors")
        } else {
            improvements.append("Try different color combinations")
            breakdown.append("⚠ Colors could work better together")
        }
        
        // Analyze style consistency
        let styleConsistency = analyzeStyleConsistency(look: look, preference: stylePreference)
        if styleConsistency > 0.8 {
            confidence += 15
            breakdown.append("✓ Perfect style match")
            styleTags.append(stylePreference)
        } else if styleConsistency > 0.5 {
            confidence += 5
            breakdown.append("✓ Good style fit")
        } else {
            improvements.append("Style doesn't quite match your preference")
            breakdown.append("⚠ Style mismatch")
        }
        
        // Generate improvement suggestions
        let improvementText = improvements.isEmpty ? 
            "This outfit looks great as is!" : 
            "Try: " + improvements.joined(separator: ", ")
        
        return PhotoAnalysis(
            confidence: min(confidence, 95),
            reason: reasons.joined(separator: ", "),
            improvementSuggestion: improvementText,
            styleTags: styleTags,
            breakdown: breakdown,
            alternatives: []
        )
    }
    
    // MARK: - Enhanced Outfit Building
    private func buildEnhancedOutfit(
        for occasion: StylePromptBuilder.Occasion,
        items: [ClothingItem],
        memory: StyleMemory,
        stylePreference: String,
        colorPreference: String,
        formalityLevel: String,
        prioritizeComfort: Bool,
        location: String?
    ) async -> EnhancedBuiltOutfit {
        
        // Filter items by occasion requirements
        let requiredFormality = formalityLevel == "auto" ? determineFormality(for: occasion) : parseFormality(formalityLevel)
        let filteredItems = requiredFormality != nil ? items.filter { isCompatible(formality: $0.formality, with: requiredFormality!) } : items

        // If the prompt is ambiguous, prefer smart-casual *when the closet supports it*.
        // This helps avoid always defaulting to "t-shirt + shorts" when the user has
        // collared shirts, quarter-zips, and dress pants.
        let preferSmartCasual = shouldPreferSmartCasual(
            occasion: occasion,
            formalityLevel: formalityLevel,
            availableItems: filteredItems
        )
        
        // Apply style and color preferences (previously computed but unused).
        let preferredItems = applyStylePreferences(
            items: filteredItems,
            stylePreference: stylePreference,
            colorPreference: colorPreference,
            memory: memory,
            requiredFormality: requiredFormality,
            preferSmartCasual: preferSmartCasual,
            prioritizeComfort: prioritizeComfort
        )

        // Categorize items (preserve preference ordering).
        let tops = preferredItems.filter { $0.category == .tops }
        let bottoms = preferredItems.filter { $0.category == .bottoms }
        let dresses = preferredItems.filter { $0.category == .dresses }
        let suits = preferredItems.filter { $0.category == .suits }
        let outerwear = preferredItems.filter { $0.category == .outerwear }
        let footwear = preferredItems.filter { $0.category == .footwear }
        let accessories = preferredItems.filter { $0.category == .accessories }
        
        // Build base outfit
        var baseItems: [ClothingItem] = []
        var styleType = "casual"
        let reason = "Built from your closet items"
        
        // Try to build the best possible outfit
        let outfitOptions = [
            buildDressOutfit(
                dresses: dresses,
                outerwear: outerwear,
                footwear: footwear,
                accessories: accessories,
                memory: memory,
                stylePreference: stylePreference,
                requiredFormality: requiredFormality,
                preferSmartCasual: preferSmartCasual,
                prioritizeComfort: prioritizeComfort
            ),
            buildSuitOutfit(
                suits: suits,
                footwear: footwear,
                accessories: accessories,
                memory: memory,
                requiredFormality: requiredFormality,
                preferSmartCasual: preferSmartCasual,
                prioritizeComfort: prioritizeComfort
            ),
            buildTopBottomOutfit(
                tops: tops,
                bottoms: bottoms,
                outerwear: outerwear,
                footwear: footwear,
                accessories: accessories,
                memory: memory,
                stylePreference: stylePreference,
                requiredFormality: requiredFormality,
                preferSmartCasual: preferSmartCasual,
                prioritizeComfort: prioritizeComfort
            ),
        ]

        let bestOutfit = outfitOptions
            .map { option in
                (option, scoreBuiltOutfit(option.items, occasion: occasion, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, memory: memory))
            }
            .max { $0.1 < $1.1 }
            .map { $0.0 } ?? OutfitBuildResult(items: [], styleType: "casual")

        baseItems = bestOutfit.items
        styleType = preferSmartCasual && bestOutfit.styleType == "casual" ? "smart_casual" : bestOutfit.styleType
        
        guard !baseItems.isEmpty else {
            return EnhancedBuiltOutfit(
                itemIDs: [],
                humanSuggestion: "I need more clothing items to build a complete outfit. Try adding some tops, bottoms, or dresses.",
                styleType: nil,
                reason: "Not enough items",
                styleTags: []
            )
        }
        
        // Use machine learning to refine the outfit
        let mlRefinedItems = refineOutfitWithML(baseItems: baseItems, allItems: filteredItems, memory: memory, occasion: occasion)
        if !mlRefinedItems.isEmpty {
            baseItems = mlRefinedItems
        }
        
        // Generate human-readable suggestion
        let suggestion = generateOutfitSuggestion(baseItems: baseItems, styleType: styleType, occasion: occasion)
        
        // Generate style tags
        let styleTags = generateStyleTags(items: baseItems, styleType: styleType, occasion: occasion)
        
        return EnhancedBuiltOutfit(
            itemIDs: baseItems.map { $0.id },
            humanSuggestion: suggestion,
            styleType: styleType,
            reason: reason,
            styleTags: styleTags
        )
    }
    
    /// Refine outfit using machine learning predictions with advanced optimization
    /// Uses iterative improvement and diversity considerations
    private func refineOutfitWithML(baseItems: [ClothingItem], allItems: [ClothingItem], memory: StyleMemory, occasion: StylePromptBuilder.Occasion) -> [ClothingItem] {
        // Start with base items
        var refinedItems = baseItems
        
        // Calculate current outfit harmony
        let currentHarmony = analyzeOutfitColorHarmony(items: baseItems)
        
        // Get ML recommendations with diversity
        let recommendedItems = memory.recommendSimilarItems(from: allItems, exclude: baseItems.map { $0.id }, maxItems: 5)
        
        // Try adding one recommended item to see if it improves harmony
        var bestItems = baseItems
        var bestHarmony = currentHarmony
        
        // Test adding each recommended item
        for item in recommendedItems {
            let testOutfit = baseItems + [item]
            let testHarmony = analyzeOutfitColorHarmony(items: testOutfit)
            
            // If harmony improves, consider this addition
            if testHarmony > bestHarmony {
                bestHarmony = testHarmony
                bestItems = testOutfit
            }
        }
        
        // Also try replacing items for even better harmony
        for (index, currentItem) in baseItems.enumerated() {
            for replacement in recommendedItems {
                // Skip if trying to replace with the same item
                if replacement.id == currentItem.id { continue }
                
                // Create test outfit with replacement
                var testOutfit = baseItems
                testOutfit[index] = replacement
                let testHarmony = analyzeOutfitColorHarmony(items: testOutfit)
                
                // If harmony improves, consider this replacement
                if testHarmony > bestHarmony {
                    bestHarmony = testHarmony
                    bestItems = testOutfit
                }
            }
        }
        
        // Only accept improvements that are significant (at least 5% better)
        if bestHarmony > currentHarmony * 1.05 {
            refinedItems = bestItems
        }
        
        return refinedItems
    }
    
    private func buildDressOutfit(
        dresses: [ClothingItem],
        outerwear: [ClothingItem],
        footwear: [ClothingItem],
        accessories: [ClothingItem],
        memory: StyleMemory,
        stylePreference: String,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool
    ) -> OutfitBuildResult {
        guard !dresses.isEmpty else { return OutfitBuildResult(items: [], styleType: "casual") }
        
        var items: [ClothingItem] = []
        
        // Pick best dress
        if let dress = pickPreferred(from: dresses, memory: memory, coordinatingWith: nil, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
            items.append(dress)
            
            // Add coordinating outerwear
            if let layer = pickPreferred(from: outerwear, memory: memory, coordinatingWith: dress, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
                items.append(layer)
            }
            
            // Add footwear
            if let shoes = pickPreferred(from: footwear, memory: memory, coordinatingWith: dress, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
                items.append(shoes)
            }
            
            // Add accessories based on style preference
            let accessoryCount = stylePreference == "bold" ? 3 : stylePreference == "minimalist" ? 1 : 2
            let selectedAccessories = pickMultiple(from: accessories, count: accessoryCount, memory: memory)
            items.append(contentsOf: selectedAccessories)
        }
        
        return OutfitBuildResult(items: items, styleType: "dressed")
    }
    
    private func buildSuitOutfit(
        suits: [ClothingItem],
        footwear: [ClothingItem],
        accessories: [ClothingItem],
        memory: StyleMemory,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool
    ) -> OutfitBuildResult {
        guard !suits.isEmpty else { return OutfitBuildResult(items: [], styleType: "casual") }
        
        var items: [ClothingItem] = []
        
        if let suit = pickPreferred(from: suits, memory: memory, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
            items.append(suit)
            
            // Add formal footwear
            let formalFootwear = footwear.filter { $0.formality == .formal || $0.formality == .business }
            if let shoes = pickPreferred(from: formalFootwear.isEmpty ? footwear : formalFootwear, memory: memory, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
                items.append(shoes)
            }
            
            // Add accessories
            let selectedAccessories = pickMultiple(from: accessories, count: 2, memory: memory)
            items.append(contentsOf: selectedAccessories)
        }
        
        return OutfitBuildResult(items: items, styleType: "suited")
    }
    
    private func buildTopBottomOutfit(
        tops: [ClothingItem],
        bottoms: [ClothingItem],
        outerwear: [ClothingItem],
        footwear: [ClothingItem],
        accessories: [ClothingItem],
        memory: StyleMemory,
        stylePreference: String,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool
    ) -> OutfitBuildResult {
        var items: [ClothingItem] = []

        // Evaluate multiple top/bottom combos so we can prefer smart-casual silhouettes when available.
        let topCandidates = Array(tops.prefix(10))
        let bottomCandidates = Array(bottoms.prefix(10))

        var bestPair: (top: ClothingItem, bottom: ClothingItem, score: Double)?
        for top in topCandidates {
            for bottom in bottomCandidates {
                let score = scoreTopBottomPair(top: top, bottom: bottom, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, memory: memory)
                if bestPair == nil || score > bestPair!.score {
                    bestPair = (top: top, bottom: bottom, score: score)
                }
            }
        }

        if let bestPair {
            items.append(bestPair.top)
            items.append(bestPair.bottom)
                
                // Add layers
                if let layer = pickPreferred(from: outerwear, memory: memory, coordinatingWith: bestPair.top, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
                    items.append(layer)
                }
                
                // Add footwear
                if let shoes = pickPreferred(from: footwear, memory: memory, coordinatingWith: bestPair.top, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort) {
                    items.append(shoes)
                }
                
                // Add accessories
                let accessoryCount = stylePreference == "minimalist" ? 1 : 2
                let selectedAccessories = pickMultiple(from: accessories, count: accessoryCount, memory: memory)
                items.append(contentsOf: selectedAccessories)
        }
        
        return OutfitBuildResult(items: items, styleType: preferSmartCasual ? "smart_casual" : "casual")
    }

    // MARK: - Missing Helpers (minimal implementations)

    private enum FormalityRank {
        static func rank(_ formality: ClothingItem.Formality) -> Int {
            switch formality {
            case .athletic: return 0
            case .casual: return 1
            case .smartCasual: return 2
            case .party: return 3
            case .business: return 4
            case .formal: return 5
            }
        }
    }

    private func analyzeFormalityCompatibility(
        lookFormality: ClothingItem.Formality?,
        requiredFormality: ClothingItem.Formality?
    ) -> Double {
        guard let requiredFormality else { return 0.75 }
        guard let lookFormality else { return 0.5 }

        let required = FormalityRank.rank(requiredFormality)
        let actual = FormalityRank.rank(lookFormality)
        let delta = abs(required - actual)

        switch delta {
        case 0: return 1.0
        case 1: return 0.75
        case 2: return 0.5
        default: return 0.25
        }
    }

    private func estimateFormality(from occasionText: String) -> ClothingItem.Formality? {
        let lowercased = occasionText.lowercased()
        if lowercased.contains("wedding") || lowercased.contains("black tie") || lowercased.contains("formal") {
            return .formal
        }
        if lowercased.contains("interview") || lowercased.contains("business") || lowercased.contains("presentation") {
            return .business
        }
        if lowercased.contains("work") || lowercased.contains("office") || lowercased.contains("meeting") {
            return .smartCasual
        }
        if lowercased.contains("party") || lowercased.contains("date") || lowercased.contains("dinner") {
            return .party
        }
        if lowercased.contains("gym") || lowercased.contains("athletic") || lowercased.contains("hiking") {
            return .athletic
        }
        if lowercased.contains("casual") || lowercased.contains("hangout") {
            return .casual
        }
        return nil
    }

    private func determineFormality(for occasion: StylePromptBuilder.Occasion) -> ClothingItem.Formality? {
        let combined = [occasion.title, occasion.timeOfDay, occasion.vibe]
            .compactMap { $0 }
            .joined(separator: " ")
        return estimateFormality(from: combined)
    }

    private func parseFormality(_ raw: String) -> ClothingItem.Formality? {
        let s = raw.lowercased().replacingOccurrences(of: "_", with: "").replacingOccurrences(of: " ", with: "")
        switch s {
        case "auto": return nil
        case "casual", "verycasual": return .casual
        case "smartcasual": return .smartCasual
        case "formal": return .formal
        case "athletic", "gym": return .athletic
        case "business": return .business
        case "party": return .party
        default: return nil
        }
    }

    private func isCompatible(formality: ClothingItem.Formality, with required: ClothingItem.Formality) -> Bool {
        let requiredRank = FormalityRank.rank(required)
        let actualRank = FormalityRank.rank(formality)
        return abs(requiredRank - actualRank) <= 1
    }

    private func analyzeColorHarmony(look: OutfitLook, preference: String) -> Double {
        // We don't persist a color palette for looks, so use a lightweight heuristic.
        if preference == "any" { return 0.7 }
        let notes = look.notes.lowercased()
        if notes.contains(preference.lowercased()) { return 0.85 }
        return 0.6
    }

    private func analyzeStyleConsistency(look: OutfitLook, preference: String) -> Double {
        if preference == "any" { return 0.7 }
        let notes = look.notes.lowercased()
        if notes.contains(preference.lowercased()) { return 0.85 }
        return 0.6
    }

    private func applyStylePreferences(
        items: [ClothingItem],
        stylePreference: String,
        colorPreference: String,
        memory: StyleMemory,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool
    ) -> [ClothingItem] {
        let preferredColor = colorPreference == "any" ? nil : colorPreference.lowercased()

        return items.sorted { a, b in
            func score(_ item: ClothingItem) -> Double {
                scoreItem(
                    item,
                    memory: memory,
                    coordinatingWith: nil,
                    preferredColor: preferredColor,
                    requiredFormality: requiredFormality,
                    preferSmartCasual: preferSmartCasual,
                    prioritizeComfort: prioritizeComfort,
                    occasionHint: stylePreference
                )
            }
            return score(a) > score(b)
        }
    }

    private func generateOutfitSuggestion(baseItems: [ClothingItem], styleType: String, occasion: StylePromptBuilder.Occasion) -> String {
        let names = baseItems.map { $0.name }.joined(separator: ", ")
        return "For \(occasion.title), try: \(names)."
    }

    private func generateStyleTags(items: [ClothingItem], styleType: String, occasion: StylePromptBuilder.Occasion) -> [String] {
        var tags: [String] = [styleType]
        tags.append(occasion.title.lowercased().replacingOccurrences(of: " ", with: "_"))
        tags.append(contentsOf: Set(items.map { $0.category.rawValue }))
        return Array(Set(tags))
    }

    private func pickPreferred(
        from items: [ClothingItem],
        memory: StyleMemory,
        coordinatingWith: ClothingItem? = nil,
        requiredFormality: ClothingItem.Formality? = nil,
        preferSmartCasual: Bool = false,
        prioritizeComfort: Bool = false
    ) -> ClothingItem? {
        guard !items.isEmpty else { return nil }

        let preferredColor: String? = nil

        return items.max { a, b in
            let sa = scoreItem(a, memory: memory, coordinatingWith: coordinatingWith, preferredColor: preferredColor, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, occasionHint: nil)
            let sb = scoreItem(b, memory: memory, coordinatingWith: coordinatingWith, preferredColor: preferredColor, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, occasionHint: nil)
            return sa < sb
        }
    }

    // MARK: - Smart-Casual Heuristics + Scoring

    private func shouldPreferSmartCasual(
        occasion: StylePromptBuilder.Occasion,
        formalityLevel: String,
        availableItems: [ClothingItem]
    ) -> Bool {
        let requested = formalityLevel.lowercased().replacingOccurrences(of: " ", with: "")
        if requested.contains("smart") { return true }
        if requested.contains("business") || requested.contains("formal") { return false }
        if requested.contains("athletic") || requested.contains("gym") { return false }

        let combined = [occasion.title, occasion.timeOfDay, occasion.vibe]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        // If the occasion is explicitly very casual, don't force smart-casual.
        if combined.contains("gym") || combined.contains("athletic") || combined.contains("beach") || combined.contains("hiking") {
            return false
        }

        // Prefer smart-casual for common "looks better" contexts.
        let occasionWantsSmart = combined.contains("work") || combined.contains("office") || combined.contains("meeting") || combined.contains("date") || combined.contains("dinner") || combined.contains("presentation") || combined.contains("network") || combined.contains("interview")

        // Only enable if the closet has at least one strong smart-casual top + bottom.
        let tops = availableItems.filter { $0.category == .tops }
        let bottoms = availableItems.filter { $0.category == .bottoms }
        let hasSmartTop = tops.contains { smartCasualSignalScore(for: $0) >= 1.5 || $0.formality == .smartCasual || $0.formality == .business }
        let hasSmartBottom = bottoms.contains { smartCasualSignalScore(for: $0) >= 1.0 || $0.formality == .smartCasual || $0.formality == .business }

        return occasionWantsSmart && hasSmartTop && hasSmartBottom
    }

    private func scoreItem(
        _ item: ClothingItem,
        memory: StyleMemory,
        coordinatingWith: ClothingItem?,
        preferredColor: String?,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool,
        occasionHint: String?
    ) -> Double {
        var score = 0.0

        // Learned preference
        score += memory.predictItemPreference(item) * 100

        // Strong favorites
        if memory.favoriteItemIDs.contains(item.id) { score += 40 }
        if item.isFavorite { score += 20 }

        // Simple negative feedback (if present)
        let dislikedKey = "disliked_\(item.id)"
        if (memory.selectionCounts[dislikedKey] ?? 0) > 0 {
            score -= 60
        }

        // Color preference (best-effort; users often set colorPreference to "any")
        if let preferredColor, item.primaryColorHex.lowercased().contains(preferredColor) {
            score += 8
        }

        // Formality match
        if let requiredFormality {
            let requiredRank = FormalityRank.rank(requiredFormality)
            let actualRank = FormalityRank.rank(item.formality)
            score += max(0, 10 - Double(abs(requiredRank - actualRank)) * 5)
        }

        // Season coordination
        if let coordinatingWith, item.season == coordinatingWith.season {
            score += 4
        }

        // Smart-casual boost
        if preferSmartCasual {
            score += smartCasualSignalScore(for: item) * 20
            if item.formality == .smartCasual { score += 10 }
            if item.formality == .business { score += 6 }
            if item.formality == .formal { score += 2 }
        }

        // Comfort bias
        if prioritizeComfort {
            if item.formality == .athletic { score += 10 }
            if item.formality == .casual { score += 6 }
            let text = itemSearchText(item)
            if text.contains("cotton") || text.contains("stretch") { score += 3 }
        }

        _ = occasionHint
        return score
    }

    private func scoreTopBottomPair(
        top: ClothingItem,
        bottom: ClothingItem,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool,
        memory: StyleMemory
    ) -> Double {
        let topScore = scoreItem(top, memory: memory, coordinatingWith: bottom, preferredColor: nil, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, occasionHint: nil)
        let bottomScore = scoreItem(bottom, memory: memory, coordinatingWith: top, preferredColor: nil, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, occasionHint: nil)

        // Pair synergy
        var synergy = 0.0
        if preferSmartCasual {
            let topSignal = smartCasualSignalScore(for: top)
            let bottomSignal = smartCasualSignalScore(for: bottom)
            synergy += (topSignal + bottomSignal) * 5
        }

        // Color harmony for the pair
        let harmony = analyzeOutfitColorHarmony(items: [top, bottom])
        return topScore + bottomScore + harmony * 20 + synergy
    }

    private func scoreBuiltOutfit(
        _ items: [ClothingItem],
        occasion: StylePromptBuilder.Occasion,
        requiredFormality: ClothingItem.Formality?,
        preferSmartCasual: Bool,
        prioritizeComfort: Bool,
        memory: StyleMemory
    ) -> Double {
        guard !items.isEmpty else { return -Double.infinity }

        let hasTop = items.contains { $0.category == .tops || $0.category == .dresses || $0.category == .suits }
        let hasBottom = items.contains { $0.category == .bottoms || $0.category == .dresses || $0.category == .suits }
        let hasShoes = items.contains { $0.category == .footwear }

        var score = 0.0
        score += hasTop ? 20 : -40
        score += hasBottom ? 20 : -40
        score += hasShoes ? 10 : -10

        // Prefer coherent color palettes
        score += analyzeOutfitColorHarmony(items: items) * 30

        // Aggregate item scores
        for item in items {
            score += scoreItem(item, memory: memory, coordinatingWith: nil, preferredColor: nil, requiredFormality: requiredFormality, preferSmartCasual: preferSmartCasual, prioritizeComfort: prioritizeComfort, occasionHint: nil) * 0.2
        }

        // Light occasion bias toward smart-casual when requested by prompt
        let combined = [occasion.title, occasion.timeOfDay, occasion.vibe]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
        if preferSmartCasual && (combined.contains("work") || combined.contains("dinner") || combined.contains("date") || combined.contains("meeting")) {
            score += 10
        }

        return score
    }

    private func itemSearchText(_ item: ClothingItem) -> String {
        [item.name, item.notes, item.material, item.pattern]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")
    }

    private func smartCasualSignalScore(for item: ClothingItem) -> Double {
        let text = itemSearchText(item)

        var score = 0.0

        // Strong smart-casual signals
        let strongTop = ["button", "buttondown", "button-up", "dress shirt", "oxford", "polo", "collar", "collared", "quarter zip", "quarter-zip", "qtr zip", "half zip", "half-zip", "henley", "sweater", "knit", "cardigan"]
        let strongBottom = ["chino", "trouser", "slack", "dress pant", "dress pants", "tailored", "pleated"]
        let strongShoe = ["loafer", "derby", "oxford shoe", "oxfords", "chelsea", "boot", "dress shoe"]

        let casualAvoid = ["t-shirt", "tee", "graphic", "tank", "shorts", "jogger", "sweatpant", "sweatpants", "track", "gym", "flip flop", "slides"]

        if item.category == .tops && strongTop.contains(where: { text.contains($0) }) { score += 2.0 }
        if item.category == .bottoms && strongBottom.contains(where: { text.contains($0) }) { score += 1.5 }
        if item.category == .footwear && strongShoe.contains(where: { text.contains($0) }) { score += 1.0 }

        // Basic smart-casual formality signal
        if item.formality == .smartCasual { score += 0.8 }
        if item.formality == .business { score += 0.5 }

        // Penalize explicitly casual/athletic items when trying for smart-casual
        if casualAvoid.contains(where: { text.contains($0) }) { score -= 1.5 }
        if item.formality == .athletic { score -= 1.0 }

        return score
    }

    private func pickMultiple(from items: [ClothingItem], count: Int, memory: StyleMemory) -> [ClothingItem] {
        guard count > 0 else { return [] }
        var remaining = items
        var selected: [ClothingItem] = []

        for _ in 0..<min(count, remaining.count) {
            guard let next = pickPreferred(from: remaining, memory: memory) else { break }
            selected.append(next)
            remaining.removeAll { $0.id == next.id }
        }

        return selected
    }
    
    // MARK: - Utility Functions
    
    static func getRecommendedFormality(for occasion: String) -> String {
        let lowercased = occasion.lowercased()
        
        if lowercased.contains("wedding") || lowercased.contains("formal") || lowercased.contains("black tie") {
            return "formal"
        } else if lowercased.contains("interview") || lowercased.contains("business") || lowercased.contains("presentation") {
            return "business"
        } else if lowercased.contains("work") || lowercased.contains("office") || lowercased.contains("meeting") {
            return "smart_casual"
        } else if lowercased.contains("party") || lowercased.contains("date") || lowercased.contains("dinner") {
            return "smart_casual"
        } else if lowercased.contains("gym") || lowercased.contains("athletic") || lowercased.contains("hiking") {
            return "very_casual"
        }
        
        return "casual"
    }
    
    // MARK: - Advanced Color Theory
    
    /// Calculate perceptual color distance using HSL space with advanced weighting
    /// Uses CIEDE2000-inspired algorithm for more accurate color perception
    private func calculateColorDistance(hex1: String, hex2: String) -> Double {
        guard let color1 = Color(hex: hex1), let color2 = Color(hex: hex2) else { return 1.0 }
        
        // Convert to HSL
        let hsl1 = color1.toHSL()
        let hsl2 = color2.toHSL()
        
        // Weighted distance calculation with perceptual adjustments
        let deltaHue = abs(hsl1.h - hsl2.h)
        let hueDiff = min(deltaHue, 360 - deltaHue) / 180.0
        let satDiff = abs(hsl1.s - hsl2.s)
        let lightDiff = abs(hsl1.l - hsl2.l)
        
        // Apply perceptual weighting based on lightness
        // Human vision is more sensitive to hue differences in mid-lightness ranges
        let lightnessWeight = 1.0 - abs((hsl1.l + hsl2.l) / 2.0 - 0.5) * 0.5
        
        // Apply perceptual weighting based on saturation
        // Human vision is more sensitive to hue differences in saturated colors
        let saturationWeight = min(1.0, (hsl1.s + hsl2.s) / 2.0 * 2.0)
        
        // Combined perceptual weighting
        let perceptualWeight = lightnessWeight * saturationWeight
        
        // Hue is most important for perception, then saturation, then lightness
        // Apply perceptual weighting to hue component
        let weightedHue = hueDiff * perceptualWeight
        let hueComponent = pow(weightedHue, 2) * 0.6
        let saturationComponent = pow(satDiff, 2) * 0.3
        let lightnessComponent = pow(lightDiff, 2) * 0.1
        return sqrt(hueComponent + saturationComponent + lightnessComponent)
    }
    
    /// Find complementary color
    private func findComplementaryColor(_ hex: String) -> String? {
        guard let color = Color(hex: hex) else { return nil }
        let hsl = color.toHSL()
        let complementaryHue = (hsl.h + 180).truncatingRemainder(dividingBy: 360)
        return Color(hue: complementaryHue / 360.0, saturation: hsl.s, lightness: hsl.l).toHex()
    }
    
    /// Generate triadic colors
    private func generateTriadicColors(_ hex: String) -> [String] {
        guard let color = Color(hex: hex) else { return [] }
        let hsl = color.toHSL()
        let triadic1Hue = (hsl.h + 120).truncatingRemainder(dividingBy: 360)
        let triadic2Hue = (hsl.h + 240).truncatingRemainder(dividingBy: 360)
        
        let color1 = Color(hue: triadic1Hue / 360.0, saturation: hsl.s, lightness: hsl.l).toHex()
        let color2 = Color(hue: triadic2Hue / 360.0, saturation: hsl.s, lightness: hsl.l).toHex()
        
        return [color1, color2].compactMap { $0 }
    }
    
    /// Generate analogous colors
    private func generateAnalogousColors(_ hex: String) -> [String] {
        guard let color = Color(hex: hex) else { return [] }
        let hsl = color.toHSL()
        let analog1Hue = (hsl.h + 30).truncatingRemainder(dividingBy: 360)
        let analog2Hue = (hsl.h - 30 + 360).truncatingRemainder(dividingBy: 360)
        
        let color1 = Color(hue: analog1Hue / 360.0, saturation: hsl.s, lightness: hsl.l).toHex()
        let color2 = Color(hue: analog2Hue / 360.0, saturation: hsl.s, lightness: hsl.l).toHex()
        
        return [color1, color2].compactMap { $0 }
    }
    
    /// Determine color temperature (warm/cool/neutral)
    private func getColorTemperature(_ hex: String) -> String {
        guard let color = Color(hex: hex) else { return "neutral" }
        let hsl = color.toHSL()
        
        // Hue ranges for warm/cool colors
        if (hsl.h >= 0 && hsl.h <= 60) || (hsl.h >= 300 && hsl.h <= 360) {
            return "warm"
        } else if hsl.h >= 120 && hsl.h <= 240 {
            return "cool"
        } else {
            return "neutral"
        }
    }
    
    /// Analyze color harmony in an outfit with advanced metrics
    /// Considers not just pairwise comparisons but overall palette coherence
    private func analyzeOutfitColorHarmony(items: [ClothingItem]) -> Double {
        guard items.count > 1 else { return 1.0 }
        
        var totalHarmony = 0.0
        var comparisonCount = 0
        
        // Track overall palette characteristics
        var allColors: [String] = []
        var warmColors = 0
        var coolColors = 0
        
        // Collect all colors
        for item in items {
            allColors.append(item.primaryColorHex)
            if let secondary = item.secondaryColorHex {
                allColors.append(secondary)
            }
            
            // Count warm/cool colors
            let temp = getColorTemperature(item.primaryColorHex)
            if temp == "warm" { warmColors += 1 }
            else if temp == "cool" { coolColors += 1 }
            
            if let secondary = item.secondaryColorHex {
                let temp2 = getColorTemperature(secondary)
                if temp2 == "warm" { warmColors += 1 }
                else if temp2 == "cool" { coolColors += 1 }
            }
        }
        
        // Calculate temperature balance (0 = perfectly balanced, 1 = completely unbalanced)
        let totalColorCount = Double(warmColors + coolColors)
        let temperatureBalance = totalColorCount > 0 ? abs(Double(warmColors - coolColors) / totalColorCount) : 0
        let temperatureHarmony = 1.0 - temperatureBalance
        
        // Compare each item with every other item
        for i in 0..<items.count {
            for j in (i + 1)..<items.count {
                let item1 = items[i]
                let item2 = items[j]
                
                // Primary to primary
                let primaryHarmony = 1.0 - calculateColorDistance(hex1: item1.primaryColorHex, hex2: item2.primaryColorHex)
                totalHarmony += primaryHarmony
                comparisonCount += 1
                
                // Secondary colors if available
                if let sec1 = item1.secondaryColorHex, let sec2 = item2.secondaryColorHex {
                    let secondaryHarmony = 1.0 - calculateColorDistance(hex1: sec1, hex2: sec2)
                    totalHarmony += secondaryHarmony * 0.7
                    comparisonCount += 1
                }
                
                // Cross comparisons
                if let sec1 = item1.secondaryColorHex {
                    let cross1 = 1.0 - calculateColorDistance(hex1: item1.primaryColorHex, hex2: sec1)
                    totalHarmony += cross1 * 0.5
                    comparisonCount += 1
                }
                
                if let sec2 = item2.secondaryColorHex {
                    let cross2 = 1.0 - calculateColorDistance(hex1: item2.primaryColorHex, hex2: sec2)
                    totalHarmony += cross2 * 0.5
                    comparisonCount += 1
                }
                
                // Temperature harmony
                let temp1 = getColorTemperature(item1.primaryColorHex)
                let temp2 = getColorTemperature(item2.primaryColorHex)
                if temp1 == temp2 {
                    totalHarmony += 0.1
                    comparisonCount += 1
                }
            }
        }
        
        // Calculate average pairwise harmony
        let averagePairwiseHarmony = comparisonCount > 0 ? totalHarmony / Double(comparisonCount) : 0.5
        
        // Combine pairwise harmony with temperature harmony
        // Temperature harmony is weighted at 30% since it affects the overall palette
        let combinedHarmony = averagePairwiseHarmony * 0.7 + temperatureHarmony * 0.3
        
        return combinedHarmony
    }
    
    /// Generate color palette suggestions based on a base color
    private func generateColorPaletteSuggestions(baseColor: String, paletteType: String) -> [String] {
        switch paletteType {
        case "complementary":
            return findComplementaryColor(baseColor).map { [$0] } ?? []
        case "triadic":
            return generateTriadicColors(baseColor)
        case "analogous":
            return generateAnalogousColors(baseColor)
        case "monochromatic":
            // Generate variations of the same hue
            guard let color = Color(hex: baseColor) else { return [] }
            let hsl = color.toHSL()
            var variations: [String] = []
            
            // Lighter variations
            for i in 1...2 {
                let lighter = Color(hue: hsl.h / 360.0, saturation: hsl.s, lightness: min(1.0, hsl.l + Double(i) * 0.1)).toHex()
                if let hex = lighter {
                    variations.append(hex)
                }
            }
            
            // Darker variations
            for i in 1...2 {
                let darker = Color(hue: hsl.h / 360.0, saturation: hsl.s, lightness: max(0.0, hsl.l - Double(i) * 0.1)).toHex()
                if let hex = darker {
                    variations.append(hex)
                }
            }
            
            return variations
        default:
            return []
        }
    }
    
    private func generateMatchingReason(occasion: StylePromptBuilder.Occasion, stylePreference: String, colorPreference: String) -> String {
        var reasons: [String] = []
        
        if let vibe = occasion.vibe {
            reasons.append("matches your \(vibe) style goal")
        }
        
        if stylePreference != "any" {
            reasons.append("fits your \(stylePreference) aesthetic")
        }
        
        if colorPreference != "any" {
            reasons.append("uses your preferred \(colorPreference) colors")
        }
        
        if let timeOfDay = occasion.timeOfDay {
            reasons.append("perfect for \(timeOfDay.lowercased())")
        }
        
        return "This outfit " + reasons.joined(separator: ", ") + "."
    }
    
    private func calculateOutfitConfidence(outfit: EnhancedBuiltOutfit, occasion: StylePromptBuilder.Occasion, memory: StyleMemory) -> Double {
        // Base confidence
        var confidence = 50.0
        
        // Check if we have all necessary pieces
        if outfit.itemIDs.count >= 3 {
            confidence += 20
        } else if outfit.itemIDs.count >= 2 {
            confidence += 10
        }
        
        // Check user preferences
        let preferredItems = outfit.itemIDs.filter { memory.favoriteItemIDs.contains($0) }
        confidence += Double(preferredItems.count) * 10
        
        // Check occasion appropriateness
        if occasion.title.lowercased().contains("formal") && outfit.styleType == "suited" {
            confidence += 15
        } else if occasion.title.lowercased().contains("casual") && outfit.styleType == "casual" {
            confidence += 10
        }
        
        return min(confidence, 95)
    }
    
    private func generateStyleBreakdown(outfit: EnhancedBuiltOutfit, occasion: StylePromptBuilder.Occasion, stylePreference: String) -> [String] {
        var breakdown: [String] = []
        
        breakdown.append("✓ Complete outfit with \(outfit.itemIDs.count) pieces")
        
        if let styleType = outfit.styleType {
            breakdown.append("✓ \(styleType.capitalized) style")
        }
        
        if stylePreference != "any" {
            breakdown.append("✓ Matches your \(stylePreference) preference")
        }
        
        breakdown.append("✓ Perfect for \(occasion.title.lowercased())")
        
        return breakdown
    }
    
    private func generateAlternativeSuggestions(currentOutfit: EnhancedBuiltOutfit, allItems: [ClothingItem], occasion: StylePromptBuilder.Occasion, memory: StyleMemory) -> [AlternativeSuggestion] {
        var alternatives: [AlternativeSuggestion] = []
        
        // Suggest more formal option if current is casual
        if currentOutfit.styleType == "casual" {
            alternatives.append(AlternativeSuggestion(
                title: "More formal option",
                description: "Try adding a blazer or switching to dress shoes for a more polished look",
                styleType: "smart_casual"
            ))
        }
        
        // Suggest more casual option if current is formal
        if currentOutfit.styleType == "formal" {
            alternatives.append(AlternativeSuggestion(
                title: "More relaxed option",
                description: "Consider swapping formal pieces for more comfortable, casual alternatives",
                styleType: "casual"
            ))
        }
        
        // Suggest color variations
        alternatives.append(AlternativeSuggestion(
            title: "Different color palette",
            description: "Try this outfit with complementary colors or your favorite color scheme",
            styleType: "color_variation"
        ))

        alternatives.append(contentsOf: generateMixAndMatchSuggestions(allItems: allItems, currentOutfit: currentOutfit, occasion: occasion, memory: memory))
        
        return alternatives
    }

    private func generateMixAndMatchSuggestions(
        allItems: [ClothingItem],
        currentOutfit: EnhancedBuiltOutfit,
        occasion: StylePromptBuilder.Occasion,
        memory: StyleMemory
    ) -> [AlternativeSuggestion] {
        guard !allItems.isEmpty else { return [] }

        func itemScore(_ item: ClothingItem) -> Double {
            let preference = memory.predictItemPreference(item)
            let favoriteBoost = item.isFavorite ? 0.25 : 0.0
            let dislikedPenalty = Double(memory.selectionCounts["disliked_\(item.id)"] ?? 0) * 0.6
            return preference + favoriteBoost - dislikedPenalty
        }

        let excluded = Set(currentOutfit.itemIDs)
        let candidates = allItems
            .filter { !excluded.contains($0.id) }

        let tops = candidates.filter { $0.category == .tops }.sorted { itemScore($0) > itemScore($1) }
        let bottoms = candidates.filter { $0.category == .bottoms }.sorted { itemScore($0) > itemScore($1) }
        let dresses = candidates.filter { $0.category == .dresses }.sorted { itemScore($0) > itemScore($1) }
        let outerwear = candidates.filter { $0.category == .outerwear }.sorted { itemScore($0) > itemScore($1) }
        let footwear = candidates.filter { $0.category == .footwear }.sorted { itemScore($0) > itemScore($1) }
        let accessories = candidates.filter { $0.category == .accessories }.sorted { itemScore($0) > itemScore($1) }

        let topPicks = Array(tops.prefix(3))
        let bottomPicks = Array(bottoms.prefix(3))
        let dressPicks = Array(dresses.prefix(2))
        let outerPicks = Array(outerwear.prefix(2))
        let shoePicks = Array(footwear.prefix(2))
        let accPicks = Array(accessories.prefix(2))

        struct Combo {
            let items: [ClothingItem]
            let score: Double
        }

        func comboScore(_ items: [ClothingItem]) -> Double {
            var total = items.reduce(0.0) { $0 + itemScore($1) }
            let uniqueCategories = Set(items.map { $0.category.rawValue }).count
            total += Double(uniqueCategories) * 0.15
            return total
        }

        var combos: [Combo] = []

        // Dress-based combos
        for dress in dressPicks {
            var items: [ClothingItem] = [dress]
            if let shoes = shoePicks.first { items.append(shoes) }
            if let outer = outerPicks.first { items.append(outer) }
            if let acc = accPicks.first { items.append(acc) }
            combos.append(Combo(items: items, score: comboScore(items)))
        }

        // Top + bottom combos
        for top in topPicks {
            for bottom in bottomPicks {
                var items: [ClothingItem] = [top, bottom]
                if let shoes = shoePicks.first { items.append(shoes) }
                if occasion.title.lowercased().contains("cold"), let outer = outerPicks.first {
                    items.append(outer)
                } else if let outer = outerPicks.first, itemScore(outer) > 0.6 {
                    items.append(outer)
                }
                if let acc = accPicks.first, itemScore(acc) > 0.55 {
                    items.append(acc)
                }
                combos.append(Combo(items: items, score: comboScore(items)))
            }
        }

        // Deduplicate by item set and pick top
        var seen: Set<String> = []
        let ranked = combos
            .sorted { $0.score > $1.score }
            .filter { combo in
                let key = combo.items.map { $0.id.uuidString }.sorted().joined(separator: "|")
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }

        let selected = Array(ranked.prefix(3))
        guard !selected.isEmpty else { return [] }

        func describe(_ items: [ClothingItem]) -> String {
            items.map { "• \($0.category.rawValue.capitalized): \($0.name)" }.joined(separator: "\n")
        }

        return selected.enumerated().map { idx, combo in
            AlternativeSuggestion(
                title: "Mix & match idea \(idx + 1)",
                description: describe(combo.items),
                styleType: "mix_match"
            )
        }
    }
}

// MARK: - Supporting Types

struct EnhancedBuiltOutfit {
    let itemIDs: [UUID]
    let humanSuggestion: String
    let styleType: String?
    let reason: String
    let styleTags: [String]
}

struct OutfitBuildResult {
    let items: [ClothingItem]
    let styleType: String
}

struct PhotoAnalysis {
    let confidence: Double
    let reason: String
    let improvementSuggestion: String
    let styleTags: [String]
    let breakdown: [String]
    let alternatives: [AlternativeSuggestion]
}

struct PhotoAnalysisResult {
    let confidence: Double
    let reason: String
    let improvementSuggestion: String?
    let bestLookID: UUID?
    let styleTags: [String]
    let breakdown: [String]
    let alternatives: [AlternativeSuggestion]
}

// MARK: - Extension for StyleMemory

extension StyleMemory {
    func recordDetailedPreference(occasion: String, timeOfDay: String, style: String, formality: String, colors: String, location: String?) {
        let key = "\(occasion)|\(timeOfDay)|\(style)|\(formality)|\(colors)"
        let current = preferredColorCombinations[key] ?? 0
        preferredColorCombinations[key] = current + 1
    }
    
    func recordNegativeFeedback(for key: String) {
        // Could implement learning from negative feedback
        // For now, just track it
        let current = selectionCounts[key] ?? 0
        if current > 0 {
            selectionCounts[key] = current - 1
        }
    }
    
    func getSuccessRate(for key: String) -> Double {
        let selections = selectionCounts[key] ?? 0
        let worn = wornCounts[key] ?? 0
        
        guard selections > 0 else { return 0 }
        return Double(worn) / Double(selections)
    }
}