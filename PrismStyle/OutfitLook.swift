import Foundation
import SwiftData

/// A photo of a full outfit (past or present) that the user uploaded or captured.
@Model
final class OutfitLook {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var occasion: String = ""
    var timeOfDay: String = ""
    var notes: String = ""
    @Attribute(.externalStorage) var imageData: Data = Data()
    var isFavorite: Bool = false

    /// Optional link to specific closet items (manually assigned in a future iteration).
    var itemIDs: [UUID] = []

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
        self.itemIDs = itemIDs
    }
}

