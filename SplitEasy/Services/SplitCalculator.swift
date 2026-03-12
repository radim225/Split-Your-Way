import Foundation

enum SplitCalculator {
    /// Equal split with round-robin remainder distribution
    static func calculateEqual(total: Int64, memberIDs: [UUID]) -> ([UUID], [Int64]) {
        guard !memberIDs.isEmpty else { return ([], []) }
        let count = Int64(memberIDs.count)
        let perPerson = total / count
        let remainder = total - (perPerson * count)

        let amounts = memberIDs.enumerated().map { idx, _ in
            perPerson + (Int64(idx) < remainder ? 1 : 0)
        }
        return (memberIDs, amounts)
    }

    /// Exact amounts — caller provides per-member amounts (must sum to total)
    static func calculateExact(memberAmounts: [(UUID, Int64)]) -> ([UUID], [Int64]) {
        let ids = memberAmounts.map(\.0)
        let amounts = memberAmounts.map(\.1)
        return (ids, amounts)
    }

    /// Percentage split — each member gets a percentage of the total
    static func calculatePercentage(total: Int64, memberPercentages: [(UUID, Double)]) -> ([UUID], [Int64]) {
        guard !memberPercentages.isEmpty else { return ([], []) }
        let ids = memberPercentages.map(\.0)

        var amounts = memberPercentages.map { _, pct in
            Int64((Double(total) * pct / 100.0).rounded())
        }

        // Adjust last person to ensure sum matches total
        let sum = amounts.reduce(0, +)
        let diff = total - sum
        if let lastIdx = amounts.indices.last {
            amounts[lastIdx] += diff
        }

        return (ids, amounts)
    }

    /// Shares/weights — proportional split based on share counts
    static func calculateShares(total: Int64, memberShares: [(UUID, Int)]) -> ([UUID], [Int64]) {
        guard !memberShares.isEmpty else { return ([], []) }
        let ids = memberShares.map(\.0)
        let totalShares = memberShares.reduce(0) { $0 + $1.1 }
        guard totalShares > 0 else { return calculateEqual(total: total, memberIDs: ids) }

        var amounts = memberShares.map { _, shares in
            Int64((Double(total) * Double(shares) / Double(totalShares)).rounded(.down))
        }

        // Distribute remainder
        let sum = amounts.reduce(0, +)
        var remainder = total - sum
        var idx = 0
        while remainder > 0 {
            amounts[idx % amounts.count] += 1
            remainder -= 1
            idx += 1
        }

        return (ids, amounts)
    }

    /// Adjustment — equal split plus per-member adjustments (adjustments must net to zero)
    static func calculateAdjustment(total: Int64, memberCount: Int, memberAdjustments: [(UUID, Int64)]) -> ([UUID], [Int64]) {
        guard !memberAdjustments.isEmpty else { return ([], []) }
        let ids = memberAdjustments.map(\.0)
        let equalPart = total / Int64(memberCount)

        let amounts = memberAdjustments.map { _, adjustment in
            equalPart + adjustment
        }

        return (ids, amounts)
    }

    /// Itemized — each item assigned to members, split equally within each item
    static func calculateItemized(items: [(amount: Int64, memberIDs: [UUID])], allMemberIDs: [UUID]) -> ([UUID], [Int64]) {
        var totals: [UUID: Int64] = [:]
        for id in allMemberIDs {
            totals[id] = 0
        }

        for item in items {
            guard !item.memberIDs.isEmpty else { continue }
            let (ids, amounts) = calculateEqual(total: item.amount, memberIDs: item.memberIDs)
            for (id, amount) in zip(ids, amounts) {
                totals[id, default: 0] += amount
            }
        }

        let ids = allMemberIDs.filter { (totals[$0] ?? 0) > 0 }
        let amounts = ids.map { totals[$0] ?? 0 }
        return (ids, amounts)
    }
}
