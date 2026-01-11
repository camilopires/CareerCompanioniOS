import SwiftUI

/// Bottom sheet that appears during demo mode to explain the sample data
/// and provide a way to start fresh with real data
struct DemoModeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onStartFresh: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.purple)
                .padding(.top, Spacing.lg)

            // Title
            Text("Exploring Sample Data")
                .font(Typography.title3)
                .fontWeight(.semibold)

            // Description
            Text("This is sample data to help you explore the app. Swipe down or tap below to start exploring.")
                .font(Typography.body)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            Spacer()

            // Continue Exploring button (primary)
            Button {
                dismiss()
            } label: {
                Text("Continue Exploring")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.md)

            // Exit Demo Mode button (secondary)
            Button(action: onStartFresh) {
                Text("Exit Demo Mode")
                    .font(Typography.callout)
                    .foregroundStyle(Colors.textSecondary)
            }
            .padding(.bottom, Spacing.sm)

            // Hint
            Text("You can turn demo mode on/off in Settings")
                .font(Typography.caption1)
                .foregroundStyle(Colors.textTertiary)
                .padding(.bottom, Spacing.lg)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationSizing(.fitted)
    }
}

// MARK: - Preview

#Preview("Demo Mode Sheet") {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            DemoModeSheet {
                print("Start Fresh tapped")
            }
        }
}
