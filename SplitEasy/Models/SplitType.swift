import Foundation

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case equal
    case exactAmount
    case percentage
    case shares
    case adjustment
    case itemized

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equal: "Equal"
        case .exactAmount: "Amounts"
        case .percentage: "Percentages"
        case .shares: "Shares"
        case .adjustment: "Adjust"
        case .itemized: "Items"
        }
    }

    var iconName: String {
        switch self {
        case .equal: "equal.circle"
        case .exactAmount: "dollarsign.circle"
        case .percentage: "percent"
        case .shares: "chart.pie"
        case .adjustment: "plusminus.circle"
        case .itemized: "list.bullet"
        }
    }
}
