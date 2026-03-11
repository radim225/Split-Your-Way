import Foundation

enum CurrencyFormatter {
    private static var formatters: [String: NumberFormatter] = [:]

    static func format(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = getFormatter(for: currencyCode)
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
    }

    static func format(minorUnits: Int64, currencyCode: String) -> String {
        let amount = Decimal.fromMinorUnits(minorUnits)
        return format(amount, currencyCode: currencyCode)
    }

    private static func getFormatter(for currencyCode: String) -> NumberFormatter {
        if let cached = formatters[currencyCode] {
            return cached
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode

        if let info = CurrencyInfo.find(byCode: currencyCode) {
            formatter.currencySymbol = info.symbol
        }

        // JPY, KRW etc. have 0 decimal places
        let zeroDPCurrencies = ["JPY", "KRW", "VND", "CLP", "ISK", "HUF"]
        if zeroDPCurrencies.contains(currencyCode) {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }

        formatters[currencyCode] = formatter
        return formatter
    }
}
