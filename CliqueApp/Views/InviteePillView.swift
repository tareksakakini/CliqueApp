//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct InviteePillView: View {
    @EnvironmentObject private var ud: ViewModel
    
    let user: UserModel?
    @Binding var invitees: [String]
    var body: some View {
        HStack {
            
            Circle()
                .frame(width: 40, height: 40)
                .padding(.horizontal)
            
            if let currentUser = user {
                Text("\(currentUser.fullname)")
                    .foregroundColor(Color(.accent))
                    .font(.title3)
                    .bold()
            }
            
            
            
            
            Spacer()
            
            Button {
                if let user = user {
                    invitees.removeAll { $0 == user.email }
                }
                
            } label: {
                Image(systemName: "minus.circle")
                    .padding()
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
        Color(.accent).ignoresSafeArea()
        InviteePillView(
            user: UserData.userData[0],
            invitees: .constant([])
        )
    }
    
}
