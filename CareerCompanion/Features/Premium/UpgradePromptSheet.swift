import SwiftUI

/// Contextual upgrade prompt shown when user hits a premium feature limit
struct UpgradePromptSheet: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: feature.icon)
                .font(.system(size: 50))
                .foregroundStyle(Color.accentColor)

            // Title
            Text(feature.rawValue)
                .font(Typography.title2)

            // Description
            Text(feature.description)
                .font(Typography.body)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Premium badge
            HStack(spacing: Spacing.xs) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                Text("Premium Feature")
            }
            .font(Typography.caption1)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(Colors.backgroundSecondary)
            .clipShape(Capsule())

            Spacer()
                .frame(height: Spacing.md)

            // Upgrade button
            Button {
                dismiss()
                // Small delay to allow sheet to dismiss before showing upgrade view
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onUpgrade()
                }
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Premium")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            // Dismiss button
            Button("Maybe Later") {
                dismiss()
            }
            .font(Typography.body)
            .foregroundStyle(Colors.textSecondary)
        }
        .padding(Spacing.xl)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Premium Locked Section

/// A placeholder section shown in place of premium-only content
struct PremiumLockedSection: View {
    let feature: PremiumFeature
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Image(systemName: feature.icon)
                    .foregroundStyle(Colors.textTertiary)
                Text(feature.rawValue)
                    .font(Typography.headline)
                Spacer()
                Image(systemName: "crown.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }

            Text(feature.description)
                .font(Typography.caption1)
                .foregroundStyle(Colors.textSecondary)

            Button {
                onUpgrade()
            } label: {
                Text("Unlock with Premium")
                    .font(Typography.caption1)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
        }
        .padding(Spacing.md)
        .background(Colors.backgroundSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                .strokeBorder(Colors.separator, lineWidth: 1)
        )
    }
}

// MARK: - Premium Badge

/// Small badge to indicate a premium feature
struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("PRO")
                .font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(.yellow)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.yellow.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Upgrade Prompt") {
    Text("Tap to show")
        .sheet(isPresented: .constant(true)) {
            UpgradePromptSheet(feature: .weeklyGoalsMetrics) {
                print("Upgrade tapped")
            }
        }
}

#Preview("Locked Section") {
    PremiumLockedSection(feature: .weeklyGoalsMetrics) {
        print("Unlock tapped")
    }
    .padding()
}

#Preview("Premium Badge") {
    PremiumBadge()
}
