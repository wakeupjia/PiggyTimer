# PiggyTimer

A minimal macOS menu bar study timer. 
灵感来自"有效学习时间"这个概念。市面上计时器都太复杂了，我只需要一个东西：一眼看到今天学了多少。

![demo](demo.GIF)

## Features

- One-click start/stop from the menu bar
- Stats window with a 30-day study time curve, totals, and editable history
- Timer automatically stops when the Mac goes to sleep (lid closed)

## Usage

1. Open PiggyTimer
2. **Left-click** the 🐱/🐷 icon in the menu bar — start/stop the timer
   - 🐱 = timing, time ticks live
   - 🐷 = stopped, shows today's total
3. **Right-click** the icon for the menu:
   - **Open UI** — stats window: past-30-day & all-time totals, daily study
     curve, and today's session list (delete any wrong record with the 🗑 button)
   - **Refresh Data** — reload `history.json`
   - **Quit ChronoBar**
4. Closing the lid automatically stops the timer and saves the session
5. Next day, today's time resets automatically

## Build

```bash
xcodebuild -project ChronoBar.xcodeproj -scheme ChronoBar -configuration Release \
  -derivedDataPath /tmp/build CONFIGURATION_BUILD_DIR=/tmp/out build
```

Then copy `/tmp/out/ChronoBar.app` to `/Applications`.

## Auto-start on Login

System Settings → General → Login Items → add PiggyTimer
