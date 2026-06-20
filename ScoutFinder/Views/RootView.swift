import SwiftUI

struct RootView: View {
    @EnvironmentObject var listingStore: ListingStore

    var body: some View {
        TabView {
            ResultsView()
                .tabItem { Label("Results", systemImage: "car.2.fill") }
                .badge(listingStore.newCount)

            SourcesView()
                .tabItem { Label("Sources", systemImage: "list.bullet.rectangle") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
