import SwiftUI

struct PhraseCardRow: View {
    let phrase: Phrase
    var showsTimestamp = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(phrase.englishText)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            if !phrase.polishText.isEmpty {
                Text(phrase.polishText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if showsTimestamp {
                Text(Self.formattedDate(phrase.createdAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = [phrase.englishText]
        if !phrase.polishText.isEmpty { parts.append(phrase.polishText) }
        if showsTimestamp { parts.append(Self.formattedDate(phrase.createdAt)) }
        return parts.joined(separator: ". ")
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    static func formattedDate(_ date: Date) -> String {
        if abs(date.timeIntervalSinceNow) < 86_400 {
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return timeFormatter.string(from: date)
    }
}
