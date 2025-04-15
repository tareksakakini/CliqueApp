//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyFriendsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @State private var isAddFriendSheetPresented: Bool = false
    
    @State var user: UserModel
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "My Friends", isFriendsView: true, navigationBinder: $isAddFriendSheetPresented)
                Friendlist
            }
        }
        .sheet(isPresented: $isAddFriendSheetPresented) {
            AddFriendView(user: user)
                .presentationDetents([.fraction(0.9)])
        }
    }
}

#Preview {
    MyFriendsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyFriendsView {
    private var Friendlist: some View {
        ScrollView {
            RequestedFriendList
            AcceptedFriendList
        }
    }
    
    private var AcceptedFriendList: some View {
        ForEach(ud.friendship, id: \.self) {friend_username in
            PersonPillView(
                viewingUser: user,
                displayedUser: ud.getUser(username: friend_username),
                personType: "friend",
                invitees: .constant([])
            )
        }
    }
    
    private var RequestedFriendList: some View {
        ForEach(ud.friendInviteReceived, id: \.self) {request_username in
            PersonPillView(
                viewingUser: user,
                displayedUser: ud.getUser(username: request_username),
                personType: "requester",
                invitees: .constant([])
            )
        }
    }
}
