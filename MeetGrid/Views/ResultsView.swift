import SwiftUI

struct ResultsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Group {
                if let group = appState.selectedGroup {
                    let overlaps = ScheduleCalculator.overlaps(for: group)
                    let overlapMap = Dictionary(uniqueKeysWithValues: overlaps.map { ($0.slot, $0) })
                    let recommendations = ScheduleCalculator.recommendations(for: group)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(
                                title: "겹치는 시간",
                                subtitle: "숫자가 클수록 더 많은 친구가 가능한 시간이에요."
                            )

                            resultSummary(group: group, recommendations: recommendations)

                            WeeklyAvailabilityGrid(
                                selectedSlots: [],
                                mode: .overlap,
                                overlapBySlot: overlapMap
                            ) { _ in }

                            recommendationList(recommendations)
                        }
                        .padding(20)
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    EmptyStateView(
                        title: "결과가 없어요",
                        message: "그룹을 만든 뒤 친구들의 가능한 시간을 모아 보세요.",
                        systemImage: "chart.bar.xaxis"
                    )
                }
            }
            .navigationTitle("추천 시간")
        }
    }

    private func resultSummary(group: FriendGroup, recommendations: [SlotOverlap]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.wave.2")
                    .font(.title2)
                    .foregroundStyle(.teal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(group.totalMembers)명 기준")
                        .font(.headline)
                    Text(group.confirmedSlot?.displayText ?? "아직 확정된 시간이 없어요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                StatusPill(text: "전원", systemImage: "circle.fill", tint: .teal)
                StatusPill(text: "대부분", systemImage: "circle.lefthalf.filled", tint: .green)
                StatusPill(text: "일부", systemImage: "circle", tint: .orange)
            }

            if let best = recommendations.first {
                Button {
                    Task {
                        await appState.confirm(best)
                    }
                } label: {
                    Label("최고 추천 시간 확정", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func recommendationList(_ recommendations: [SlotOverlap]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "추천 순위")

            if recommendations.isEmpty {
                Text("아직 겹치는 시간이 없어요. 시간 탭에서 가능한 시간을 더 표시해 보세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(Array(recommendations.enumerated()), id: \.element.id) { index, overlap in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.overlapColor(ratio: overlap.ratio), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(overlap.slot.displayText)
                                .font(.headline)
                            Text(overlap.availableMembers.map(\.name).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(overlap.summary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        Task {
                            await appState.confirm(overlap)
                        }
                    }
                }
            }
        }
    }
}
