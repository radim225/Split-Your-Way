import SwiftData
import SwiftUI

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let group: ExpenseGroup

    @State private var selectedTab = 0
    @State private var showAddExpense = false
    @State private var showManageMembers = false

    var sortedExpenses: [Expense] {
        group.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            GroupHeaderView(group: group)

            // Tab picker
            Picker("View", selection: $selectedTab) {
                Text("Expenses").tag(0)
                Text("Members").tag(1)
                Text("Balances").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            // Tab content
            switch selectedTab {
            case 0:
                expensesTab
            case 1:
                membersTab
            case 2:
                balancesTab
            default:
                EmptyView()
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showAddExpense = true
                    } label: {
                        Label("Add Expense", systemImage: "plus.circle")
                    }
                    Button {
                        showManageMembers = true
                    } label: {
                        Label("Manage Members", systemImage: "person.2.badge.gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(group: group)
        }
        .sheet(isPresented: $showManageMembers) {
            MemberManageView(group: group)
        }
    }

    // MARK: - Expenses Tab

    private var expensesTab: some View {
        Group {
            if sortedExpenses.isEmpty {
                ContentUnavailableView {
                    Label("No Expenses", systemImage: "creditcard")
                } description: {
                    Text("Add an expense to get started.")
                } actions: {
                    Button("Add Expense") {
                        showAddExpense = true
                    }
                }
            } else {
                List {
                    ForEach(sortedExpenses) { expense in
                        NavigationLink {
                            ExpenseDetailView(expense: expense, group: group)
                        } label: {
                            ExpenseRowView(expense: expense, group: group)
                        }
                    }
                    .onDelete(perform: deleteExpenses)
                }
            }
        }
    }

    // MARK: - Members Tab

    private var membersTab: some View {
        List {
            ForEach(group.activeMembers) { member in
                MemberRowView(member: member, group: group, modelContext: modelContext)
            }

            Button {
                showManageMembers = true
            } label: {
                Label("Manage Members", systemImage: "person.badge.plus")
            }
        }
    }

    // MARK: - Balances Tab

    private var balancesTab: some View {
        let vm = ExpenseViewModel(modelContext: modelContext)
        return List {
            ForEach(group.activeMembers) { member in
                let balance = vm.memberBalance(memberID: member.id, in: group)
                HStack {
                    MemberAvatarView(member: member, size: 36)
                    Text(member.name)
                    Spacer()
                    Text(CurrencyFormatter.format(balance, currencyCode: group.defaultCurrencyCode))
                        .foregroundStyle(balance >= 0 ? .green : .red)
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("\(member.name), balance: \(CurrencyFormatter.format(balance, currencyCode: group.defaultCurrencyCode))")
            }
        }
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedExpenses[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct GroupHeaderView: View {
    let group: ExpenseGroup

    var body: some View {
        VStack(spacing: 8) {
            Text(group.emoji)
                .font(.system(size: 48))

            Text(CurrencyFormatter.format(minorUnits: group.totalExpensesInMinorUnits, currencyCode: group.defaultCurrencyCode))
                .font(.title2)
                .fontWeight(.bold)

            Text("\(group.activeMembers.count) members")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let group: ExpenseGroup

    var paidByName: String {
        group.members.first { $0.id == expense.paidByMemberID }?.name ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(expense.expenseCategory.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Paid by \(paidByName) · \(expense.date.shortFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.format(minorUnits: expense.amountInMinorUnits, currencyCode: expense.currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 2)
    }
}

struct MemberRowView: View {
    let member: Member
    let group: ExpenseGroup
    let modelContext: ModelContext

    var body: some View {
        let vm = ExpenseViewModel(modelContext: modelContext)
        let balance = vm.memberBalance(memberID: member.id, in: group)

        HStack {
            MemberAvatarView(member: member, size: 36)
            Text(member.name)
                .font(.body)
            Spacer()
            Text(CurrencyFormatter.format(balance, currencyCode: group.defaultCurrencyCode))
                .font(.subheadline)
                .foregroundStyle(balance >= 0 ? .green : .red)
        }
    }
}

struct MemberAvatarView: View {
    let member: Member
    let size: CGFloat

    var body: some View {
        Text(member.initials)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color(hex: member.avatarColor))
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}
