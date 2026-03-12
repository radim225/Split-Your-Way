import Foundation
import SwiftData

@MainActor
@Observable
final class ProfileViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchProfiles() -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func defaultProfile() -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.isDefault }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    @discardableResult
    func createProfile(name: String, avatarColor: String) -> UserProfile {
        // Clear previous default
        let existing = fetchProfiles()
        for profile in existing {
            profile.isDefault = false
        }

        let profile = UserProfile(name: name, avatarColor: avatarColor, isDefault: true)
        modelContext.insert(profile)
        try? modelContext.save()
        return profile
    }

    func setDefault(profile: UserProfile) {
        let all = fetchProfiles()
        for p in all {
            p.isDefault = (p.id == profile.id)
        }
        try? modelContext.save()
    }

    func deleteProfile(_ profile: UserProfile) {
        // Delete all groups belonging to this profile
        let profileID = profile.id
        var groupDescriptor = FetchDescriptor<ExpenseGroup>(
            predicate: #Predicate<ExpenseGroup> { $0.profileID == profileID }
        )
        groupDescriptor.fetchLimit = 1000
        if let groups = try? modelContext.fetch(groupDescriptor) {
            for group in groups {
                modelContext.delete(group)
            }
        }

        modelContext.delete(profile)
        try? modelContext.save()
    }

    func updateProfile(_ profile: UserProfile, name: String, avatarColor: String) {
        profile.name = name
        profile.avatarColor = avatarColor
        try? modelContext.save()
    }
}
