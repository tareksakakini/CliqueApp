//
//  PhoneNumberFieldWithCountryCode.swift
//  CliqueApp
//
//  A reusable phone number input field with country code picker
//

import SwiftUI

struct PhoneNumberFieldWithCountryCode: View {
    let title: String
    @Binding var phoneNumber: String
    @Binding var selectedCountry: Country
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                // Country Code Dropdown
                Menu {
                    ForEach(Country.allCountries) { country in
                        Button {
                            // Clear the phone number when changing countries to avoid formatting issues
                            let digitsOnly = phoneNumber.filter { $0.isNumber }
                            selectedCountry = country
                            // Apply new country formatting to digits only
                            phoneNumber = formatPhoneNumber(digitsOnly, for: country)
                        } label: {
                            Text("\(country.name) (\(country.dialCode))")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(selectedCountry.dialCode)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    )
                }
                
                // Phone Number Input
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField(placeholder, text: $phoneNumber)
                        .font(.system(size: 16, weight: .medium))
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { oldValue, newValue in
                            // Only apply formatting if user is adding characters, not deleting
                            let oldDigits = oldValue.filter { $0.isNumber }
                            let newDigits = newValue.filter { $0.isNumber }
                            
                            // If user is deleting, just remove the formatting characters but keep the digits
                            if newDigits.count < oldDigits.count {
                                // User is deleting
                                phoneNumber = formatPhoneNumber(newDigits, for: selectedCountry)
                            } else if newDigits.count > oldDigits.count {
                                // User is adding
                                phoneNumber = formatPhoneNumber(newDigits, for: selectedCountry)
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
        }
    }
    
    // Helper to get the full phone number with country code
    func getFullPhoneNumber() -> String {
        let digits = phoneNumber.filter { $0.isNumber }
        if digits.isEmpty {
            return ""
        }
        // Remove any leading zeros
        let trimmedDigits = digits.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        return "\(selectedCountry.dialCode)\(trimmedDigits)"
    }
    
    // Format phone number based on country
    private func formatPhoneNumber(_ number: String, for country: Country) -> String {
        let digits = number.filter { $0.isNumber }
        if digits.isEmpty { return "" }
        
        // Only format US and Canada numbers: (###) ###-####
        if country.code == "US" || country.code == "CA" {
            var formatted = ""
            for (index, character) in digits.enumerated() {
                if index == 0 {
                    formatted.append("(")
                }
                formatted.append(character)
                
                if index == 2 {
                    formatted.append(") ")
                } else if index == 5 {
                    formatted.append("-")
                } else if index == 9 {
                    break // Max 10 digits
                }
            }
            return formatted
        }
        
        // All other countries: just return the digits as-is
        return digits
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var phoneNumber = ""
        @State private var selectedCountry = Country.default
        
        var body: some View {
            VStack {
                PhoneNumberFieldWithCountryCode(
                    title: "Phone Number",
                    phoneNumber: $phoneNumber,
                    selectedCountry: $selectedCountry,
                    placeholder: "Enter your mobile number"
                )
                .padding()
                
                Text("Full number: \((selectedCountry.dialCode + phoneNumber))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    return PreviewWrapper()
}

