# Installing NightShift

## Option 1: Install from .dmg

1. Download the latest `.dmg` file from the [Releases](../../releases) page.
2. Open the `.dmg` file.
3. Drag **NightShift.app** into the **Applications** folder shortcut in the window.
4. Eject the disk image.
5. Open NightShift from Applications or Spotlight.

> **First launch:** macOS may show a security warning because the app is not distributed
> through the Mac App Store. To open it: right-click (or Control-click) the app icon →
> **Open** → **Open** in the dialog. You only need to do this once.

## Option 2: Build from source

### Prerequisites

- macOS 13 Ventura or later
- Xcode 15 or later ([download from the Mac App Store](https://apps.apple.com/app/xcode/id497799835))

### Steps

1. Clone the repository:
   ```
   git clone https://github.com/ArrayOfLilly/NightShift.git
   cd NightShift/countdownApp
   ```

2. Open the project in Xcode:
   ```
   open countdownApp.xcodeproj
   ```

3. Select the `countdownApp` scheme and your Mac as the run destination.

4. Press **⌘R** to build and run, or **⌘B** to build only.

The app appears in the menubar after launch. No additional configuration is required.

### Notes

- Sun times (Calculate tab) require a network connection on first use to resolve your
  location coordinates. After that, the last known position is cached.
- All data (countdowns, deadlines, snippets) is stored locally in `UserDefaults`.
  No account, no sync, no cloud.
