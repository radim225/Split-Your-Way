import SwiftUI

// MARK: - Decimal Extensions

extension Decimal {
    var toMinorUnits: Int64 {
        NSDecimalNumber(decimal: self * 100).int64Value
    }

    static func fromMinorUnits(_ value: Int64) -> Decimal {
        Decimal(value) / 100
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

// MARK: - Date Extensions

extension Date {
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var mediumFormatted: String {
        formatted(date: .long, time: .shortened)
    }

    var monthYearFormatted: String {
        formatted(.dateTime.month(.wide).year())
    }
}

// MARK: - Color from Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - View Extensions

extension View {
    func successHaptic() -> some View {
        self.sensoryFeedback(.success, trigger: true)
    }
}

// MARK: - Avatar Colors

enum AvatarColors {
    static let all: [String] = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
        "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F",
        "#BB8FCE", "#85C1E9", "#F0B27A", "#82E0AA",
    ]

    static func random() -> String {
        all.randomElement() ?? "#007AFF"
    }
}
