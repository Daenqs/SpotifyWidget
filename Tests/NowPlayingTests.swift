import Foundation
import Testing

struct NowPlayingTests {
    private let base = Date(timeIntervalSinceReferenceDate: 1_000)

    private func state(playing: Bool = true, position: TimeInterval = 30, at date: Date? = nil) -> NowPlaying {
        NowPlaying(title: "Song", artist: "Artist", album: "Album", isPlaying: playing,
                   duration: 200, position: position, updatedAt: date ?? base)
    }

    @Test func startAndEndDates() {
        let s = state(position: 30)
        #expect(s.startDate == base.addingTimeInterval(-30))
        #expect(s.endDate == base.addingTimeInterval(170))
    }

    @Test func pausingKeepsElapsedTime() {
        let paused = state(position: 30).toggled(at: base.addingTimeInterval(10))
        #expect(!paused.isPlaying)
        #expect(paused.position == 40)
    }

    @Test func resumingDoesNotAdvancePosition() {
        let resumed = state(playing: false, position: 30).toggled(at: base.addingTimeInterval(10))
        #expect(resumed.isPlaying)
        #expect(resumed.position == 30)
    }

    @Test func pausingNeverPassesDuration() {
        let paused = state(position: 195).toggled(at: base.addingTimeInterval(60))
        #expect(paused.position == 200)
    }

    @Test func seekMovesToFraction() {
        let seeked = state().seeked(to: 0.25, at: base)
        #expect(seeked.position == 50)
    }

    @Test func sameTrackIgnoresPosition() {
        #expect(state(position: 10).sameTrackAndState(as: state(position: 90)))
        #expect(!state(playing: true).sameTrackAndState(as: state(playing: false)))
        #expect(!state().sameTrackAndState(as: nil))
    }

    @Test func normalPlaybackIsNotAJump() {
        let later = state(position: 40, at: base.addingTimeInterval(10))
        #expect(!later.jumped(from: state(position: 30)))
    }

    @Test func seekingIsAJump() {
        let later = state(position: 120, at: base.addingTimeInterval(10))
        #expect(later.jumped(from: state(position: 30)))
    }

    @Test func pausedStateExpectsSamePosition() {
        let old = state(playing: false, position: 30)
        #expect(!state(playing: false, position: 31, at: base.addingTimeInterval(60)).jumped(from: old))
        #expect(state(playing: false, position: 90, at: base.addingTimeInterval(60)).jumped(from: old))
    }

    @Test func codableRoundTrip() throws {
        let original = state()
        let decoded = try JSONDecoder().decode(NowPlaying.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
