//
//  User.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

struct UserModel {
    var uid: String = ""
    var fullname: String
    var email: String
    var createdAt: Date = Date()
    var profilePic: String = "userDefault"
}
