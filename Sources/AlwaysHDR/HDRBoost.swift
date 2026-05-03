import Cocoa
import CoreGraphics

extension NSScreen {
    var displayId: CGDirectDisplayID? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
    }
}

final class GammaTable {
    static let size: UInt32 = 256
    var red = [CGGammaValue](repeating: 0, count: Int(size))
    var green = [CGGammaValue](repeating: 0, count: Int(size))
    var blue = [CGGammaValue](repeating: 0, count: Int(size))

    static func capture(displayId: CGDirectDisplayID) -> GammaTable? {
        let table = GammaTable()
        var count: UInt32 = 0
        let err = CGGetDisplayTransferByTable(displayId, size, &table.red, &table.green, &table.blue, &count)
        guard err == .success else { return nil }
        return table
    }

    func apply(displayId: CGDirectDisplayID, factor: Float) {
        var r = red, g = green, b = blue
        for i in 0..<Int(GammaTable.size) {
            r[i] *= factor
            g[i] *= factor
            b[i] *= factor
        }
        CGSetDisplayTransferByTable(displayId, GammaTable.size, &r, &g, &b)
    }
}

final class OverlayWindow: NSWindow {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        hidesOnDeactivate = false
        canHide = false
        alphaValue = 1
        level = .screenSaver
        collectionBehavior = [.stationary, .ignoresCycle, .canJoinAllSpaces]
    }
}

final class HDRBoostController {
    private var overlays: [CGDirectDisplayID: OverlayWindow] = [:]
    private var baselineGammas: [CGDirectDisplayID: GammaTable] = [:]
    private var pollTimer: Timer?
    private var intensity: Float = 1.3
    private(set) var isEnabled = false

    func setIntensity(_ value: Float) {
        intensity = value
        if isEnabled { applyGammas() }
    }

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        setupOverlays()
        startPolling()
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        stopPolling()
        restoreBaselineGammas()
        tearDownOverlays()
    }

    func screensChanged() {
        guard isEnabled else { return }
        // Restore anything we captured for displays that are gone, then re-sync.
        let activeIds = Set(NSScreen.screens.compactMap { $0.displayId })
        for id in Array(overlays.keys) where !activeIds.contains(id) {
            overlays[id]?.orderOut(nil)
            overlays[id]?.close()
            overlays.removeValue(forKey: id)
            baselineGammas[id]?.apply(displayId: id, factor: 1.0)
            baselineGammas.removeValue(forKey: id)
        }
        setupOverlays()
        applyGammas()
    }

    private func setupOverlays() {
        for screen in NSScreen.screens {
            guard let id = screen.displayId else { continue }
            if overlays[id] == nil {
                let window = OverlayWindow()
                let origin = NSPoint(
                    x: screen.frame.origin.x,
                    y: screen.frame.origin.y + screen.frame.height - 1
                )
                window.setFrame(NSRect(origin: origin, size: NSSize(width: 1, height: 1)), display: true)
                window.contentView = MetalView()
                window.orderFrontRegardless()
                overlays[id] = window
            }
            if baselineGammas[id] == nil {
                baselineGammas[id] = GammaTable.capture(displayId: id)
            }
        }
    }

    private func tearDownOverlays() {
        for (_, window) in overlays {
            window.orderOut(nil)
            window.close()
        }
        overlays.removeAll()
    }

    private func startPolling() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.applyGammas()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func applyGammas() {
        for (id, baseline) in baselineGammas {
            guard let screen = NSScreen.screens.first(where: { $0.displayId == id }) else { continue }
            let maxEDR = screen.maximumExtendedDynamicRangeColorComponentValue
            guard maxEDR > 1.05 else { continue }
            let factor = 1 + (intensity - 1) * Float(maxEDR) / 4.0
            baseline.apply(displayId: id, factor: factor)
        }
    }

    private func restoreBaselineGammas() {
        for (id, baseline) in baselineGammas {
            baseline.apply(displayId: id, factor: 1.0)
        }
        CGDisplayRestoreColorSyncSettings()
        baselineGammas.removeAll()
    }
}
