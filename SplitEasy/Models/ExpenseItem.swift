import Foundation
import SwiftData

@Model
final class ExpenseItem {
    var id: UUID
    var name: String
    var amountInMinorUnits: Int64
    var assignedMemberIDs: [UUID]

    init(name: String, amountInMinorUnits: Int64, assignedMemberIDs: [UUID] = []) {
        self.id = UUID()
        self.name = name
        self.amountInMinorUnits = amountInMinorUnits
        self.assignedMemberIDs = assignedMemberIDs
    }

    var amount: Decimal {
        get { Decimal(amountInMinorUnits) / 100 }
        set { amountInMinorUnits = NSDecimalNumber(decimal: newValue * 100).int64Value }
    }
}
