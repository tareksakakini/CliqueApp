//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddFriendView: View {
    
    @EnvironmentObject private var ud: ViewModel
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
                        if user.email != user_returned.email && !ud.friendship.contains(user_returned.email) {
                            PersonPillView(
                                viewing_user: user,
                                displayed_user: user_returned,
                                personType: "stranger",
                                invitees: .constant([])
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
        }
        .padding()
    }
}
