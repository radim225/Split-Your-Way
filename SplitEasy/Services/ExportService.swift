import Foundation

enum ExportService {
    static func generateCSV(for group: ExpenseGroup) -> String {
        var csv = "Date,Title,Amount,Currency,Category,Paid By,Split Type,Note\n"

        let sortedExpenses = group.expenses.sorted { $0.date < $1.date }

        for expense in sortedExpenses {
            let date = expense.date.shortFormatted
            let title = expense.title.replacingOccurrences(of: ",", with: ";")
            let amount = CurrencyFormatter.format(minorUnits: expense.amountInMinorUnits, currencyCode: expense.currencyCode)
            let currency = expense.currencyCode
            let category = expense.expenseCategory.displayName
            let paidBy = group.members.first { $0.id == expense.paidByMemberID }?.name ?? "Unknown"
            let splitType = expense.splitType.displayName
            let note = (expense.note ?? "").replacingOccurrences(of: ",", with: ";")

            csv += "\(date),\(title),\(amount),\(currency),\(category),\(paidBy),\(splitType),\(note)\n"
        }

        return csv
    }

    static func writeToTempFile(csv: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
