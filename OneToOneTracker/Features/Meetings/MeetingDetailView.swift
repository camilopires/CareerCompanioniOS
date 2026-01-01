import SwiftUI

/// Detailed view of a past or scheduled meeting
struct MeetingDetailView: View {
    let meeting: Meeting

    @State private var showingActiveMeeting = false
    @State private var showingAgendaBuilder = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.sectionSpacing) {
                // Header card
                MeetingHeaderCard(meeting: meeting)

                if meeting.status == .completed {
                    // Completed meeting sections
                    CompletedMeetingContent(meeting: meeting)
                } else {
                    // Scheduled meeting actions
                    ScheduledMeetingActions(
                        meeting: meeting,
                        onStartMeeting: { showingActiveMeeting = true },
                        onPrepareAgenda: { showingAgendaBuilder = true }
                    )
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Colors.backgroundGrouped)
        .navigationTitle(meeting.status == .completed ? "Meeting Details" : "Upcoming 1:1")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingActiveMeeting) {
            NavigationStack {
                ActiveMeetingView(meeting: meeting)
            }
        }
        .sheet(isPresented: $showingAgendaBuilder) {
            NavigationStack {
                AgendaBuilderView(meeting: meeting)
            }
        }
    }
}

// MARK: - Header Card

private struct MeetingHeaderCard: View {
    let meeting: Meeting

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(meeting.formattedDate)
                            .font(Typography.title3)
                            .fontWeight(.semibold)

                        Label(meeting.status.displayName, systemImage: meeting.status.icon)
                            .font(Typography.callout)
                            .foregroundStyle(meeting.status.color)
                    }

                    Spacer()

                    // Sentiment if available
                    if let sentiment = meeting.meetingSentimentValue {
                        VStack(spacing: Spacing.xxs) {
                            Text(sentiment.emoji)
                                .font(.title)

                            Text("1:1 Rating")
                                .font(Typography.caption2)
                                .foregroundStyle(Colors.textTertiary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Scheduled Meeting Actions

private struct ScheduledMeetingActions: View {
    let meeting: Meeting
    let onStartMeeting: () -> Void
    let onPrepareAgenda: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {
            Button(action: onStartMeeting) {
                Label("Start Meeting", systemImage: "play.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button(action: onPrepareAgenda) {
                Label("Prepare Agenda", systemImage: "list.bullet.clipboard")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
}

// MARK: - Completed Meeting Content

private struct CompletedMeetingContent: View {
    let meeting: Meeting

    var body: some View {
        VStack(spacing: Spacing.sectionSpacing) {
            // Sentiments
            if meeting.weekSentiment != nil || meeting.meetingSentiment != nil {
                SentimentsCard(meeting: meeting)
            }

            // Notes
            if !meeting.notes.isEmpty {
                NotesCard(notes: meeting.notes)
            }

            // What went well
            if !meeting.wentWell.isEmpty {
                FeedbackCard(
                    title: "What Went Well",
                    icon: "hand.thumbsup.fill",
                    iconColor: Colors.success,
                    items: meeting.wentWell
                )
            }

            // What didn't go well
            if !meeting.didntGoWell.isEmpty {
                FeedbackCard(
                    title: "What Didn't Go Well",
                    icon: "hand.thumbsdown.fill",
                    iconColor: Colors.warning,
                    items: meeting.didntGoWell
                )
            }

            // Blockers
            if !meeting.blockers.isEmpty {
                FeedbackCard(
                    title: "Blockers",
                    icon: "exclamationmark.octagon.fill",
                    iconColor: Colors.error,
                    items: meeting.blockers
                )
            }

            // Escalations
            if !meeting.escalations.isEmpty {
                FeedbackCard(
                    title: "Escalations",
                    icon: "arrow.up.circle.fill",
                    iconColor: Colors.info,
                    items: meeting.escalations
                )
            }
        }
    }
}

// MARK: - Sentiments Card

private struct SentimentsCard: View {
    let meeting: Meeting

    var body: some View {
        Card {
            HStack(spacing: Spacing.xl) {
                if let weekSentiment = meeting.weekSentimentValue {
                    VStack(spacing: Spacing.xs) {
                        Text(weekSentiment.emoji)
                            .font(.title)

                        Text("Week")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                if let meetingSentiment = meeting.meetingSentimentValue {
                    VStack(spacing: Spacing.xs) {
                        Text(meetingSentiment.emoji)
                            .font(.title)

                        Text("1:1")
                            .font(Typography.caption1)
                            .foregroundStyle(Colors.textSecondary)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Notes Card

private struct NotesCard: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Notes", systemImage: "note.text")
                .font(Typography.headline)

            Card {
                Text(notes)
                    .font(Typography.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Feedback Card

private struct FeedbackCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: icon)
                .font(Typography.headline)
                .foregroundStyle(iconColor)

            Card {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Text("•")
                                .foregroundStyle(iconColor)

                            Text(item)
                                .font(Typography.body)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Meeting Detail - Completed") {
    let completedMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(-86400 * 7),
        status: .completed,
        notes: "Great discussion about Q4 priorities.",
        wentWell: ["Completed API migration", "Got positive feedback"],
        didntGoWell: ["Missed documentation deadline"],
        weekSentiment: 4,
        meetingSentiment: 5
    )
    return NavigationStack {
        MeetingDetailView(meeting: completedMeeting)
    }
}

#Preview("Meeting Detail - Scheduled") {
    let scheduledMeeting = Meeting(
        managerID: UUID(),
        date: Date().addingTimeInterval(86400 * 2)
    )
    return NavigationStack {
        MeetingDetailView(meeting: scheduledMeeting)
    }
}
