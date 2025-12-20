import Foundation
import UIKit
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
        let wantedVibe = (occasion.vibe ?? "").lowercased()
        
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
        if let imageData = look.imageData, let image = UIImage(data: imageData) {
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
        
        // Categorize items
        let tops = filteredItems.filter { $0.category == .tops }
        let bottoms = filteredItems.filter { $0.category == .bottoms }
        let dresses = filteredItems.filter { $0.category == .dresses }
        let suits = filteredItems.filter { $0.category == .suits }
        let outerwear = filteredItems.filter { $0.category == .outerwear }
        let footwear = filteredItems.filter { $0.category == .footwear }
        let accessories = filteredItems.filter { $0.category == .accessories }
        
        // Apply style and color preferences
        let styleFilteredItems = applyStylePreferences(
            items: filteredItems,
            stylePreference: stylePreference,
            colorPreference: colorPreference,
            memory: memory
        )
        
        // Build base outfit
        var baseItems: [ClothingItem] = []
        var styleType = "casual"
        var reason = "Built from your closet items"
        
        // Try to build the best possible outfit
        let outfitOptions = [
            buildDressOutfit(dresses: dresses, outerwear: outerwear, footwear: footwear, accessories: accessories, memory: memory, stylePreference: stylePreference),
            buildSuitOutfit(suits: suits, footwear: footwear, accessories: accessories, memory: memory),
            buildTopBottomOutfit(tops: tops, bottoms: bottoms, outerwear: outerwear, footwear: footwear, accessories: accessories, memory: memory, stylePreference: stylePreference),
        ]
        
        let bestOutfit = outfitOptions.max { $0.items.count < $1.items.count } ?? outfitOptions.first!
        baseItems = bestOutfit.items
        styleType = bestOutfit.styleType
        
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
            var testOutfit = baseItems + [item]
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
    
    private func buildDressOutfit(dresses: [ClothingItem], outerwear: [ClothingItem], footwear: [ClothingItem], accessories: [ClothingItem], memory: StyleMemory, stylePreference: String) -> OutfitBuildResult {
        guard !dresses.isEmpty else { return OutfitBuildResult(items: [], styleType: "casual") }
        
        var items: [ClothingItem] = []
        
        // Pick best dress
        if let dress = pickPreferred(from: dresses, memory: memory, coordinatingWith: nil) {
            items.append(dress)
            
            // Add coordinating outerwear
            if let layer = pickPreferred(from: outerwear, memory: memory, coordinatingWith: dress) {
                items.append(layer)
            }
            
            // Add footwear
            if let shoes = pickPreferred(from: footwear, memory: memory, coordinatingWith: dress) {
                items.append(shoes)
            }
            
            // Add accessories based on style preference
            let accessoryCount = stylePreference == "bold" ? 3 : stylePreference == "minimalist" ? 1 : 2
            let selectedAccessories = pickMultiple(from: accessories, count: accessoryCount, memory: memory)
            items.append(contentsOf: selectedAccessories)
        }
        
        return OutfitBuildResult(items: items, styleType: "dressed")
    }
    
    private func buildSuitOutfit(suits: [ClothingItem], footwear: [ClothingItem], accessories: [ClothingItem], memory: StyleMemory) -> OutfitBuildResult {
        guard !suits.isEmpty else { return OutfitBuildResult(items: [], styleType: "casual") }
        
        var items: [ClothingItem] = []
        
        if let suit = pickPreferred(from: suits, memory: memory) {
            items.append(suit)
            
            // Add formal footwear
            let formalFootwear = footwear.filter { $0.formality == .formal || $0.formality == .business }
            if let shoes = pickPreferred(from: formalFootwear.isEmpty ? footwear : formalFootwear, memory: memory) {
                items.append(shoes)
            }
            
            // Add accessories
            let selectedAccessories = pickMultiple(from: accessories, count: 2, memory: memory)
            items.append(contentsOf: selectedAccessories)
        }
        
        return OutfitBuildResult(items: items, styleType: "suited")
    }
    
    private func buildTopBottomOutfit(tops: [ClothingItem], bottoms: [ClothingItem], outerwear: [ClothingItem], footwear: [ClothingItem], accessories: [ClothingItem], memory: StyleMemory, stylePreference: String) -> OutfitBuildResult {
        var items: [ClothingItem] = []
        
        if let top = pickPreferred(from: tops, memory: memory) {
            items.append(top)
            
            // Find coordinating bottom
            if let bottom = pickPreferred(from: bottoms, memory: memory, coordinatingWith: top) {
                items.append(bottom)
                
                // Add layers
                if let layer = pickPreferred(from: outerwear, memory: memory, coordinatingWith: top) {
                    items.append(layer)
                }
                
                // Add footwear
                if let shoes = pickPreferred(from: footwear, memory: memory, coordinatingWith: top) {
                    items.append(shoes)
                }
                
                // Add accessories
                let accessoryCount = stylePreference == "minimalist" ? 1 : 2
                let selectedAccessories = pickMultiple(from: accessories, count: accessoryCount, memory: memory)
                items.append(contentsOf: selectedAccessories)
            }
        }
        
        return OutfitBuildResult(items: items, styleType: "casual")
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
        memory: StyleMemory
    ) -> [ClothingItem] {
        let preferredColor = colorPreference == "any" ? nil : colorPreference.lowercased()

        return items.sorted { a, b in
            func score(_ item: ClothingItem) -> Double {
                var s = 0.0
                if memory.favoriteItemIDs.contains(item.id) { s += 100 }
                if item.isFavorite { s += 50 }
                if let preferredColor, item.primaryColorHex.lowercased().contains(preferredColor) { s += 10 }
                
                // Boost items that match user's preferred categories
                let categoryBoost = Double(memory.getPreferredCategories(for: stylePreference).first { $0.0 == item.category.rawValue }?.1 ?? 0) * 0.5
                s += categoryBoost
                
                // Boost items that match user's preferred formality
                let formalityBoost = Double(memory.getPreferredFormality().first { $0.0 == item.formality.rawValue }?.1 ?? 0) * 0.3
                s += formalityBoost
                
                return s
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
        coordinatingWith: ClothingItem? = nil
    ) -> ClothingItem? {
        guard !items.isEmpty else { return nil }

        // Prefer favorites first.
        if let favorite = items.first(where: { memory.favoriteItemIDs.contains($0.id) || $0.isFavorite }) {
            return favorite
        }

        // If coordinating, lightly prefer same season.
        if let coordinatingWith {
            if let match = items.first(where: { $0.season == coordinatingWith.season }) {
                return match
            }
        }

        return items.first
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
        let hueDiff = min(abs(hsl1.h - hsl2.h), 360 - abs(hsl1.h - hsl2.h)) / 180.0
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
        return sqrt(pow(hueDiff * perceptualWeight, 2) * 0.6 + pow(satDiff, 2) * 0.3 + pow(lightDiff, 2) * 0.1)
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
        
        return alternatives
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