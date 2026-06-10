import Foundation
import SwiftUI

enum Weekday: Int, CaseIterable, Codable, Identifiable {
    case monday = 1
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .monday: "월요일"
        case .tuesday: "화요일"
        case .wednesday: "수요일"
        case .thursday: "목요일"
        case .friday: "금요일"
        case .saturday: "토요일"
        case .sunday: "일요일"
        }
    }

    var shortTitle: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }
}

struct TimeSlot: Hashable, Codable, Identifiable {
    let weekday: Weekday
    let startHour: Int

    var id: String {
        "\(weekday.rawValue)-\(startHour)"
    }

    var rangeText: String {
        "\(startHour):00-\(startHour + 1):00"
    }

    var displayText: String {
        "\(weekday.shortTitle) \(rangeText)"
    }
}

struct Member: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var color: MemberColor

    var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(1))
    }
}

enum MemberColor: String, CaseIterable, Codable {
    case teal
    case coral
    case indigo
    case amber
    case mint

    var color: Color {
        switch self {
        case .teal: .teal
        case .coral: .pink
        case .indigo: .indigo
        case .amber: .orange
        case .mint: .mint
        }
    }
}

struct FriendGroup: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var inviteCode: String
    var members: [Member]
    var availability: [String: Set<TimeSlot>]
    var confirmedSlot: TimeSlot?

    func slots(for memberID: String) -> Set<TimeSlot> {
        availability[memberID, default: []]
    }

    var totalMembers: Int {
        members.count
    }
}

struct SlotOverlap: Identifiable, Hashable {
    let slot: TimeSlot
    let availableMembers: [Member]
    let totalMembers: Int

    var id: String {
        slot.id
    }

    var count: Int {
        availableMembers.count
    }

    var ratio: Double {
        guard totalMembers > 0 else { return 0 }
        return Double(count) / Double(totalMembers)
    }

    var summary: String {
        "\(count)/\(totalMembers)명 가능"
    }
}

enum ScheduleCatalog {
    static let startHour = 9
    static let endHour = 23

    static var hours: [Int] {
        Array(startHour..<endHour)
    }

    static var allSlots: [TimeSlot] {
        Weekday.allCases.flatMap { weekday in
            hours.map { TimeSlot(weekday: weekday, startHour: $0) }
        }
    }
}

enum ScheduleCalculator {
    static func overlaps(for group: FriendGroup) -> [SlotOverlap] {
        ScheduleCatalog.allSlots.map { slot in
            let availableMembers = group.members.filter { member in
                group.slots(for: member.id).contains(slot)
            }
            return SlotOverlap(
                slot: slot,
                availableMembers: availableMembers,
                totalMembers: group.totalMembers
            )
        }
    }

    static func recommendations(for group: FriendGroup, limit: Int = 5) -> [SlotOverlap] {
        overlaps(for: group)
            .filter { $0.count > 0 }
            .sorted {
                if $0.count == $1.count {
                    return $0.slot.startHour < $1.slot.startHour
                }
                return $0.count > $1.count
            }
            .prefix(limit)
            .map { $0 }
    }
}
