import SwiftUI

/// Circular progress indicator for goals and completion tracking
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var trackColor: Color = Colors.separator
    var progressColor: Color = .accentColor
    var showPercentage: Bool = true

    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    private var percentageText: String {
        "\(Int(clampedProgress * 100))%"
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.springAnimation, value: clampedProgress)

            // Percentage text
            if showPercentage {
                Text(percentageText)
                    .font(size > 50 ? Typography.headline : Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Colors.textPrimary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(clampedProgress * 100)) percent")
        .accessibilityValue(percentageText)
    }
}

// MARK: - Progress Ring with Label

struct LabeledProgressRing: View {
    let progress: Double
    let label: String
    var size: CGFloat = 80
    var progressColor: Color = .accentColor

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ProgressRing(
                progress: progress,
                size: size,
                progressColor: progressColor
            )

            Text(label)
                .font(Typography.caption1)
                .foregroundStyle(Colors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Mini Progress Ring

/// Small progress ring for inline use
struct MiniProgressRing: View {
    let progress: Double
    var size: CGFloat = 24
    var progressColor: Color = .accentColor

    var body: some View {
        ProgressRing(
            progress: progress,
            size: size,
            lineWidth: 3,
            progressColor: progressColor,
            showPercentage: false
        )
    }
}

// MARK: - Goal Progress Ring

/// Progress ring styled for career goals
struct GoalProgressRing: View {
    let goal: CareerGoal

    private var progressColor: Color {
        switch goal.status {
        case .achieved: return Colors.success
        case .inProgress: return goal.category.color
        case .paused: return Colors.warning
        case .notStarted: return Colors.textTertiary
        }
    }

    var body: some View {
        ProgressRing(
            progress: goal.progressPercentage,
            size: 60,
            progressColor: progressColor
        )
    }
}

// MARK: - Linear Progress Bar

/// Horizontal progress bar alternative
struct ProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var trackColor: Color = Colors.separator
    var progressColor: Color = .accentColor
    var cornerRadius: CGFloat = 4

    private var clampedProgress: Double {
        min(1.0, max(0.0, progress))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(trackColor)

                // Progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * clampedProgress)
                    .animation(Theme.springAnimation, value: clampedProgress)
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

// MARK: - Preview

#Preview("Progress Indicators") {
    ScrollView {
        VStack(spacing: Spacing.xxl) {
            Text("Progress Rings")
                .font(.headline)

            HStack(spacing: Spacing.xl) {
                ProgressRing(progress: 0.25)
                ProgressRing(progress: 0.50, progressColor: .orange)
                ProgressRing(progress: 0.75, progressColor: .green)
                ProgressRing(progress: 1.0, progressColor: Colors.success)
            }

            Divider()

            Text("Different Sizes")
                .font(.headline)

            HStack(spacing: Spacing.xl) {
                ProgressRing(progress: 0.65, size: 40, lineWidth: 4)
                ProgressRing(progress: 0.65, size: 60)
                ProgressRing(progress: 0.65, size: 80, lineWidth: 8)
                ProgressRing(progress: 0.65, size: 100, lineWidth: 10)
            }

            Divider()

            Text("Mini Progress Rings")
                .font(.headline)

            HStack(spacing: Spacing.md) {
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                    MiniProgressRing(progress: value)
                }
            }

            Divider()

            Text("Labeled Progress Rings")
                .font(.headline)

            HStack(spacing: Spacing.xl) {
                LabeledProgressRing(progress: 0.45, label: "Technical")
                LabeledProgressRing(progress: 0.70, label: "Leadership", progressColor: .purple)
                LabeledProgressRing(progress: 1.0, label: "Complete", progressColor: Colors.success)
            }

            Divider()

            Text("Progress Bars")
                .font(.headline)

            VStack(spacing: Spacing.md) {
                ProgressBar(progress: 0.3)
                ProgressBar(progress: 0.6, progressColor: .orange)
                ProgressBar(progress: 0.9, progressColor: .green)
                ProgressBar(progress: 1.0, height: 12, progressColor: Colors.success)
            }
        }
        .padding()
    }
}
