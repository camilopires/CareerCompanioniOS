import SwiftUI

/// 8pt grid spacing system for consistent layout
/// All spacing values are multiples of 4pt (half-grid) or 8pt (full grid)
enum Spacing {

    // MARK: - Base Units

    /// 4pt - Half grid unit, for tight spacing
    static let xxs: CGFloat = 4

    /// 8pt - Base grid unit
    static let xs: CGFloat = 8

    /// 12pt - Between related elements
    static let sm: CGFloat = 12

    /// 16pt - Standard spacing
    static let md: CGFloat = 16

    /// 20pt - Between sections
    static let lg: CGFloat = 20

    /// 24pt - Major sections
    static let xl: CGFloat = 24

    /// 32pt - Screen sections
    static let xxl: CGFloat = 32

    /// 40pt - Major screen divisions
    static let xxxl: CGFloat = 40

    // MARK: - Semantic Spacing

    /// Padding inside cards
    static let cardPadding: CGFloat = 16

    /// Spacing between list items
    static let listItemSpacing: CGFloat = 12

    /// Screen edge padding
    static let screenPadding: CGFloat = 16

    /// Section header spacing
    static let sectionSpacing: CGFloat = 24

    /// Spacing between form fields
    static let formFieldSpacing: CGFloat = 16

    /// Icon to text spacing
    static let iconTextSpacing: CGFloat = 8

    // MARK: - Touch Targets

    /// Minimum touch target size (44pt per Apple HIG)
    static let touchTarget: CGFloat = 44

    /// Minimum spacing between touch targets
    static let touchTargetSpacing: CGFloat = 8

    // MARK: - Corner Radius

    /// Small corner radius - buttons, tags
    static let cornerRadiusSmall: CGFloat = 8

    /// Medium corner radius - cards
    static let cornerRadiusMedium: CGFloat = 12

    /// Large corner radius - modals, sheets
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large - full cards
    static let cornerRadiusXL: CGFloat = 20

    // MARK: - Shadows

    /// Shadow radius for elevated cards
    static let shadowRadius: CGFloat = 8

    /// Shadow Y offset
    static let shadowY: CGFloat = 4
}

// MARK: - Padding Helpers

extension View {
    /// Apply standard screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Spacing.screenPadding)
    }

    /// Apply card internal padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }

    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.bottom, Spacing.sectionSpacing)
    }
}

// MARK: - Layout Helpers

extension CGFloat {
    /// Round to nearest grid point (8pt)
    var gridAligned: CGFloat {
        (self / 8).rounded() * 8
    }

    /// Round to nearest half-grid point (4pt)
    var halfGridAligned: CGFloat {
        (self / 4).rounded() * 4
    }
}

// MARK: - Preview

#Preview("Spacing Scale") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Spacing Scale")
                .font(.headline)

            ForEach([
                ("xxs", Spacing.xxs),
                ("xs", Spacing.xs),
                ("sm", Spacing.sm),
                ("md", Spacing.md),
                ("lg", Spacing.lg),
                ("xl", Spacing.xl),
                ("xxl", Spacing.xxl),
                ("xxxl", Spacing.xxxl)
            ], id: \.0) { name, value in
                HStack {
                    Text("\(name): \(Int(value))pt")
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: value, height: 20)
                }
            }

            Divider()
                .padding(.vertical)

            Text("Corner Radii")
                .font(.headline)

            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Text("8pt").font(.caption))

                RoundedRectangle(cornerRadius: Spacing.cornerRadiusMedium)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Text("12pt").font(.caption))

                RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Text("16pt").font(.caption))

                RoundedRectangle(cornerRadius: Spacing.cornerRadiusXL)
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Text("20pt").font(.caption))
            }

            Divider()
                .padding(.vertical)

            Text("Touch Target: \(Int(Spacing.touchTarget))pt minimum")
                .font(.headline)

            Rectangle()
                .fill(Color.accentColor)
                .frame(width: Spacing.touchTarget, height: Spacing.touchTarget)
                .overlay(Text("44").foregroundStyle(.white))
        }
        .padding()
    }
}
