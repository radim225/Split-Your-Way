import Foundation
import SwiftData

@Model
final class Member {
    var id: UUID
    var name: String
    var avatarColor: String
    var defaultWeight: Double
    var isActive: Bool
    var group: ExpenseGroup?

    init(
        name: String,
        avatarColor: String = "#007AFF",
        defaultWeight: Double = 1.0
    ) {
        self.id = UUID()
        self.name = name
        self.avatarColor = avatarColor
        self.defaultWeight = defaultWeight
        self.isActive = true
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
