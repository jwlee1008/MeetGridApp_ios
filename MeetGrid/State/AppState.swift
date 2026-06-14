import Foundation
import FirebaseCore
import GoogleSignIn
import Observation
import UIKit

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
    var currentUserEmail: String?

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
        if googleSignInConfigurationError != nil {
            return "Google 설정 필요"
        }
        if currentUserID == nil {
            return "Google 로그인 필요"
        }
        return "Firebase 연결됨"
    }

    var requiresGoogleLogin: Bool {
        isFirebaseConfigured && currentUserID == nil
    }

    var canStartGoogleLogin: Bool {
        isFirebaseConfigured && googleSignInConfigurationError == nil && !isBusy
    }

    var googleSignInConfigurationError: String? {
        guard isFirebaseConfigured else { return nil }

        guard hasGoogleServiceValue(for: "CLIENT_ID") else {
            return "GoogleService-Info.plist에 CLIENT_ID가 없어요. Firebase Authentication에서 Google 로그인을 켠 뒤 iOS 설정 파일을 다시 받아 주세요."
        }

        guard let reversedClientID = googleServiceValue(for: "REVERSED_CLIENT_ID") else {
            return "GoogleService-Info.plist에 REVERSED_CLIENT_ID가 없어요. Firebase에서 iOS 설정 파일을 다시 받아 주세요."
        }

        guard registeredURLSchemes.contains(reversedClientID) else {
            return "Google 로그인 URL Scheme이 앱에 등록되지 않았어요. Xcode에서 다시 빌드해 주세요."
        }

        return nil
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
            if let googleSignInConfigurationError {
                groups = []
                selectedGroupID = nil
                statusMessage = googleSignInConfigurationError
                return
            }

            if let user = try repository().currentUser() {
                applySignedInUser(user)
                try await loadGroupsForCurrentUser()
            } else {
                groups = []
                selectedGroupID = nil
                statusMessage = "Firebase 연결 완료. Google로 로그인해 주세요."
            }
        }
    }

    func signInWithGoogle(presenting viewController: UIViewController) async {
        guard isFirebaseConfigured else {
            statusMessage = "Firebase 설정 파일이 없어서 Google 로그인을 사용할 수 없어요."
            return
        }

        if let googleSignInConfigurationError {
            statusMessage = googleSignInConfigurationError
            return
        }

        guard let clientID = FirebaseApp.app()?.options.clientID, !clientID.isEmpty else {
            statusMessage = "Google 로그인 설정을 읽지 못했어요. GoogleService-Info.plist를 다시 확인해 주세요."
            return
        }

        await runBusy {
            let configuration = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = configuration

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw FirebaseRepositoryError.missingUser
            }

            let user = try await repository().signInWithGoogle(
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            applySignedInUser(user)
            try await loadGroupsForCurrentUser()
        }
    }

    func signOut() {
        guard isFirebaseConfigured else { return }

        do {
            try repository().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUserID = nil
            currentUserEmail = nil
            currentMember = SampleData.currentMember
            groups = []
            selectedGroupID = nil
            statusMessage = "로그아웃했어요. 다시 Google로 로그인할 수 있어요."
        } catch {
            statusMessage = "로그아웃 오류: \(error.localizedDescription)"
        }
    }

    func createGroup() async {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let groupName = name.isEmpty ? "새 약속 그룹" : name

        if isFirebaseConfigured {
            await runBusy {
                guard requireSignedIn() != nil else { return }
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
                guard requireSignedIn() != nil else { return }
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

    private func loadGroupsForCurrentUser() async throws {
        guard let currentUserID else { return }
        let fetchedGroups = try await repository().fetchGroups(forMemberID: currentUserID)
        groups = fetchedGroups
        selectedGroupID = fetchedGroups.first?.id
        statusMessage = fetchedGroups.isEmpty
            ? "Google 로그인 완료. 그룹을 만들거나 초대코드를 입력해 주세요."
            : "Firebase에서 내 그룹 \(fetchedGroups.count)개를 불러왔어요."
    }

    private func applySignedInUser(_ user: AuthenticatedUser) {
        let displayName = user.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let memberName = displayName?.isEmpty == false ? displayName! : "나"

        currentUserID = user.uid
        currentUserEmail = user.email
        currentMember = Member(
            id: user.uid,
            name: memberName,
            color: .teal
        )
    }

    private func requireSignedIn() -> String? {
        guard let currentUserID else {
            statusMessage = "먼저 Google로 로그인해 주세요."
            return nil
        }
        return currentUserID
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

    private func hasGoogleServiceValue(for key: String) -> Bool {
        googleServiceValue(for: key) != nil
    }

    private func googleServiceValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let values = NSDictionary(contentsOfFile: path),
              let value = values[key] as? String
        else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private var registeredURLSchemes: Set<String> {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return []
        }

        return Set(
            urlTypes.flatMap { urlType in
                urlType["CFBundleURLSchemes"] as? [String] ?? []
            }
        )
    }
}
