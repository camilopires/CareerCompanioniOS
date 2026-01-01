import SwiftUI

struct WatchActionItemsView: View {
    @ObservedObject var viewModel: WatchHomeViewModel

    var body: some View {
        List {
            if viewModel.openActionItems.isEmpty {
                ContentUnavailableView(
                    "All Done!",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No open action items")
                )
            } else {
                ForEach(viewModel.openActionItems) { item in
                    ActionItemDetailRow(
                        item: item,
                        onComplete: {
                            Task {
                                await viewModel.completeActionItem(item)
                            }
                        }
                    )
                }
            }
        }
        .navigationTitle("Action Items")
    }
}

// MARK: - Action Item Detail Row

private struct ActionItemDetailRow: View {
    let item: ActionItem
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                priorityIndicator
                Text(item.title)
                    .font(.footnote)
                    .lineLimit(3)
            }

            HStack {
                if item.isOverdue {
                    Label("Overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if let dueDate = item.formattedDueDate {
                    Label(dueDate, systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onComplete) {
                    Label("Done", systemImage: "checkmark")
                        .font(.caption2)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var priorityIndicator: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 8, height: 8)
    }

    private var priorityColor: Color {
        switch item.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchActionItemsView(viewModel: WatchHomeViewModel())
    }
}
