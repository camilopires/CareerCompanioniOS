import SwiftUI
import SwiftData

/// Detailed view of an achievement
struct AchievementDetailView: View {
    @State private var achievement: Achievement
    @State private var sdAchievement: SDAchievement?
    @State private var isEditing = false
    @State private var linkedGoals: [CareerGoal] = []

    init(achievement: Achievement) {
        self._achievement = State(initialValue: achievement)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Header
                HeaderCard(achievement: achievement)

                // Details
                DetailsCard(achievement: $achievement, isEditing: isEditing)

                // Impact
                if !achievement.impactStatement.isEmpty || isEditing {
                    ImpactCard(achievement: $achievement, isEditing: isEditing)
                }

                // Evidence links
                if !achievement.evidenceLinks.isEmpty || isEditing {
                    EvidenceCard(links: $achievement.evidenceLinks, isEditing: isEditing)
                }

                // Linked goals
                if !linkedGoals.isEmpty {
                    LinkedGoalsSection(goals: linkedGoals)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle("Achievement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveChanges() }
                    isEditing.toggle()
                }
            }
        }
        .task {
            await loadData()
        }
    }

    private func saveChanges() {
        if AppSettings.shared.isDemoMode { return }

        if let sdAchievement = sdAchievement {
            sdAchievement.update(from: achievement)
            try? DataManager.shared.save()
        }
    }

    private func loadData() async {
        if AppSettings.shared.isDemoMode {
            linkedGoals = DemoDataProvider.careerGoals.filter { achievement.goalIDs.contains($0.id) }
            return
        }

        // Load the SDAchievement
        let achievementID = achievement.id
        let achievementPredicate = #Predicate<SDAchievement> { $0.id == achievementID }
        let achievementDescriptor = FetchDescriptor<SDAchievement>(predicate: achievementPredicate)
        sdAchievement = try? DataManager.shared.context.fetch(achievementDescriptor).first

        // Load linked goals
        guard !achievement.goalIDs.isEmpty else { return }
        do {
            let fetchedGoals = try DataManager.shared.fetchCareerGoals()
            linkedGoals = fetchedGoals
                .map { $0.toCareerGoal() }
                .filter { achievement.goalIDs.contains($0.id) }
        } catch {}
    }
}

// MARK: - Header Card

private struct HeaderCard: View {
    let achievement: Achievement

    var body: some View {
        Card(style: .elevated) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.yellow)

                Text(achievement.title)
                    .font(Typography.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(achievement.formattedDate)
                    .font(Typography.callout)
                    .foregroundStyle(Colors.textSecondary)

                // Tags
                if !achievement.tags.isEmpty {
                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(achievement.tags, id: \.self) { tag in
                            Text(tag)
                                .font(Typography.caption1)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Details Card

private struct DetailsCard: View {
    @Binding var achievement: Achievement
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Description")
                .font(Typography.headline)

            Card {
                if isEditing {
                    TextField("What did you accomplish?", text: $achievement.achievementDescription, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    Text(achievement.achievementDescription.isEmpty ? "No description" : achievement.achievementDescription)
                        .font(Typography.body)
                        .foregroundStyle(achievement.achievementDescription.isEmpty ? Colors.textTertiary : Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Impact Card

private struct ImpactCard: View {
    @Binding var achievement: Achievement
    let isEditing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Impact")
                .font(Typography.headline)

            Card {
                if isEditing {
                    TextField("Quantify the impact...", text: $achievement.impactStatement, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    Text(achievement.impactStatement)
                        .font(Typography.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - Evidence Card

private struct EvidenceCard: View {
    @Binding var links: [URL]
    let isEditing: Bool

    @State private var newLink = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Evidence")
                .font(Typography.headline)

            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(links, id: \.self) { url in
                        HStack {
                            Link(destination: url) {
                                Label(url.host ?? url.absoluteString, systemImage: "link")
                                    .lineLimit(1)
                            }

                            Spacer()

                            if isEditing {
                                Button(action: { links.removeAll { $0 == url } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Colors.textTertiary)
                                }
                            }
                        }
                    }

                    if isEditing {
                        HStack {
                            TextField("Add link...", text: $newLink)
                                .keyboardType(.URL)
                                .autocapitalization(.none)

                            if !newLink.isEmpty {
                                Button(action: addLink) {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func addLink() {
        var urlString = newLink
        if !urlString.hasPrefix("http") {
            urlString = "https://" + urlString
        }
        if let url = URL(string: urlString) {
            links.append(url)
            newLink = ""
        }
    }
}

// MARK: - Linked Goals

private struct LinkedGoalsSection: View {
    let goals: [CareerGoal]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Linked Goals")
                .font(Typography.headline)

            VStack(spacing: Spacing.sm) {
                ForEach(goals) { goal in
                    Card {
                        HStack {
                            Image(systemName: goal.category.icon)
                                .foregroundStyle(goal.category.color)

                            Text(goal.title)
                                .font(Typography.body)

                            Spacer()

                            Text("\(goal.progress)%")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview

#Preview("Achievement Detail") {
    let previewAchievement = Achievement(
        title: "Led API Migration Project",
        achievementDescription: "Successfully led the migration of our legacy API to a new microservices architecture",
        dateAchieved: Date().addingTimeInterval(-86400 * 30),
        impactStatement: "Reduced API response times by 40% and improved system reliability to 99.9% uptime",
        tags: ["Technical Leadership", "Architecture", "Performance"],
        visibility: .manager
    )
    return NavigationStack {
        AchievementDetailView(achievement: previewAchievement)
    }
}
