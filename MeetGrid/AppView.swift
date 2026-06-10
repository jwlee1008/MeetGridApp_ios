import SwiftUI

struct AppView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GroupsView()
                .tabItem {
                    Label("그룹", systemImage: "person.3")
                }

            AvailabilityView()
                .tabItem {
                    Label("시간", systemImage: "calendar")
                }

            ResultsView()
                .tabItem {
                    Label("결과", systemImage: "chart.cellular")
                }
        }
        .tint(.teal)
        .task {
            await appState.start()
        }
    }
}
