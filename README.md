# AlwaysHDR

A tiny macOS menu bar app that pushes SDR content past the normal brightness ceiling on HDR/EDR-capable displays.

It works by keeping a 1×1-pixel Metal overlay onscreen with `wantsExtendedDynamicRangeContent = true`. That nudges the system into HDR mode, which unlocks the display's full brightness headroom. AlwaysHDR then scales the gamma table so SDR content — browser, terminal, editor, video — fills that headroom instead of being clamped to the SDR range.

The result: a noticeably brighter, punchier picture on XDR / mini-LED MacBook displays and external HDR monitors, without changing any system settings.

## Requirements

- macOS 12 or later (macOS 13+ for "Launch at Login")
- A display with EDR headroom (XDR MacBook, mini-LED, or HDR-capable external)
- Xcode command-line tools (`xcode-select --install`)

## Install

Clone and build:

```sh
git clone git@github.com:greatjack1/alwayshdr.git
cd alwayshdr
./build.sh
mv AlwaysHDR.app /Applications/
open /Applications/AlwaysHDR.app
```

`build.sh` produces a universal (arm64 + x86_64) ad-hoc-signed `.app` bundle. The first time you launch it, macOS may warn about an unidentified developer — right-click the app and choose **Open** to bypass.

## Usage

A sun icon appears in the menu bar. Click it for:

- **HDR Boost slider** — intensity from 1.0× (off) to 1.6×. Default is 1.3×.
- **Disable / Enable HDR Boost** — pause without quitting.
- **Launch at Login** — start automatically on macOS 13+.
- **Quit AlwaysHDR** — restores original gamma on exit.

Settings persist across launches.

## How it works

- `MetalView` renders a 1-pixel `MTKView` per display with `rgba16Float` and the extended-linear sRGB color space. Its presence is what flips the display into HDR mode.
- `HDRBoostController` captures each display's baseline gamma table, then re-applies it scaled by a factor that depends on the slider value and the display's reported EDR headroom (`maximumExtendedDynamicRangeColorComponentValue`).
- Re-syncs on display changes (sleep/wake, hotplug, resolution changes).
- On quit or disable, `CGDisplayRestoreColorSyncSettings()` puts everything back.

Displays without EDR headroom (`maxEDR ≤ 1.05`) are skipped, so non-HDR monitors are left alone.

## Uninstall

```sh
rm -rf /Applications/AlwaysHDR.app
```

If "Launch at Login" was enabled, toggle it off in the menu before quitting, or remove `AlwaysHDR` from **System Settings → General → Login Items**.

## License

All rights reserved. Open an issue if you'd like a permissive license added.
