import Foundation
import SwiftUI

struct CalendarDay: Hashable, Identifiable {
    let dateKey: String
    let date: Date
    let isToday: Bool

    var id: String { dateKey }

    var dayNumberText: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var monthDayText: String {
        "\(Calendar.current.component(.month, from: date))/\(Calendar.current.component(.day, from: date))"
    }

    var weekdayText: String {
        ScheduleCatalog.weekdayShortText(for: date)
    }

    var titleText: String {
        "\(monthDayText) \(weekdayText)"
    }
}

struct TimeSlot: Hashable, Codable, Identifiable {
    let dateKey: String
    let startHour: Int

    var id: String {
        "\(dateKey)-\(startHour)"
    }

    var rangeText: String {
        "\(startHour):00-\(startHour + 1):00"
    }

    var dayText: String {
        guard let date = ScheduleCatalog.date(from: dateKey) else {
            return dateKey
        }
        return "\(Calendar.current.component(.month, from: date))/\(Calendar.current.component(.day, from: date)) \(ScheduleCatalog.weekdayShortText(for: date))"
    }

    var displayText: String {
        "\(dayText) \(rangeText)"
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
    static let dayCount = 30

    private static let calendar = Calendar.current

    private static let keyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static var hours: [Int] {
        Array(startHour..<endHour)
    }

    static var todayKey: String {
        dateKey(for: Date())
    }

    static var days: [CalendarDay] {
        let today = calendar.startOfDay(for: Date())
        return (0..<dayCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            return CalendarDay(dateKey: dateKey(for: date), date: date, isToday: offset == 0)
        }
    }

    static var leadingBlankCount: Int {
        guard let firstDay = days.first else { return 0 }
        let weekday = calendar.component(.weekday, from: firstDay.date)
        return weekday - 1
    }

    static var allSlots: [TimeSlot] {
        days.flatMap { day in
            hours.map { TimeSlot(dateKey: day.dateKey, startHour: $0) }
        }
    }

    static func slots(on dateKey: String) -> [TimeSlot] {
        hours.map { TimeSlot(dateKey: dateKey, startHour: $0) }
    }

    static func day(for dateKey: String) -> CalendarDay? {
        days.first { $0.dateKey == dateKey }
    }

    static func dateKey(for date: Date) -> String {
        keyFormatter.string(from: date)
    }

    static func date(from dateKey: String) -> Date? {
        keyFormatter.date(from: dateKey)
    }

    static func weekdayShortText(for date: Date) -> String {
        switch calendar.component(.weekday, from: date) {
        case 1: "일"
        case 2: "월"
        case 3: "화"
        case 4: "수"
        case 5: "목"
        case 6: "금"
        default: "토"
        }
    }

    static func dateKeyForLegacyWeekday(_ legacyWeekday: Int) -> String? {
        guard (1...7).contains(legacyWeekday) else { return nil }
        return days.first { day in
            let weekday = calendar.component(.weekday, from: day.date)
            let mondayBasedWeekday = weekday == 1 ? 7 : weekday - 1
            return mondayBasedWeekday == legacyWeekday
        }?.dateKey
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
                    if $0.slot.dateKey == $1.slot.dateKey {
                        return $0.slot.startHour < $1.slot.startHour
                    }
                    return $0.slot.dateKey < $1.slot.dateKey
                }
                return $0.count > $1.count
            }
            .prefix(limit)
            .map { $0 }
    }

    static func bestOverlapByDate(for group: FriendGroup) -> [String: SlotOverlap] {
        Dictionary(grouping: overlaps(for: group), by: { $0.slot.dateKey })
            .compactMapValues { overlaps in
                overlaps
                    .filter { $0.count > 0 }
                    .sorted {
                        if $0.count == $1.count {
                            return $0.slot.startHour < $1.slot.startHour
                        }
                        return $0.count > $1.count
                    }
                    .first
            }
    }
}
