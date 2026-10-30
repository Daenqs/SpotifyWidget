import CoreImage

enum BackgroundRenderer {
    private static let size: CGFloat = 128
    private static let context = CIContext()

    static func render(_ artwork: Data) -> Data? {
        guard let image = CIImage(data: artwork), image.extent.width > 0 else { return nil }
        let scale = size / image.extent.width
        let output = image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .clampedToExtent()
            .applyingGaussianBlur(sigma: 12)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.3])
            .cropped(to: CGRect(x: 0, y: 0, width: size, height: size))
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        return context.jpegRepresentation(of: output, colorSpace: colorSpace, options: [:])
    }
}
