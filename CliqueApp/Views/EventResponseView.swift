//
//  EventResponse.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/30/25.
//

import SwiftUI

struct EventResponseView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user: UserModel
    @State var event: EventModel
    let inviteView: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                if inviteView {
                    reponseButtons
                }
                else {
                    leaveButton
                }
                
            }
        }
    }
}

#Preview {
    EventResponseView(user: UserData.userData[0], event: UserData.eventData[0], inviteView: false)
        .environmentObject(ViewModel())
}

extension EventResponseView {
    private var reponseButtons: some View {
        HStack {
            Spacer()
            
            Button {
                ud.inviteRespond(username: user.userName, event_id: event.id, accepted: true)
            } label: {
                Text("Accept")
                    .padding()
                    .padding(.horizontal)
                    .background(.green.opacity(0.8))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .bold()
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
            }
            
            Spacer()
            
            Button {
                ud.inviteRespond(username: user.userName, event_id: event.id, accepted: false)
            } label: {
                Text("Reject")
                    .padding()
                    .padding(.horizontal)
                    .background(.white)
                    .cornerRadius(10)
                    .foregroundColor(Color.accentColor)
                    .bold()
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
            }
            
            Spacer()
            
        }
    }
    
    private var leaveButton: some View {
        HStack {
            Spacer()
            
            Button {
                ud.eventLeave(username: user.userName, event_id: event.id)
            } label: {
                Text("Leave Event")
                    .padding()
                    .padding(.horizontal)
                    .background(.white)
                    .cornerRadius(10)
                    .foregroundColor(Color.accentColor)
                    .bold()
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
            }
            
            Spacer()
        }
    }
}
