import Foundation

struct SuggestedSettlement: Identifiable {
    let id = UUID()
    let fromMemberID: UUID
    let toMemberID: UUID
    let amountInMinorUnits: Int64
}

enum DebtSimplifier {
    /// Greedy net-balance algorithm to minimize number of transactions.
    /// Returns at most (n-1) settlements.
    static func simplify(balances: [(memberID: UUID, balance: Int64)]) -> [SuggestedSettlement] {
        // Filter out zero balances
        var debtors: [(UUID, Int64)] = [] // negative balance (they owe)
        var creditors: [(UUID, Int64)] = [] // positive balance (they are owed)

        for (id, balance) in balances {
            if balance < 0 {
                debtors.append((id, -balance)) // store as positive amount
            } else if balance > 0 {
                creditors.append((id, balance))
            }
        }

        // Sort descending by amount
        debtors.sort { $0.1 > $1.1 }
        creditors.sort { $0.1 > $1.1 }

        var settlements: [SuggestedSettlement] = []
        var di = 0
        var ci = 0

        while di < debtors.count && ci < creditors.count {
            let amount = min(debtors[di].1, creditors[ci].1)
            if amount > 0 {
                settlements.append(SuggestedSettlement(
                    fromMemberID: debtors[di].0,
                    toMemberID: creditors[ci].0,
                    amountInMinorUnits: amount
                ))
            }

            debtors[di].1 -= amount
            creditors[ci].1 -= amount

            if debtors[di].1 == 0 { di += 1 }
            if creditors[ci].1 == 0 { ci += 1 }
        }

        return settlements
    }
}
