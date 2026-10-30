import Foundation

struct NowPlaying: Codable, Equatable {
    var title: String
    var artist: String
    var album: String
    var isPlaying: Bool
    var duration: TimeInterval
    var position: TimeInterval
    var updatedAt: Date

    var startDate: Date { updatedAt.addingTimeInterval(-position) }
    var endDate: Date { startDate.addingTimeInterval(duration) }

    func sameTrackAndState(as other: NowPlaying?) -> Bool {
        guard let other else { return false }
        return title == other.title && artist == other.artist && album == other.album && isPlaying == other.isPlaying
    }

    func toggled(at now: Date = .now) -> NowPlaying {
        var copy = self
        if isPlaying { copy.position = min(duration, position + now.timeIntervalSince(updatedAt)) }
        copy.updatedAt = now
        copy.isPlaying.toggle()
        return copy
    }

    static let placeholder = NowPlaying(
        title: "Şarkı Adı", artist: "Sanatçı", album: "Albüm",
        isPlaying: true, duration: 210, position: 70, updatedAt: .now
    )
}

enum SharedStore {
    static let groupID = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as! String

    private static var container: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)!
    }
    private static var stateURL: URL { container.appending(path: "now-playing.json") }
    static var artworkURL: URL { container.appending(path: "artwork.jpg") }

    static func load() -> NowPlaying? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(NowPlaying.self, from: data)
    }

    static func save(_ state: NowPlaying?) {
        guard let state else {
            try? FileManager.default.removeItem(at: stateURL)
            return
        }
        try? JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
    }
}

enum Command: String, CaseIterable {
    case playPause, next, previous, seek

    var notification: Notification.Name { .init("spotifywidget.\(rawValue)") }

    func post(_ argument: String? = nil) {
        DistributedNotificationCenter.default().postNotificationName(
            notification, object: argument, userInfo: nil, deliverImmediately: true
        )
    }
}
