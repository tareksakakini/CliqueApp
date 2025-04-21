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
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    @Binding var selectedTab: Int
    @State var event: EventModel
    let isNewEvent: Bool
    @State var selectedImage: UIImage? = nil
    
    @State var oldEvent: EventModel = EventModel()
    @State var newPhoneNumbers: [String] = []
    @State var inviteesUserModels: [UserModel] = []
    @State var imageSelection: PhotosPickerItem? = nil
    
    @State var showAddInviteeSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    
    @State var showMessageComposer = false
    @State var messageEventID: String = ""

    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: isNewEvent ? "New Event" : "Update Event", navigationBinder: .constant(false))
                Spacer()
                ScrollView() {
                    EventFields
                    HStack {
                        CreateButton
                        if !isNewEvent {
                            CancelButton
                        }
                    }
                    .padding(.vertical, 50)
                }
                Spacer()
            }
            .onAppear {
                oldEvent = event
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("Dismiss", role: .cancel) { }
            }
            .sheet(isPresented: $showMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    MessageComposer(
                        recipients: newPhoneNumbers,
                        body: "https://cliqueapp-3834b.web.app/?eventId=\(messageEventID)",
                        onFinish: {
                            Task {
                                await vm.createEventButtonPressed(eventID: messageEventID, user: user, event: event, selectedImage: selectedImage, isNewEvent: isNewEvent, oldEvent: oldEvent)
                                await vm.getAllEvents()
                                event = EventModel()
                                inviteesUserModels = []
                                imageSelection = nil
                                selectedImage = nil
                                newPhoneNumbers = []
                                oldEvent = EventModel()
                                if isNewEvent {
                                    selectedTab = 0
                                }
                            }
                        }
                    )
                }  else {
                    Text("This device can't send SMS messages.")
                        .padding()
                }
            }
            .id(messageEventID)
        }
    }
}

#Preview {
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2), event: EventModel(), isNewEvent: false)
        .environmentObject(ViewModel())
}

extension CreateEventView {
    
    private var CancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Back")
                .frame(width: 150, height: 55)
                .background(Color(#colorLiteral(red: 0.6642242074, green: 0.6642400622, blue: 0.6642315388, alpha: 1)))
                .cornerRadius(10)
                .foregroundColor(.white)
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
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
                    let temp_uuid = isNewEvent ? UUID().uuidString : event.id
                    messageEventID = temp_uuid
                    
                    event.attendeesInvited = inviteesUserModels.map({$0.email})
                    newPhoneNumbers = []
                    for phoneNumber in event.invitedPhoneNumbers {
                        if !oldEvent.invitedPhoneNumbers.contains(phoneNumber) {
                            newPhoneNumbers.append(phoneNumber)
                        }
                    }
                    
                    if newPhoneNumbers.count > 0 {
                        print("MessageEventID: \(messageEventID)")
                        DispatchQueue.main.async {showMessageComposer = true}
                    } else {
                        await vm.createEventButtonPressed(eventID: temp_uuid, user: user, event: event, selectedImage: selectedImage, isNewEvent: isNewEvent, oldEvent: oldEvent)
                        await vm.getAllEvents()
                        event = EventModel()
                        inviteesUserModels = []
                        imageSelection = nil
                        selectedImage = nil
                        newPhoneNumbers = []
                        oldEvent = EventModel()
                        if isNewEvent {
                            selectedTab = 0
                        }
                    }
                }
            }
        } label: {
            Text(isNewEvent ? "Create Event" : "Update Event")
                .frame(width: 150, height: 55)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
    private var ImageSelector: some View {
        ZStack {
            if selectedImage != nil {
                ImageSelectionField(whichView: "SelectedEventImage", imageSelection: $imageSelection, selectedImage: $selectedImage)
            } else {
                ImageSelectionField(whichView: "EventImagePlaceholder", imageSelection: $imageSelection, selectedImage: $selectedImage)
            }
        }
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
            Text("Starts")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            DatePicker("", selection: $event.startDateTime, displayedComponents: [.date, .hourAndMinute])
                .foregroundColor(.white)
                .labelsHidden()
                .tint(.white)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)
        
            HStack() {
                Text("Ends")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: event.noEndTime ? "checkmark.square.fill" : "square.fill")
                    .foregroundColor(event.noEndTime ? .blue.opacity(0.5) : .white)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .onTapGesture {
                        event.noEndTime.toggle()
                    }
                
                Text("Do not include end time")
                    .foregroundColor(.white)
                    .font(.footnote)
            }
            .padding(.top, 15)
            .padding(.horizontal, 25)
            
            if !event.noEndTime {
                DatePicker("", selection: $event.endDateTime, displayedComponents: [.date, .hourAndMinute])
                    .foregroundColor(.white)
                    .labelsHidden()
                    .tint(.white)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var InviteesSelector: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Invitees")
                
                Button {
                    showAddInviteeSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $showAddInviteeSheet) {
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
                    viewingUser: user,
                    displayedUser: inviteeUser,
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
            InviteesSelector
        }
    }
}



