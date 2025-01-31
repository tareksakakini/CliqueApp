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
                
                ScrollView {
                    
                    ForEach(ud.stringMatchUsers(query: searchEntry), id: \.userName)
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
    AddInviteesView(invitees: .constant([]))
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
