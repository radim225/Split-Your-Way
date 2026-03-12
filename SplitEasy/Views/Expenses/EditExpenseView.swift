import SwiftData
import SwiftUI

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let expense: Expense
    let group: ExpenseGroup

    @State private var title: String
    @State private var amountText: String
    @State private var currencyCode: String
    @State private var date: Date
    @State private var category: ExpenseCategory
    @State private var selectedPayerID: UUID?
    @State private var note: String
    @State private var includedMemberIDs: Set<UUID>

    init(expense: Expense, group: ExpenseGroup) {
        self.expense = expense
        self.group = group
        _title = State(initialValue: expense.title)
        _amountText = State(initialValue: "\(NSDecimalNumber(decimal: expense.amount))")
        _currencyCode = State(initialValue: expense.currencyCode)
        _date = State(initialValue: expense.date)
        _category = State(initialValue: expense.expenseCategory)
        _selectedPayerID = State(initialValue: expense.paidByMemberID)
        _note = State(initialValue: expense.note ?? "")
        _includedMemberIDs = State(initialValue: Set(expense.splitMemberIDs))
    }

    var amountInMinorUnits: Int64? {
        guard let value = Decimal(string: amountText) else { return nil }
        let minor = NSDecimalNumber(decimal: value * 100).int64Value
        return minor > 0 ? minor : nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            amountInMinorUnits != nil &&
            selectedPayerID != nil &&
            includedMemberIDs.count >= 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who Paid?") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(group.activeMembers) { member in
                                VStack(spacing: 4) {
                                    MemberAvatarView(member: member, size: 48)
                                        .overlay {
                                            if selectedPayerID == member.id {
                                                Circle()
                                                    .strokeBorder(Color.accentColor, lineWidth: 3)
                                                    .frame(width: 52, height: 52)
                                            }
                                        }
                                    Text(member.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                .onTapGesture { selectedPayerID = member.id }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Expense Details") {
                    HStack {
                        Text(CurrencyInfo.find(byCode: currencyCode)?.symbol ?? currencyCode)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    TextField("What was it for?", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    ForEach(group.activeMembers) { member in
                        Toggle(isOn: Binding(
                            get: { includedMemberIDs.contains(member.id) },
                            set: { included in
                                if included { includedMemberIDs.insert(member.id) }
                                else { includedMemberIDs.remove(member.id) }
                            }
                        )) {
                            HStack {
                                MemberAvatarView(member: member, size: 28)
                                Text(member.name)
                            }
                        }
                    }
                } header: {
                    Text("Split Among")
                }

                Section("Notes") {
                    TextField("Add a note (optional)", text: $note, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveExpense() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveExpense() {
        guard let amount = amountInMinorUnits else { return }

        expense.title = title.trimmingCharacters(in: .whitespaces)
        expense.amountInMinorUnits = amount
        expense.currencyCode = currencyCode
        expense.date = date
        expense.expenseCategory = category
        expense.paidByMemberID = selectedPayerID
        expense.note = note.isEmpty ? nil : note

        let includedMembers = group.activeMembers.filter { includedMemberIDs.contains($0.id) }
        let (ids, amounts) = SplitCalculator.calculateEqual(total: amount, memberIDs: includedMembers.map(\.id))
        expense.splitMemberIDs = ids
        expense.splitAmountsInMinorUnits = amounts

        try? modelContext.save()
        dismiss()
    }
}
