# Run Scout Finder on GitHub (no Mac, phone-friendly)

This runs the whole search **on GitHub's servers** — daily and on demand — and delivers
results to your phone via a **GitHub Issue (with push notifications)** and a **GitHub
Pages webpage**. Nothing to install except the free GitHub mobile app.

It searches the auto-scrapeable sources live (**eBay, Craigslist, Hemmings,
ClassicCars.com**) and lists one-tap guided searches for everything else
(Facebook Marketplace, Bring a Trailer, Cars & Bids, the Scout specialists, NC/VA
auctions, etc.).

---

## One-time setup (≈3 minutes, all doable on a phone)

1. **Get the workflow onto the `main` branch.**
   GitHub only shows the *Run workflow* button and runs the daily schedule for
   workflows on the default branch. Merge this branch into `main`
   (open the repo → *Pull requests* → merge, or ask me to open a PR you can tap **Merge** on).

2. **Enable GitHub Pages** (for the webpage):
   Repo → **Settings → Pages → Build and deployment → Source: _GitHub Actions_**.

3. **Turn on notifications:** install the **GitHub** mobile app, sign in, and in the
   app's settings enable push notifications. (After the first run you'll be subscribed to
   the listings issue automatically — see below.)

4. *(Optional)* **Choose Craigslist regions:**
   Settings → **Secrets and variables → Actions → Variables → New variable**
   - Name: `CL_REGIONS`
   - Value: comma list of Craigslist subdomains, e.g. `raleigh,charlotte,greensboro,atlanta`
   Leave it unset to use the defaults (raleigh, charlotte, greensboro, norfolk, richmond, washingtondc).

---

## Using it

- **Automatic:** runs every day (~13:00 UTC). No action needed.
- **On demand (the "button"):** repo → **Actions → Scout search → Run workflow**.
  This works from the GitHub mobile web view too.

### Where the results show up

- **Issue:** an issue titled **“🚜 Scout Finder — listings”** is created/updated every run
  with the full current list **plus** the guided manual-search links. When new listings
  appear, the workflow posts a **comment** — that's what triggers your **push
  notification**. Open the issue once and tap **Subscribe** (you're also auto-assigned on
  creation) so notifications keep coming.
- **Webpage:** after a run with Pages enabled, your site is at
  **`https://<your-username>.github.io/scout-finder/`** (the exact URL is printed at the
  end of the *Deploy to GitHub Pages* step). Add it to your home screen for a quick
  bookmark. It shows photos, prices, **NEW** badges, and the manual links.

---

## Notes & limits

- **Daily schedule needs `main`.** Until merged, use *Run workflow* on the branch
  (manual runs can target any branch once the file exists on `main`).
- **State** (which listings you've already seen) is saved to `data/seen.json`, committed
  back by the workflow so "new" means new across runs. If your `main` branch is
  *protected* and blocks the bot's push, allow GitHub Actions to push, or every run will
  re-flag listings as new. The run itself won't fail either way.
- **Anti-bot:** eBay and Craigslist scrape reliably from GitHub's servers. **Hemmings**
  and **ClassicCars.com** sometimes block data-center IPs with a challenge — when that
  happens they simply contribute no auto-results that run, and you use their one-tap
  guided links instead (always listed). The native iOS app, running on your phone's
  residential IP, gets through more often.
- **Cost:** free on public repos. On private repos it uses your Actions minutes (this job
  is tiny — well under a minute).

---

## How it works (for the curious)

```
Actions (cron or button)
  → python -m scout_finder.run
      • fetch eBay / Craigslist / Hemmings / ClassicCars  (scout_finder/fetch.py + parsers.py)
      • diff against data/seen.json  → find NEW
      • render public/index.html (Pages) + out/issue.md + out/new.md
  → commit data/seen.json
  → gh: create/update issue, comment if new  (push notification)
  → deploy public/ to GitHub Pages
```

The parsing rules are shared with the iOS app and covered by tests
(`scripts/validate_parsers.py`, `scripts/test_pipeline.py`, and the Swift
`ScoutFinderTests`).
