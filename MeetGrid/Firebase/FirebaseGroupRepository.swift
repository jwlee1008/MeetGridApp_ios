import Foundation
import FirebaseAuth
import FirebaseFirestore

struct FirebaseGroupRepository {
    private let database = Firestore.firestore()

    func signInAnonymouslyIfNeeded() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            signInAnonymouslyIfNeeded { result in
                continuation.resume(with: result)
            }
        }
    }

    func save(_ group: FriendGroup) async throws {
        try await withCheckedThrowingContinuation { continuation in
            save(group) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetch(inviteCode: String) async throws -> FriendGroup? {
        try await withCheckedThrowingContinuation { continuation in
            fetch(inviteCode: inviteCode) { result in
                continuation.resume(with: result)
            }
        }
    }

    func fetchGroups(forMemberID memberID: String) async throws -> [FriendGroup] {
        try await withCheckedThrowingContinuation { continuation in
            database.collection("groups")
                .whereField("memberIDs", arrayContains: memberID)
                .getDocuments { snapshot, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let groups = snapshot?.documents.compactMap {
                        FriendGroup(documentID: $0.documentID, data: $0.data())
                    } ?? []
                    continuation.resume(returning: groups.sorted { $0.name < $1.name })
                }
        }
    }

    private func signInAnonymouslyIfNeeded(completion: @escaping (Result<String, Error>) -> Void) {
        if let user = Auth.auth().currentUser {
            completion(.success(user.uid))
            return
        }

        Auth.auth().signInAnonymously { result, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let uid = result?.user.uid else {
                completion(.failure(FirebaseRepositoryError.missingUser))
                return
            }

            completion(.success(uid))
        }
    }

    private func save(_ group: FriendGroup, completion: @escaping (Result<Void, Error>) -> Void) {
        database.collection("groups").document(group.id).setData(group.firestoreData, merge: true) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func fetch(inviteCode: String, completion: @escaping (Result<FriendGroup?, Error>) -> Void) {
        database.collection("groups")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let document = snapshot?.documents.first else {
                    completion(.success(nil))
                    return
                }

                completion(.success(FriendGroup(documentID: document.documentID, data: document.data())))
            }
    }
}

enum FirebaseRepositoryError: Error {
    case missingUser
    case notConfigured
}

private extension FriendGroup {
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "inviteCode": inviteCode,
            "memberIDs": members.map(\.id),
            "members": members.map { member in
                [
                    "id": member.id,
                    "name": member.name,
                    "color": member.color.rawValue
                ]
            },
            "availability": availability.mapValues { slots in
                slots.map { slot in
                    [
                        "weekday": slot.weekday.rawValue,
                        "startHour": slot.startHour
                    ]
                }
            },
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let confirmedSlot {
            data["confirmedSlot"] = confirmedSlot.firestoreData
        } else {
            data["confirmedSlot"] = FieldValue.delete()
        }

        return data
    }

    init?(documentID: String, data: [String: Any]) {
        guard let name = data["name"] as? String,
              let inviteCode = data["inviteCode"] as? String
        else { return nil }

        let members = (data["members"] as? [[String: Any]])?.compactMap(Member.init(data:)) ?? []
        let rawAvailability = data["availability"] as? [String: [[String: Any]]] ?? [:]
        let availability = rawAvailability.mapValues { values in
            Set(values.compactMap(TimeSlot.init(data:)))
        }

        self.init(
            id: documentID,
            name: name,
            inviteCode: inviteCode,
            members: members,
            availability: availability,
            confirmedSlot: (data["confirmedSlot"] as? [String: Any]).flatMap(TimeSlot.init(data:))
        )
    }
}

private extension Member {
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let name = data["name"] as? String
        else { return nil }

        let colorName = data["color"] as? String
        self.init(
            id: id,
            name: name,
            color: colorName.flatMap(MemberColor.init(rawValue:)) ?? .teal
        )
    }
}

private extension TimeSlot {
    var firestoreData: [String: Any] {
        [
            "weekday": weekday.rawValue,
            "startHour": startHour
        ]
    }

    init?(data: [String: Any]) {
        guard let weekdayValue = data["weekday"] as? Int,
              let weekday = Weekday(rawValue: weekdayValue),
              let startHour = data["startHour"] as? Int
        else { return nil }

        self.init(weekday: weekday, startHour: startHour)
    }
}
