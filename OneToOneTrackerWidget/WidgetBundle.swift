import WidgetKit
import SwiftUI

@main
struct OneToOneTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        ActionItemsWidget()
        NextMeetingWidget()
        CareerGoalsWidget()
    }
}
