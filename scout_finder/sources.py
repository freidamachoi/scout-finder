"""Python mirror of the iOS app's SourceRegistry. Drives the manual/guided-search
section of the published page and issue. Keep in sync with
ScoutFinder/Data/SourceRegistry.swift.
"""

STANDARD = ('Terms: "International Scout 80", "Scout 800", "Scout 800A", "Scout 800B" '
            '(also "International Harvester Scout"). Years 1960-1971. Set location/ZIP, '
            "sort by Newest, save the search/alert if offered.")

def _login(extra=""):
    return "Requires login - sign in first. " + STANDARD + ((" " + extra) if extra else "")

# Each: (id, name, category, kind, url, criteria, requires_login, notes)
SOURCES = [
    # ---- Auction platforms
    ("bringatrailer", "Bring a Trailer", "Auction", "manual",
     "https://bringatrailer.com/international/scout-800/",
     STANDARD + ' Click "Follow" for alerts.', False, "Top Scout auction site."),
    ("carsandbids", "Cars & Bids", "Auction", "manual",
     "https://carsandbids.com/search?q=international%20scout", STANDARD, False, None),
    ("ebay", "eBay Motors", "Auction", "auto",
     "https://www.ebay.com/sch/6001/i.html?_nkw=international+scout+800&_sop=10",
     STANDARD, False, "Searched automatically."),
    ("autohunter", "AutoHunter", "Auction", "manual",
     "https://www.autohunter.com/search?q=international%20scout", STANDARD, False, None),
    ("hagerty", "Hagerty Marketplace", "Auction", "manual",
     "https://www.hagerty.com/marketplace/search?q=international+scout", STANDARD, False, None),
    ("mecum", "Mecum Auctions", "Auction", "manual",
     "https://www.mecum.com/search/?q=international+scout",
     STANDARD + " Event-based; note event/lot.", False, None),
    ("barrettjackson", "Barrett-Jackson", "Auction", "manual",
     "https://www.barrett-jackson.com/Events/Search?q=international+scout", STANDARD, False, None),
    ("rmsothebys", "RM Sotheby's", "Auction", "manual",
     "https://rmsothebys.com/search?searchterm=international+scout", STANDARD, False, None),
    ("gaa", "GAA Classic Cars", "Auction", "manual",
     "https://www.gaaclassiccars.com", STANDARD + " Greensboro, NC event auction.", False,
     "NC-based."),
    ("pcarmarket", "PCARMARKET", "Auction", "manual",
     "https://www.pcarmarket.com/search/?q=international+scout", STANDARD, False, None),
    ("govdeals", "GovDeals", "Auction", "manual",
     "https://www.govdeals.com/search?kWord=international+scout",
     STANDARD + " Government surplus.", False, None),

    # ---- Classic car marketplaces
    ("classic_com", "Classic.com (aggregator)", "Classic marketplaces", "manual",
     "https://www.classic.com/m/international-harvester/scout/800/",
     STANDARD + " Aggregator - set an alert here first (highest leverage).", False,
     "Aggregates many sites."),
    ("classiccars", "ClassicCars.com", "Classic marketplaces", "auto",
     "https://classiccars.com/listings/find/1960-1972/international/scout",
     STANDARD, False, "Searched automatically (JSON-LD); manual fallback if blocked."),
    ("classics_autotrader", "Classics on Autotrader", "Classic marketplaces", "manual",
     "https://classics.autotrader.com/classic-cars-for-sale/international_harvester-scout-for-sale",
     STANDARD, False, None),
    ("hemmings", "Hemmings", "Classic marketplaces", "auto",
     "https://www.hemmings.com/classifieds/cars-for-sale/international-harvester/scout/",
     STANDARD + " Supports saved-search email alerts.", False,
     "Searched automatically (JSON-LD); manual fallback if blocked."),
    ("oldride", "OldRide", "Classic marketplaces", "manual",
     "https://www.oldride.com/classifieds/international_scout.html", STANDARD, False, None),
    ("hotrodhotline", "Hotrod Hotline", "Classic marketplaces", "manual",
     "https://www.hotrodhotline.com/classifieds/search?keywords=international+scout",
     STANDARD, False, None),
    ("dupont", "duPont Registry", "Classic marketplaces", "manual",
     "https://www.dupontregistry.com/autos/results/international/scout", STANDARD, False, None),

    # ---- General / local / peer-to-peer
    ("autotempest", "AutoTempest (Craigslist+)", "General / local", "manual",
     "https://www.autotempest.com/results?localization=country&make=international&maxyear=1971&minyear=1968&model=scout&zip=27932",
     STANDARD + " Aggregates Craigslist/eBay/Cars.com - adjust ZIP.", False, "Aggregator."),
    ("craigslist", "Craigslist", "General / local", "auto",
     "https://www.craigslist.org/search/sss?query=international%20scout",
     STANDARD + " Searched automatically per region.", False, "Searched automatically."),
    ("facebook", "Facebook Marketplace", "General / local", "manual",
     "https://www.facebook.com/marketplace/search/?query=international%20scout%20800",
     _login("Set radius (e.g. 500 mi), sort by Date listed: Newest, save the search."),
     True, "Login + anti-bot. Best local-find source - check often."),
    ("offerup", "OfferUp", "General / local", "manual",
     "https://offerup.com/search?q=international+scout",
     _login("Set location radius, sort by Newest."), True, None),
    ("cars_com", "Cars.com", "General / local", "manual",
     "https://www.cars.com/shopping/results/?makes[]=international_harvester&models[]=",
     STANDARD + " Pick make International Harvester, then Scout, max year 1971.", False, None),
    ("cargurus", "CarGurus", "General / local", "manual",
     "https://www.cargurus.com/Cars/l-Used-International-Harvester-Scout", STANDARD, False, None),

    # ---- IH / Scout specialists & community
    ("superscout", "Super Scout Specialists", "Scout specialists", "manual",
     "https://www.superscoutspecialists.com/ih-vehicle-sales",
     "Browse IH Vehicle Sales; call Rob with specific wants.", False, "Rob - 937-525-0000"),
    ("anythingscout", "Anything Scout Marketplace", "Scout specialists", "manual",
     "https://marketplace.anythingscout.com", STANDARD, False, "Scout-specific marketplace."),
    ("scoutconnection", "Scout Connection", "Scout specialists", "manual",
     "https://www.scoutconnection.net/classifieds/", STANDARD, False, None),
    ("fourbie", "Fourbie Exchange", "Scout specialists", "manual",
     "https://fourbieexchange.com/listings/international-harvester/scout", STANDARD, False, None),
    ("binderplanet", "Binder Planet (forum)", "Scout specialists", "manual",
     "https://www.binderplanet.com/forums/forums/binder-classifieds.34/",
     _login("Search the Binder Classifieds section for 80/800/800A/800B."), True, None),
    ("ihparts", "IH Parts America", "Scout specialists", "manual",
     "https://www.ihpartsamerica.com/", "Mostly parts; call for vehicle leads.", False, None),
    ("eastcoastscout", "East Coast Scout Parts", "Scout specialists", "manual",
     "https://www.google.com/search?q=East+Coast+Scout+Parts+Annapolis+MD",
     "Annapolis, MD specialist - call for leads.", False, "Annapolis, MD - 410-573-9269"),
    ("scoutco", "ScoutCo Products", "Scout specialists", "manual",
     "https://www.google.com/search?q=ScoutCo+Products+Harrisonburg+VA",
     "Harrisonburg, VA specialist - call for leads.", False, "Harrisonburg, VA"),

    # ---- Barn-find / curated
    ("barnfinds", "Barn Finds", "Barn-find / curated", "manual",
     "https://barnfinds.com/tag/scout/", "Browse the Scout tag; act fast on good ones.",
     False, None),

    # ---- Regional (NC / VA)
    ("raleighclassic", "Raleigh Classic Car Auctions", "Regional (NC/VA)", "manual",
     "https://www.raleighclassic.com",
     STANDARD + " Event-based (Raleigh, NC) - check the docket.", False, "NC regional."),
    ("gaa_regional", "GAA Classic Cars (Greensboro)", "Regional (NC/VA)", "manual",
     "https://www.gaaclassiccars.com", STANDARD + " Greensboro, NC event auction.",
     False, "Greensboro, NC."),
]

CATEGORY_ORDER = ["Auction", "Classic marketplaces", "General / local",
                  "Scout specialists", "Barn-find / curated", "Regional (NC/VA)"]

def manual_sources():
    return [s for s in SOURCES if s[3] == "manual"]

def grouped_manual():
    by_cat = {c: [] for c in CATEGORY_ORDER}
    for s in manual_sources():
        by_cat.setdefault(s[2], []).append(s)
    return [(c, by_cat[c]) for c in CATEGORY_ORDER if by_cat.get(c)]
