import SwiftUI

/// View for managing custom relationship types and meeting types
struct ManageTypesView: View {
    @State private var showingAddRelationshipType = false
    @State private var showingAddMeetingType = false
    @State private var newTypeName = ""
    @State private var selectedMeetingTypeForColor: String?
    @State private var refreshID = UUID()

    var body: some View {
        List {
            // MARK: - Relationship Types Section
            Section {
                ForEach(AppSettings.shared.allRelationshipTypes, id: \.self) { type in
                    HStack {
                        // Icon based on type
                        Image(systemName: iconForRelationshipType(type))
                            .foregroundColor(colorForRelationshipType(type))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(type)
                                .font(.body)

                            if isSpecialRelationshipType(type) {
                                Text("Drives app mode")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if isDefaultRelationshipType(type) {
                            Text("Default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !isDefaultRelationshipType(type) {
                            Button(role: .destructive) {
                                AppSettings.shared.removeCustomRelationshipType(type)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                Button {
                    newTypeName = ""
                    showingAddRelationshipType = true
                } label: {
                    Label("Add Relationship Type", systemImage: "plus.circle")
                }
            } header: {
                Text("Relationship Types")
            } footer: {
                Text("\"My Manager\" and \"Direct Report\" are special types that determine which dashboard section people appear in.")
            }

            // MARK: - Meeting Types Section
            Section {
                ForEach(AppSettings.shared.allMeetingTypes, id: \.self) { type in
                    Button {
                        selectedMeetingTypeForColor = type
                    } label: {
                        HStack {
                            // Color indicator
                            Circle()
                                .fill(AppSettings.shared.colorForMeetingType(type))
                                .frame(width: 12, height: 12)

                            Image(systemName: iconForMeetingType(type))
                                .foregroundColor(AppSettings.shared.colorForMeetingType(type))
                                .frame(width: 24)

                            Text(type)
                                .font(.body)
                                .foregroundStyle(Colors.textPrimary)

                            Spacer()

                            if isDefaultMeetingType(type) {
                                Text("Default")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.15))
                                    .cornerRadius(4)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Colors.textTertiary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !isDefaultMeetingType(type) {
                            Button(role: .destructive) {
                                AppSettings.shared.removeCustomMeetingType(type)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }

                Button {
                    newTypeName = ""
                    showingAddMeetingType = true
                } label: {
                    Label("Add Meeting Type", systemImage: "plus.circle")
                }
            } header: {
                Text("Meeting Types")
            } footer: {
                Text("Tap a meeting type to change its color.")
            }
        }
        .id(refreshID)
        .navigationTitle("Manage Types")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add Relationship Type", isPresented: $showingAddRelationshipType) {
            TextField("Type name", text: $newTypeName)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                AppSettings.shared.addCustomRelationshipType(newTypeName)
            }
        } message: {
            Text("Enter a name for the new relationship type.")
        }
        .alert("Add Meeting Type", isPresented: $showingAddMeetingType) {
            TextField("Type name", text: $newTypeName)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                AppSettings.shared.addCustomMeetingType(newTypeName)
            }
        } message: {
            Text("Enter a name for the new meeting type.")
        }
        .sheet(item: $selectedMeetingTypeForColor) { type in
            MeetingTypeColorPicker(meetingType: type) {
                refreshID = UUID()
            }
        }
    }

    // MARK: - Helper Functions

    private func isDefaultRelationshipType(_ type: String) -> Bool {
        AppSettings.defaultRelationshipTypes.contains(type)
    }

    private func isDefaultMeetingType(_ type: String) -> Bool {
        AppSettings.defaultMeetingTypes.contains(type)
    }

    private func isSpecialRelationshipType(_ type: String) -> Bool {
        type == "My Manager" || type == "Direct Report"
    }

    private func iconForRelationshipType(_ type: String) -> String {
        switch type {
        case "My Manager": return "person.badge.shield.checkmark.fill"
        case "Direct Report": return "person.fill"
        case "Mentor": return "graduationcap.fill"
        case "Peer": return "person.2.fill"
        case "Stakeholder": return "star.fill"
        case "Skip-Level Manager": return "arrow.up.forward.circle.fill"
        case "Cross-Team Partner": return "arrow.triangle.branch"
        case "External Coach": return "person.crop.circle.badge.checkmark"
        default: return "person.circle"
        }
    }

    private func colorForRelationshipType(_ type: String) -> Color {
        switch type {
        case "My Manager": return .blue
        case "Direct Report": return .green
        case "Mentor": return .purple
        case "Peer": return .orange
        case "Stakeholder": return .yellow
        case "Skip-Level Manager": return .teal
        case "Cross-Team Partner": return .indigo
        case "External Coach": return .mint
        default: return .gray
        }
    }

    private func iconForMeetingType(_ type: String) -> String {
        switch type {
        case "1:1": return "person.2"
        case "Career Development": return "chart.line.uptrend.xyaxis"
        case "Project Sync": return "doc.text.magnifyingglass"
        case "Feedback Session": return "text.bubble"
        case "Mentorship": return "graduationcap"
        case "Coffee Chat": return "cup.and.saucer.fill"
        default: return "calendar"
        }
    }
}

// MARK: - String Identifiable Extension

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Meeting Type Color Picker

struct MeetingTypeColorPicker: View {
    let meetingType: String
    let onColorChanged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedHex: String

    init(meetingType: String, onColorChanged: @escaping () -> Void) {
        self.meetingType = meetingType
        self.onColorChanged = onColorChanged
        self._selectedHex = State(initialValue: AppSettings.shared.hexColorForMeetingType(meetingType))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Preview of the meeting type badge
                    HStack {
                        Spacer()
                        Text(meetingType)
                            .font(Typography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: selectedHex))
                            .cornerRadius(6)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, Spacing.md)
                } header: {
                    Text("Preview")
                }

                Section {
                    ForEach(AppSettings.availableMeetingColors, id: \.hex) { color in
                        Button {
                            selectedHex = color.hex
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 24, height: 24)

                                Text(color.name)
                                    .foregroundStyle(Colors.textPrimary)

                                Spacer()

                                if selectedHex == color.hex {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Colors")
                }
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        AppSettings.shared.setColorForMeetingType(meetingType, hex: selectedHex)
                        onColorChanged()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        ManageTypesView()
    }
}

#Preview("Color Picker") {
    MeetingTypeColorPicker(meetingType: "1:1") {}
}
