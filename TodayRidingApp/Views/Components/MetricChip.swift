import SwiftUI

struct MetricChip: View {
    let icon: String
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(AppTheme.surface2, in: RoundedRectangle(cornerRadius: 16))
    }
}

