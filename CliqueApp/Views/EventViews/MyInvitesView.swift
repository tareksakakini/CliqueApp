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
    @State var refreshTrigger: Bool = false
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                HeaderView(user: user, title: "My Invites")
                
                ScrollView {
                    ForEach(ud.events, id: \.self) {event in
                        if event.attendeesInvited .contains(user.email) {
                            EventPillView(
                                event: event,
                                user: user,
                                inviteView: true,
                                refreshTrigger: $refreshTrigger
                            )
                        }
                    }
                }
            }
        }
        .onChange(of: refreshTrigger) { _ in
            print("variable changed")
            Task {
                await ud.getAllEvents()
            }
        }
    }
}

#Preview {
    MyInvitesView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}
