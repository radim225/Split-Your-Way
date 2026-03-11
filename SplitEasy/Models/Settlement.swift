import Foundation
import SwiftData

@Model
final class Settlement {
    var id: UUID
    var fromMemberID: UUID
    var toMemberID: UUID
    var amountInMinorUnits: Int64
    var currencyCode: String
    var date: Date
    var isSettled: Bool
    var group: ExpenseGroup?

    init(
        fromMemberID: UUID,
        toMemberID: UUID,
        amountInMinorUnits: Int64,
        currencyCode: String = "USD",
        date: Date = Date()
    ) {
        self.id = UUID()
        self.fromMemberID = fromMemberID
        self.toMemberID = toMemberID
        self.amountInMinorUnits = amountInMinorUnits
        self.currencyCode = currencyCode
        self.date = date
        self.isSettled = false
    }

    var amount: Decimal {
        get { Decimal(amountInMinorUnits) / 100 }
        set { amountInMinorUnits = NSDecimalNumber(decimal: newValue * 100).int64Value }
    }
}
