import SwiftData
import SwiftUI

struct ProfilePickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]

    var onProfileSelected: ((UserProfile) -> Void)?

    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // App icon
                VStack(spacing: 12) {
                    Image(systemName: "dollarsign.arrow.trianglehead.counterclockwise.rotate.90")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)

                    Text("SplitEasy")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Split expenses with friends")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if profiles.isEmpty {
                    // First time — create profile
                    VStack(spacing: 16) {
                        Text("Create your profile to get started")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create Profile", systemImage: "person.badge.plus")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    // Profile list
                    VStack(spacing: 8) {
                        Text("Who's using the app?")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(profiles) { profile in
                                    Button {
                                        selectProfile(profile)
                                    } label: {
                                        HStack(spacing: 14) {
                                            Text(profile.initials)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 48, height: 48)
                                                .background(Color(hex: profile.avatarColor))
                                                .clipShape(Circle())

                                            Text(profile.name)
                                                .font(.title3)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            if profile.isDefault {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color.accentColor)
                                            }

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                }

                                Button {
                                    showCreateSheet = true
                                } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "plus")
                                            .font(.title3)
                                            .foregroundStyle(Color.accentColor)
                                            .frame(width: 48, height: 48)
                                            .background(Color.accentColor.opacity(0.1))
                                            .clipShape(Circle())

                                        Text("Add Profile")
                                            .font(.title3)
                                            .foregroundStyle(Color.accentColor)

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer()
            }
            .sheet(isPresented: $showCreateSheet) {
                ProfileCreateView { profile in
                    onProfileSelected?(profile)
                }
            }
        }
    }

    private func selectProfile(_ profile: UserProfile) {
        let vm = ProfileViewModel(modelContext: modelContext)
        vm.setDefault(profile: profile)
        onProfileSelected?(profile)
    }
}
