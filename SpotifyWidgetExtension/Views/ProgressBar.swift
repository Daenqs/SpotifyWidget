import SwiftUI

struct ProgressBar: View {
    let state: NowPlaying

    private let segments = 20

    private var isLive: Bool {
        state.isPlaying && state.duration > 0 && state.endDate > .now
    }

    private var fraction: Double {
        min(1, max(0, state.position / max(state.duration, 1)))
    }

    var body: some View {
        VStack(spacing: 3) {
            bar
                .tint(.primary)
                .frame(maxHeight: .infinity)
                .overlay { seekTargets }
                .frame(height: 14)

            HStack(spacing: 0) {
                elapsed.frame(maxWidth: .infinity, alignment: .leading)
                Text(Self.format(state.duration)).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    // The system animates a timer-driven bar on its own, so the timeline needs a single entry.
    @ViewBuilder
    private var bar: some View {
        if isLive {
            ProgressView(timerInterval: state.startDate...state.endDate, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
        } else {
            ProgressView(value: fraction)
        }
    }

    @ViewBuilder
    private var elapsed: some View {
        if isLive {
            Text(timerInterval: state.startDate...state.endDate, countsDown: false)
        } else {
            Text(Self.format(state.position))
        }
    }

    private var seekTargets: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments, id: \.self) { i in
                Button(intent: SeekIntent(fraction: (Double(i) + 0.5) / Double(segments))) {
                    Color.clear.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private static func format(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.down)).formatted(.time(pattern: .minuteSecond))
    }
}
