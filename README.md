# Login Link Fixer

<img src="Resources/AppIcon.png" alt="Login Link Fixer icon" width="160">

A tiny native macOS menu-bar utility for fixing login URLs mangled by line breaks or Markdown.

## Use

1. Copy the broken link.
2. Press `⌥⌘L` or click the chain icon in the menu bar.
3. Press Return to fix and open it.

You can also paste, type, or drag text into the popup. Everything happens locally; the app has no backend, analytics, or storage.

Right-click the menu-bar icon for clipboard actions, the About screen, and the **Start at Login** setting.
When started by macOS at login, the app stays quietly in the menu bar without opening the fixer window.

## Download

Get the signed and notarized disk image from the [latest release](https://github.com/joon-aca/login-link-fixer/releases/latest). Open it, drag **Login Link Fixer** to Applications, then launch the app. Requires macOS 14 or later on Apple silicon or Intel.

## Build and install locally

```bash
make install
```

This builds the app, installs it to `/Applications/Login Link Fixer.app`, and launches it.

## Make a release

`make release` builds a universal Developer ID signed app, notarizes and staples both the app and its disk image, and writes a SHA-256 checksum in `dist/`. It uses the `aca-notary` keychain profile by default; override it with `NOTARY_PROFILE`. The script only produces local artifacts, so review and upload them separately when ready.
