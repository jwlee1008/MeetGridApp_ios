import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var currentMember = SampleData.currentMember
    var groups: [FriendGroup] = [SampleData.starterGroup]
    var selectedGroupID: String? = SampleData.starterGroup.id
    var newGroupName = ""
    var inviteCodeInput = ""
    var statusMessage: String?
    var isBusy = false
    var currentUserID: String?

    @ObservationIgnored private var firebaseRepository: FirebaseGroupRepository?

    var selectedGroup: FriendGroup? {
        guard let selectedGroupID else { return groups.first }
        return groups.first { $0.id == selectedGroupID }
    }

    var isFirebaseConfigured: Bool {
        FirebaseBootstrap.isConfigured
    }

    var connectionTitle: String {
        if !isFirebaseConfigured {
            return "로컬 데모"
        }
        if currentUserID == nil {
            return "Firebase 준비 중"
        }
        return "Firebase 연결됨"
    }

    func select(_ group: FriendGroup) {
        selectedGroupID = group.id
    }

    func start() async {
        guard isFirebaseConfigured else {
            statusMessage = "Firebase 설정 파일이 없어서 로컬 데모로 실행 중이에요."
            return
        }

        await runBusy {
            let uid = try await ensureSignedIn()
            let fetchedGroups = try await repository().fetchGroups(forMemberID: uid)
            groups = fetchedGroups
            selectedGroupID = fetchedGroups.first?.id
            statusMessage = fetchedGroups.isEmpty
                ? "Firebase 연결 완료. 그룹을 만들거나 초대코드를 입력해 주세요."
                : "Firebase에서 내 그룹 \(fetchedGroups.count)개를 불러왔어요."
        }
    }

    func createGroup() async {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let groupName = name.isEmpty ? "새 약속 그룹" : name

        if isFirebaseConfigured {
            await runBusy {
                _ = try await ensureSignedIn()
                let group = makeGroup(named: groupName, inviteCode: Self.makeInviteCode(), members: [currentMember])
                try await repository().save(group)
                upsert(group)
                selectedGroupID = group.id
                newGroupName = ""
                statusMessage = "'\(groupName)' 그룹을 Firebase에 만들었어요."
            }
        } else {
            let group = makeGroup(named: groupName, inviteCode: Self.makeInviteCode(), members: [currentMember])
            upsert(group)
            selectedGroupID = group.id
            newGroupName = ""
            statusMessage = "'\(groupName)' 그룹을 만들었어요."
        }
    }

    func joinGroup() async {
        let code = inviteCodeInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !code.isEmpty else {
            statusMessage = "초대코드를 입력해 주세요."
            return
        }

        if let existing = groups.first(where: { $0.inviteCode == code }) {
            selectedGroupID = existing.id
            inviteCodeInput = ""
            statusMessage = "이미 들어와 있는 그룹이에요."
            return
        }

        if isFirebaseConfigured {
            await runBusy {
                _ = try await ensureSignedIn()
                guard var group = try await repository().fetch(inviteCode: code) else {
                    statusMessage = "해당 초대코드의 그룹을 찾지 못했어요."
                    return
                }

                if !group.members.contains(where: { $0.id == currentMember.id }) {
                    group.members.append(currentMember)
                    group.availability[currentMember.id] = group.availability[currentMember.id, default: []]
                    try await repository().save(group)
                }

                upsert(group)
                selectedGroupID = group.id
                inviteCodeInput = ""
                statusMessage = "'\(group.name)' 그룹에 참가했어요."
            }
        } else {
            let friend = Member(id: "friend-\(code)", name: "초대 친구", color: .mint)
            let group = makeGroup(named: "초대코드 \(code)", inviteCode: code, members: [currentMember, friend])
            upsert(group)
            selectedGroupID = group.id
            inviteCodeInput = ""
            statusMessage = "데모 그룹에 참가했어요. Firebase 연결 후에는 실제 그룹을 불러옵니다."
        }
    }

    func toggleMyAvailability(_ slot: TimeSlot) async {
        guard var group = selectedGroup else { return }

        var slots = group.availability[currentMember.id, default: []]
        if slots.contains(slot) {
            slots.remove(slot)
        } else {
            slots.insert(slot)
        }
        group.availability[currentMember.id] = slots
        upsert(group)

        await saveIfNeeded(group, successMessage: "가능 시간이 저장됐어요.")
    }

    func confirm(_ overlap: SlotOverlap) async {
        guard var group = selectedGroup else { return }
        group.confirmedSlot = overlap.slot
        upsert(group)

        await saveIfNeeded(group, successMessage: "\(overlap.slot.displayText)에 약속을 확정했어요.")
    }

    func clearConfirmedSlot() async {
        guard var group = selectedGroup else { return }
        group.confirmedSlot = nil
        upsert(group)

        await saveIfNeeded(group, successMessage: "확정 시간을 취소했어요.")
    }

    func mySlots(in group: FriendGroup) -> Set<TimeSlot> {
        group.slots(for: currentMember.id)
    }

    private func makeGroup(named name: String, inviteCode: String, members: [Member]) -> FriendGroup {
        FriendGroup(
            id: UUID().uuidString,
            name: name,
            inviteCode: inviteCode,
            members: members,
            availability: Dictionary(uniqueKeysWithValues: members.map { ($0.id, Set<TimeSlot>()) }),
            confirmedSlot: nil
        )
    }

    private func ensureSignedIn() async throws -> String {
        if let currentUserID {
            return currentUserID
        }

        let uid = try await repository().signInAnonymouslyIfNeeded()
        currentUserID = uid
        currentMember = Member(id: uid, name: "나", color: .teal)
        return uid
    }

    private func repository() throws -> FirebaseGroupRepository {
        guard isFirebaseConfigured else {
            throw FirebaseRepositoryError.notConfigured
        }

        if let firebaseRepository {
            return firebaseRepository
        }

        let repository = FirebaseGroupRepository()
        firebaseRepository = repository
        return repository
    }

    private func saveIfNeeded(_ group: FriendGroup, successMessage: String) async {
        guard isFirebaseConfigured else {
            statusMessage = successMessage
            return
        }

        await runBusy {
            try await repository().save(group)
            statusMessage = successMessage
        }
    }

    private func upsert(_ group: FriendGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.insert(group, at: 0)
        }
    }

    private func runBusy(_ operation: () async throws -> Void) async {
        isBusy = true
        defer { isBusy = false }

        do {
            try await operation()
        } catch {
            statusMessage = "Firebase 오류: \(error.localizedDescription)"
        }
    }

    private static func makeInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let token = String((0..<4).compactMap { _ in letters.randomElement() })
        return "MGT-\(token)"
    }
}
