import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Timeline

struct Entry: TimelineEntry {
    let date: Date
    let state: NowPlaying?
    let artwork: NSImage?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, state: .placeholder, artwork: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(current(preview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let now = current(preview: false)
        guard let state = now.state, state.isPlaying, state.duration > 0, state.endDate > .now else {
            completion(Timeline(entries: [now], policy: .never))
            return
        }
        let step = max(2, state.duration / 100)
        let entries = stride(from: Date.now, through: state.endDate, by: step).map {
            Entry(date: $0, state: state, artwork: now.artwork)
        }
        completion(Timeline(entries: entries, policy: .never))
    }

    private func current(preview: Bool) -> Entry {
        let state = SharedStore.load()
        return Entry(
            date: .now,
            state: state ?? (preview ? .placeholder : nil),
            artwork: state == nil ? nil : NSImage(contentsOf: SharedStore.artworkURL)
        )
    }
}

// MARK: - Intents

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Oynat / Duraklat"

    func perform() async throws -> some IntentResult {
        if let state = SharedStore.load() { SharedStore.save(state.toggled()) }
        Command.playPause.post()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Sonraki Şarkı"

    func perform() async throws -> some IntentResult {
        Command.next.post()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Önceki Şarkı"

    func perform() async throws -> some IntentResult {
        Command.previous.post()
        return .result()
    }
}

struct SeekIntent: AppIntent {
    static let title: LocalizedStringResource = "Şarkıda Atla"

    @Parameter(title: "Konum (0–1)")
    var fraction: Double

    init() {}
    init(fraction: Double) { self.fraction = fraction }

    func perform() async throws -> some IntentResult {
        if var state = SharedStore.load() {
            state.position = fraction * state.duration
            state.updatedAt = .now
            SharedStore.save(state)
        }
        Command.seek.post(String(fraction))
        return .result()
    }
}

// MARK: - Views

struct SpotifyWidgetView: View {
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
        .environment(\.colorScheme, entry.artwork == nil ? colorScheme : .dark)
        .containerBackground(for: .widget) { background }
        .widgetURL(URL(string: "spotify:"))
    }

    @ViewBuilder
    private var background: some View {
        if let image = entry.artwork {
            ZStack {
                cover(image, fill: true)
                    .blur(radius: 40, opaque: true)
                    .saturation(1.3)
                Color.black.opacity(0.35)
            }
        } else {
            Rectangle().fill(.fill.tertiary)
        }
    }

    @ViewBuilder
    private func cover(_ image: NSImage, fill: Bool) -> some View {
        if #available(macOS 15.0, *) {
            Image(nsImage: image).resizable().widgetAccentedRenderingMode(.fullColor)
                .aspectRatio(contentMode: fill ? .fill : .fit)
        } else {
            Image(nsImage: image).resizable()
                .aspectRatio(contentMode: fill ? .fill : .fit)
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
                progress(state)
                controls(state).frame(maxWidth: .infinity)
            }
        }
    }

    private func large(_ state: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            artwork.frame(maxWidth: .infinity, alignment: .leading)
            titles(state)
            progress(state)
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
                cover(image, fill: false)
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

    private func progress(_ state: NowPlaying) -> some View {
        let live = state.isPlaying && state.duration > 0 && state.endDate > .now
        let elapsed = live ? entry.date.timeIntervalSince(state.startDate) : state.position
        let fraction = min(1, max(0, elapsed / max(state.duration, 1)))
        let segments = 20
        return VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(.primary).frame(width: geo.size.width * fraction)
                }
                .frame(height: 4)
                .frame(maxHeight: .infinity)
                .overlay {
                    HStack(spacing: 0) {
                        ForEach(0..<segments, id: \.self) { i in
                            Button(intent: SeekIntent(fraction: (Double(i) + 0.5) / Double(segments))) {
                                Color.clear.contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(height: 14)

            HStack(spacing: 0) {
                Group {
                    if live {
                        Text(timerInterval: state.startDate...state.endDate, countsDown: false)
                    } else {
                        Text(Self.time(state.position))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(Self.time(state.duration))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }

    private static func time(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.down)).formatted(.time(pattern: .minuteSecond))
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

// MARK: - Widget

@main
struct SpotifyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpotifyWidget", provider: Provider()) { entry in
            SpotifyWidgetView(entry: entry)
        }
        .configurationDisplayName("Spotify")
        .description("Çalan şarkı ve oynatma kontrolleri.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
