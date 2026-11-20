# Login Link Fixer

<img src="Resources/AppIcon.png" alt="Login Link Fixer icon" width="160">

A tiny native macOS menu-bar utility for fixing login URLs mangled by line breaks or Markdown.

## Use

1. Copy the login link.
2. Left-click the chain icon in the menu bar to open the fixed link immediately in your default browser.

**To confirm the destination first**, press `⌥⌘L`, check the hostname, then click **Open Link** or press Return.

**To inspect the full copied URL before opening it**, right-click the chain icon and choose **Show Link Fixer**. The fixer shows the URL as copied and lets you edit it before clicking **Open**. If the confirmation is already open, press Esc first.

If the app can’t turn the copied text into a web link, it opens the fixer with that text ready to edit. You can also paste, type, or drag text into the fixer. Everything happens locally, with no backend, analytics, or storage.

The right-click menu also offers **Fix Clipboard & Open** to open a fixable link immediately, plus the About screen and the **Start at Login** setting.
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
