import Foundation

/// Searches eBay Motors. Two modes:
///  1. Official Browse API when an OAuth token is set in Settings (reliable, JSON).
///  2. HTML scrape of the public search results page as a no-key fallback (best-effort).
struct EbayProvider: SearchProvider {
    static let providerID = "ebay"
    let sourceID = "ebay"

    func fetch(settings: SearchSettings) async throws -> [Listing] {
        if !settings.ebayAPIKey.trimmingCharacters(in: .whitespaces).isEmpty {
            if let viaAPI = try? await fetchViaAPI(settings: settings), !viaAPI.isEmpty {
                return viaAPI
            }
        }
        return try await fetchViaHTML()
    }

    // MARK: - Browse API

    private func fetchViaAPI(settings: SearchSettings) async throws -> [Listing] {
        let term = "international scout"
        guard let q = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.ebay.com/buy/browse/v1/item_summary/search?q=\(q)&limit=50&category_ids=6001&sort=newlyListed")
        else { return [] }

        var req = URLRequest(url: url, timeoutInterval: 25)
        req.setValue("Bearer \(settings.ebayAPIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("EBAY_US", forHTTPHeaderField: "X-EBAY-C-MARKETPLACE-ID")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw HTTPClient.HTTPError(status: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(BrowseResponse.self, from: data)
        return (decoded.itemSummaries ?? []).compactMap { s -> Listing? in
            guard Scrape.isRelevant(s.title), let link = URL(string: s.itemWebUrl) else { return nil }
            let priceStr = s.price.map { "$" + $0.value }
            return Listing(
                title: s.title,
                url: link,
                price: priceStr,
                priceValue: s.price.flatMap { Double($0.value) },
                imageURL: s.image?.imageUrl.flatMap(URL.init(string:)),
                location: s.itemLocation?.country,
                sourceID: "ebay",
                sourceName: "eBay Motors",
                postedAt: nil
            )
        }
    }

    private struct BrowseResponse: Decodable { let itemSummaries: [Summary]? }
    private struct Summary: Decodable {
        let title: String
        let itemWebUrl: String
        let price: Money?
        let image: Img?
        let itemLocation: Loc?
    }
    private struct Money: Decodable { let value: String }
    private struct Img: Decodable { let imageUrl: String }
    private struct Loc: Decodable { let country: String? }

    // MARK: - HTML fallback

    private func fetchViaHTML() async throws -> [Listing] {
        guard let url = URL(string: "https://www.ebay.com/sch/6001/i.html?_nkw=international+scout&_sop=10&_ipg=60")
        else { return [] }
        let html = try await HTTPClient.getString(url)

        // eBay renders each result inside an `<li class="s-item ...">` block.
        let blocks = html.components(separatedBy: "class=\"s-item")
        var out: [Listing] = []
        for block in blocks.dropFirst() {
            guard let href = Scrape.first("href=\"(https://www.ebay.com/itm/[^\"]+)\"", in: block),
                  let link = URL(string: href.replacingOccurrences(of: "&amp;", with: "&"))
            else { continue }

            let rawTitle = Scrape.first("s-item__title\"[^>]*>(?:<span[^>]*>)?([^<]+)", in: block)
                ?? Scrape.first("s-item__title[^>]*>(.*?)</", in: block)
            let title = Scrape.stripTags(rawTitle ?? "")
            guard !title.isEmpty, !title.lowercased().contains("shop on ebay"),
                  Scrape.isRelevant(title) else { continue }

            let price = Scrape.first("s-item__price\"[^>]*>(?:<span[^>]*>)?([^<]+)", in: block).map(Scrape.stripTags)
            let img = Scrape.first("src=\"(https://i.ebayimg.com/[^\"]+)\"", in: block)

            out.append(Listing(
                title: title,
                url: link,
                price: price,
                priceValue: Scrape.priceValue(price),
                imageURL: img.flatMap(URL.init(string:)),
                location: nil,
                sourceID: "ebay",
                sourceName: "eBay Motors",
                postedAt: nil
            ))
        }
        // De-dup by URL.
        var seen = Set<String>()
        return out.filter { seen.insert($0.id).inserted }
    }
}
