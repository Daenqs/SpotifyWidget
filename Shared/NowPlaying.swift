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

    func seeked(to fraction: Double, at now: Date = .now) -> NowPlaying {
        var copy = self
        copy.position = fraction * duration
        copy.updatedAt = now
        return copy
    }

    static let placeholder = NowPlaying(
        title: "Şarkı Adı", artist: "Sanatçı", album: "Albüm",
        isPlaying: true, duration: 210, position: 70, updatedAt: .now
    )
}
