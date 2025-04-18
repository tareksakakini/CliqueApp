//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyEventsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    let isInviteView: Bool
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: isInviteView ? "My Invites" : "My Events", navigationBinder: .constant(false))
                EventScrollView
            }
        }
    }
}

#Preview {
    MyEventsView(user: UserData.userData[0], isInviteView: true)
        .environmentObject(ViewModel())
}

extension MyEventsView {
    private var EventScrollView: some View {
        let filteredEvents = vm.events.filter { event in
            let checklist = isInviteView ? event.attendeesInvited : event.attendeesAccepted + [event.host]
            return checklist.contains(user.email)
        }
        
        return ScrollView {
            if filteredEvents.count == 0 {
                Text("Pull down to refresh")
                    .foregroundColor(Color(.accent))
            }
            ForEach(filteredEvents, id: \.self) {event in
                EventPillView(
                    event: event,
                    user: user,
                    inviteView: isInviteView
                )
            }
        }
        .refreshable {
            await vm.getAllEvents()
        }
    }
}
