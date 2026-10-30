import SwiftUI
import WidgetKit

struct NowPlayingView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private static let logo = Bundle.main.url(forResource: "SpotifyLogo", withExtension: "png")
        .flatMap { NSImage(contentsOf: $0) }

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
                artwork(fill: false).frame(width: 64, height: 64)
                Spacer()
                logo
            }
            Spacer(minLength: 8)
            HStack(alignment: .bottom) {
                titles(state)
                Spacer(minLength: 4)
                Button(intent: PlayPauseIntent()) {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func medium(_ state: NowPlaying) -> some View {
        HStack(spacing: 14) {
            artwork(fill: false)
            VStack(alignment: .leading, spacing: 6) {
                header(state)
                Spacer(minLength: 0)
                ProgressBar(state: state, date: entry.date)
                controls(state).frame(maxWidth: .infinity)
            }
        }
    }

    private func large(_ state: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            artwork(fill: true)
            header(state)
            ProgressBar(state: state, date: entry.date)
            controls(state).frame(maxWidth: .infinity)
        }
    }

    private var empty: some View {
        VStack(spacing: 6) {
            Image(systemName: "music.note")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Nothing playing on Spotify")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var logo: some View {
        if let image = Self.logo {
            CoverImage(image: image, contentMode: .fit)
                .frame(width: 18, height: 18)
        }
    }

    private func artwork(fill: Bool) -> some View {
        Group {
            if let image = entry.artwork {
                if fill {
                    Color.clear.overlay { CoverImage(image: image, contentMode: .fill) }
                } else {
                    CoverImage(image: image, contentMode: .fit)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .aspectRatio(fill ? nil : 1, contentMode: .fit)
                    .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: fill ? 12 : 8))
    }

    private func header(_ state: NowPlaying) -> some View {
        HStack(alignment: .top, spacing: 6) {
            titles(state)
            Spacer(minLength: 0)
            logo
        }
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
