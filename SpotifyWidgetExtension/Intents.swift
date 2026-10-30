import AppIntents

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Play / Pause"

    func perform() async throws -> some IntentResult {
        if let state = SharedStore.load() { SharedStore.save(state.toggled()) }
        Command.playPause.post()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"

    func perform() async throws -> some IntentResult {
        await Command.next.postAndWaitForUpdate()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"

    func perform() async throws -> some IntentResult {
        await Command.previous.postAndWaitForUpdate()
        return .result()
    }
}

private extension Command {
    func postAndWaitForUpdate(timeout: Duration = .seconds(2)) async {
        let before = SharedStore.load()?.updatedAt
        post()
        let deadline = ContinuousClock.now + timeout
        while ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(50))
            if SharedStore.load()?.updatedAt != before { return }
        }
    }
}

struct SeekIntent: AppIntent {
    static let title: LocalizedStringResource = "Seek"

    @Parameter(title: "Position")
    var fraction: Double

    init() {}
    init(fraction: Double) { self.fraction = fraction }

    func perform() async throws -> some IntentResult {
        if let state = SharedStore.load() { SharedStore.save(state.seeked(to: fraction)) }
        Command.seek.post(String(fraction))
        return .result()
    }
}
