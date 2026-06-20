import Foundation

/// Searches Craigslist via its public RSS feed (no login, no API key) across each
/// region the user configured in Settings. Craigslist exposes any search as RSS by
/// appending `&format=rss`.
struct CraigslistProvider: SearchProvider {
    static let providerID = "craigslist"
    let sourceID = "craigslist"

    func fetch(settings: SearchSettings) async throws -> [Listing] {
        var collected: [Listing] = []

        // One query per region; "international scout" is broad enough that the
        // relevance filter trims Scout II / unrelated hits afterward.
        await withTaskGroup(of: [Listing].self) { group in
            for region in settings.craigslistRegions {
                group.addTask { await Self.fetchRegion(region) }
            }
            for await batch in group { collected.append(contentsOf: batch) }
        }

        // De-dup by URL across regions.
        var seen = Set<String>()
        return collected.filter { seen.insert($0.id).inserted }
    }

    private static func fetchRegion(_ region: String) async -> [Listing] {
        let term = "international scout"
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://\(region).craigslist.org/search/cta?query=\(encoded)&format=rss")
        else { return [] }

        do {
            let data = try await HTTPClient.getData(url, accept: "application/rss+xml, application/xml")
            let items = RSSParser.parse(data)
            return items.compactMap { item -> Listing? in
                let title = Scrape.decodeEntities(item.title)
                guard Scrape.isRelevant(title), let link = URL(string: item.link) else { return nil }
                // Craigslist RSS titles are "Year Make Model - $price (location)".
                let price = Scrape.first("(\\$[0-9,]+)", in: title)
                return Listing(
                    title: title,
                    url: link,
                    price: price,
                    priceValue: Scrape.priceValue(price),
                    imageURL: nil,
                    location: region.capitalized,
                    sourceID: "craigslist",
                    sourceName: "Craigslist (\(region))",
                    postedAt: item.date
                )
            }
        } catch {
            // A blocked/empty region must not fail the whole run.
            return []
        }
    }
}
