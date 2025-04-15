//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddFriendView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    
    @State private var searchEntry: String = ""
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "Add Friend", navigationBinder: .constant(false), specialScreen: "AddFriendView")
                SearchField
                Results
                Spacer()
            }
        }
    }
}

#Preview {
    AddFriendView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension AddFriendView {
    private var SearchField: some View {
        TextField("", text: $searchEntry, prompt: Text("Search for friends ...").foregroundColor(Color.black.opacity(0.5)))
            .foregroundColor(.black)
            .padding()
            .background(.white)
            .cornerRadius(10)
            .padding()
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
    }
    
    private var Results: some View {
        ScrollView {
            
            ForEach(ud.stringMatchUsers(query: searchEntry, viewingUser: user), id: \.email)
            {user_returned in
                if ud.friendInviteSent.contains(user_returned.email) {
                    PersonPillView(
                        viewingUser: user,
                        displayedUser: user_returned,
                        personType: "requestedFriend",
                        invitees: .constant([])
                    )
                } else if user.email != user_returned.email && !ud.friendship.contains(user_returned.email) {
                    PersonPillView(
                        viewingUser: user,
                        displayedUser: user_returned,
                        personType: "stranger",
                        invitees: .constant([])
                    )
                }
            }
        }
    }
}
