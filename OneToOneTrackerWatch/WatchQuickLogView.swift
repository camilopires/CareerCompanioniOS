import SwiftUI

struct WatchQuickLogView: View {
    @ObservedObject var viewModel: WatchHomeViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSentiment: Sentiment?
    @State private var showingConfirmation = false

    var body: some View {
        VStack(spacing: 16) {
            Text("How was your week?")
                .font(.headline)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                ForEach(Sentiment.allCases) { sentiment in
                    SentimentButton(
                        sentiment: sentiment,
                        isSelected: selectedSentiment == sentiment,
                        action: {
                            selectedSentiment = sentiment
                        }
                    )
                }
            }

            if selectedSentiment != nil {
                Button("Save") {
                    if let sentiment = selectedSentiment {
                        Task {
                            await viewModel.logSentiment(sentiment, for: nil)
                            showingConfirmation = true
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Log Sentiment")
        .alert("Saved!", isPresented: $showingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your sentiment has been logged.")
        }
    }
}

// MARK: - Sentiment Button

private struct SentimentButton: View {
    let sentiment: Sentiment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(sentiment.emoji)
                    .font(.title2)

                Text(sentiment.displayName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(width: 50, height: 50)
            .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WatchQuickLogView(viewModel: WatchHomeViewModel())
    }
}
