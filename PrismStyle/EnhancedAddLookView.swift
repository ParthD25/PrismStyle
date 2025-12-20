import SwiftUI
import SwiftData
import PhotosUI

struct EnhancedAddLookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var clothingItems: [ClothingItem]
    
    @State private var occasion = ""
    @State private var timeOfDay = "Afternoon"
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var selectedItems: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Photo Section
                    VStack(spacing: DesignSystem.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.Colors.surfaceVariant)
                                .aspectRatio(3/4, contentMode: .fit)
                            
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
                                    
                                    Text("Add Outfit Photo")
                                        .font(DesignSystem.Typography.bodyMedium)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                        }
                        .aspectRatio(3/4, contentMode: .fit)
                        
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
                    
                    // Outfit Details
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Outfit Details")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        // Occasion
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Occasion")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("e.g., Date Night, Work Meeting", text: $occasion)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Time of Day
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Time of Day")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            Picker("Time", selection: $timeOfDay) {
                                Text("Morning").tag("Morning")
                                Text("Afternoon").tag("Afternoon")
                                Text("Evening").tag("Evening")
                                Text("Night").tag("Night")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                            Text("Notes (Optional)")
                                .font(DesignSystem.Typography.labelMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            TextField("Add any notes about this look...", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                    .background(DesignSystem.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .modernCardStyle()
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    
                    // Items in this Look
                    if !clothingItems.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Items in this Look")
                                .font(DesignSystem.Typography.titleLarge)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text("Select items from your closet that are part of this outfit")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm),
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.sm)
                            ], spacing: DesignSystem.Spacing.sm) {
                                ForEach(clothingItems) { item in
                                    ModernClothingItemCheckbox(
                                        item: item,
                                        isSelected: selectedItems.contains(item.id)
                                    ) {
                                        if selectedItems.contains(item.id) {
                                            selectedItems.remove(item.id)
                                        } else {
                                            selectedItems.insert(item.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(DesignSystem.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                        .modernCardStyle()
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    // Action Buttons
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .modernButtonStyle(variant: .secondary, size: .large)
                        
                        Button("Save Look") {
                            saveLook()
                        }
                        .modernButtonStyle(variant: .primary, size: .large)
                        .disabled(occasion.isEmpty || imageData == nil)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Create Look")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func saveLook() {
        guard let imageData else { return }
        
        let look = OutfitLook(
            occasion: occasion,
            timeOfDay: timeOfDay,
            notes: notes,
            imageData: imageData,
            itemIDs: Array(selectedItems)
        )
        
        modelContext.insert(look)
        dismiss()
    }
}

// MARK: - Modern Clothing Item Checkbox
struct ModernClothingItemCheckbox: View {
    let item: ClothingItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(DesignSystem.Colors.surfaceVariant)
                        .aspectRatio(1, contentMode: .fit)
                    
                    if let data = item.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    } else {
                        Image(systemName: "tshirt")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    // Selection indicator
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.primary)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(DesignSystem.Spacing.xs)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                Text(item.name)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(item.category.rawValue.capitalized)
                    .font(DesignSystem.Typography.labelSmall)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.surfaceVariant, lineWidth: 2)
            )
        }
        .foregroundColor(DesignSystem.Colors.textPrimary)
    }
}