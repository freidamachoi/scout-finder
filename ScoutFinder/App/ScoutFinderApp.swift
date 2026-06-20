import SwiftUI
import BackgroundTasks

@main
struct ScoutFinderApp: App {
    // Shared app-wide state.
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var listingStore = ListingStore()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Must run at launch, before the app finishes launching, so iOS can hand us
        // background time. Registers the BGAppRefreshTask handler.
        BackgroundScheduler.shared.registerHandlers()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settingsStore)
                .environmentObject(listingStore)
                .task {
                    // Ask for notification permission once so we can alert on new finds.
                    await NotificationManager.shared.requestAuthorizationIfNeeded()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                // Re-arm the daily background search whenever we leave the foreground.
                if settingsStore.settings.dailyEnabled {
                    BackgroundScheduler.shared.scheduleDailyRefresh()
                }
            }
        }
    }
}
