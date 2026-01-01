import SwiftUI

/// Reusable card component with consistent styling
struct Card<Content: View>: View {
    let content: Content
    var style: CardStyle

    init(
        style: CardStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(style.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .shadow(
                color: style.shadowColor,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowY
            )
    }
}

// MARK: - Card Styles

enum CardStyle {
    case standard
    case elevated
    case outlined
    case flat

    var padding: CGFloat {
        Spacing.cardPadding
    }

    var cornerRadius: CGFloat {
        switch self {
        case .standard, .flat: return Spacing.cornerRadiusMedium
        case .elevated: return Spacing.cornerRadiusLarge
        case .outlined: return Spacing.cornerRadiusMedium
        }
    }

    var backgroundColor: Color {
        switch self {
        case .standard: return Colors.backgroundSecondary
        case .elevated: return Colors.background
        case .outlined: return .clear
        case .flat: return Colors.backgroundSecondary
        }
    }

    var shadowColor: Color {
        switch self {
        case .standard: return .black.opacity(0.06)
        case .elevated: return .black.opacity(0.1)
        case .outlined, .flat: return .clear
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .standard: return Spacing.shadowRadius
        case .elevated: return 12
        case .outlined, .flat: return 0
        }
    }

    var shadowY: CGFloat {
        switch self {
        case .standard: return Spacing.shadowY
        case .elevated: return 6
        case .outlined, .flat: return 0
        }
    }
}

// MARK: - Tappable Card

/// Card that responds to taps with visual feedback
struct TappableCard<Content: View>: View {
    let action: () -> Void
    let content: Content
    var style: CardStyle

    @State private var isPressed = false

    init(
        style: CardStyle = .standard,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: {
            Theme.lightHaptic()
            action()
        }) {
            Card(style: style) {
                content
            }
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.springAnimation, value: configuration.isPressed)
    }
}

// MARK: - Outlined Card

/// Card with a border instead of shadow
struct OutlinedCard<Content: View>: View {
    let content: Content
    var borderColor: Color

    init(
        borderColor: Color = Colors.separator,
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Colors.background)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview("Card Styles") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Standard Card")
                        .font(Typography.headline)
                    Text("Default card style with subtle shadow")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            Card(style: .elevated) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Elevated Card")
                        .font(Typography.headline)
                    Text("More prominent with larger shadow")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            OutlinedCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Outlined Card")
                        .font(Typography.headline)
                    Text("Border instead of shadow")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            Card(style: .flat) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Flat Card")
                        .font(Typography.headline)
                    Text("No shadow, just background")
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                }
            }

            TappableCard(action: { print("Tapped!") }) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Tappable Card")
                            .font(Typography.headline)
                        Text("Tap me for haptic feedback")
                            .font(Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
