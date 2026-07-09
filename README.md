# LaunchNotes

A tiny SwiftUI package for showing a **"what's new in this version"** screen to returning users on
update — while **never** showing it to first-time downloaders.

The trick isn't detecting "is this a returning user" (which is surprisingly hard around fresh installs,
restores, and the first LaunchNotes-aware build). It's simpler: the event that separates the two groups
is **onboarding completion**. A brand-new user finishes your intro flow; a returning user updating in
place doesn't. So:

- On onboarding completion, call `markCaughtUp()` → the new user is recorded as caught up to the current
  version and never sees the changelog.
- Attach `.launchNotes(model)` at your post-onboarding root → a returning user (who didn't onboard, or
  who's updating) sees the newest version's note once, then it's marked seen.

This also handles the first-rollout bootstrap (v1 → the first version with LaunchNotes) and the
restore-during-onboarding case, with no version-comparison guesswork.

## Install

```swift
.package(url: "https://github.com/DaveJabe/LaunchNotes.git", from: "1.0.0")
```

## Use

```swift
import LaunchNotes

let notes = [
    LaunchNote(version: "2.0", title: "Version 2 is here", highlights: [
        Highlight(symbolName: "house", title: "Reimagined home", detail: "A cleaner way to see everything."),
        Highlight(symbolName: "sparkles", title: "New this-and-that", detail: "…"),
    ])
]

@StateObject private var launchNotes = LaunchNotesModel(notes: notes)

var body: some View {
    RootView()
        .launchNotes(launchNotes)               // default view
}
```

Onboarding completion (the one required hook):

```swift
launchNotes.markCaughtUp()
```

### Your own design system

```swift
RootView()
    .launchNotes(launchNotes) { note, dismiss in
        MyStyledWhatsNewView(note: note, onDismiss: dismiss)
    }
```

## How it decides (`LaunchNotesEngine`)

| `lastSeen` | meaning | shows |
|---|---|---|
| `nil` | first LaunchNotes build; returning user reached the app without re-onboarding | newest note ≤ current |
| `< current` | in-place update | newest note in `(lastSeen, current]` |
| `== current` | caught up / already seen | nothing |

A brand-new user's `markCaughtUp()` seeds `lastSeen == current` before the root evaluates, so they land
in the "nothing" row. Versions compare with `.numeric` (so `1.10 > 1.9`) — use one string format for
`CFBundleShortVersionString` and each note's `version`.

## Notes

- Persistence is injectable (`LaunchNotesStorage`, default `UserDefaults`) — point it at an App Group or
  a scratch suite for tests.
- The engine is a pure function, fully unit-tested; `swift test` runs on the Mac host (no simulator).
- iCloud/database restores don't carry the seen-marker (it's a local default), so a reinstall-and-restore
  on a new device can show the current note once more. Rare; sync via `NSUbiquitousKeyValueStore` if it
  ever matters.
