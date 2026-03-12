import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var avatarColor: String
    var isDefault: Bool
    var createdAt: Date

    init(name: String, avatarColor: String = "#007AFF", isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.avatarColor = avatarColor
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
