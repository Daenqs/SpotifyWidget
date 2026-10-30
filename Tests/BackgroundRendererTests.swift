import AppKit
import CoreImage
import Testing

struct BackgroundRendererTests {
    private func jpeg(width: Int, height: Int) -> Data {
        let image = CIImage(color: CIColor(red: 0.1, green: 0.8, blue: 0.4))
            .cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        return CIContext().jpegRepresentation(of: image, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])!
    }

    @Test func rendersSmallSquareImage() throws {
        let output = try #require(BackgroundRenderer.render(jpeg(width: 640, height: 640)))
        let image = try #require(NSBitmapImageRep(data: output))
        #expect(image.pixelsWide == 128)
        #expect(image.pixelsHigh == 128)
        #expect(output.count < 20_000)
    }

    @Test func rejectsInvalidData() {
        #expect(BackgroundRenderer.render(Data("not an image".utf8)) == nil)
    }

    @Test func renderingIsFast() {
        let input = jpeg(width: 640, height: 640)
        _ = BackgroundRenderer.render(input)
        let elapsed = ContinuousClock().measure {
            for _ in 0..<10 { _ = BackgroundRenderer.render(input) }
        }
        #expect(elapsed < .milliseconds(500))
    }
}
