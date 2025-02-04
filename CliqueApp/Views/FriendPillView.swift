//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct FriendPillView: View {
    @EnvironmentObject private var ud: ViewModel
    
    let viewing_user: UserModel?
    let user: UserModel?
    var body: some View {
        HStack {
            
            Circle()
                .frame(width: 40, height: 40)
                .padding(.horizontal)
            
            if let currentUser = user {
                Text("\(currentUser.fullname)")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                    .bold()
            }
            
            
            
            
            Spacer()
            
            Button {
                if let user = user {
                    if let viewing_user = viewing_user {
                        ud.removeFriendship(username1: user.userName, username2: viewing_user.userName)
                    }
                }
                
            } label: {
                Image(systemName: "minus.circle")
                    .padding()
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
        
    }
}


#Preview {
    ZStack {
        Color.accentColor.ignoresSafeArea()
        FriendPillView(
            viewing_user: UserData.userData[0], user: UserData.userData[0]
        )
    }
    
}
