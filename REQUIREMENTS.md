# OneToOne Tracker iOS App - Requirements Document

## Overview

A native iOS app built in Swift to help employees prepare for, conduct, and follow up on 1:1 meetings with their managers, while also tracking career goals and achievements for performance reviews. The app focuses on tracking action items, capturing meeting notes, career progression, and providing seamless integration with communication tools.

---

## Core Features

### 1. Home Screen / Dashboard

#### 1.1 Primary Navigation
Two main entry points displayed prominently:
- **1:1 Meetings** - Access meeting preparation, history, and action items
- **Career Goals** - Access goals, achievements, and performance reports

#### 1.2 Action Items Overview
- Display all open action items in a prioritized list
- Show action item details: title, due date, source meeting, assignee
- Quick-action button to mark items as complete
- Filter/sort options: by date, priority, status
- Visual indicators for overdue items

#### 1.3 Upcoming 1:1 Section
- Show next scheduled 1:1 with countdown
- Quick access to prepare agenda
- Preview of carried-over action items

#### 1.4 Career Progress Snapshot
- Active goals count with progress indicators
- Recent achievements badge
- Days until next review period

#### 1.5 Quick Stats
- Number of open action items
- Completed items this week
- Streak of completed 1:1s
- Goals progress percentage

---

### 2. Pre-Meeting Preparation

#### 2.1 Agenda Builder
- Create agenda items for upcoming 1:1
- Reorder agenda items via drag-and-drop
- Auto-populate with:
  - Incomplete action items from previous meetings
  - Recurring discussion topics
  - Recent achievements to discuss
- Templates for common agenda structures

#### 2.2 Share/Export Agenda
- Copy agenda as formatted text for:
  - Slack message
  - Microsoft Teams message
  - Email
  - Plain text
- Customizable export format
- One-tap copy to clipboard
- Direct share sheet integration

---

### 3. During 1:1 Meeting

#### 3.1 Meeting View
- Display current agenda with checkboxes
- Easy navigation between agenda items
- Timer showing meeting duration

#### 3.2 Notes & Comments
- Rich text notes for each agenda item
- General meeting notes section
- Voice-to-text support (optional)

#### 3.3 Action Items Capture
- Quick-add action items during meeting
- Assign owner (self or manager)
- Set due date
- Link to specific agenda item
- Priority level (low, medium, high)

#### 3.4 Structured Feedback Sections

**What Went Well**
- Bullet point list
- Celebrate wins and achievements
- Track positive patterns over time

**What Didn't Go Well**
- Challenges faced during the week
- Areas for improvement
- Learning opportunities

**Blockers**
- Current impediments to progress
- Resources needed
- Dependencies on others

**Escalations for Manager**
- Issues requiring manager attention
- Decisions needing approval
- Support requests

#### 3.5 Sentiment Tracking

**Week Sentiment**
- How was your week overall? (1-5 scale or emoji)
- Optional notes explaining rating
- Track trends over time

**1:1 Sentiment**
- How did this 1:1 go? (1-5 scale or emoji)
- Feedback on meeting effectiveness
- Track 1:1 quality over time

---

### 4. Action Items Management

#### 4.1 Action Item Properties
- Title (required)
- Description
- Due date
- Priority (low, medium, high)
- Status (open, in progress, completed)
- Owner (self, manager)
- Links/attachments
- Comments thread
- Source meeting reference

#### 4.2 Action Item Lifecycle
- Created during 1:1 or standalone
- Appears on home screen when open
- Can add progress comments
- Mark as complete with completion notes
- Completed items auto-populate next meeting's "Review" section
- Archive after review in next meeting

#### 4.3 Action Item Links
- Add URLs to relevant resources
- Deep links to other apps (Jira, Linear, etc.)
- Attach images or documents

---

### 5. Career Goals & Achievements

#### 5.1 Career Goals

**Goal Properties**
- Title (required)
- Description / Why this matters
- Category (Technical, Leadership, Communication, Domain Knowledge, Other)
- Target date / Timeline
- Status (Not Started, In Progress, Achieved, Paused)
- Priority (Primary, Secondary)
- Success metrics - How will you measure this?
- Tracking method - How will you track progress?
- Progress percentage (0-100%)
- Related competencies/skills
- Notes

**Goal Management**
- Create, edit, archive goals
- Set quarterly/annual goals
- Link goals to company competency frameworks (optional)
- Drag-and-drop priority ordering
- Progress tracking with milestones
- Visual progress indicators (progress bars, charts)

#### 5.2 Achievements

**Achievement Properties**
- Title (required)
- Description - What did you accomplish?
- Date achieved
- Impact statement - Quantifiable results where possible
- Linked goal(s) - Which career goal(s) does this support?
- Evidence/artifacts - Links, screenshots, documents
- Category tags
- Visibility (Private, Share with Manager, Public)

**Achievement Capture**
- Quick-add from home screen
- Add during 1:1 (from "What Went Well")
- Prompt to add achievements when completing action items
- Import from "What Went Well" sections in past meetings
- Photo attachment for certificates, awards, etc.

#### 5.3 Performance Review Report Generator

**Report Configuration**
- Select date range (Quarter, Half-year, Year, Custom)
- Choose which goals to include
- Select achievements to highlight
- Add personal summary/narrative
- Include sentiment trends (optional)
- Include 1:1 meeting summaries (optional)

**Report Sections**
1. Executive Summary
   - Period overview
   - Key accomplishments count
   - Goals achieved vs. set

2. Goals Progress
   - Each goal with status and progress
   - Achievements linked to each goal
   - Evidence and metrics

3. Key Achievements
   - Chronological or by impact
   - Full details with evidence links
   - Impact statements

4. Growth Areas
   - Skills developed
   - Challenges overcome
   - Learning highlights

5. Looking Forward
   - Upcoming goals
   - Development areas
   - Support needed

**Export Options**
- PDF (formatted, printable)
- Markdown
- Plain text
- Copy to clipboard
- Share sheet (email, Slack, Teams)
- Save to Files app

---

### 6. iOS Widgets

#### 6.1 Small Widget
- Number of open action items
- Next 1:1 date/time
- Tap to open app

#### 6.2 Medium Widget
- List of top 3 action items
- Quick-complete buttons
- Next 1:1 countdown

#### 6.3 Large Widget
- Full action items list (scrollable)
- Upcoming agenda preview
- Week sentiment quick-entry

#### 6.4 Lock Screen Widgets
- Action item count badge
- Next 1:1 countdown
- Quick sentiment indicator

#### 6.5 Career Goals Widget (Medium)
- Top 3 active goals with progress bars
- Days until target date
- Tap to open goals view

---

### 7. Meeting History

#### 7.1 Past Meetings List
- Chronological list of all 1:1s
- Search and filter capabilities
- Quick stats per meeting

#### 7.2 Meeting Detail View
- Full meeting notes
- All sections (went well, blockers, etc.)
- Action items created
- Sentiment ratings

#### 7.3 Analytics
- Sentiment trends over time
- Action item completion rate
- Common topics/themes
- Meeting frequency

---

## Design Requirements

### Visual Design Philosophy

#### Design Principles
- **Clean & Focused** - Minimal visual clutter, content-first approach
- **Warm & Approachable** - Friendly without being unprofessional
- **Consistent** - Unified design language throughout
- **Delightful** - Subtle animations and micro-interactions
- **Native Feel** - Follows iOS Human Interface Guidelines

#### Color Palette
- Primary brand color with semantic variations
- Neutral grays for backgrounds and text
- Semantic colors for status (success, warning, error, info)
- Ensure all color combinations meet WCAG AA contrast ratios
- Support for light and dark mode with appropriate palettes

#### Typography
- San Francisco (system font) for optimal legibility
- Clear type hierarchy:
  - Large Title: Navigation headers
  - Title 1-3: Section headers
  - Headline: Card titles
  - Body: Primary content
  - Callout: Secondary information
  - Caption: Metadata, timestamps
- Support Dynamic Type (all text sizes)

#### Iconography
- SF Symbols for consistency with iOS
- Filled icons for selected states
- Outlined icons for unselected states
- Consistent icon sizing and padding

#### Spacing & Layout
- 8pt grid system
- Consistent margins and padding
- Generous white space for readability
- Card-based layouts for grouped content
- Clear visual hierarchy

#### Animations & Transitions
- Smooth, purposeful animations (0.2-0.3s duration)
- Spring animations for interactive elements
- Fade transitions between views
- Subtle haptic feedback for actions
- Loading states with skeleton screens

#### Component Library

**Buttons**
- Primary: Filled, high contrast
- Secondary: Outlined or tinted
- Tertiary: Text only
- Minimum touch target: 44x44pt

**Cards**
- Rounded corners (12-16pt radius)
- Subtle shadows in light mode
- Clear content hierarchy
- Optional swipe actions

**Forms**
- Clear labels above fields
- Helpful placeholder text
- Inline validation with clear error states
- Grouped related fields

**Lists**
- Clear row separation
- Swipe actions where appropriate
- Pull-to-refresh
- Empty states with helpful guidance

**Progress Indicators**
- Circular for goals/completion
- Linear for steps/processes
- Animated state changes
- Clear percentage labels

---

## Accessibility Requirements (WCAG 2.1 AA Compliance)

### Perceivable

#### 1.1 Text Alternatives
- All images have descriptive alt text
- Icons have accessibility labels
- Decorative images marked as such
- Charts/graphs have text descriptions

#### 1.2 Time-based Media
- Any audio/video content has captions (if applicable)

#### 1.3 Adaptable
- Content structure conveyed through proper semantics
- Reading order is logical and intuitive
- No reliance on sensory characteristics alone (shape, color, location)

#### 1.4 Distinguishable

**Color Contrast**
- Normal text: minimum 4.5:1 contrast ratio
- Large text (18pt+ or 14pt bold): minimum 3:1 contrast ratio
- UI components and graphics: minimum 3:1 contrast ratio
- Focus indicators: clearly visible with sufficient contrast

**Color Independence**
- Information not conveyed by color alone
- Status indicators use icons + color + text
- Error states use icons and text labels
- Charts use patterns in addition to colors

**Text Sizing**
- Full support for Dynamic Type (all sizes)
- Text scales up to 200% without loss of content
- No horizontal scrolling at larger text sizes
- Minimum body text size: 17pt (default)

**Visual Presentation**
- Text not justified
- Line height at least 1.5x font size
- Paragraph spacing at least 2x font size
- No images of text (use real text)

### Operable

#### 2.1 Keyboard Accessible
- All functionality available via external keyboard
- No keyboard traps
- Logical tab order
- Visible focus indicators

#### 2.4 Navigable

**VoiceOver Support**
- All elements have appropriate accessibility labels
- Accessibility hints for complex interactions
- Accessibility traits set correctly (button, header, etc.)
- Logical reading order
- Group related elements with accessibility containers
- Custom actions for swipe gestures

**Focus Management**
- Focus moves logically through interface
- Focus trapped in modals until dismissed
- Focus returns appropriately after modal dismissal
- Skip navigation for repetitive content

**Touch Targets**
- Minimum touch target size: 44x44 points
- Adequate spacing between targets (8pt minimum)
- Forgiving tap areas for small icons

### Understandable

#### 3.1 Readable
- Language of app specified
- Abbreviations explained on first use
- Jargon minimized or explained

#### 3.2 Predictable
- Consistent navigation patterns
- Consistent identification of UI elements
- No unexpected context changes
- User-initiated actions only

#### 3.3 Input Assistance
- Clear error identification
- Labels and instructions for inputs
- Error prevention for important actions (confirmations)
- Suggestions for error correction

### Robust

#### 4.1 Compatible
- Works with current and future assistive technologies
- Valid, semantic markup
- Status messages announced to screen readers
- Compatible with Switch Control
- Compatible with Voice Control

### Additional iOS Accessibility Features

**Reduce Motion**
- Respect `UIAccessibility.isReduceMotionEnabled`
- Provide alternatives to animated transitions
- Disable parallax effects when enabled
- Simpler, faster transitions

**Reduce Transparency**
- Respect `UIAccessibility.isReduceTransparencyEnabled`
- Use solid backgrounds instead of blurred
- Increase contrast when enabled

**Bold Text**
- Respect `UIAccessibility.isBoldTextEnabled`
- Use system font weight adjustments
- Test layouts with bold text enabled

**Smart Invert / Dark Mode**
- Full dark mode support
- Images and icons adapt appropriately
- No color inversion issues

**Haptic Feedback**
- Use for important actions and confirmations
- Respect system haptic settings
- Don't overuse - meaningful only

### Accessibility Testing Requirements

**Automated Testing**
- Accessibility Inspector (Xcode)
- XCUI accessibility audits
- Contrast ratio verification

**Manual Testing**
- Full VoiceOver navigation
- Dynamic Type at all sizes
- External keyboard navigation
- Switch Control testing
- Voice Control testing
- Reduce Motion testing

**User Testing**
- Include users with disabilities in beta testing
- Gather feedback on accessibility experience
- Iterate based on real-world usage

---

## Technical Requirements

### Platform & Framework
- iOS 17+ (minimum deployment target)
- Swift 5.9+
- SwiftUI for UI
- SwiftData for persistence
- WidgetKit for widgets
- CloudKit for sync (optional)

### Architecture
- MVVM architecture pattern
- Protocol-oriented design
- Dependency injection
- Unit and UI testing

### Data Model

```
Manager
├── id: UUID
├── name: String
├── email: String (optional)
└── meetings: [Meeting]

Meeting
├── id: UUID
├── date: Date
├── status: MeetingStatus (scheduled, completed, cancelled)
├── agendaItems: [AgendaItem]
├── notes: String
├── wentWell: [String]
├── didntGoWell: [String]
├── blockers: [String]
├── escalations: [String]
├── weekSentiment: Int (1-5)
├── meetingSentiment: Int (1-5)
└── actionItems: [ActionItem]

AgendaItem
├── id: UUID
├── title: String
├── notes: String
├── isCompleted: Bool
└── order: Int

ActionItem
├── id: UUID
├── title: String
├── description: String
├── dueDate: Date?
├── priority: Priority (low, medium, high)
├── status: ActionStatus (open, inProgress, completed)
├── owner: Owner (self, manager)
├── links: [URL]
├── comments: [Comment]
├── createdAt: Date
├── completedAt: Date?
└── sourceMeeting: Meeting?

CareerGoal
├── id: UUID
├── title: String
├── description: String
├── category: GoalCategory
├── targetDate: Date?
├── status: GoalStatus (notStarted, inProgress, achieved, paused)
├── priority: GoalPriority (primary, secondary)
├── successMetrics: String
├── trackingMethod: String
├── progress: Int (0-100)
├── skills: [String]
├── notes: String
├── createdAt: Date
├── updatedAt: Date
└── achievements: [Achievement]

Achievement
├── id: UUID
├── title: String
├── description: String
├── dateAchieved: Date
├── impactStatement: String
├── linkedGoals: [CareerGoal]
├── evidenceLinks: [URL]
├── attachments: [Attachment]
├── tags: [String]
├── visibility: Visibility (private, manager, public)
├── createdAt: Date
└── sourceMeeting: Meeting? (if from "What Went Well")

Comment
├── id: UUID
├── text: String
├── createdAt: Date
└── attachments: [Attachment]

PerformanceReport
├── id: UUID
├── title: String
├── dateRange: DateInterval
├── goals: [CareerGoal]
├── achievements: [Achievement]
├── personalSummary: String
├── includeSentiment: Bool
├── includeMeetingSummaries: Bool
├── createdAt: Date
└── exportedFormats: [ExportFormat]
```

### Storage
- Local persistence with SwiftData
- iCloud sync via CloudKit (optional feature)
- Export/backup to JSON

### Notifications
- Reminder before scheduled 1:1
- Action item due date reminders
- Weekly preparation reminder
- Goal milestone reminders

---

## User Experience

### Onboarding
- Quick setup wizard
- Add manager details
- Set 1:1 schedule
- Optional: Set up first career goal
- Permission requests (notifications)
- Brief accessibility settings prompt

### Themes
- System appearance (light/dark/auto)
- Accent color customization
- High contrast mode option

---

## Future Enhancements (v2+)

- Multiple managers support
- Calendar integration (sync with iOS Calendar)
- Siri Shortcuts
- Apple Watch companion app
- AI-powered suggestions for agenda items
- AI-assisted achievement writing
- Team view (for managers tracking their reports)
- Integration APIs (Slack, Teams, Notion)
- Competency framework templates
- Goal templates library

---

## Project Structure

```
OneToOneTrackeriOS/
├── App/
│   ├── OneToOneTrackerApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Manager.swift
│   ├── Meeting.swift
│   ├── AgendaItem.swift
│   ├── ActionItem.swift
│   ├── CareerGoal.swift
│   ├── Achievement.swift
│   ├── PerformanceReport.swift
│   └── Comment.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── ActionItemsListView.swift
│   │   ├── UpcomingMeetingCard.swift
│   │   └── CareerProgressCard.swift
│   ├── Preparation/
│   │   ├── AgendaBuilderView.swift
│   │   └── ShareAgendaView.swift
│   ├── Meeting/
│   │   ├── MeetingView.swift
│   │   ├── NotesSection.swift
│   │   ├── FeedbackSections.swift
│   │   └── SentimentPicker.swift
│   ├── ActionItems/
│   │   ├── ActionItemDetailView.swift
│   │   ├── ActionItemRow.swift
│   │   └── AddActionItemView.swift
│   ├── Career/
│   │   ├── CareerHomeView.swift
│   │   ├── GoalsListView.swift
│   │   ├── GoalDetailView.swift
│   │   ├── AddGoalView.swift
│   │   ├── AchievementsListView.swift
│   │   ├── AchievementDetailView.swift
│   │   ├── AddAchievementView.swift
│   │   ├── ReportBuilderView.swift
│   │   └── ReportPreviewView.swift
│   ├── History/
│   │   ├── MeetingHistoryView.swift
│   │   └── MeetingDetailView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── ProgressRing.swift
│       ├── SentimentPicker.swift
│       ├── TagsView.swift
│       └── EmptyStateView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── MeetingViewModel.swift
│   ├── ActionItemViewModel.swift
│   ├── CareerGoalsViewModel.swift
│   ├── AchievementsViewModel.swift
│   └── ReportViewModel.swift
├── Services/
│   ├── DataService.swift
│   ├── NotificationService.swift
│   ├── ExportService.swift
│   └── ReportGeneratorService.swift
├── Widgets/
│   ├── ActionItemsWidget.swift
│   ├── NextMeetingWidget.swift
│   ├── CareerGoalsWidget.swift
│   └── WidgetBundle.swift
├── Design/
│   ├── Theme.swift
│   ├── Colors.swift
│   ├── Typography.swift
│   └── Spacing.swift
├── Accessibility/
│   ├── AccessibilityModifiers.swift
│   └── AccessibilityIdentifiers.swift
├── Extensions/
│   ├── Date+Extensions.swift
│   ├── View+Accessibility.swift
│   └── Color+Contrast.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── UnitTests/
    ├── UITests/
    └── AccessibilityTests/
```

---

## Development Phases

### Phase 1: Foundation
- Project setup and architecture
- Design system (colors, typography, spacing)
- Data models with SwiftData
- Basic CRUD operations
- Home screen with dual navigation (1:1s + Career)

### Phase 2: Core Meeting Flow
- Pre-meeting agenda builder
- During-meeting view with all sections
- Action item capture
- Sentiment tracking

### Phase 3: Career Goals & Achievements
- Goals CRUD and management
- Achievements CRUD with goal linking
- Progress tracking and visualization
- Import achievements from meetings

### Phase 4: Sharing & Reports
- Copy to clipboard functionality
- Share sheet integration
- Formatted export for Slack/Teams
- Performance report generator
- PDF export

### Phase 5: Widgets
- Small, medium, large widgets
- Lock screen widgets
- Career goals widget
- Widget data refresh

### Phase 6: Polish & Accessibility
- Meeting history and analytics
- Notifications
- Settings and customization
- Full WCAG AA accessibility audit
- VoiceOver optimization
- Dynamic Type testing

### Phase 7: Testing & Launch
- Unit tests
- UI tests
- Accessibility tests
- Beta testing (include users with disabilities)
- App Store submission

---

## Success Metrics

- User can prepare for 1:1 in under 2 minutes
- Zero action items forgotten between meetings
- 100% of action items tracked to completion
- Seamless copy-to-Slack/Teams experience
- Widget usage for quick action item visibility
- Performance report generated in under 5 minutes
- Pass WCAG 2.1 AA automated and manual audits
- VoiceOver users can complete all core tasks
- App usable at all Dynamic Type sizes
