import Foundation

@Observable
final class CurrencyService {
    private(set) var rates: [String: Double] = [:]
    private(set) var lastUpdated: Date?
    private(set) var isLoading = false
    private(set) var error: String?

    private let cacheTTL: TimeInterval = 3600 // 1 hour

    private var apiKey: String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["ExchangeRateAPIKey"] as? String
        else { return nil }
        return key
    }

    func fetchRates(base: String) async {
        // Check cache first
        let cacheKey = "currency_rates_\(base)"
        let timestampKey = "currency_rates_timestamp_\(base)"

        if let cached = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
           let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date,
           Date().timeIntervalSince(timestamp) < cacheTTL
        {
            rates = cached
            lastUpdated = timestamp
            return
        }

        guard let apiKey else {
            error = "No API key found"
            return
        }

        isLoading = true
        error = nil

        do {
            // fxratesapi.com API
            let urlString = "https://api.fxratesapi.com/latest?base=\(base)&api_key=\(apiKey)"
            let url = URL(string: urlString)!
            let (data, _) = try await URLSession.shared.data(from: url)

            let response = try JSONDecoder().decode(FxRatesResponse.self, from: data)
            guard response.success else {
                self.error = "API returned unsuccessful response"
                isLoading = false
                return
            }
            rates = response.rates
            lastUpdated = Date()

            // Cache
            UserDefaults.standard.set(rates, forKey: cacheKey)
            UserDefaults.standard.set(lastUpdated, forKey: timestampKey)
        } catch {
            self.error = error.localizedDescription
            // Fall back to cache even if stale
            if let cached = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double] {
                rates = cached
                lastUpdated = UserDefaults.standard.object(forKey: timestampKey) as? Date
            }
        }

        isLoading = false
    }

    func convert(amount: Int64, from: String, to: String) -> Int64 {
        guard from != to else { return amount }
        guard let fromRate = rates[from], let toRate = rates[to], fromRate > 0 else { return amount }
        let converted = Double(amount) * toRate / fromRate
        return Int64(converted.rounded())
    }

    func rate(from: String, to: String) -> Double? {
        guard let fromRate = rates[from], let toRate = rates[to], fromRate > 0 else { return nil }
        return toRate / fromRate
    }
}

private struct FxRatesResponse: Decodable {
    let success: Bool
    let base: String?
    let rates: [String: Double]
}
