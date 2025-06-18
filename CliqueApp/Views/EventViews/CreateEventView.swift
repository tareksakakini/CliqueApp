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
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerSection
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            eventFormCard
                            
                            actionButtons
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
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
            } else {
                    Text("This device can't send SMS messages.")
                        .padding()
            }
        }
        .sheet(isPresented: $showAddInviteeSheet) {
            AddInviteesView(user: user, invitees: $inviteesUserModels, selectedPhoneNumbers: $event.invitedPhoneNumbers)
                .presentationDetents([.fraction(0.9)])
        }
        .id(messageEventID)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5),
                Color(.systemGray4).opacity(0.3),
                Color(.systemGray5).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    if !isNewEvent {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .opacity(!isNewEvent ? 1 : 0)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Text(isNewEvent ? "Create Event" : "Update Event")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(isNewEvent ? "Plan something amazing with your friends" : "Make changes to your event")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
    }
    
    private var eventFormCard: some View {
        VStack(spacing: 24) {
            // Event Image Section
            eventImageSection
            
            // Form Fields
            eventDetailsSection
            
            // Date & Time Section
            dateTimeSection
            
            // Invitees Section
            inviteesSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(.accent).opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                .shadow(color: Color(.accent).opacity(0.1), radius: 24, x: 0, y: 12)
        )
    }
    
    private var eventImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Photo")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ZStack {
                if selectedImage != nil {
                    ImageSelectionField(whichView: "SelectedEventImage", imageSelection: $imageSelection, selectedImage: $selectedImage)
                } else {
                    ImageSelectionField(whichView: "EventImagePlaceholder", imageSelection: $imageSelection, selectedImage: $selectedImage)
                }
            }
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(spacing: 20) {
            // Event Title
            ModernTextField(
                title: "Event Title",
                text: $event.title,
                placeholder: "What's the event called?",
                icon: "textformat"
            )
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                ModernLocationSearchField(eventLocation: $event.location)
            }
        }
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Start Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Starts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                DatePicker("", selection: $event.startDateTime, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .tint(Color(.accent))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    )
            }
            
            // End Time Toggle
            ModernCheckbox(
                isChecked: $event.noEndTime,
                text: "This event doesn't have an end time"
            )
            
            // End Date & Time (aligned with Start Date & Time)
            if !event.noEndTime {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ends")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    DatePicker("", selection: $event.endDateTime, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .tint(Color(.accent))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
    
    private var inviteesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Invitees")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    showAddInviteeSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Add People")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.accent), Color(.accent).opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color(.accent).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            if inviteesUserModels.isEmpty && event.invitedPhoneNumbers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.secondary)
                    
                    Text("No invitees yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Tap 'Add People' to invite friends")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        )
                )
            } else {
                LazyVStack(spacing: 0) {
                    let totalItems = inviteesUserModels.count + event.invitedPhoneNumbers.count
                    
                    ForEach(Array(inviteesUserModels.enumerated()), id: \.element) { index, invitee in
                        let inviteeUser = vm.getUser(username: invitee.email)
                        ModernInviteePillView(
                            viewingUser: user,
                            displayedUser: inviteeUser,
                            personType: "invited",
                            invitees: $inviteesUserModels,
                            isLastItem: index == totalItems - 1
                        )
                    }
                    
                    ForEach(Array(event.invitedPhoneNumbers.enumerated()), id: \.element) { index, number in
                        ModernNumberPillView(
                            phoneNumber: number,
                            selectedPhoneNumbers: $event.invitedPhoneNumbers,
                            isLastItem: (inviteesUserModels.count + index) == totalItems - 1
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !isNewEvent {
        Button {
            dismiss()
        } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                }
            }
            
            Button {
                handleCreateEvent()
            } label: {
                Text(isNewEvent ? "Create Event" : "Update Event")
                    .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.accent), Color(.accent).opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(.accent).opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
    }
    
    private func handleCreateEvent() {
        let now = Date()
        
            if event.title.count < 3 {
            alertMessage = "Event title must be at least 3 characters long"
                showAlert = true
            } else if event.location.isEmpty {
            alertMessage = "Please select a location for your event"
            showAlert = true
        } else if event.startDateTime < now {
            alertMessage = "Event start time cannot be in the past"
            showAlert = true
        } else if !event.noEndTime && event.endDateTime <= event.startDateTime {
            alertMessage = "Event end time must be after the start time"
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
    }
}

#Preview {
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2), event: EventModel(), isNewEvent: false)
        .environmentObject(ViewModel())
}

// MARK: - Modern UI Components

struct ModernLocationSearchField: View {
    @StateObject private var locationSearchHelper = LocationSearchHelper()
    @Binding var eventLocation: String
    @State private var locationQuery: String = ""
    
    var body: some View {
        VStack {
            if eventLocation.isEmpty {
                locationInputField
                if shouldShowSuggestions {
                    suggestionsList
                }
            } else {
                selectedLocationView
            }
        }
    }
    
    private var locationInputField: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            TextField(
                "Search for a location...",
                text: Binding(
                    get: { locationQuery },
                    set: { newValue in
                        locationQuery = newValue
                        locationSearchHelper.updateSearchResults(for: newValue)
                    }
                )
            )
            .font(.system(size: 16, weight: .medium))
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(locationSearchHelper.suggestions.prefix(5).indices, id: \.self) { index in
                let suggestion = locationSearchHelper.suggestions[index]
                
                Button {
                    selectLocation(suggestion.title)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Text(suggestion.subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < locationSearchHelper.suggestions.count - 1 {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var selectedLocationView: some View {
        HStack {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(eventLocation)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                
                Spacer()
                
            Button(action: { 
                eventLocation = ""
                locationQuery = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    private var shouldShowSuggestions: Bool {
        !locationSearchHelper.suggestions.isEmpty && !locationQuery.isEmpty
    }
    
    private func selectLocation(_ location: String) {
        eventLocation = location
        locationQuery = ""
        locationSearchHelper.suggestions = []
    }
}

// MARK: - Modern Invitee List Components

struct ModernInviteePillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    let personType: String
    @Binding var invitees: [UserModel]
    let isLastItem: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            if let user = displayedUser {
                profileSection(for: user)
            }
            
            Spacer()
            
            removeButton
        }
                    .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
        .overlay(
            Group {
                if !isLastItem {
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 1)
                        .padding(.leading, 66)
                }
            },
            alignment: .bottom
        )
    }
    
    private func profileSection(for user: UserModel) -> some View {
        HStack(spacing: 12) {
            ProfilePictureView(user: user, diameter: 42, isPhone: false)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(user.fullname)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(user.username.isEmpty ? "@username" : "@\(user.username)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(user.username.isEmpty ? .secondary.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var removeButton: some View {
        Button {
            guard let user = displayedUser else { return }
            invitees.removeAll { $0 == user }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

struct ModernNumberPillView: View {
    let phoneNumber: String
    @Binding var selectedPhoneNumbers: [String]
    let isLastItem: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(.accent).opacity(0.1))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.accent))
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Phone Contact")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(phoneNumber)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Button {
                selectedPhoneNumbers.removeAll { $0 == phoneNumber }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
        .overlay(
            Group {
                if !isLastItem {
                    Rectangle()
                        .fill(Color.black.opacity(0.12))
                        .frame(height: 1)
                        .padding(.leading, 66)
                }
            },
            alignment: .bottom
        )
    }
}



