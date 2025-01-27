//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyFriendsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    

    @State var user: UserModel
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    ForEach(ud.getFriends(username: user.userName), id: \.self) {friend_username in
                        FriendPillView(
                            user: ud.getUser(username: friend_username)
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    MyFriendsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyFriendsView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("My Friends")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Circle()
                .frame(width: 25, height: 25)
                .foregroundColor(.white)
            
            Text(user.firstName)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
