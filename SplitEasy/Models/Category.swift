import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case food
    case transport
    case accommodation
    case entertainment
    case groceries
    case health
    case education
    case rent
    case utilities
    case work
    case gifts
    case other

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .food: "🍽"
        case .transport: "✈️"
        case .accommodation: "🏨"
        case .entertainment: "🎉"
        case .groceries: "🛒"
        case .health: "💊"
        case .education: "🎓"
        case .rent: "🏠"
        case .utilities: "⚡"
        case .work: "💼"
        case .gifts: "🎁"
        case .other: "📦"
        }
    }

    var displayName: String {
        switch self {
        case .food: "Food"
        case .transport: "Transport"
        case .accommodation: "Accommodation"
        case .entertainment: "Entertainment"
        case .groceries: "Groceries"
        case .health: "Health"
        case .education: "Education"
        case .rent: "Rent"
        case .utilities: "Utilities"
        case .work: "Work"
        case .gifts: "Gifts"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "airplane"
        case .accommodation: "bed.double"
        case .entertainment: "party.popper"
        case .groceries: "cart"
        case .health: "cross.case"
        case .education: "graduationcap"
        case .rent: "house"
        case .utilities: "bolt"
        case .work: "briefcase"
        case .gifts: "gift"
        case .other: "shippingbox"
        }
    }

    var colorHex: String {
        switch self {
        case .food: "#FF9500"
        case .transport: "#007AFF"
        case .accommodation: "#AF52DE"
        case .entertainment: "#FF2D55"
        case .groceries: "#34C759"
        case .health: "#FF3B30"
        case .education: "#5856D6"
        case .rent: "#8E8E93"
        case .utilities: "#FFCC00"
        case .work: "#00C7BE"
        case .gifts: "#FF6482"
        case .other: "#636366"
        }
    }
}
