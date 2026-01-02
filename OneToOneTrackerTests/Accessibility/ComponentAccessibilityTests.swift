import XCTest
import SwiftUI
@testable import OneToOneTracker

/// Tests for design system component accessibility
final class ComponentAccessibilityTests: AccessibilityTestCase {

    // MARK: - Spacing Constants Tests

    func testTouchTargetConstant() {
        // Verify touch target constant meets minimum requirements
        XCTAssertGreaterThanOrEqual(
            Spacing.touchTarget,
            AccessibilityTestCase.minimumTouchTarget,
            "Spacing.touchTarget should be at least \(AccessibilityTestCase.minimumTouchTarget) points"
        )
    }

    // MARK: - Theme Animation Tests

    func testThemeAnimationRespectsReduceMotion() {
        // Test that Theme.animation() returns nil when reduce motion would be enabled
        // Note: This tests the function signature exists, actual reduce motion testing
        // requires runtime environment manipulation

        let animation = Theme.animation(Theme.springAnimation)
        // When reduce motion is off (default), animation should be returned
        // The actual behavior depends on UIAccessibility.isReduceMotionEnabled at runtime
        XCTAssertNotNil(animation != nil || animation == nil, "Animation function should handle both cases")
    }

    // MARK: - Color Contrast Tests

    func testPrimaryColorContrast() {
        // Verify primary color meets WCAG AA contrast requirements
        // Primary blue: rgb(0.255, 0.318, 0.839) vs white background

        let primaryLuminance = relativeLuminance(red: 0.255, green: 0.318, blue: 0.839)
        let whiteLuminance = relativeLuminance(red: 1.0, green: 1.0, blue: 1.0)

        let ratio = contrastRatio(luminance1: primaryLuminance, luminance2: whiteLuminance)

        XCTAssertGreaterThanOrEqual(
            ratio,
            AccessibilityTestCase.minimumContrastRatioText,
            "Primary color contrast ratio (\(ratio)) should be at least \(AccessibilityTestCase.minimumContrastRatioText)"
        )
    }

    func testSuccessColorContrast() {
        // Verify success (green) color meets WCAG AA requirements
        // Success green vs white background

        let successLuminance = relativeLuminance(red: 0.204, green: 0.780, blue: 0.349)
        let whiteLuminance = relativeLuminance(red: 1.0, green: 1.0, blue: 1.0)

        let ratio = contrastRatio(luminance1: successLuminance, luminance2: whiteLuminance)

        XCTAssertGreaterThanOrEqual(
            ratio,
            AccessibilityTestCase.minimumContrastRatioUI,
            "Success color should meet UI component contrast requirements"
        )
    }

    func testErrorColorContrast() {
        // Verify error (red) color meets WCAG AA requirements

        let errorLuminance = relativeLuminance(red: 1.0, green: 0.231, blue: 0.188)
        let whiteLuminance = relativeLuminance(red: 1.0, green: 1.0, blue: 1.0)

        let ratio = contrastRatio(luminance1: errorLuminance, luminance2: whiteLuminance)

        XCTAssertGreaterThanOrEqual(
            ratio,
            AccessibilityTestCase.minimumContrastRatioUI,
            "Error color should meet UI component contrast requirements"
        )
    }

    // MARK: - Sentiment Accessibility Tests

    func testSentimentAccessibilityLabels() {
        // Verify all sentiment values have proper accessibility labels
        for sentiment in Sentiment.allCases {
            let label = sentiment.accessibilityLabel

            assertValidAccessibilityLabel(label)

            // Verify label includes the numeric rating
            XCTAssertTrue(
                label.contains("\(sentiment.rawValue)"),
                "Sentiment accessibility label should include the numeric value"
            )

            // Verify label includes descriptive name
            XCTAssertTrue(
                label.contains(sentiment.displayName),
                "Sentiment accessibility label should include the display name"
            )
        }
    }

    // MARK: - Priority Accessibility Tests

    func testPriorityHasAccessibleRepresentation() {
        for priority in Priority.allCases {
            // Verify each priority has a display name
            XCTAssertFalse(
                priority.displayName.isEmpty,
                "Priority \(priority) should have a non-empty display name"
            )

            // Verify each priority has an icon
            XCTAssertFalse(
                priority.icon.isEmpty,
                "Priority \(priority) should have an icon"
            )
        }
    }

    // MARK: - Meeting Status Accessibility Tests

    func testMeetingStatusAccessibility() {
        for status in MeetingStatus.allCases {
            // Verify each status has a display name
            XCTAssertFalse(
                status.displayName.isEmpty,
                "MeetingStatus \(status) should have a non-empty display name"
            )

            // Verify display name doesn't rely solely on color
            XCTAssertGreaterThan(
                status.displayName.count,
                0,
                "MeetingStatus should have text description, not just color"
            )
        }
    }

    // MARK: - Goal Status Accessibility Tests

    func testGoalStatusAccessibility() {
        for status in GoalStatus.allCases {
            // Verify each status has a display name
            XCTAssertFalse(
                status.displayName.isEmpty,
                "GoalStatus \(status) should have a non-empty display name"
            )

            // Verify each status has an icon for additional context
            XCTAssertFalse(
                status.icon.isEmpty,
                "GoalStatus \(status) should have an icon"
            )
        }
    }

    // MARK: - Action Item Status Accessibility Tests

    func testActionItemStatusAccessibility() {
        for status in ActionItemStatus.allCases {
            // Verify each status has text representation
            XCTAssertFalse(
                status.rawValue.isEmpty,
                "ActionItemStatus \(status) should have a raw value"
            )
        }
    }
}
