import AppIntents

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Oynat / Duraklat"

    func perform() async throws -> some IntentResult {
        if let state = SharedStore.load() { SharedStore.save(state.toggled()) }
        Command.playPause.post()
        return .result()
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Sonraki Şarkı"

    func perform() async throws -> some IntentResult {
        Command.next.post()
        return .result()
    }
}

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Önceki Şarkı"

    func perform() async throws -> some IntentResult {
        Command.previous.post()
        return .result()
    }
}

struct SeekIntent: AppIntent {
    static let title: LocalizedStringResource = "Şarkıda Atla"

    @Parameter(title: "Konum (0–1)")
    var fraction: Double

    init() {}
    init(fraction: Double) { self.fraction = fraction }

    func perform() async throws -> some IntentResult {
        if let state = SharedStore.load() { SharedStore.save(state.seeked(to: fraction)) }
        Command.seek.post(String(fraction))
        return .result()
    }
}
