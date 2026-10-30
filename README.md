# SpotifyWidget

A native macOS desktop / Notification Center widget for the Spotify desktop app.

- Album art, track title and artist
- Play / pause, previous and next buttons
- Live progress bar with elapsed and total time
- Click anywhere on the progress bar to seek
- Small, medium and large sizes

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later
- Spotify desktop app
- A free Apple ID signed in to Xcode

## Build

1. Clone the repo.
2. Copy `Configs/Local.xcconfig.example` to `Configs/Local.xcconfig` and fill in:
   - `DEVELOPMENT_TEAM`: your team ID (Xcode → Settings → Accounts → your team)
   - `BUNDLE_ID_PREFIX`: something unique, e.g. `com.yourname`
3. Open `SpotifyWidget.xcodeproj`, select the `SpotifyWidget` scheme and choose Product → Archive, or build Release and copy the app to `~/Applications`.
4. Launch the app once. It has no window and runs in the background; it registers itself as a login item.
5. Allow it to control Spotify when macOS asks.
6. Right-click the desktop → Edit Widgets, search for "Spotify" and drag the widget out.

## How it works

Widgets are sandboxed and can't talk to Spotify directly, so the project has two parts:

- **SpotifyWidget** – a background helper that listens to Spotify's `com.spotify.client.PlaybackStateChanged` notification and writes the current track to a shared App Group container. Track info comes straight from the notification; AppleScript is only used for artwork URLs and playback commands.
- **SpotifyWidgetExtension** – a WidgetKit extension that renders that state. Buttons are App Intents that send a distributed notification back to the helper, which forwards the command to Spotify.

## Tests

```sh
xcodebuild test -project SpotifyWidget.xcodeproj -scheme SpotifyWidgetTests -destination 'platform=macOS'
```

## Custom icon

Put an `Assets.car` (compiled icon with an `AppIcon` entry) and/or an `AppIcon.icns` in `SpotifyWidget/` and they will be picked up automatically. Both are git-ignored.

## Disclaimer

Not affiliated with or endorsed by Spotify. Spotify is a trademark of Spotify AB.

## License

MIT
