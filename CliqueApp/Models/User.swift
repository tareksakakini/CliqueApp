//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation
import FirebaseCore

struct UserModel: Hashable, Identifiable {
    var id: String { uid }
    var uid: String = ""
    var fullname: String = ""
    var username: String = ""
    var email: String = ""
    var createdAt: Date = Date()
    var profilePic: String = ""
    var subscriptionId: String = ""
    var gender: String = ""
    var isEmailVerified: Bool = false
    
    func initFromFirestore(userData: [String: Any]) -> UserModel {
        var user = UserModel()
        user.uid = userData["uid"] as? String ?? ""
        user.fullname = userData["fullname"] as? String ?? ""
        user.username = userData["username"] as? String ?? ""
        user.email = userData["email"] as? String ?? ""
        user.createdAt = (userData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        user.profilePic = userData["profilePic"] as? String ?? ""
        user.subscriptionId = userData["subscriptionId"] as? String ?? ""
        user.gender = userData["gender"] as? String ?? ""
        user.isEmailVerified = userData["isEmailVerified"] as? Bool ?? false
        return user
    }
}
