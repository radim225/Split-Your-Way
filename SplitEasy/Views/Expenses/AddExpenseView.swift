import SwiftData
import SwiftUI

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let group: ExpenseGroup

    @State private var title = ""
    @State private var amountText = ""
    @State private var currencyCode: String
    @State private var date = Date()
    @State private var category: ExpenseCategory = .other
    @State private var selectedPayerID: UUID?
    @State private var note = ""
    @State private var includedMemberIDs: Set<UUID> = []
    @State private var showMoreOptions = false
    @State private var showCurrencyPicker = false
    @State private var currencyService = CurrencyService()

    init(group: ExpenseGroup) {
        self.group = group
        _currencyCode = State(initialValue: group.defaultCurrencyCode)
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
                // Payer selection
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
                                .onTapGesture {
                                    selectedPayerID = member.id
                                }
                                .accessibilityLabel("Paid by \(member.name)")
                                .accessibilityAddTraits(selectedPayerID == member.id ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Amount & Title
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
                            .accessibilityLabel("Amount")
                    }

                    TextField("What was it for?", text: $title)
                        .accessibilityLabel("Expense title")

                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                // Split among
                Section {
                    ForEach(group.activeMembers) { member in
                        Toggle(isOn: Binding(
                            get: { includedMemberIDs.contains(member.id) },
                            set: { included in
                                if included {
                                    includedMemberIDs.insert(member.id)
                                } else {
                                    includedMemberIDs.remove(member.id)
                                }
                            }
                        )) {
                            HStack {
                                MemberAvatarView(member: member, size: 28)
                                Text(member.name)
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
                    if let amount = amountInMinorUnits, includedMemberIDs.count > 0 {
                        let perPerson = Decimal(amount / Int64(includedMemberIDs.count)) / 100
                        Text("Equal split: \(CurrencyFormatter.format(perPerson, currencyCode: currencyCode)) per person")
                    }
                }

                // More options
                if showMoreOptions {
                    Section("Notes") {
                        TextField("Add a note (optional)", text: $note, axis: .vertical)
                            .lineLimit(3 ... 6)
                    }
                } else {
                    Section {
                        Button {
                            showMoreOptions = true
                        } label: {
                            Label("More Options", systemImage: "ellipsis.circle")
                        }
                    }
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerView(selectedCode: $currencyCode)
            }
            .onAppear {
                if selectedPayerID == nil {
                    selectedPayerID = group.activeMembers.first?.id
                }
                if includedMemberIDs.isEmpty {
                    includedMemberIDs = Set(group.activeMembers.map(\.id))
                }
            }
            .task {
                await currencyService.fetchRates(base: group.defaultCurrencyCode)
            }
        }
    }

    private func addExpense() {
        guard let amount = amountInMinorUnits,
              let payerID = selectedPayerID else { return }

        let includedMembers = group.activeMembers.filter { includedMemberIDs.contains($0.id) }

        // Calculate exchange rate from expense currency to group base currency
        var exchangeRate = 1.0
        if currencyCode != group.defaultCurrencyCode {
            if let rate = currencyService.rate(from: group.defaultCurrencyCode, to: currencyCode) {
                exchangeRate = rate
            }
        }

        let expense = Expense(
            title: title.trimmingCharacters(in: .whitespaces),
            amountInMinorUnits: amount,
            currencyCode: currencyCode,
            exchangeRateToBase: exchangeRate,
            date: date,
            category: category,
            splitType: .equal,
            paidByMemberID: payerID,
            note: note.isEmpty ? nil : note
        )
        expense.group = group

        let (ids, amounts) = SplitCalculator.calculateEqual(total: amount, memberIDs: includedMembers.map(\.id))
        expense.splitMemberIDs = ids
        expense.splitAmountsInMinorUnits = amounts

        modelContext.insert(expense)
        try? modelContext.save()
        dismiss()
    }
}
