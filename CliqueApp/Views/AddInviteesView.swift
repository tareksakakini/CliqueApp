//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddInviteesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @State private var searchEntry: String = ""
    @State var user: UserModel
    
    @Binding var invitees: [String]
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                
                header
                
                TextField("Search for friends ...", text: $searchEntry)
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
                        AddInviteePillView(userToAdd: user_returned, invitees: $invitees)
                    }
                    
                }
                
                Spacer()
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
        }
        .padding()
    }
}
