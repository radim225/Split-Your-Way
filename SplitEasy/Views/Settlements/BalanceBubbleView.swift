import SwiftUI

struct BalanceBubbleView: View {
    let member: Member
    let balance: Decimal
    let currencyCode: String

    var isPositive: Bool { balance > 0 }
    var isZero: Bool { balance == 0 }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            MemberAvatarView(member: member, size: 52)
                .overlay {
                    Circle()
                        .strokeBorder(borderColor, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }

            Text(member.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(CurrencyFormatter.format(balance, currencyCode: currencyCode))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(textColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(textColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(balanceLabel)")
    }

    private var borderColor: Color {
        if isZero { return .gray }
        return isPositive ? .green : .red
    }

    private var textColor: Color {
        if isZero { return .secondary }
        return isPositive ? .green : .red
    }

    private var balanceLabel: String {
        if isZero { return "settled" }
        return isPositive ? "is owed \(CurrencyFormatter.format(balance, currencyCode: currencyCode))" :
            "owes \(CurrencyFormatter.format(-balance, currencyCode: currencyCode))"
    }
}
