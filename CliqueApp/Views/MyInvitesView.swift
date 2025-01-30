//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyInvitesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    

    @State var user: UserModel
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    ForEach(ud.getInvites(username: user.userName), id: \.self) {event in
                        EventPillView(
                            event: event,
                            user: user,
                            inviteView: true
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    MyInvitesView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyInvitesView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("My Invites")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Circle()
                .frame(width: 25, height: 25)
                .foregroundColor(.white)
            
            Text(user.firstName)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
