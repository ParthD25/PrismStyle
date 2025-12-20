import SwiftUI
import SwiftData

struct ModernLookDetailView: View {
    let look: OutfitLook
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isEditing = false
    @State private var editedNotes: String
    @State private var editedOccasion: String
    
    init(look: OutfitLook) {
        self.look = look
        self._editedNotes = State(initialValue: look.notes)
        self._editedOccasion = State(initialValue: look.occasion)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Image
                    if let ui = UIImage(data: look.imageData) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                            .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    // Details Card
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        if isEditing {
                            // Edit Mode
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                Text("Occasion")
                                    .font(DesignSystem.Typography.labelMedium)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                TextField("Occasion", text: $editedOccasion)
                                    .textFieldStyle(.roundedBorder)
                                
                                Text("Notes")
                                    .font(DesignSystem.Typography.labelMedium)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                
                                TextField("Add notes...", text: $editedNotes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...6)
                            }
                        } else {
                            // View Mode
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                // Occasion
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Occasion")
                                        .font(DesignSystem.Typography.labelMedium)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    Text(look.occasion)
                                        .font(DesignSystem.Typography.titleMedium)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                                
                                // Time & Date
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    if !look.timeOfDay.isEmpty {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 14))
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                            
                                            Text(look.timeOfDay)
                                                .font(DesignSystem.Typography.bodyMedium)
                                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                        }
                                    }
                                    
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        
                                        Text(look.createdAt, style: .date)
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                }
                                
                                // Notes
                                if !look.notes.isEmpty {
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        Text("Notes")
                                            .font(DesignSystem.Typography.labelMedium)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                        
                                        Text(look.notes)
                                            .font(DesignSystem.Typography.bodyMedium)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
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
                    
                    // Actions
                    if !isEditing {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Button {
                                // TODO: Recreate look with AI suggestions
                            } label: {
                                Label("Get AI Recommendations", systemImage: "wand.and.stars")
                                    .frame(maxWidth: .infinity)
                            }
                            .modernButtonStyle(variant: .primary, size: .medium)
                            
                            Button {
                                // TODO: Share look
                            } label: {
                                Label("Share Look", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .modernButtonStyle(variant: .secondary, size: .medium)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Look Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            editedNotes = look.notes
                            editedOccasion = look.occasion
                            isEditing = false
                        }
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        look.notes = editedNotes
        look.occasion = editedOccasion
    }
}