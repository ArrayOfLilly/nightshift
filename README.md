# NightShift

A macOS menubar app for developers who work on side projects at night — on a budget.

## Why I built this

I work on side projects late at night, after my day job, using free-tier AI accounts
(Claude, ChatGPT, Codex, DeepSeek, Qwen, Kimi, and others). The constraints are real:
each account has a cooldown window, and when dawn arrives, it's time to sleep — not a
suggestion, a hard stop.

NightShift is the tool I built to manage that workflow. Three tabs, one purpose: keep
the night productive and know when to stop.

## What it does

**Countdown tab** — tracks when each AI account becomes available again. Not a generic
timer list: every row is a specific service with its own cooldown. When the countdown
hits zero, that account is free again.

**Calculate tab** — shows how much time is left until sunrise at your location. This is
the core of the app: the sun time is the deadline for the night's work. Named deadlines
(project milestones, self-imposed goals) can be saved here and compared against the
remaining window.

**Snippets tab** — stores session handoff notes. When switching between AI sessions or
picking up where you left off the next night, this is where the context lives: what was
done, what's next, which files are open.

Notes on individual countdown items let you record mid-task context without switching
tabs — a quick reminder of where you were when a cooldown interrupted the work.

## Requirements

- macOS 26.5 or later
- Xcode 26 or later (to build from source)

## Installation

See [install.md](install.md) for build-from-source and .dmg installation instructions.

## License

Personal use. No warranty.
