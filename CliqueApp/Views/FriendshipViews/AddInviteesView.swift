//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddInviteesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchEntry: String = ""
    @State var user: UserModel
    
    @Binding var invitees: [UserModel]
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header
                
                TextField("", text: $searchEntry, prompt: Text("Search for friends to invite ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.black)
                
                ScrollView {
                    
                    ForEach(ud.stringMatchUsers(query: searchEntry, viewingUser: user, isFriend: true), id: \.email)
                    {user_returned in
                        if invitees.contains(user_returned) {
                            PersonPillView(
                                viewing_user: user,
                                displayed_user: user_returned,
                                personType: "requestedInvitee",
                                invitees: $invitees
                            )
                        } else {
                            PersonPillView(
                                viewing_user: user,
                                displayed_user: user_returned,
                                personType: "invitee",
                                invitees: $invitees
                            )
                        }
                    }
                    
                }
                
                Spacer()
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
        }
    }
}

#Preview {
    AddInviteesView(user: UserData.userData[0], invitees: .constant([]))
        .environmentObject(ViewModel())
}

extension AddInviteesView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("Add Invitees")
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
