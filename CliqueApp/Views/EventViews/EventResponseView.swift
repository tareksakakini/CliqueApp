//
//  EventResponse.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/30/25.
//

import SwiftUI
import MessageUI
import ContactsUI

struct EventResponseView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    @State var event: EventModel
    let inviteView: Bool
    @Binding var isPresented: Bool
    @Binding var eventImage: UIImage?
    
    @State var editView: Bool = false
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.accent).ignoresSafeArea()
                VStack {
                    EventInfo
                    Spacer()
                    inviteView ? AnyView(ResponseButtons) : AnyView(LeaveButton)
                }
            }
        }
    }
}

#Preview {
    EventResponseView(user: UserData.userData[0], event: UserData.eventData[0], inviteView: false, isPresented: .constant(true), eventImage: .constant(nil))
        .environmentObject(ViewModel())
}

extension EventResponseView {
    private var EventInfo: some View {
        ScrollView {
            VStack(alignment: .leading) {
                EventHeader
                EventDate
                EventTime
                
                if event.hours != "" && event.minutes != "" {
                    EventDuration
                }
                
                EventLocation
                EventOrganizer
                EventAttendees
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.white)
            .padding()
        }
    }
    
    private var EventAttendees: some View {
        VStack {
            HStack {
                Image(systemName: "person.3.fill")
                Text("People")
            }
            .font(.body)
            .bold()
            .padding(.top, 15)
            
            EventAttendeesAccepted
            EventAttendeesAcceptedPhone
            EventAttendeesInvited
            EventAttendeesInvitedPhone
        }
    }
    
    private var AcceptButton: some View {
        Button {
            Task {
                await vm.acceptButtonPressed(user: user, event: event)
                await vm.getAllEvents()
                isPresented.toggle()
            }
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
    }
    
    private var DeclineButton: some View {
        Button {
            Task {
                await vm.declineButtonPressed(user: user, event: event)
                await vm.getAllEvents()
                isPresented.toggle()
            }
            
        } label: {
            Text("Decline")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    private var ResponseButtons: some View {
        HStack {
            Spacer()
            AcceptButton
            Spacer()
            DeclineButton
            Spacer()
        }
    }
    
    private var LeaveButton: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    await vm.leaveButtonPressed(user: user, event: event)
                    await vm.getAllEvents()
                    isPresented.toggle()
                }
            } label: {
                Text("Leave Event")
                    .padding()
                    .padding(.horizontal)
                    .background(.white)
                    .cornerRadius(10)
                    .foregroundColor(Color(.accent))
                    .bold()
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
            }
            Spacer()
        }
    }
    
    private var EventTitle: some View {
        Text("\(event.title)")
            .font(.largeTitle)
            .padding(.bottom)
    }
    
    private var EditButton: some View {
        Button {
            editView = true
        } label: {
            Image(systemName: "square.and.pencil")
                .resizable()
                .scaledToFit()
                .padding(.trailing)
                .padding(.bottom)
                .frame(width: 40)
        }
        .fullScreenCover(isPresented: $editView) {
            CreateEventView(user: user, selectedTab: .constant(0), event: event, isNewEvent: false, selectedImage: eventImage)
        }
    }
    
    private var EventHeader: some View {
        HStack {
            EventTitle
            Spacer()
            if event.host == user.email {
                EditButton
            }
        }
    }
    
    private var EventDate: some View {
        HStack {
            Image(systemName: "calendar")
            Text("\(vm.formatDate(date: event.dateTime))")
        }
        .font(.body)
    }
    
    private var EventTime: some View {
        HStack {
            Image(systemName: "clock")
            Text("\(vm.formatTime(time: event.dateTime))")
        }
        .font(.body)
    }
    
    private var EventDuration: some View {
        HStack {
            Image(systemName: "timer")
            Text("\(event.hours) Hours \(event.minutes) Minutes")
        }
        .font(.body)
    }
    
    private var EventLocation: some View {
        HStack {
            Image(systemName: "map.fill")
            Text("\(event.location)")
        }
        .font(.body)
    }
    
    private var EventOrganizer: some View {
        VStack {
            HStack {
                Image(systemName: "crown.fill")
                Text("Organized by")
            }
            .font(.body)
            .bold()
            .padding(.top, 15)
            
            if let user = vm.getUser(username: event.host) {
                HStack {
                    ProfilePictureView(user: user, diameter: 30, isPhone: false)
                    Text("\(user.fullname)")
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var EventAttendeesAccepted: some View {
        ForEach(event.attendeesAccepted, id: \.self) {username in
            if let user = vm.getUser(username: username) {
                HStack {
                    ProfilePictureView(user: user, diameter: 30, isPhone: false)
                    Text("\(user.fullname)")
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var EventAttendeesInvited: some View {
        ForEach(event.attendeesInvited, id: \.self) {username in
            if let user = vm.getUser(username: username) {
                HStack {
                    ProfilePictureView(user: user, diameter: 30, isPhone: false)
                    Text("\(user.fullname)")
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var EventAttendeesAcceptedPhone: some View {
        ForEach(event.acceptedPhoneNumbers, id: \.self) {phone_number in
            HStack {
                ProfilePictureView(user: nil, diameter: 30, isPhone: true)
                Text("\(phone_number)")
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var EventAttendeesInvitedPhone: some View {
        ForEach(event.invitedPhoneNumbers, id: \.self) {phone_number in
            HStack {
                ProfilePictureView(user: nil, diameter: 30, isPhone: true)
                Text("\(phone_number)")
                Image(systemName: "questionmark.circle")
                    .foregroundColor(.white)
            }
        }
    }
}
