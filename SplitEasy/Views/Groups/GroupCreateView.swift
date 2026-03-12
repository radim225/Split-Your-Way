import SwiftData
import SwiftUI

struct GroupCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profileID: UUID

    @State private var name = ""
    @State private var emoji = "👥"
    @State private var colorHex = "#007AFF"
    @State private var currencyCode = "USD"
    @State private var memberNames: [String] = ["", ""]
    @State private var showEmojiPicker = false

    private let emojiOptions = ["👥", "🏖️", "🏠", "🍕", "✈️", "🎉", "💼", "🎓", "🛒", "⚽", "🎮", "🎸", "🏕️", "🚗", "❤️", "🌍"]
    private let colorOptions = ["#007AFF", "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#F7DC6F"]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            memberNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count >= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                // Group Info
                Section("Group Info") {
                    TextField("Group Name", text: $name)
                        .accessibilityLabel("Group name")

                    // Emoji picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { option in
                                Text(option)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(emoji == option ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture {
                                        emoji = option
                                    }
                            }
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorHex == color {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        colorHex = color
                                    }
                            }
                        }
                    }
                }

                // Currency
                Section("Default Currency") {
                    Picker("Currency", selection: $currencyCode) {
                        ForEach(CurrencyInfo.allCurrencies) { currency in
                            Text("\(currency.flag) \(currency.code) - \(currency.name)")
                                .tag(currency.code)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                // Members
                Section {
                    ForEach(memberNames.indices, id: \.self) { index in
                        HStack {
                            TextField("Member \(index + 1)", text: $memberNames[index])
                            if memberNames.count > 2 {
                                Button {
                                    memberNames.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        memberNames.append("")
                    } label: {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Members (min. 2)")
                } footer: {
                    Text("You can always add more members later.")
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func createGroup() {
        let vm = GroupViewModel(modelContext: modelContext)
        let validNames = memberNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        _ = vm.createGroup(
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            colorHex: colorHex,
            currencyCode: currencyCode,
            memberNames: validNames,
            profileID: profileID
        )
        dismiss()
    }
}
