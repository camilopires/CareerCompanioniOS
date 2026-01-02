import SwiftUI

/// Picker for selecting sentiment rating (1-5)
struct SentimentPicker: View {
    @Binding var selectedSentiment: Int?
    var label: String = "How was it?"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(label)
                .font(Typography.subheadline)
                .foregroundStyle(Colors.textSecondary)

            HStack(spacing: Spacing.md) {
                ForEach(Sentiment.allCases) { sentiment in
                    SentimentButton(
                        sentiment: sentiment,
                        isSelected: selectedSentiment == sentiment.rawValue,
                        action: {
                            Theme.selectionHaptic()
                            withAnimation(Theme.animation(Theme.springAnimation)) {
                                if selectedSentiment == sentiment.rawValue {
                                    selectedSentiment = nil
                                } else {
                                    selectedSentiment = sentiment.rawValue
                                }
                            }
                        }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}

// MARK: - Sentiment Button

private struct SentimentButton: View {
    let sentiment: Sentiment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Text(sentiment.emoji)
                    .font(Typography.sentiment)
                    .scaleEffect(UIAccessibility.isReduceMotionEnabled ? 1.0 : (isSelected ? 1.2 : 1.0))

                if isSelected {
                    Circle()
                        .fill(sentiment.color)
                        .frame(width: 6, height: 6)
                        .transition(UIAccessibility.isReduceMotionEnabled ? .opacity : .scale.combined(with: .opacity))
                }
            }
            .frame(minWidth: Spacing.touchTarget, minHeight: Spacing.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .fill(isSelected ? sentiment.color.opacity(0.15) : .clear)
            )
        }
        .buttonStyle(.plain)
        .accessibleAnimation(Theme.springAnimation, value: isSelected)
        .accessibilityLabel(sentiment.accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Compact Sentiment Display

/// Read-only display of a sentiment value
struct SentimentDisplay: View {
    let sentiment: Sentiment

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(sentiment.emoji)
                .font(.title3)

            Text(sentiment.displayName)
                .font(Typography.callout)
                .foregroundStyle(Colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sentiment.accessibilityLabel)
    }
}

// MARK: - Inline Sentiment Picker

/// Horizontal sentiment picker without label
struct InlineSentimentPicker: View {
    @Binding var selectedSentiment: Int?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(Sentiment.allCases) { sentiment in
                Button {
                    Theme.selectionHaptic()
                    withAnimation(Theme.animation(Theme.springAnimation)) {
                        selectedSentiment = sentiment.rawValue
                    }
                } label: {
                    Text(sentiment.emoji)
                        .font(.title2)
                        .opacity(selectedSentiment == sentiment.rawValue ? 1.0 : 0.4)
                        .scaleEffect(UIAccessibility.isReduceMotionEnabled ? 1.0 : (selectedSentiment == sentiment.rawValue ? 1.1 : 1.0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sentiment.accessibilityLabel)
                .accessibilityAddTraits(selectedSentiment == sentiment.rawValue ? [.isSelected] : [])
            }
        }
    }
}

// MARK: - Sentiment Summary

/// Shows sentiment with trend indicator
struct SentimentSummary: View {
    let currentSentiment: Sentiment
    let previousSentiment: Sentiment?

    private var trend: Trend {
        guard let previous = previousSentiment else { return .neutral }
        if currentSentiment.rawValue > previous.rawValue { return .up }
        if currentSentiment.rawValue < previous.rawValue { return .down }
        return .neutral
    }

    private enum Trend {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .neutral: return "equal.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .up: return Colors.success
            case .down: return Colors.error
            case .neutral: return Colors.textTertiary
            }
        }

        var accessibilityDescription: String {
            switch self {
            case .up: return "trending up"
            case .down: return "trending down"
            case .neutral: return "no change"
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(currentSentiment.emoji)
                .font(.title2)

            if previousSentiment != nil {
                Image(systemName: trend.icon)
                    .foregroundStyle(trend.color)
                    .font(.caption)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentSentiment.displayName), \(trend.accessibilityDescription)")
    }
}

// MARK: - Preview

#Preview("Sentiment Pickers") {
    struct PreviewContainer: View {
        @State private var weekSentiment: Int? = 4
        @State private var meetingSentiment: Int? = nil
        @State private var inlineSentiment: Int? = 3

        var body: some View {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    Text("Sentiment Picker")
                        .font(.headline)

                    SentimentPicker(
                        selectedSentiment: $weekSentiment,
                        label: "How was your week?"
                    )

                    SentimentPicker(
                        selectedSentiment: $meetingSentiment,
                        label: "How was this 1:1?"
                    )

                    Divider()

                    Text("Inline Picker")
                        .font(.headline)

                    InlineSentimentPicker(selectedSentiment: $inlineSentiment)

                    Divider()

                    Text("Sentiment Display")
                        .font(.headline)

                    ForEach(Sentiment.allCases) { sentiment in
                        SentimentDisplay(sentiment: sentiment)
                    }

                    Divider()

                    Text("Sentiment Summary")
                        .font(.headline)

                    HStack(spacing: Spacing.xl) {
                        SentimentSummary(
                            currentSentiment: .veryGood,
                            previousSentiment: .good
                        )
                        SentimentSummary(
                            currentSentiment: .neutral,
                            previousSentiment: .good
                        )
                        SentimentSummary(
                            currentSentiment: .good,
                            previousSentiment: .good
                        )
                    }
                }
                .padding()
            }
        }
    }

    return PreviewContainer()
}
