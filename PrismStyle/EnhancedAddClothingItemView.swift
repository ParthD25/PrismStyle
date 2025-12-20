import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EnhancedAddClothingItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var category: ClothingItem.ClothingCategory = .tops
    @State private var formality: ClothingItem.Formality = .casual
    @State private var season: String = "all"
    @State private var primaryColorHex: String = "#ECF0F1"
    @State private var secondaryColorHex: String = ""
    @State private var pattern: String = ""
    @State private var material: String = ""
    @State private var brand: String = ""
    @State private var purchaseDate = Date()
    @State private var price: String = ""
    @State private var size: String = ""
    @State private var notes: String = ""
    @State private var isFavorite: Bool = false
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingColorPicker = false
    @State private var showingPatternPicker = false
    @State private var showingSizeChart = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add to Your Closet")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Add clothing items to build your digital wardrobe and get AI-powered outfit recommendations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Photo section with improved UI
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Photo")
                            .font(.headline)
                        
                        HStack(alignment: .center, spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 120, height: 120)
                                
                                if let imageData, let ui = UIImage(data: imageData) {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tshirt")
                                            .font(.title)
                                        Text("Add Photo")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Text("Choose Photo")
                                        .font(.callout)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                
                                Text("Clear, well-lit photos work best for AI analysis")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Basic information section
                    VStack(spacing: 16) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Item Name")
                                .font(.headline)
                            TextField("e.g., Blue Denim Jacket", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        // Category picker with icons
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(ClothingItem.ClothingCategory.allCases) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: self.category == category,
                                        action: { self.category = category }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Formality picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Formality Level")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(ClothingItem.Formality.allCases) { formality in
                                        FormalityButton(
                                            formality: formality,
                                            isSelected: self.formality == formality,
                                            action: { self.formality = formality }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Season picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Season")
                                .font(.headline)
                            
                            Picker("Season", selection: $season) {
                                Text("All Year").tag("all")
                                Text("Spring").tag("spring")
                                Text("Summer").tag("summer")
                                Text("Fall").tag("fall")
                                Text("Winter").tag("winter")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                    }
                    
                    // Color section with visual picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Colors")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Primary Color")
                                    .font(.callout)
                                Spacer()
                                
                                Button {
                                    showingColorPicker = true
                                } label: {
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: primaryColorHex) ?? .gray)
                                            .frame(width: 20, height: 20)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                        
                                        Text(primaryColorHex)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            HStack {
                                Text("Secondary Color (Optional)")
                                    .font(.callout)
                                Spacer()
                                
                                if secondaryColorHex.isEmpty {
                                    Button {
                                        showingColorPicker = true
                                    } label: {
                                        Text("Add")
                                            .font(.caption)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                } else {
                                    Button {
                                        showingColorPicker = true
                                    } label: {
                                        HStack {
                                            Circle()
                                                .fill(Color(hex: secondaryColorHex) ?? .gray)
                                                .frame(width: 20, height: 20)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                            
                                            Text(secondaryColorHex)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick color suggestions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(commonColors, id: \.hex) { color in
                                    Button {
                                        if secondaryColorHex.isEmpty {
                                            secondaryColorHex = color.hex
                                        } else {
                                            primaryColorHex = color.hex
                                        }
                                    } label: {
                                        VStack {
                                            Circle()
                                                .fill(Color(hex: color.hex) ?? .gray)
                                                .frame(width: 30, height: 30)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                            Text(color.name)
                                                .font(.caption2)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Details section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            // Pattern
                            HStack {
                                Text("Pattern")
                                    .font(.callout)
                                Spacer()
                                Button {
                                    showingPatternPicker = true
                                } label: {
                                    Text(pattern.isEmpty ? "Select" : pattern)
                                        .font(.caption)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            
                            // Material
                            HStack {
                                Text("Material")
                                    .font(.callout)
                                Spacer()
                                TextField("e.g., Cotton", text: $material)
                                    .frame(maxWidth: 120)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Brand
                            HStack {
                                Text("Brand")
                                    .font(.callout)
                                Spacer()
                                TextField("e.g., Nike", text: $brand)
                                    .frame(maxWidth: 120)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Size with chart button
                            HStack {
                                Text("Size")
                                    .font(.callout)
                                Spacer()
                                HStack {
                                    TextField("e.g., M", text: $size)
                                        .frame(maxWidth: 60)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Button {
                                        showingSizeChart = true
                                    } label: {
                                        Image(systemName: "chart.bar")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            // Price
                            HStack {
                                Text("Price")
                                    .font(.callout)
                                Spacer()
                                TextField("0.00", text: $price)
                                    .frame(maxWidth: 80)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Purchase date
                            HStack {
                                Text("Purchase Date")
                                    .font(.callout)
                                Spacer()
                                DatePicker("", selection: $purchaseDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tags section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tags")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Add new tag
                            HStack {
                                TextField("Add tag (e.g., work, casual)", text: $newTag)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button {
                                    if !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        tags.append(newTag.trimmingCharacters(in: .whitespacesAndNewlines))
                                        newTag = ""
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                            }
                            
                            // Existing tags
                            if !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(tags, id: \.self) { tag in
                                            HStack {
                                                Text(tag)
                                                    .font(.caption)
                                                Button {
                                                    tags.removeAll { $0 == tag }
                                                } label: {
                                                    Image(systemName: "xmark")
                                                        .font(.caption2)
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.1))
                                            .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                            
                            // Quick tag suggestions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(["work", "casual", "formal", "date", "party", "comfortable", "favorite"], id: \.self) { tag in
                                        Button {
                                            if !tags.contains(tag) {
                                                tags.append(tag)
                                            }
                                        } label: {
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.gray.opacity(0.1))
                                                .clipShape(Capsule())
                                        }
                                        .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                    }
                    
                    // Favorite toggle
                    Toggle(isOn: $isFavorite) {
                        HStack {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(isFavorite ? .red : .secondary)
                            Text("Mark as Favorite")
                                .font(.headline)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Save button
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Item")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $primaryColorHex)
            }
            .sheet(isPresented: $showingPatternPicker) {
                PatternPickerView(selectedPattern: $pattern)
            }
            .sheet(isPresented: $showingSizeChart) {
                SizeChartView()
            }
            .task(id: selectedPhoto) {
                guard let item = selectedPhoto else { return }
                if let data = try? await item.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = ClothingItem(
            id: UUID(),
            name: trimmed,
            category: category,
            formality: formality,
            season: season,
            primaryColorHex: primaryColorHex.isEmpty ? "#ECF0F1" : primaryColorHex,
            secondaryColorHex: secondaryColorHex.isEmpty ? nil : secondaryColorHex,
            pattern: pattern.isEmpty ? nil : pattern,
            material: material.isEmpty ? nil : material,
            notes: notes,
            imageData: imageData,
            isFavorite: isFavorite
        )
        
        // Store additional metadata in notes
        var metadata: [String] = []
        if !brand.isEmpty { metadata.append("Brand: \(brand)") }
        if !size.isEmpty { metadata.append("Size: \(size)") }
        if !price.isEmpty { metadata.append("Price: $\(price)") }
        if !tags.isEmpty { metadata.append("Tags: \(tags.joined(separator: ", "))") }
        metadata.append("Purchase Date: \(purchaseDate.formatted(date: .abbreviated, time: .omitted))")
        
        if !metadata.isEmpty {
            item.notes = (item.notes.isEmpty ? "" : "\(item.notes)\n\n") + metadata.joined(separator: "\n")
        }
        
        modelContext.insert(item)
        dismiss()
    }
}

// MARK: - Supporting Views

struct CategoryButton: View {
    let category: ClothingItem.ClothingCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: category))
                    .font(.title2)
                Text(category.rawValue.capitalized)
                    .font(.caption)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    
    private func iconName(for category: ClothingItem.ClothingCategory) -> String {
        switch category {
        case .tops: return "tshirt"
        case .bottoms: return "figure.stand"
        case .outerwear: return "wind"
        case .footwear: return "shoe"
        case .accessories: return "sparkles"
        case .dresses: return "person.fill"
        case .suits: return "person.2.fill"
        }
    }
}

struct FormalityButton: View {
    let formality: ClothingItem.Formality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formality == .smartCasual ? "Smart Casual" : formality.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose a color")
                    .font(.headline)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(commonColors, id: \.hex) { color in
                        Button {
                            selectedColor = color.hex
                            dismiss()
                        } label: {
                            VStack {
                                Circle()
                                    .fill(Color(hex: color.hex) ?? .gray)
                                    .frame(width: 50, height: 50)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Text(color.name)
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Color Picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct PatternPickerView: View {
    @Binding var selectedPattern: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(commonPatterns, id: \.self) { pattern in
                    Button {
                        selectedPattern = pattern
                        dismiss()
                    } label: {
                        HStack {
                            Text(pattern)
                            Spacer()
                            if selectedPattern == pattern {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Pattern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct SizeChartView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Size Guide")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Tops")
                        .font(.headline)
                    
                    ForEach([("XS", "32-34"), ("S", "34-36"), ("M", "38-40"), ("L", "42-44"), ("XL", "46-48")], id: \.0) { size, chest in
                        HStack {
                            Text(size)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Chest: \(chest)\"")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Bottoms")
                        .font(.headline)
                    
                    ForEach([("XS", "24-26"), ("S", "26-28"), ("M", "30-32"), ("L", "34-36"), ("XL", "38-40")], id: \.0) { size, waist in
                        HStack {
                            Text(size)
                                .fontWeight(.medium)
                            Spacer()
                            Text("Waist: \(waist)\"")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding()
            .navigationTitle("Size Chart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Common colors and patterns
let commonColors = [
    (name: "Black", hex: "#000000"),
    (name: "White", hex: "#FFFFFF"),
    (name: "Gray", hex: "#808080"),
    (name: "Navy", hex: "#000080"),
    (name: "Blue", hex: "#0000FF"),
    (name: "Red", hex: "#FF0000"),
    (name: "Green", hex: "#008000"),
    (name: "Yellow", hex: "#FFFF00"),
    (name: "Purple", hex: "#800080"),
    (name: "Pink", hex: "#FFC0CB"),
    (name: "Orange", hex: "#FFA500"),
    (name: "Brown", hex: "#A52A2A"),
    (name: "Beige", hex: "#F5F5DC"),
    (name: "Khaki", hex: "#C3B091"),
    (name: "Burgundy", hex: "#800020"),
    (name: "Teal", hex: "#008080")
]

let commonPatterns = [
    "Solid",
    "Striped",
    "Plaid",
    "Checked",
    "Polka Dot",
    "Floral",
    "Paisley",
    "Geometric",
    "Abstract",
    "Animal Print",
    "Camouflage",
    "Herringbone",
    "Tweed",
    "Knit",
    "Lace"
]

#Preview {
    EnhancedAddClothingItemView()
        .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self, FashionTrend.self, StyleProfile.self], inMemory: true)
}