//
//  CreateEventView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/31/25.
//

import SwiftUI
import MapKit

struct EditEventView: View {
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var createEventSuccess: Bool = false
    @State var addInviteeSheet: Bool = false
    
    @State private var showAlertTitle: Bool = false
    @State private var showAlertLocation: Bool = false
    
    @State var user: UserModel
    @State var event: EventModel
    @State var event_title: String = ""
    @State var event_location: String = ""
    @State var event_dateTime: Date = Date()
    @State var invitees: [UserModel] = []
    @State var inviteesInvited: [UserModel] = []
    @State var inviteesAccepted: [UserModel] = []
    
    @StateObject private var locationSearchHelper = LocationSearchHelper()
    @State private var locationQuery = ""
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header_view_local
                
                Spacer()
                
                ScrollView() {
                    
                    event_fields
                    
                    HStack {
                        create_button
                    }
                    .padding(.vertical, 50)
                    
                }
                
                Spacer()
                
            }
            .alert("Event title has to be 3 characters or longer!", isPresented: $showAlertTitle) {
                Button("Dismiss", role: .cancel) { }
            }
            .alert("You have to select a location first!", isPresented: $showAlertLocation) {
                Button("Dismiss", role: .cancel) { }
            }
        }
        .onAppear {
            event_title = event.title
            event_location = event.location
            event_dateTime = event.dateTime
            Task {
                await ud.getAllUsers()
            }
            Task {
                await ud.getUserFriends(user_email: user.email)
            }
            for invitee_accepted_email in event.attendeesAccepted {
                if let invitee_accepted = ud.getUser(username: invitee_accepted_email) {
                    inviteesAccepted.append(invitee_accepted)
                }
            }
            for invitee_email in event.attendeesInvited {
                if let invitee = ud.getUser(username: invitee_email) {
                    inviteesInvited.append(invitee)
                }
            }
            invitees = inviteesInvited + inviteesAccepted
        }
    }
}

#Preview {
    EditEventView(user: UserData.userData[0], event: UserData.eventData[0])
        .environmentObject(ViewModel())
}

extension EditEventView {
    
    private var header_view_local: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("Edit Event")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            cancel_button
        }
        .padding()
    }
    
    private var cancel_button: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .font(.caption)
                .frame(width: 20, height: 20)
                .padding()
        }
    }
    
    private var create_button: some View {
        
        Button {
            if event_title.count < 3 {
                showAlertTitle = true
            } else if event_location.isEmpty {
                showAlertLocation = true
            } else {
                Task {
                    do {
                        let firestoreService = DatabaseManager()
                        var invitee_emails = invitees.map {$0.email}
                        var inviteeAccepted_emails_old = inviteesAccepted.map {$0.email}
                        var inviteeInvited_emails_old = inviteesInvited.map {$0.email}
                        
                        var inviteeAccepted_new: [UserModel] = []
                        var inviteeInvited_new: [UserModel] = []
                        
                        for invitee in invitees {
                            if inviteeAccepted_emails_old.contains(invitee.email) {
                                inviteeAccepted_new.append(invitee)
                                let notificationText: String = "\(user.fullname) just updated an event you're going to!"
                                sendPushNotification(notificationText: notificationText, receiverID: invitee.subscriptionId)
                            } else if inviteeInvited_emails_old.contains(invitee.email) {
                                inviteeInvited_new.append(invitee)
                                let notificationText: String = "\(user.fullname) just updated an event you're invited to!"
                                sendPushNotification(notificationText: notificationText, receiverID: invitee.subscriptionId)
                            } else {
                                inviteeInvited_new.append(invitee)
                                let notificationText: String = "\(user.fullname) just invited you to an event!"
                                sendPushNotification(notificationText: notificationText, receiverID: invitee.subscriptionId)
                            }
                        }
                        
                        var inviteeAccepted_new_emails = inviteeAccepted_new.map {$0.email}
                        var inviteeInvited_new_emails = inviteeInvited_new.map {$0.email}
                        
                        try await firestoreService.deleteEventFromFirestore(id: event.id)
                        try await firestoreService.addEventToFirestore(id: event.id, title: event_title, location: event_location, dateTime: event_dateTime, attendeesAccepted: inviteeAccepted_new_emails, attendeesInvited: inviteeInvited_new_emails, host: user.email)
                        //ud.events.removeAll { $0.id == event.id }
                        //ud.events += [EventModel(id: event.id, title: event_title, location: event_location, dateTime: event_dateTime, attendeesAccepted: inviteeAccepted_new_emails, attendeesInvited: inviteeInvited_new_emails, host: user.email)]
                    } catch {
                        print("Failed to update event: \(error.localizedDescription)")
                    }
                }
            }
            dismiss()
        } label: {
            Text("Update Event")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
    private var event_fields: some View {
        
        VStack(alignment: .leading) {
            
            Text("Event Title")
                .padding(.top, 30)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("", text: $event_title, prompt: Text("Enter your event title here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Location")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            if event_location.isEmpty {
                TextField("", text: $locationQuery, prompt: Text("Enter your event location here ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: locationQuery) { newValue in
                        locationSearchHelper.updateSearchResults(for: newValue)
                    }
                
                if !locationSearchHelper.suggestions.isEmpty && !locationQuery.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(locationSearchHelper.suggestions.prefix(5).indices, id: \.self) { index in
                            let suggestion = locationSearchHelper.suggestions[index]
                            VStack(alignment: .leading) {
                                Text(suggestion.title)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(suggestion.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            //.padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                            .onTapGesture {
                                event_location = suggestion.title
                                locationQuery = ""
                                locationSearchHelper.suggestions = [] // Hide suggestions after selection
                            }
                            
                            if index < locationSearchHelper.suggestions.count - 1 {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                            }
                        }
                    }
                    //.padding(.horizontal)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                
            } else {
                HStack() {
                    Text(event_location)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Button {
                        event_location = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            
            Text("Date and Time")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            DatePicker("", selection: $event_dateTime, displayedComponents: [.date, .hourAndMinute])
                .foregroundColor(.white)
                .labelsHidden()
                .tint(.white)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)
            
            HStack {
                Text("Invitees")
                
                Button {
                    addInviteeSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $addInviteeSheet) {
                    AddInviteesView(user: user, invitees: $invitees)
                        .presentationDetents([.fraction(0.9)])
                }
            }
            .padding(.top, 15)
            .padding(.leading, 25)
            .font(.title2)
            .foregroundColor(.white)
            
            ForEach(invitees, id: \.self) { invitee in
                let inviteeUser = ud.getUser(username: invitee.email)
                PersonPillView(
                    viewing_user: user,
                    displayed_user: inviteeUser,
                    personType: "invited",
                    invitees: $invitees
                )
            }
        }
        
    }
}



