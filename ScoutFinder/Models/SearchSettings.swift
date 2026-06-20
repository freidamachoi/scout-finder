import Foundation

/// User-tunable search parameters. Persisted by SettingsStore.
struct SearchSettings: Codable, Equatable {
    /// Keyword variants searched across providers. Defaults cover every trim the
    /// user cares about.
    var keywords: [String] = [
        "international scout 80",
        "international scout 800",
        "international scout 800a",
        "international scout 800b"
    ]

    /// Model years for the 80 / 800 / 800A / 800B generation (1961–1971).
    var minYear: Int = 1960
    var maxYear: Int = 1971

    /// Home ZIP used for distance-based sources (Craigslist region hints, AutoTempest).
    var zip: String = "27932"

    /// Optional eBay Browse API OAuth token. When set, EbayProvider uses the official
    /// API instead of HTML scraping (more reliable). See README → "eBay API key".
    var ebayAPIKey: String = ""

    /// Craigslist subdomains to query (RSS, no login). Add nearby regions as needed.
    var craigslistRegions: [String] = [
        "raleigh", "charlotte", "greensboro", "norfolk", "richmond", "washingtondc"
    ]

    /// Run the background search once per day when possible.
    var dailyEnabled: Bool = true

    /// Post a local notification when new listings are found.
    var notifyOnNew: Bool = true

    /// The "international scout" base term used for keyword matching/relevance.
    static let baseTerm = "international scout"
}
