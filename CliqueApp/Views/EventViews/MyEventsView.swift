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
        ScrollView {
            ForEach(vm.events, id: \.self) {event in
                let checklist = isInviteView ? event.attendeesInvited : event.attendeesAccepted + [event.host]
                if checklist.contains(user.email) {
                    EventPillView(
                        event: event,
                        user: user,
                        inviteView: isInviteView
                    )
                }
            }
        }
        .refreshable {
            await vm.getAllEvents()
        }
    }
}
