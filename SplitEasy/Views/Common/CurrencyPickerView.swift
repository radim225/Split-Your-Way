import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCode: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    var filteredCurrencies: [CurrencyInfo] {
        if searchText.isEmpty { return CurrencyInfo.allCurrencies }
        return CurrencyInfo.allCurrencies.filter {
            $0.code.localizedCaseInsensitiveContains(searchText) ||
                $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCurrencies, id: \.code) { currency in
                    Button {
                        selectedCode = currency.code
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Text(currency.flag)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(currency.code)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(currency.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedCode == currency.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
