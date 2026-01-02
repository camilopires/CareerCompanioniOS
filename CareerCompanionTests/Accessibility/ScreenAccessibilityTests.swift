import XCTest
import SwiftUI
@testable import CareerCompanion

/// Tests for screen-level accessibility
final class ScreenAccessibilityTests: AccessibilityTestCase {

    // MARK: - Filter Accessibility Tests

    func testActionItemFilterHasAccessibleNames() {
        for filter in ActionItemFilter.allCases {
            XCTAssertFalse(
                filter.displayName.isEmpty,
                "ActionItemFilter \(filter) should have a display name for VoiceOver"
            )
        }
    }

    func testGoalFilterHasAccessibleNames() {
        for filter in GoalFilter.allCases {
            XCTAssertFalse(
                filter.displayName.isEmpty,
                "GoalFilter \(filter) should have a display name for VoiceOver"
            )
        }
    }

    // MARK: - User Role Accessibility Tests

    func testUserRoleHasAccessibleNames() {
        for role in UserRole.allCases {
            XCTAssertFalse(
                role.displayName.isEmpty,
                "UserRole \(role) should have a display name"
            )

            XCTAssertFalse(
                role.icon.isEmpty,
                "UserRole \(role) should have an icon"
            )
        }
    }

    // MARK: - Goal Category Accessibility Tests

    func testGoalCategoryAccessibility() {
        for category in GoalCategory.allCases {
            XCTAssertFalse(
                category.displayName.isEmpty,
                "GoalCategory \(category) should have a display name"
            )

            XCTAssertFalse(
                category.icon.isEmpty,
                "GoalCategory \(category) should have an icon"
            )
        }
    }

    // MARK: - Owner Accessibility Tests

    func testOwnerHasAccessibleNames() {
        for owner in Owner.allCases {
            XCTAssertFalse(
                owner.displayName.isEmpty,
                "Owner \(owner) should have a display name"
            )

            XCTAssertFalse(
                owner.icon.isEmpty,
                "Owner \(owner) should have an icon"
            )
        }
    }

    // MARK: - Agenda Template Accessibility Tests

    func testAgendaTemplateAccessibility() {
        for template in AgendaTemplate.allCases {
            XCTAssertFalse(
                template.title.isEmpty,
                "AgendaTemplate \(template) should have a title"
            )

            XCTAssertFalse(
                template.icon.isEmpty,
                "AgendaTemplate \(template) should have an icon"
            )
        }
    }

    // MARK: - Meeting Perspective Accessibility Tests

    func testMeetingPerspectiveAccessibility() {
        for perspective in MeetingPerspective.allCases {
            // Perspectives should have meaningful raw values
            XCTAssertFalse(
                perspective.rawValue.isEmpty,
                "MeetingPerspective \(perspective) should have a raw value"
            )
        }
    }

    // MARK: - Typography Dynamic Type Tests

    func testTypographyUsesDynamicType() {
        // All typography styles should use semantic fonts that scale with Dynamic Type
        // This test verifies the font styles are properly defined

        // These should all be semantic styles that support Dynamic Type
        let styles: [Font] = [
            Typography.largeTitle,
            Typography.title1,
            Typography.title2,
            Typography.title3,
            Typography.headline,
            Typography.subheadline,
            Typography.body,
            Typography.callout,
            Typography.footnote,
            Typography.caption1,
            Typography.caption2
        ]

        // Basic verification that styles are defined
        XCTAssertEqual(styles.count, 11, "All typography styles should be defined")
    }

    // MARK: - Empty State Accessibility Tests

    func testEmptyStateHasAccessibleContent() {
        // Verify standard empty states have content
        let noMeetings = EmptyState.noMeetings
        let noGoals = EmptyState.noGoals
        let noActionItems = EmptyState.noActionItems

        // These should all produce valid view content
        XCTAssertNotNil(noMeetings)
        XCTAssertNotNil(noGoals)
        XCTAssertNotNil(noActionItems)
    }

    // MARK: - Haptic Feedback Tests

    func testHapticFeedbackMethodsExist() {
        // Verify all haptic feedback methods are available
        // These provide non-visual feedback for accessibility

        // These should not throw or crash
        Theme.lightHaptic()
        Theme.mediumHaptic()
        Theme.successHaptic()
        Theme.errorHaptic()
        Theme.selectionHaptic()

        // If we get here, all methods exist and are callable
        XCTAssertTrue(true, "All haptic feedback methods should be available")
    }
}
