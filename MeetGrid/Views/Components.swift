import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusPill: View {
    let text: String
    var systemImage: String
    var tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct MemberAvatar: View {
    let member: Member

    var body: some View {
        HStack(spacing: 8) {
            Text(member.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(member.color.color.gradient, in: Circle())
            Text(member.name)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

extension Color {
    static func overlapColor(ratio: Double) -> Color {
        switch ratio {
        case 0.9...1:
            return .teal
        case 0.65..<0.9:
            return .green
        case 0.4..<0.65:
            return .orange
        case 0.1..<0.4:
            return .pink
        default:
            return Color(.systemGray5)
        }
    }
}
