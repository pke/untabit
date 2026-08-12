# Untabit — store listing copy

## Chrome Web Store

**Title:** Untabit — Move Tab to New Window

**Short description** (max 132 chars):

> Pop the current tab out into its own window — press again to merge it back. Alt+U. No reload, no data access.

**Category:** Tools / Workflow & Planning

**Detailed description:**

> Untab it! One shortcut to pop the current tab out into its own window — and the same shortcut to put it back.
>
> HOW IT WORKS
> • Press Alt+U (Ctrl+U on macOS) or click the toolbar icon
> • A tab with siblings pops out into its own window
> • A tab alone in its window merges back where it came from, at its old position
> • If the original window is gone, it joins the most recently used window instead
>
> NO RELOAD
> The tab is moved, not reopened: video keeps playing, scroll position and form state survive.
>
> PRIVACY
> No data access, no tracking, no analytics. The only permission is "storage", used to remember where a tab came from — session-only, cleared when the browser closes, never written to disk.
>
> The shortcut is rebindable at chrome://extensions/shortcuts.

**Privacy tab answers:**
- Single purpose: move the current tab to its own window and back.
- Permission justification (`storage`): remembers which window a popped-out tab came from so it can be merged back; session storage only.
- Data collected: none.

## Firefox Add-ons (AMO)

**Name:** Untabit

**Summary** (max 250 chars):

> Pop the current tab out into its own window — press the shortcut again to merge it back where it came from. No page reload: video keeps playing, scroll and form state survive. No data access, no tracking.

**Description:** same as Chrome detailed description, with `about:addons` →
gear → Manage Extension Shortcuts as the rebinding path and Alt+U /
Ctrl+U (macOS) unchanged.

**Tags:** tabs, window, tab management, productivity

## Assets

| File | Purpose |
|------|---------|
| `screenshot-1-1280x800.png` | Screenshot 1 (pop out) — CWS & AMO |
| `screenshot-2-1280x800.png` | Screenshot 2 (merge back + features) — CWS & AMO |
| `promo-tile-440x280.png` | CWS small promo tile |
| `marquee-1400x560.png` | CWS marquee promo tile |
| `../icons/icon128.png` | Store icon (both stores) |

Regenerate the images with `make-store-assets.ps1`.
