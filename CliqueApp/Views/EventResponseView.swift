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
            Color.accent.ignoresSafeArea()
            
            VStack {
                
                event_info
                
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
                ud.inviteRespond(username: user.email, event_id: event.id, accepted: true)
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
                ud.inviteRespond(username: user.email, event_id: event.id, accepted: false)
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
                ud.eventLeave(username: user.email, event_id: event.id)
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
    
    private var event_info: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("\(event.title)")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                HStack {
                    Image(systemName: "calendar")
                    Text("\(ud.formatDate(date: event.dateTime))")
                }
                .font(.body)
                
                HStack {
                    Image(systemName: "clock")
                    Text("\(ud.formatTime(time: event.dateTime))")
                }
                .font(.body)
                
                HStack {
                    Image(systemName: "map.fill")
                    Text("\(event.location)")
                }
                .font(.body)
                
                HStack {
                    Image(systemName: "person.3.fill")
                    Text("People")
                }
                .font(.body)
                .bold()
                .padding(.top, 15)
                
                ForEach(event.attendeesAccepted, id: \.self) {username in
                    if let user = ud.getUser(username: username) {
                        HStack {
                            Image(user.profilePic)
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(width: 30)
                                .padding(.horizontal, 3)
                            Text("\(user.fullname)")
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                ForEach(event.attendeesInvited, id: \.self) {username in
                    if let user = ud.getUser(username: username) {
                        HStack {
                            Image(user.profilePic)
                                .resizable()
                                .scaledToFit()
                                .clipShape(Circle())
                                .frame(width: 30)
                                .padding(.horizontal, 3)
                            Text("\(user.fullname)")
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
                
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.white)
            .padding()
        }
    }
}
