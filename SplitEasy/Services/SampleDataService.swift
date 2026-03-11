import Foundation
import SwiftData

enum SampleDataService {
    @MainActor
    static func loadIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<ExpenseGroup>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        createSampleData(context: context)
    }

    @MainActor
    private static func createSampleData(context: ModelContext) {
        // Group 1: Weekend Trip
        let trip = ExpenseGroup(name: "Weekend Trip", emoji: "🏖️", colorHex: "#FF6B6B", defaultCurrencyCode: "USD")
        context.insert(trip)

        let alice = Member(name: "Alice", avatarColor: "#FF6B6B")
        let bob = Member(name: "Bob", avatarColor: "#4ECDC4")
        let charlie = Member(name: "Charlie", avatarColor: "#45B7D1")
        let dana = Member(name: "Dana", avatarColor: "#96CEB4")

        for member in [alice, bob, charlie, dana] {
            member.group = trip
            context.insert(member)
        }

        let tripMembers = [alice, bob, charlie, dana]
        let tripExpenses: [(String, Int64, ExpenseCategory, UUID?)] = [
            ("Hotel booking", 45000, .accommodation, alice.id),
            ("Gas station", 6500, .transport, bob.id),
            ("Dinner at seafood place", 12000, .food, charlie.id),
            ("Museum tickets", 8000, .entertainment, dana.id),
            ("Breakfast cafe", 3500, .food, alice.id),
            ("Uber to airport", 4200, .transport, bob.id),
            ("Souvenirs", 2500, .gifts, charlie.id),
            ("Snacks & drinks", 1800, .groceries, dana.id),
            ("Lunch downtown", 7600, .food, alice.id),
            ("Parking fees", 2000, .transport, bob.id),
        ]

        addExpenses(tripExpenses, to: trip, members: tripMembers, currencyCode: "USD", context: context)

        // Group 2: Apartment
        let apartment = ExpenseGroup(name: "Apartment", emoji: "🏠", colorHex: "#4ECDC4", defaultCurrencyCode: "EUR")
        context.insert(apartment)

        let emma = Member(name: "Emma", avatarColor: "#DDA0DD")
        let frank = Member(name: "Frank", avatarColor: "#F7DC6F")
        let grace = Member(name: "Grace", avatarColor: "#82E0AA")

        for member in [emma, frank, grace] {
            member.group = apartment
            context.insert(member)
        }

        let aptMembers = [emma, frank, grace]
        let aptExpenses: [(String, Int64, ExpenseCategory, UUID?)] = [
            ("Rent March", 150000, .rent, emma.id),
            ("Electricity bill", 8500, .utilities, frank.id),
            ("Internet", 4500, .utilities, grace.id),
            ("Cleaning supplies", 2200, .groceries, emma.id),
            ("Water bill", 3500, .utilities, frank.id),
            ("Groceries week 1", 6800, .groceries, grace.id),
            ("Groceries week 2", 7200, .groceries, emma.id),
            ("New lamp", 4500, .other, frank.id),
        ]

        addExpenses(aptExpenses, to: apartment, members: aptMembers, currencyCode: "EUR", context: context)

        // Group 3: Office Lunch
        let lunch = ExpenseGroup(name: "Office Lunch", emoji: "🍕", colorHex: "#45B7D1", defaultCurrencyCode: "CZK")
        context.insert(lunch)

        let hana = Member(name: "Hana", avatarColor: "#BB8FCE")
        let ivan = Member(name: "Ivan", avatarColor: "#85C1E9")
        let jan = Member(name: "Jan", avatarColor: "#F0B27A")
        let katka = Member(name: "Katka", avatarColor: "#FF6B6B")
        let lukas = Member(name: "Lukáš", avatarColor: "#98D8C8")

        for member in [hana, ivan, jan, katka, lukas] {
            member.group = lunch
            context.insert(member)
        }

        let lunchMembers = [hana, ivan, jan, katka, lukas]
        let lunchExpenses: [(String, Int64, ExpenseCategory, UUID?)] = [
            ("Pizza Monday", 85000, .food, hana.id),
            ("Sushi Tuesday", 120000, .food, ivan.id),
            ("Burgers Wednesday", 65000, .food, jan.id),
            ("Thai Thursday", 95000, .food, katka.id),
            ("Coffee run", 35000, .food, lukas.id),
            ("Pasta Friday", 72000, .food, hana.id),
            ("Bakery breakfast", 28000, .food, ivan.id),
            ("Indian lunch", 88000, .food, jan.id),
            ("Ice cream", 15000, .food, katka.id),
            ("Vietnamese Monday", 78000, .food, lukas.id),
            ("Kebab Tuesday", 45000, .food, hana.id),
            ("Canteen Wednesday", 55000, .food, ivan.id),
        ]

        addExpenses(lunchExpenses, to: lunch, members: lunchMembers, currencyCode: "CZK", context: context)

        try? context.save()
    }

    private static func addExpenses(
        _ expenses: [(String, Int64, ExpenseCategory, UUID?)],
        to group: ExpenseGroup,
        members: [Member],
        currencyCode: String,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        for (index, item) in expenses.enumerated() {
            let daysAgo = expenses.count - index
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()

            let expense = Expense(
                title: item.0,
                amountInMinorUnits: item.1,
                currencyCode: currencyCode,
                date: date,
                category: item.2,
                splitType: .equal,
                paidByMemberID: item.3
            )
            expense.group = group

            // Calculate equal split
            let memberCount = Int64(members.count)
            let perPerson = item.1 / memberCount
            let remainder = item.1 - (perPerson * memberCount)

            expense.splitMemberIDs = members.map(\.id)
            expense.splitAmountsInMinorUnits = members.enumerated().map { idx, _ in
                // Distribute remainder cents round-robin
                perPerson + (Int64(idx) < remainder ? 1 : 0)
            }

            context.insert(expense)
        }
    }
}
