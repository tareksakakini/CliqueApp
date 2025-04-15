//
//  HeaderView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/20/25.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let user: UserModel
    let title: String
    @Binding var navigationBinder: Bool
    var specialScreen: String = ""
    var body: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            if specialScreen == "MyFriendsView" {
                Button {
                    navigationBinder = true
                } label: {
                    Image(systemName: "person.fill.badge.plus")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 2)
                }
            } else if specialScreen == "AddFriendView" {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .font(.caption)
                        .frame(width: 20, height: 20)
                        .padding()
                }
            } else {
                ProfilePictureView(user: user, diameter: 50, isPhone: false)
                
                Text(user.fullname.components(separatedBy: " ").first ?? "")
                    .foregroundColor(.white)
                    .font(.headline)
                    .bold()
            }
        }
        .padding()
    }
}

#Preview {
    HeaderView(user: UserData.userData[0], title: "Title", navigationBinder: .constant(false))
        .environmentObject(ViewModel())
}
