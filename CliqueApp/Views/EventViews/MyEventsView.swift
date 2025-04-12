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
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "My Events")
                EventScrollView
            }
        }
    }
}

#Preview {
    MyEventsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyEventsView {
    private var EventScrollView: some View {
        ScrollView {
            ForEach(vm.events, id: \.self) {event in
                if event.attendeesAccepted.contains(user.email) || event.host == user.email {
                    EventPillView(
                        event: event,
                        user: user,
                        inviteView: false
                    )
                }
            }
        }
        .refreshable {
            await vm.getAllEvents()
        }
    }
}
