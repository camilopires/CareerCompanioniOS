import XCTest
import SwiftUI
@testable import OneToOneTracker

/// Base class for accessibility tests with common helpers
class AccessibilityTestCase: XCTestCase {

    // MARK: - Touch Target Helpers

    /// Minimum touch target size per Apple HIG (44x44 points)
    static let minimumTouchTarget: CGFloat = 44

    /// Verifies a view meets minimum touch target requirements
    func assertMinimumTouchTarget(_ size: CGSize, file: StaticString = #file, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(
            size.width,
            Self.minimumTouchTarget,
            "Width \(size.width) is below minimum touch target of \(Self.minimumTouchTarget)",
            file: file,
            line: line
        )
        XCTAssertGreaterThanOrEqual(
            size.height,
            Self.minimumTouchTarget,
            "Height \(size.height) is below minimum touch target of \(Self.minimumTouchTarget)",
            file: file,
            line: line
        )
    }

    // MARK: - Reduce Motion Helpers

    /// Tests that animations respect reduce motion setting
    func assertReduceMotionRespected(
        animation: Animation?,
        reduceMotionEnabled: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if reduceMotionEnabled {
            XCTAssertNil(
                animation,
                "Animation should be nil when reduce motion is enabled",
                file: file,
                line: line
            )
        }
    }

    // MARK: - Color Contrast Helpers

    /// WCAG AA minimum contrast ratio for normal text
    static let minimumContrastRatioText: CGFloat = 4.5

    /// WCAG AA minimum contrast ratio for large text (18pt+ or 14pt bold)
    static let minimumContrastRatioLargeText: CGFloat = 3.0

    /// WCAG AA minimum contrast ratio for UI components
    static let minimumContrastRatioUI: CGFloat = 3.0

    /// Calculates relative luminance of a color (WCAG formula)
    func relativeLuminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        func adjust(_ component: CGFloat) -> CGFloat {
            return component <= 0.03928
                ? component / 12.92
                : pow((component + 0.055) / 1.055, 2.4)
        }

        let r = adjust(red)
        let g = adjust(green)
        let b = adjust(blue)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// Calculates contrast ratio between two luminance values
    func contrastRatio(luminance1: CGFloat, luminance2: CGFloat) -> CGFloat {
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    // MARK: - Accessibility Label Helpers

    /// Verifies that a string is suitable as an accessibility label
    func assertValidAccessibilityLabel(
        _ label: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let label = label else {
            XCTFail("Accessibility label should not be nil", file: file, line: line)
            return
        }

        XCTAssertFalse(
            label.isEmpty,
            "Accessibility label should not be empty",
            file: file,
            line: line
        )

        // Labels should not include the word "button" or similar as VoiceOver adds traits automatically
        let forbiddenWords = ["button", "image", "icon", "picture"]
        for word in forbiddenWords {
            XCTAssertFalse(
                label.lowercased().contains(word),
                "Accessibility label should not include '\(word)' - VoiceOver adds this automatically",
                file: file,
                line: line
            )
        }
    }
}
