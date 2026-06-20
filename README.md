# Scout Finder

An iPhone app that searches for **International Harvester Scout 80 / 800 / 800A / 800B**
for sale across the web. It runs **automatically every day** and on demand via a
**Search Now** button, and for sites that require a login (or block automated access)
it gives you a **one-tap guided search with the exact criteria** to run inside the site.

Built with SwiftUI, targets **iOS 17+**, no third-party dependencies.

---

## What it does

- **Automated search** of login-free sources that expose feeds/structured data:
  - **eBay Motors** — official Browse API when you add a token, otherwise scrapes the
    public search page.
  - **Craigslist** — public RSS feed across each region you configure.
  - Results land in the **Results** tab with a **NEW** badge, price, location, and a
    tap-through to the listing in an in-app browser.
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
    Providers/    EbayProvider, CraigslistProvider
    Util/         HTTPClient, ScrapeHelpers, RSSParser
  Background/     BackgroundScheduler (BGAppRefreshTask), NotificationManager
  Views/          RootView, ResultsView, ListingRow, SourcesView, SettingsView, SafariView
docs/             ARCHITECTURE.md, SOURCES.md
project.yml       XcodeGen spec
```

See `docs/SOURCES.md` for the full source catalog and `docs/ARCHITECTURE.md` for design
notes and the backend option.
