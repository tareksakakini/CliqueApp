//
//  CreateEventView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/31/25.
//

import SwiftUI
import PhotosUI
import MessageUI
import ContactsUI

struct CreateEventView: View {
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    @Binding var selectedTab: Int
    @State var event: EventModel
    @State var inviteesUserModels: [UserModel] = []
    
    @State var imageSelection: PhotosPickerItem? = nil
    @State var selectedImage: UIImage? = nil
    
    @State var addInviteeSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    @State var showMessageComposer = false
    @State var messageEventID: String = ""

    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "New Event")
                Spacer()
                ScrollView() {
                    EventFields
                    CreateButton
                        .padding(.vertical, 50)
                }
                Spacer()
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("Dismiss", role: .cancel) { }
            }
            .sheet(isPresented: $showMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    MessageComposer(recipients: event.invitedPhoneNumbers, body: "https://cliqueapp-3834b.web.app/?eventId=\(messageEventID)")
                }  else {
                    Text("This device can't send SMS messages.")
                        .padding()
                }
            }
        }
        .task {
            await vm.getAllUsers()
            await vm.getUserFriends(user_email: user.email)
        }
    }
}

#Preview {
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2), event: EventModel())
        .environmentObject(ViewModel())
}

extension CreateEventView {
    
    private var CreateButton: some View {
        
        Button {
            if event.title.count < 3 {
                alertMessage = "Event title has to be 3 characters or longer!"
                showAlert = true
            } else if event.location.isEmpty {
                alertMessage = "You have to select a location first!"
                showAlert = true
            } else {
                Task {
                    let temp_uuid = UUID().uuidString
                    messageEventID = temp_uuid
                    event.attendeesInvited = inviteesUserModels.map({$0.email})
                    
                    await vm.createEventButtonPressed(eventID: temp_uuid, eventTitle: event.title, eventLocation: event.location, eventDateTime: event.dateTime, invitees: event.attendeesInvited, user: user, eventDurationHours: event.hours, eventDurationMinutes: event.minutes, selectedPhoneNumbers: event.invitedPhoneNumbers, selectedImage: selectedImage)
                    
                    if event.invitedPhoneNumbers.count > 0 {
                        showMessageComposer = true
                    }
                    event.title = ""
                    event.location = ""
                    event.dateTime = Date()
                    event.attendeesInvited = []
                    inviteesUserModels = []
                    imageSelection = nil
                    selectedImage = nil
                    event.invitedPhoneNumbers = []
                    
                    
                }
                selectedTab = 0
            }
        } label: {
            Text("Create Event")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
    private var ImageSelector: some View {
        ImageSelectionField(imageSelection: $imageSelection, selectedImage: $selectedImage)
    }
    
    private var TitleField: some View {
        VStack(alignment: .leading) {
            Text("Event Title")
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("", text: $event.title, prompt: Text("Enter your event title here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
    }
    
    private var LocationSelector: some View {
        VStack(alignment: .leading) {
            Text("Location")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            LocationSearchField(eventLocation: $event.location)
        }
    }
    
    private var DateTimeSelector: some View {
        VStack(alignment: .leading) {
            Text("Date and Time")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            DatePicker("", selection: $event.dateTime, displayedComponents: [.date, .hourAndMinute])
                .foregroundColor(.white)
                .labelsHidden()
                .tint(.white)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)
        }
    }
    
    private var DurationSelector: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Duration")
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("(Optional)")
                    .padding(.top, 20)
                    .font(.caption)
                    .foregroundColor(.white)
            }
    
            HStack {
                Picker(
                    selection : $event.hours,
                    label: Text("Hours"),
                    content: {
                        Text("").tag("")
                        ForEach(Array(0...23), id: \.self) {hour in
                            Text("\(hour) h").tag(String(hour))
                        }
                    }
                )
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.white)
                .cornerRadius(10)
            
                
                Picker(
                    selection : $event.minutes,
                    label: Text("Minutes"),
                    content: {
                        Text("").tag("")
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) {minute in
                            Text("\(minute) m").tag(String(minute))
                        }
                    }
                )
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.white)
                .cornerRadius(10)
            }
            .padding(.top, 5)
            .padding(.leading)
        }
    }
    
    private var InviteesSelector: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Invitees")
                
                Button {
                    addInviteeSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $addInviteeSheet) {
                    AddInviteesView(user: user, invitees: $inviteesUserModels, selectedPhoneNumbers: $event.invitedPhoneNumbers)
                        .presentationDetents([.fraction(0.9)])
                }
            }
            .padding(.top, 15)
            .padding(.leading, 25)
            .font(.title2)
            .foregroundColor(.white)
            
            ForEach(inviteesUserModels, id: \.self) { invitee in
                let inviteeUser = vm.getUser(username: invitee.email)
                PersonPillView(
                    viewing_user: user,
                    displayed_user: inviteeUser,
                    personType: "invited",
                    invitees: $inviteesUserModels
                )
            }
            
            ForEach(event.invitedPhoneNumbers, id: \.self) { number in
                NumberPillView(
                    phoneNumber: number,
                    selectedPhoneNumbers: $event.invitedPhoneNumbers
                )
            }
        }
    }
    
    private var EventFields: some View {
        
        VStack(alignment: .leading) {
            ImageSelector
            TitleField
            LocationSelector
            DateTimeSelector
            DurationSelector
            InviteesSelector
        }
    }
}



