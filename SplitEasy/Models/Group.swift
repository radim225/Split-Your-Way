import Foundation
import SwiftData

@Model
final class ExpenseGroup {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var defaultCurrencyCode: String
    var createdAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \Member.group)
    var members: [Member]

    @Relationship(deleteRule: .cascade, inverse: \Expense.group)
    var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \Settlement.group)
    var settlements: [Settlement]

    init(
        name: String,
        emoji: String = "👥",
        colorHex: String = "#007AFF",
        defaultCurrencyCode: String = "USD"
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.defaultCurrencyCode = defaultCurrencyCode
        self.createdAt = Date()
        self.isArchived = false
        self.members = []
        self.expenses = []
        self.settlements = []
    }

    var activeMembers: [Member] {
        members.filter { $0.isActive }
    }

    var totalExpensesInMinorUnits: Int64 {
        expenses.reduce(0) { $0 + $1.amountInMinorUnits }
    }

    var totalExpenses: Decimal {
        Decimal(totalExpensesInMinorUnits) / 100
    }
}
