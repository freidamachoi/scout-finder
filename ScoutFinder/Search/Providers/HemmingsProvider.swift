import Foundation

/// Searches Hemmings by reading the schema.org JSON-LD on its classifieds results page.
///
/// Same caveat as ClassicCars.com: Hemmings uses bot protection that can block
/// data-center IPs. On a real device this generally works; if blocked, `parse` returns
/// nothing and the run continues, with the manual one-tap search always available.
struct HemmingsProvider: SearchProvider {
    static let providerID = "hemmings"
    let sourceID = "hemmings"

    private static let searchURL = URL(string:
        "https://www.hemmings.com/classifieds/cars-for-sale/international-harvester/scout/")!

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
                sourceID: "hemmings",
                sourceName: "Hemmings",
                postedAt: nil
            ))
        }
        return out
    }
}
