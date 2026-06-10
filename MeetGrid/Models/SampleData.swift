import Foundation

enum SampleData {
    static let currentMember = Member(id: "me", name: "나", color: .teal)

    static var starterGroup: FriendGroup {
        let mina = Member(id: "mina", name: "민아", color: .coral)
        let jun = Member(id: "jun", name: "준호", color: .indigo)
        let seo = Member(id: "seo", name: "서연", color: .amber)

        var availability: [String: Set<TimeSlot>] = [:]
        availability[currentMember.id] = [
            TimeSlot(weekday: .friday, startHour: 18),
            TimeSlot(weekday: .friday, startHour: 19),
            TimeSlot(weekday: .saturday, startHour: 14),
            TimeSlot(weekday: .saturday, startHour: 15)
        ]
        availability[mina.id] = [
            TimeSlot(weekday: .friday, startHour: 18),
            TimeSlot(weekday: .friday, startHour: 19),
            TimeSlot(weekday: .saturday, startHour: 15),
            TimeSlot(weekday: .sunday, startHour: 13)
        ]
        availability[jun.id] = [
            TimeSlot(weekday: .friday, startHour: 19),
            TimeSlot(weekday: .saturday, startHour: 14),
            TimeSlot(weekday: .saturday, startHour: 15),
            TimeSlot(weekday: .sunday, startHour: 13)
        ]
        availability[seo.id] = [
            TimeSlot(weekday: .friday, startHour: 18),
            TimeSlot(weekday: .saturday, startHour: 15),
            TimeSlot(weekday: .saturday, startHour: 16)
        ]

        return FriendGroup(
            id: "starter",
            name: "이번 주 저녁 약속",
            inviteCode: "MGT-4281",
            members: [currentMember, mina, jun, seo],
            availability: availability,
            confirmedSlot: nil
        )
    }
}
