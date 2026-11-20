# Changelog

## 1.2.1

Everything since 1.0.0.

- **One-click open.** Left-clicking the menu-bar icon fixes the copied link and opens it right away in your default browser.
- **Check before you go.** Pressing `⌥⌘L`, or opening the app from Finder or Spotlight, shows the link's hostname and waits for you to confirm.
- **Smarter link endings.** Text after a link, like "then press Enter" on the same line or a "Waiting for authentication…" line below it, no longer gets glued onto the link. A blank line also ends the link. Wrapped pieces are still joined however many lines they span.
- **Markdown fix.** Markdown links that escape the `&` between query parameters as `\&` now open with the right parameters.
- **The fixer shows what you copied.** If the clipboard text can't be turned into a web link, the fixer opens with that text ready to edit instead of a blank field. **Show Link Fixer** always starts with your clipboard text.
- The About window's shortcut hint now reads "Press ⌥⌘L to fix a copied link".
- `make install` keeps exactly one installed copy. It moves other copies to the Trash so macOS can't launch a stale version.

## 1.0.0

- Initial macOS menu-bar release with a global shortcut, link repair for wrapped and Markdown links, and an optional Start at Login setting.
