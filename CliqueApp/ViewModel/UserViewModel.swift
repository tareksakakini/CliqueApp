//
//  UserViewModel.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/23/25.
//

import Foundation

class UserViewModel: ObservableObject {
    let users: [UserModel]
    
    init() {
        self.users = UserData.userData
    }
    
    func isUserPresent(username: String, password: String) -> Bool {
        var userPresent = false
        for user in self.users {
            if user.userName == username && user.password == password {
                userPresent = true
            }
        }
        return userPresent
    }
}
