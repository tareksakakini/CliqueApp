//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyInvitesView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    
    var body: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "My Invites")
                MyInviteScrollView
            }
        }
    }
}

#Preview {
    MyInvitesView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyInvitesView {
    private var MyInviteScrollView: some View {
        ScrollView {
            ForEach(vm.events, id: \.self) {event in
                if event.attendeesInvited .contains(user.email) {
                    EventPillView(
                        event: event,
                        user: user,
                        inviteView: true
                    )
                }
            }
        }
        .refreshable {
            await vm.getAllEvents()
        }
    }
}
