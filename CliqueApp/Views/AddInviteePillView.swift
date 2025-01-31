//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct AddInviteePillView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let userToAdd: UserModel?
    @Binding var invitees: [String]
    var body: some View {
        HStack {
            
            Circle()
                .frame(width: 40, height: 40)
                .padding(.horizontal)
            
            if let currentUser = userToAdd {
                Text("\(currentUser.firstName) \(currentUser.lastName)")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                    .bold()
            }
            
            Spacer()
            
            Button {
                if let userToAdd = userToAdd {
                    invitees += [userToAdd.userName]
                    dismiss()
                }
                
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.accentColor)
                    .font(.caption)
                    .frame(width: 25, height: 25)
                    .padding()
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
        
    }
}


#Preview {
    ZStack {
        Color.accentColor.ignoresSafeArea()
        AddInviteePillView(
            userToAdd: UserData.userData[1],
            invitees: .constant([])
        )
        .environmentObject(ViewModel())
    }
    
}
