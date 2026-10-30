import AppKit
import ServiceManagement

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
