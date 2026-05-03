import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let controller = HDRBoostController()
    private var statusItem: NSStatusItem!
    private var slider: NSSlider!
    private var toggleItem: NSMenuItem!

    private let intensityKey = "hdrIntensity"
    private let pausedKey = "hdrPaused"

    private var intensity: Float {
        get {
            UserDefaults.standard.object(forKey: intensityKey) == nil
                ? 1.3
                : UserDefaults.standard.float(forKey: intensityKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: intensityKey) }
    }

    private var paused: Bool {
        get { UserDefaults.standard.bool(forKey: pausedKey) }
        set { UserDefaults.standard.set(newValue, forKey: pausedKey) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.setIntensity(intensity)
        buildStatusBar()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Give AppKit time to finish initializing its display-observer state
        // before we trigger an HDR mode change.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if !self.paused { self.controller.enable() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.disable()
    }

    @objc private func screensChanged() {
        controller.screensChanged()
    }

    private func buildStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: "AlwaysHDR")
        }

        let menu = NSMenu(title: "AlwaysHDR")

        let title = NSMenuItem(title: "AlwaysHDR", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())
        menu.addItem(makeSliderItem())
        menu.addItem(.separator())

        toggleItem = NSMenuItem(
            title: paused ? "Enable HDR Boost" : "Disable HDR Boost",
            action: #selector(togglePaused),
            keyEquivalent: "p"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit AlwaysHDR",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        statusItem.menu = menu
    }

    private func makeSliderItem() -> NSMenuItem {
        let item = NSMenuItem()
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 36))

        let label = NSTextField(labelWithString: "HDR Boost")
        label.frame = NSRect(x: 14, y: 10, width: 80, height: 16)
        label.font = NSFont.menuFont(ofSize: 0)
        label.textColor = .labelColor
        container.addSubview(label)

        slider = NSSlider(frame: NSRect(x: 96, y: 7, width: 152, height: 22))
        slider.minValue = 1.0
        slider.maxValue = 1.6
        slider.doubleValue = Double(intensity)
        slider.target = self
        slider.action = #selector(sliderChanged(_:))
        slider.isContinuous = true
        container.addSubview(slider)

        item.view = container
        return item
    }

    @objc private func sliderChanged(_ sender: NSSlider) {
        let value = Float(sender.doubleValue)
        intensity = value
        controller.setIntensity(value)
    }

    @objc private func togglePaused() {
        paused.toggle()
        if paused {
            controller.disable()
            toggleItem.title = "Enable HDR Boost"
        } else {
            controller.enable()
            toggleItem.title = "Disable HDR Boost"
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let enabled = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled = enabled
        sender.state = enabled ? .on : .off
    }
}
