import SwiftUI

/// Reusable row view for displaying a person (manager, report, etc.)
struct PersonRow: View {
    let person: Manager
    var showRelationshipType: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(person.name)
                        .font(Typography.body)

                    if showRelationshipType {
                        Text(person.relationshipType)
                            .font(Typography.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.8))
                            .cornerRadius(4)
                    }
                }

                if let email = person.email {
                    Text(email)
                        .font(Typography.caption1)
                        .foregroundStyle(Colors.textSecondary)
                }

                if !person.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(person.tags, id: \.self) { tag in
                            Text(tag)
                                .font(Typography.caption2)
                                .foregroundStyle(Colors.textSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Colors.textTertiary.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        var parts = [person.name]
        if showRelationshipType {
            parts.append(person.relationshipType)
        }
        if let email = person.email {
            parts.append(email)
        }
        if !person.tags.isEmpty {
            parts.append("Tags: \(person.tags.joined(separator: ", "))")
        }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    List {
        PersonRow(person: Manager(name: "Sarah Chen", email: "sarah@example.com", relationshipType: "My Manager"))
        PersonRow(person: Manager(name: "Alex Kim", relationshipType: "Direct Report"), showRelationshipType: true)
        PersonRow(person: Manager(name: "Dr. Smith", relationshipType: "Mentor", tags: ["Career", "Technical"]), showRelationshipType: true)
    }
}
