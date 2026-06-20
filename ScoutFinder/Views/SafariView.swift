import SwiftUI
import SafariServices

/// Opens a URL in an in-app Safari sheet (keeps logins/cookies, supports the guided
/// manual searches without leaving the app).
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// Convenience modifier to present a SafariView from an optional URL binding.
extension View {
    func safariSheet(url: Binding<URL?>) -> some View {
        sheet(isPresented: Binding(
            get: { url.wrappedValue != nil },
            set: { if !$0 { url.wrappedValue = nil } }
        )) {
            if let u = url.wrappedValue { SafariView(url: u).ignoresSafeArea() }
        }
    }
}
