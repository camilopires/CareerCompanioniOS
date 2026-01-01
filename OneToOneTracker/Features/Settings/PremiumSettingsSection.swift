import SwiftUI

/// Settings section showing premium status and upgrade options
struct PremiumSettingsSection: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingUpgrade = false

    var body: some View {
        Section {
            if subscriptionManager.isPremium {
                premiumActiveRow
            } else if subscriptionManager.isTrialActive {
                trialActiveRow
            } else {
                freeUserRow
            }
        } header: {
            Label("OneToOne Premium", systemImage: "crown.fill")
        }
        .sheet(isPresented: $showingUpgrade) {
            UpgradeView()
        }
    }

    // MARK: - Premium Active

    private var premiumActiveRow: some View {
        HStack {
            Label {
                Text("Premium Active")
            } icon: {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Colors.success)
        }
    }

    // MARK: - Trial Active

    private var trialActiveRow: some View {
        Button {
            showingUpgrade = true
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trial Active")
                        Text("All premium features unlocked")
                            .font(Typography.caption2)
                            .foregroundStyle(Colors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(subscriptionManager.trialDaysRemaining) days left")
                        .font(Typography.caption1)
                        .foregroundStyle(.orange)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Colors.textTertiary)
            }
        }
        .foregroundStyle(Colors.textPrimary)
    }

    // MARK: - Free User

    private var freeUserRow: some View {
        Button {
            showingUpgrade = true
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upgrade to Premium")
                        Text("Unlock all features")
                            .font(Typography.caption2)
                            .foregroundStyle(Colors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "crown")
                        .foregroundStyle(Color.accentColor)
                }

                Spacer()

                Text(subscriptionManager.formattedPrice)
                    .font(Typography.caption1)
                    .foregroundStyle(Colors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Colors.textTertiary)
            }
        }
        .foregroundStyle(Colors.textPrimary)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Form {
            PremiumSettingsSection()
        }
        .navigationTitle("Settings")
    }
}
