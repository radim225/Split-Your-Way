import SwiftData
import SwiftUI

struct GroupListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ExpenseGroup> { !$0.isArchived },
           sort: \ExpenseGroup.createdAt, order: .reverse)
    private var groups: [ExpenseGroup]

    @State private var searchText = ""
    @State private var showCreateSheet = false
    @State private var hasSeeded = false

    var filteredGroups: [ExpenseGroup] {
        if searchText.isEmpty { return groups }
        return groups.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredGroups.isEmpty {
                    ContentUnavailableView {
                        Label("No Groups", systemImage: "person.3")
                    } description: {
                        Text("Create a group to start splitting expenses.")
                    } actions: {
                        Button("Create Group") {
                            showCreateSheet = true
                        }
                    }
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
            .navigationTitle("SplitEasy")
            .searchable(text: $searchText, prompt: "Search groups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create new group")
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                GroupCreateView()
            }
            .navigationDestination(for: ExpenseGroup.self) { group in
                GroupDetailView(group: group)
            }
            .onAppear {
                if !hasSeeded {
                    SampleDataService.loadIfNeeded(context: modelContext)
                    hasSeeded = true
                }
            }
        }
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredGroups[index])
        }
        try? modelContext.save()
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
        .accessibilityLabel("\(group.name) group, \(group.activeMembers.count) members, total \(CurrencyFormatter.format(minorUnits: group.totalExpensesInMinorUnits, currencyCode: group.defaultCurrencyCode))")
    }
}
