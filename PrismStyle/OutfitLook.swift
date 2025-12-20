import Foundation
import SwiftData

/// A photo of a full outfit (past or present) that the user uploaded or captured.
@Model
final class OutfitLook {
    var id: UUID
    var createdAt: Date
    var occasion: String
    var timeOfDay: String
    var notes: String
    var imageData: Data
    var isFavorite: Bool

    /// Optional link to specific closet items (stored as JSON for SwiftData compatibility).
    var itemIDsData: Data

    var itemIDs: [UUID] {
        get { decodeJSON([UUID].self, from: itemIDsData) ?? [] }
        set { itemIDsData = encodeJSON(newValue) }
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        occasion: String,
        timeOfDay: String,
        notes: String = "",
        imageData: Data,
        isFavorite: Bool = false,
        itemIDs: [UUID] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.occasion = occasion
        self.timeOfDay = timeOfDay
        self.notes = notes
        self.imageData = imageData
        self.isFavorite = isFavorite
        self.itemIDsData = encodeJSON(itemIDs)
    }
}
