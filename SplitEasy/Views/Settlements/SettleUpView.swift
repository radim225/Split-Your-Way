import SwiftData
import SwiftUI

struct SettleUpView: View {
    @Environment(\.modelContext) private var modelContext
    let group: ExpenseGroup

    @State private var suggestions: [SuggestedSettlement] = []
    @State private var settledIDs: Set<UUID> = []

    var body: some View {
        List {
            if suggestions.isEmpty {
                Section {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("All Settled!")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Everyone is square in this group.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            } else {
                Section("Suggested Settlements") {
                    ForEach(suggestions) { settlement in
                        let from = group.members.first { $0.id == settlement.fromMemberID }
                        let to = group.members.first { $0.id == settlement.toMemberID }

                        HStack(spacing: AppSpacing.md) {
                            if let from {
                                MemberAvatarView(member: from, size: 36)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(from?.name ?? "?") pays \(to?.name ?? "?")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(CurrencyFormatter.format(minorUnits: settlement.amountInMinorUnits, currencyCode: group.defaultCurrencyCode))
                                    .font(.headline)
                                    .foregroundStyle(.red)
                            }

                            Spacer()

                            if settledIDs.contains(settlement.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                            } else {
                                Button("Settle") {
                                    markSettled(settlement)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }

            // History
            let settledItems = group.settlements.filter(\.isSettled).sorted { $0.date > $1.date }
            if !settledItems.isEmpty {
                Section("Settlement History") {
                    ForEach(settledItems) { settlement in
                        let from = group.members.first { $0.id == settlement.fromMemberID }
                        let to = group.members.first { $0.id == settlement.toMemberID }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(from?.name ?? "?") paid \(to?.name ?? "?")")
                                    .font(.subheadline)
                                Text(settlement.date.shortFormatted)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(CurrencyFormatter.format(minorUnits: settlement.amountInMinorUnits, currencyCode: settlement.currencyCode))
                                .font(.subheadline)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settle Up")
        .task { calculateSuggestions() }
    }

    private func calculateSuggestions() {
        let vm = ExpenseViewModel(modelContext: modelContext)
        let balances = group.activeMembers.map { member in
            let balance = vm.memberBalance(memberID: member.id, in: group)
            return (memberID: member.id, balance: balance.toMinorUnits)
        }
        suggestions = DebtSimplifier.simplify(balances: balances)
    }

    private func markSettled(_ settlement: SuggestedSettlement) {
        let record = Settlement(
            fromMemberID: settlement.fromMemberID,
            toMemberID: settlement.toMemberID,
            amountInMinorUnits: settlement.amountInMinorUnits,
            currencyCode: group.defaultCurrencyCode
        )
        record.isSettled = true
        record.group = group
        modelContext.insert(record)
        try? modelContext.save()

        withAnimation {
            settledIDs.insert(settlement.id)
        }

        // Recalculate after a short delay
        Task {
            try? await Task.sleep(for: .seconds(1))
            calculateSuggestions()
        }
    }
}
