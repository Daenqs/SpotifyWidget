import SwiftUI

struct ProgressBar: View {
    let state: NowPlaying
    let date: Date

    private let segments = 20

    private var isLive: Bool {
        state.isPlaying && state.duration > 0 && state.endDate > .now
    }

    private var fraction: Double {
        let elapsed = isLive ? date.timeIntervalSince(state.startDate) : state.position
        return min(1, max(0, elapsed / max(state.duration, 1)))
    }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(.primary).frame(width: geo.size.width * fraction)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity)
                .overlay { seekTargets }
            }
            .frame(height: 14)

            HStack(spacing: 0) {
                elapsed.frame(maxWidth: .infinity, alignment: .leading)
                Text(Self.format(state.duration)).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
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
