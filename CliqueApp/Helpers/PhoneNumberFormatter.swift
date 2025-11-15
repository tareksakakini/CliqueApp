//
//  PhoneNumberFormatter.swift
//  CliqueApp
//
//  Centralized helpers for normalizing and comparing phone numbers plus
//  generating deterministic pseudo emails used for Firebase Auth.
//

import Foundation

struct PhoneNumberFormatter {
    /// Default country code (US) used when users omit a prefix.
    private static let defaultCountryCode = "1"
    
    /// Removes everything except digits.
    static func digitsOnly(from input: String) -> String {
        String(input.filter { $0.isNumber })
    }
    
    /// Canonical representation (used across Firestore)
    /// For US numbers (10-11 digits), trims to 10 digits
    /// For international numbers, keeps full number with country code
    static func canonical(_ input: String) -> String {
        var digits = digitsOnly(from: input)
        
        // Handle US numbers specifically
        if digits.count == 11, digits.hasPrefix(defaultCountryCode) {
            digits = String(digits.dropFirst())
        }
        
        return digits
    }

    /// Returns an E.164 formatted number (e.g. +12175551212) for Firebase SMS APIs.
    /// Handles international numbers by preserving the + prefix if present.
    static func e164(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If already has +, just clean it up
        if trimmed.hasPrefix("+") {
            let normalized = "+" + trimmed.dropFirst().filter { $0.isNumber }
            return normalized
        }
        
        let digits = digitsOnly(from: trimmed)
        if digits.isEmpty {
            return ""
        }
        
        // If it's a 10-digit number, assume US
        if digits.count == 10 {
            return "+\(defaultCountryCode)\(digits)"
        }
        
        // If it's 11 digits starting with 1, it's US/Canada
        if digits.count == 11, digits.hasPrefix(defaultCountryCode) {
            return "+\(digits)"
        }
        
        // For any other number, assume it already includes country code
        return "+\(digits)"
    }
    
    /// Builds E.164 format from separate country code and phone number
    static func e164(countryCode: String, phoneNumber: String) -> String {
        let cleanCountryCode = countryCode.filter { $0.isNumber }
        let cleanNumber = phoneNumber.filter { $0.isNumber }
        
        if cleanNumber.isEmpty {
            return ""
        }
        
        // Remove leading zeros from phone number
        let trimmedNumber = cleanNumber.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        
        return "+\(cleanCountryCode)\(trimmedNumber)"
    }
    
    /// Generates a deterministic pseudo email for Firebase Auth's email/password provider.
    static func pseudoEmail(for input: String) -> String {
        let canonicalNumber = canonical(input)
        return "\(canonicalNumber)@cliqueapp.phone"
    }
    
    /// Determines if two phone numbers represent the same value.
    static func numbersMatch(_ lhs: String, _ rhs: String) -> Bool {
        let normalizedLhs = canonical(lhs)
        let normalizedRhs = canonical(rhs)
        
        if !normalizedLhs.isEmpty, normalizedLhs == normalizedRhs {
            return true
        }
        
        if normalizedLhs.count != normalizedRhs.count {
            let longer = normalizedLhs.count > normalizedRhs.count ? normalizedLhs : normalizedRhs
            let shorter = normalizedLhs.count > normalizedRhs.count ? normalizedRhs : normalizedLhs
            
            if !shorter.isEmpty, longer.hasSuffix(shorter) {
                return true
            }
        }
        
        return false
    }
}
