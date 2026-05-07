# PiggyTimer

A minimal macOS menu bar study timer.

🐷 when idle, 🐱 when studying. Your today's total shows right in the menu bar.

![demo](demo.GIF)

## Features

- One-click start/stop from the menu bar
- 感来自"有效学习时间"这个概念。市面上计时器都太复杂了，我只需要一个东西：一眼看到今天学了多少。

## Usage

1. Open PiggyTimer
2. Click the 🐱/🐷 icon in the menu bar
3. **Start Timer** — icon switches to 🐱, time ticks live
4. **Stop Timer** — icon switches to 🐷, time freezes but keeps today's total
5. Next day, today's time resets automatically

## Build

```bash
xcodebuild -project ChronoBar.xcodeproj -scheme ChronoBar -configuration Release \
  -derivedDataPath /tmp/build CONFIGURATION_BUILD_DIR=/tmp/out build
```

Then copy `/tmp/out/ChronoBar.app` to `/Applications`.

## Auto-start on Login

System Settings → General → Login Items → add PiggyTimer
