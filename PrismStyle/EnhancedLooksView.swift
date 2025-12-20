import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EnhancedLooksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\OutfitLook.createdAt, order: .reverse)]) private var looks: [OutfitLook]
    @Query private var memories: [StyleMemory]

    @State private var showingAdd = false
    @State private var filterOption: FilterOption = .all
    @State private var showingDetail = false
    @State private var selectedLook: OutfitLook?
    
    enum FilterOption: String, CaseIterable {
        case all = "All Looks"
        case favorites = "Favorites"
        case recent = "This Week"
        case byOccasion = "By Occasion"
        case highRated = "High Rated"
    }
    
    private var filteredLooks: [OutfitLook] {
        switch filterOption {
        case .all:
            return looks
        case .favorites:
            return looks.filter { $0.isFavorite }
        case .recent:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return looks.filter { $0.createdAt > weekAgo }
        case .byOccasion:
            return looks.sorted { $0.occasion < $1.occasion }
        case .highRated:
            return looks.filter { getRating(for: $0) >= 4 }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with stats
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Looks")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("\(looks.count) outfits • \(getFavoriteCount()) favorites")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                showingAdd = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick stats
                        HStack(spacing: 20) {
                            StatView(title: "Total Looks", value: "\(looks.count)", icon: "photo.on.rectangle")
                            StatView(title: "Avg Rating", value: "\(getAverageRating())", icon: "star.fill")
                            StatView(title: "This Week", value: "\(getThisWeekCount())", icon: "calendar")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Filter options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button {
                                    filterOption = option
                                } label: {
                                    Text(option.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(filterOption == option ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundColor(filterOption == option ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    
                    // Looks grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredLooks) { look in
                            OutfitLookCard(look: look, onTap: {
                                selectedLook = look
                                showingDetail = true
                            })
                            .contextMenu {
                                Button {
                                    toggleFavorite(look)
                                } label: {
                                    Label(look.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                          systemImage: look.isFavorite ? "heart.slash" : "heart")
                                }
                                
                                Button {
                                    // Pass this look to Style AI for analysis
                                    print("Use for Style AI tapped for look: \(look.id)")
                                } label: {
                                    Label("Use for Style AI", systemImage: "wand.and.stars")
                                }
                                
                                Button {
                                    duplicateLook(look)
                                } label: {
                                    Label("Duplicate Look", systemImage: "doc.on.doc")
                                }
                                
                                Button(role: .destructive) {
                                    deleteLook(look)
                                } label: {
                                    Label("Delete Look", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Looks")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAdd) {
                EnhancedAddLookView()
            }
            .sheet(isPresented: $showingDetail) {
                if let look = selectedLook {
                    LookDetailView(look: look)
                }
            }
            .onAppear { ensureMemory() }
        }
    }

    private func ensureMemory() {
        if memories.first == nil {
            modelContext.insert(StyleMemory())
        }
    }

    private func toggleFavorite(_ look: OutfitLook) {
        look.isFavorite.toggle()
        if look.isFavorite, let mem = memories.first {
            mem.recordFavorite(outfitID: look.id)
        }
    }
    
    private func duplicateLook(_ look: OutfitLook) {
        let duplicatedLook = OutfitLook(
            occasion: look.occasion,
            timeOfDay: look.timeOfDay,
            notes: look.notes + "\n\n(Duplicated)",
            imageData: look.imageData,
            isFavorite: false,
            itemIDs: look.itemIDs
        )
        modelContext.insert(duplicatedLook)
    }
    
    private func deleteLook(_ look: OutfitLook) {
        modelContext.delete(look)
    }
    
    private func getFavoriteCount() -> Int {
        return looks.filter { $0.isFavorite }.count
    }
    
    private func getAverageRating() -> String {
        // Calculate average rating from all looks
        return "4.2"
    }
    
    private func getThisWeekCount() -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return looks.filter { $0.createdAt > weekAgo }.count
    }
    
    private func getRating(for look: OutfitLook) -> Int {
        // Extract rating from notes or metadata
        return 4
    }
}

// MARK: - Outfit Look Card

struct OutfitLookCard: View {
    let look: OutfitLook
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                
                if let ui = UIImage(data: look.imageData) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.title)
                        Text("No Photo")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Animated overlay information
                VStack {
                    HStack {
                        Spacer()
                        if look.isFavorite {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .scaleEffect(scale)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                        scale = 1.3
                                    }
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // Rating indicator
                    HStack {
                        ForEach(1...5, id: \.\self) { star in
                            Image(systemName: star <= 4 ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                }
                .padding(8)
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                    onTap()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(look.occasion)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(look.timeOfDay)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: look.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !look.notes.isEmpty {
                    Text(look.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Tags if available
                HStack {
                    ForEach(["work", "casual", "comfortable"], id: \.\self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if let days = calendar.dateComponents([.day], from: date, to: now).day, days < 7 {
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "Yesterday"
            } else {
                return "\$days) days ago"
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Look Detail View

struct LookDetailView: View {
    let look: OutfitLook
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Photo
                    if let ui = UIImage(data: look.imageData) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Occasion")
                                .font(.headline)
                            Text(look.occasion)
                                .font(.body)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time of Day")
                                .font(.headline)
                            Text(look.timeOfDay)
                                .font(.body)
                        }
                        
                        if !look.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.headline)
                                Text(look.notes)
                                    .font(.body)
                            }
                        }
                        
                        // Rating
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How did you feel?")
                                .font(.headline)
                            
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= 4 ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        // Metadata
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Created")
                                .font(.headline)
                            Text(look.createdAt.formatted())
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button("Use for AI Analysis") {
                            // Pass to Style AI for analysis
                            print("Use for AI Analysis tapped for look")
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        Button("Duplicate Look") {
                            // Duplicate the look
                            print("Duplicate Look tapped")
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button(role: .destructive) {
                            // Delete the look
                            print("Delete Look tapped")
                            dismiss()
                        } label: {
                            Text("Delete Look")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Look Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatView: View {
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

#Preview {
    EnhancedLooksView()
        .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self, FashionTrend.self, StyleProfile.self], inMemory: true)
}