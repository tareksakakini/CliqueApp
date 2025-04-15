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
    
    @State private var isSheetPresented: Bool = false
    @State private var searchEntry: String = ""
    
    @State var user: UserModel
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header
                
                TextField("", text: $searchEntry, prompt: Text("Search for friends ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
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
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("Add Friends")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
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
        }
        .padding()
    }
}
