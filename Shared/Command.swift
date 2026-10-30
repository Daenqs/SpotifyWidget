import Foundation

enum Command: String, CaseIterable {
    case playPause, next, previous, seek

    var notification: Notification.Name { .init("spotifywidget.\(rawValue)") }

    static func seekFraction(_ argument: String?) -> Double? {
        guard let value = argument.flatMap(Double.init), (0...1).contains(value) else { return nil }
        return value
    }

    func post(_ argument: String? = nil) {
        DistributedNotificationCenter.default().postNotificationName(
            notification, object: argument, userInfo: nil, deliverImmediately: true
        )
    }
}
