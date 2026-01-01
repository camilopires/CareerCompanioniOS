import SwiftUI

/// Onboarding flow for new users
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var cloudKitManager: CloudKitManager

    @State private var currentPage = 0
    @State private var managerName = ""
    @State private var showingSetup = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "person.2.circle.fill",
            title: "Welcome to OneToOne Tracker",
            description: "Prepare for your 1:1 meetings, capture action items, and track your career growth.",
            color: .accentColor
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Your Data, Your Privacy",
            description: "All your data is stored securely in your personal iCloud account. It's never shared with anyone - not even us.",
            color: Colors.success
        ),
        OnboardingPage(
            icon: "star.circle.fill",
            title: "Track Your Growth",
            description: "Set career goals, record achievements, and generate performance reports for reviews.",
            color: .purple
        ),
        OnboardingPage(
            icon: "checklist",
            title: "Never Forget an Action Item",
            description: "Capture action items during meetings and track them to completion with widgets and reminders.",
            color: .orange
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator
            HStack(spacing: Spacing.sm) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Colors.textTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.spring(), value: currentPage)
                }
            }
            .padding()

            // Actions
            VStack(spacing: Spacing.md) {
                if currentPage == pages.count - 1 {
                    Button(action: { showingSetup = true }) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button(action: { currentPage += 1 }) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button(action: { showingSetup = true }) {
                        Text("Skip")
                    }
                    .buttonStyle(TertiaryButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .sheet(isPresented: $showingSetup) {
            SetupView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                managerName: $managerName
            )
        }
    }
}

// MARK: - Onboarding Page

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(page.color)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.md) {
                Text(page.title)
                    .font(Typography.title1)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(Typography.body)
                    .foregroundStyle(Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Setup View

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hasCompletedOnboarding: Bool
    @Binding var managerName: String

    @State private var notificationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Manager's Name", text: $managerName)
                        .textContentType(.name)
                } header: {
                    Text("Your Manager")
                } footer: {
                    Text("Who do you have 1:1 meetings with?")
                }

                Section {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Get reminders before meetings and for action items.")
                }

                Section {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title)
                            .foregroundStyle(Colors.success)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Private & Secure")
                                .font(Typography.headline)

                            Text("Your data is stored in your personal iCloud account and never shared.")
                                .font(Typography.caption1)
                                .foregroundStyle(Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .navigationTitle("Quick Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        completeSetup()
                    }
                }
            }
        }
    }

    private func completeSetup() {
        // Save manager if provided
        if !managerName.trimmingCharacters(in: .whitespaces).isEmpty {
            Task {
                let manager = Manager(name: managerName.trimmingCharacters(in: .whitespaces))
                _ = try? await CloudKitManager.shared.save(manager)
            }
        }

        // Request notification permissions if enabled
        if notificationsEnabled {
            Task {
                await requestNotificationPermissions()
            }
        }

        // Complete onboarding
        hasCompletedOnboarding = true
        dismiss()
    }

    private func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()
        do {
            _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {}
    }
}

// MARK: - Preview

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(CloudKitManager.shared)
}

#Preview("Setup") {
    SetupView(
        hasCompletedOnboarding: .constant(false),
        managerName: .constant("")
    )
}
