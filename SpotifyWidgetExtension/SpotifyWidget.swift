import SwiftUI
import WidgetKit

@main
struct SpotifyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpotifyWidget", provider: Provider()) { entry in
            NowPlayingView(entry: entry)
        }
        .configurationDisplayName("Spotify")
        .description("Now playing and playback controls.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
