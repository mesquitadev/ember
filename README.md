<div align="center">

# Ember

**Keep the Mac awake, from the menu bar.** The `caffeinate` job, without a
terminal window you have to leave open — and without forgetting it's running.

</div>

---

Click the cup in the menu bar, pick how long, and the Mac stays up. Filled cup
means it's holding; outlined means the Mac sleeps normally. When you set a
duration, the menu counts it down.

## Install

```sh
brew install --cask mesquitadev/tap/ember
xattr -dr com.apple.quarantine /Applications/Ember.app
```

Or build from source: `Scripts/bundle.sh` then `open dist/Ember.app`.

## What it does

- **Keep the display on** — the `caffeinate -d` case: presenting, reading,
  watching something run.
- **Keep the Mac awake, screen may sleep** — the `caffeinate -i` case: a long
  build or a download with nobody watching.
- Durations from 15 minutes to 8 hours, or until you turn it off.
- Opens at login, and can turn itself on when it opens — set both and it stays
  out of your way for good.
- English and Portuguese.

## Why not just run `caffeinate`

Ember doesn't shell out to it. `caffeinate` is a thin wrapper over
`IOPMAssertionCreateWithName`, the system power-management API, and going
through the tool costs three things: a child process that outlives the app if it
dies, no way to know how much time is left, and cancelling means finding and
killing a PID.

That last one is not hypothetical. The machine this was written on had a
`caffeinate -d` running for six days — left behind by a terminal window closed
long ago, quietly keeping the display awake. Talking to power management
directly means the assertion dies with the app, including a force quit: the
system drops assertions held by processes that no longer exist.

You can see what it holds at any time:

```sh
pmset -g assertions | grep Ember
```

## Requirements

macOS 14 or later. No permissions, no network, no background helper.

## License

MIT © Paulo Victor Mesquita
