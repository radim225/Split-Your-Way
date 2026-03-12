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
    @State private var showCurrencyPicker = false
    @State private var currencyService = CurrencyService()

    // Manual split state
    @State private var isManualSplit = false
    @State private var manualAmounts: [UUID: String] = [:] // text fields per member
    @State private var lockedMembers: Set<UUID> = [] // members whose amounts are manually set
    @FocusState private var focusedMemberID: UUID?

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

        // Initialize manual amounts from existing split
        var amounts: [UUID: String] = [:]
        for (index, memberID) in expense.splitMemberIDs.enumerated() {
            if index < expense.splitAmountsInMinorUnits.count {
                let decimal = Decimal(expense.splitAmountsInMinorUnits[index]) / 100
                amounts[memberID] = "\(NSDecimalNumber(decimal: decimal))"
            }
        }
        _manualAmounts = State(initialValue: amounts)
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

    /// Sum of all manually entered amounts in minor units
    var totalAssigned: Int64 {
        var total: Int64 = 0
        for memberID in includedMemberIDs {
            if let text = manualAmounts[memberID], let value = Decimal(string: text) {
                total += NSDecimalNumber(decimal: value * 100).int64Value
            }
        }
        return total
    }

    /// Remaining amount not yet assigned
    var remainingAmount: Int64 {
        (amountInMinorUnits ?? 0) - totalAssigned
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
                        Button {
                            showCurrencyPicker = true
                        } label: {
                            Text(CurrencyInfo.find(byCode: currencyCode)?.symbol ?? currencyCode)
                                .font(.headline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray5))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .onChange(of: amountText) {
                                if !isManualSplit {
                                    recalculateEqualSplit()
                                } else {
                                    redistributeUnlocked()
                                }
                            }
                    }

                    TextField("What was it for?", text: $title)

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName).tag(cat)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Split section with manual editing
                Section {
                    // Split mode toggle
                    Toggle(isOn: $isManualSplit) {
                        Label("Custom Split", systemImage: "slider.horizontal.3")
                    }
                    .onChange(of: isManualSplit) {
                        if !isManualSplit {
                            lockedMembers.removeAll()
                            recalculateEqualSplit()
                        }
                    }

                    ForEach(group.activeMembers) { member in
                        if isManualSplit {
                            // Manual split row
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { includedMemberIDs.contains(member.id) },
                                    set: { included in
                                        if included {
                                            includedMemberIDs.insert(member.id)
                                        } else {
                                            includedMemberIDs.remove(member.id)
                                            manualAmounts.removeValue(forKey: member.id)
                                            lockedMembers.remove(member.id)
                                        }
                                        redistributeUnlocked()
                                    }
                                )) {
                                    HStack {
                                        MemberAvatarView(member: member, size: 28)
                                        Text(member.name)
                                            .font(.subheadline)
                                    }
                                }

                                if includedMemberIDs.contains(member.id) {
                                    let currencySymbol = CurrencyInfo.find(byCode: currencyCode)?.symbol ?? currencyCode
                                    HStack(spacing: 4) {
                                        Text(currencySymbol)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        TextField("0", text: Binding(
                                            get: { manualAmounts[member.id] ?? "0" },
                                            set: { newValue in
                                                manualAmounts[member.id] = newValue
                                                lockedMembers.insert(member.id)
                                                redistributeUnlocked()
                                            }
                                        ))
                                        .keyboardType(.decimalPad)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                        .focused($focusedMemberID, equals: member.id)
                                    }
                                }
                            }
                        } else {
                            // Equal split toggle
                            Toggle(isOn: Binding(
                                get: { includedMemberIDs.contains(member.id) },
                                set: { included in
                                    if included {
                                        includedMemberIDs.insert(member.id)
                                    } else {
                                        includedMemberIDs.remove(member.id)
                                        manualAmounts.removeValue(forKey: member.id)
                                    }
                                    recalculateEqualSplit()
                                }
                            )) {
                                HStack {
                                    MemberAvatarView(member: member, size: 28)
                                    Text(member.name)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Split Among")
                        Spacer()
                        Text("\(includedMemberIDs.count) of \(group.activeMembers.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    if isManualSplit, let total = amountInMinorUnits {
                        let remaining = Decimal(total - totalAssigned) / 100
                        if remaining != 0 {
                            Text("Remaining: \(CurrencyFormatter.format(remaining, currencyCode: currencyCode))")
                                .foregroundStyle(remaining < 0 ? .red : .orange)
                        } else {
                            Text("Split adds up correctly ✓")
                                .foregroundStyle(.green)
                        }
                    } else if !isManualSplit, let amount = amountInMinorUnits, includedMemberIDs.count > 0 {
                        let perPerson = Decimal(amount / Int64(includedMemberIDs.count)) / 100
                        Text("Equal split: \(CurrencyFormatter.format(perPerson, currencyCode: currencyCode)) per person")
                    }
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
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerView(selectedCode: $currencyCode)
            }
            .task {
                await currencyService.fetchRates(base: group.defaultCurrencyCode)
            }
        }
    }

    /// Recalculate equal split amounts for all included members
    private func recalculateEqualSplit() {
        guard let total = amountInMinorUnits, !includedMemberIDs.isEmpty else { return }
        let memberIDs = group.activeMembers.filter { includedMemberIDs.contains($0.id) }.map(\.id)
        let (_, amounts) = SplitCalculator.calculateEqual(total: total, memberIDs: memberIDs)
        for (index, id) in memberIDs.enumerated() {
            if index < amounts.count {
                let decimal = Decimal(amounts[index]) / 100
                manualAmounts[id] = "\(NSDecimalNumber(decimal: decimal))"
            }
        }
    }

    /// When a member's amount is manually changed, redistribute the remaining total equally among unlocked members
    private func redistributeUnlocked() {
        guard let total = amountInMinorUnits else { return }

        let includedIDs = group.activeMembers.filter { includedMemberIDs.contains($0.id) }.map(\.id)
        guard !includedIDs.isEmpty else { return }

        // Sum locked amounts
        var lockedTotal: Int64 = 0
        for id in includedIDs where lockedMembers.contains(id) {
            if let text = manualAmounts[id], let value = Decimal(string: text) {
                lockedTotal += NSDecimalNumber(decimal: value * 100).int64Value
            }
        }

        // Unlocked members
        let unlockedIDs = includedIDs.filter { !lockedMembers.contains($0) }
        guard !unlockedIDs.isEmpty else { return }

        let remaining = total - lockedTotal
        let (_, amounts) = SplitCalculator.calculateEqual(total: max(remaining, 0), memberIDs: unlockedIDs)

        for (index, id) in unlockedIDs.enumerated() {
            if index < amounts.count {
                let decimal = Decimal(amounts[index]) / 100
                manualAmounts[id] = "\(NSDecimalNumber(decimal: decimal))"
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

        // Update exchange rate if currency changed
        if currencyCode != group.defaultCurrencyCode {
            if let rate = currencyService.rate(from: group.defaultCurrencyCode, to: currencyCode) {
                expense.exchangeRateToBase = rate
            }
        } else {
            expense.exchangeRateToBase = 1.0
        }

        let includedIDs = group.activeMembers.filter { includedMemberIDs.contains($0.id) }.map(\.id)

        if isManualSplit {
            // Use manual amounts
            expense.splitType = .exactAmount
            expense.splitMemberIDs = includedIDs
            expense.splitAmountsInMinorUnits = includedIDs.map { id in
                if let text = manualAmounts[id], let value = Decimal(string: text) {
                    return NSDecimalNumber(decimal: value * 100).int64Value
                }
                return 0
            }
        } else {
            // Equal split
            expense.splitType = .equal
            let (ids, amounts) = SplitCalculator.calculateEqual(total: amount, memberIDs: includedIDs)
            expense.splitMemberIDs = ids
            expense.splitAmountsInMinorUnits = amounts
        }

        try? modelContext.save()
        dismiss()
    }
}
