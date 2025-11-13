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
    
    /// Canonical representation (used across Firestore) with US numbers trimmed to 10 digits.
    static func canonical(_ input: String) -> String {
        var digits = digitsOnly(from: input)
        
        if digits.count == 11, digits.hasPrefix(defaultCountryCode) {
            digits = String(digits.dropFirst())
        }
        
        return digits
    }

    /// Returns an E.164 formatted number (e.g. +12175551212) for Firebase SMS APIs.
    static func e164(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("+") {
            let normalized = "+" + trimmed.dropFirst().filter { $0.isNumber }
            return normalized
        }
        
        let digits = digitsOnly(from: trimmed)
        if digits.isEmpty {
            return ""
        }
        
        if digits.count == 10 {
            return "+\(defaultCountryCode)\(digits)"
        }
        
        if digits.count == 11, digits.hasPrefix(defaultCountryCode) {
            return "+\(digits)"
        }
        
        return "+\(digits)"
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
