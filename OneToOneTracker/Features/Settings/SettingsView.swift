import SwiftUI

/// App settings view
struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("meetingReminderMinutes") private var meetingReminderMinutes = 60
    @AppStorage("weeklyPrepReminderEnabled") private var weeklyPrepReminderEnabled = true
    @AppStorage("weeklyPrepReminderDay") private var weeklyPrepReminderDay = 1 // Monday
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var userRole: UserRole = AppSettings.shared.userRole
    @State private var isDemoMode: Bool = AppSettings.shared.isDemoMode

    var body: some View {
        Form {
            // Premium section (at top)
            PremiumSettingsSection()

            // App Mode section
            Section {
                Picker("I am a", selection: $userRole) {
                    ForEach(UserRole.allCases) { role in
                        Label(role.displayName, systemImage: role.icon)
                            .tag(role)
                    }
                }
                .onChange(of: userRole) { _, newValue in
                    AppSettings.shared.userRole = newValue
                }
            } header: {
                Text("App Mode")
            } footer: {
                Text(userRole == .individualContributor
                    ? "Track your 1:1 meetings with your manager."
                    : "Track 1:1 meetings with your direct reports.")
            }

            // People section
            Section {
                NavigationLink(destination: PeopleListView()) {
                    HStack {
                        Label("People", systemImage: "person.3")
                        Spacer()
                    }
                }

                NavigationLink(destination: ManageTypesView()) {
                    Label("Manage Types", systemImage: "tag")
                }
            } header: {
                Text("People & 1:1s")
            } footer: {
                Text("Manage the people you have 1:1 meetings with and customize relationship and meeting types.")
            }

            // Notifications section
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)

                if notificationsEnabled {
                    Picker("Meeting Reminder", selection: $meetingReminderMinutes) {
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("1 day before").tag(1440)
                    }

                    Toggle("Weekly Prep Reminder", isOn: $weeklyPrepReminderEnabled)

                    if weeklyPrepReminderEnabled {
                        Picker("Reminder Day", selection: $weeklyPrepReminderDay) {
                            Text("Sunday").tag(0)
                            Text("Monday").tag(1)
                            Text("Tuesday").tag(2)
                            Text("Wednesday").tag(3)
                            Text("Thursday").tag(4)
                            Text("Friday").tag(5)
                            Text("Saturday").tag(6)
                        }
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get reminded before your 1:1 meetings and to prepare your agenda.")
            }

            // Calendar section
            CalendarSettingsSection()

            // AI Suggestions section
            AISettingsSection()

            // Data section
            Section {
                NavigationLink(destination: DataPrivacyView()) {
                    Label("Data & Privacy", systemImage: "lock.shield")
                }

                NavigationLink(destination: ExportView()) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                NavigationLink(destination: ImportView()) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            } header: {
                Text("Your Data")
            } footer: {
                Text("Your data is stored securely in your personal iCloud account and syncs across your devices.")
            }

            // About section
            Section {
                NavigationLink(destination: AboutView()) {
                    Label("About", systemImage: "info.circle")
                }

                Link(destination: URL(string: "https://apple.com/feedback")!) {
                    Label("Send Feedback", systemImage: "envelope")
                }

                Link(destination: URL(string: "https://apple.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }

            // Demo Mode section (visible to all users)
            Section {
                Toggle("Demo Mode", isOn: $isDemoMode)
                    .onChange(of: isDemoMode) { _, newValue in
                        AppSettings.shared.isDemoMode = newValue
                    }
            } header: {
                Text("Demo Mode")
            } footer: {
                Text("View the app with sample data to see how it works. Your real data is preserved and will return when you turn this off.")
            }

            // Developer section (only in debug builds)
            #if DEBUG
            Section {
                Button("Reset Onboarding") {
                    AppSettings.shared.hasCompletedOnboarding = false
                    AppSettings.shared.hasExploredDemo = false
                    hasCompletedOnboarding = false
                }
            } header: {
                Text("Developer")
            } footer: {
                Text("These options are only visible in debug builds.")
            }
            #endif
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Manager Editor

struct ManagerEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Manager Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveManager()
                        dismiss()
                    }
                }
            }
            .task {
                await loadManager()
            }
        }
    }

    private func loadManager() async {
        do {
            let managers: [Manager] = try await CloudKitManager.shared.fetch()
            if let manager = managers.first {
                name = manager.name
                email = manager.email ?? ""
            }
        } catch {}
    }

    private func saveManager() {
        Task {
            let manager = Manager(name: name, email: email.isEmpty ? nil : email)
            _ = try? await CloudKitManager.shared.save(manager)
        }
    }
}

// MARK: - Data Privacy View

struct DataPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Card(style: .elevated) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Colors.success)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Your Data is Private")
                                .font(Typography.headline)

                            Text("Stored in your personal iCloud")
                                .font(Typography.callout)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    PrivacyPoint(
                        icon: "icloud.fill",
                        title: "Personal iCloud Storage",
                        description: "All your data is stored in your personal iCloud account using CloudKit's private database."
                    )

                    PrivacyPoint(
                        icon: "lock.fill",
                        title: "End-to-End Encryption",
                        description: "Your data is encrypted and only accessible by you across your Apple devices."
                    )

                    PrivacyPoint(
                        icon: "xmark.shield.fill",
                        title: "No Third-Party Access",
                        description: "We never have access to your data. It stays between you and Apple's iCloud."
                    )

                    PrivacyPoint(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Automatic Sync",
                        description: "Your data automatically syncs across all your devices signed into the same iCloud account."
                    )

                    PrivacyPoint(
                        icon: "trash.fill",
                        title: "You Control Your Data",
                        description: "Delete the app and your data persists in iCloud. Delete from iCloud settings to remove completely."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.headline)

                Text(description)
                    .font(Typography.callout)
                    .foregroundStyle(Colors.textSecondary)
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // App icon and name
                VStack(spacing: Spacing.md) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentColor)

                    Text("Career Companion")
                        .font(Typography.title1)
                        .fontWeight(.bold)

                    Text("Version 1.0.0")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)
                }
                .padding(.top, Spacing.xl)

                // Description
                Text("Track your 1:1 meetings, career goals, and achievements. Prepare for conversations, capture action items, and generate performance reports.")
                    .font(Typography.body)
                    .foregroundStyle(Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Divider()

                // Credits
                VStack(spacing: Spacing.sm) {
                    Text("Made with ❤️")
                        .font(Typography.callout)
                        .foregroundStyle(Colors.textSecondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - People Views are in Features/People/
// PeopleListView, AddPersonView, and PersonRow are now standalone files

// MARK: - Preview

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("Data Privacy") {
    NavigationStack {
        DataPrivacyView()
    }
}

#Preview("People List") {
    NavigationStack {
        PeopleListView()
    }
}

// MARK: - Calendar Settings Section

struct CalendarSettingsSection: View {
    @StateObject private var calendarManager = CalendarManager.shared
    @State private var syncEnabled: Bool = AppSettings.shared.syncMeetingsToCalendar
    @State private var selectedCalendarID: String? = AppSettings.shared.selectedCalendarID

    var body: some View {
        Section {
            Toggle("Sync to Calendar", isOn: $syncEnabled)
                .onChange(of: syncEnabled) { _, newValue in
                    handleSyncToggle(newValue)
                }

            if syncEnabled && calendarManager.canCreateEvents {
                Picker("Calendar", selection: $selectedCalendarID) {
                    Text("Default Calendar")
                        .tag(nil as String?)

                    ForEach(calendarManager.availableCalendars, id: \.calendarIdentifier) { calendar in
                        Text(calendar.title)
                            .tag(calendar.calendarIdentifier as String?)
                    }
                }
                .onChange(of: selectedCalendarID) { _, newValue in
                    AppSettings.shared.selectedCalendarID = newValue
                }
            }

            if syncEnabled && !calendarManager.canCreateEvents {
                Button {
                    Task {
                        _ = await calendarManager.requestAccess()
                    }
                } label: {
                    Label("Grant Calendar Access", systemImage: "calendar.badge.plus")
                }
            }
        } header: {
            Text("Calendar")
        } footer: {
            if syncEnabled {
                if calendarManager.canCreateEvents {
                    Text("New meetings will be added to your selected calendar with reminders.")
                } else {
                    Text("Calendar access is required to sync meetings. Tap above to grant access.")
                }
            } else {
                Text("Automatically add your 1:1 meetings to your calendar.")
            }
        }
    }

    private func handleSyncToggle(_ enabled: Bool) {
        AppSettings.shared.syncMeetingsToCalendar = enabled

        if enabled && !calendarManager.canCreateEvents {
            Task {
                _ = await calendarManager.requestAccess()
            }
        }
    }
}

#Preview("Calendar Settings") {
    Form {
        CalendarSettingsSection()
    }
}

// MARK: - AI Settings Section

struct AISettingsSection: View {
    @StateObject private var aiManager = AIManager.shared
    @State private var isEnabled: Bool = AIManager.shared.isEnabled

    var body: some View {
        Section {
            if aiManager.isAvailable {
                Toggle("AI Suggestions", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _, newValue in
                        aiManager.isEnabled = newValue
                    }
            } else {
                HStack {
                    Label("AI Suggestions", systemImage: "sparkles")
                    Spacer()
                    Text("iOS 18+")
                        .font(Typography.caption1)
                        .foregroundStyle(Colors.textTertiary)
                }
            }
        } header: {
            HStack {
                Text("AI Features")
                if aiManager.isAvailable {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
        } footer: {
            if aiManager.isAvailable {
                Text("Get intelligent suggestions for agenda items, achievement descriptions, and meeting summaries. All processing happens on-device for privacy.")
            } else {
                Text("AI features require iOS 18 or later with Apple Intelligence support.")
            }
        }
    }
}

#Preview("AI Settings") {
    Form {
        AISettingsSection()
    }
}
