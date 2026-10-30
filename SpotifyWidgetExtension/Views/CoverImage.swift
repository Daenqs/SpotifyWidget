import SwiftUI
import WidgetKit

struct CoverImage: View {
    let image: NSImage
    let contentMode: ContentMode

    var body: some View {
        if #available(macOS 15.0, *) {
            Image(nsImage: image)
                .resizable()
                .widgetAccentedRenderingMode(.fullColor)
                .aspectRatio(contentMode: contentMode)
        } else {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }
}
