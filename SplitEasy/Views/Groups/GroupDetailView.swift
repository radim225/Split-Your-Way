import SwiftData
import SwiftUI

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let group: ExpenseGroup

    @State private var selectedTab = 0
    @State private var showAddExpense = false
    @State private var showManageMembers = false
    @State private var showSettleUp = false
    @State private var showStatistics = false
    @State private var showExportShare = false
    @State private var exportURL: URL?

    var sortedExpenses: [Expense] {
        group.expenses.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Enhanced header
            GroupHeaderView(group: group)

            // Tab picker
            Picker("View", selection: $selectedTab) {
                Text("Expenses").tag(0)
                Text("Members").tag(1)
                Text("Balances").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, AppSpacing.sm)

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

                    Divider()

                    Button {
                        showSettleUp = true
                    } label: {
                        Label("Settle Up", systemImage: "arrow.left.arrow.right")
                    }

                    Button {
                        showStatistics = true
                    } label: {
                        Label("Statistics", systemImage: "chart.bar")
                    }

                    Divider()

                    Button {
                        exportCSV()
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Floating add button
            Button {
                showAddExpense = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xl)
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseView(group: group)
        }
        .sheet(isPresented: $showManageMembers) {
            MemberManageView(group: group)
        }
        .sheet(isPresented: $showSettleUp) {
            NavigationStack {
                SettleUpView(group: group)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettleUp = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showStatistics) {
            NavigationStack {
                StatisticsView(group: group)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showStatistics = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showExportShare) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    // MARK: - Expenses Tab

    private var expensesTab: some View {
        Group {
            if sortedExpenses.isEmpty {
                EmptyStateView(
                    icon: "creditcard",
                    title: "No Expenses Yet",
                    subtitle: "Add an expense to start tracking who owes what.",
                    actionTitle: "Add Expense"
                ) {
                    showAddExpense = true
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
        Group {
            if group.activeMembers.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Members",
                    subtitle: "Add members to start splitting expenses.",
                    actionTitle: "Manage Members"
                ) {
                    showManageMembers = true
                }
            } else {
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
        }
    }

    // MARK: - Balances Tab

    private var balancesTab: some View {
        let vm = ExpenseViewModel(modelContext: modelContext)
        return ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Balance bubbles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.lg) {
                        ForEach(group.activeMembers) { member in
                            let balance = vm.memberBalance(memberID: member.id, in: group)
                            BalanceBubbleView(
                                member: member,
                                balance: balance,
                                currencyCode: group.defaultCurrencyCode
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, AppSpacing.md)

                // Balance list
                VStack(spacing: 0) {
                    ForEach(group.activeMembers) { member in
                        let balance = vm.memberBalance(memberID: member.id, in: group)
                        HStack {
                            MemberAvatarView(member: member, size: 36)
                            Text(member.name)
                                .font(.body)
                            Spacer()
                            Text(CurrencyFormatter.format(balance, currencyCode: group.defaultCurrencyCode))
                                .foregroundStyle(balance >= 0 ? .green : .red)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, AppSpacing.md)

                        if member.id != group.activeMembers.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg))
                .padding(.horizontal)

                // Settle up button
                if group.expenses.count > 0 {
                    Button {
                        showSettleUp = true
                    } label: {
                        Label("Settle Up", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 80) // space for floating button
        }
        .background(Color(.systemGroupedBackground))
    }

    private func deleteExpenses(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedExpenses[index])
        }
        try? modelContext.save()
    }

    private func exportCSV() {
        let csv = ExportService.generateCSV(for: group)
        let filename = "\(group.name.replacingOccurrences(of: " ", with: "_"))_expenses.csv"
        if let url = ExportService.writeToTempFile(csv: csv, filename: filename) {
            exportURL = url
            showExportShare = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Views

struct GroupHeaderView: View {
    let group: ExpenseGroup

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(group.emoji)
                .font(.system(size: 44))

            Text(CurrencyFormatter.format(minorUnits: group.totalExpensesInMinorUnits, currencyCode: group.defaultCurrencyCode))
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: AppSpacing.lg) {
                Label("\(group.activeMembers.count) members", systemImage: "person.2")
                Label("\(group.expenses.count) expenses", systemImage: "creditcard")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    let group: ExpenseGroup

    var paidByName: String {
        group.members.first { $0.id == expense.paidByMemberID }?.name ?? "Unknown"
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(expense.expenseCategory.emoji)
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))

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
            MemberAvatarView(member: member, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(balance == 0 ? "Settled" : (balance > 0 ? "Is owed" : "Owes"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.format(balance, currencyCode: group.defaultCurrencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
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
