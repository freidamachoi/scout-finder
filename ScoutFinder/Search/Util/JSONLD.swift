import Foundation

/// A vehicle-like entity extracted from a page's schema.org JSON-LD. This is the most
/// stable scrape target for classic-car listing sites (Hemmings, ClassicCars.com, etc.)
/// — far more resilient than CSS-class regex, which changes constantly.
struct JSONLDVehicle: Equatable {
    let name: String
    let url: String?
    let priceText: String?
    let priceValue: Double?
    let imageURL: String?
}

enum JSONLD {
    /// Pull the raw payloads of every `<script type="application/ld+json">` block.
    static func scripts(in html: String) -> [String] {
        Scrape.matches(
            "<script[^>]*type=\"application/ld\\+json\"[^>]*>(.*?)</script>",
            in: html
        )
    }

    /// Decode all JSON-LD and flatten out any vehicle/product entities found, walking
    /// `@graph`, `itemListElement`, and `item` containers.
    static func vehicles(in html: String) -> [JSONLDVehicle] {
        var out: [JSONLDVehicle] = []
        for raw in scripts(in: html) {
            let cleaned = raw
                .replacingOccurrences(of: "<!--", with: "")
                .replacingOccurrences(of: "-->", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard let data = cleaned.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) else { continue }
            collect(obj, into: &out)
        }
        return out
    }

    // MARK: - Walk

    private static func collect(_ any: Any, into out: inout [JSONLDVehicle]) {
        if let arr = any as? [Any] {
            for el in arr { collect(el, into: &out) }
            return
        }
        guard let dict = any as? [String: Any] else { return }

        // Recurse into common list/wrapper containers.
        if let graph = dict["@graph"] { collect(graph, into: &out) }
        if let items = dict["itemListElement"] { collect(items, into: &out) }
        if let item = dict["item"] { collect(item, into: &out) }

        let type = typeString(dict["@type"])
        let vehicleTypes = ["vehicle", "car", "product", "individualproduct", "motorizedvehicle"]
        guard vehicleTypes.contains(where: { type.contains($0) }) else { return }

        let name = (dict["name"] as? String) ?? ""
        guard !name.isEmpty else { return }
        let url = (dict["url"] as? String) ?? (dict["@id"] as? String)
        let (priceText, priceValue) = price(from: dict["offers"])
        out.append(JSONLDVehicle(
            name: name,
            url: url,
            priceText: priceText,
            priceValue: priceValue,
            imageURL: imageString(dict["image"])
        ))
    }

    private static func typeString(_ any: Any?) -> String {
        if let s = any as? String { return s.lowercased() }
        if let arr = any as? [String] { return arr.joined(separator: ",").lowercased() }
        if let arr = any as? [Any] { return arr.compactMap { $0 as? String }.joined(separator: ",").lowercased() }
        return ""
    }

    private static func price(from any: Any?) -> (String?, Double?) {
        func extract(_ d: [String: Any]) -> (String?, Double?) {
            let raw = d["price"]
                ?? d["lowPrice"]
                ?? (d["priceSpecification"] as? [String: Any])?["price"]
            if let num = raw as? NSNumber {
                let v = num.doubleValue
                return (formatPrice(v), v)
            }
            if let s = raw as? String {
                let v = Scrape.priceValue(s)
                return (v != nil ? formatPrice(v!) : s, v)
            }
            return (nil, nil)
        }
        if let d = any as? [String: Any] { return extract(d) }
        if let arr = any as? [[String: Any]], let first = arr.first { return extract(first) }
        return (nil, nil)
    }

    private static func formatPrice(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return "$" + (f.string(from: NSNumber(value: v)) ?? String(Int(v)))
    }

    private static func imageString(_ any: Any?) -> String? {
        if let s = any as? String { return s }
        if let arr = any as? [Any], let s = arr.first as? String { return s }
        if let d = any as? [String: Any], let s = d["url"] as? String { return s }
        if let arr = any as? [[String: Any]], let s = arr.first?["url"] as? String { return s }
        return nil
    }
}
