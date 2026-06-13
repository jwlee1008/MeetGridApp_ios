import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.meetGridMuted)
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
            .background(tint.opacity(0.18), in: Capsule())
            .overlay {
                Capsule().stroke(tint.opacity(0.42), lineWidth: 1)
            }
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
        .foregroundStyle(.white)
        .background(Color.meetGridSurface2, in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(.white)
        } description: {
            Text(message)
                .foregroundStyle(Color.meetGridMuted)
        }
    }
}

extension Color {
    static let meetGridBackground = Color(red: 0.043, green: 0.055, blue: 0.071)
    static let meetGridSurface = Color(red: 0.082, green: 0.102, blue: 0.125)
    static let meetGridSurface2 = Color(red: 0.125, green: 0.149, blue: 0.180)
    static let meetGridMuted = Color(red: 0.640, green: 0.690, blue: 0.745)
    static let meetGridNeonBlue = Color(red: 0.340, green: 0.640, blue: 0.730)
    static let meetGridNeonPink = Color(red: 0.830, green: 0.630, blue: 0.310)
    static let meetGridNeonRed = Color(red: 0.780, green: 0.330, blue: 0.330)
    static let meetGridNeonPurple = Color(red: 0.430, green: 0.520, blue: 0.640)
    static let meetGridAcid = Color(red: 0.350, green: 0.650, blue: 0.500)

    static func availabilityDayColor(hasSlots: Bool) -> Color {
        hasSlots ? .meetGridNeonBlue : .meetGridNeonRed
    }

    static func resultDayColor(count: Int, total: Int) -> Color {
        if count <= 0 {
            return .meetGridNeonRed
        }
        if total > 0, count >= total {
            return .meetGridNeonBlue
        }
        return .meetGridNeonPink
    }

    static func overlapColor(ratio: Double) -> Color {
        switch ratio {
        case 0.9...1:
            return .meetGridNeonBlue
        case 0.65..<0.9:
            return .meetGridAcid
        case 0.4..<0.65:
            return .meetGridNeonPink
        case 0.1..<0.4:
            return .meetGridNeonPurple
        default:
            return .meetGridNeonRed
        }
    }
}
