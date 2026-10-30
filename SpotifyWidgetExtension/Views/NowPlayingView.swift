import SwiftUI
import WidgetKit

struct NowPlayingView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let state = entry.state {
                switch family {
                case .systemSmall: small(state)
                case .systemLarge: large(state)
                default: medium(state)
                }
            } else {
                empty
            }
        }
        .environment(\.colorScheme, entry.background == nil ? colorScheme : .dark)
        .containerBackground(for: .widget) { background }
        .widgetURL(URL(string: "spotify:"))
    }

    @ViewBuilder
    private var background: some View {
        if let image = entry.background {
            ZStack {
                CoverImage(image: image, contentMode: .fill)
                Color.black.opacity(0.35)
            }
        } else {
            Rectangle().fill(.fill.tertiary)
        }
    }

    private func small(_ state: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                artwork.frame(width: 64, height: 64)
                Spacer()
                Button(intent: PlayPauseIntent()) {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 8)
            titles(state)
        }
    }

    private func medium(_ state: NowPlaying) -> some View {
        HStack(spacing: 14) {
            artwork
            VStack(alignment: .leading, spacing: 6) {
                titles(state)
                Spacer(minLength: 0)
                ProgressBar(state: state, date: entry.date)
                controls(state).frame(maxWidth: .infinity)
            }
        }
    }

    private func large(_ state: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            artwork.frame(maxWidth: .infinity, alignment: .leading)
            titles(state)
            ProgressBar(state: state, date: entry.date)
            controls(state).frame(maxWidth: .infinity)
        }
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Spotify'da çalan bir şey yok")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var artwork: some View {
        Group {
            if let image = entry.artwork {
                CoverImage(image: image, contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func titles(_ state: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.title)
                .font(.headline)
                .lineLimit(family == .systemSmall ? 2 : 1)
            Text(state.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func controls(_ state: NowPlaying) -> some View {
        HStack(spacing: 28) {
            Button(intent: PreviousTrackIntent()) { Image(systemName: "backward.fill") }
            Button(intent: PlayPauseIntent()) {
                Image(systemName: state.isPlaying ? "pause.fill" : "play.fill").font(.title2)
            }
            Button(intent: NextTrackIntent()) { Image(systemName: "forward.fill") }
        }
        .font(.title3)
        .buttonStyle(.plain)
    }
}
