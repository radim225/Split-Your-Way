import SwiftData
import SwiftUI

struct GroupListView: View {
    @Environment(\.modelContext) private var modelContext

    let profileID: UUID
    let profile: UserProfile
    var onSwitchProfile: (() -> Void)?

    @State private var groups: [ExpenseGroup] = []
    @State private var searchText = ""
    @State private var showCreateSheet = false
    @State private var showSettings = false

    var filteredGroups: [ExpenseGroup] {
        if searchText.isEmpty { return groups }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredGroups.isEmpty && searchText.isEmpty {
                    ContentUnavailableView {
                        Label("No Trips Yet", systemImage: "airplane.departure")
                    } description: {
                        Text("Create your first trip to start splitting expenses with friends.")
                    } actions: {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create Trip", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if filteredGroups.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredGroups) { group in
                            NavigationLink(value: group) {
                                GroupRowView(group: group)
                            }
                        }
                        .onDelete(perform: deleteGroups)
                    }
                }
            }
            .navigationTitle("My Trips")
            .searchable(text: $searchText, prompt: "Search trips")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Text(profile.initials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: profile.avatarColor))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create new trip")
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                GroupCreateView(profileID: profileID)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(profile: profile, onSwitchProfile: onSwitchProfile)
            }
            .navigationDestination(for: ExpenseGroup.self) { group in
                GroupDetailView(group: group)
            }
            .task {
                loadGroups()
            }
            .onChange(of: showCreateSheet) {
                if !showCreateSheet { loadGroups() }
            }
        }
    }

    private func loadGroups() {
        let pid = profileID
        var descriptor = FetchDescriptor<ExpenseGroup>(
            predicate: #Predicate<ExpenseGroup> { group in
                group.profileID == pid && !group.isArchived
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        groups = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredGroups[index])
        }
        try? modelContext.save()
        loadGroups()
    }
}

struct GroupRowView: View {
    let group: ExpenseGroup

    var body: some View {
        HStack(spacing: 12) {
            Text(group.emoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color(hex: group.colorHex).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(group.activeMembers.count)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.format(minorUnits: group.totalExpensesInMinorUnits, currencyCode: group.defaultCurrencyCode))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(group.name), \(group.activeMembers.count) members, total \(CurrencyFormatter.format(minorUnits: group.totalExpensesInMinorUnits, currencyCode: group.defaultCurrencyCode))")
    }
}
