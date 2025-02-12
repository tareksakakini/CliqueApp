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
            
            if let currentUser = userToAdd {
                
                Image(currentUser.profilePic)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 50)
                    .padding(.leading)
                
                
                VStack(alignment: .leading) {
                    Text("\(currentUser.fullname)")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                        .bold()
                    
                    Text("@\(currentUser.email)")
                        .foregroundColor(Color(#colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)))
                        .font(.caption)
                        .bold()
                }
                .padding(.leading, 5)
                
            }
            
            Spacer()
            
            Button {
                if let userToAdd = userToAdd {
                    invitees += [userToAdd.email]
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
