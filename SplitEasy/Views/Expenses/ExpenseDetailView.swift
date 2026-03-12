import SwiftData
import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    let group: ExpenseGroup

    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false

    var paidByMember: Member? {
        group.members.first { $0.id == expense.paidByMemberID }
    }

    var splitMembers: [(member: Member, amount: Decimal)] {
        expense.splitMemberIDs.enumerated().compactMap { index, memberID in
            guard let member = group.members.first(where: { $0.id == memberID }),
                  index < expense.splitAmountsInMinorUnits.count else { return nil }
            let amount = Decimal(expense.splitAmountsInMinorUnits[index]) / 100
            return (member, amount)
        }
    }

    var isDifferentCurrency: Bool {
        expense.currencyCode != group.defaultCurrencyCode
    }

    var displayAmountInMinorUnits: Int64 {
        if !isDifferentCurrency { return expense.amountInMinorUnits }
        guard expense.exchangeRateToBase > 0 else { return expense.amountInMinorUnits }
        return Int64((Double(expense.amountInMinorUnits) / expense.exchangeRateToBase).rounded())
    }

    var body: some View {
        List {
            // Header section
            Section {
                VStack(spacing: 12) {
                    CategoryIconView(category: expense.expenseCategory, size: 64)

                    Text(expense.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(CurrencyFormatter.format(minorUnits: displayAmountInMinorUnits, currencyCode: group.defaultCurrencyCode))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if isDifferentCurrency {
                        Text("(\(CurrencyFormatter.format(minorUnits: expense.amountInMinorUnits, currencyCode: expense.currencyCode)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text(expense.date.mediumFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            // Paid by
            Section("Paid By") {
                if let payer = paidByMember {
                    HStack {
                        MemberAvatarView(member: payer, size: 36)
                        Text(payer.name)
                            .font(.body)
                        Spacer()
                        Text(CurrencyFormatter.format(minorUnits: expense.amountInMinorUnits, currencyCode: expense.currencyCode))
                            .fontWeight(.medium)
                    }
                }
            }

            // Split breakdown
            Section("Split Breakdown (\(expense.splitType.displayName))") {
                ForEach(splitMembers, id: \.member.id) { item in
                    HStack {
                        MemberAvatarView(member: item.member, size: 28)
                        Text(item.member.name)
                        Spacer()
                        Text(CurrencyFormatter.format(item.amount, currencyCode: expense.currencyCode))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Details
            Section("Details") {
                LabeledContent("Category") {
                    Label(expense.expenseCategory.displayName, systemImage: expense.expenseCategory.iconName)
                }

                LabeledContent("Currency") {
                    if let info = CurrencyInfo.find(byCode: expense.currencyCode) {
                        Text("\(info.flag) \(info.code)")
                    } else {
                        Text(expense.currencyCode)
                    }
                }

                if let note = expense.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(note)
                    }
                }
            }

            // Actions
            Section {
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Expense", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Expense", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Expense Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditSheet) {
            EditExpenseView(expense: expense, group: group)
        }
        .confirmationDialog("Delete this expense?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(expense)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
