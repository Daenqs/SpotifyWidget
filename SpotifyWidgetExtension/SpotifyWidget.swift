import SwiftUI
import WidgetKit

@main
struct SpotifyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpotifyWidget", provider: Provider()) { entry in
            NowPlayingView(entry: entry)
        }
        .configurationDisplayName("Spotify")
        .description("Çalan şarkı ve oynatma kontrolleri.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
