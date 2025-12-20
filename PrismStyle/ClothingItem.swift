import SwiftUI
import SwiftData

@Model
final class ClothingItem {
    let id: UUID

    enum ClothingCategory: String, CaseIterable, Identifiable, Codable {
        case tops
        case bottoms
        case outerwear
        case footwear
        case accessories
        case dresses
        case suits
        
        var id: String { rawValue }
    }
    
    enum Formality: String, CaseIterable, Identifiable, Codable {
        case casual
        case smartCasual
        case formal
        case athletic
        case business
        case party
        
        var id: String { rawValue }
    }
    
    var name: String
    var category: ClothingCategory
    var formality: Formality
    var season: String
    var primaryColorHex: String
    var secondaryColorHex: String?
    var pattern: String?
    var material: String?
    var notes: String
    var imageData: Data?
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        formality: Formality,
        season: String = "all",
        primaryColorHex: String = "#ECF0F1",
        secondaryColorHex: String? = nil,
        pattern: String? = nil,
        material: String? = nil,
        notes: String = "",
        imageData: Data? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.formality = formality
        self.season = season
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.pattern = pattern
        self.material = material
        self.notes = notes
        self.imageData = imageData
        self.isFavorite = isFavorite
    }
}
