import SwiftData
import SwiftUI

struct ProfileCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var onCreated: ((UserProfile) -> Void)?

    @State private var name = ""
    @State private var selectedColor = AvatarColors.all[0]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Avatar preview
                Text(initials)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 100, height: 100)
                    .background(Color(hex: selectedColor))
                    .clipShape(Circle())
                    .shadow(color: Color(hex: selectedColor).opacity(0.4), radius: 12, y: 6)

                // Name field
                VStack(spacing: 8) {
                    Text("What's your name?")
                        .font(.title2)
                        .fontWeight(.bold)

                    TextField("Enter your name", text: $name)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 40)
                }

                // Color picker
                VStack(spacing: 8) {
                    Text("Pick a color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(AvatarColors.all, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if selectedColor == color {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                            .frame(width: 34, height: 34)
                                    }
                                }
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedColor = color
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()

                // Create button
                Button {
                    createProfile()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? Color.accentColor : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!isValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2)).uppercased()
    }

    private func createProfile() {
        let vm = ProfileViewModel(modelContext: modelContext)
        let profile = vm.createProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            avatarColor: selectedColor
        )
        onCreated?(profile)
        dismiss()
    }
}
