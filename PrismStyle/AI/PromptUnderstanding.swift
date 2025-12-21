import Foundation
import NaturalLanguage

struct ParsedStylePrompt: Sendable {
    let inferredStylePreference: String?
    let inferredColorPreference: String?
    let inferredPrioritizeComfort: Bool?
}

/// Lightweight on-device prompt parsing using Apple's NaturalLanguage framework.
///
/// This is not an LLM. It’s a deterministic parser that improves robustness when users type free-form text
/// (e.g. "casual chic, warm colors, comfy").
enum PromptUnderstanding {

    static func parse(styleGoal: String, occasion: String) -> ParsedStylePrompt {
        let combined = [styleGoal, occasion]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !combined.isEmpty else {
            return ParsedStylePrompt(inferredStylePreference: nil, inferredColorPreference: nil, inferredPrioritizeComfort: nil)
        }

        let tokens = tokenizeLowercased(combined)

        let style = inferStylePreference(from: tokens)
        let color = inferColorPreference(from: tokens)
        let comfort = inferComfort(from: tokens)

        return ParsedStylePrompt(
            inferredStylePreference: style,
            inferredColorPreference: color,
            inferredPrioritizeComfort: comfort
        )
    }

    // MARK: - Internals

    private static func tokenizeLowercased(_ text: String) -> [String] {
        let lower = text.lowercased()
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = lower

        var out: [String] = []
        let range = lower.startIndex..<lower.endIndex
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: [.omitPunctuation, .omitWhitespace]) { _, tokenRange in
            let token = String(lower[tokenRange])
            if !token.isEmpty { out.append(token) }
            return true
        }

        return out
    }

    private static func inferStylePreference(from tokens: [String]) -> String? {
        // Map common words to the existing stylePreference values used by EnhancedStyleBrain.
        // Keep this minimal and predictable.
        let set = Set(tokens)

        if set.contains("minimal") || set.contains("minimalist") { return "minimalist" }
        if set.contains("classic") || set.contains("timeless") { return "classic" }
        if set.contains("trendy") || set.contains("modern") || set.contains("fashion") { return "trendy" }
        if set.contains("bold") || set.contains("statement") { return "bold" }
        if set.contains("romantic") { return "romantic" }
        if set.contains("edgy") { return "edgy" }
        if set.contains("professional") || set.contains("office") || set.contains("business") { return "professional" }
        if set.contains("casual") { return "casual" }

        return nil
    }

    private static func inferColorPreference(from tokens: [String]) -> String? {
        let set = Set(tokens)

        if set.contains("neutral") || set.contains("neutrals") { return "neutral" }
        if set.contains("warm") || set.contains("warmth") { return "warm" }
        if set.contains("cool") { return "cool" }
        if set.contains("bright") || set.contains("vibrant") { return "bright" }
        if set.contains("dark") || set.contains("black") { return "dark" }
        if set.contains("pastel") || set.contains("pastels") { return "pastels" }

        return nil
    }

    private static func inferComfort(from tokens: [String]) -> Bool? {
        let set = Set(tokens)
        if set.contains("comfortable") || set.contains("comfort") || set.contains("comfy") || set.contains("relaxed") {
            return true
        }
        return nil
    }
}
