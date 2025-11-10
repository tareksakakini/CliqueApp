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
    @State var duration: (days: Int, hours: Int, minutes: Int) = (0, 0, 0)
    @State var isAcceptingInvite: Bool = false
    @State var isDecliningInvite: Bool = false
    @State var isLeavingEvent: Bool = false
    @State private var errorAlert: AlertConfig? = nil
    
    
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
        .onAppear {
            duration = vm.calculateDuration(startDateTime: event.startDateTime, endDateTime: event.endDateTime)
        }
        .alert(errorAlert?.title ?? "Error", isPresented: Binding(
            get: { errorAlert != nil },
            set: { if !$0 { errorAlert = nil } }
        )) {
            Button("OK", role: .cancel) { errorAlert = nil }
        } message: {
            if let errorAlert = errorAlert {
                Text(errorAlert.message)
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
                if !event.noEndTime {
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
                isAcceptingInvite = true
                do {
                    try await vm.acceptButtonPressed(user: user, event: event)
                    try await vm.getAllEvents()
                    isPresented.toggle()
                } catch {
                    errorAlert = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Accept invitation"))
                }
                isAcceptingInvite = false
            }
        } label: {
            HStack(spacing: 8) {
                if isAcceptingInvite {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isAcceptingInvite ? "Accepting..." : "Accept")
            }
            .padding()
            .padding(.horizontal)
            .background(.green.opacity(0.8))
            .cornerRadius(10)
            .foregroundColor(.white)
            .bold()
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .disabled(isAcceptingInvite)
    }
    
    private var DeclineButton: some View {
        Button {
            Task {
                isDecliningInvite = true
                do {
                    try await vm.declineButtonPressed(user: user, event: event)
                    try await vm.getAllEvents()
                    isPresented.toggle()
                } catch {
                    errorAlert = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Decline invitation"))
                }
                isDecliningInvite = false
            }
            
        } label: {
            HStack(spacing: 8) {
                if isDecliningInvite {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Color(.accent))
                }
                Text(isDecliningInvite ? "Declining..." : "Decline")
            }
            .padding()
            .padding(.horizontal)
            .background(.white)
            .cornerRadius(10)
            .foregroundColor(Color(.accent))
            .bold()
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .disabled(isDecliningInvite)
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
                    isLeavingEvent = true
                    do {
                        try await vm.leaveButtonPressed(user: user, event: event)
                        try await vm.getAllEvents()
                        isPresented.toggle()
                    } catch {
                        errorAlert = AlertConfig(message: ErrorHandler.shared.handleError(error, operation: "Leave event"))
                    }
                    isLeavingEvent = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isLeavingEvent {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Color(.accent))
                    }
                    Text(isLeavingEvent ? "Leaving..." : "Leave Event")
                }
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
            }
            .disabled(isLeavingEvent)
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
            Text("\(vm.formatDate(date: event.startDateTime))")
        }
        .font(.body)
    }
    
    private var EventTime: some View {
        HStack {
            Image(systemName: "clock")
            Text("\(vm.formatTime(time: event.startDateTime))")
        }
        .font(.body)
    }
    
    private var EventDuration: some View {
        HStack {
            Image(systemName: "timer")
            Text(durationText)
        }
        .font(.body)
    }
    
    private var durationText: String {
        var components: [String] = []
        
        if duration.days > 0 {
            components.append("\(duration.days) \(duration.days == 1 ? "Day" : "Days")")
        }
        if duration.hours > 0 {
            components.append("\(duration.hours) \(duration.hours == 1 ? "Hour" : "Hours")")
        }
        if duration.minutes > 0 {
            components.append("\(duration.minutes) \(duration.minutes == 1 ? "Minute" : "Minutes")")
        }
        
        return components.isEmpty ? "0 Minutes" : components.joined(separator: " ")
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
