import Foundation
import BackgroundTasks

/// Drives the daily background search using BGAppRefreshTask.
///
/// iOS does not guarantee an exact daily run — it schedules opportunistically based on
/// usage, charging, and network. We request "no earlier than ~24h" and re-arm after
/// every run. The manual "Search Now" button is always available as a guaranteed path.
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()
    private init() {}

    /// Must match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    static let refreshTaskID = "com.scoutfinder.app.refresh"

    /// Call once at launch (from the App initializer) to install the handler.
    func registerHandlers() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { task.setTaskCompleted(success: false); return }
            self.handleRefresh(task: refreshTask)
        }
    }

    /// Ask iOS to run us again in ~24 hours.
    func scheduleDailyRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Common in the simulator (BG tasks are device-only). Safe to ignore.
            print("BGTaskScheduler submit failed: \(error)")
        }
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        // Always re-arm for the next day first.
        scheduleDailyRefresh()

        let work = Task {
            let settings = SettingsStore.load()
            let store = await ListingStore()   // its own instance for the background run
            let result = await SearchCoordinator.run(settings: settings, store: store)
            if settings.notifyOnNew {
                await NotificationManager.shared.notifyNewListings(result.newListings)
            }
            task.setTaskCompleted(success: result.errors.count < SearchCoordinator.providers.count)
        }

        task.expirationHandler = { work.cancel() }
    }

    /// Developer helper: simulate a background launch from a paused debugger with:
    ///   e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.scoutfinder.app.refresh"]
    /// (See README → "Testing the daily search".)
}
