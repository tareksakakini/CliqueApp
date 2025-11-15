//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation
import FirebaseCore

typealias UserID = String

struct UserModel: Hashable, Identifiable {
    var id: String { uid }
    var uid: UserID = ""
    var fullname: String = ""
    var username: String = ""
    var email: String = ""
    var createdAt: Date = Date()
    var profilePic: String = ""
    var gender: String = ""
    var phoneNumber: String = ""
    
    /// Returns the UID if available, otherwise falls back to the legacy email/contact handle.
    var stableIdentifier: String {
        uid.isEmpty ? email : uid
    }
    
    /// Returns all known identifiers that might appear in legacy documents.
    var identifierCandidates: [String] {
        var identifiers: [String] = []
        if !uid.isEmpty {
            identifiers.append(uid)
        }
        if !email.isEmpty {
            identifiers.append(email)
        }
        return identifiers
    }
    
    /// Checks if the provided identifier matches this user (by UID or legacy email).
    func matchesIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        if !uid.isEmpty, identifier == uid {
            return true
        }
        if !email.isEmpty, identifier == email {
            return true
        }
        return false
    }
    
    /// Returns the phone number normalized to E.164 (+<countrycode><number>).
    var phoneNumberE164: String {
        let normalized = PhoneNumberFormatter.e164(phoneNumber)
        return normalized.isEmpty ? phoneNumber : normalized
    }
    
    func initFromFirestore(userData: [String: Any]) -> UserModel {
        var user = UserModel()
        user.uid = userData["uid"] as? String
            ?? userData["id"] as? String
            ?? ""
        user.fullname = userData["fullname"] as? String ?? ""
        user.username = userData["username"] as? String ?? ""
        user.email = userData["email"] as? String ?? ""
        user.createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        user.profilePic = userData["profilePic"] as? String ?? ""
        user.gender = userData["gender"] as? String ?? ""
        
        let rawPhone = userData["phoneNumber"] as? String ?? ""
        let normalizedPhone = PhoneNumberFormatter.e164(rawPhone)
        user.phoneNumber = normalizedPhone.isEmpty ? rawPhone : normalizedPhone
        return user
    }
}
