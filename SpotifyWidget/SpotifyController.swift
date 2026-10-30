import AppKit
import OSLog
import WidgetKit

@MainActor
final class SpotifyController {
    private struct Snapshot {
        var state: NowPlaying
        var trackID: String?
        var artworkURL: String?
    }

    private enum ArtworkChange {
        case unchanged
        case remove
        case replace(Data, background: Data?)
    }

    private let log = Logger(subsystem: "spotifywidget", category: "spotify")
    private let session = URLSession(configuration: .ephemeral)

    private var published: NowPlaying?
    private var artworkSource: String?
    private var knownArtwork: (trackID: String, url: String)?
    private var pendingArtwork: String?
    private var pendingState: NowPlaying?
    private var failedArtwork: String?
    private var artworkCache: [String: (image: Data, background: Data?)] = [:]
    private var lastPublish = ContinuousClock.now

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

    private static let artworkScript = spotify("artwork url of current track")

    private static let commandScripts: [Command: NSAppleScript] = [
        .playPause: spotify("playpause"),
        .next: spotify("next track"),
        .previous: spotify("previous track"),
    ]

    func send(_ command: Command, argument: String? = nil) {
        let script: NSAppleScript
        if command == .seek {
            guard let fraction = Command.seekFraction(argument) else { return }
            script = Self.spotify("set player position to (\(fraction) * (duration of current track) / 1000)")
        } else {
            guard let cached = Self.commandScripts[command] else { return }
            script = cached
        }
        let start = ContinuousClock.now
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error { log.error("Spotify command \(command.rawValue, privacy: .public) failed: \(error, privacy: .public)") }
        log.debug("command \(command.rawValue, privacy: .public) took \(ContinuousClock.now - start, privacy: .public)")

        let sent = ContinuousClock.now
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            if lastPublish < sent { publishState() }
        }
    }

    func publishState(from info: [AnyHashable: Any]? = nil) {
        let start = ContinuousClock.now
        lastPublish = start
        defer { log.debug("publishState(\(info == nil ? "script" : "notification", privacy: .public)) took \(ContinuousClock.now - start, privacy: .public)") }

        guard let snapshot = snapshot(from: info) else {
            artworkSource = nil
            knownArtwork = nil
            pendingArtwork = nil
            update(nil, artwork: .remove)
            return
        }

        let artwork: String
        if let url = snapshot.artworkURL {
            artwork = url
        } else if let id = snapshot.trackID, let known = knownArtwork, known.trackID == id {
            artwork = known.url
        } else {
            update(snapshot.state, artwork: .unchanged)
            artwork = readArtworkURL()
        }
        if let id = snapshot.trackID { knownArtwork = (id, artwork) }

        publish(snapshot.state, artwork: artwork)
    }

    private func snapshot(from info: [AnyHashable: Any]?) -> Snapshot? {
        guard let info,
              let playerState = info["Player State"] as? String,
              let title = info["Name"] as? String,
              let duration = info["Duration"] as? NSNumber,
              let position = info["Playback Position"] as? NSNumber
        else { return readSnapshot() }

        guard playerState != "Stopped" else { return nil }
        let state = NowPlaying(
            title: title,
            artist: info["Artist"] as? String ?? "",
            album: info["Album"] as? String ?? "",
            isPlaying: playerState == "Playing",
            duration: duration.doubleValue / 1000,
            position: position.doubleValue,
            updatedAt: .now
        )
        return Snapshot(state: state, trackID: info["Track ID"] as? String)
    }

    private func readSnapshot() -> Snapshot? {
        var error: NSDictionary?
        let result = Self.stateScript.executeAndReturnError(&error)
        if let error { log.error("Couldn't read Spotify state: \(error, privacy: .public)") }
        guard error == nil, result.numberOfItems == 7 else { return nil }

        func text(_ i: Int) -> String { result.atIndex(i)?.stringValue ?? "" }
        func number(_ i: Int) -> Double { result.atIndex(i)?.doubleValue ?? 0 }
        let state = NowPlaying(
            title: text(1), artist: text(2), album: text(3),
            isPlaying: text(4) == "playing",
            duration: number(5) / 1000,
            position: number(6),
            updatedAt: .now
        )
        return Snapshot(state: state, artworkURL: text(7))
    }

    private func readArtworkURL() -> String {
        var error: NSDictionary?
        let result = Self.artworkScript.executeAndReturnError(&error)
        if let error { log.error("Couldn't read artwork URL: \(error, privacy: .public)") }
        return result.stringValue ?? ""
    }

    private func publish(_ state: NowPlaying, artwork: String) {
        if artwork != pendingArtwork {
            pendingArtwork = nil
            pendingState = nil
        }
        if artwork == artworkSource {
            update(state, artwork: .unchanged)
        } else if let cached = artworkCache[artwork] {
            artworkSource = artwork
            update(state, artwork: .replace(cached.image, background: cached.background))
        } else if !artwork.isEmpty, let url = URL(string: artwork) {
            // Show the new track now instead of waiting on the network; the cover follows once downloaded.
            update(state, artwork: .unchanged)
            pendingState = state
            guard pendingArtwork == nil else { return }
            pendingArtwork = artwork
            download(url, key: artwork)
        } else {
            artworkSource = artwork
            update(state, artwork: .remove)
        }
    }

    private func download(_ url: URL, key: String) {
        Task {
            let start = ContinuousClock.now
            let response = try? await session.data(from: url)
            let image = (response?.1 as? HTTPURLResponse)?.statusCode == 200 ? response?.0 : nil
            let background = await Task.detached(priority: .userInitiated) { image.flatMap(BackgroundRenderer.render) }.value
            log.debug("artwork took \(ContinuousClock.now - start, privacy: .public)")

            guard pendingArtwork == key, let state = pendingState else { return }
            pendingArtwork = nil
            pendingState = nil
            if let image {
                if artworkCache.count >= 20 { artworkCache.removeAll() }
                artworkCache[key] = (image, background)
                publish(state, artwork: key)
            } else if failedArtwork != key {
                // Right after login the network is often not up yet: show the track now, retry the cover once.
                failedArtwork = key
                artworkSource = nil
                update(state, artwork: .remove)
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if artworkSource == nil { publishState() }
                }
            } else {
                artworkSource = key
                update(state, artwork: .remove)
            }
        }
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
        let changed = artworkChanged || stateChanged || (state?.jumped(from: published) ?? false)
        published = state
        if changed { WidgetCenter.shared.reloadAllTimelines() }
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
