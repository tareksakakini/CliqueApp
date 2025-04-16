//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyFriendsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State private var isAddFriendSheetPresented: Bool = false
    
    @State var user: UserModel
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "My Friends", navigationBinder: $isAddFriendSheetPresented, specialScreen: "MyFriendsView")
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
            if vm.friendship.count + vm.friendInviteReceived.count == 0 {
                Text("Pull down to refresh")
                    .foregroundColor(Color(.accent))
            }
            RequestedFriendList
            AcceptedFriendList
        }
        .refreshable {
            await vm.getUserFriends(user_email: user.email)
            await vm.getUserFriendRequests(user_email: user.email)
            await vm.getUserFriendRequestsSent(user_email: user.email)
        }
    }
    
    private var AcceptedFriendList: some View {
        ForEach(vm.friendship, id: \.self) {friend_username in
            PersonPillView(
                viewingUser: user,
                displayedUser: vm.getUser(username: friend_username),
                personType: "friend",
                invitees: .constant([])
            )
        }
    }
    
    private var RequestedFriendList: some View {
        ForEach(vm.friendInviteReceived, id: \.self) {request_username in
            PersonPillView(
                viewingUser: user,
                displayedUser: vm.getUser(username: request_username),
                personType: "requester",
                invitees: .constant([])
            )
        }
    }
}
