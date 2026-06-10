import SwiftUI
import UIKit

struct GroupsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    createAndJoinSection(appState: appState)

                    if let selectedGroup = appState.selectedGroup {
                        selectedGroupSection(selectedGroup)
                        groupSwitcher(selectedGroup: selectedGroup)
                    } else {
                        EmptyStateView(
                            title: "그룹이 없어요",
                            message: "친구 그룹을 만들거나 초대코드로 참가해 보세요.",
                            systemImage: "person.3.sequence"
                        )
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("MeetGrid")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("가능한 시간을 모아서 약속을 빠르게 정해요.")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: 8) {
                StatusPill(
                    text: appState.connectionTitle,
                    systemImage: appState.isFirebaseConfigured ? "checkmark.icloud" : "iphone",
                    tint: appState.isFirebaseConfigured ? .teal : .orange
                )

                if appState.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }

                if let statusMessage = appState.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func createAndJoinSection(appState: AppState) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "시작하기",
                subtitle: "그룹을 만들거나 친구가 준 초대코드로 들어갈 수 있어요."
            )

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    TextField("그룹 이름", text: Bindable(appState).newGroupName)
                        .textFieldStyle(.roundedBorder)
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
                    .disabled(appState.isBusy)
                    .accessibilityLabel("그룹 만들기")
                }

                HStack(spacing: 10) {
                    TextField("초대코드", text: Bindable(appState).inviteCodeInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
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
                    .disabled(appState.isBusy)
                    .accessibilityLabel("초대코드로 참가")
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func selectedGroupSection(_ group: FriendGroup) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: group.name, subtitle: "\(group.totalMembers)명이 참여 중")

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("초대코드")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(group.inviteCode)
                        .font(.title3.monospaced().weight(.bold))
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
                .accessibilityLabel("초대코드 복사")
            }

            if let confirmedSlot = group.confirmedSlot {
                HStack(spacing: 10) {
                    StatusPill(text: "확정", systemImage: "checkmark.circle", tint: .teal)
                    Text(confirmedSlot.displayText)
                        .font(.headline)
                    Spacer()
                    Button("취소") {
                        Task {
                            await appState.clearConfirmedSlot()
                        }
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(12)
                .background(Color.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }

            let recommendations = ScheduleCalculator.recommendations(for: group, limit: 1)
            if let best = recommendations.first {
                HStack(spacing: 12) {
                    Image(systemName: "sparkle.magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.teal)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("가장 많이 겹치는 시간")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(best.slot.displayText) · \(best.summary)")
                            .font(.headline)
                    }
                    Spacer()
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(group.members) { member in
                    MemberAvatar(member: member)
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func groupSwitcher(selectedGroup: FriendGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "내 그룹", subtitle: "작업할 그룹을 바꿀 수 있어요.")

            ForEach(appState.groups) { group in
                Button {
                    appState.select(group)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(group.name)
                                .font(.subheadline.weight(.semibold))
                            Text(group.inviteCode)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if group.id == selectedGroup.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.teal)
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
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
