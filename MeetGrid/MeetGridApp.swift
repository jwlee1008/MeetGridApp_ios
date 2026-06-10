import SwiftUI

@main
struct MeetGridApp: App {
    @State private var appState = AppState()

    init() {
        FirebaseBootstrap.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appState)
        }
    }
}
