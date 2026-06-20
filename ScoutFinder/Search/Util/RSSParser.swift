import Foundation

/// Minimal RSS/RDF item parser used by the Craigslist provider. Extracts title, link,
/// and date from `<item>` elements (handles both RSS 2.0 and Craigslist's RDF feed).
final class RSSParser: NSObject, XMLParserDelegate {
    struct Item {
        var title = ""
        var link = ""
        var date: Date?
    }

    private var items: [Item] = []
    private var current: Item?
    private var element = ""
    private var buffer = ""

    private let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parse(_ data: Data) -> [Item] {
        let p = RSSParser()
        let parser = XMLParser(data: data)
        parser.delegate = p
        parser.parse()
        return p.items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        element = elementName
        buffer = ""
        if elementName == "item" {
            current = Item()
            // RDF feeds carry the URL on the item element itself.
            if let about = attributeDict["rdf:about"] ?? attributeDict["about"] {
                current?.link = about
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName {
        case "title": if current != nil { current?.title = text }
        case "link": if current != nil, !text.isEmpty { current?.link = text }
        case "dc:date", "date", "pubDate":
            if current != nil { current?.date = isoFormatter.date(from: text) }
        case "item":
            if let c = current, !c.link.isEmpty { items.append(c) }
            current = nil
        default: break
        }
        buffer = ""
    }
}
