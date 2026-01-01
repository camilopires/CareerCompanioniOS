import SwiftUI

/// Full-screen upgrade view showing premium benefits and purchase option
struct UpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Hero section
                    heroSection

                    // Features grid
                    featuresSection

                    // Pricing
                    pricingSection

                    // Purchase button
                    purchaseButton

                    // Restore link
                    restoreLink

                    // Terms
                    termsSection
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, Spacing.xxl)
            }
            .background(Colors.backgroundGrouped)
            .navigationTitle("OneToOne Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow.gradient)

            Text("Unlock Everything")
                .font(Typography.title1)

            Text("One purchase. Lifetime access. No subscriptions.")
                .font(Typography.body)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.xl)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            ForEach(PremiumFeature.allCases) { feature in
                FeatureCell(feature: feature)
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(subscriptionManager.formattedPrice)
                .font(.system(size: 48, weight: .bold))

            Text("One-time purchase")
                .font(Typography.caption1)
                .foregroundStyle(Colors.textSecondary)

            if subscriptionManager.isTrialActive {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock.fill")
                    Text("\(subscriptionManager.trialDaysRemaining) days left in trial")
                }
                .font(Typography.caption1)
                .foregroundStyle(.orange)
                .padding(.top, Spacing.xs)
            }
        }
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await purchase() }
        } label: {
            HStack(spacing: Spacing.sm) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "crown.fill")
                    Text("Purchase Premium")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isPurchasing || subscriptionManager.isPremium)
    }

    // MARK: - Restore Link

    private var restoreLink: some View {
        Button("Restore Purchase") {
            Task { await restore() }
        }
        .font(Typography.body)
        .disabled(isPurchasing)
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        Text("Payment will be charged to your Apple ID account. Your purchase is protected by Apple's App Store policies.")
            .font(Typography.caption2)
            .foregroundStyle(Colors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.top, Spacing.md)
    }

    // MARK: - Actions

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionManager.purchasePremium()
            if subscriptionManager.isPremium {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.isPremium {
                dismiss()
            } else {
                errorMessage = "No previous purchase found."
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Feature Cell

private struct FeatureCell: View {
    let feature: PremiumFeature

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: feature.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            Text(feature.rawValue)
                .font(Typography.caption1)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
    }
}

// MARK: - Preview

#Preview {
    UpgradeView()
}
