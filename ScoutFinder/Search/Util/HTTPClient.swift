import Foundation

/// Thin wrapper around URLSession that sets a browser-like User-Agent (many listing
/// sites return empty/blocked bodies to the default URLSession agent) and returns the
/// decoded string body.
enum HTTPClient {
    /// A desktop Safari UA. Keep this realistic; some sites gate on it.
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
        "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    struct HTTPError: Error { let status: Int }

    static func getString(_ url: URL, accept: String = "text/html,application/xhtml+xml") async throws -> String {
        var req = URLRequest(url: url, timeoutInterval: 25)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(accept, forHTTPHeaderField: "Accept")
        req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw HTTPError(status: http.statusCode)
        }
        return String(decoding: data, as: UTF8.self)
    }

    static func getData(_ url: URL, accept: String = "application/json") async throws -> Data {
        var req = URLRequest(url: url, timeoutInterval: 25)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue(accept, forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw HTTPError(status: http.statusCode)
        }
        return data
    }
}
