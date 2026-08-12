# Untabit

[![CI](https://github.com/pke/untabit/actions/workflows/ci.yml/badge.svg)](https://github.com/pke/untabit/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/pke/untabit?color=7C3AED)](https://github.com/pke/untabit/releases)
[![License: MIT](https://img.shields.io/github/license/pke/untabit?color=4F46E5)](LICENSE)
[![Website](https://img.shields.io/badge/website-untabit.dudesoft.app-4F46E5)](https://untabit.dudesoft.app)

**Untab it!** Pop the current tab out into its own window — press again to merge it back where it came from. Keyboard shortcut or toolbar icon.

- **Toggle** — a tab with siblings pops out; a tab alone in its window merges back into the window it came from, at its old position. If that window is gone, it merges into the most recently focused other window.
- **No page reload** — the tab is *moved*, not reopened: video keeps playing, scroll position and form state survive.
- **No data access** — only the `storage` permission (no install warning), used to remember where a tab came from. Session-only: cleared when the browser closes, never written to disk.
- **One codebase** for Chrome, Brave, Edge, and Firefox (Manifest V3).

## Usage

- Press **Alt+U** (**Ctrl+U** on macOS; rebindable, see below), or
- Click the Untabit toolbar icon.

Press once to untab, press again to put the tab back.

If the shortcut can't be registered (usually because another extension
claimed it first), the toolbar icon shows a red **!** badge and the next
click on it opens the shortcut settings (Chromium) or an instructions
page (Firefox, which doesn't allow extensions to open `about:addons`)
instead of toggling.

## Install (unpacked / development)

### Chrome / Brave / Edge

1. Open `chrome://extensions` (Brave: `brave://extensions`, Edge: `edge://extensions`)
2. Enable **Developer mode**
3. Click **Load unpacked** and select this folder

### Firefox

Temporary install (resets on restart):

1. Run `build.ps1` (produces `dist\firefox\` with the Firefox manifest)
2. Open `about:debugging#/runtime/this-firefox`
3. Click **Load Temporary Add-on…** and select `dist\firefox\manifest.json`

Permanent install requires signing the extension through
[addons.mozilla.org](https://addons.mozilla.org/developers/) (free, also for
self-distributed/unlisted extensions).

## Rebinding the shortcut

- Chrome: `chrome://extensions/shortcuts`
- Brave: `brave://extensions/shortcuts`
- Edge: `edge://extensions/shortcuts`
- Firefox: `about:addons` → gear menu → **Manage Extension Shortcuts**

## Releasing

- **CI** (`.github/workflows/ci.yml`): every push/PR builds both packages
  and lints the Firefox one with `web-ext`.
- **Release** (`release.yml`): pushing a tag `vX.Y.Z` verifies the tag
  matches the version in both manifests, builds, and attaches the two
  zips to a GitHub release.
- **Publish** (`publish.yml`): manual trigger (Actions → "Publish to
  stores" → Run workflow) uploads to the Chrome Web Store and/or Firefox
  AMO. Store credentials are configured as repository secrets — the
  required names and where to obtain them are documented at the top of
  the workflow file.

Store listing copy and promo images live in `store-assets/`
(regenerate images with `store-assets\make-store-assets.ps1`).

## How it works

Two API calls do all the work: `windows.create({ tabId })` *moves* an
existing tab into a fresh window instead of opening a URL, and
`tabs.move()` merges it back. A `commands` entry provides the
user-rebindable keyboard shortcut. Origin records and window focus
history live in `storage.session` because the MV3 background worker is
suspended after ~30 seconds of idle and would otherwise forget them.
See [background.js](background.js).

Cross-browser notes:

- There are two manifests because the browsers disagree on how a
  background script is declared: Chromium wants `service_worker`,
  Firefox (which doesn't support extension service workers) wants
  `scripts`, and each browser warns about the other's key.
  `manifest.json` is the Chromium one — so **Load unpacked** on this
  folder stays warning-free — and `manifest.firefox.json` adds the
  `scripts` key plus the `browser_specific_settings.gecko.id` Firefox
  requires for Manifest V3. `build.ps1` assembles ready-to-ship
  packages for both under `dist\`.
- `background.js` is byte-identical in both packages; only the
  manifest differs.

## License

[MIT](LICENSE)
