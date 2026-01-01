import SwiftUI

/// View for building and exporting performance reports
struct ReportBuilderView: View {
    @Environment(\.dismiss) private var dismiss

    let goals: [CareerGoal]
    let achievements: [Achievement]

    @State private var dateRange: DateRange = .year
    @State private var customStartDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    @State private var customEndDate = Date()
    @State private var selectedGoalIDs: Set<UUID> = []
    @State private var selectedAchievementIDs: Set<UUID> = []
    @State private var personalSummary = ""
    @State private var includeSentiment = false
    @State private var showingPreview = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Time Period", selection: $dateRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }

                    if dateRange == .custom {
                        DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Report Period")
                }

                Section {
                    ForEach(goals) { goal in
                        Toggle(isOn: binding(for: goal.id, in: $selectedGoalIDs)) {
                            HStack {
                                Image(systemName: goal.category.icon)
                                    .foregroundStyle(goal.category.color)
                                Text(goal.title)
                                    .lineLimit(1)
                            }
                        }
                    }

                    if goals.isEmpty {
                        Text("No goals to include")
                            .foregroundStyle(Colors.textTertiary)
                    }
                } header: {
                    Text("Goals to Include")
                }

                Section {
                    ForEach(filteredAchievements) { achievement in
                        Toggle(isOn: binding(for: achievement.id, in: $selectedAchievementIDs)) {
                            VStack(alignment: .leading) {
                                Text(achievement.title)
                                    .lineLimit(1)
                                Text(achievement.formattedDate)
                                    .font(Typography.caption1)
                                    .foregroundStyle(Colors.textSecondary)
                            }
                        }
                    }

                    if filteredAchievements.isEmpty {
                        Text("No achievements in this period")
                            .foregroundStyle(Colors.textTertiary)
                    }
                } header: {
                    Text("Achievements to Highlight")
                }

                Section {
                    TextEditor(text: $personalSummary)
                        .frame(minHeight: 100)
                } header: {
                    Text("Personal Summary")
                } footer: {
                    Text("Add a narrative summary of your performance during this period.")
                }

                Section {
                    Toggle("Include Sentiment Trends", isOn: $includeSentiment)
                }

                Section {
                    Button(action: { showingPreview = true }) {
                        Label("Preview Report", systemImage: "doc.text.magnifyingglass")
                    }
                }
            }
            .navigationTitle("Performance Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPreview) {
                ReportPreviewView(
                    dateRange: effectiveDateRange,
                    goals: selectedGoals,
                    achievements: selectedAchievements,
                    personalSummary: personalSummary,
                    includeSentiment: includeSentiment
                )
            }
            .onAppear {
                // Select all by default
                selectedGoalIDs = Set(goals.map(\.id))
                selectedAchievementIDs = Set(achievements.map(\.id))
            }
        }
    }

    private var effectiveDateRange: (start: Date, end: Date) {
        switch dateRange {
        case .quarter:
            return (Calendar.current.date(byAdding: .month, value: -3, to: Date())!, Date())
        case .halfYear:
            return (Calendar.current.date(byAdding: .month, value: -6, to: Date())!, Date())
        case .year:
            return (Calendar.current.date(byAdding: .year, value: -1, to: Date())!, Date())
        case .custom:
            return (customStartDate, customEndDate)
        }
    }

    private var filteredAchievements: [Achievement] {
        let range = effectiveDateRange
        return achievements.filter { $0.dateAchieved >= range.start && $0.dateAchieved <= range.end }
    }

    private var selectedGoals: [CareerGoal] {
        goals.filter { selectedGoalIDs.contains($0.id) }
    }

    private var selectedAchievements: [Achievement] {
        achievements.filter { selectedAchievementIDs.contains($0.id) }
    }

    private func binding(for id: UUID, in set: Binding<Set<UUID>>) -> Binding<Bool> {
        Binding(
            get: { set.wrappedValue.contains(id) },
            set: { isSelected in
                if isSelected {
                    set.wrappedValue.insert(id)
                } else {
                    set.wrappedValue.remove(id)
                }
            }
        )
    }
}

// MARK: - Date Range

enum DateRange: String, CaseIterable, Identifiable {
    case quarter
    case halfYear
    case year
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quarter: return "Last Quarter"
        case .halfYear: return "Last 6 Months"
        case .year: return "Last Year"
        case .custom: return "Custom Range"
        }
    }
}

// MARK: - Report Preview

struct ReportPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let dateRange: (start: Date, end: Date)
    let goals: [CareerGoal]
    let achievements: [Achievement]
    let personalSummary: String
    let includeSentiment: Bool

    @State private var showingShareSheet = false

    private var reportText: String {
        generateReport()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(reportText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .navigationTitle("Report Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: copyToClipboard) {
                        Image(systemName: "doc.on.doc")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [reportText])
            }
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = reportText
        Theme.successHaptic()
    }

    private func generateReport() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        var report = """
        # Performance Report
        Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))

        """

        if !personalSummary.isEmpty {
            report += """

            ## Summary
            \(personalSummary)

            """
        }

        if !goals.isEmpty {
            report += """

            ## Goals Progress

            """

            for goal in goals {
                report += """
                ### \(goal.title)
                - Category: \(goal.category.displayName)
                - Status: \(goal.status.displayName)
                - Progress: \(goal.progress)%
                \(goal.goalDescription.isEmpty ? "" : "- Description: \(goal.goalDescription)")
                \(goal.successMetrics.isEmpty ? "" : "- Success Metrics: \(goal.successMetrics)")

                """
            }
        }

        if !achievements.isEmpty {
            report += """

            ## Key Achievements

            """

            for achievement in achievements.sorted(by: { $0.dateAchieved > $1.dateAchieved }) {
                report += """
                ### \(achievement.title)
                - Date: \(achievement.formattedDate)
                \(achievement.impactStatement.isEmpty ? "" : "- Impact: \(achievement.impactStatement)")
                \(achievement.achievementDescription.isEmpty ? "" : "- Details: \(achievement.achievementDescription)")

                """
            }
        }

        let achievedCount = goals.filter { $0.isAchieved }.count
        report += """

        ## Summary Statistics
        - Total Goals: \(goals.count)
        - Goals Achieved: \(achievedCount)
        - Achievements Recorded: \(achievements.count)

        ---
        Generated on \(dateFormatter.string(from: Date()))
        """

        return report
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Report Builder") {
    ReportBuilderView(goals: CareerGoal.samples, achievements: Achievement.samples)
}
