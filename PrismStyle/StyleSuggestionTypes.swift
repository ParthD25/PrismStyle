import Foundation

/// Shared lightweight types used across the app's style engines and SwiftUI views.
///
/// These types are intentionally kept small and dependency-free so they can be
/// used by the recommendation engines (Foundation-only) and UI.
enum StylePromptBuilder {
    struct Occasion: Hashable, Codable {
        var title: String
        var timeOfDay: String?
        var vibe: String?
        var season: String?

        init(title: String, timeOfDay: String? = nil, vibe: String? = nil, season: String? = nil) {
            self.title = title
            self.timeOfDay = timeOfDay
            self.vibe = vibe
            self.season = season
        }
    }
}

struct AlternativeSuggestion: Hashable, Codable {
    let title: String
    let description: String
    let styleType: String
}

struct EnhancedStyleSuggestion {
    let verdict: String
    let why: String
    let detailedSuggestion: String
    let suggestedItemIDs: [UUID]
    let bestLookID: UUID?
    let confidenceScore: Double
    let styleTags: [String]
    let styleBreakdown: [String]
    let alternativeSuggestions: [AlternativeSuggestion]
}
