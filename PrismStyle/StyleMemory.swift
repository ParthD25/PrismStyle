import Foundation
import SwiftData

@Model
final class StyleMemory {
    var id: UUID
    var userAgeRange: String?
    var favoriteItemIDs: [UUID]
    var favoriteOutfitIDs: [UUID]
    /// How often the user *selects* something for a given occasion/time.
    var selectionCounts: [String: Int]
    /// How often the user actually *wore* something for a given occasion/time.
    var wornCounts: [String: Int]
    /// User's preferred color combinations
    var preferredColorCombinations: [String: Int]
    /// User's preferred categories for different occasions
    var preferredCategoriesByOccasion: [String: [String: Int]]
    /// User's preferred formality levels
    var preferredFormality: [String: Int]
    
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
        self.favoriteItemIDs = favoriteItemIDs
        self.favoriteOutfitIDs = favoriteOutfitIDs
        self.selectionCounts = selectionCounts
        self.wornCounts = wornCounts
        self.preferredColorCombinations = preferredColorCombinations
        self.preferredCategoriesByOccasion = preferredCategoriesByOccasion
        self.preferredFormality = preferredFormality
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
    
    func getMostPreferredColors() -> [(String, Int)] {
        return preferredColorCombinations.sorted { $0.value > $1.value }
    }
    
    func getPreferredCategories(for occasion: String) -> [(String, Int)] {
        guard let categories = preferredCategoriesByOccasion[occasion] else { return [] }
        return categories.sorted { $0.value > $1.value }
    }
    
    func getPreferredFormality() -> [(String, Int)] {
        return preferredFormality.sorted { $0.value > $1.value }
    }
}
