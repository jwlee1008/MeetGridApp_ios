import SwiftUI
import UIKit

struct GroupsView: View {
    @Environment(AppState.self) private var appState
    @State private var showsSettings = false

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    createAndJoinSection(appState: appState)

                    if let selectedGroup = appState.selectedGroup {
                        selectedGroupSection(selectedGroup)
                        groupSwitcher(selectedGroup: selectedGroup)
                    } else {
                        EmptyStateView(
                            title: "NO CREW",
                            message: "그룹 만들거나 코드 넣기.",
                            systemImage: "person.3.sequence"
                        )
                    }
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Color.meetGridBackground)
            .navigationTitle("MeetGrid")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color.meetGridNeonBlue)
                    }
                    .accessibilityLabel("설정")
                }
            }
            .toolbarBackground(Color.meetGridBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showsSettings) {
                SettingsView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func createAndJoinSection(appState: AppState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEW CREW")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.meetGridNeonBlue)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("", text: Bindable(appState).newGroupName, prompt: Text("그룹 이름").foregroundStyle(Color.meetGridMuted))
                        .meetGridField()
                        .submitLabel(.done)

                    Button {
                        Task {
                            await appState.createGroup()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.meetGridNeonBlue)
                    .disabled(appState.isBusy || appState.requiresGoogleLogin)
                    .accessibilityLabel("그룹 만들기")
                }

                HStack(spacing: 10) {
                    TextField("", text: Bindable(appState).inviteCodeInput, prompt: Text("초대코드").foregroundStyle(Color.meetGridMuted))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .meetGridField()
                        .submitLabel(.join)
                        .onSubmit {
                            Task {
                                await appState.joinGroup()
                            }
                        }

                    Button {
                        Task {
                            await appState.joinGroup()
                        }
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.bordered)
                    .tint(.meetGridNeonPink)
                    .disabled(appState.isBusy || appState.requiresGoogleLogin)
                    .accessibilityLabel("초대코드로 참가")
                }
            }
        }
        .padding(16)
        .background(Color.meetGridSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.meetGridNeonPurple.opacity(0.55), lineWidth: 1)
        }
    }

    private func selectedGroupSection(_ group: FriendGroup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.name)
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(group.totalMembers)명")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.meetGridAcid)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CODE")
                        .font(.caption)
                        .foregroundStyle(Color.meetGridMuted)
                    Text(group.inviteCode)
                        .font(.title3.monospaced().weight(.bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    UIPasteboard.general.string = group.inviteCode
                    appState.statusMessage = "초대코드를 복사했어요."
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.bordered)
                .tint(.meetGridNeonBlue)
                .accessibilityLabel("초대코드 복사")
            }

            FlowLayout(spacing: 8) {
                ForEach(group.members) { member in
                    MemberAvatar(member: member)
                }
            }
        }
        .padding(16)
        .background(Color.meetGridSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.meetGridNeonPink.opacity(0.45), lineWidth: 1)
        }
    }

    private func groupSwitcher(selectedGroup: FriendGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CREWS")
                .font(.caption.weight(.black))
                .foregroundStyle(Color.meetGridNeonPink)

            ForEach(appState.groups) { group in
                Button {
                    appState.select(group)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(group.inviteCode)
                                .font(.caption.monospaced())
                                .foregroundStyle(Color.meetGridMuted)
                        }
                        Spacer()
                        if group.id == selectedGroup.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.meetGridNeonBlue)
                        }
                    }
                    .padding(12)
                    .background(Color.meetGridSurface2, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("설정")
                    .font(.title2.weight(.black))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.meetGridMuted)
            }

            VStack(alignment: .leading, spacing: 12) {
                StatusPill(
                    text: appState.connectionTitle,
                    systemImage: appState.isFirebaseConfigured ? "checkmark.icloud" : "iphone",
                    tint: appState.isFirebaseConfigured ? .meetGridNeonBlue : .meetGridNeonRed
                )

                if appState.currentUserID == nil, appState.isFirebaseConfigured {
                    Button {
                        guard let viewController = UIApplication.shared.meetGridTopViewController else {
                            appState.statusMessage = "Google 로그인 화면을 열 수 없어요."
                            return
                        }
                        Task {
                            await appState.signInWithGoogle(presenting: viewController)
                        }
                    } label: {
                        Label("Google 로그인", systemImage: "person.crop.circle.badge.checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.meetGridNeonPink)
                    .disabled(!appState.canStartGoogleLogin)
                } else if appState.currentUserID != nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.currentMember.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(appState.currentUserEmail ?? "Google 로그인됨")
                            .font(.caption)
                            .foregroundStyle(Color.meetGridMuted)
                            .lineLimit(1)
                    }

                    Button {
                        appState.signOut()
                    } label: {
                        Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.meetGridNeonRed)
                    .disabled(appState.isBusy)
                }

                if appState.isBusy {
                    ProgressView()
                        .tint(.meetGridNeonBlue)
                }

                if let statusMessage = appState.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(Color.meetGridMuted)
                        .lineLimit(3)
                }
            }
            .padding(16)
            .background(Color.meetGridSurface, in: RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .padding(20)
        .background(Color.meetGridBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

extension View {
    func meetGridField() -> some View {
        self
            .padding(.horizontal, 12)
            .frame(height: 44)
            .foregroundStyle(.white)
            .tint(.meetGridNeonBlue)
            .background(Color.meetGridSurface2, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
    }
}

extension UIApplication {
    var meetGridTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .meetGridTopViewController
    }
}

extension UIViewController {
    var meetGridTopViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.meetGridTopViewController
        }

        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.meetGridTopViewController
        }

        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.meetGridTopViewController
        }

        return self
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, width: width)
        return CGSize(width: width, height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var origin = bounds.origin
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if origin.x > bounds.minX, origin.x + size.width > bounds.maxX {
                origin.x = bounds.minX
                origin.y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: origin, proposal: ProposedViewSize(size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [CGSize] {
        var rows: [CGSize] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth > 0, currentWidth + spacing + size.width > width {
                rows.append(CGSize(width: currentWidth, height: currentHeight))
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth += currentWidth == 0 ? size.width : size.width + spacing
                currentHeight = max(currentHeight, size.height)
            }
        }

        if currentWidth > 0 {
            rows.append(CGSize(width: currentWidth, height: currentHeight))
        }

        return rows
    }
}
