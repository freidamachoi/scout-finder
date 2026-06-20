import Foundation

/// Searches ClassicCars.com by reading the schema.org JSON-LD its listing pages embed.
///
/// Note: ClassicCars.com may serve a bot challenge to data-center IPs. From a real
/// device (residential IP, Safari engine) this typically succeeds; if it ever returns
/// a challenge page, `parse` simply yields no JSON-LD and the run continues — the
/// source remains usable via the one-tap manual search in the Sources tab.
struct ClassicCarsProvider: SearchProvider {
    static let providerID = "classiccars"
    let sourceID = "classiccars"

    private static let searchURL = URL(string:
        "https://classiccars.com/listings/find/1960-1972/international/scout")!

    func fetch(settings: SearchSettings) async throws -> [Listing] {
        let html = try await HTTPClient.getString(Self.searchURL)
        return Self.parse(html: html)
    }

    /// Pure, testable parse from page HTML → listings.
    static func parse(html: String) -> [Listing] {
        var out: [Listing] = []
        var seen = Set<String>()
        for v in JSONLD.vehicles(in: html) {
            let title = Scrape.decodeEntities(v.name)
            guard Scrape.isRelevant(title),
                  let urlStr = v.url, let url = URL(string: urlStr),
                  seen.insert(url.absoluteString).inserted else { continue }
            out.append(Listing(
                title: title,
                url: url,
                price: v.priceText,
                priceValue: v.priceValue,
                imageURL: v.imageURL.flatMap(URL.init(string:)),
                location: nil,
                sourceID: "classiccars",
                sourceName: "ClassicCars.com",
                postedAt: nil
            ))
        }
        return out
    }
}
