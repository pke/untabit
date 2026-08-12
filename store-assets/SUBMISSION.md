# Store submission guide

The listing content (text, screenshots, privacy answers) is a one-time
manual step — Chrome has no public API for listing data at all, and
AMO's first submission practically runs through the dashboard too.
Everything after that (each new version) is automated via the
"Publish to stores" GitHub workflow.

All listing text is in [listing.md](listing.md); images are in this
folder; packages come from `build.ps1` → `dist\`.

## One-time: Chrome Web Store

1. Register as a developer (one-time $5 fee):
   https://chrome.google.com/webstore/devconsole
2. **New item** → upload `dist\untabit-chromium.zip`
3. Fill the listing from `listing.md` (title, descriptions, category),
   upload `screenshot-*.png`, `promo-tile-440x280.png`,
   `marquee-1400x560.png`
4. Privacy tab: single purpose, `storage` justification, "no data
   collected" — answers are in `listing.md`
5. Set the support email; submit for review (typically 1–3 days)
6. Note the **extension ID** from the dashboard URL — needed below

### API credentials (for automated publishing)

Follow https://developer.chrome.com/docs/webstore/using-api — creates a
Google Cloud OAuth client and a refresh token. Then add repository
secrets on GitHub (Settings → Secrets and variables → Actions):

- `CWS_EXTENSION_ID` — from step 6
- `CWS_CLIENT_ID`, `CWS_CLIENT_SECRET`, `CWS_REFRESH_TOKEN` — from the
  OAuth setup

## One-time: Firefox AMO

1. Create a (free) account: https://addons.mozilla.org/developers/
2. **Submit a New Add-on** → upload `dist\untabit-firefox.zip`
   (choose "On this site" for a listed extension)
3. Fill the listing from `listing.md` (summary, description, tags),
   pick the MIT license, upload the screenshots
4. Review is typically automatic within minutes for a clean MV3
   extension with only the `storage` permission

The extension ID `untabit.extension@dudesoft.app` is fixed by the
manifest and becomes permanent with this first submission.

### API credentials

Generate JWT credentials at
https://addons.mozilla.org/developers/addon/api/key/ and add secrets:

- `AMO_JWT_ISSUER`, `AMO_JWT_SECRET`

## Every release afterwards (automated)

1. Bump `version` in **both** manifests, commit
2. Tag and push: `git tag v0.4.0 && git push --tags`
   → the Release workflow builds and attaches the zips to a GitHub
   release (tag must match the manifest versions or it fails)
3. GitHub → Actions → **Publish to stores** → Run workflow (choose
   both / chrome-web-store / firefox-amo)
   → uploads the new version to the stores; store review happens on
   their side, no dashboard visit needed

Listing *content* changes (new screenshots, new description) remain
dashboard-only on Chrome; on AMO most text fields can also be edited
via the v5 API if that ever needs automating.
