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
        completion(Timeline(entries: [current(preview: false)], policy: .never))
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
