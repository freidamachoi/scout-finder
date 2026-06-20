import Foundation

/// Small, dependency-free helpers for pulling fields out of HTML and for relevance
/// filtering. Deliberately tolerant — scraping is best-effort, so these return
/// optionals and never throw.
enum Scrape {

    /// Return every capture-group-1 match of `pattern` in `text`.
    static func matches(_ pattern: String, in text: String, options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let ns = text as NSString
        let results = re.matches(in: text, range: NSRange(location: 0, length: ns.length))
        return results.compactMap { m in
            guard m.numberOfRanges > 1, m.range(at: 1).location != NSNotFound else { return nil }
            return ns.substring(with: m.range(at: 1))
        }
    }

    /// First capture-group-1 match, if any.
    static func first(_ pattern: String, in text: String) -> String? {
        matches(pattern, in: text).first
    }

    /// Decode the handful of HTML entities that show up in listing titles/prices.
    static func decodeEntities(_ s: String) -> String {
        var out = s
        let map = ["&amp;": "&", "&#x27;": "'", "&#39;": "'", "&quot;": "\"",
                   "&apos;": "'", "&nbsp;": " ", "&gt;": ">", "&lt;": "<", "&ndash;": "–", "&mdash;": "—"]
        for (k, v) in map { out = out.replacingOccurrences(of: k, with: v) }
        return out
    }

    /// Strip HTML tags and collapse whitespace.
    static func stripTags(_ s: String) -> String {
        let noTags = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        return decodeEntities(noTags)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parse a dollar amount from a string like "$24,500" → 24500.
    static func priceValue(_ s: String?) -> Double? {
        guard let s else { return nil }
        let digits = s.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        guard !digits.isEmpty, let v = Double(digits) else { return nil }
        return v
    }

    /// True if the title plausibly refers to an International Scout 80/800/800A/800B.
    /// Filters out unrelated "scout" hits (Scout II, boats, Ford, etc.).
    static func isRelevant(_ title: String) -> Bool {
        let t = title.lowercased()
        guard t.contains("scout") else { return false }
        let internationalish = t.contains("international") || t.contains("harvester") || t.contains(" ih ") || t.hasPrefix("ih ")
        // Accept explicit early-Scout model numbers even without the marque word.
        let earlyModel = t.contains("scout 80") || t.contains("scout 800") ||
                         t.contains("800a") || t.contains("800b") || t.contains("scout80") || t.contains("scout800")
        // Exclude the later Scout II generation unless the title is clearly an 80/800.
        let scoutII = t.contains("scout ii") || t.contains("scout 2") || t.contains("scoutii")
        if scoutII && !earlyModel { return false }
        return internationalish || earlyModel
    }
}
