import SwiftUI

struct StatBlock: View {
    let value: String
    let unit: String
    let label: String
    var accent: Color = .white

    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
                Text(unit)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

