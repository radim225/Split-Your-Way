import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: UserProfile
    var onSwitchProfile: (() -> Void)?

    @State private var editName: String
    @State private var editColor: String
    @State private var isEditing = false

    init(profile: UserProfile, onSwitchProfile: (() -> Void)? = nil) {
        self.profile = profile
        self.onSwitchProfile = onSwitchProfile
        _editName = State(initialValue: profile.name)
        _editColor = State(initialValue: profile.avatarColor)
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                Section("Profile") {
                    HStack(spacing: AppSpacing.lg) {
                        Text(profile.initials)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(hex: profile.avatarColor))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            if isEditing {
                                TextField("Name", text: $editName)
                                    .font(.headline)
                            } else {
                                Text(profile.name)
                                    .font(.headline)
                            }
                            Text("Active profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(isEditing ? "Save" : "Edit") {
                            if isEditing {
                                saveProfile()
                            }
                            isEditing.toggle()
                        }
                        .font(.subheadline)
                    }

                    if isEditing {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Avatar Color")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                                ForEach(AvatarColors.all, id: \.self) { color in
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            if editColor == color {
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: 2)
                                                    .frame(width: 30, height: 30)
                                            }
                                        }
                                        .onTapGesture { editColor = color }
                                }
                            }
                        }
                    }
                }

                // Switch profile
                Section {
                    Button {
                        onSwitchProfile?()
                        dismiss()
                    } label: {
                        Label("Switch Profile", systemImage: "person.2.badge.gearshape")
                    }
                }

                // App info
                Section("About") {
                    LabeledContent("Version", value: "0.2.0")
                    LabeledContent("Build", value: "Phase 2")

                    HStack {
                        Text("Made with")
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text("by Radim")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func saveProfile() {
        let vm = ProfileViewModel(modelContext: modelContext)
        vm.updateProfile(profile, name: editName, avatarColor: editColor)
    }
}
