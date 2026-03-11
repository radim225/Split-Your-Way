import Foundation

struct CurrencyInfo: Codable, Hashable, Identifiable {
    let code: String
    let name: String
    let symbol: String
    let flag: String

    var id: String { code }

    static let allCurrencies: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", name: "US Dollar", symbol: "$", flag: "🇺🇸"),
        CurrencyInfo(code: "EUR", name: "Euro", symbol: "€", flag: "🇪🇺"),
        CurrencyInfo(code: "GBP", name: "British Pound", symbol: "£", flag: "🇬🇧"),
        CurrencyInfo(code: "JPY", name: "Japanese Yen", symbol: "¥", flag: "🇯🇵"),
        CurrencyInfo(code: "CHF", name: "Swiss Franc", symbol: "CHF", flag: "🇨🇭"),
        CurrencyInfo(code: "CAD", name: "Canadian Dollar", symbol: "CA$", flag: "🇨🇦"),
        CurrencyInfo(code: "AUD", name: "Australian Dollar", symbol: "A$", flag: "🇦🇺"),
        CurrencyInfo(code: "CNY", name: "Chinese Yuan", symbol: "¥", flag: "🇨🇳"),
        CurrencyInfo(code: "INR", name: "Indian Rupee", symbol: "₹", flag: "🇮🇳"),
        CurrencyInfo(code: "CZK", name: "Czech Koruna", symbol: "Kč", flag: "🇨🇿"),
        CurrencyInfo(code: "PLN", name: "Polish Zloty", symbol: "zł", flag: "🇵🇱"),
        CurrencyInfo(code: "SEK", name: "Swedish Krona", symbol: "kr", flag: "🇸🇪"),
        CurrencyInfo(code: "NOK", name: "Norwegian Krone", symbol: "kr", flag: "🇳🇴"),
        CurrencyInfo(code: "DKK", name: "Danish Krone", symbol: "kr", flag: "🇩🇰"),
        CurrencyInfo(code: "HUF", name: "Hungarian Forint", symbol: "Ft", flag: "🇭🇺"),
        CurrencyInfo(code: "THB", name: "Thai Baht", symbol: "฿", flag: "🇹🇭"),
        CurrencyInfo(code: "SGD", name: "Singapore Dollar", symbol: "S$", flag: "🇸🇬"),
        CurrencyInfo(code: "NZD", name: "New Zealand Dollar", symbol: "NZ$", flag: "🇳🇿"),
        CurrencyInfo(code: "KRW", name: "South Korean Won", symbol: "₩", flag: "🇰🇷"),
        CurrencyInfo(code: "MXN", name: "Mexican Peso", symbol: "MX$", flag: "🇲🇽"),
        CurrencyInfo(code: "BRL", name: "Brazilian Real", symbol: "R$", flag: "🇧🇷"),
        CurrencyInfo(code: "TRY", name: "Turkish Lira", symbol: "₺", flag: "🇹🇷"),
        CurrencyInfo(code: "ZAR", name: "South African Rand", symbol: "R", flag: "🇿🇦"),
        CurrencyInfo(code: "HKD", name: "Hong Kong Dollar", symbol: "HK$", flag: "🇭🇰"),
        CurrencyInfo(code: "TWD", name: "Taiwan Dollar", symbol: "NT$", flag: "🇹🇼"),
    ]

    static func find(byCode code: String) -> CurrencyInfo? {
        allCurrencies.first { $0.code == code }
    }
}
