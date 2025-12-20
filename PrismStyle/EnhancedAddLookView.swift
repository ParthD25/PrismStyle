import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct EnhancedAddLookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var occasion: String = ""
    @State private var timeOfDay: String = ""
    @State private var location: String = ""
    @State private var weather: String = ""
    @State private var mood: String = ""
    @State private var notes: String = ""
    @State private var rating: Int = 0
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var itemIDs: [UUID] = []

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingCamera = false
    @State private var showingItemSelector = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a New Look")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Share a photo of an outfit you've worn to help train the AI and build your style memory")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Photo section with camera option
                    VStack(spacing: 16) {
                        // Photo picker options
                        HStack(spacing: 16) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.title2)
                                    Text("Choose Photo")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                showingCamera = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera")
                                        .font(.title2)
                                    Text("Take Photo")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Preview image
                        if let imageData, let ui = UIImage(data: imageData) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Outfit Preview")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .frame(height: 300)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Occasion details
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Occasion")
                                .font(.headline)
                            
                            // Quick occasion buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickOccasions, id: \.self) { occasionType in
                                        Button {
                                            occasion = occasionType
                                        } label: {
                                            Text(occasionType)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(occasion == occasionType ? Color.blue : Color.gray.opacity(0.1))
                                                .foregroundColor(occasion == occasionType ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Custom occasion field
                            TextField("Or describe your own occasion...", text: $occasion)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time of Day")
                                .font(.headline)
                            
                            Picker("Time of Day", selection: $timeOfDay) {
                                Text("Select").tag("")
                                Text("Morning").tag("Morning")
                                Text("Afternoon").tag("Afternoon")
                                Text("Evening").tag("Evening")
                                Text("Night").tag("Night")
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.headline)
                            TextField("e.g., Office, Restaurant, Park", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weather")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(weatherOptions, id: \.self) { weatherOption in
                                        Button {
                                            weather = weather == weatherOption ? "" : weatherOption
                                        } label: {
                                            Text(weatherOption)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(weather == weatherOption ? Color.blue : Color.gray.opacity(0.1))
                                                .foregroundColor(weather == weatherOption ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mood / Vibe")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(moodOptions, id: \.self) { moodOption in
                                        Button {
                                            mood = mood == moodOption ? "" : moodOption
                                        } label: {
                                            Text(moodOption)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(mood == moodOption ? Color.blue : Color.gray.opacity(0.1))
                                                .foregroundColor(mood == moodOption ? .white : .primary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Rating section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How did you feel in this outfit?")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    rating = star
                                } label: {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Clothing items used
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Clothing Items")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingItemSelector = true
                            } label: {
                                Text("Add Items")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        if !itemIDs.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(itemIDs, id: \.self) { itemID in
                                        // This would show actual item names
                                        Text("Item")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        } else {
                            Text("No items selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tags section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tags")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // Add new tag
                            HStack {
                                TextField("Add tag (e.g., favorite, comfortable)", text: $newTag)
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
                            .padding(.horizontal)
                            
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
                                .padding(.horizontal)
                            }
                            
                            // Quick tag suggestions
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(["work", "casual", "formal", "date", "party", "comfortable", "favorite", "new"], id: \.self) { tag in
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
                            .padding(.horizontal)
                        }
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
                    
                    // Save button
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Look")
                                .font(.headline)
                            Spacer()
                        }
                        .padding()
                        .background(imageData != nil && !occasion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(imageData == nil || occasion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            .navigationTitle("Add Look")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCamera) {
                EnhancedCameraBurstView(
                    captureMode: .single,
                    countdownSeconds: 5,
                    burstCount: 3,
                    totalOutfitsToCapture: 1,
                    onCancel: {
                        showingCamera = false
                    },
                    onCapturedBest: { image in
                        showingCamera = false
                        if let data = image.jpegData(compressionQuality: 0.9) {
                            imageData = data
                        }
                    },
                    onCapturedMultiple: { _ in
                        showingCamera = false
                    }
                )
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
        guard let imageData else { return }
        
        let look = OutfitLook(
            occasion: occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            timeOfDay: timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes,
            imageData: imageData,
            isFavorite: rating >= 4, // Auto-favorite if rating is 4 or 5
            itemIDs: itemIDs
        )
        
        // Store additional metadata in notes
        var metadata: [String] = []
        if !location.isEmpty { metadata.append("Location: \(location)") }
        if !weather.isEmpty { metadata.append("Weather: \(weather)") }
        if !mood.isEmpty { metadata.append("Mood: \(mood)") }
        if rating > 0 { metadata.append("Rating: \(rating)/5 stars") }
        if !tags.isEmpty { metadata.append("Tags: \(tags.joined(separator: ", "))") }
        if !itemIDs.isEmpty { metadata.append("Items: \(itemIDs.count) pieces") }
        
        if !metadata.isEmpty {
            look.notes = (look.notes.isEmpty ? "" : "\(look.notes)\n\n") + metadata.joined(separator: "\n")
        }
        
        modelContext.insert(look)
        dismiss()
    }
}

// Quick selection options
let quickOccasions = [
    "Work", "School", "Date", "Party", "Interview", "Gym", "Brunch", "Shopping", "Travel", "Meeting", "Wedding", "Casual Hangout"
]

let weatherOptions = [
    "Sunny", "Cloudy", "Rainy", "Hot", "Cold", "Windy", "Snowy"
]

let moodOptions = [
    "Confident", "Comfortable", "Professional", "Casual", "Elegant", "Fun", "Relaxed", "Bold", "Romantic", "Powerful"
]

#Preview {
    EnhancedAddLookView()
        .modelContainer(for: [ClothingItem.self, OutfitLook.self, StyleMemory.self, FashionTrend.self, StyleProfile.self], inMemory: true)
}