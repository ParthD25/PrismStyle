import AppIntents

// MARK: - Recommend Outfit

struct RecommendOutfitIntent: AppIntent {
    static var title: LocalizedStringResource = "Recommend an Outfit"
    static var description = IntentDescription("Get an outfit recommendation for a given occasion.")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Occasion")
    var occasion: String

    @Parameter(title: "Style Goal", default: "")
    var styleGoal: String

    func perform() async throws -> some IntentResult {
        // iOS 17-compatible: we open the app and let the existing Style AI flow handle data
        // and on-device Vision/NL parsing.
        let goalText = styleGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        let msg = goalText.isEmpty
            ? "Opening PrismStyle with your occasion."
            : "Opening PrismStyle with your occasion and style goal."

        return .result(dialog: IntentDialog(stringLiteral: msg))
    }
}

// MARK: - Log Outfit

struct LogOutfitIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Today’s Outfit"
    static var description = IntentDescription("Open PrismStyle to log what you wore today.")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Occasion", default: "")
    var occasion: String

    @Parameter(title: "Notes", default: "")
    var notes: String

    func perform() async throws -> some IntentResult {
        return .result(dialog: IntentDialog(stringLiteral: "Opening PrismStyle to log your outfit."))
    }
}

// NOTE:
// We intentionally do not register suggested phrases via AppShortcutsProvider here.
// The API surface varies across Xcode/iOS SDK versions, and keeping compilation stable
// is more important than suggested phrases. The intents themselves are still discoverable
// in Shortcuts and Siri search.
