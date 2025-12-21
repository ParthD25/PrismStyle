//
//  PrismStyleApp.swift
//  PrismStyle
//
//  Enhanced AI-powered outfit recommendation app for iOS
//  Advanced algorithms with color theory, style matching, and comprehensive features
//

import SwiftUI
import SwiftData
import AppIntents

@main
struct PrismStyleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClothingItem.self,
            OutfitLook.self,
            StyleMemory.self,
            FeedbackEvent.self,
            FashionTrend.self,
            StyleProfile.self,
            WeatherData.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

@available(iOS 16.0, *)
struct OpenPrismStyleIntent: AppIntent {
    static var title: LocalizedStringResource = "Open PrismStyle"

    func perform() async throws -> some IntentResult {
        .result()
    }
}