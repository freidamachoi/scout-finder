# Scout Finder

An iPhone app that searches for **International Harvester Scout 80 / 800 / 800A / 800B**
for sale across the web. It runs **automatically every day** and on demand via a
**Search Now** button, and for sites that require a login (or block automated access)
it gives you a **one-tap guided search with the exact criteria** to run inside the site.

Built with SwiftUI, targets **iOS 17+**, no third-party dependencies.

## Two ways to run it

| | Native iOS app | **GitHub Actions (no Mac, phone-friendly)** |
|---|---|---|
| Needs | Mac + Xcode (+ Apple Dev acct to install on a phone) | just a GitHub account |
| Daily run | iOS background task (best-effort) | reliable cron + a *Run workflow* button |
| Results | in-app Results tab + local notifications | GitHub **Issue + push notifications** & a **GitHub Pages webpage** |
| Live scraping | from your phone's IP (best reach) | from GitHub's servers (eBay/Craigslist reliable; Hemmings/ClassicCars may be bot-blocked) |

**On a phone and want to use it now?** → see **[docs/GITHUB_USAGE.md](docs/GITHUB_USAGE.md)**.
It runs the search on GitHub, posts new finds to an issue (with notifications), and
publishes a webpage — no Mac, no app install. The rest of this README covers the native
iOS app.

---

## What it does

- **Automated search** of login-free sources that expose feeds/structured data:
  - **eBay Motors** — official Browse API when you add a token, otherwise scrapes the
    public search page.
  - **Craigslist** — public RSS feed across each region you configure.
  - **ClassicCars.com** and **Hemmings** — read the schema.org **JSON-LD** embedded in
    their listing pages (a far more stable scrape target than CSS-class regex).
  - Results land in the **Results** tab with a **NEW** badge, price, location, and a
    tap-through to the listing in an in-app browser.
  - *Anti-bot note:* ClassicCars.com and Hemmings use bot protection that can block
    data-center IPs. From a real iPhone (residential IP, Safari engine) they generally
    succeed; if ever blocked, that provider quietly yields nothing and the run
    continues — both remain available via the one-tap manual search in **Sources**.
- **Guided manual search** for every other source in your list (Bring a Trailer,
  Cars & Bids, Classic.com, Hemmings, AutoTempest, Facebook Marketplace, OfferUp,
  Cars.com, CarGurus, the Scout specialists, barn-find/curated, and the NC/VA regional
  auctions). The **Sources** tab opens a prebuilt search in one tap and shows the
  **precise criteria** (terms, year range, sort, save-alert) to run — including the
  "sign in first" note for login-gated sites.
- **Daily background run** via `BGAppRefreshTask` (best-effort, when the phone is idle/
  charging) plus a guaranteed **manual** run.
- **Local notifications** when new listings are discovered.
- On-device persistence of seen listings so "new" actually means new.

> Why "guided manual" for so many sites? Sites like Facebook Marketplace and OfferUp
> require login and actively block scraping; auction houses (Mecum, Barrett-Jackson,
> GAA) and many classic marketplaces are event-driven or JS-only. Rather than ship
> brittle scrapers that silently break, the app gives you a reliable one-tap search
> with the exact criteria — exactly as requested. **Classic.com and AutoTempest are
> aggregators**; setting an alert on those covers a large share of the market.

---

## Build & run

You need a Mac with **Xcode 15+**.

### Option A — XcodeGen (recommended)

```bash
brew install xcodegen      # one time
cd scout-finder
xcodegen generate          # creates ScoutFinder.xcodeproj from project.yml
open ScoutFinder.xcodeproj
```

Select an iPhone simulator (or your device) and press **Run** (⌘R).

### Option B — Manual Xcode setup

1. Xcode → **File ▸ New ▸ Project ▸ iOS App**. Name it `ScoutFinder`,
   Interface **SwiftUI**, Language **Swift**, bundle id `com.scoutfinder.app`.
2. Delete the auto-generated `ContentView.swift` and the default `App` file.
3. Drag the `ScoutFinder/` folder from this repo into the project
   (**Copy items if needed**, create groups).
4. Set the target's **Info.plist** to `ScoutFinder/App/Info.plist`
   (Build Settings → *Info.plist File*), or merge its keys into the generated one —
   the important ones are listed below.
5. Set **iOS Deployment Target** to 17.0.

### Required Info.plist keys (already in `ScoutFinder/App/Info.plist`)

| Key | Value | Why |
|---|---|---|
| `UIBackgroundModes` | `fetch`, `processing` | allow background search |
| `BGTaskSchedulerPermittedIdentifiers` | `com.scoutfinder.app.refresh` | register the daily task |
| `NSAppTransportSecurity ▸ NSAllowsArbitraryLoads` | `true` | some listing sites are HTTP-only |

Local notification permission is requested at runtime via `UNUserNotificationCenter`
(no Info.plist string required).

---

## eBay API key (optional but recommended)

Without a key the app scrapes eBay's public search HTML, which works but can break when
eBay changes markup. For reliable results:

1. Create a free developer account at <https://developer.ebay.com>.
2. Create a keyset and get an **Application (client-credentials) OAuth token** for the
   **Buy ▸ Browse API**.
3. In the app: **Settings ▸ eBay API ▸ token** — paste the OAuth access token.

The token is stored in `UserDefaults` for simplicity; move it to Keychain before
shipping to the App Store (see *Production checklist*).

---

## Tests

There are two layers of tests covering the parsing/filtering logic behind every
automated provider:

**1. XCTest suite (`ScoutFinderTests/`)** — runs on a Mac/simulator:

```bash
xcodegen generate
xcodebuild test -scheme ScoutFinder -destination 'platform=iOS Simulator,name=iPhone 15'
# or just press ⌘U in Xcode
```

Covers: relevance filtering (accepts 80/800/800A/800B, rejects Scout II and unrelated
"scout" hits), price parsing, eBay HTML parsing, Craigslist RSS parsing, ClassicCars.com
+ Hemmings JSON-LD parsing, and `ListingStore` new-listing tracking. Fixtures live in
`ScoutFinderTests/Fixtures/`.

**2. Logic validation harness (`scripts/validate_parsers.py`)** — runs anywhere with
Python 3, no Xcode/network needed. It ports the *exact same* parsing rules and runs them
against the *same fixtures* as the XCTest suite, so the logic can be verified outside a
Mac:

```bash
python3 scripts/validate_parsers.py     # 28 checks: parser/relevance/price logic
python3 scripts/test_pipeline.py        # 11 checks: full GitHub-edition pipeline (new-detection, render)
```

Both run against the same fixtures as the Swift XCTest suite. They were used to validate
the parsers and the GitHub Actions pipeline during development without a Mac or network.

## Testing the daily search

Background tasks don't fire on the simulator on a schedule. To force a run while paused
in the Xcode debugger:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.scoutfinder.app.refresh"]
```

Or just use **Search Now** (Results tab toolbar, or Settings) for an immediate run.

---

## Adding a new automated source

1. Create a type conforming to `SearchProvider` in `ScoutFinder/Search/Providers/`.
2. Give it a unique `providerID` and the `sourceID` of its registry entry.
3. Add it to `SearchCoordinator.providers`.
4. In `SourceRegistry`, set the matching `Source.kind = .automated` and
   `providerID = YourProvider.providerID`.

The scraping helpers in `ScoutFinder/Search/Util/` (`HTTPClient`, `Scrape`, `RSSParser`)
cover most HTML/RSS/JSON cases. `Scrape.isRelevant(_:)` filters out Scout II and
unrelated "scout" hits.

---

## Production checklist (before App Store)

- Move the eBay token to **Keychain**.
- Replace `NSAllowsArbitraryLoads` with per-domain ATS exceptions.
- Add an app icon + launch screen assets.
- Consider a **backend** (cron worker + push notifications) if you need *guaranteed*
  daily runs and more robust scraping than iOS background scheduling allows — the
  provider architecture ports directly to a server. See `docs/ARCHITECTURE.md`.
- Review each site's Terms of Service for automated access.

---

## Project layout

```
ScoutFinder/
  App/            ScoutFinderApp.swift, Info.plist
  Models/         Listing, Source, SearchSettings
  Data/           SourceRegistry (all sources), ListingStore, SettingsStore
  Search/         SearchProvider, SearchCoordinator
    Providers/    EbayProvider, CraigslistProvider, ClassicCarsProvider, HemmingsProvider
    Util/         HTTPClient, ScrapeHelpers, RSSParser, JSONLD
  Background/     BackgroundScheduler (BGAppRefreshTask), NotificationManager
  Views/          RootView, ResultsView, ListingRow, SourcesView, SettingsView, SafariView
ScoutFinderTests/ ParsingTests.swift + Fixtures/ (eBay, Craigslist, ClassicCars, Hemmings)
scout_finder/     GitHub Actions edition (Python): parsers, sources, fetch, render, run
.github/workflows/scout-search.yml   daily cron + manual button + issue/Pages
scripts/          validate_parsers.py, test_pipeline.py (run against the same fixtures)
docs/             ARCHITECTURE.md, SOURCES.md, GITHUB_USAGE.md
project.yml       XcodeGen spec (app + test target + scheme)
```

See `docs/SOURCES.md` for the full source catalog and `docs/ARCHITECTURE.md` for design
notes and the backend option.
