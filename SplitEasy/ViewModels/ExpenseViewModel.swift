import Foundation
import SwiftData

@Observable
final class ExpenseViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func expenses(for group: ExpenseGroup) -> [Expense] {
        group.expenses.sorted { $0.date > $1.date }
    }

    func addExpense(
        to group: ExpenseGroup,
        title: String,
        amountInMinorUnits: Int64,
        currencyCode: String,
        date: Date,
        category: ExpenseCategory,
        paidByMemberID: UUID,
        splitAmong members: [Member],
        note: String?
    ) {
        let expense = Expense(
            title: title,
            amountInMinorUnits: amountInMinorUnits,
            currencyCode: currencyCode,
            date: date,
            category: category,
            splitType: .equal,
            paidByMemberID: paidByMemberID,
            note: note
        )
        expense.group = group

        // Equal split with round-robin remainder distribution
        let memberCount = Int64(members.count)
        guard memberCount > 0 else { return }

        let perPerson = amountInMinorUnits / memberCount
        let remainder = amountInMinorUnits - (perPerson * memberCount)

        expense.splitMemberIDs = members.map(\.id)
        expense.splitAmountsInMinorUnits = members.enumerated().map { idx, _ in
            perPerson + (Int64(idx) < remainder ? 1 : 0)
        }

        modelContext.insert(expense)
        try? modelContext.save()
    }

    func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
        try? modelContext.save()
    }

    /// Convert an expense amount to the group's default currency (minor units)
    private func convertToGroupCurrency(_ amount: Int64, expense: Expense, group: ExpenseGroup) -> Int64 {
        if expense.currencyCode == group.defaultCurrencyCode {
            return amount
        }
        guard expense.exchangeRateToBase > 0 else { return amount }
        return Int64((Double(amount) / expense.exchangeRateToBase).rounded())
    }

    func memberBalance(memberID: UUID, in group: ExpenseGroup) -> Decimal {
        var balance: Int64 = 0

        for expense in group.expenses {
            // Amount this member paid (converted to group currency)
            if expense.paidByMemberID == memberID {
                balance += convertToGroupCurrency(expense.amountInMinorUnits, expense: expense, group: group)
            }

            // Amount this member owes (converted to group currency)
            if let index = expense.splitMemberIDs.firstIndex(of: memberID),
               index < expense.splitAmountsInMinorUnits.count
            {
                balance -= convertToGroupCurrency(expense.splitAmountsInMinorUnits[index], expense: expense, group: group)
            }
        }

        // Account for settlements (already in group currency)
        for settlement in group.settlements where settlement.isSettled {
            if settlement.fromMemberID == memberID {
                balance -= settlement.amountInMinorUnits
            }
            if settlement.toMemberID == memberID {
                balance += settlement.amountInMinorUnits
            }
        }

        return Decimal(balance) / 100
    }
}
