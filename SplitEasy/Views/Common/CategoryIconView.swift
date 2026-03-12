import SwiftUI

struct CategoryIconView: View {
    let category: ExpenseCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.iconName)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: category.colorHex))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
    }
}
