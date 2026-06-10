import SwiftUI

struct AvailabilityView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Group {
                if let group = appState.selectedGroup {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(
                                title: "가능한 시간 입력",
                                subtitle: "\(group.name)에 내가 가능한 시간을 표시해요."
                            )

                            legend

                            WeeklyAvailabilityGrid(
                                selectedSlots: appState.mySlots(in: group),
                                mode: .editing,
                                overlapBySlot: [:]
                            ) { slot in
                                Task {
                                    await appState.toggleMyAvailability(slot)
                                }
                            }

                            Text(appState.isFirebaseConfigured ? "선택한 시간은 Firebase에 저장됩니다." : "선택한 시간은 현재 로컬 데모 상태에 저장됩니다.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    EmptyStateView(
                        title: "선택된 그룹이 없어요",
                        message: "먼저 그룹을 만들거나 초대코드로 참가해 주세요.",
                        systemImage: "calendar.badge.plus"
                    )
                }
            }
            .navigationTitle("내 시간")
        }
    }

    private var legend: some View {
        HStack(spacing: 10) {
            StatusPill(text: "가능", systemImage: "checkmark", tint: .teal)
            StatusPill(text: "비어 있음", systemImage: "square", tint: .gray)
        }
    }
}

enum WeeklyGridMode {
    case editing
    case overlap
}

struct WeeklyAvailabilityGrid: View {
    let selectedSlots: Set<TimeSlot>
    let mode: WeeklyGridMode
    let overlapBySlot: [TimeSlot: SlotOverlap]
    let onTap: (TimeSlot) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(horizontalSpacing: 7, verticalSpacing: 7) {
                GridRow {
                    Color.clear
                        .frame(width: 50, height: 28)
                    ForEach(Weekday.allCases) { weekday in
                        Text(weekday.shortTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 42, height: 28)
                    }
                }

                ForEach(ScheduleCatalog.hours, id: \.self) { hour in
                    GridRow {
                        Text("\(hour)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 50, height: 34, alignment: .trailing)

                        ForEach(Weekday.allCases) { weekday in
                            let slot = TimeSlot(weekday: weekday, startHour: hour)
                            let overlap = overlapBySlot[slot]

                            Button {
                                onTap(slot)
                            } label: {
                                gridCell(slot: slot, overlap: overlap)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibilityText(slot: slot, overlap: overlap))
                        }
                    }
                }
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func gridCell(slot: TimeSlot, overlap: SlotOverlap?) -> some View {
        switch mode {
        case .editing:
            let isSelected = selectedSlots.contains(slot)
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.teal : Color(.secondarySystemGroupedBackground))
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 42, height: 34)

        case .overlap:
            let ratio = overlap?.ratio ?? 0
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.overlapColor(ratio: ratio).opacity(ratio == 0 ? 1 : 0.82))
                .overlay {
                    if let overlap, overlap.count > 0 {
                        Text("\(overlap.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ratio >= 0.65 ? .white : .primary)
                    }
                }
                .frame(width: 42, height: 34)
        }
    }

    private func accessibilityText(slot: TimeSlot, overlap: SlotOverlap?) -> String {
        switch mode {
        case .editing:
            return "\(slot.displayText) 가능 시간 토글"
        case .overlap:
            return "\(slot.displayText), \(overlap?.summary ?? "가능한 사람 없음")"
        }
    }
}
