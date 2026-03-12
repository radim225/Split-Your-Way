import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class GroupViewModel {
    var searchText = ""
    var showArchived = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchGroups(profileID: UUID) -> [ExpenseGroup] {
        var descriptor = FetchDescriptor<ExpenseGroup>(
            predicate: #Predicate<ExpenseGroup> { group in
                group.profileID == profileID && !group.isArchived
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 100

        let groups = (try? modelContext.fetch(descriptor)) ?? []

        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func createGroup(name: String, emoji: String, colorHex: String, currencyCode: String, memberNames: [String], profileID: UUID) -> ExpenseGroup {
        let group = ExpenseGroup(
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            defaultCurrencyCode: currencyCode,
            profileID: profileID
        )
        modelContext.insert(group)

        for memberName in memberNames where !memberName.trimmingCharacters(in: .whitespaces).isEmpty {
            let member = Member(name: memberName.trimmingCharacters(in: .whitespaces), avatarColor: AvatarColors.random())
            member.group = group
            modelContext.insert(member)
        }

        try? modelContext.save()
        return group
    }

    func deleteGroup(_ group: ExpenseGroup) {
        modelContext.delete(group)
        try? modelContext.save()
    }

    func archiveGroup(_ group: ExpenseGroup) {
        group.isArchived = true
        try? modelContext.save()
    }

    func addMember(to group: ExpenseGroup, name: String) {
        let member = Member(name: name, avatarColor: AvatarColors.random())
        member.group = group
        modelContext.insert(member)
        try? modelContext.save()
    }

    func removeMember(_ member: Member) {
        member.isActive = false
        try? modelContext.save()
    }

    func renameMember(_ member: Member, to newName: String) {
        member.name = newName
        try? modelContext.save()
    }
}
