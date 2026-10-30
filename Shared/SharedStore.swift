import Foundation

enum SharedStore {
    static let groupID = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as! String

    private static let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
    private static let stateURL = container.appending(path: "now-playing.json")
    static let artworkURL = container.appending(path: "artwork.jpg")
    static let backgroundURL = container.appending(path: "background.jpg")

    static func load() -> NowPlaying? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(NowPlaying.self, from: data)
    }

    static func save(_ state: NowPlaying?) {
        write(state.flatMap { try? JSONEncoder().encode($0) }, to: stateURL)
    }

    static func saveArtwork(_ artwork: Data?, background: Data?) {
        write(artwork, to: artworkURL)
        write(background, to: backgroundURL)
    }

    private static func write(_ data: Data?, to url: URL) {
        if let data {
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
