# OneToOne Tracker - Monetization Strategy

## Overview

This document outlines the monetization strategy for OneToOne Tracker iOS app.

---

## Pricing Model

### Free + Premium (£20 Lifetime) with 1-Month Free Trial

**Chosen Approach**: Option C - Power Features (Clean Split)

The free tier provides a genuinely useful core experience, while premium unlocks professional/power features that serious users will value.

---

## Tier Breakdown

### Free Tier

Core meeting flow that's genuinely useful for casual 1:1 tracking:

| Feature | Details |
|---------|---------|
| **People** | 1 manager OR 1 direct report |
| **Meetings** | Unlimited with single person |
| **Meeting History** | Last 10 meetings visible |
| **Agenda Builder** | Full access |
| **Notes & Feedback** | What went well, didn't go well, blockers, escalations |
| **Action Items** | Up to 10 active items |
| **Sentiment Tracking** | Week and meeting sentiment |
| **Career Goals** | Up to 3 active goals |
| **Achievements** | View and create (up to 5) |
| **Demo Mode** | Full access |
| **Basic Widget** | Small widget only |
| **Siri Shortcuts** | "When is my next 1:1?" only |

### Premium Tier (£20 Lifetime)

Everything in Free, PLUS professional features for power users:

| Feature | Details |
|---------|---------|
| **Unlimited People** | Multiple managers, reports, mentors, peers, etc. |
| **Full Meeting History** | All meetings, forever |
| **Unlimited Action Items** | No limits |
| **Unlimited Career Goals** | No limits |
| **Unlimited Achievements** | No limits |
| **Weekly Goals & Metrics** | This week's goals, progress updates, key metrics, next week's goals |
| **Performance Reports** | Full report generator with PDF/Markdown export |
| **AI Suggestions** | Smart agenda suggestions (iOS 18+) |
| **Apple Watch App** | Full companion app access |
| **All Widgets** | Small, medium, large, lock screen |
| **All Siri Shortcuts** | Full shortcut library |
| **Calendar Sync** | EventKit integration |
| **Export/Import** | Full JSON/CSV backup and restore |
| **Custom Types** | Custom relationship and meeting types |
| **Relationship Filters** | Filter by relationship type |

---

## Trial Period

- **Duration**: 1 month (30 days)
- **Access**: Full premium features
- **Activation**: Automatic on first launch (no credit card required)
- **End of Trial**: Graceful downgrade to free tier with data preserved
- **Re-trial**: Not available (one trial per Apple ID)

---

## Pricing Rationale

### Why £20 Lifetime?

1. **Impulse Buy Territory**: Low enough for immediate decision without overthinking
2. **No Subscription Fatigue**: Users own it forever, no recurring guilt
3. **Professional Value**: Worth it for anyone who has regular 1:1s
4. **Competitive**: Most productivity apps charge £3-5/month (£36-60/year)
5. **Simple**: One price, one decision, forever access

### Why Not Subscription?

- Target users already have subscription fatigue
- 1:1 tracking is a "set and forget" tool, not daily active usage
- Lifetime creates goodwill and word-of-mouth
- Lower support burden (no billing issues)

---

## Feature Gating Strategy

### Soft Limits (Show Upgrade Prompt)

These features show an upgrade prompt but don't hard-block:

- Adding 2nd person → "Upgrade to add unlimited people"
- Creating 11th action item → "Upgrade for unlimited action items"
- Creating 4th career goal → "Upgrade for unlimited goals"
- Viewing 11th+ meeting in history → "Upgrade for full history"

### Hard Limits (Premium Only)

These features are completely locked in free tier:

- Weekly goals/metrics sections (hidden in meeting view)
- Performance report generator (locked behind paywall)
- AI suggestions (premium badge)
- Apple Watch app (shows upgrade prompt)
- Medium/Large widgets (shows upgrade in widget gallery)
- Calendar sync (locked in settings)
- Export/Import (locked in settings)
- Custom types (locked in settings)

### Graceful Degradation

When trial ends or user doesn't upgrade:

- Existing data is preserved (never deleted)
- Extra people become read-only (can view, not add meetings)
- Extra action items become read-only
- Extra goals become read-only
- Meeting history truncated in list view (data still exists)

---

## Technical Implementation

### StoreKit 2 Integration

```swift
// Product IDs
static let premiumLifetime = "com.onetoonetracker.premium.lifetime"

// Entitlements
enum Entitlement: String {
    case premium = "premium"
}
```

### Subscription Manager

```swift
@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var trialDaysRemaining: Int = 0

    // Check entitlement status
    // Handle purchases
    // Manage trial period
    // Restore purchases
}
```

### Feature Flags

```swift
extension AppSettings {
    var canAddMorePeople: Bool { isPremium || peopleCount < 1 }
    var canAddMoreActionItems: Bool { isPremium || activeActionItemCount < 10 }
    var canAddMoreGoals: Bool { isPremium || activeGoalCount < 3 }
    var canAccessWeeklyGoals: Bool { isPremium }
    var canAccessReports: Bool { isPremium }
    var canAccessWatch: Bool { isPremium }
    var canAccessCalendarSync: Bool { isPremium }
    var canExportData: Bool { isPremium }
    var canUseCustomTypes: Bool { isPremium }
}
```

---

## UI/UX for Monetization

### Upgrade Prompts

- **Non-intrusive**: Never interrupt active workflows
- **Contextual**: Show when user hits a limit naturally
- **Value-focused**: Explain what they'll get, not what they're missing
- **Dismissible**: Always allow user to continue in free tier

### Premium Badge

- Subtle crown/star icon on premium features
- Consistent visual language throughout app
- Tap to see upgrade screen

### Upgrade Screen

- Hero section with key benefits
- Feature comparison table
- Price prominently displayed
- "Restore Purchase" link
- Trial status (if applicable)

### Settings Integration

- "OneToOne Premium" section in Settings
- Current status (Free/Trial/Premium)
- Trial days remaining (if applicable)
- Upgrade button (if not premium)
- Restore purchases
- Manage subscription (links to App Store)

---

## Analytics & Metrics

### Track These Events

- Trial started
- Trial expired
- Upgrade prompt shown (which feature triggered it)
- Upgrade prompt dismissed
- Purchase initiated
- Purchase completed
- Purchase failed
- Restore initiated
- Restore completed

### Success Metrics

- Trial-to-paid conversion rate (target: 10-15%)
- Upgrade prompt-to-purchase rate
- Feature usage in trial vs post-trial
- Churn rate (users who stop using after trial)

---

## App Store Considerations

### Pricing

- UK: £19.99 (displayed as £20)
- US: $24.99
- EU: €24.99
- Other regions: Apple's automatic conversion

### App Store Description

Highlight both free and premium value:
- "Free: Track 1:1s with your manager, action items, and career goals"
- "Premium: Unlimited people, performance reports, Apple Watch, and more"

### Screenshots

- Show premium features with subtle "Premium" badges
- Include upgrade screen in screenshot set

---

## Future Considerations

### Potential Add-ons (v3.0+)

- Team/Enterprise tier (shared team goals, manager dashboard)
- Notion/Slack integration (separate IAP?)
- Custom themes/icons (cosmetic IAP?)

### Price Adjustments

- Monitor conversion rates
- Consider regional pricing
- Holiday promotions (30% off?)
- Launch promotion (50% off first month?)

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| 2024-01-01 | 1.0 | Initial monetization strategy (Option C selected) |
