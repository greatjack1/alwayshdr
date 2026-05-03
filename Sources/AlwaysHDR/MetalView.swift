import Cocoa
import MetalKit

final class MetalView: MTKView, MTKViewDelegate {
    private var commandQueue: MTLCommandQueue?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1), device: MTLCreateSystemDefaultDevice())
        guard let device else { fatalError("No Metal device") }

        autoResizeDrawable = false
        drawableSize = CGSize(width: 1, height: 1)
        commandQueue = device.makeCommandQueue()
        delegate = self

        colorPixelFormat = .rgba16Float
        colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        clearColor = MTLClearColorMake(16.0, 16.0, 16.0, 1.0)
        preferredFramesPerSecond = 5

        if let layer = self.layer as? CAMetalLayer {
            layer.wantsExtendedDynamicRangeContent = true
            layer.isOpaque = false
            layer.pixelFormat = .rgba16Float
        }
    }

    required init(coder: NSCoder) { fatalError() }

    func draw(in view: MTKView) {
        guard let q = commandQueue,
              let descriptor = view.currentRenderPassDescriptor,
              let buffer = q.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor),
              let drawable = view.currentDrawable else { return }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
