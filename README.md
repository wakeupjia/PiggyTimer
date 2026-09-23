# PiggyTimer

A minimal macOS menu bar study timer. 
灵感来自"有效学习时间"这个概念。市面上计时器都太复杂了，我只需要一个东西：一眼看到今天学了多少。

![demo](demo.GIF)

## Features

- One-click start/stop from the menu bar
- Themes: track time in separate independent spaces (e.g. AI, paper1), switchable anytime
- Stats window with a 30-day study time curve, totals, and editable history
- Monospaced, fixed-width time display that never shifts around
- Timer automatically stops when the Mac goes to sleep (lid closed)

## Usage

1. Open PiggyTimer
2. **Left-click** the 🐱/🐷 icon in the menu bar — start/stop the timer
   - 🐱 = timing, time ticks live (zero-padded `HH:MM`, no jumping)
   - 🐷 = stopped, shows today's total
3. **Right-click** the icon for the menu:
   - **Open UI** — stats window: past-30-day & all-time totals, daily study
     curve, and today's session list (delete any wrong record with the 🗑 button).
     Use the picker at the top-right to switch themes, or **Create a new theme**
   - **Switch Theme** — pick the theme your time is tracked under
   - **Quit ChronoBar**
4. Each theme stores its own history (`history-<theme>.json`); switching themes
   while timing auto-saves the current session first
5. Closing the lid automatically stops the timer and saves the session
6. Next day, today's time resets automatically

## Build

```bash
xcodebuild -project ChronoBar.xcodeproj -scheme ChronoBar -configuration Release \
  -derivedDataPath /tmp/build CONFIGURATION_BUILD_DIR=/tmp/out build
```

Then copy `/tmp/out/ChronoBar.app` to `/Applications`.

## Auto-start on Login

System Settings → General → Login Items → add PiggyTimer
