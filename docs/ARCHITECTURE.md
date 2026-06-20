# Architecture

## Overview

Scout Finder is a single-target SwiftUI app. It has two search paths that share one
data model:

1. **Automated providers** — code that fetches and parses a source on-device
   (eBay, Craigslist, ClassicCars.com, Hemmings). Output flows into `ListingStore` and
   the **Results** tab. Each provider separates a **pure parse function** (string →
   `[Listing]`) from its network fetch, so the parsing is unit-tested in isolation.
   Classic-car sites are parsed via schema.org **JSON-LD** (`Util/JSONLD.swift`) rather
   than CSS-class regex, for resilience.
2. **Guided manual sources** — every other site. The app stores a prebuilt search URL
   and exact criteria; the user runs the search inside the site (one tap opens it in an
   in-app Safari sheet). This is the only reliable way to cover login/anti-bot/JS-only
   and event-driven (auction) sites.

```
                +------------------+
   Search Now → | SearchCoordinator| → runs all SearchProviders concurrently
   BG task    → +------------------+
                        |
                        v
                  [Listing] merge
                        |
                        v
                 +--------------+      +------------------+
                 | ListingStore | ───► | ResultsView (UI) |
                 +--------------+      +------------------+
                        |
                        v
                NotificationManager (new finds)

   SourceRegistry ──► SourcesView (browse + guided manual search) ──► SafariView
```

## Key types

| Type | Role |
|---|---|
| `Listing` | One discovered listing. Identity = canonical URL (de-dup + "new" tracking). |
| `Source` | A site. `kind = .automated`/`.manual`, deep link, exact criteria, login flag. |
| `SourceRegistry` | The full catalog of sources (see `docs/SOURCES.md`). |
| `SearchProvider` | Protocol for an automated source. `fetch(settings:) async -> [Listing]`. |
| `SearchCoordinator` | Runs every provider concurrently, merges, reports new listings. |
| `ListingStore` | Disk-persisted listings + new-tracking (`@MainActor ObservableObject`). |
| `SettingsStore` | Persisted `SearchSettings` (keywords, years, ZIP, regions, eBay token). |
| `BackgroundScheduler` | Registers/schedules the daily `BGAppRefreshTask`. |
| `NotificationManager` | Local notifications for new finds. |

## Concurrency

- `SearchCoordinator.run` fans out to providers with a `TaskGroup`; one provider failing
  never fails the run (errors are collected and surfaced, partial results kept).
- `ListingStore` / `SettingsStore` are `@MainActor`. `SettingsStore.load()` is a
  `nonisolated` static so the background task can read settings off the main actor.
- Each provider isolates failure internally too (e.g. Craigslist skips a blocked region
  rather than throwing).

## The daily run

iOS `BGAppRefreshTask` is **best-effort**: the system decides when to run based on usage,
battery, and network — it is not a guaranteed cron. We:

1. Register the handler at launch (`BackgroundScheduler.registerHandlers`).
2. Re-arm `scheduleDailyRefresh()` whenever the app backgrounds and at the start of each
   background run.
3. Always provide a manual **Search Now** path as the guaranteed alternative.

If you need *guaranteed* daily execution, run the search on a server (next section).

## Backend option (future)

The `SearchProvider` protocol and `SearchCoordinator` are pure Swift with no UIKit
dependency, so they port directly to a server-side Swift worker (or can be reimplemented
in any language). A backend would:

- Run providers on a real cron (guaranteed daily, multiple times/day).
- Use headless-browser scraping for JS/anti-bot sites the on-device app can't touch.
- Store listings centrally and send **APNs push** (instead of local) notifications.
- Let the iOS app become a thin viewer over a `/listings` API.

This was offered as an alternative architecture; the shipped app is self-contained so it
needs no hosting or running cost.

## Testing

Provider parsing is the riskiest part of a scraper, so it's isolated and tested:

- `ScoutFinderTests/ParsingTests.swift` — XCTest over fixtures in
  `ScoutFinderTests/Fixtures/` (run with ⌘U / `xcodebuild test`).
- `scripts/validate_parsers.py` — the same rules ported to Python, run against the same
  fixtures, so the logic is verifiable without a Mac or network. See README → "Tests".

Because providers expose pure `parse(...)` statics, the tests never touch the network.

## Extending sources

See README → "Adding a new automated source". To add a guided manual source, append a
`Source(kind: .manual, …)` to the right category array in `SourceRegistry`.
