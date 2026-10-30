import AppKit
import WidgetKit

struct Entry: TimelineEntry {
    let date: Date
    let state: NowPlaying?
    let artwork: NSImage?
    let background: NSImage?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: .now, state: .placeholder, artwork: nil, background: nil)
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
            Entry(date: $0, state: state, artwork: now.artwork, background: now.background)
        }
        completion(Timeline(entries: entries, policy: .never))
    }

    private func current(preview: Bool) -> Entry {
        guard let state = SharedStore.load() else {
            return Entry(date: .now, state: preview ? .placeholder : nil, artwork: nil, background: nil)
        }
        return Entry(
            date: .now,
            state: state,
            artwork: NSImage(contentsOf: SharedStore.artworkURL),
            background: NSImage(contentsOf: SharedStore.backgroundURL)
        )
    }
}
