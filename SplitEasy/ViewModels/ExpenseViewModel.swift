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

    func memberBalance(memberID: UUID, in group: ExpenseGroup) -> Decimal {
        var balance: Int64 = 0

        for expense in group.expenses {
            // Amount this member paid
            if expense.paidByMemberID == memberID {
                balance += expense.amountInMinorUnits
            }

            // Amount this member owes
            if let index = expense.splitMemberIDs.firstIndex(of: memberID),
               index < expense.splitAmountsInMinorUnits.count
            {
                balance -= expense.splitAmountsInMinorUnits[index]
            }
        }

        // Account for settlements
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
