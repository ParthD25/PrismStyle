import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @Query private var memories: [StyleMemory]
    @Query private var styleProfiles: [StyleProfile]

    @State private var showingAddClothingItem = false
    @State private var sortOption: SortOption = .name
    @State private var selectedTab: Tab = .closet
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case category = "Category"
        case recent = "Recently Added"
        case favorites = "Favorites First"
        case formality = "Formality"
        case color = "Color"
        case usage = "Most Worn"
        
        var title: String {
            rawValue
        }
    }
    
    enum Tab: String, CaseIterable {
        case closet = "Closet"
        case looks = "Looks"
        case styleAI = "Style AI"
        case trends = "Trends"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .closet: return "hanger"
            case .looks: return "photo.on.rectangle"
            case .styleAI: return "wand.and.stars"
            case .trends: return "chart.line.uptrend.xyaxis"
            case .profile: return "person.circle"
            }
        }
    }
    
    private var sortedClothingItems: [ClothingItem] {
        switch sortOption {
        case .name:
            return clothingItems.sorted { $0.name < $1.name }
        case .category:
            return clothingItems.sorted { $0.category.rawValue < $1.category.rawValue }
        case .recent:
            return clothingItems.sorted { $0.createdAt > $1.createdAt }
        case .favorites:
            return clothingItems.sorted { 
                if $0.isFavorite && !$1.isFavorite { return true }
                if !$0.isFavorite && $1.isFavorite { return false }
                return $0.name < $1.name
            }
        case .formality:
            return clothingItems.sorted { $0.formality.rawValue < $1.formality.rawValue }
        case .color:
            return clothingItems.sorted { $0.primaryColorHex < $1.primaryColorHex }
        case .usage:
            return clothingItems.sorted { 
                let usage1 = getUsageCount(for: $0.id)
                let usage2 = getUsageCount(for: $1.id)
                return usage1 > usage2
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Enhanced Closet Tab
            closetTab
                .tag(Tab.closet)
                .tabItem { 
                    VStack {
                        Image(systemName: Tab.closet.icon)
                            .font(.title2)
                        Text(Tab.closet.rawValue)
                    }
                }

            // Enhanced Looks Tab
            EnhancedLooksView()
                .tag(Tab.looks)
                .tabItem { 
                    VStack {
                        Image(systemName: Tab.looks.icon)
                            .font(.title2)
                        Text(Tab.looks.rawValue)
                    }
                }

            // Enhanced AI Style Tab
            NavigationStack {
                EnhancedStyleFlowView()
            }
            .tag(Tab.styleAI)
            .tabItem { 
                VStack {
                    Image(systemName: Tab.styleAI.icon)
                        .font(.title2)
                    Text(Tab.styleAI.rawValue)
                }
            }

            // Fashion Trends Tab
            FashionTrendsView()
                .tag(Tab.trends)
                .tabItem { 
                    VStack {
                        Image(systemName: Tab.trends.icon)
                            .font(.title2)
                        Text(Tab.trends.rawValue)
                    }
                }

            // Style Profile Tab
            StyleProfileView()
                .tag(Tab.profile)
                .tabItem { 
                    VStack {
                        Image(systemName: Tab.profile.icon)
                            .font(.title2)
                        Text(Tab.profile.rawValue)
                    }
                }
        }
        .onAppear { ensureMemory() }
        .accentColor(.blue)
    }

    private var closetTab: some View {
        NavigationStack {
            VStack {
                // Enhanced header with stats
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Closet")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("\(clothingItems.count) items • \(getFavoriteCount()) favorites")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingAddClothingItem = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Quick stats
                    HStack(spacing: 20) {
                        DashboardStatView(title: "Total Items", value: "\(clothingItems.count)", icon: "tshirt")
                        DashboardStatView(title: "Outfits", value: "\(getOutfitCount())", icon: "photo.on.rectangle")
                        DashboardStatView(title: "Style Score", value: "\(getStyleScore())", icon: "star.fill")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Enhanced sorting and filtering options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Sort options
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.title) {
                                    sortOption = option
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text("Sort: \(sortOption.title)")
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        // Filter options
                        ForEach(["All", "Tops", "Bottoms", "Dresses", "Outerwear"], id: \.self) { filter in
                            Button(filter) {
                                // TODO: Implement filtering
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                }
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(sortedClothingItems) { item in
                            ClothingItemCard(item: item)
                                .onTapGesture {
                                    // TODO: Show detail view with outfit suggestions
                                }
                                .contextMenu {
                                    Button {
                                        toggleFavorite(item)
                                    } label: {
                                        Label(item.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                              systemImage: item.isFavorite ? "heart.slash" : "heart")
                                    }
                                    
                                    Button {
                                        // TODO: Show in outfit builder
                                    } label: {
                                        Label("Build Outfit With This", systemImage: "wand.and.stars")
                                    }
                                    
                                    Button {
                                        // TODO: Mark as worn
                                    } label: {
                                        Label("Mark as Worn", systemImage: "checkmark.circle")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddClothingItem) {
                EnhancedAddClothingItemView()
            }
        }
    }

    private func ensureMemory() {
        if memories.first == nil {
            modelContext.insert(StyleMemory())
        }
        
        if styleProfiles.first == nil {
            let profile = StyleProfile(
                userName: "User",
                bodyType: "average",
                colorSeason: "all",
                stylePersonality: "classic",
                lifestyle: "mixed"
            )
            modelContext.insert(profile)
        }
    }

    private func toggleFavorite(_ item: ClothingItem) {
        item.isFavorite.toggle()
        if item.isFavorite, let mem = memories.first {
            mem.recordFavorite(itemID: item.id)
        }
    }
    
    private func getFavoriteCount() -> Int {
        return clothingItems.filter { $0.isFavorite }.count
    }
    
    private func getOutfitCount() -> Int {
        // This would query OutfitLook items
        return 0
    }
    
    private func getStyleScore() -> String {
        // Calculate based on AI learning and user feedback
        return "85%"
    }
    
    private func getUsageCount(for itemID: UUID) -> Int {
        // This would track usage from StyleMemory
        return 0
    }
}

// MARK: - Supporting Views

struct DashboardStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                
                if let data = item.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: "tshirt")
                            .font(.title)
                        Text(item.category.rawValue.capitalized)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Color indicators
                VStack {
                    HStack {
                        Circle()
                            .fill(Color(hex: item.primaryColorHex) ?? .gray)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        
                        if let secondary = item.secondaryColorHex {
                            Circle()
                                .fill(Color(hex: secondary) ?? .gray)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                        }
                        
                        Spacer()
                        
                        if item.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(item.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.formality.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Usage indicator
                HStack {
                    if let pattern = item.pattern, !pattern.isEmpty {
                        Text(pattern)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Fashion Trends View

struct FashionTrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var trends: [FashionTrend]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fashion Trends")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Stay updated with the latest fashion trends and incorporate them into your style")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Current season trends
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This Season")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(getCurrentSeasonTrends()) { trend in
                            TrendCard(trend: trend)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Color trends
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trending Colors")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(getTrendingColors(), id: \.self) { color in
                                    VStack {
                                        Circle()
                                            .fill(Color(hex: color) ?? .gray)
                                            .frame(width: 60, height: 60)
                                        Text(color)
                                            .font(.caption)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Style inspiration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Style Inspiration")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ForEach(1...5, id: \.self) { _ in
                            InspirationCard()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func getCurrentSeasonTrends() -> [FashionTrend] {
        let currentSeason = getCurrentSeason()
        return trends.filter { $0.season == currentSeason }
    }
    
    private func getTrendingColors() -> [String] {
        return ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FECA57"]
    }
    
    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }
}

struct TrendCard: View {
    let trend: FashionTrend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(trend.trendName)
                .font(.headline)
            
            Text("\(trend.season.capitalized) \(trend.year)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(trend.keyColors, id: \.self) { color in
                        Circle()
                            .fill(Color(hex: color) ?? .gray)
                            .frame(width: 30, height: 30)
                    }
                }
            }
            
            ForEach(trend.keyStyles, id: \.self) { style in
                Text("• \(style)")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InspirationCard: View {
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Casual Chic")
                    .font(.headline)
                Text("Perfect for weekend brunches")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(1...3, id: \.self) { _ in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            Spacer()
            
            Button("Try") {
                // TODO: Apply this style
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Style Profile View

struct StyleProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var styleProfiles: [StyleProfile]
    @Query private var memories: [StyleMemory]
    
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let profile = styleProfiles.first {
                        // Profile Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                            
                            Text(profile.userName)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your Personal Style Profile")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Style Analysis
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Style Analysis")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            StyleMetricView(title: "Body Type", value: profile.bodyType, icon: "person")
                            StyleMetricView(title: "Color Season", value: profile.colorSeason, icon: "paintpalette")
                            StyleMetricView(title: "Style Personality", value: profile.stylePersonality, icon: "sparkles")
                            StyleMetricView(title: "Lifestyle", value: profile.lifestyle, icon: "briefcase")
                            StyleMetricView(title: "Budget Range", value: profile.budgetRange, icon: "dollarsign.circle")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        
                        // Style Statistics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Style Statistics")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            HStack(spacing: 20) {
                                DashboardStatView(title: "Outfits Created", value: "24", icon: "photo.on.rectangle")
                                DashboardStatView(title: "AI Suggestions", value: "89%", icon: "wand.and.stars")
                                DashboardStatView(title: "Style Consistency", value: "92%", icon: "checkmark.circle")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Actions")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 12) {
                                Button("Update Style Quiz") {
                                    showingEditProfile = true
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(maxWidth: .infinity)
                                
                                Button("View Style History") {
                                    // TODO: Show style history
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                                
                                Button("Export Style Profile") {
                                    // TODO: Export profile
                                }
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        
                    } else {
                        // Empty state
                        VStack(spacing: 24) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            
                            VStack(spacing: 8) {
                                Text("Create Your Style Profile")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Help the AI understand your personal style for better recommendations")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button("Start Style Quiz") {
                                showingEditProfile = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Style Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                StyleQuizView()
            }
        }
    }
}

struct StyleMetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value.capitalized)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Style Quiz View

struct StyleQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentQuestion = 0
    @State private var answers: [String: String] = [:]
    
    let questions = [
        (id: "bodyType", question: "What's your body type?", options: ["Petite", "Average", "Tall", "Curvy", "Athletic"]),
        (id: "colorSeason", question: "Which color palette suits you best?", options: ["Spring", "Summer", "Autumn", "Winter", "All Colors"]),
        (id: "stylePersonality", question: "What's your style personality?", options: ["Classic", "Trendy", "Minimalist", "Bold", "Romantic"]),
        (id: "lifestyle", question: "What's your lifestyle?", options: ["Professional", "Casual", "Active", "Social", "Mixed"])
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ProgressView(value: Double(currentQuestion) / Double(questions.count))
                    .padding(.horizontal)
                
                if currentQuestion < questions.count {
                    let question = questions[currentQuestion]
                    
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Question \(currentQuestion + 1) of \(questions.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(question.question)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(question.options, id: \.self) { option in
                                Button {
                                    answers[question.id] = option
                                    if currentQuestion < questions.count - 1 {
                                        currentQuestion += 1
                                    } else {
                                        saveProfile()
                                    }
                                } label: {
                                    HStack {
                                        Text(option)
                                        Spacer()
                                        if answers[question.id] == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .background(answers[question.id] == option ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Completion view
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Profile Complete!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your style profile has been created. The AI will now provide more personalized recommendations.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Continue") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
            .navigationTitle("Style Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveProfile() {
        let profile = StyleProfile(
            userName: "User",
            bodyType: answers["bodyType"] ?? "average",
            colorSeason: answers["colorSeason"] ?? "all",
            stylePersonality: answers["stylePersonality"] ?? "classic",
            lifestyle: answers["lifestyle"] ?? "mixed"
        )
        
        modelContext.insert(profile)
        currentQuestion = questions.count
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self, FashionTrend.self, StyleProfile.self], inMemory: true)
}