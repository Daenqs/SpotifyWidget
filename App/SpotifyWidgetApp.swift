import AppKit
import ServiceManagement
import WidgetKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let spotify = SpotifyController()

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? SMAppService.mainApp.register()

        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(spotifyChanged),
                           name: .init("com.spotify.client.PlaybackStateChanged"),
                           object: nil, suspensionBehavior: .deliverImmediately)
        for command in Command.allCases {
            center.addObserver(self, selector: #selector(commandReceived(_:)),
                               name: command.notification,
                               object: nil, suspensionBehavior: .deliverImmediately)
        }
        spotify.publishState()
    }

    @objc private func spotifyChanged() {
        spotify.publishState()
    }

    @objc private func commandReceived(_ notification: Notification) {
        guard let command = Command.allCases.first(where: { $0.notification == notification.name }) else { return }
        spotify.send(command, argument: notification.object as? String)
    }
}

final class SpotifyController {
    private var published: NowPlaying?
    private var artworkSource: String?

    private static let stateScript = NSAppleScript(source: """
        if application id "com.spotify.client" is running then
            tell application id "com.spotify.client"
                if player state is stopped then return {}
                set t to current track
                return {name of t, artist of t, album of t, (player state as text), duration of t, player position, artwork url of t}
            end tell
        end if
        return {}
        """)!

    func send(_ command: Command, argument: String? = nil) {
        let verb: String
        switch command {
        case .playPause: verb = "playpause"
        case .next: verb = "next track"
        case .previous: verb = "previous track"
        case .seek:
            guard let fraction = argument.flatMap(Double.init), (0...1).contains(fraction) else { return }
            verb = "set player position to (\(fraction) * (duration of current track) / 1000)"
        }
        var error: NSDictionary?
        NSAppleScript(source: "tell application id \"com.spotify.client\" to \(verb)")?.executeAndReturnError(&error)
        if let error { NSLog("Spotify komutu başarısız: \(error)") }
    }

    func publishState() {
        var error: NSDictionary?
        let result = Self.stateScript.executeAndReturnError(&error)
        if let error { NSLog("Spotify durumu okunamadı: \(error)") }

        guard error == nil, result.numberOfItems == 7 else {
            update(nil, artwork: nil)
            return
        }
        func text(_ i: Int) -> String { result.atIndex(i)?.stringValue ?? "" }
        func number(_ i: Int) -> Double { result.atIndex(i)?.doubleValue ?? 0 }

        let state = NowPlaying(
            title: text(1), artist: text(2), album: text(3),
            isPlaying: text(4) == "playing",
            duration: number(5) / 1000,
            position: number(6),
            updatedAt: .now
        )
        let artwork = text(7)
        guard artwork != artworkSource, let url = URL(string: artwork) else {
            update(state, artwork: nil)
            return
        }
        artworkSource = artwork
        URLSession.shared.dataTask(with: url) { data, response, _ in
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                guard self.artworkSource == artwork else { return }
                if !ok { self.artworkSource = nil }
                self.update(state, artwork: ok ? data : Data())
            }
        }.resume()
    }

    private func update(_ state: NowPlaying?, artwork: Data?) {
        if let artwork {
            if artwork.isEmpty {
                try? FileManager.default.removeItem(at: SharedStore.artworkURL)
            } else {
                try? artwork.write(to: SharedStore.artworkURL, options: .atomic)
            }
        }
        SharedStore.save(state)
        let changed = artwork != nil
            || (state == nil ? published != nil : !state!.sameTrackAndState(as: published))
            || Self.jumped(from: published, to: state)
        published = state
        if changed { WidgetCenter.shared.reloadAllTimelines() }
    }

    private static func jumped(from old: NowPlaying?, to new: NowPlaying?) -> Bool {
        guard let old, let new else { return false }
        let expected = old.isPlaying ? old.position + new.updatedAt.timeIntervalSince(old.updatedAt) : old.position
        return abs(expected - new.position) > 3
    }
}
