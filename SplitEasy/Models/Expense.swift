import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var amountInMinorUnits: Int64
    var currencyCode: String
    var exchangeRateToBase: Double
    var date: Date
    var category: String
    var splitTypeRaw: String
    var note: String?
    var receiptImageData: Data?
    var isIncome: Bool
    var createdAt: Date

    var paidByMemberID: UUID?

    // Stored as JSON-encoded arrays for SwiftData compatibility
    var splitMemberIDs: [UUID]
    var splitAmountsInMinorUnits: [Int64]

    var group: ExpenseGroup?

    init(
        title: String,
        amountInMinorUnits: Int64,
        currencyCode: String = "USD",
        exchangeRateToBase: Double = 1.0,
        date: Date = Date(),
        category: ExpenseCategory = .other,
        splitType: SplitType = .equal,
        paidByMemberID: UUID? = nil,
        note: String? = nil,
        isIncome: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.exchangeRateToBase = exchangeRateToBase
        self.date = date
        self.category = category.rawValue
        self.splitTypeRaw = splitType.rawValue
        self.paidByMemberID = paidByMemberID
        self.note = note
        self.isIncome = isIncome
        self.createdAt = Date()
        self.splitMemberIDs = []
        self.splitAmountsInMinorUnits = []
    }

    var amount: Decimal {
        get { Decimal(amountInMinorUnits) / 100 }
        set { amountInMinorUnits = NSDecimalNumber(decimal: newValue * 100).int64Value }
    }

    var expenseCategory: ExpenseCategory {
        get { ExpenseCategory(rawValue: category) ?? .other }
        set { category = newValue.rawValue }
    }

    var splitType: SplitType {
        get { SplitType(rawValue: splitTypeRaw) ?? .equal }
        set { splitTypeRaw = newValue.rawValue }
    }

    func splitAmount(forMemberID memberID: UUID) -> Decimal {
        guard let index = splitMemberIDs.firstIndex(of: memberID) else { return 0 }
        guard index < splitAmountsInMinorUnits.count else { return 0 }
        return Decimal(splitAmountsInMinorUnits[index]) / 100
    }
}
