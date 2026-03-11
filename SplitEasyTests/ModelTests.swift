import Testing
import Foundation
@testable import SplitEasy

@Suite("Model Tests")
struct ModelTests {

    @Test("Group creation with defaults")
    func groupCreation() {
        let group = ExpenseGroup(name: "Test Group", emoji: "🏖️", defaultCurrencyCode: "USD")
        #expect(group.name == "Test Group")
        #expect(group.emoji == "🏖️")
        #expect(group.defaultCurrencyCode == "USD")
        #expect(group.isArchived == false)
        #expect(group.members.isEmpty)
        #expect(group.expenses.isEmpty)
    }

    @Test("Member creation and initials")
    func memberCreation() {
        let member = Member(name: "Alice Smith")
        #expect(member.name == "Alice Smith")
        #expect(member.initials == "AS")
        #expect(member.isActive == true)
        #expect(member.defaultWeight == 1.0)

        let singleName = Member(name: "Bob")
        #expect(singleName.initials == "BO")
    }

    @Test("Expense Decimal to minor units round-trip")
    func decimalRoundTrip() {
        let expense = Expense(title: "Test", amountInMinorUnits: 1999)
        #expect(expense.amountInMinorUnits == 1999)

        let expectedAmount: Decimal = Decimal(string: "19.99")!
        #expect(expense.amount == expectedAmount)

        expense.amount = Decimal(string: "42.50")!
        #expect(expense.amountInMinorUnits == 4250)
    }

    @Test("Equal split with remainder distribution")
    func equalSplitRemainder() {
        // $10.00 split among 3 people: 334 + 333 + 333 = 1000 cents
        let total: Int64 = 1000
        let memberCount: Int64 = 3
        let perPerson = total / memberCount
        let remainder = total - (perPerson * memberCount)

        let splits: [Int64] = (0 ..< memberCount).map { idx in
            perPerson + (idx < remainder ? 1 : 0)
        }

        #expect(splits == [334, 333, 333])
        #expect(splits.reduce(0, +) == total)
    }

    @Test("Category has emoji and display name")
    func categoryProperties() {
        let food = ExpenseCategory.food
        #expect(food.emoji == "🍽")
        #expect(food.displayName == "Food")
        #expect(!food.iconName.isEmpty)
    }

    @Test("Currency lookup by code")
    func currencyLookup() {
        let usd = CurrencyInfo.find(byCode: "USD")
        #expect(usd != nil)
        #expect(usd?.symbol == "$")
        #expect(usd?.flag == "🇺🇸")

        let czk = CurrencyInfo.find(byCode: "CZK")
        #expect(czk != nil)
        #expect(czk?.symbol == "Kč")

        let unknown = CurrencyInfo.find(byCode: "XYZ")
        #expect(unknown == nil)
    }

    @Test("SplitType properties")
    func splitTypeProperties() {
        let equal = SplitType.equal
        #expect(equal.displayName == "Equal")
        #expect(!equal.iconName.isEmpty)

        // Verify raw value round-trip
        let raw = equal.rawValue
        let decoded = SplitType(rawValue: raw)
        #expect(decoded == .equal)
    }

    @Test("Settlement amount tracking")
    func settlementAmounts() {
        let settlement = Settlement(
            fromMemberID: UUID(),
            toMemberID: UUID(),
            amountInMinorUnits: 5000,
            currencyCode: "EUR"
        )

        let expectedAmount: Decimal = Decimal(string: "50.00")!
        #expect(settlement.amount == expectedAmount)
        #expect(settlement.isSettled == false)

        settlement.amount = Decimal(string: "75.25")!
        #expect(settlement.amountInMinorUnits == 7525)
    }
}
