import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 17.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(AppTheme.brand, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.brand.opacity(0.45), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }
}

