## NightShift 0.9.2

A macOS menu bar app for night-shift developers who work with free-tier AI accounts.

### What it does

**Countdown** — track when each free AI account resets. Keep a slot for Claude, Codex,
ChatGPT, DeepSeek, or whatever you're cycling through. See at a glance which one is
free right now, and add a note to any slot so you can pick up exactly where you left off.

**Calculate** — enter your project deadlines and watch them count down against tonight's
sunrise. The sun panel pulls local sunrise and sunset times once a year (sunrisesunset.io,
coordinates only — no account, no tracking) and caches them locally.

**Snippets** — save session handoff notes by project. Copy them into your next AI session
in one click.

### This release

- Full English and Hungarian localization
- Tooltip help on every interactive element
- In-app Help window with detailed usage notes for all three tabs
- Privacy Policy window (Help menu)
- Settings: language, font size, date format
- Recovery banner for corrupted data (rare, but handled gracefully)
- No accounts. No cloud sync. No analytics. Everything stays on your Mac.

### Requirements

- macOS 26.5 or later
- Apple Silicon or Intel

### Installation

Download `NightShift-0.9.2.dmg`, open it, drag NightShift to Applications.

On first launch macOS may show a Gatekeeper warning ("cannot be opened because it is
from an unidentified developer"). Right-click the app in Applications and choose Open
to bypass it once — after that it launches normally.

### Notes

This is a pre-1.0 personal release. It works, I use it every night, but expect rough
edges. If something breaks, open an issue or email arrayoflilly@gmail.com.
