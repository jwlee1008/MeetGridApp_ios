import SwiftUI

struct ResultsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedDateKey = ScheduleCatalog.todayKey

    var body: some View {
        NavigationStack {
            Group {
                if let group = appState.selectedGroup {
                    let overlaps = ScheduleCalculator.overlaps(for: group)
                    let overlapMap = Dictionary(uniqueKeysWithValues: overlaps.map { ($0.slot, $0) })
                    let bestOverlapByDate = ScheduleCalculator.bestOverlapByDate(for: group)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            resultLegend

                            CalendarDayGrid(
                                selectedDateKey: selectedDateKey,
                                selectedCounts: [:],
                                bestOverlapByDate: bestOverlapByDate,
                                totalMembers: group.totalMembers
                            ) { day in
                                selectedDateKey = day.dateKey
                            }

                            selectedDayResult(group: group, overlapMap: overlapMap)
                        }
                        .padding(20)
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.meetGridBackground)
                } else {
                    EmptyStateView(
                        title: "NO DATA",
                        message: "시간 먼저 찍기.",
                        systemImage: "chart.bar.xaxis"
                    )
                }
            }
            .navigationTitle("결과")
            .toolbarBackground(Color.meetGridBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var resultLegend: some View {
        HStack(spacing: 8) {
            StatusPill(text: "가능", systemImage: "circle.fill", tint: .meetGridNeonBlue)
            StatusPill(text: "일부", systemImage: "circle.lefthalf.filled", tint: .meetGridNeonPink)
            StatusPill(text: "불가", systemImage: "circle", tint: .meetGridNeonRed)
        }
    }

    private func selectedDayResult(group: FriendGroup, overlapMap: [TimeSlot: SlotOverlap]) -> some View {
        let daySlots = ScheduleCatalog.slots(on: selectedDateKey)
            .compactMap { overlapMap[$0] }
            .filter { $0.count > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(ScheduleCatalog.day(for: selectedDateKey)?.titleText ?? selectedDateKey)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(group.totalMembers)명")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.meetGridMuted)
            }

            if daySlots.isEmpty {
                Text("가능한 사람 없음")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.meetGridNeonRed.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(daySlots) { overlap in
                    HStack(spacing: 12) {
                        Text(overlap.slot.rangeText)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(width: 98, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(overlap.availableMembers.map(\.name).joined(separator: ", "))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            Text(overlap.summary)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.meetGridMuted)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        Color.resultDayColor(count: overlap.count, total: group.totalMembers).opacity(0.86),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
            }
        }
    }
}
