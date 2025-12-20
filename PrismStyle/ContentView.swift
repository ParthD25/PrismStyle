import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @Query private var memories: [StyleMemory]
    
    @State private var selectedTab: Tab = .styleAI
    @State private var showingAddClothingItem = false
    
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
        
        var color: Color {
            switch self {
            case .closet: return DesignSystem.Colors.fashion1
            case .looks: return DesignSystem.Colors.fashion2
            case .styleAI: return DesignSystem.Colors.primary
            case .trends: return DesignSystem.Colors.fashion3
            case .profile: return DesignSystem.Colors.fashion4
            }
        }
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ModernHeaderView(title: selectedTab.rawValue)
                
                // Content
                ZStack {
                    switch selectedTab {
                    case .closet:
                        ModernClosetView(showingAddClothingItem: $showingAddClothingItem)
                    case .looks:
                        ModernLooksView()
                    case .styleAI:
                        EnhancedStyleFlowView()
                    case .trends:
                        ModernTrendsView()
                    case .profile:
                        ModernProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Modern Tab Bar
                ModernTabBar(selectedTab: $selectedTab)
            }
        }
        .sheet(isPresented: $showingAddClothingItem) {
            ModernAddClothingItemView()
        }
        .onAppear { ensureMemory() }
    }
    
    private func ensureMemory() {
        if memories.first == nil {
            modelContext.insert(StyleMemory())
        }
    }
}

// MARK: - Modern Header View
struct ModernHeaderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(DesignSystem.Typography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Notification bell
                Button {
                    // Show a simple alert for now - can be expanded to full notification system
                    print("Notifications tapped")
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.lg)
            
            Divider()
                .background(DesignSystem.Colors.surfaceVariant)
        }
        .background(DesignSystem.Colors.surface)
        .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Tab Bar
struct ModernTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack {
            ForEach(ContentView.Tab.allCases, id: \.\self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        ZStack {
                            // Animated selection indicator
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(tab.color)
                                    .frame(width: 24, height: 4)
                                    .matchedGeometryEffect(id: "tabIndicator", in: animationNamespace)
                                    .offset(y: 12)
                            }
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundColor(selectedTab == tab ? tab.color : DesignSystem.Colors.textSecondary)
                        }
                        
                        Text(tab.rawValue)
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(selectedTab == tab ? tab.color : DesignSystem.Colors.textSecondary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(AnimatedTabButtonStyle())
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surface)
        .shadow(color: DesignSystem.Colors.textPrimary.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Animated Tab Button Style
struct AnimatedTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Closet View
struct ModernClosetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    @Binding var showingAddClothingItem: Bool
    
    @State private var sortOption: SortOption = .recent
    @State private var filterCategory: ClothingItem.ClothingCategory? = nil
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case recent = "Recent"
        case favorites = "Favorites"
        case category = "Category"
        
        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .recent: return "clock"
            case .favorites: return "heart"
            case .category: return "square.grid.2x2"
            }
        }
    }
    
    private var sortedItems: [ClothingItem] {
        switch sortOption {
        case .name:
            return clothingItems.sorted(by: { $0.name < $1.name })
        case .recent:
            return clothingItems.sorted(by: { $0.createdAt > $1.createdAt })
        case .favorites:
            return clothingItems.sorted(by: {
                if $0.isFavorite && !$1.isFavorite { return true }
                if !$0.isFavorite && $1.isFavorite { return false }
                return $0.name < $1.name
            })
        case .category:
            return clothingItems.sorted(by: { $0.category.rawValue < $1.category.rawValue })
        }
    }
    
    private var filteredItems: [ClothingItem] {
        if let category = filterCategory {
            return sortedItems.filter { $0.category == category }
        }
        return sortedItems
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Header with gradient background
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("My Closet")
                                .font(DesignSystem.Typography.displaySmall)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                            
                            Text("\$$clothingItems.count) items")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                                        
                        Spacer()
                                        
                        Button {
                            showingAddClothingItem = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [DesignSystem.Colors.gradientStart, DesignSystem.Colors.gradientEnd]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.lg)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
                                
                // Quick Stats with cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ModernStatCard(
                            title: "Total Items",
                            value: "\$$clothingItems.count)",
                            icon: "tshirt",
                            color: DesignSystem.Colors.primary
                        )
                                        
                        ModernStatCard(
                            title: "Favorites",
                            value: "\$$clothingItems.filter { $0.isFavorite }.count)",
                            icon: "heart.fill",
                            color: DesignSystem.Colors.error
                        )
                                        
                        ModernStatCard(
                            title: "Categories",
                            value: "\$$Set(clothingItems.map { $0.category }).count)",
                            icon: "square.grid.2x2",
                            color: DesignSystem.Colors.fashion2
                        )
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                                
                // Sort and Filter with modern controls
                HStack {
                    // Sort Control
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Sort By")
                            .font(DesignSystem.Typography.labelMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    sortOption = option
                                } label: {
                                    Label(option.rawValue, systemImage: option.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: sortOption.icon)
                                Text(sortOption.rawValue)
                                    .font(DesignSystem.Typography.bodyMedium)
                                                
                                Spacer()
                                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.surfaceVariant, lineWidth: 1)
                            )
                        }
                    }
                                    
                    Spacer()
                                    
                    // Filter Control
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Filter")
                            .font(DesignSystem.Typography.labelMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        
                        Menu {
                            Button("All Items") { filterCategory = nil }
                            ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { category in
                                Button(category.rawValue.capitalized) {
                                    filterCategory = category
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                Text(filterCategory?.rawValue.capitalized ?? "All")
                                    .font(DesignSystem.Typography.bodyMedium)
                                                
                                Spacer()
                                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.surfaceVariant, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                // Items Grid
                if filteredItems.isEmpty {
                    ModernEmptyStateView(
                        title: "No Items Yet",
                        message: "Start building your digital wardrobe by adding your first clothing item",
                        actionTitle: "Add Item",
                        action: { showingAddClothingItem = true }
                    )
                    .padding(.horizontal, DesignSystem.Spacing.md)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                    ], spacing: DesignSystem.Spacing.md) {
                        ForEach(filteredItems) { item in
                            ModernClothingItemCard(item: item)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
            }
            .padding(.vertical, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Modern Stat View
struct ModernStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(DesignSystem.Typography.titleMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Text(title)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
    }
}

// MARK: - Modern Stat Card
struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Text(value)
                    .font(DesignSystem.Typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
            }
            
            Text(title)
                .font(DesignSystem.Typography.labelSmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 140)
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
    }
}

// MARK: - Modern Clothing Item Card
struct ModernClothingItemCard: View {
    let item: ClothingItem
    @Environment(\.modelContext) private var modelContext
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.surfaceVariant)
                    .aspectRatio(1, contentMode: .fit)
                
                if let data = item.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                } else {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "tshirt")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(item.category.rawValue.capitalized)
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                // Animated Favorite Badge
                if item.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(DesignSystem.Colors.error)
                                .padding(DesignSystem.Spacing.xs)
                                .background(DesignSystem.Colors.surface)
                                .clipShape(Circle())
                                .padding(DesignSystem.Spacing.xs)
                                .scaleEffect(scale)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        scale = 1.2
                                    }
                                }
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.name)
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    Text(item.category.rawValue.capitalized)
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(item.formality.rawValue.capitalized)
                        .font(DesignSystem.Typography.labelSmall)
                        .padding(.horizontal, DesignSystem.Spacing.xs)
                        .padding(.vertical, DesignSystem.Spacing.xs / 2)
                        .background(DesignSystem.Colors.surfaceVariant)
                        .clipShape(Capsule())
                }
                
                // Color Indicators
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Circle()
                        .fill(Color(hex: item.primaryColorHex) ?? DesignSystem.Colors.textSecondary)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(DesignSystem.Colors.surface, lineWidth: 1))
                    
                    if let secondary = item.secondaryColorHex {
                        Circle()
                            .fill(Color(hex: secondary) ?? DesignSystem.Colors.textSecondary)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(DesignSystem.Colors.surface, lineWidth: 1))
                    }
                    
                    Spacer()
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    toggleFavorite(item)
                }
            } label: {
                Label(item.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                      systemImage: item.isFavorite ? "heart.slash" : "heart.fill")
            }
            
            Button {
                // For now, we'll just print - can be expanded to full edit functionality
                print("Edit item tapped")
            } label: {
                Label("Edit Item", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                deleteItem(item)
            } label: {
                Label("Delete Item", systemImage: "trash")
            }
        }
    }
    
    private func toggleFavorite(_ item: ClothingItem) {
        item.isFavorite.toggle()
    }
    
    private func deleteItem(_ item: ClothingItem) {
        modelContext.delete(item)
    }
}

// MARK: - Modern Looks View
struct ModernLooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\OutfitLook.createdAt, order: .reverse)]) private var looks: [OutfitLook]
    
    @State private var showingAddLook = false
    @State private var selectedLook: OutfitLook?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("My Looks")
                                .font(DesignSystem.Typography.displaySmall)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("\(looks.count) saved outfits")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingAddLook = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Looks Grid
                    if looks.isEmpty {
                        ModernEmptyStateView(
                            title: "No Looks Yet",
                            message: "Start creating outfit looks by taking photos or building from your closet",
                            actionTitle: "Create Look",
                            action: { showingAddLook = true }
                        )
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                        ], spacing: DesignSystem.Spacing.md) {
                            ForEach(looks) { look in
                                ModernLookCard(look: look)
                                    .onTapGesture {
                                        selectedLook = look
                                    }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Looks")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddLook) {
                EnhancedAddLookView()
            }
            .sheet(item: $selectedLook) { look in
                ModernLookDetailView(look: look)
            }
        }
    }
}

// MARK: - Modern Look Card
struct ModernLookCard: View {
    let look: OutfitLook
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.surfaceVariant)
                    .aspectRatio(3/4, contentMode: .fit)
                
                if let ui = UIImage(data: look.imageData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                } else {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "photo")
                            .font(.system(size: 32))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .aspectRatio(3/4, contentMode: .fit)
            
            // Content
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(look.occasion)
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    if !look.timeOfDay.isEmpty {
                        Text(look.timeOfDay)
                            .font(DesignSystem.Typography.labelSmall)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xs / 2)
                            .background(DesignSystem.Colors.surfaceVariant)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text(look.createdAt, style: .date)
                        .font(DesignSystem.Typography.labelSmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                if !look.notes.isEmpty {
                    Text(look.notes)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
        .contextMenu {
            Button(role: .destructive) {
                deleteLook(look)
            } label: {
                Label("Delete Look", systemImage: "trash")
            }
        }
    }
    
    private func deleteLook(_ look: OutfitLook) {
        modelContext.delete(look)
    }
}

// MARK: - Modern Style AI View (Placeholder)
struct ModernStyleAIView: View {
    @State private var isAnimating = false
    @State private var rotationAngle: Double = 0.0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Animated AI Icon
            ZStack {
                // Pulsing background
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0.3 : 0.1)
                
                // Rotating stars
                ForEach(0..<6) { index in
                    Image(systemName: "star.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(.system(size: 20))
                        .offset(x: 50 * cos(CGFloat(index) * .pi * 2 / 6))
                        .offset(y: 50 * sin(CGFloat(index) * .pi * 2 / 6))
                        .rotationEffect(.degrees(rotationAngle))
                }
                
                // Central wand and stars
                Image(systemName: "wand.and.stars")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 48))
                    .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Style AI Assistant")
                    .font(DesignSystem.Typography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Get personalized outfit recommendations based on your style preferences, occasion, and wardrobe")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
            }
            
            // Feature Highlights
            VStack(spacing: DesignSystem.Spacing.lg) {
                HStack(spacing: DesignSystem.Spacing.xl) {
                    FeatureIcon(icon: "brain", title: "Smart Learning")
                    FeatureIcon(icon: "wand.and.stars", title: "AI Recommendations")
                }
                
                HStack(spacing: DesignSystem.Spacing.xl) {
                    FeatureIcon(icon: "photo.on.rectangle", title: "Visual Analysis")
                    FeatureIcon(icon: "heart", title: "Personal Style")
                }
            }
            .padding(.top, DesignSystem.Spacing.xxl)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.background)
    }
}

// MARK: - Feature Icon Component
struct FeatureIcon: View {
    let icon: String
    let title: String
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [DesignSystem.Colors.primary, DesignSystem.Colors.fashion1]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 24))
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
            
            Text(title)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isHovered = false
                }
            }
        }
    }
}

// MARK: - Modern Trends View
struct ModernTrendsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\FashionTrend.popularityScore, order: .reverse)]) private var trends: [FashionTrend]
    @Query private var clothingItems: [ClothingItem]
    
    @State private var selectedSeason = "Current"
    
    let seasons = ["Current", "Spring", "Summer", "Fall", "Winter"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Fashion Trends")
                            .font(DesignSystem.Typography.displaySmall)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Discover what's trending and get personalized recommendations")
                            .font(DesignSystem.Typography.bodyMedium)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Season Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(seasons, id: \.self) { season in
                                Button {
                                    selectedSeason = season
                                } label: {
                                    Text(season)
                                        .font(DesignSystem.Typography.labelMedium)
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                        .padding(.vertical, DesignSystem.Spacing.sm)
                                        .background(selectedSeason == season ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant)
                                        .foregroundColor(selectedSeason == season ? .white : DesignSystem.Colors.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    // Trending Items
                    if trends.isEmpty {
                        ModernEmptyStateView(
                            title: "No Trends Available",
                            message: "Fashion trends will appear here based on your style and current fashion",
                            actionTitle: nil,
                            action: nil
                        )
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    } else {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(trends.filter { selectedSeason == "Current" || $0.season == selectedSeason.lowercased() }) { trend in
                                ModernTrendCard(trend: trend, items: clothingItems)
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Trends")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Modern Trend Card
struct ModernTrendCard: View {
    let trend: FashionTrend
    let items: [ClothingItem]
    
    var matchingItems: [ClothingItem] {
        items.filter { item in
            trend.suggestedCategories.contains(item.category.rawValue) ||
            trend.suggestedColors.contains(item.primaryColorHex)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Trend Header
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(trend.name)
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        Text(trend.category)
                            .font(DesignSystem.Typography.labelSmall)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xs / 2)
                            .background(DesignSystem.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text(trend.season.capitalized)
                            .font(DesignSystem.Typography.labelSmall)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, DesignSystem.Spacing.xs / 2)
                            .background(DesignSystem.Colors.fashion2.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.error)
                        
                        Text("\(Int(trend.popularityScore))%")
                            .font(DesignSystem.Typography.labelSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            
            // Description
            Text(trend.description)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(3)
            
            // Matching Items
            if !matchingItems.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("You have \(matchingItems.count) matching item\(matchingItems.count == 1 ? "" : "s"):")
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(matchingItems.prefix(5)) { item in
                                VStack(spacing: DesignSystem.Spacing.xs) {
                                    if let data = item.imageData, let ui = UIImage(data: data) {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                                    } else {
                                        Image(systemName: "tshirt")
                                            .frame(width: 60, height: 60)
                                            .background(DesignSystem.Colors.surfaceVariant)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                                    }
                                    
                                    Text(item.name)
                                        .font(DesignSystem.Typography.labelSmall)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            
            // Key Elements
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text("Key Elements:")
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                ForEach(trend.keyElements, id: \.self) { element in
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Circle()
                            .fill(DesignSystem.Colors.primary)
                            .frame(width: 6, height: 6)
                        
                        Text(element)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
    }
}

// MARK: - Modern Profile View
struct ModernProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var styleProfiles: [StyleProfile]
    @Query private var clothingItems: [ClothingItem]
    @Query private var looks: [OutfitLook]
    @Query private var memories: [StyleMemory]
    
    @State private var showingProfileSetup = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Profile Header
                    if let profile = styleProfiles.first {
                        ModernProfileHeader(profile: profile)
                    } else {
                        ModernProfileSetupPrompt(onSetup: { showingProfileSetup = true })
                    }
                    
                    // Stats Section
                    ModernProfileStats(
                        totalItems: clothingItems.count,
                        totalLooks: looks.count,
                        favoriteItems: clothingItems.filter { $0.isFavorite }.count
                    )
                    
                    // Style Insights
                    if let memory = memories.first {
                        ModernStyleInsights(memory: memory)
                    }
                    
                    // Settings and Actions
                    ModernProfileActions()
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProfileSetup) {
                ModernProfileSetupView()
            }
        }
    }
}

// MARK: - Modern Profile Header
struct ModernProfileHeader: View {
    let profile: StyleProfile
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            // Name and Style
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(profile.name)
                    .font(DesignSystem.Typography.displaySmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Style: \(profile.preferredStyle)")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            // Quick Tags
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(profile.stylePreferences.prefix(3), id: \.self) { preference in
                    Text(preference)
                        .font(DesignSystem.Typography.labelSmall)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Colors.surfaceVariant)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Modern Profile Setup Prompt
struct ModernProfileSetupPrompt: View {
    let onSetup: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "person.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Complete Your Profile")
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Tell us about your style preferences to get better recommendations")
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                onSetup()
            } label: {
                Label("Set Up Profile", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .modernButtonStyle(variant: .primary, size: .medium)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .modernCardStyle()
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

// MARK: - Modern Profile Stats
struct ModernProfileStats: View {
    let totalItems: Int
    let totalLooks: Int
    let favoriteItems: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Your Stats")
                .font(DesignSystem.Typography.titleLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                ModernStatView(
                    title: "Closet Items",
                    value: "\(totalItems)",
                    icon: "tshirt",
                    color: DesignSystem.Colors.primary
                )
                
                ModernStatView(
                    title: "Saved Looks",
                    value: "\(totalLooks)",
                    icon: "photo.on.rectangle",
                    color: DesignSystem.Colors.fashion2
                )
                
                ModernStatView(
                    title: "Favorites",
                    value: "\(favoriteItems)",
                    icon: "heart",
                    color: DesignSystem.Colors.error
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Modern Style Insights
struct ModernStyleInsights: View {
    let memory: StyleMemory
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Style Insights")
                .font(DesignSystem.Typography.titleLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                // Most Worn Style
                if let mostWorn = memory.occasionFrequency.max(by: { $0.value < $1.value }) {
                    ModernInsightCard(
                        title: "Most Worn Style",
                        value: mostWorn.key,
                        subtitle: "Worn \(mostWorn.value) time\(mostWorn.value == 1 ? "" : "s")",
                        icon: "star",
                        color: DesignSystem.Colors.fashion1
                    )
                }
                
                // Favorite Category
                if let favCategory = memory.categoryPreferences.max(by: { $0.value < $1.value }) {
                    ModernInsightCard(
                        title: "Favorite Category",
                        value: favCategory.key.capitalized,
                        subtitle: "Preferred for most occasions",
                        icon: "square.grid.2x2",
                        color: DesignSystem.Colors.fashion2
                    )
                }
                
                // Color Preference
                if let colorPref = memory.colorCombinationFrequency.max(by: { $0.value < $1.value }) {
                    ModernInsightCard(
                        title: "Go-To Colors",
                        value: colorPref.key,
                        subtitle: "Your most worn color combination",
                        icon: "paintpalette",
                        color: DesignSystem.Colors.fashion3
                    )
                }
                
                // Style Consistency Score
                let consistencyScore = memory.styleInsights["styleConsistencyScore"] as? Int ?? 50
                ModernProgressInsightCard(
                    title: "Style Consistency",
                    value: consistencyScore,
                    subtitle: consistencyScore > 80 ? "Very consistent style" : consistencyScore > 60 ? "Moderately consistent" : "Exploring different styles",
                    icon: "chart.bar.doc.horizontal",
                    color: DesignSystem.Colors.primary
                )
                
                // Style Diversity Score
                let diversityScore = memory.styleInsights["diversityScore"] as? Int ?? 50
                ModernProgressInsightCard(
                    title: "Style Diversity",
                    value: diversityScore,
                    subtitle: diversityScore > 80 ? "Highly diverse style" : diversityScore > 60 ? "Moderately diverse" : "Focused style",
                    icon: "paintbrush.pointed",
                    color: DesignSystem.Colors.fashion2
                )
                
                // Preference Stability
                let stabilityScore = (memory.styleInsights["preferenceStability"] as? Double ?? 0.5) * 100
                ModernProgressInsightCard(
                    title: "Preference Stability",
                    value: Int(stabilityScore),
                    subtitle: stabilityScore > 80 ? "Very stable preferences" : stabilityScore > 60 ? "Moderately stable" : "Evolving preferences",
                    icon: "waveform.path.ecg",
                    color: DesignSystem.Colors.fashion3
                )
                
                // Favorite Colors Visualization
                if let favoriteColors = memory.styleInsights["favoriteColorCombinations"] as? [String], !favoriteColors.isEmpty {
                    ModernColorInsightCard(
                        title: "Your Color Palette",
                        colors: favoriteColors.prefix(5).map { Color(hex: $0) ?? .gray },
                        subtitle: "Most used colors in your wardrobe"
                    )
                }
                
                // Seasonal Preferences
                if let seasonalPrefs = memory.styleInsights["seasonalPreferences"] as? [String: Int], !seasonalPrefs.isEmpty {
                    ModernSeasonalInsightCard(
                        title: "Seasonal Preferences",
                        seasonalData: seasonalPrefs,
                        subtitle: "Your style preferences by season"
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Modern Progress Insight Card
struct ModernProgressInsightCard: View {
    let title: String
    let value: Int
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title)
                        .font(DesignSystem.Typography.labelMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("\(value)%")
                        .font(DesignSystem.Typography.titleMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DesignSystem.Colors.surfaceVariant)
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * CGFloat(value) / 100.0, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .modernCardStyle()
    }
}

// MARK: - Modern Color Insight Card
struct ModernColorInsightCard: View {
    let title: String
    let colors: [Color]
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Color palette visualization
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<colors.count, id: \.self) { index in
                    Circle()
                        .fill(colors[index])
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(DesignSystem.Colors.surface, lineWidth: 2)
                        )
                }
                
                Spacer()
            }
            
            Text(subtitle)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .modernCardStyle()
    }
}

// MARK: - Modern Insight Card
struct ModernInsightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.labelMedium)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(value)
                    .font(DesignSystem.Typography.titleMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .modernCardStyle()
    }
}

// MARK: - Modern Seasonal Insight Card
struct ModernSeasonalInsightCard: View {
    let title: String
    let seasonalData: [String: Int]
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.labelMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            // Seasonal chart visualization
            ModernSeasonalChartView(seasonalData: seasonalData)
            
            Text(subtitle)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .modernCardStyle()
    }
}

// MARK: - Modern Profile Actions
struct ModernProfileActions: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Settings")
                .font(DesignSystem.Typography.titleLarge)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, DesignSystem.Spacing.md)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                ModernActionRow(
                    title: "Edit Profile",
                    icon: "person.crop.rectangle",
                    action: {}
                )
                
                ModernActionRow(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    action: {}
                )
                
                ModernActionRow(
                    title: "Privacy Settings",
                    icon: "lock",
                    action: {}
                )
                
                ModernActionRow(
                    title: "Help & Support",
                    icon: "questionmark.circle",
                    action: {}
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

// MARK: - Modern Action Row
struct ModernActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.surfaceVariant)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .modernCardStyle()
        }
    }
}

// MARK: - Modern Add Item View
struct ModernAddClothingItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var category: ClothingItem.ClothingCategory = .tops
    @State private var formality: ClothingItem.Formality = .casual
    @State private var primaryColorHex = "#000000"
    @State private var secondaryColorHex: String?
    @State private var material = ""
    @State private var season = "all"
    @State private var isFavorite = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    
    let seasons = ["all", "spring", "summer", "fall", "winter"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Photo Section
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.Colors.surfaceVariant)
                                .aspectRatio(1, contentMode: .fit)
                            
                            if let imageData, let ui = UIImage(data: imageData) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                            } else {
                                VStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    Text("Add Photo")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label(imageData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                        }
                        .modernButtonStyle(variant: .secondary, size: .medium)
                        .onChange(of: selectedPhoto) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    imageData = data
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Basic Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Basic Information")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Name
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Item Name")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("e.g., Blue Denim Jacket", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Category")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(ClothingItem.ClothingCategory.allCases, id: \.self) { cat in
                                    Text(cat.rawValue.capitalized).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Formality
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Formality")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Formality", selection: $formality) {
                                ForEach(ClothingItem.Formality.allCases, id: \.self) { form in
                                    Text(form.rawValue.capitalized).tag(form)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Colors
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Colors")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Primary Color
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Primary Color")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            ColorPicker("Primary Color", selection: Binding(
                                get: { Color(hex: primaryColorHex) ?? .black },
                                set: { primaryColorHex = $0.toHex() ?? "#000000" }
                            ))
                        }
                        
                        // Secondary Color
                        Toggle("Has secondary color", isOn: .constant(secondaryColorHex != nil))
                        
                        if secondaryColorHex != nil {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Secondary Color")
                                    .font(DesignSystem.Typography.labelMedium)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                ColorPicker("Secondary Color", selection: Binding(
                                    get: { Color(hex: secondaryColorHex ?? "#FFFFFF") ?? .white },
                                    set: { secondaryColorHex = $0.toHex() }
                                ))
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Additional Details")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Material
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Material (Optional)")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("e.g., Cotton, Leather", text: $material)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Season
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Best Season")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Season", selection: $season) {
                                ForEach(seasons, id: \.self) { s in
                                    Text(s.capitalized).tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Favorite Toggle
                        Toggle("Add to Favorites", isOn: $isFavorite)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Action Buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .modernButtonStyle(variant: .secondary, size: .large)
                        
                        Button("Save Item") {
                            saveItem()
                        }
                        .modernButtonStyle(variant: .primary, size: .large)
                        .disabled(name.isEmpty || imageData == nil)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Add Clothing Item")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func saveItem() {
        guard let imageData else { return }
        
        let item = ClothingItem(
            name: name,
            category: category,
            formality: formality,
            season: season,
            primaryColorHex: primaryColorHex,
            secondaryColorHex: secondaryColorHex,
            material: material.isEmpty ? nil : material,
            imageData: imageData,
            isFavorite: isFavorite
        )
        
        modelContext.insert(item)
        dismiss()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self], inMemory: true)
}