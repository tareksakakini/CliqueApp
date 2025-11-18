//
//  Country.swift
//  CliqueApp
//
//  Model for country information including dial codes
//

import Foundation

struct Country: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let dialCode: String
    let code: String // ISO 3166-1 alpha-2 code
    let flag: String
    
    /// Removes formatting characters so we can compare dial codes reliably.
    var sanitizedDialCode: String {
        let digits = dialCode.filter { $0.isNumber }
        guard !digits.isEmpty else { return dialCode }
        return "+\(digits)"
    }
    
    static let allCountries: [Country] = [
        Country(name: "Afghanistan", dialCode: "+93", code: "AF", flag: "🇦🇫"),
        Country(name: "Albania", dialCode: "+355", code: "AL", flag: "🇦🇱"),
        Country(name: "Algeria", dialCode: "+213", code: "DZ", flag: "🇩🇿"),
        Country(name: "Andorra", dialCode: "+376", code: "AD", flag: "🇦🇩"),
        Country(name: "Angola", dialCode: "+244", code: "AO", flag: "🇦🇴"),
        Country(name: "Argentina", dialCode: "+54", code: "AR", flag: "🇦🇷"),
        Country(name: "Australia", dialCode: "+61", code: "AU", flag: "🇦🇺"),
        Country(name: "Austria", dialCode: "+43", code: "AT", flag: "🇦🇹"),
        Country(name: "Bahrain", dialCode: "+973", code: "BH", flag: "🇧🇭"),
        Country(name: "Bangladesh", dialCode: "+880", code: "BD", flag: "🇧🇩"),
        Country(name: "Belgium", dialCode: "+32", code: "BE", flag: "🇧🇪"),
        Country(name: "Bolivia", dialCode: "+591", code: "BO", flag: "🇧🇴"),
        Country(name: "Brazil", dialCode: "+55", code: "BR", flag: "🇧🇷"),
        Country(name: "Canada", dialCode: "+1", code: "CA", flag: "🇨🇦"),
        Country(name: "Chile", dialCode: "+56", code: "CL", flag: "🇨🇱"),
        Country(name: "China", dialCode: "+86", code: "CN", flag: "🇨🇳"),
        Country(name: "Colombia", dialCode: "+57", code: "CO", flag: "🇨🇴"),
        Country(name: "Costa Rica", dialCode: "+506", code: "CR", flag: "🇨🇷"),
        Country(name: "Croatia", dialCode: "+385", code: "HR", flag: "🇭🇷"),
        Country(name: "Cuba", dialCode: "+53", code: "CU", flag: "🇨🇺"),
        Country(name: "Cyprus", dialCode: "+357", code: "CY", flag: "🇨🇾"),
        Country(name: "Czech Republic", dialCode: "+420", code: "CZ", flag: "🇨🇿"),
        Country(name: "Denmark", dialCode: "+45", code: "DK", flag: "🇩🇰"),
        Country(name: "Dominican Republic", dialCode: "+1-809", code: "DO", flag: "🇩🇴"),
        Country(name: "Ecuador", dialCode: "+593", code: "EC", flag: "🇪🇨"),
        Country(name: "Egypt", dialCode: "+20", code: "EG", flag: "🇪🇬"),
        Country(name: "Estonia", dialCode: "+372", code: "EE", flag: "🇪🇪"),
        Country(name: "Finland", dialCode: "+358", code: "FI", flag: "🇫🇮"),
        Country(name: "France", dialCode: "+33", code: "FR", flag: "🇫🇷"),
        Country(name: "Germany", dialCode: "+49", code: "DE", flag: "🇩🇪"),
        Country(name: "Greece", dialCode: "+30", code: "GR", flag: "🇬🇷"),
        Country(name: "Hong Kong", dialCode: "+852", code: "HK", flag: "🇭🇰"),
        Country(name: "Hungary", dialCode: "+36", code: "HU", flag: "🇭🇺"),
        Country(name: "Iceland", dialCode: "+354", code: "IS", flag: "🇮🇸"),
        Country(name: "India", dialCode: "+91", code: "IN", flag: "🇮🇳"),
        Country(name: "Indonesia", dialCode: "+62", code: "ID", flag: "🇮🇩"),
        Country(name: "Iran", dialCode: "+98", code: "IR", flag: "🇮🇷"),
        Country(name: "Iraq", dialCode: "+964", code: "IQ", flag: "🇮🇶"),
        Country(name: "Ireland", dialCode: "+353", code: "IE", flag: "🇮🇪"),
        Country(name: "Italy", dialCode: "+39", code: "IT", flag: "🇮🇹"),
        Country(name: "Japan", dialCode: "+81", code: "JP", flag: "🇯🇵"),
        Country(name: "Jordan", dialCode: "+962", code: "JO", flag: "🇯🇴"),
        Country(name: "Kenya", dialCode: "+254", code: "KE", flag: "🇰🇪"),
        Country(name: "Kuwait", dialCode: "+965", code: "KW", flag: "🇰🇼"),
        Country(name: "Latvia", dialCode: "+371", code: "LV", flag: "🇱🇻"),
        Country(name: "Lebanon", dialCode: "+961", code: "LB", flag: "🇱🇧"),
        Country(name: "Lithuania", dialCode: "+370", code: "LT", flag: "🇱🇹"),
        Country(name: "Luxembourg", dialCode: "+352", code: "LU", flag: "🇱🇺"),
        Country(name: "Malaysia", dialCode: "+60", code: "MY", flag: "🇲🇾"),
        Country(name: "Mexico", dialCode: "+52", code: "MX", flag: "🇲🇽"),
        Country(name: "Morocco", dialCode: "+212", code: "MA", flag: "🇲🇦"),
        Country(name: "Netherlands", dialCode: "+31", code: "NL", flag: "🇳🇱"),
        Country(name: "New Zealand", dialCode: "+64", code: "NZ", flag: "🇳🇿"),
        Country(name: "Nigeria", dialCode: "+234", code: "NG", flag: "🇳🇬"),
        Country(name: "Norway", dialCode: "+47", code: "NO", flag: "🇳🇴"),
        Country(name: "Oman", dialCode: "+968", code: "OM", flag: "🇴🇲"),
        Country(name: "Pakistan", dialCode: "+92", code: "PK", flag: "🇵🇰"),
        Country(name: "Palestine", dialCode: "+970", code: "PS", flag: "🇵🇸"),
        Country(name: "Panama", dialCode: "+507", code: "PA", flag: "🇵🇦"),
        Country(name: "Peru", dialCode: "+51", code: "PE", flag: "🇵🇪"),
        Country(name: "Philippines", dialCode: "+63", code: "PH", flag: "🇵🇭"),
        Country(name: "Poland", dialCode: "+48", code: "PL", flag: "🇵🇱"),
        Country(name: "Portugal", dialCode: "+351", code: "PT", flag: "🇵🇹"),
        Country(name: "Qatar", dialCode: "+974", code: "QA", flag: "🇶🇦"),
        Country(name: "Romania", dialCode: "+40", code: "RO", flag: "🇷🇴"),
        Country(name: "Russia", dialCode: "+7", code: "RU", flag: "🇷🇺"),
        Country(name: "Saudi Arabia", dialCode: "+966", code: "SA", flag: "🇸🇦"),
        Country(name: "Singapore", dialCode: "+65", code: "SG", flag: "🇸🇬"),
        Country(name: "Slovakia", dialCode: "+421", code: "SK", flag: "🇸🇰"),
        Country(name: "Slovenia", dialCode: "+386", code: "SI", flag: "🇸🇮"),
        Country(name: "South Africa", dialCode: "+27", code: "ZA", flag: "🇿🇦"),
        Country(name: "South Korea", dialCode: "+82", code: "KR", flag: "🇰🇷"),
        Country(name: "Spain", dialCode: "+34", code: "ES", flag: "🇪🇸"),
        Country(name: "Sri Lanka", dialCode: "+94", code: "LK", flag: "🇱🇰"),
        Country(name: "Sweden", dialCode: "+46", code: "SE", flag: "🇸🇪"),
        Country(name: "Switzerland", dialCode: "+41", code: "CH", flag: "🇨🇭"),
        Country(name: "Syria", dialCode: "+963", code: "SY", flag: "🇸🇾"),
        Country(name: "Taiwan", dialCode: "+886", code: "TW", flag: "🇹🇼"),
        Country(name: "Thailand", dialCode: "+66", code: "TH", flag: "🇹🇭"),
        Country(name: "Tunisia", dialCode: "+216", code: "TN", flag: "🇹🇳"),
        Country(name: "Turkey", dialCode: "+90", code: "TR", flag: "🇹🇷"),
        Country(name: "Ukraine", dialCode: "+380", code: "UA", flag: "🇺🇦"),
        Country(name: "United Arab Emirates", dialCode: "+971", code: "AE", flag: "🇦🇪"),
        Country(name: "United Kingdom", dialCode: "+44", code: "GB", flag: "🇬🇧"),
        Country(name: "United States", dialCode: "+1", code: "US", flag: "🇺🇸"),
        Country(name: "Uruguay", dialCode: "+598", code: "UY", flag: "🇺🇾"),
        Country(name: "Venezuela", dialCode: "+58", code: "VE", flag: "🇻🇪"),
        Country(name: "Vietnam", dialCode: "+84", code: "VN", flag: "🇻🇳"),
        Country(name: "Yemen", dialCode: "+967", code: "YE", flag: "🇾🇪"),
    ]
    
    // Default country (United States)
    static let `default` = Country(name: "United States", dialCode: "+1", code: "US", flag: "🇺🇸")
    
    // Get country by dial code
    static func byDialCode(_ dialCode: String) -> Country? {
        allCountries.first { $0.dialCode == dialCode }
    }
    
    // Get country by code
    static func byCode(_ code: String) -> Country? {
        allCountries.first { $0.code == code }
    }
}

extension Country {
    /// Countries sorted by dial code length descending for prefix matching.
    private static let dialCodeLookup: [Country] = {
        allCountries.sorted { $0.sanitizedDialCode.count > $1.sanitizedDialCode.count }
    }()
    
    /// Attempts to match an E.164 number to a known country.
    static func matchCountry(forE164 number: String) -> Country? {
        let sanitized = sanitize(e164: number)
        guard sanitized.hasPrefix("+") else { return nil }
        return dialCodeLookup.first { sanitized.hasPrefix($0.sanitizedDialCode) }
    }
    
    /// Returns `sanitized` E.164 string with digits only.
    private static func sanitize(e164: String) -> String {
        let filtered = e164.filter { $0 == "+" || $0.isNumber }
        if filtered.first == "+" {
            return "+\(filtered.dropFirst().filter { $0.isNumber })"
        }
        return "+\(filtered.filter { $0.isNumber })"
    }
}
