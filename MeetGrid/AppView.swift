import SwiftUI

struct AppView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.requiresGoogleLogin {
                LoginGateView()
            } else {
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
                .tint(.meetGridNeonBlue)
                .toolbarBackground(Color.meetGridSurface, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
            }
        }
        .background(Color.meetGridBackground)
        .preferredColorScheme(.dark)
        .task {
            await appState.start()
        }
    }
}

struct LoginGateView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 26) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 34)
                    .fill(Color.meetGridSurface2)
                    .frame(width: 112, height: 112)
                    .overlay {
                        RoundedRectangle(cornerRadius: 34)
                            .stroke(Color.meetGridNeonBlue.opacity(0.35), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.22), radius: 18, y: 10)

                Image(systemName: "calendar")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.meetGridNeonBlue)
            }

            VStack(spacing: 8) {
                Text("MeetGrid")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("로그인하고 바로 모여.")
                    .font(.headline)
                    .foregroundStyle(Color.meetGridMuted)
            }

            Button {
                guard let viewController = UIApplication.shared.meetGridTopViewController else {
                    appState.statusMessage = "Google 로그인 화면을 열 수 없어요."
                    return
                }

                Task {
                    await appState.signInWithGoogle(presenting: viewController)
                }
            } label: {
                Label("Google로 시작", systemImage: "person.crop.circle.badge.checkmark")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.meetGridNeonBlue)
            .disabled(!appState.canStartGoogleLogin)

            if appState.isBusy {
                ProgressView()
                    .tint(.meetGridNeonBlue)
            }

            if let statusMessage = appState.statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.meetGridMuted)
                    .lineLimit(4)
            }

            Spacer()
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.meetGridBackground.ignoresSafeArea())
    }
}
