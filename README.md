# Login Link Fixer

<img src="Resources/AppIcon.png" alt="Login Link Fixer icon" width="160">

**Copy a login link from your terminal. Click the chain. You're in.**

Login Link Fixer is a tiny macOS menu-bar app for the long sign-in links that command-line tools print. Copying one from a shell breaks it with line breaks. Login Link Fixer stitches it back together and opens it in your browser with one click.

## Why this exists

You run `some-cli login`. It prints a link and asks you to open it in your browser:

```text
https://auth.example.com/oauth/authorize?client_id=abc123&redirect_uri=http%3A%2F%2Flocalhost%3A54
321%2Fcallback&scope=openid+profile+offline_access&state=Zx9qT3mK8vLp2RwYc5Nd&code_challenge=Hj4kL
9mN2pQ7rS1tU6vW8xY0zA3bC5dE
```

Your terminal wraps that long link to fit the window. Select and copy it, and in many terminals (and almost always over SSH, inside tmux, or in a full-screen app) the wrap points come along as **real line breaks** and padding spaces. Paste it into your browser and you get:

> *Invalid request.* 😩

The break can land in the middle of `client_id`, `state`, or the PKCE challenge, and you won't spot it by eye in a 300-character link. So you end up hand-editing the link in the address bar, or shrinking your font until it fits on one line.

Login Link Fixer cleans it up for you. Copy the whole messy block, click once, and you're signing in instead of hunting for line breaks.

## How to use it

### The everyday way: one click

1. **Copy** the login link from your terminal, line breaks and all. Don't worry about being precise: a prompt before the link or a "Waiting…" line after it gets left out.
2. **Left-click the chain icon** 🔗 in your menu bar.

That's it. The fixed link opens in your default browser.

If what you copied can't be turned into a web link, the fixer window opens with your text in it so you can see what went wrong and edit it.

### The careful way: check first

Want to see where you're going before you go? Press **`⌥⌘L`** from any app. Login Link Fixer shows you the destination's hostname and waits for you to click **Open Link** (or press Return). Press Esc to back out.

Opening the app from Finder or Spotlight does the same thing.

### The hands-on way: see the whole link

Right-click the chain icon and choose **Show Link Fixer** to see the full link exactly as you copied it. You can edit it, paste or drag in something else, then click **Open ↗**.

### Everything in the right-click menu

| Menu item | What it does |
| --- | --- |
| **Show Link Fixer** | Opens the fixer with your clipboard text, ready to inspect or edit |
| **Fix Clipboard & Open** | Same as a left-click: fixes the copied link and opens it |
| **Start at Login** | Keeps the chain icon in your menu bar after every restart |
| **About Login Link Fixer** | Version info and a link back here |
| **Quit** | See you later 👋 |

When macOS starts the app at login, it sits quietly in the menu bar and doesn't open any windows.

## What it fixes

The main job is **line breaks and padding spaces** from a terminal wrapping a long link. The pieces are stitched back together, however many lines the link was split across.

It knows where the link ends, too. A wrapped piece of a link never has a space in it, so the link stops at the first space between words, the first line of words, or the first blank line. "Visit this URL to sign in:" before it and "Waiting for authentication…" after it stay out of your browser.

It also handles the other ways shells and CLIs mess up links:

- **Wrapping punctuation**, like quotes or angle brackets around the link, or a trailing `.` or `)`
- **Markdown links** like `[click here](https://…)`, which tools that render Markdown output often print, including Markdown-escaped `\&` between parameters
- **HTML-escaped ampersands** such as `&amp;` and `&#38;`

It only opens `http` and `https` links. Anything else stays in the fixer for you to look at.

## Private by design

Everything happens on your Mac. There's no server, no account, no analytics, and no history. Login Link Fixer reads your clipboard only when you ask it to, fixes the link, and passes it to your browser. Your login tokens never go anywhere else.

## Install

Download the signed, notarized disk image from the [latest release](https://github.com/joon-aca/login-link-fixer/releases/latest), open it, and drag **Login Link Fixer** into Applications. Then launch it, look for the chain in your menu bar, and you're set. You may also want to turn on **Start at Login** from the right-click menu.

Works on macOS 14 or later, on Apple silicon and Intel Macs.

---

## For developers

Needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

| Command | What it does |
| --- | --- |
| `make install` | Builds the app, installs it to `/Applications`, and launches it |
| `make test` | Runs the test suite |
| `make release` | Builds a universal, Developer ID–signed, notarized app and disk image in `dist/` |

**`make install` keeps exactly one copy installed.** Every copy shares a bundle ID, so macOS may launch a stale one. Before installing, the script moves any other copy in `/Applications` (including `Utilities`) or `~/Applications` to the Trash. Finder may ask for an admin password, and **Put Back** restores a trashed copy.

**`make release`** uses the `aca-notary` keychain profile by default; set `NOTARY_PROFILE` to use a different one. It writes the disk image and its SHA-256 checksum to `dist/` but doesn't upload anything, so publish the release yourself when you're ready.

See [CHANGELOG.md](CHANGELOG.md) for what's new.
