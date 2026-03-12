import Charts
import SwiftData
import SwiftUI

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    let group: ExpenseGroup

    var expenses: [Expense] { group.expenses.sorted { $0.date < $1.date } }

    var totalAmount: Decimal {
        Decimal(group.totalExpensesInMinorUnits) / 100
    }

    /// Convert an expense amount to the group's default currency
    private func convertedAmount(_ expense: Expense) -> Int64 {
        if expense.currencyCode == group.defaultCurrencyCode {
            return expense.amountInMinorUnits
        }
        guard expense.exchangeRateToBase > 0 else { return expense.amountInMinorUnits }
        return Int64((Double(expense.amountInMinorUnits) / expense.exchangeRateToBase).rounded())
    }

    var categoryBreakdown: [(category: ExpenseCategory, total: Int64)] {
        var map: [ExpenseCategory: Int64] = [:]
        for expense in expenses {
            map[expense.expenseCategory, default: 0] += convertedAmount(expense)
        }
        return map.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    /// Shows each member's share (split amounts), not who paid
    var memberSpending: [(member: Member, total: Int64)] {
        var map: [UUID: Int64] = [:]
        for expense in expenses {
            let conversionFactor: Double = expense.currencyCode == group.defaultCurrencyCode ? 1.0 :
                (expense.exchangeRateToBase > 0 ? 1.0 / expense.exchangeRateToBase : 1.0)
            for (index, memberID) in expense.splitMemberIDs.enumerated() {
                if index < expense.splitAmountsInMinorUnits.count {
                    let convertedSplit = Int64((Double(expense.splitAmountsInMinorUnits[index]) * conversionFactor).rounded())
                    map[memberID, default: 0] += convertedSplit
                }
            }
        }
        return group.activeMembers.compactMap { member in
            guard let total = map[member.id], total > 0 else { return nil }
            return (member, total)
        }.sorted { $0.total > $1.total }
    }

    var dailySpending: [(date: Date, total: Int64)] {
        var map: [String: Int64] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for expense in expenses {
            let key = formatter.string(from: expense.date)
            map[key, default: 0] += convertedAmount(expense)
        }

        return map.sorted { $0.key < $1.key }.compactMap { key, value in
            guard let date = formatter.date(from: key) else { return nil }
            return (date, value)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Summary cards
                HStack(spacing: AppSpacing.md) {
                    StatCard(title: "Total", value: CurrencyFormatter.format(totalAmount, currencyCode: group.defaultCurrencyCode), icon: "creditcard")
                    StatCard(title: "Expenses", value: "\(expenses.count)", icon: "list.bullet")
                    StatCard(title: "Members", value: "\(group.activeMembers.count)", icon: "person.2")
                }
                .padding(.horizontal)

                // Spending by category
                if !categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("By Category")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(categoryBreakdown, id: \.category) { item in
                            BarMark(
                                x: .value("Amount", Double(item.total) / 100.0),
                                y: .value("Category", "\(item.category.emoji) \(item.category.displayName)")
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                        }
                        .frame(height: CGFloat(categoryBreakdown.count) * 40)
                        .padding(.horizontal)
                    }
                }

                // Spending over time
                if dailySpending.count > 1 {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("Over Time")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(dailySpending, id: \.date) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Amount", Double(item.total) / 100.0)
                            )
                            .foregroundStyle(Color.accentColor)

                            AreaMark(
                                x: .value("Date", item.date),
                                y: .value("Amount", Double(item.total) / 100.0)
                            )
                            .foregroundStyle(Color.accentColor.opacity(0.1))
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }

                // Spending by member
                if !memberSpending.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        Text("By Member (Share)")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(memberSpending, id: \.member.id) { item in
                            HStack(spacing: AppSpacing.md) {
                                MemberAvatarView(member: item.member, size: 32)
                                Text(item.member.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(CurrencyFormatter.format(minorUnits: item.total, currencyCode: group.defaultCurrencyCode))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
    }
}
