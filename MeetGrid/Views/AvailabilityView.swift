import SwiftUI

struct AvailabilityView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDateKey = ScheduleCatalog.todayKey

    var body: some View {
        NavigationStack {
            Group {
                if let group = appState.selectedGroup {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            let mySlots = appState.mySlots(in: group)
                            let selectedCounts = Dictionary(grouping: mySlots, by: \.dateKey)
                                .mapValues(\.count)

                            CalendarDayGrid(
                                selectedDateKey: selectedDateKey,
                                selectedCounts: selectedCounts,
                                bestOverlapByDate: [:],
                                totalMembers: group.totalMembers
                            ) { day in
                                selectedDateKey = day.dateKey
                            }

                            selectedDaySection(mySlots: mySlots)
                        }
                        .padding(20)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.meetGridBackground)
                } else {
                    EmptyStateView(
                        title: "NO CREW",
                        message: "그룹부터.",
                        systemImage: "calendar.badge.plus"
                    )
                }
            }
            .navigationTitle("내 시간")
            .toolbarBackground(Color.meetGridBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func selectedDaySection(mySlots: Set<TimeSlot>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ScheduleCatalog.day(for: selectedDateKey)?.titleText ?? selectedDateKey)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)

            CalendarTimeSlotGrid(
                dateKey: selectedDateKey,
                selectedSlots: mySlots,
                mode: .editing,
                overlapBySlot: [:]
            ) { slot in
                Task {
                    await appState.toggleMyAvailability(slot)
                }
            }
        }
    }
}

enum CalendarSlotMode {
    case editing
    case overlap
}

struct CalendarDayGrid: View {
    let selectedDateKey: String
    var selectedCounts: [String: Int]
    var bestOverlapByDate: [String: SlotOverlap]
    var totalMembers: Int
    let onSelect: (CalendarDay) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 7)
    private let weekdayHeaders = ["일", "월", "화", "수", "목", "금", "토"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(weekdayHeaders, id: \.self) { title in
                    Text(title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.meetGridMuted)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<ScheduleCatalog.leadingBlankCount, id: \.self) { _ in
                    Color.clear.frame(height: 58)
                }

                ForEach(ScheduleCatalog.days) { day in
                    Button {
                        onSelect(day)
                    } label: {
                        dayCell(day)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(day.titleText) 선택")
                }
            }
        }
        .padding(14)
        .background(Color.meetGridSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = day.dateKey == selectedDateKey
        let selectedCount = selectedCounts[day.dateKey, default: 0]
        let overlap = bestOverlapByDate[day.dateKey]
        let count = overlap?.count ?? 0
        let isResultMode = !bestOverlapByDate.isEmpty
        let backgroundColor: Color = {
            if isResultMode {
                return Color.resultDayColor(count: count, total: totalMembers)
            }
            return Color.availabilityDayColor(hasSlots: selectedCount > 0)
        }()

        return VStack(spacing: 2) {
            Text(day.dayNumberText)
                .font(.headline.monospacedDigit())
            Text(day.isToday ? "오늘" : day.weekdayText)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: backgroundColor.opacity(isSelected ? 0.75 : 0.30), radius: isSelected ? 14 : 4)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        }
    }
}

struct CalendarTimeSlotGrid: View {
    let dateKey: String
    let selectedSlots: Set<TimeSlot>
    let mode: CalendarSlotMode
    let overlapBySlot: [TimeSlot: SlotOverlap]
    let onTap: (TimeSlot) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(ScheduleCatalog.slots(on: dateKey)) { slot in
                let overlap = overlapBySlot[slot]
                Button {
                    onTap(slot)
                } label: {
                    slotCell(slot: slot, overlap: overlap)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityText(slot: slot, overlap: overlap))
            }
        }
        .padding(14)
        .background(Color.meetGridSurface, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func slotCell(slot: TimeSlot, overlap: SlotOverlap?) -> some View {
        switch mode {
        case .editing:
            let isSelected = selectedSlots.contains(slot)
            HStack(spacing: 8) {
                Text(slot.rangeText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .foregroundStyle(.white)
            .background(isSelected ? Color.meetGridNeonBlue : Color.meetGridNeonRed, in: RoundedRectangle(cornerRadius: 8))
            .shadow(color: (isSelected ? Color.meetGridNeonBlue : Color.meetGridNeonRed).opacity(0.35), radius: 8)

        case .overlap:
            let ratio = overlap?.ratio ?? 0
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.rangeText)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                    Text(overlap?.summary ?? "가능한 사람 없음")
                        .font(.caption2)
                }
                Spacer()
                if let overlap, overlap.count > 0 {
                    Text("\(overlap.count)")
                        .font(.headline.monospacedDigit())
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .foregroundStyle(ratio >= 0.65 ? Color.white : Color.primary)
            .background(Color.overlapColor(ratio: ratio).opacity(ratio == 0 ? 1 : 0.86), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func accessibilityText(slot: TimeSlot, overlap: SlotOverlap?) -> String {
        switch mode {
        case .editing:
            "\(slot.displayText) 가능 시간 토글"
        case .overlap:
            "\(slot.displayText), \(overlap?.summary ?? "가능한 사람 없음")"
        }
    }
}
