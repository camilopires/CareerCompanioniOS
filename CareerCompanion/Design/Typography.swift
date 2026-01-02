import SwiftUI

/// Typography system using San Francisco with full Dynamic Type support
/// All text styles scale appropriately for accessibility
enum Typography {

    // MARK: - Display Styles

    /// Largest title - for main screen headers
    static let largeTitle = Font.largeTitle

    /// Title 1 - major section headers
    static let title1 = Font.title

    /// Title 2 - subsection headers
    static let title2 = Font.title2

    /// Title 3 - minor section headers
    static let title3 = Font.title3

    // MARK: - Content Styles

    /// Headline - card titles, emphasized content
    static let headline = Font.headline

    /// Subheadline - supporting headlines
    static let subheadline = Font.subheadline

    /// Body - primary content text (17pt default)
    static let body = Font.body

    /// Callout - secondary content
    static let callout = Font.callout

    /// Footnote - tertiary content
    static let footnote = Font.footnote

    /// Caption 1 - metadata, timestamps
    static let caption1 = Font.caption

    /// Caption 2 - smallest text
    static let caption2 = Font.caption2

    // MARK: - Custom Styles

    /// Bold body text
    static let bodyBold = Font.body.bold()

    /// Semibold headline
    static let headlineSemibold = Font.headline.weight(.semibold)

    /// Monospaced for numbers/code
    static let monospacedBody = Font.system(.body, design: .monospaced)

    /// Rounded design for friendly elements
    static let roundedHeadline = Font.system(.headline, design: .rounded)

    // MARK: - Semantic Styles

    /// For action item titles
    static let actionItemTitle = Font.headline

    /// For goal progress numbers
    static let progressNumber = Font.system(.title, design: .rounded).weight(.bold)

    /// For sentiment emojis
    static let sentiment = Font.system(size: 32)

    /// For countdown timers
    static let timer = Font.system(.title2, design: .monospaced).weight(.medium)
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply primary text styling
    func textStylePrimary() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(Colors.textPrimary)
    }

    /// Apply secondary text styling
    func textStyleSecondary() -> some View {
        self
            .font(Typography.callout)
            .foregroundStyle(Colors.textSecondary)
    }

    /// Apply caption styling
    func textStyleCaption() -> some View {
        self
            .font(Typography.caption1)
            .foregroundStyle(Colors.textTertiary)
    }

    /// Apply headline styling
    func textStyleHeadline() -> some View {
        self
            .font(Typography.headline)
            .foregroundStyle(Colors.textPrimary)
    }
}

// MARK: - Accessibility

extension Typography {
    /// Minimum recommended line height multiplier for readability
    static let minimumLineHeightMultiplier: CGFloat = 1.5

    /// Check if larger accessibility sizes are enabled
    static var isAccessibilitySizeEnabled: Bool {
        UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    }
}

// MARK: - Preview

#Preview("Typography Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Large Title")
                    .font(Typography.largeTitle)

                Text("Title 1")
                    .font(Typography.title1)

                Text("Title 2")
                    .font(Typography.title2)

                Text("Title 3")
                    .font(Typography.title3)
            }

            Divider()

            Group {
                Text("Headline")
                    .font(Typography.headline)

                Text("Subheadline")
                    .font(Typography.subheadline)

                Text("Body - The quick brown fox jumps over the lazy dog.")
                    .font(Typography.body)

                Text("Callout - Supporting information")
                    .font(Typography.callout)

                Text("Footnote - Additional details")
                    .font(Typography.footnote)

                Text("Caption 1 - Metadata")
                    .font(Typography.caption1)

                Text("Caption 2 - Smallest")
                    .font(Typography.caption2)
            }

            Divider()

            Group {
                Text("Body Bold")
                    .font(Typography.bodyBold)

                Text("Monospaced: 12345")
                    .font(Typography.monospacedBody)

                Text("Rounded Headline")
                    .font(Typography.roundedHeadline)

                Text("75%")
                    .font(Typography.progressNumber)
            }
        }
        .padding()
    }
}
