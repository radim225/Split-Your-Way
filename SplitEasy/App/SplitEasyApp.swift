import SwiftData
import SwiftUI

@main
struct SplitEasyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            ExpenseGroup.self,
            Member.self,
            Expense.self,
            ExpenseItem.self,
            Settlement.self,
        ])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<UserProfile> { $0.isDefault }) private var defaultProfiles: [UserProfile]

    @State private var activeProfile: UserProfile?
    @State private var showProfilePicker = false

    var body: some View {
        Group {
            if let profile = activeProfile {
                GroupListView(profileID: profile.id, profile: profile) {
                    showProfilePicker = true
                }
            } else {
                ProfilePickerView { profile in
                    activeProfile = profile
                }
            }
        }
        .onAppear {
            if activeProfile == nil, let profile = defaultProfiles.first {
                activeProfile = profile
            }
        }
        .onChange(of: defaultProfiles) {
            if activeProfile == nil, let profile = defaultProfiles.first {
                activeProfile = profile
            }
        }
        .fullScreenCover(isPresented: $showProfilePicker) {
            ProfilePickerView { profile in
                activeProfile = profile
                showProfilePicker = false
            }
        }
    }
}
