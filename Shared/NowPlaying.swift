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

    func jumped(from old: NowPlaying?, tolerance: TimeInterval = 3) -> Bool {
        guard let old else { return false }
        let expected = old.isPlaying ? old.position + updatedAt.timeIntervalSince(old.updatedAt) : old.position
        return abs(expected - position) > tolerance
    }

    func toggled(at now: Date = .now) -> NowPlaying {
        var copy = self
        if isPlaying { copy.position = min(duration, position + now.timeIntervalSince(updatedAt)) }
        copy.updatedAt = now
        copy.isPlaying.toggle()
        return copy
    }

    func seeked(to fraction: Double, at now: Date = .now) -> NowPlaying {
        var copy = self
        copy.position = fraction * duration
        copy.updatedAt = now
        return copy
    }

    static let placeholder = NowPlaying(
        title: String(localized: "Song Title"), artist: String(localized: "Artist"), album: "",
        isPlaying: true, duration: 210, position: 70, updatedAt: .now
    )
}
