import Foundation
import SwiftData

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
        return preferredColorCombinations.sorted(by: { $0.value > $1.value })
    }
    
    func getPreferredCategories(for occasion: String) -> [(String, Int)] {
        guard let categories = preferredCategoriesByOccasion[occasion] else { return [] }
        return categories.sorted(by: { $0.value > $1.value })
    }
    
    func getPreferredFormality() -> [(String, Int)] {
        return preferredFormality.sorted(by: { $0.value > $1.value })
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
}
