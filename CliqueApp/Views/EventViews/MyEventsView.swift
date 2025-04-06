//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyEventsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user: UserModel
    @State private var refreshTrigger = false
    
    var body: some View {
        
        ZStack {
            
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                HeaderView(user: user, title: "My Events")
                
                ScrollView {
                    
                    ForEach(ud.events.indices, id: \.self) {event_index in
                        let event = ud.events[event_index]
                        if event.attendeesAccepted.contains(user.email) || event.host == user.email {
                            EventPillView(
                                event: event,
                                user: user,
                                inviteView: false,
                                refreshTrigger: $refreshTrigger
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await ud.getAllEvents()
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
    MyEventsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}
