import Foundation

/// The complete catalog of sources the app knows about. Automated sources are wired
/// to a SearchProvider via `providerID`; every other source is a one-tap guided
/// manual search with the exact criteria to run inside the site.
///
/// URLs come from the operator-supplied source list. Where a site supports it, the
/// deep link is prebuilt to the Scout search; otherwise it lands on the site's search
/// page and the `criteria` string tells the user precisely what to enter.
enum SourceRegistry {

    /// Standard criteria block shown for guided/manual sources.
    private static let standardCriteria = """
    Search terms: "International Scout 80", "Scout 800", "Scout 800A", "Scout 800B" \
    (try "International Harvester Scout" too).
    Years: 1960–1971.
    Set your location/ZIP, sort by Newest, and — if the site offers it — Save the \
    search or create an alert so you get notified of new listings.
    """

    private static func loginCriteria(_ extra: String = "") -> String {
        "Requires login — sign in first, then run:\n" + standardCriteria + (extra.isEmpty ? "" : "\n" + extra)
    }

    private static func url(_ s: String) -> URL { URL(string: s)! }

    static let all: [Source] = auction + classicMarkets + general + specialists + barnFinds + regional

    // MARK: - Auction Platforms

    static let auction: [Source] = [
        Source(id: "bringatrailer", name: "Bring a Trailer", category: .auction, kind: .manual,
               searchURL: url("https://bringatrailer.com/international/scout-800/"),
               criteria: standardCriteria + "\nAlso check the live-auctions tab and click \"Follow\" to get alerts.",
               requiresLogin: false,
               providerID: nil,
               notes: "Top auction site for Scouts. Following a search/model sends you new-listing emails."),

        Source(id: "carsandbids", name: "Cars & Bids", category: .auction, kind: .manual,
               searchURL: url("https://carsandbids.com/search?q=international%20scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil,
               notes: "Modern-enthusiast auctions; Scouts appear periodically."),

        Source(id: "ebay", name: "eBay Motors", category: .auction, kind: .automated,
               searchURL: url("https://www.ebay.com/sch/6001/i.html?_nkw=international+scout+800&_sop=10"),
               criteria: standardCriteria + "\nUse the in-app automatic search; this link opens the same query on eBay.",
               requiresLogin: false,
               providerID: EbayProvider.providerID,
               notes: "Searched automatically by the app. Set an eBay API key in Settings for best reliability."),

        Source(id: "autohunter", name: "AutoHunter", category: .auction, kind: .manual,
               searchURL: url("https://www.autohunter.com/search?q=international%20scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: "ClassicCars.com's auction arm."),

        Source(id: "hagerty", name: "Hagerty Marketplace", category: .auction, kind: .manual,
               searchURL: url("https://www.hagerty.com/marketplace/search?q=international+scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "mecum", name: "Mecum Auctions", category: .auction, kind: .manual,
               searchURL: url("https://www.mecum.com/search/?q=international+scout"),
               criteria: standardCriteria + "\nResults are tied to scheduled auction events — note the event/date and lot number.",
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "barrettjackson", name: "Barrett-Jackson", category: .auction, kind: .manual,
               searchURL: url("https://www.barrett-jackson.com/Events/Search?q=international+scout"),
               criteria: standardCriteria + "\nCheck both upcoming docket and past results.",
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "rmsothebys", name: "RM Sotheby's", category: .auction, kind: .manual,
               searchURL: url("https://rmsothebys.com/search?searchterm=international+scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: "High-end; Scouts are rare here but worth a periodic check."),

        Source(id: "gaa", name: "GAA Classic Cars", category: .auction, kind: .manual,
               searchURL: url("https://www.gaaclassiccars.com"),
               criteria: standardCriteria + "\nGAA is event-based (Greensboro, NC). Browse the current/upcoming docket for Scouts.",
               requiresLogin: false, providerID: nil, notes: "NC-based auction house."),

        Source(id: "pcarmarket", name: "PCARMARKET", category: .auction, kind: .manual,
               searchURL: url("https://www.pcarmarket.com/search/?q=international+scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "govdeals", name: "GovDeals", category: .auction, kind: .manual,
               searchURL: url("https://www.govdeals.com/search?kWord=international+scout"),
               criteria: standardCriteria + "\nGovernment surplus — listings are sporadic; sort by newest.",
               requiresLogin: false, providerID: nil, notes: "Surplus/seized vehicles; occasional fleet Scouts."),
    ]

    // MARK: - Classic Car Marketplaces

    static let classicMarkets: [Source] = [
        Source(id: "classic_com", name: "Classic.com (aggregator)", category: .classicMarket, kind: .manual,
               searchURL: url("https://www.classic.com/m/international-harvester/scout/800/"),
               criteria: standardCriteria + "\nClassic.com aggregates most other sites — create a free alert here first; it's the single highest-leverage move.",
               requiresLogin: false, providerID: nil,
               notes: "Aggregator. A saved Classic.com alert covers a large share of the market."),

        Source(id: "classiccars", name: "ClassicCars.com", category: .classicMarket, kind: .manual,
               searchURL: url("https://classiccars.com/listings/find/1968-1980/international/scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "classics_autotrader", name: "Classics on Autotrader", category: .classicMarket, kind: .manual,
               searchURL: url("https://classics.autotrader.com/classic-cars-for-sale/international_harvester-scout-for-sale"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "hemmings", name: "Hemmings", category: .classicMarket, kind: .manual,
               searchURL: url("https://www.hemmings.com/classifieds/cars-for-sale/international-harvester/scout/"),
               criteria: standardCriteria + "\nHemmings supports email alerts on a saved search.",
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "oldride", name: "OldRide", category: .classicMarket, kind: .manual,
               searchURL: url("https://www.oldride.com/classifieds/international_scout.html"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "hotrodhotline", name: "Hotrod Hotline", category: .classicMarket, kind: .manual,
               searchURL: url("https://www.hotrodhotline.com/classifieds/search?keywords=international+scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "dupont", name: "duPont Registry", category: .classicMarket, kind: .manual,
               searchURL: url("https://www.dupontregistry.com/autos/results/international/scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),
    ]

    // MARK: - General / Local / Peer-to-Peer

    static let general: [Source] = [
        Source(id: "autotempest", name: "AutoTempest (Craigslist+)", category: .general, kind: .manual,
               searchURL: url("https://www.autotempest.com/results?localization=country&make=international&maxyear=1971&minyear=1968&model=scout&zip=27932"),
               criteria: standardCriteria + "\nAutoTempest aggregates Craigslist, eBay, Cars.com and more in one view — adjust the ZIP to your area.",
               requiresLogin: false, providerID: nil, notes: "Aggregator across many general marketplaces."),

        Source(id: "craigslist", name: "Craigslist", category: .general, kind: .automated,
               searchURL: url("https://www.craigslist.org/search/sss?query=international%20scout"),
               criteria: standardCriteria + "\nSearched automatically per region (set your regions in Settings).",
               requiresLogin: false,
               providerID: CraigslistProvider.providerID,
               notes: "Searched automatically by the app across your configured regions."),

        Source(id: "facebook", name: "Facebook Marketplace", category: .general, kind: .manual,
               searchURL: url("https://www.facebook.com/marketplace/search/?query=international%20scout%20800"),
               criteria: loginCriteria("Set radius (e.g. 500 mi) around your city, sort by Date listed: Newest first, and save the search."),
               requiresLogin: true, providerID: nil,
               notes: "Login + anti-bot — cannot be auto-searched. Best local-find source; check often."),

        Source(id: "offerup", name: "OfferUp", category: .general, kind: .manual,
               searchURL: url("https://offerup.com/search?q=international+scout"),
               criteria: loginCriteria("Set your location radius and sort by Newest."),
               requiresLogin: true, providerID: nil, notes: "Account usually required to contact sellers."),

        Source(id: "cars_com", name: "Cars.com", category: .general, kind: .manual,
               searchURL: url("https://www.cars.com/shopping/results/?makes[]=international_harvester&models[]="),
               criteria: standardCriteria + "\nSelect make International Harvester, then the Scout model, and set max year 1971.",
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "cargurus", name: "CarGurus", category: .general, kind: .manual,
               searchURL: url("https://www.cargurus.com/Cars/l-Used-International-Harvester-Scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),
    ]

    // MARK: - IH / Scout Specialists & Community

    static let specialists: [Source] = [
        Source(id: "superscout", name: "Super Scout Specialists", category: .specialist, kind: .manual,
               searchURL: url("https://www.superscoutspecialists.com/ih-vehicle-sales"),
               criteria: "Browse the IH Vehicle Sales page for current inventory. Call Rob with specific wants.",
               requiresLogin: false, providerID: nil, notes: "Rob — 937-525-0000"),

        Source(id: "anythingscout", name: "Anything Scout Marketplace", category: .specialist, kind: .manual,
               searchURL: url("https://marketplace.anythingscout.com"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: "Scout-specific community marketplace."),

        Source(id: "scoutconnection", name: "Scout Connection", category: .specialist, kind: .manual,
               searchURL: url("https://www.scoutconnection.net/classifieds/"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "fourbie", name: "Fourbie Exchange", category: .specialist, kind: .manual,
               searchURL: url("https://fourbieexchange.com/listings/international-harvester/scout"),
               criteria: standardCriteria,
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "binderplanet", name: "Binder Planet (forum classifieds)", category: .specialist, kind: .manual,
               searchURL: url("https://www.binderplanet.com/forums/forums/binder-classifieds.34/"),
               criteria: loginCriteria("Use the forum search within the Binder Classifieds section for 80/800/800A/800B."),
               requiresLogin: true, providerID: nil, notes: "Account often needed to view contact info / post WTB."),

        Source(id: "ihparts", name: "IH Parts America", category: .specialist, kind: .manual,
               searchURL: url("https://www.ihpartsamerica.com/"),
               criteria: "Primarily parts, but worth a periodic check and a call for vehicle leads.",
               requiresLogin: false, providerID: nil, notes: nil),

        Source(id: "eastcoastscout", name: "East Coast Scout Parts", category: .specialist, kind: .manual,
               searchURL: url("https://www.google.com/search?q=East+Coast+Scout+Parts+Annapolis+MD"),
               criteria: "Annapolis, MD specialist. Call for vehicle and lead availability.",
               requiresLogin: false, providerID: nil, notes: "Annapolis, MD — 410-573-9269"),

        Source(id: "scoutco", name: "ScoutCo Products", category: .specialist, kind: .manual,
               searchURL: url("https://www.google.com/search?q=ScoutCo+Products+Harrisonburg+VA"),
               criteria: "Harrisonburg, VA specialist. Call for vehicle and lead availability.",
               requiresLogin: false, providerID: nil, notes: "Harrisonburg, VA"),
    ]

    // MARK: - Barn-Find / Curated

    static let barnFinds: [Source] = [
        Source(id: "barnfinds", name: "Barn Finds", category: .barnFind, kind: .manual,
               searchURL: url("https://barnfinds.com/tag/scout/"),
               criteria: "Browse the Scout tag for curated finds. Listings are editorial — act fast on good ones.",
               requiresLogin: false, providerID: nil, notes: nil),
    ]

    // MARK: - Regional (NC / VA)

    static let regional: [Source] = [
        Source(id: "raleighclassic", name: "Raleigh Classic Car Auctions", category: .regional, kind: .manual,
               searchURL: url("https://www.raleighclassic.com"),
               criteria: standardCriteria + "\nEvent-based (Raleigh, NC). Check the current/upcoming consignment list for Scouts.",
               requiresLogin: false, providerID: nil, notes: "NC regional auction."),

        Source(id: "gaa_regional", name: "GAA Classic Cars (Greensboro, NC)", category: .regional, kind: .manual,
               searchURL: url("https://www.gaaclassiccars.com"),
               criteria: standardCriteria + "\nGreensboro, NC event auction — browse the docket.",
               requiresLogin: false, providerID: nil, notes: "Greensboro, NC."),
    ]

    /// Lookup helpers.
    static func source(id: String) -> Source? { all.first { $0.id == id } }
    static var automated: [Source] { all.filter { $0.kind == .automated } }
    static var manual: [Source] { all.filter { $0.kind == .manual } }
    static func grouped() -> [(SourceCategory, [Source])] {
        SourceCategory.allCases.map { cat in (cat, all.filter { $0.category == cat }) }
            .filter { !$0.1.isEmpty }
    }
}
