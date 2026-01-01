# OneToOne Tracker

A native iOS app for tracking 1:1 meetings with managers and career goals. Built with SwiftUI and CloudKit for secure, private data storage in your personal iCloud account.

![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)
![CloudKit](https://img.shields.io/badge/Storage-CloudKit-green)
![watchOS 10+](https://img.shields.io/badge/watchOS-10%2B-red)
![WCAG AA](https://img.shields.io/badge/Accessibility-WCAG%20AA-brightgreen)

---

## Overview

OneToOne Tracker helps employees prepare for, conduct, and follow up on 1:1 meetings with their managers while tracking career goals and achievements for performance reviews. Your data is stored securely in your personal iCloud account and is never shared with anyone.

### Key Features

- **1:1 Meeting Management** - Prepare agendas, capture notes, track action items
- **Flexible Relationships** - Track 1:1s with managers, mentors, peers, stakeholders, or any custom relationship type
- **User-Defined Types** - Create custom relationship types and meeting types to fit your workflow
- **IC & Manager Modes** - Switch between tracking meetings with your manager or your direct reports
- **Multiple Managers/Reports** - Track 1:1s with multiple people, filter by relationship type
- **Demo Mode** - Explore the app with sample data before starting fresh
- **Career Goals Tracking** - Set goals, track progress, record achievements
- **Performance Reports** - Generate reports for performance reviews
- **Calendar Integration** - Sync meetings to your iOS calendar via EventKit
- **Siri Shortcuts** - "When is my next 1:1?", "Add action item", and more
- **Apple Watch App** - View meetings, complete action items, log sentiment from your wrist
- **AI Suggestions** - Smart agenda suggestions based on meeting history (iOS 18+)
- **Data Export/Import** - Full backup to JSON/CSV, restore from backup
- **iOS Widgets** - Quick access to action items and upcoming meetings
- **Export & Share** - Copy agendas to Slack, Teams, or email

---

## Screenshots

| Home | Meetings | Career Goals |
|------|----------|--------------|
| Dashboard with action items and upcoming 1:1 | Active meeting with agenda and notes | Goals progress and achievements |

---

## Features

### Home Dashboard

- **Two Main Entry Points**: 1:1 Meetings and Career Goals
- **Action Items Overview**: Prioritized list with quick-complete actions
- **Upcoming 1:1 Card**: Countdown to next meeting with agenda preview
- **Career Progress Snapshot**: Active goals and recent achievements
- **Quick Stats**: Open items, completed this week, goals progress

### 1:1 Meetings

#### Pre-Meeting Preparation
- Create and reorder agenda items with drag-and-drop
- Auto-populate from incomplete action items
- Export agenda to Slack, Teams, or email
- One-tap copy to clipboard

#### During Meeting
- Interactive agenda with checkboxes
- Meeting timer
- Weekly planning sections (optional):
  - This Week's Goals (auto-populated from previous meeting)
  - Progress Updates
  - Key Metrics (carries over between meetings)
  - Next Week's Goals (carries to next meeting)
- Structured feedback sections:
  - What Went Well
  - What Didn't Go Well
  - Blockers
  - Escalations
- Quick-add action items with owner and due date
- Sentiment tracking (week and meeting ratings)

#### Action Items
- Title, description, due date, priority
- Owner assignment (self or manager)
- Status tracking (open, in progress, completed)
- Links and comments
- Automatic carry-over to next meeting

### Career Goals & Achievements

#### Goals Management
- Categories: Technical, Leadership, Communication, Domain Knowledge
- Progress tracking with visual indicators
- Target dates and milestones
- Success metrics and tracking methods
- Priority ordering (primary/secondary)

#### Achievements
- Link achievements to goals
- Impact statements with evidence
- Import from "What Went Well" sections
- Visibility settings (private, manager, public)

#### Performance Reports
- Select date range (quarter, half-year, year, custom)
- Choose goals and achievements to include
- Generate formatted reports
- Export as PDF, Markdown, or plain text
- Share via email, Slack, or Teams

### iOS Widgets

| Widget | Sizes | Features |
|--------|-------|----------|
| **Action Items** | Small, Medium, Large | Open items count, top items list, overdue alerts |
| **Next Meeting** | Small, Lock Screen | Countdown, manager name, date/time |
| **Career Goals** | Medium | Active goals with progress rings |

---

## Architecture

### Tech Stack

- **iOS 18+** minimum deployment target
- **watchOS 10+** for Apple Watch companion app
- **Swift 5.9+**
- **SwiftUI** for all UI components
- **CloudKit** for secure iCloud storage
- **StoreKit 2** for in-app purchases
- **EventKit** for calendar integration
- **App Intents** for Siri Shortcuts
- **WidgetKit** for home screen widgets
- **MVVM** architecture pattern

### Data Privacy

All data is stored in CloudKit's **private database**, which means:
- Data is encrypted in your personal iCloud account
- Never shared with the app developer or third parties
- Automatically syncs across all your Apple devices
- Persists even if the app is deleted

### Project Structure

```
OneToOneTracker/
├── OneToOneTrackerApp.swift          # App entry point
├── Core/
│   ├── CloudKit/
│   │   ├── CloudKitManager.swift     # CloudKit operations
│   │   └── CloudKitRecordable.swift  # Protocol for models
│   ├── DemoData/
│   │   └── DemoDataProvider.swift    # In-memory demo data
│   ├── Intents/
│   │   ├── AppIntents.swift          # Siri Shortcuts definitions
│   │   └── ShortcutsManager.swift    # Shortcut donations
│   ├── Models/
│   │   ├── AppSettings.swift         # App settings (demo mode, user role, premium)
│   │   ├── Enums.swift               # Status, Priority, etc.
│   │   ├── PremiumFeatures.swift     # Free tier limits, feature flags
│   │   ├── Manager.swift
│   │   ├── Meeting.swift
│   │   ├── AgendaItem.swift
│   │   ├── ActionItem.swift
│   │   ├── CareerGoal.swift
│   │   └── Achievement.swift
│   └── Services/
│       ├── AIManager.swift           # AI suggestions (iOS 18+)
│       ├── CalendarManager.swift     # EventKit integration
│       ├── ExportImportService.swift # Data export/import
│       └── SubscriptionManager.swift # StoreKit 2 integration
├── Design/
│   ├── Colors.swift                  # WCAG AA color palette
│   ├── Typography.swift              # Dynamic Type support
│   ├── Spacing.swift                 # 8pt grid system
│   ├── Theme.swift                   # Button styles, etc.
│   └── Components/
│       ├── Card.swift
│       ├── EmptyState.swift
│       ├── ProgressRing.swift
│       └── SentimentPicker.swift
├── Features/
│   ├── Home/
│   ├── Meetings/
│   ├── ActionItems/
│   ├── Career/
│   ├── Premium/
│   │   ├── UpgradeView.swift         # Full upgrade screen
│   │   └── UpgradePromptSheet.swift  # Contextual upgrade prompts
│   ├── People/
│   │   ├── PeopleListView.swift      # Standalone people list
│   │   ├── AddPersonView.swift       # Add person form with callback
│   │   └── PersonRow.swift           # Reusable person row component
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── PremiumSettingsSection.swift
│   │   ├── ManageTypesView.swift
│   │   ├── ExportView.swift
│   │   └── ImportView.swift
│   └── Onboarding/
├── OneToOneTrackerWidget/
│   ├── ActionItemsWidget.swift
│   ├── NextMeetingWidget.swift
│   ├── CareerGoalsWidget.swift
│   └── WidgetBundle.swift
└── OneToOneTrackerWatch/             # Apple Watch App
    ├── OneToOneTrackerWatchApp.swift
    ├── WatchHomeView.swift
    ├── WatchHomeViewModel.swift
    ├── WatchMeetingDetailView.swift
    ├── WatchActionItemsView.swift
    └── WatchQuickLogView.swift
```

### Data Models

```
Manager (Person)
├── id, name, email
├── relationshipType (My Manager, Direct Report, Mentor, Peer, custom...)
├── tags (optional filtering tags)
└── createdAt

Meeting
├── id, date, status, perspective
├── meetingType (1:1, Career Development, Project Sync, custom...)
├── agendaItems, notes
├── thisWeekGoals, thisWeekProgress, keyMetrics, nextWeekGoals
├── wentWell, didntGoWell, blockers, escalations
├── weekSentiment, meetingSentiment
└── actionItems

ActionItem
├── id, title, description
├── dueDate, priority, status, owner
├── links, comments
└── sourceMeeting

CareerGoal
├── id, title, description, category
├── targetDate, status, priority
├── successMetrics, trackingMethod
├── progress (0-100%)
└── achievements

Achievement
├── id, title, description
├── dateAchieved, impactStatement
├── linkedGoals, evidenceLinks
├── tags, visibility
└── sourceMeeting
```

---

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 18.0+ device or simulator
- watchOS 10.0+ simulator (for Watch app testing)
- Apple Developer account (for CloudKit)
- iCloud account signed in on device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/camilopires/OneToOneTrackeriOS.git
   cd OneToOneTrackeriOS
   ```

2. **Open in Xcode**
   ```bash
   open OneToOneTracker.xcodeproj
   ```

3. **Configure Signing**
   - Select the project in the navigator
   - Go to Signing & Capabilities
   - Select your Development Team for all targets:
     - `OneToOneTracker`
     - `OneToOneTrackerWidgetExtension`
     - `OneToOneTrackerWatch`

4. **Update Bundle Identifiers** (optional)
   - Default: `com.onetoonetracker.app`
   - Widget: `com.onetoonetracker.app.widget`
   - Watch: `com.onetoonetracker.app.watch`

5. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Demo Mode

OneToOne Tracker includes a Demo Mode that lets you explore the app with sample data before committing to your own data:

1. **During Onboarding**: After the welcome slides, demo mode activates automatically
2. **Explore with Sample Data**: Navigate through meetings, action items, and career goals
3. **Start Fresh**: Tap "Start Fresh" in the bottom sheet to begin with your own data
4. **Re-enable Anytime**: Toggle demo mode on/off in Settings

Demo data is stored in-memory only and is never saved to your iCloud account.

### CloudKit Setup

On first run, Xcode will automatically:
- Create the CloudKit container in your iCloud account
- Set up the required record types
- Configure subscriptions for sync

---

## Accessibility

This app is designed to meet **WCAG 2.1 AA** standards:

### Visual
- **Color Contrast**: All text meets 4.5:1 minimum ratio
- **Dynamic Type**: Full support for all text sizes
- **Dark Mode**: Complete dark mode support
- **Color Independence**: Information not conveyed by color alone

### Motor
- **Touch Targets**: Minimum 44x44pt touch areas
- **Keyboard Navigation**: Full external keyboard support
- **Reduce Motion**: Respects system motion preferences

### Screen Reader
- **VoiceOver**: All elements have accessibility labels
- **Accessibility Hints**: Complex interactions explained
- **Logical Reading Order**: Content flows naturally
- **Custom Actions**: Swipe actions have alternatives

---

## Design System

### Colors

| Color | Usage | Light | Dark |
|-------|-------|-------|------|
| Primary | Actions, links | Blue | Light Blue |
| Success | Completed, positive | Green | Green |
| Warning | Attention needed | Orange | Orange |
| Error | Overdue, failures | Red | Red |

### Typography

Uses San Francisco (system font) with Dynamic Type:
- Large Title: Navigation headers
- Title 1-3: Section headers
- Headline: Card titles
- Body: Primary content
- Caption: Metadata, timestamps

### Spacing

8pt grid system with consistent values:
- `xxs`: 4pt
- `xs`: 8pt
- `sm`: 12pt
- `md`: 16pt
- `lg`: 24pt
- `xl`: 32pt
- `xxl`: 48pt

---

## Export Formats

### Agenda Export
- **Slack**: Formatted with emoji and markdown
- **Teams**: Microsoft Teams compatible
- **Email**: Clean plain text
- **Markdown**: Full markdown formatting

### Report Export
- **PDF**: Formatted, printable document
- **Markdown**: For documentation systems
- **Plain Text**: Universal compatibility

---

## Widgets

### Adding Widgets

1. Long press on home screen
2. Tap the `+` button
3. Search for "1:1 Tracker"
4. Choose widget size and add

### Available Widgets

| Widget | Size | Description |
|--------|------|-------------|
| Action Items | Small | Count of open items |
| Action Items | Medium | Top 3 items with overdue count |
| Action Items | Large | Full list with details |
| Next Meeting | Small | Countdown with date |
| Next Meeting | Circular | Days until meeting |
| Next Meeting | Rectangular | Date and manager name |
| Career Goals | Medium | Progress rings and goal list |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## Roadmap

### v1.0
- [x] 1:1 Meeting management
- [x] Action items tracking
- [x] Career goals and achievements
- [x] Performance report generation
- [x] iOS widgets
- [x] Export to Slack/Teams

### v2.0
- [x] Demo Mode for onboarding exploration
- [x] IC/Manager mode switching
- [x] Multiple people support (managers or direct reports)

### v2.1
- [x] Multiple managers filtering
- [x] Calendar integration (EventKit)
- [x] Siri Shortcuts (App Intents)
- [x] Apple Watch companion app
- [x] AI-powered suggestions (iOS 18+)
- [x] Data export/import (JSON/CSV)
- [x] Enhanced team view for managers

### v2.2
- [x] Flexible relationship types (My Manager, Direct Report, Mentor, Peer, Stakeholder, custom)
- [x] User-defined meeting types (1:1, Career Development, Project Sync, custom)
- [x] Manage Types settings screen for custom types
- [x] "Other 1:1s" section on dashboards for non-manager/report meetings
- [x] Relationship type filter in meetings list
- [x] Meeting type badges on meeting cards

### v2.3
- [x] Weekly goals tracking with auto-carry-over from previous meeting
- [x] Progress updates section for ongoing work
- [x] Key metrics tracking that persists across meetings
- [x] Next week's goals that carry forward automatically
- [x] All new sections are optional - use what's relevant

### v2.4
- [x] **Premium Monetization** - Freemium model with StoreKit 2
  - Free tier: 1 person, 10 action items, 3 goals, 5 achievements
  - Premium (£19.99 lifetime): Unlimited everything + power features
  - 30-day free trial for new users
- [x] **Premium-Only Features**
  - Weekly goals & metrics tracking
  - Performance reports
  - AI suggestions
  - Calendar sync
  - Data export/import
  - Custom types
  - Apple Watch app
- [x] **Upgrade Experience**
  - Upgrade prompts when hitting limits
  - Full upgrade view with feature showcase
  - Restore purchases support
  - Premium status in Settings

### v2.5 (Current)
- [x] **People Quick Access** - Manage people directly from dashboards
  - "Add Your First Person" button when no people exist (no more "Go to Settings")
  - "Add a new person" option at top of person picker when scheduling meetings
  - Auto-select newly added person in meeting creation flow
  - Standalone People views extracted for reuse across the app
- [x] **Improved UX Flow**
  - Tappable empty states that open AddPersonView directly
  - Seamless person creation during meeting scheduling

### Future
- [ ] Integration APIs (Slack, Teams, Notion)
- [ ] Competency framework templates
- [ ] Goal templates library
- [ ] Watch complications

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Built with SwiftUI and CloudKit
- Icons from SF Symbols
- Accessibility guidelines from WCAG 2.1

---

## Support

- **Issues**: [GitHub Issues](https://github.com/camilopires/OneToOneTrackeriOS/issues)
- **Discussions**: [GitHub Discussions](https://github.com/camilopires/OneToOneTrackeriOS/discussions)
