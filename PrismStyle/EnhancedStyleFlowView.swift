import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Enhanced StyleFlowView with comprehensive occasion input and AI recommendations
struct EnhancedStyleFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @Query(sort: [SortDescriptor(\OutfitLook.createdAt, order: .reverse)]) private var looks: [OutfitLook]
    @Query private var memories: [StyleMemory]
    @Query private var styleProfiles: [StyleProfile]

    @State private var step: Step = .context
    
    // Enhanced occasion inputs
    @State private var occasion: String = ""
    @State private var occasionPreset: String = ""
    @State private var timeOfDay: String = "Afternoon"
    @State private var formalityLevel: String = "auto"
    @State private var styleGoal: String = ""
    @State private var weather: String = "any"
    @State private var location: String = ""
    @State private var personalStyle: String = "any"
    @State private var colorPreference: String = "any"
    @State private var preferFavorites = true
    @State private var allowMixing = true
    @State private var prioritizeComfort = false
    @State private var budgetConsideration = "any"

    @State private var selectedUploadItems: [PhotosPickerItem] = []
    @State private var candidateImages: [UIImage] = []
    @State private var bestImage: UIImage?
    @State private var showingCamera = false

    @State private var isLoading = false
    @State private var suggestion: AdvancedStyleSuggestion?
    @State private var showingMultipleOutfits = false
    @State private var multipleOutfitImages: [UIImage] = []

    private let brain = AdvancedStyleBrain()

    enum Step { case context, pickMethod, confirm, result, multipleOutfitAnalysis }

    var body: some View {
        Group {
            switch step {
            case .context:
                contextStep
            case .pickMethod:
                methodStep
            case .confirm:
                confirmStep
            case .result:
                resultStep
            case .multipleOutfitAnalysis:
                multipleOutfitAnalysisStep
            }
        }
        .navigationTitle("Style AI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { ensureMemory() }
        .sheet(isPresented: $showingCamera) {
            EnhancedCameraBurstView(
                captureMode: .multiple,
                countdownSeconds: 7,
                burstCount: 5,
                totalOutfitsToCapture: 3,
                onCancel: { showingCamera = false },
                onCapturedBest: { image in
                    showingCamera = false
                    bestImage = image
                    step = .confirm
                },
                onCapturedMultiple: { images in
                    showingCamera = false
                    multipleOutfitImages = images
                    step = .multipleOutfitAnalysis
                }
            )
        }
        .task(id: selectedUploadItems) {
            await loadUploadsIfNeeded()
        }
    }

    // MARK: - Step 1: Enhanced Context Input
    private var contextStep: some View {
        Form {
            Section("What's the occasion?") {
                Picker("Quick pick", selection: $occasionPreset) {
                    Text("Select occasion").tag("")
                    ForEach(EnhancedStyleBrain.OCCASION_PRESETS, id: \.self) { v in
                        Text(v).tag(v)
                    }
                }
                .onChange(of: occasionPreset) { _, newValue in
                    if !newValue.isEmpty { 
                        occasion = newValue 
                        formalityLevel = EnhancedStyleBrain.getRecommendedFormality(for: newValue)
                    }
                }
                
                TextField("Or describe your own occasion...", text: $occasion, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Style Goals & Personality") {
                TextField("What look are you going for? (e.g., confident, professional, casual chic)", text: $styleGoal, axis: .vertical)
                    .lineLimit(2...4)
                
                Picker("Personal Style", selection: $personalStyle) {
                    Text("Any style").tag("any")
                    Text("Classic & Timeless").tag("classic")
                    Text("Modern & Trendy").tag("trendy")
                    Text("Minimalist").tag("minimalist")
                    Text("Bold & Statement").tag("bold")
                    Text("Casual & Comfortable").tag("casual")
                    Text("Professional").tag("professional")
                    Text("Romantic").tag("romantic")
                    Text("Edgy").tag("edgy")
                }
                .pickerStyle(.menu)
                
                Picker("Budget Range", selection: $budgetConsideration) {
                    Text("Any budget").tag("any")
                    Text("Budget-friendly").tag("budget")
                    Text("Mid-range").tag("mid")
                    Text("Premium").tag("premium")
                    Text("Luxury").tag("luxury")
                }
                .pickerStyle(.menu)
            }

            Section("When & Where") {
                Picker("Time of day", selection: $timeOfDay) {
                    Text("Morning").tag("Morning")
                    Text("Afternoon").tag("Afternoon")
                    Text("Evening").tag("Evening")
                    Text("Night").tag("Night")
                }
                .pickerStyle(.segmented)
                
                Picker("Weather", selection: $weather) {
                    Text("Any weather").tag("any")
                    Text("Hot & Sunny").tag("hot")
                    Text("Warm").tag("warm")
                    Text("Cool").tag("cool")
                    Text("Cold").tag("cold")
                    Text("Rainy").tag("rainy")
                }
                .pickerStyle(.menu)
                
                TextField("Location (optional)", text: $location)
            }

            Section("Formality & Dress Code") {
                Picker("Dress code", selection: $formalityLevel) {
                    Text("Auto-detect").tag("auto")
                    Text("Very Casual").tag("very_casual")
                    Text("Casual").tag("casual")
                    Text("Smart Casual").tag("smart_casual")
                    Text("Business").tag("business")
                    Text("Formal").tag("formal")
                    Text("Black Tie").tag("black_tie")
                }
                .pickerStyle(.menu)
            }

            Section("Color Preferences") {
                Picker("Color preference", selection: $colorPreference) {
                    Text("Any colors").tag("any")
                    Text("Neutral tones").tag("neutral")
                    Text("Warm colors").tag("warm")
                    Text("Cool colors").tag("cool")
                    Text("Bright & Bold").tag("bright")
                    Text("Dark & Moody").tag("dark")
                    Text("Pastels").tag("pastels")
                    Text("Earth tones").tag("earth")
                }
                .pickerStyle(.menu)
            }

            Section("Preferences") {
                Toggle("Prefer favorite items", isOn: $preferFavorites)
                Toggle("Mix & match pieces", isOn: $allowMixing)
                Toggle("Prioritize comfort", isOn: $prioritizeComfort)
            }

            Section {
                Button {
                    step = .pickMethod
                } label: {
                    HStack {
                        Spacer()
                        Label("Continue", systemImage: "arrow.right")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(occasion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Step 2: Enhanced Method Selection
    private var methodStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Show me your outfits")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("For \(occasion), I can analyze multiple outfit photos and recommend the perfect look.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                // Multiple outfit analysis option
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take photos of multiple outfits", systemImage: "camera.badge.clock")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("I'll take several photos of different outfit combinations and pick the best one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Upload multiple photos
                VStack(alignment: .leading, spacing: 12) {
                    PhotosPicker(selection: $selectedUploadItems, maxSelectionCount: 10, matching: .images) {
                        Label("Upload multiple outfit photos", systemImage: "photo.on.rectangle.angled")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("Share up to 10 photos of different outfit options you've put together.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                Divider()
                    .padding(.vertical)

                // Single photo options
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take a single photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("Quick photo with 7-second timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                // Build from closet only
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        bestImage = nil
                        candidateImages.removeAll()
                        selectedUploadItems.removeAll()
                        step = .result
                        runSuggestion(confirmedImages: [])
                    } label: {
                        Label("Build from my closet", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Text("I'll create a new outfit using your clothing items without photos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Step 3: Enhanced Confirmation
    private var confirmStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let bestImage {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best captured outfit:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Image(uiImage: bestImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("How does this look?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("I'll analyze this outfit and suggest improvements or recommend the best combination.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button {
                        bestImage = nil
                        candidateImages.removeAll()
                        selectedUploadItems.removeAll()
                        step = .pickMethod
                    } label: {
                        Label("Try again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        step = .result
                        runSuggestion(confirmedImages: bestImage != nil ? [bestImage!] : [])
                    } label: {
                        Label("Analyze outfit", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Step 4: Multiple Outfit Analysis
    private var multipleOutfitAnalysisStep: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !multipleOutfitImages.isEmpty {
                    Text("Analyzing \(multipleOutfitImages.count) outfits...")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(multipleOutfitImages.indices, id: \.self) { index in
                            VStack {
                                Image(uiImage: multipleOutfitImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text("Outfit \(index + 1)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if isLoading {
                    ProgressView("Analyzing your outfits...")
                        .padding()
                }

                Button {
                    step = .result
                    runSuggestion(confirmedImages: multipleOutfitImages)
                } label: {
                    Label("Get recommendations", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Step 5: Enhanced Results
    private var resultStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isLoading {
                    VStack {
                        ProgressView("Creating your perfect outfit...")
                        Text("Analyzing your style preferences and occasion requirements")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }

                if let suggestion {
                    // Main recommendation card
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(suggestion.verdict)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if let score = suggestion.confidenceScore {
                                    Text(String(format: "%.0f%%", score))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(score >= 80 ? Color.green.opacity(0.2) : score >= 60 ? Color.yellow.opacity(0.2) : Color.red.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text(suggestion.why)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if let detailed = suggestion.detailedSuggestion, !detailed.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("My recommendation:")
                                    .font(.headline)
                                Text(detailed)
                                    .font(.body)
                            }
                        }

                        // Style breakdown
                        if !suggestion.styleBreakdown.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Style breakdown:")
                                    .font(.headline)
                                
                                ForEach(suggestion.styleBreakdown, id: \.self) { item in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text(item)
                                            .font(.body)
                                    }
                                }
                            }
                        }

                        // Style tags
                        HStack {
                            ForEach(suggestion.styleTags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 2)
                    .padding(.horizontal)

                    // Best matching outfit photo
                    if let bestLookID = suggestion.bestLookID,
                       let look = looks.first(where: { $0.id == bestLookID }),
                       let ui = UIImage(data: look.imageData) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best match from your photos")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Image(uiImage: ui)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                        }
                    }

                    // Built outfit from closet
                    if !suggestion.suggestedItemIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended from your closet")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(clothingItems.filter { suggestion.suggestedItemIDs.contains($0.id) }) { item in
                                    HStack(spacing: 16) {
                                        if let data = item.imageData, let ui = UIImage(data: data) {
                                            Image(uiImage: ui)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        } else {
                                            Image(systemName: "tshirt")
                                                .frame(width: 60, height: 60)
                                                .background(Color.gray.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.name).font(.headline)
                                            Text(item.category.rawValue.capitalized).font(.caption).foregroundStyle(.secondary)
                                            if let formality = item.formality.rawValue.split(separator: ".").last {
                                                Text(formality.capitalized)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.1))
                                                    .clipShape(Capsule())
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if item.isFavorite {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Alternative suggestions
                    if !suggestion.alternativeSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Alternative suggestions")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(suggestion.alternativeSuggestions, id: \.self) { alt in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(alt.title)
                                        .font(.headline)
                                    Text(alt.description)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal)
                            }
                        }
                    }
                } else if !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "wand.and.stars")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("Ready to create your perfect outfit")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tell me about your occasion and I'll help you look your best")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

                // Action buttons
                if let suggestion {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button {
                                recordFeedback(for: suggestion, isPositive: true)
                            } label: {
                                Label("Love it!", systemImage: "hand.thumbsup")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                recordFeedback(for: suggestion, isPositive: false)
                            } label: {
                                Label("Not for me", systemImage: "hand.thumbsdown")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        Button {
                            // Start over with same context but different approach
                            self.suggestion = nil
                            isLoading = false
                            step = .pickMethod
                        } label: {
                            Label("Try different approach", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            // Complete reset
                            resetFlow()
                        } label: {
                            Label("Start completely over", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
    }

    // MARK: - Helpers
    private func ensureMemory() {
        if memories.first == nil {
            modelContext.insert(StyleMemory())
        }
    }

    private func loadUploadsIfNeeded() async {
        guard !selectedUploadItems.isEmpty else { return }
        var images: [UIImage] = []
        for item in selectedUploadItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                images.append(ui)
            }
        }
        
        candidateImages = images
        if images.count > 1 {
            multipleOutfitImages = images
            step = .multipleOutfitAnalysis
        } else if let best = images.max(by: { ImageScoring.sharpnessScore($0) < ImageScoring.sharpnessScore($1) }) {
            bestImage = best
            step = .confirm
        }
    }

    private func runSuggestion(confirmedImages: [UIImage]) {
        guard let memory = memories.first else { return }
        isLoading = true
        suggestion = nil

        let occ = StylePromptBuilder.Occasion(
            title: occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            timeOfDay: timeOfDay.isEmpty ? nil : timeOfDay,
            vibe: styleGoal.isEmpty ? nil : styleGoal,
            season: weather == "any" ? nil : weather
        )

        Task {
            // Persist uploaded images as Looks
            var lookCandidates: [OutfitLook] = []
            for confirmedImage in confirmedImages {
                if let data = confirmedImage.jpegData(compressionQuality: 0.9) {
                    await MainActor.run {
                        let persisted = OutfitLook(
                            occasion: occ.title, 
                            timeOfDay: occ.timeOfDay ?? "", 
                            notes: "AI analysis candidate", 
                            imageData: data
                        )
                        modelContext.insert(persisted)
                        lookCandidates.append(persisted)
                    }
                }
            }

            do {
                let s = try await brain.generateAdvancedRecommendation(
                    occasion: occ,
                    items: clothingItems,
                    looks: lookCandidates.isEmpty ? looks : lookCandidates,
                    memory: memory,
                    stylePreference: personalStyle,
                    colorPreference: colorPreference,
                    formalityLevel: formalityLevel,
                    prioritizeComfort: prioritizeComfort,
                    location: location.isEmpty ? nil : location
                )
                await MainActor.run {
                    suggestion = s
                    isLoading = false
                }

            } catch {
                await MainActor.run {
                    suggestion = AdvancedStyleSuggestion(
                        verdict: "Couldn\'t generate recommendation",
                        why: "Something went wrong. Please try again.",
                        detailedSuggestion: nil,
                        suggestedItemIDs: [],
                        bestLookID: nil,
                        confidenceScore: 0,
                        styleTags: [],
                        styleBreakdown: [],
                        alternativeSuggestions: []
                    )
                    isLoading = false
                }
            }
        }
    }
    
    private func recordFeedback(for suggestion: AdvancedStyleSuggestion, isPositive: Bool) {
        guard let memory = memories.first else { return }
        
        let key = "\(occasion)|\(timeOfDay)|\(personalStyle)"
        
        if isPositive {
            // Record positive feedback
            memory.recordWorn(occasionKey: key)
            
            // Record detailed preferences for AI learning
            memory.recordDetailedPreference(
                occasion: occasion,
                timeOfDay: timeOfDay,
                style: personalStyle,
                formality: formalityLevel,
                colors: colorPreference,
                location: location
            )
            
            // If this was a built outfit, learn from the items
            if let styleType = suggestion.styleTags.first, styleType != "matched" {
                for item in clothingItems.filter({ suggestion.suggestedItemIDs.contains($0.id) }) {
                    memory.recordFavorite(itemID: item.id)
                    memory.recordCategoryPreference(for: occasion, category: item.category.rawValue)
                    memory.recordFormalityPreference(item.formality.rawValue)
                    memory.recordColorCombination(primary: item.primaryColorHex, secondary: item.secondaryColorHex)
                }
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        } else {
            // Record negative feedback for learning
            memory.recordNegativeFeedback(for: key)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private func resetFlow() {
        occasion = ""
        occasionPreset = ""
        timeOfDay = "Afternoon"
        formalityLevel = "auto"
        styleGoal = ""
        weather = "any"
        location = ""
        personalStyle = "any"
        colorPreference = "any"
        budgetConsideration = "any"
        preferFavorites = true
        allowMixing = true
        prioritizeComfort = false
        selectedUploadItems = []
        candidateImages = []
        bestImage = nil
        suggestion = nil
        isLoading = false
        step = .context
    }
}

// MARK: - Advanced Style Suggestion

struct AdvancedStyleSuggestion {
    let verdict: String
    let why: String
    let detailedSuggestion: String?
    let suggestedItemIDs: [UUID]
    let bestLookID: UUID?
    let confidenceScore: Double?
    let styleTags: [String]
    let styleBreakdown: [String]
    let alternativeSuggestions: [AlternativeSuggestion]
}

#Preview {
    NavigationStack {
        EnhancedStyleFlowView()
    }
    .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self, FashionTrend.self, StyleProfile.self], inMemory: true)
}