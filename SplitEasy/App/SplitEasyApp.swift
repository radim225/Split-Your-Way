import SwiftData
import SwiftUI

@main
struct SplitEasyApp: App {
    var body: some Scene {
        WindowGroup {
            GroupListView()
        }
        .modelContainer(for: [
            ExpenseGroup.self,
            Member.self,
            Expense.self,
            ExpenseItem.self,
            Settlement.self,
        ])
    }
}
