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
    /// App-specific immutable user identifier used everywhere in Firestore.
    var uid: UserID = ""
    /// Firebase Auth user identifier used for authentication lookups.
    var authUID: String = ""
    var fullname: String = ""
    var username: String = ""
    var createdAt: Date = Date()
    var profilePic: String = ""
    var gender: String = ""
    var phoneNumber: String = ""
    
    /// Returns the identifier that other entities should use.
    var stableIdentifier: String {
        uid
    }
    
    /// Returns all known identifiers for this user.
    var identifierCandidates: [String] {
        var identifiers: [String] = []
        if !uid.isEmpty {
            identifiers.append(uid)
        }
        if !authUID.isEmpty {
            identifiers.append(authUID)
        }
        return identifiers
    }
    
    /// Determines if the given identifier corresponds to this user.
    func matchesIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        return identifier == uid || identifier == authUID
    }
    
    /// Returns the phone number normalized to E.164 (+<countrycode><number>).
    var phoneNumberE164: String {
        let normalized = PhoneNumberFormatter.e164(phoneNumber)
        return normalized.isEmpty ? phoneNumber : normalized
    }
    
    func initFromFirestore(userData: [String: Any]) -> UserModel {
        var user = UserModel()
        user.uid = userData["uid"] as? String
            ?? userData["userId"] as? String
            ?? ""
        user.authUID = userData["authUID"] as? String ?? ""
        user.fullname = userData["fullname"] as? String ?? ""
        user.username = userData["username"] as? String ?? ""
        user.createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        user.profilePic = userData["profilePic"] as? String ?? ""
        user.gender = userData["gender"] as? String ?? ""
        
        let rawPhone = userData["phoneNumber"] as? String ?? ""
        let normalizedPhone = PhoneNumberFormatter.e164(rawPhone)
        user.phoneNumber = normalizedPhone.isEmpty ? rawPhone : normalizedPhone
        return user
    }
}
