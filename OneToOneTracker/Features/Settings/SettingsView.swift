import SwiftUI

/// App settings view
struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("meetingReminderMinutes") private var meetingReminderMinutes = 60
    @AppStorage("weeklyPrepReminderEnabled") private var weeklyPrepReminderEnabled = true
    @AppStorage("weeklyPrepReminderDay") private var weeklyPrepReminderDay = 1 // Monday
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showingManagerEditor = false
    @State private var showingAbout = false
    @State private var showingPrivacy = false

    var body: some View {
        Form {
            // Manager section
            Section {
                Button(action: { showingManagerEditor = true }) {
                    HStack {
                        Label("Manager Details", systemImage: "person.circle")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Colors.textTertiary)
                    }
                }
            } header: {
                Text("Your Manager")
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

            // Data section
            Section {
                NavigationLink(destination: DataPrivacyView()) {
                    Label("Data & Privacy", systemImage: "lock.shield")
                }

                Button(action: exportAllData) {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
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

            // Debug section (only in debug builds)
            #if DEBUG
            Section {
                Button("Reset Onboarding") {
                    hasCompletedOnboarding = false
                }

                Button("Load Sample Data") {
                    // Load sample data for testing
                }
            } header: {
                Text("Debug")
            }
            #endif
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingManagerEditor) {
            ManagerEditorView()
        }
    }

    private func exportAllData() {
        // TODO: Implement data export
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

                    Text("OneToOne Tracker")
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
