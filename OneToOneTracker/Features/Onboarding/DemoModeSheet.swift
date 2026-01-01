import SwiftUI

/// Bottom sheet that appears during demo mode to explain the sample data
/// and provide a way to start fresh with real data
struct DemoModeSheet: View {
    let onStartFresh: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.purple)
                .padding(.top, Spacing.md)

            // Title
            Text("Exploring Sample Data")
                .font(Typography.title3)
                .fontWeight(.semibold)

            // Description
            Text("Take a look around! This is sample data to show you how the app works. Tap around to explore meetings, action items, and career goals.")
                .font(Typography.body)
                .foregroundStyle(Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            // Start Fresh button
            Button(action: onStartFresh) {
                Text("Start Fresh")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            // Hint
            Text("You can re-enable demo mode anytime in Settings")
                .font(Typography.caption1)
                .foregroundStyle(Colors.textTertiary)
                .padding(.bottom, Spacing.md)
        }
        .padding()
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
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
