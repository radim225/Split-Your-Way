import SwiftData
import SwiftUI

struct MemberManageView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let group: ExpenseGroup

    @State private var newMemberName = ""
    @State private var editingMemberID: UUID?
    @State private var editName = ""
    @State private var showRemoveAlert = false
    @State private var memberToRemove: Member?

    var body: some View {
        NavigationStack {
            List {
                // Active members
                Section("Members (\(group.activeMembers.count))") {
                    ForEach(group.activeMembers) { member in
                        HStack {
                            MemberAvatarView(member: member, size: 36)

                            if editingMemberID == member.id {
                                TextField("Name", text: $editName)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        saveName(for: member)
                                    }

                                Button {
                                    saveName(for: member)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(member.name)
                                    .font(.body)

                                Spacer()

                                Button {
                                    editingMemberID = member.id
                                    editName = member.name
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                memberToRemove = member
                                showRemoveAlert = true
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }

                // Inactive members
                let inactiveMembers = group.members.filter { !$0.isActive }
                if !inactiveMembers.isEmpty {
                    Section("Removed Members") {
                        ForEach(inactiveMembers) { member in
                            HStack {
                                MemberAvatarView(member: member, size: 28)
                                    .opacity(0.5)
                                Text(member.name)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Restore") {
                                    member.isActive = true
                                    try? modelContext.save()
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                // Add new member
                Section("Add Member") {
                    HStack {
                        TextField("New member name", text: $newMemberName)
                            .accessibilityLabel("New member name")

                        Button {
                            addMember()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newMemberName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Add member")
                    }
                }
            }
            .navigationTitle("Manage Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Remove Member?", isPresented: $showRemoveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
            } message: {
                if let member = memberToRemove {
                    let hasExpenses = group.expenses.contains { expense in
                        expense.paidByMemberID == member.id ||
                            expense.splitMemberIDs.contains(member.id)
                    }
                    if hasExpenses {
                        Text("\(member.name) has linked expenses and will be marked as removed but kept in history.")
                    } else {
                        Text("\(member.name) will be permanently removed from this group.")
                    }
                }
            }
        }
    }

    private func addMember() {
        let name = newMemberName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let member = Member(name: name, avatarColor: AvatarColors.random())
        member.group = group
        modelContext.insert(member)
        try? modelContext.save()
        newMemberName = ""
    }

    private func saveName(for member: Member) {
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            member.name = trimmed
            try? modelContext.save()
        }
        editingMemberID = nil
    }

    private func removeMember(_ member: Member) {
        let hasExpenses = group.expenses.contains { expense in
            expense.paidByMemberID == member.id ||
                expense.splitMemberIDs.contains(member.id)
        }

        if hasExpenses {
            // Soft delete — keep in history
            member.isActive = false
        } else {
            // Hard delete — no linked data
            modelContext.delete(member)
        }
        try? modelContext.save()
    }
}
