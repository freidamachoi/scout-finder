import XCTest
@testable import ScoutFinder

/// Unit tests for the pure parsing/filtering logic behind every automated provider.
/// These run with ⌘U in Xcode, or `xcodebuild test`. They use the HTML/RSS fixtures
/// in ScoutFinderTests/Fixtures (also exercised by scripts/validate_parsers.py).
final class ParsingTests: XCTestCase {

    // MARK: - Fixtures

    private func fixture(_ name: String, _ ext: String) throws -> String {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: ext),
                                "missing fixture \(name).\(ext)")
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Relevance filter

    func testRelevanceAcceptsEarlyScouts() {
        XCTAssertTrue(Scrape.isRelevant("1965 International Harvester Scout 800"))
        XCTAssertTrue(Scrape.isRelevant("1963 International Scout 80"))
        XCTAssertTrue(Scrape.isRelevant("1969 Scout 800A project"))
        XCTAssertTrue(Scrape.isRelevant("1971 INTERNATIONAL SCOUT 800B"))
    }

    func testRelevanceRejectsUnrelatedAndScoutII() {
        XCTAssertFalse(Scrape.isRelevant("1972 Ford Bronco"))
        XCTAssertFalse(Scrape.isRelevant("Boy Scout memorabilia lot"))
        XCTAssertFalse(Scrape.isRelevant("1974 International Scout II"))   // later generation
        XCTAssertFalse(Scrape.isRelevant("Jeep Scrambler"))
    }

    // MARK: - Price parsing

    func testPriceValueParsing() {
        XCTAssertEqual(Scrape.priceValue("$24,500"), 24500)
        XCTAssertEqual(Scrape.priceValue("$31,500.00"), 31500)
        XCTAssertNil(Scrape.priceValue("—"))
        XCTAssertNil(Scrape.priceValue(nil))
    }

    // MARK: - eBay HTML

    func testEbayHTMLParsing() throws {
        let html = try fixture("ebay", "html")
        let listings = EbayProvider.parseSearchHTML(html)

        // Two relevant Scouts; "Shop on eBay" and the Bronco are dropped.
        XCTAssertEqual(listings.count, 2)
        let titles = listings.map(\.title)
        XCTAssertTrue(titles.contains("1967 International Scout 800 4x4"))
        XCTAssertTrue(titles.contains("1971 International Scout 800B"))
        XCTAssertFalse(titles.contains(where: { $0.lowercased().contains("shop on ebay") }))

        let first = try XCTUnwrap(listings.first { $0.title.contains("1967") })
        XCTAssertEqual(first.priceValue, 22000)
        XCTAssertEqual(first.url.absoluteString, "https://www.ebay.com/itm/111222333?hash=item5f&var=0")
        XCTAssertEqual(first.imageURL?.absoluteString, "https://i.ebayimg.com/images/g/abcAAOSw/s-l225.jpg")
    }

    // MARK: - Craigslist RSS

    func testCraigslistRSSParsing() throws {
        let data = try XCTUnwrap(fixture("craigslist", "xml").data(using: .utf8))
        let listings = CraigslistProvider.parse(rss: data, region: "raleigh")

        // Scout 800 + Scout 80 pass; Bronco filtered.
        XCTAssertEqual(listings.count, 2)
        let scout800 = try XCTUnwrap(listings.first { $0.title.contains("Scout 800") })
        XCTAssertEqual(scout800.priceValue, 18500)
        XCTAssertEqual(scout800.location, "Raleigh")
        XCTAssertEqual(scout800.sourceName, "Craigslist (raleigh)")
        XCTAssertNotNil(scout800.postedAt)
    }

    // MARK: - ClassicCars.com JSON-LD

    func testClassicCarsJSONLDParsing() throws {
        let html = try fixture("classiccars", "html")
        let listings = ClassicCarsProvider.parse(html: html)

        // Two Scouts (ItemList + standalone Vehicle); Camaro filtered.
        XCTAssertEqual(listings.count, 2)
        let scout800 = try XCTUnwrap(listings.first { $0.title.contains("Scout 800") })
        XCTAssertEqual(scout800.priceValue, 24500)
        XCTAssertEqual(scout800.sourceName, "ClassicCars.com")
        let scout800a = try XCTUnwrap(listings.first { $0.title.contains("800A") })
        XCTAssertEqual(scout800a.priceValue, 19995)   // from AggregateOffer.lowPrice
    }

    // MARK: - Hemmings JSON-LD

    func testHemmingsJSONLDParsing() throws {
        let html = try fixture("hemmings", "html")
        let listings = HemmingsProvider.parse(html: html)

        // Scout 800 + 800B pass; Scout II filtered.
        XCTAssertEqual(listings.count, 2)
        let prices = Set(listings.compactMap(\.priceValue))
        XCTAssertEqual(prices, [27500, 33900])
        XCTAssertFalse(listings.contains { $0.title.lowercased().contains("scout ii") })
    }

    // MARK: - ListingStore new-tracking

    @MainActor
    func testListingStoreMergeTracksNew() {
        let store = ListingStore()
        store.clearAll()

        let a = makeListing("https://example.com/a", "1965 International Scout 800")
        let b = makeListing("https://example.com/b", "1969 International Scout 800A")

        let firstRun = store.merge([a, b])
        XCTAssertEqual(firstRun.count, 2)
        XCTAssertEqual(store.newCount, 2)

        store.markAllSeen()
        XCTAssertEqual(store.newCount, 0)

        // Re-seeing a + a brand-new c: only c is new.
        let c = makeListing("https://example.com/c", "1971 International Scout 800B")
        let secondRun = store.merge([a, c])
        XCTAssertEqual(secondRun.count, 1)
        XCTAssertEqual(secondRun.first?.url.absoluteString, "https://example.com/c")
        XCTAssertEqual(store.listings.count, 3)

        store.clearAll()
    }

    private func makeListing(_ url: String, _ title: String) -> Listing {
        Listing(title: title, url: URL(string: url)!, price: nil, priceValue: nil,
                imageURL: nil, location: nil, sourceID: "test", sourceName: "Test", postedAt: nil)
    }
}
