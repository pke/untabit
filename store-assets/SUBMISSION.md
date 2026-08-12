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
5. Set the support email: `untabit.extension@dudesoft.app` (CWS sends a
   verification mail there — the mailbox/alias must exist and be
   readable before this step); submit for review (typically 1–3 days)
6. The **extension ID** is `jfdejeecmmellhpmbcjkkmegegahifkh`
   (listing: https://chromewebstore.google.com/detail/jfdejeecmmellhpmbcjkkmegegahifkh)

### API credentials (for automated publishing)

Base reference: https://developer.chrome.com/docs/webstore/using-api.
Note the Cloud console never shows a refresh token — it must be
obtained through an OAuth flow, easiest via the OAuth Playground:

1. Cloud console → APIs & Services → Credentials → OAuth client of type
   **Web application** with authorized redirect URI
   `https://developers.google.com/oauthplayground`
2. OAuth consent screen: publishing status **In production** — while in
   "Testing" status, refresh tokens expire after 7 days and the publish
   workflow silently breaks. The "unverified app" warning during
   authorization is expected (Advanced → continue).
3. https://developers.google.com/oauthplayground → gear icon → "Use
   your own OAuth credentials" → paste client id/secret → Step 1: scope
   `https://www.googleapis.com/auth/chromewebstore` → Authorize APIs
   (sign in with the CWS developer account) → Step 2: "Exchange
   authorization code for tokens" → copy the **refresh token**
4. Add the repository secrets (via `gh secret set <NAME> --repo
   pke/untabit`, entered interactively — never in shell history):
   `CWS_EXTENSION_ID`, `CWS_CLIENT_ID`, `CWS_CLIENT_SECRET`,
   `CWS_REFRESH_TOKEN` — all four are set as of 2026-08-12.

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
