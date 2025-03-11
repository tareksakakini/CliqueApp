//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyFriendsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @State private var isSheetPresented: Bool = false

    @State var user: UserModel
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    
                    ForEach(ud.friendInviteReceived, id: \.self) {request_username in
                        PersonPillView(
                            viewing_user: user,
                            displayed_user: ud.getUser(username: request_username),
                            personType: "requester",
                            invitees: .constant([])
                        )
                    }
                    
                    ForEach(ud.friendship, id: \.self) {friend_username in
                        PersonPillView(
                            viewing_user: user,
                            displayed_user: ud.getUser(username: friend_username),
                            personType: "friend",
                            invitees: .constant([])
                        )
                    }
                }
            }
        }
        .onAppear {
            Task {
                await ud.getAllUsers()
            }
            Task {
                await ud.getUserFriends(user_email: user.email)
            }
            Task {
                await ud.getUserFriendRequests(user_email: user.email)
            }
            Task {
                await ud.getUserFriendRequestsSent(user_email: user.email)
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
            
            Button {
                isSheetPresented = true
            } label: {
                Image(systemName: "person.fill.badge.plus")
                    .resizable()
                    .scaledToFill()
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: 2)
            }
            .sheet(isPresented: $isSheetPresented) {
                AddFriendView(user: user)
                    .presentationDetents([.fraction(0.9)])
            }

        }
        .padding()
    }
}
