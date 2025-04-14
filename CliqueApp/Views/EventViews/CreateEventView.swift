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
    
    @State var eventTitle: String = ""
    @State var eventLocation: String = ""
    @State var eventDateTime: Date = Date()
    @State var eventDurationHours: String = ""
    @State var eventDurationMinutes: String = ""
    @State var invitees: [UserModel] = []
    
    @State var imageSelection: PhotosPickerItem? = nil
    @State var selectedImage: UIImage? = nil
    
    @State var addInviteeSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    @State var selectedPhoneNumbers: [String] = []
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
                    MessageComposer(recipients: selectedPhoneNumbers, body: "https://cliqueapp-3834b.web.app/?eventId=\(messageEventID)")
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
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2))
        .environmentObject(ViewModel())
}

extension CreateEventView {
    
    private var CreateButton: some View {
        
        Button {
            if eventTitle.count < 3 {
                alertMessage = "Event title has to be 3 characters or longer!"
                showAlert = true
            } else if eventLocation.isEmpty {
                alertMessage = "You have to select a location first!"
                showAlert = true
            } else {
                Task {
                    let temp_uuid = UUID().uuidString
                    messageEventID = temp_uuid
                    
                    await vm.createEventButtonPressed(eventID: temp_uuid, eventTitle: eventTitle, eventLocation: eventLocation, eventDateTime: eventDateTime, invitees: invitees, user: user, eventDurationHours: eventDurationHours, eventDurationMinutes: eventDurationMinutes, selectedPhoneNumbers: selectedPhoneNumbers, selectedImage: selectedImage)
                    
                    eventTitle = ""
                    eventLocation = ""
                    eventDateTime = Date()
                    invitees = []
                    imageSelection = nil
                    selectedImage = nil
                    selectedPhoneNumbers = []
                    if selectedPhoneNumbers.count > 0 {
                        showMessageComposer = true
                    }
                    
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
            
            TextField("", text: $eventTitle, prompt: Text("Enter your event title here ...").foregroundColor(Color.black.opacity(0.5)))
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
            
            LocationSearchField(eventLocation: $eventLocation)
        }
    }
    
    private var DateTimeSelector: some View {
        VStack(alignment: .leading) {
            Text("Date and Time")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            DatePicker("", selection: $eventDateTime, displayedComponents: [.date, .hourAndMinute])
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
                    selection : $eventDurationHours,
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
                    selection : $eventDurationMinutes,
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
                    AddInviteesView(user: user, invitees: $invitees, selectedPhoneNumbers: $selectedPhoneNumbers)
                        .presentationDetents([.fraction(0.9)])
                }
            }
            .padding(.top, 15)
            .padding(.leading, 25)
            .font(.title2)
            .foregroundColor(.white)
            
            ForEach(invitees, id: \.self) { invitee in
                let inviteeUser = vm.getUser(username: invitee.email)
                PersonPillView(
                    viewing_user: user,
                    displayed_user: inviteeUser,
                    personType: "invited",
                    invitees: $invitees
                )
            }
            
            ForEach(selectedPhoneNumbers, id: \.self) { number in
                NumberPillView(
                    phoneNumber: number,
                    selectedPhoneNumbers: $selectedPhoneNumbers
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



