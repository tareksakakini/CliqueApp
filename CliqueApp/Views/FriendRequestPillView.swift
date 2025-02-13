//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct FriendRequestPillView: View {
    @EnvironmentObject private var ud: ViewModel
    
    let viewing_user: UserModel?
    let user: UserModel?
    var body: some View {
        HStack {
            
            if let currentUser = user {
                
                Image(currentUser.profilePic)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 50)
                    .padding(.leading)
                
                VStack(alignment: .leading) {
                    Text("\(currentUser.fullname)")
                        .foregroundColor(Color(.accent))
                        .font(.title3)
                        .bold()
                    
                    Text("@\(currentUser.email)")
                        .foregroundColor(Color(#colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)))
                        .font(.caption)
                        .bold()
                }
                .padding(.leading, 5)
                
            }
            
            
            
            
            Spacer()
            
            Button {
                if let user = user {
                    if let viewing_user = viewing_user {
                        ud.acceptFriendshipRequest(sender: user.email, receiver: viewing_user.email)
                    }
                }
                
            } label: {
                Text("Accept")
            }
            .bold()
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.green.opacity(0.6))
            .cornerRadius(10)
            .padding()

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
        Color(.accent).ignoresSafeArea()
        FriendRequestPillView(
            viewing_user: UserData.userData[0], user: UserData.userData[0]
        )
    }
    
}
