import SwiftUI

/// Central theme configuration for the app
/// Provides consistent styling across all views
enum Theme {

    // MARK: - Animation

    /// Standard animation duration
    static let animationDuration: Double = 0.25

    /// Spring animation for interactive elements
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Ease out animation for transitions
    static let easeOutAnimation = Animation.easeOut(duration: animationDuration)

    /// Reduce motion safe animation
    static func animation(_ animation: Animation = .default) -> Animation? {
        UIAccessibility.isReduceMotionEnabled ? nil : animation
    }

    // MARK: - Shadows

    /// Card shadow style
    static func cardShadow() -> some View {
        Color.black.opacity(0.08)
    }

    /// Elevated shadow style
    static let elevatedShadow = ShadowStyle.drop(
        color: .black.opacity(0.15),
        radius: 10,
        x: 0,
        y: 4
    )

    // MARK: - Blur

    /// Standard blur radius
    static let blurRadius: CGFloat = 20

    // MARK: - Haptics

    /// Light impact haptic
    static func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact haptic
    static func mediumHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Success haptic
    static func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Error haptic
    static func errorHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection haptic
    static func selectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Modifiers

extension View {
    /// Apply card styling with shadow
    func cardStyle() -> some View {
        self
            .background(Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .shadow(
                color: .black.opacity(0.06),
                radius: Spacing.shadowRadius,
                x: 0,
                y: Spacing.shadowY
            )
    }

    /// Apply elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .background(Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge))
            .shadow(
                color: .black.opacity(0.1),
                radius: 12,
                x: 0,
                y: 6
            )
    }

    /// Apply standard animation with reduce motion support
    func standardAnimation() -> some View {
        self.animation(Theme.springAnimation, value: UUID())
    }

    /// Conditionally apply animation based on reduce motion setting
    func accessibleAnimation<V: Equatable>(_ animation: Animation? = .default, value: V) -> some View {
        self.animation(UIAccessibility.isReduceMotionEnabled ? nil : animation, value: value)
    }
}

// MARK: - Button Styles

/// Primary button style - filled with primary color
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .fill(isEnabled ? Color.accentColor : Colors.disabled)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(UIAccessibility.isReduceMotionEnabled ? 1.0 : (configuration.isPressed ? 0.98 : 1.0))
            .accessibleAnimation(Theme.springAnimation, value: configuration.isPressed)
    }
}

/// Secondary button style - outlined
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(isEnabled ? Color.accentColor : Colors.disabled)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .strokeBorder(isEnabled ? Color.accentColor : Colors.disabled, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .accessibleAnimation(Theme.springAnimation, value: configuration.isPressed)
    }
}

/// Tertiary button style - text only
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.body)
            .foregroundStyle(Color.accentColor)
            .frame(minHeight: Spacing.touchTarget)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

/// Destructive button style
struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: Spacing.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .fill(Colors.error)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Text Field Styles

/// Standard text field style
struct StandardTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Typography.body)
            .padding(Spacing.md)
            .background(Colors.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall))
    }
}

// MARK: - Preview

#Preview("Theme Components") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Text("Button Styles")
                .font(.headline)

            Button("Primary Button") { }
                .buttonStyle(PrimaryButtonStyle())

            Button("Secondary Button") { }
                .buttonStyle(SecondaryButtonStyle())

            Button("Tertiary Button") { }
                .buttonStyle(TertiaryButtonStyle())

            Button("Destructive Button") { }
                .buttonStyle(DestructiveButtonStyle())

            Button("Disabled Button") { }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(true)

            Divider()

            Text("Card Styles")
                .font(.headline)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Standard Card")
                    .font(.headline)
                Text("Some content inside the card")
                    .foregroundStyle(.secondary)
            }
            .cardPadding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Elevated Card")
                    .font(.headline)
                Text("More prominent card style")
                    .foregroundStyle(.secondary)
            }
            .cardPadding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCardStyle()
        }
        .padding()
    }
}
