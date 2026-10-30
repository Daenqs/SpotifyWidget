import Foundation

enum Command: String, CaseIterable {
    case playPause, next, previous, seek

    var notification: Notification.Name { .init("spotifywidget.\(rawValue)") }

    func post(_ argument: String? = nil) {
        DistributedNotificationCenter.default().postNotificationName(
            notification, object: argument, userInfo: nil, deliverImmediately: true
        )
    }
}
