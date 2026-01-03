import SwiftUI

/// Sheet showing before/after comparison for AI improvements
struct ImprovementPreviewSheet: View {
    let preview: NoteImprovementPreview
    let onApply: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header
                    headerSection

                    // Original content
                    contentSection(
                        title: "Original",
                        content: preview.originalContent,
                        color: Colors.textSecondary
                    )

                    // Divider with arrow
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                    }

                    // Improved content
                    contentSection(
                        title: "Improved",
                        content: preview.improvedContent,
                        color: Colors.success
                    )

                    // No changes message
                    if !preview.hasChanges {
                        noChangesMessage
                    }

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.screenPadding)
            }
            .background(Colors.backgroundGrouped)
            .navigationTitle("Preview Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .disabled(!preview.hasChanges)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var headerSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: preview.sectionType.icon)
                .foregroundStyle(preview.sectionType.iconColor)

            Text(preview.sectionType.displayName)
                .font(Typography.headline)

            Spacer()

            HStack(spacing: Spacing.xxs) {
                Image(systemName: preview.improvementType.icon)
                Text(preview.improvementType.displayName)
            }
            .font(Typography.caption1)
            .foregroundStyle(Colors.textSecondary)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(Colors.backgroundSecondary)
            .clipShape(Capsule())
        }
        .padding(.top, Spacing.md)
    }

    private func contentSection(title: String, content: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title)
                .font(Typography.caption1)
                .foregroundStyle(Colors.textSecondary)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                ForEach(content, id: \.self) { item in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(item)
                            .font(Typography.body)
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        }
    }

    private var noChangesMessage: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Colors.success)
            Text("Content is already optimized!")
                .font(Typography.callout)
                .foregroundStyle(Colors.textSecondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Colors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }
}

/// Sheet for batch improvement preview
struct BatchImprovementPreviewSheet: View {
    let preview: BatchImprovementPreview
    let onApply: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Summary section
                Section {
                    HStack {
                        Image(systemName: preview.improvementType.icon)
                            .foregroundStyle(Color.accentColor)
                        Text(preview.improvementType.displayName)
                        Spacer()
                        Text("\(preview.sectionsWithChanges) sections improved")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                } header: {
                    Text("Improvement Type")
                }

                // Changed sections
                ForEach(preview.improvements.filter { $0.hasChanges }) { improvement in
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Before:")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)

                            ForEach(improvement.originalContent, id: \.self) { item in
                                Text(item)
                                    .font(Typography.body)
                                    .foregroundStyle(Colors.textSecondary)
                            }

                            Divider()

                            Text("After:")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.success)

                            ForEach(improvement.improvedContent, id: \.self) { item in
                                Text(item)
                                    .font(Typography.body)
                            }
                        }
                    } header: {
                        Label(improvement.sectionType.displayName, systemImage: improvement.sectionType.icon)
                    }
                }

                // No changes message
                if !preview.hasChanges {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Colors.success)
                            Text("All content is already optimized!")
                                .font(Typography.callout)
                        }
                    }
                }
            }
            .navigationTitle("Preview All Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply All") {
                        onApply()
                        dismiss()
                    }
                    .disabled(!preview.hasChanges)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Improvement") {
    ImprovementPreviewSheet(
        preview: NoteImprovementPreview(
            sectionType: .wentWell,
            improvementType: .professionalTone,
            originalContent: ["finished the project", "got good feedback from team"],
            improvedContent: ["Finished the project.", "Got excellent feedback from team."]
        ),
        onApply: {},
        onCancel: {}
    )
}

#Preview("Batch Improvement") {
    BatchImprovementPreviewSheet(
        preview: BatchImprovementPreview(
            improvements: [
                NoteImprovementPreview(
                    sectionType: .wentWell,
                    improvementType: .professionalTone,
                    originalContent: ["finished project"],
                    improvedContent: ["Finished project."]
                ),
                NoteImprovementPreview(
                    sectionType: .blockers,
                    improvementType: .professionalTone,
                    originalContent: ["waiting on api"],
                    improvedContent: ["Waiting on API."]
                )
            ],
            improvementType: .professionalTone
        ),
        onApply: {},
        onCancel: {}
    )
}
