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
                
                header
                
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
            
            Image(user.profilePic)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.leading)
            
            Text(user.fullname.components(separatedBy: " ").first ?? "")
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
