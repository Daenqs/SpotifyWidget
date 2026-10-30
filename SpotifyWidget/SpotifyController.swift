import AppKit
import WidgetKit

final class SpotifyController {
    private var published: NowPlaying?
    private var artworkSource: String?
    private var pendingArtwork: String?
    private var artworkCache: [String: (image: Data, background: Data?)] = [:]

    private static let stateScript = compiled("""
        if application id "com.spotify.client" is running then
            tell application id "com.spotify.client"
                if player state is stopped then return {}
                set t to current track
                return {name of t, artist of t, album of t, (player state as text), duration of t, player position, artwork url of t}
            end tell
        end if
        return {}
        """)

    private static let commandScripts: [Command: NSAppleScript] = [
        .playPause: spotify("playpause"),
        .next: spotify("next track"),
        .previous: spotify("previous track"),
    ]

    func send(_ command: Command, argument: String? = nil) {
        let script: NSAppleScript
        if command == .seek {
            guard let fraction = argument.flatMap(Double.init), (0...1).contains(fraction) else { return }
            script = Self.spotify("set player position to (\(fraction) * (duration of current track) / 1000)")
        } else {
            guard let cached = Self.commandScripts[command] else { return }
            script = cached
        }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error { NSLog("Spotify command failed: \(error)") }
    }

    func publishState() {
        var error: NSDictionary?
        let result = Self.stateScript.executeAndReturnError(&error)
        if let error { NSLog("Couldn't read Spotify state: \(error)") }

        guard error == nil, result.numberOfItems == 7 else {
            artworkSource = nil
            pendingArtwork = nil
            update(nil, artwork: .remove)
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
        if artwork == artworkSource {
            update(state, artwork: .unchanged)
        } else if let cached = artworkCache[artwork] {
            artworkSource = artwork
            update(state, artwork: .replace(cached.image, background: cached.background))
        } else if !artwork.isEmpty, let url = URL(string: artwork) {
            guard artwork != pendingArtwork else { return }
            pendingArtwork = artwork
            download(url, key: artwork)
        } else {
            artworkSource = artwork
            update(state, artwork: .remove)
        }
    }

    private func download(_ url: URL, key: String) {
        URLSession.shared.dataTask(with: url) { data, response, _ in
            let image = (response as? HTTPURLResponse)?.statusCode == 200 ? data : nil
            let background = image.flatMap(BackgroundRenderer.render)
            DispatchQueue.main.async {
                guard self.pendingArtwork == key else { return }
                self.pendingArtwork = nil
                if let image {
                    if self.artworkCache.count >= 20 { self.artworkCache.removeAll() }
                    self.artworkCache[key] = (image, background)
                } else {
                    self.artworkSource = key
                    SharedStore.saveArtwork(nil, background: nil)
                }
                self.publishState()
            }
        }.resume()
    }

    private enum ArtworkChange {
        case unchanged
        case remove
        case replace(Data, background: Data?)
    }

    private func update(_ state: NowPlaying?, artwork: ArtworkChange) {
        let artworkChanged: Bool
        switch artwork {
        case .unchanged:
            artworkChanged = false
        case .remove:
            artworkChanged = true
            SharedStore.saveArtwork(nil, background: nil)
        case let .replace(image, background):
            artworkChanged = true
            SharedStore.saveArtwork(image, background: background)
        }
        SharedStore.save(state)

        let stateChanged = state.map { !$0.sameTrackAndState(as: published) } ?? (published != nil)
        let changed = artworkChanged || stateChanged || Self.jumped(from: published, to: state)
        published = state
        if changed { WidgetCenter.shared.reloadAllTimelines() }
    }

    private static func jumped(from old: NowPlaying?, to new: NowPlaying?) -> Bool {
        guard let old, let new else { return false }
        let expected = old.isPlaying ? old.position + new.updatedAt.timeIntervalSince(old.updatedAt) : old.position
        return abs(expected - new.position) > 3
    }

    private static func spotify(_ statement: String) -> NSAppleScript {
        compiled("tell application id \"com.spotify.client\" to \(statement)")
    }

    private static func compiled(_ source: String) -> NSAppleScript {
        let script = NSAppleScript(source: source)!
        var error: NSDictionary?
        script.compileAndReturnError(&error)
        return script
    }
}
