import Foundation

enum SampleData {
    static let currentMember = Member(id: "me", name: "나", color: .teal)

    static var starterGroup: FriendGroup {
        let mina = Member(id: "mina", name: "민아", color: .coral)
        let jun = Member(id: "jun", name: "준호", color: .indigo)
        let seo = Member(id: "seo", name: "서연", color: .amber)

        var availability: [String: Set<TimeSlot>] = [:]
        availability[currentMember.id] = [
            Self.slot(dayOffset: 2, hour: 18),
            Self.slot(dayOffset: 2, hour: 19),
            Self.slot(dayOffset: 3, hour: 14),
            Self.slot(dayOffset: 3, hour: 15)
        ]
        availability[mina.id] = [
            Self.slot(dayOffset: 2, hour: 18),
            Self.slot(dayOffset: 2, hour: 19),
            Self.slot(dayOffset: 3, hour: 15),
            Self.slot(dayOffset: 4, hour: 13)
        ]
        availability[jun.id] = [
            Self.slot(dayOffset: 2, hour: 19),
            Self.slot(dayOffset: 3, hour: 14),
            Self.slot(dayOffset: 3, hour: 15),
            Self.slot(dayOffset: 4, hour: 13)
        ]
        availability[seo.id] = [
            Self.slot(dayOffset: 2, hour: 18),
            Self.slot(dayOffset: 3, hour: 15),
            Self.slot(dayOffset: 3, hour: 16)
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

    private static func slot(dayOffset: Int, hour: Int) -> TimeSlot {
        let day = ScheduleCatalog.days[min(dayOffset, ScheduleCatalog.days.count - 1)]
        return TimeSlot(dateKey: day.dateKey, startHour: hour)
    }
}
