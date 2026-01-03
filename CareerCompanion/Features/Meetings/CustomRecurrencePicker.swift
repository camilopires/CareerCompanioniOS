import SwiftUI

/// Custom recurrence picker like Google Calendar
/// Allows setting frequency, interval, and weekday for weekly meetings
struct CustomRecurrencePicker: View {
    @Binding var rule: RecurrenceRule

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Row 1: "Every [X] [weeks/days/months]"
            HStack {
                Text("Every")
                    .foregroundStyle(Colors.textSecondary)

                // Interval stepper
                HStack(spacing: 0) {
                    Button {
                        if rule.interval > 1 {
                            rule.interval -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 32, height: 32)
                            .background(Colors.backgroundSecondary)
                    }
                    .buttonStyle(.plain)

                    Text("\(rule.interval)")
                        .font(Typography.headline)
                        .frame(width: 40)
                        .multilineTextAlignment(.center)

                    Button {
                        if rule.interval < 52 {
                            rule.interval += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 32, height: 32)
                            .background(Colors.backgroundSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Colors.separator, lineWidth: 1)
                )

                // Frequency picker
                Picker("", selection: $rule.frequency) {
                    ForEach(RecurrenceRule.Frequency.allCases) { freq in
                        Text(rule.interval == 1 ? freq.displayName : freq.pluralName)
                            .tag(freq)
                    }
                }
                .pickerStyle(.menu)
                .tint(Colors.textPrimary)
            }

            // Row 2: Weekday selector (only for weekly frequency)
            if rule.frequency == .weekly {
                HStack {
                    Text("On")
                        .foregroundStyle(Colors.textSecondary)

                    Picker("", selection: $rule.weekday) {
                        Text("Same day as meeting")
                            .tag(nil as RecurrenceRule.Weekday?)

                        Divider()

                        ForEach(RecurrenceRule.Weekday.allCases) { day in
                            Text(day.fullName)
                                .tag(day as RecurrenceRule.Weekday?)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Colors.textPrimary)
                }
            }

            // Preview text
            HStack {
                Image(systemName: "repeat")
                    .foregroundStyle(Colors.textTertiary)
                Text(rule.displayText)
                    .font(Typography.callout)
                    .foregroundStyle(Colors.textSecondary)
            }
            .padding(.top, Spacing.xs)
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Recurrence Picker Section

/// Complete recurrence picker with presets and custom option
struct RecurrencePickerSection: View {
    @Binding var recurrence: RecurrenceRule?
    @State private var selectedPreset: RecurrencePreset = .none
    @State private var customRule: RecurrenceRule = .weekly

    var body: some View {
        Section {
            // Preset picker
            Picker("Repeats", selection: $selectedPreset) {
                ForEach(RecurrencePreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .onChange(of: selectedPreset) { _, newValue in
                switch newValue {
                case .none:
                    recurrence = nil
                case .weekly:
                    recurrence = .weekly
                case .biweekly:
                    recurrence = .biweekly
                case .monthly:
                    recurrence = .monthly
                case .custom:
                    recurrence = customRule
                }
            }

            // Custom picker (shown when custom is selected)
            if selectedPreset == .custom {
                CustomRecurrencePicker(rule: $customRule)
                    .onChange(of: customRule) { _, newRule in
                        recurrence = newRule
                    }
            }
        } header: {
            Text("Repeat")
        }
        .onAppear {
            // Initialize preset from existing recurrence
            selectedPreset = RecurrencePreset.from(rule: recurrence)
            if let rule = recurrence, selectedPreset == .custom {
                customRule = rule
            }
        }
    }
}

// MARK: - Preview

#Preview("Custom Picker") {
    struct PreviewWrapper: View {
        @State private var rule = RecurrenceRule.biweekly

        var body: some View {
            Form {
                Section("Custom Recurrence") {
                    CustomRecurrencePicker(rule: $rule)
                }
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Full Picker Section") {
    struct PreviewWrapper: View {
        @State private var recurrence: RecurrenceRule? = nil

        var body: some View {
            Form {
                RecurrencePickerSection(recurrence: $recurrence)

                if let rule = recurrence {
                    Section("Result") {
                        Text(rule.displayText)
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
