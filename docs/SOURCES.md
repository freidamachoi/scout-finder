# Source catalog

Defined in `ScoutFinder/Data/SourceRegistry.swift`. **Auto** = searched automatically by
the app (Results tab). **Manual** = one-tap guided search with exact criteria (Sources
tab). **Login** = requires sign-in before searching.

## Auction platforms
| Source | Mode | Notes |
|---|---|---|
| Bring a Trailer | Manual | Top Scout auction site; "Follow" for alerts |
| Cars & Bids | Manual | |
| **eBay Motors** | **Auto** | API with token, else HTML scrape |
| AutoHunter | Manual | |
| Hagerty Marketplace | Manual | |
| Mecum Auctions | Manual | Event-based |
| Barrett-Jackson | Manual | Event-based |
| RM Sotheby's | Manual | High-end |
| GAA Classic Cars | Manual | NC-based |
| PCARMARKET | Manual | |
| GovDeals | Manual | Government surplus |

## Classic car marketplaces
| Source | Mode | Notes |
|---|---|---|
| Classic.com | Manual | **Aggregator — set an alert here first** |
| ClassicCars.com | Manual | |
| Classics on Autotrader | Manual | |
| Hemmings | Manual | Supports saved-search alerts |
| OldRide | Manual | |
| Hotrod Hotline | Manual | |
| duPont Registry | Manual | |

## General / local / peer-to-peer
| Source | Mode | Notes |
|---|---|---|
| AutoTempest | Manual | Aggregator (Craigslist + eBay + Cars.com …) |
| **Craigslist** | **Auto** | RSS per configured region |
| Facebook Marketplace | Manual · Login | Best local-find source |
| OfferUp | Manual · Login | |
| Cars.com | Manual | |
| CarGurus | Manual | |

## IH / Scout specialists & community
| Source | Mode | Notes |
|---|---|---|
| Super Scout Specialists | Manual | Rob — 937-525-0000 |
| Anything Scout Marketplace | Manual | |
| Scout Connection | Manual | |
| Fourbie Exchange | Manual | |
| Binder Planet (forum) | Manual · Login | |
| IH Parts America | Manual | Parts; call for leads |
| East Coast Scout Parts | Manual | Annapolis, MD — 410-573-9269 |
| ScoutCo Products | Manual | Harrisonburg, VA |

## Barn-find / curated
| Source | Mode | Notes |
|---|---|---|
| Barn Finds | Manual | Scout tag, editorial |

## Regional (NC / VA)
| Source | Mode | Notes |
|---|---|---|
| Raleigh Classic Car Auctions | Manual | NC event auction |
| GAA Classic Cars (Greensboro) | Manual | NC event auction |

---

### Default search criteria (shown in-app per source)

> Search terms: "International Scout 80", "Scout 800", "Scout 800A", "Scout 800B"
> (try "International Harvester Scout" too). Years: 1960–1971. Set your location/ZIP,
> sort by Newest, and — if the site offers it — Save the search / create an alert.

Login-gated sources prepend a "sign in first" instruction.

### Promoting a Manual source to Auto

If a manual source later proves reliably scrapeable (stable HTML, JSON-LD, or an RSS/API
endpoint), implement a `SearchProvider` for it and flip its registry entry to
`.automated` — see README → "Adding a new automated source". Good next candidates:
**Hemmings** and **ClassicCars.com** (server-rendered listing HTML) and **Classic.com**
(aggregator).
