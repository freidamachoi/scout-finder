import Foundation
import Combine

/// Persists SearchSettings to UserDefaults and publishes changes to the UI.
@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: SearchSettings {
        didSet { save() }
    }

    private let key = "scoutfinder.settings.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(SearchSettings.self, from: data) {
            settings = decoded
        } else {
            settings = SearchSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Non-isolated snapshot for use by background tasks (which read settings off the
    /// main actor). UserDefaults access is thread-safe.
    nonisolated static func load() -> SearchSettings {
        let key = "scoutfinder.settings.v1"
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(SearchSettings.self, from: data) {
            return decoded
        }
        return SearchSettings()
    }
}
