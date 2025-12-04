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

// Extension to handle timezone-agnostic date conversions
extension Date {
    // Convert from local time to UTC while preserving the wall-clock time
    // Example: 8:00 PM local -> 8:00 PM UTC
    func toUTCPreservingWallClock() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: self)
        var utcComponents = DateComponents()
        utcComponents.year = components.year
        utcComponents.month = components.month
        utcComponents.day = components.day
        utcComponents.hour = components.hour
        utcComponents.minute = components.minute
        utcComponents.second = components.second
        utcComponents.timeZone = TimeZone(identifier: "UTC")
        
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: utcComponents) ?? self
    }
    
    // Convert from UTC to local time while preserving the wall-clock time
    // Example: 8:00 PM UTC -> 8:00 PM local
    func fromUTCPreservingWallClock() -> Date {
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        var localComponents = DateComponents()
        localComponents.year = components.year
        localComponents.month = components.month
        localComponents.day = components.day
        localComponents.hour = components.hour
        localComponents.minute = components.minute
        localComponents.second = components.second
        localComponents.timeZone = TimeZone.current
        
        let calendar = Calendar.current
        return calendar.date(from: localComponents) ?? self
    }
}

enum InviteStatus: String, CaseIterable {
    case invited
    case accepted
    case declined
    
    var displayName: String {
        switch self {
        case .invited:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        }
    }
    
    var iconName: String {
        switch self {
        case .invited:
            return "clock.circle"
        case .accepted:
            return "checkmark.circle.fill"
        case .declined:
            return "xmark.circle.fill"
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .invited:
            return .orange
        case .accepted:
            return Color(.systemGreen)
        case .declined:
            return Color(.systemRed)
        }
    }
}

struct CreateEventView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    @Binding var selectedTab: Int
    @State var event: EventModel
    let isNewEvent: Bool
    @State var selectedImage: UIImage? = nil
    let hideSuggestionsHeader: Bool
    let unsplashImageURL: String?
    let onEventCreated: (() -> Void)?
    
    init(user: UserModel, selectedTab: Binding<Int>, event: EventModel, isNewEvent: Bool, selectedImage: UIImage? = nil, hideSuggestionsHeader: Bool = false, unsplashImageURL: String? = nil, onEventCreated: (() -> Void)? = nil) {
        self._user = State(initialValue: user)
        self._selectedTab = selectedTab
        self._event = State(initialValue: event)
        self.isNewEvent = isNewEvent
        self._selectedImage = State(initialValue: selectedImage)
        self.hideSuggestionsHeader = hideSuggestionsHeader
        self.unsplashImageURL = unsplashImageURL
        self.onEventCreated = onEventCreated
    }
    
    @State var oldEvent: EventModel = EventModel()
    @State var newPhoneNumbers: [String] = []
    @State var inviteesUserModels: [UserModel] = []
    @State var invitedContacts: [ContactInfo] = []
    @State private var inviteeStatuses: [String: InviteStatus] = [:]
    @State private var contactStatuses: [String: InviteStatus] = [:]
    @State var imageSelection: PhotosPickerItem? = nil
    @State var tempSelectedImage: UIImage? = nil
    @State var showImageCrop = false
    
    @State var showAddInviteeSheet: Bool = false
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    @State var showCreateWithAI: Bool = false
    @State var isPreparingAI: Bool = false
    
    @State var showMessageComposer = false
    @State var messageEventID: String = ""
    @State private var draftEventIDForSMS: String? = nil
    @State var viewIdentityID: String = ""
    @State var isCreatingEvent: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    if !hideSuggestionsHeader {
                        headerSection
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            eventFormCard
                            
                            actionButtons
                    }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        .padding(.top, hideSuggestionsHeader ? 20 : 0)
                    }
                }
            }
            }
            .onAppear {
                oldEvent = event
                // Load existing invitees when editing an event
                if !isNewEvent {
                    loadExistingInvitees()
                } else {
                    // For new events, update the times to current if all fields are empty
                    let isFormEmpty = event.title.isEmpty &&
                                     event.location.isEmpty &&
                                     event.description.isEmpty &&
                                     inviteesUserModels.isEmpty &&
                                     invitedContacts.isEmpty &&
                                     selectedImage == nil
                    
                    if isFormEmpty {
                        let now = Date()
                        // Convert current time to UTC-preserving format
                        event.startDateTime = now.toUTCPreservingWallClock()
                        // Set end time to 30 minutes after start time
                        let endTime = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now
                        event.endDateTime = endTime.toUTCPreservingWallClock()
                    }
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("Dismiss", role: .cancel) { }
            }
            .fullScreenCover(isPresented: $showCreateWithAI) {
                AIEventCreationView(
                    user: user, 
                    selectedTab: $selectedTab,
                    onEventCreated: {
                        // When event is created from AI, dismiss the AI flow and go to My Events
                        showCreateWithAI = false
                        selectedTab = 0
                    }
                )
            }
            .sheet(isPresented: $showMessageComposer) {
                if MFMessageComposeViewController.canSendText() {
                    MessageComposer(
                        recipients: newPhoneNumbers,
                        body: "https://cliqueapp-3834b.web.app/?eventId=\(messageEventID)&v=1",
                        onFinish: { result in
                            Task {
                                await handleSMSSendResult(sent: result == .sent)
                            }
                        }
                    )
            } else {
                    Text("This device can't send SMS messages.")
                        .padding()
                }
            }
        .sheet(isPresented: $showAddInviteeSheet) {
            AddInviteesView(user: user, invitees: $inviteesUserModels, selectedContacts: $invitedContacts)
                .presentationDetents([.fraction(0.9)])
        }
        .sheet(isPresented: $showImageCrop) {
            if let image = tempSelectedImage {
                EventImageCropView(
                    image: image,
                    onCrop: { croppedImage in
                        selectedImage = croppedImage
                        showImageCrop = false
                        tempSelectedImage = nil
                        imageSelection = nil
                    },
                    onCancel: {
                        showImageCrop = false
                        tempSelectedImage = nil
                        imageSelection = nil
                    }
                )
            }
        }
        .onChange(of: imageSelection) { oldValue, newValue in
            Task {
                if let photoItem = newValue {
                    // Convert PhotosPickerItem to UIImage for cropping
                    do {
                        guard let imageData = try await photoItem.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: imageData) else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.tempSelectedImage = uiImage
                            self.showImageCrop = true
                        }
                    } catch {
                        print("Failed to load image data:", error)
                    }
                }
                }
            }
        .onChange(of: inviteesUserModels) { oldValue, newValue in
            syncInviteeStatuses(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: invitedContacts) { oldValue, newValue in
            syncContactStatuses(oldValue: oldValue, newValue: newValue)
        }
            .id(viewIdentityID)
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
            
            // Create with AI Button (only for new events)
            if isNewEvent && FeatureFlags.enableAIEventCreation {
                Button {
                    isPreparingAI = true
                    // Add a small delay to simulate preparation, then show the AI chat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isPreparingAI = false
                        showCreateWithAI = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isPreparingAI {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isPreparingAI ? "Preparing AI..." : "Create with AI")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple,
                                Color.blue
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isPreparingAI)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
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
            HStack {
                Text("Event Photo")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Clear image button (only show when image is selected or Unsplash URL exists)
                if selectedImage != nil || unsplashImageURL != nil {
                    Button(action: {
                        selectedImage = nil
                        imageSelection = nil
                        tempSelectedImage = nil
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Remove")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Color(.accent))
                    }
                }
            }
            
            ZStack {
                if let selectedImage = selectedImage {
                    ImageSelectionField(whichView: "SelectedEventImage", imageSelection: $imageSelection, selectedImage: $selectedImage, enableCropMode: true)
                } else if let urlString = unsplashImageURL, let url = URL(string: urlString) {
                    PhotosPicker(selection: $imageSelection, matching: .images) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                                    .cornerRadius(10)
                                    .padding()
                            case .failure:
                                ImageSelectionField(whichView: "EventImagePlaceholder", imageSelection: $imageSelection, selectedImage: $selectedImage, enableCropMode: true)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                } else {
                    ImageSelectionField(whichView: "EventImagePlaceholder", imageSelection: $imageSelection, selectedImage: $selectedImage, enableCropMode: true)
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
                icon: "text.page",
                autocapitalization: .words
            )
            
            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                ModernLocationSearchField(eventLocation: $event.location)
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(event.description.count)/1000")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(event.description.count > 1000 ? .red : .secondary)
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $event.description)
                        .font(.system(size: 16))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 80, maxHeight: 120)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    
                    if event.description.isEmpty {
                        Text("Tell your friends more about this event...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(event.description.count > 1000 ? Color.red : Color(.systemGray4), lineWidth: 1)
                        )
                )
                    .onChange(of: event.description) { _, newValue in
                        if newValue.count > 1000 {
                            event.description = String(newValue.prefix(1000))
                        }
                    }
            }
        }
    }
    
    // Custom binding that converts between local timezone (for DatePicker) and UTC (for storage)
    private var startDateBinding: Binding<Date> {
        Binding(
            get: { event.startDateTime.fromUTCPreservingWallClock() },
            set: { newStartTime in
                event.startDateTime = newStartTime.toUTCPreservingWallClock()
                
                // If start time is after end time, automatically update end time to 30 mins after start
                let endTimeInLocal = event.endDateTime.fromUTCPreservingWallClock()
                if newStartTime >= endTimeInLocal && !event.noEndTime {
                    let newEndTime = Calendar.current.date(byAdding: .minute, value: 30, to: newStartTime) ?? newStartTime
                    event.endDateTime = newEndTime.toUTCPreservingWallClock()
                }
            }
        )
    }
    
    private var endDateBinding: Binding<Date> {
        Binding(
            get: { event.endDateTime.fromUTCPreservingWallClock() },
            set: { event.endDateTime = $0.toUTCPreservingWallClock() }
        )
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Start Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Starts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                DatePicker("", selection: startDateBinding, displayedComponents: [.date, .hourAndMinute])
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
                    
                    DatePicker("", selection: endDateBinding, displayedComponents: [.date, .hourAndMinute])
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
            
            if inviteesUserModels.isEmpty && invitedContacts.isEmpty {
                Button {
                    showAddInviteeSheet = true
                } label: {
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
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                LazyVStack(spacing: 0) {
                    let totalItems = inviteesUserModels.count + invitedContacts.count
                    
                    ForEach(Array(inviteesUserModels.enumerated()), id: \.element) { index, invitee in
                        ModernInviteePillView(
                            viewingUser: user,
                            displayedUser: vm.getUser(by: invitee.stableIdentifier) ?? invitee,
                            invitees: $inviteesUserModels,
                            status: inviteeStatuses[invitee.stableIdentifier] ?? .invited,
                            onStatusChange: { newStatus in
                                inviteeStatuses[invitee.stableIdentifier] = newStatus
                            },
                            showStatusControls: !isNewEvent,
                            isLastItem: index == inviteesUserModels.count - 1 && invitedContacts.isEmpty
                        )
                    }
                    
                    ForEach(Array(invitedContacts.enumerated()), id: \.element.phoneNumber) { index, contact in
                        let phoneKey = canonicalPhoneNumber(contact.phoneNumber)
                        ModernContactPillView(
                            contact: contact,
                            invitedContacts: $invitedContacts,
                            status: contactStatuses[phoneKey] ?? .invited,
                            onStatusChange: { newStatus in
                                contactStatuses[phoneKey] = newStatus
                            },
                            showStatusControls: !isNewEvent,
                            isLastItem: (inviteesUserModels.count + index) == totalItems - 1
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                if isNewEvent {
                    // Reset all form fields before switching tabs
                    resetForm()
                    // When creating a new event from the tab, go back to My Events tab
                    selectedTab = 0
                } else {
                    // When editing an existing event (modal), dismiss the modal
                    dismiss()
                }
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
            
            Button {
                handleCreateEvent()
            } label: {
                HStack(spacing: 8) {
                    if isCreatingEvent {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isCreatingEvent ? (isNewEvent ? "Creating..." : "Updating...") : (isNewEvent ? "Create Event" : "Update Event"))
                        .font(.system(size: 16, weight: .semibold))
                }
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
            .disabled(isCreatingEvent)
        }
    }
    
    private func handleCreateEvent() {
        let now = Date()
        let nowUTC = now.toUTCPreservingWallClock()
        
            if event.title.count < 3 {
            alertMessage = "Event title must be at least 3 characters long"
                showAlert = true
            } else if event.location.isEmpty {
            alertMessage = "Please select a location for your event"
            showAlert = true
        } else if event.startDateTime < nowUTC {
            alertMessage = "Event start time cannot be in the past"
            showAlert = true
        } else if !event.noEndTime && event.endDateTime <= event.startDateTime {
            alertMessage = "Event end time must be after the start time"
                showAlert = true
            } else {
                Task {
                    isCreatingEvent = true
                    
                    do {
                        let temp_uuid = isNewEvent ? UUID().uuidString : event.id
                        messageEventID = temp_uuid
                        
                        var invitedUserIds: [String] = []
                        var acceptedUserIds: [String] = []
                        var declinedUserIds: [String] = []
                        
                        for user in inviteesUserModels {
                            let identifier = user.stableIdentifier
                            guard !identifier.isEmpty else { continue }
                            let status = inviteeStatuses[identifier] ?? .invited
                            switch status {
                            case .invited:
                                if !invitedUserIds.contains(identifier) {
                                    invitedUserIds.append(identifier)
                                }
                            case .accepted:
                                if !acceptedUserIds.contains(identifier) {
                                    acceptedUserIds.append(identifier)
                                }
                            case .declined:
                                if !declinedUserIds.contains(identifier) {
                                    declinedUserIds.append(identifier)
                                }
                            }
                        }
                        
                        event.attendeesInvited = invitedUserIds
                        event.attendeesAccepted = acceptedUserIds
                        event.attendeesDeclined = declinedUserIds
                        
                        var pendingNumbers: [String] = []
                        var acceptedNumbers: [String] = []
                        var declinedNumbers: [String] = []
                        
                        for contact in invitedContacts {
                            let storedNumber = canonicalPhoneNumber(contact.phoneNumber)
                            guard !storedNumber.isEmpty else { continue }
                            let status = contactStatuses[storedNumber] ?? .invited
                            switch status {
                            case .invited:
                                if !pendingNumbers.contains(storedNumber) {
                                    pendingNumbers.append(storedNumber)
                                }
                            case .accepted:
                                if !acceptedNumbers.contains(storedNumber) {
                                    acceptedNumbers.append(storedNumber)
                                }
                            case .declined:
                                if !declinedNumbers.contains(storedNumber) {
                                    declinedNumbers.append(storedNumber)
                                }
                            }
                        }
                        
                        event.invitedPhoneNumbers = pendingNumbers
                        event.acceptedPhoneNumbers = acceptedNumbers
                        event.declinedPhoneNumbers = declinedNumbers
                        
                        newPhoneNumbers = []
                        for phoneNumber in event.invitedPhoneNumbers {
                            let alreadyInvited = oldEvent.invitedPhoneNumbers.contains {
                                PhoneNumberFormatter.numbersMatch($0, phoneNumber)
                            }
                            if !alreadyInvited {
                                newPhoneNumbers.append(phoneNumber)
                            }
                        }
                        
                        // Handle Unsplash image if no user-selected image
                        var imageToUse = selectedImage
                        if selectedImage == nil, let unsplashURL = unsplashImageURL, let url = URL(string: unsplashURL) {
                            // Download and crop the Unsplash image
                            imageToUse = await downloadAndCropUnsplashImage(from: url)
                        }
                        
                        try await vm.createEventButtonPressed(eventID: temp_uuid, user: user, event: event, selectedImage: imageToUse, isNewEvent: isNewEvent, oldEvent: oldEvent)
                        try await vm.getAllEvents()
                        
                        let hasNewPhoneInvites = !newPhoneNumbers.isEmpty
                        draftEventIDForSMS = (isNewEvent && hasNewPhoneInvites) ? temp_uuid : nil
                        
                        isCreatingEvent = false
                        
                        if hasNewPhoneInvites {
                            print("MessageEventID: \(messageEventID)")
                            DispatchQueue.main.async { showMessageComposer = true }
                        } else {
                            await MainActor.run {
                                finalizeEventUI()
                            }
                        }
                    } catch {
                        isCreatingEvent = false
                        alertMessage = ErrorHandler.shared.handleError(error, operation: isNewEvent ? "Create event" : "Update event")
                        showAlert = true
                    }
                }
            }
    }
    
    private func loadExistingInvitees() {
        inviteesUserModels = []
        invitedContacts = []
        inviteeStatuses = [:]
        contactStatuses = [:]
        
        var addedIdentifiers: Set<String> = []
        let identifierGroups: [(ids: [String], status: InviteStatus)] = [
            (event.attendeesAccepted, .accepted),
            (event.attendeesInvited, .invited),
            (event.attendeesDeclined, .declined)
        ]
        
        for group in identifierGroups {
            for identifier in group.ids where !identifier.isEmpty {
                inviteeStatuses[identifier] = group.status
                guard !addedIdentifiers.contains(identifier) else { continue }
                
                if let user = vm.getUser(by: identifier) {
                    inviteesUserModels.append(user)
                } else {
                    inviteesUserModels.append(makePlaceholderUser(identifier: identifier))
                }
                addedIdentifiers.insert(identifier)
            }
        }
        
        var addedNumbers: Set<String> = []
        let phoneGroups: [(numbers: [String], status: InviteStatus)] = [
            (event.acceptedPhoneNumbers, .accepted),
            (event.invitedPhoneNumbers, .invited),
            (event.declinedPhoneNumbers, .declined)
        ]
        
        for group in phoneGroups {
            for number in group.numbers {
                let canonical = canonicalPhoneNumber(number)
                guard !canonical.isEmpty else { continue }
                contactStatuses[canonical] = group.status
                guard !addedNumbers.contains(canonical) else { continue }
                
                let contact = ContactInfo(name: number, phoneNumber: number)
                invitedContacts.append(contact)
                addedNumbers.insert(canonical)
            }
        }
    }

    private func makePlaceholderUser(identifier: String) -> UserModel {
        var placeholder = UserModel()
        placeholder.uid = identifier
        placeholder.uid = identifier
        placeholder.fullname = identifier
        placeholder.username = identifier.split(separator: "@").first.map(String.init) ?? identifier
        return placeholder
    }
    
    private func syncInviteeStatuses(oldValue: [UserModel], newValue: [UserModel]) {
        let oldIdentifiers = Set(oldValue.map { $0.stableIdentifier }.filter { !$0.isEmpty })
        let newIdentifiers = Set(newValue.map { $0.stableIdentifier }.filter { !$0.isEmpty })
        
        let added = newIdentifiers.subtracting(oldIdentifiers)
        let removed = oldIdentifiers.subtracting(newIdentifiers)
        
        for identifier in added where inviteeStatuses[identifier] == nil {
            inviteeStatuses[identifier] = .invited
        }
        
        for identifier in removed {
            inviteeStatuses.removeValue(forKey: identifier)
        }
    }
    
    private func syncContactStatuses(oldValue: [ContactInfo], newValue: [ContactInfo]) {
        let oldNumbers = Set(oldValue.map { canonicalPhoneNumber($0.phoneNumber) }.filter { !$0.isEmpty })
        let newNumbers = Set(newValue.map { canonicalPhoneNumber($0.phoneNumber) }.filter { !$0.isEmpty })
        
        let added = newNumbers.subtracting(oldNumbers)
        let removed = oldNumbers.subtracting(newNumbers)
        
        for number in added where contactStatuses[number] == nil {
            contactStatuses[number] = .invited
        }
        
        for number in removed {
            contactStatuses.removeValue(forKey: number)
        }
    }
    
    private func handleSMSSendResult(sent: Bool) async {
        if sent {
            await MainActor.run {
                finalizeEventUI()
            }
        } else {
            print("SMS composer result: Cancelled/Failed")
            
            if isNewEvent, let draftId = draftEventIDForSMS {
                await cleanupDraftEvent(eventID: draftId)
            } else {
                await MainActor.run {
                    isCreatingEvent = false
                }
            }
        }
        
        await MainActor.run {
            draftEventIDForSMS = nil
        }
    }
    
    @MainActor
    private func finalizeEventUI() {
        isCreatingEvent = false
        
        if isNewEvent {
            selectedTab = 0
            // Call the callback if provided (for AI suggestions)
            onEventCreated?()
            
            // Small delay to allow tab switch, then reset the form and view identity
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                resetForm()
            }
        } else {
            dismiss()
        }
    }
    
    private func cleanupDraftEvent(eventID: String) async {
        let firestoreService = DatabaseManager()
        
        do {
            try await firestoreService.deleteEventFromFirestore(id: eventID)
            await MainActor.run {
                vm.deleteEvent(event_id: eventID)
                isCreatingEvent = false
            }
            print("Draft event \(eventID) deleted after SMS cancellation.")
        } catch {
            print("Failed to delete draft event \(eventID): \(error.localizedDescription)")
            await MainActor.run {
                isCreatingEvent = false
            }
        }
    }
    
    private func resetForm() {
        event = EventModel()
        inviteesUserModels = []
        invitedContacts = []
        inviteeStatuses = [:]
        contactStatuses = [:]
        imageSelection = nil
        selectedImage = nil
        tempSelectedImage = nil
        newPhoneNumbers = []
        oldEvent = EventModel()
        viewIdentityID = UUID().uuidString
        messageEventID = ""
        draftEventIDForSMS = nil
    }
    
    private func canonicalPhoneNumber(_ number: String) -> String {
        let trimmed = number.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        if trimmed.hasPrefix("+") {
            return PhoneNumberFormatter.e164(trimmed)
        }
        
        if trimmed.hasPrefix("00") {
            let withoutPrefix = "+" + trimmed.dropFirst(2)
            return PhoneNumberFormatter.e164(withoutPrefix)
        }
        
        let digits = PhoneNumberFormatter.digitsOnly(from: trimmed)
        guard !digits.isEmpty else { return "" }
        
        if digits.count >= 11 {
            return "+\(digits)"
        }
        
        return buildPhoneNumberUsingFallbackCountry(digits)
    }
    
    private func buildPhoneNumberUsingFallbackCountry(_ digits: String) -> String {
        PhoneNumberFormatter.e164(countryCode: fallbackInviteDialDigits, phoneNumber: digits)
    }
    
    private var fallbackInviteDialDigits: String {
        let dialCode = fallbackInviteDialCode
        let digits = dialCode.filter { $0.isNumber }
        return digits.isEmpty ? "1" : digits
    }
    
    private var fallbackInviteDialCode: String {
        if let userDial = inferDialCode(from: user.phoneNumber) {
            return userDial
        }
        if let regionCode = Locale.current.regionCode,
           let localeCountry = Country.byCode(regionCode) {
            return localeCountry.sanitizedDialCode
        }
        return Country.default.sanitizedDialCode
    }
    
    private func inferDialCode(from phoneNumber: String) -> String? {
        let normalized = PhoneNumberFormatter.e164(phoneNumber)
        guard normalized.hasPrefix("+"),
              let country = Country.matchCountry(forE164: normalized) else { return nil }
        return country.sanitizedDialCode
    }
    
    private func downloadAndCropUnsplashImage(from url: URL) async -> UIImage? {
        do {
            print("🖼️ Downloading Unsplash image from: \(url)")
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let downloadedImage = UIImage(data: data) else {
                print("❌ Failed to create UIImage from downloaded data")
                return nil
            }
            
            print("✅ Downloaded image size: \(downloadedImage.size)")
            
            // Crop the image to the same aspect ratio as user-selected images (16:10)
            let targetAspectRatio: CGFloat = 16.0 / 10.0
            let croppedImage = cropImageToAspectRatio(downloadedImage, aspectRatio: targetAspectRatio)
            
            print("✅ Cropped image to aspect ratio 16:10")
            return croppedImage
            
        } catch {
            print("❌ Error downloading Unsplash image: \(error)")
            return nil
        }
    }
    
    private func cropImageToAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let imageAspectRatio = image.size.width / image.size.height
        
        var cropRect: CGRect
        
        if imageAspectRatio > aspectRatio {
            // Image is wider than target - crop horizontally
            let newWidth = image.size.height * aspectRatio
            let xOffset = (image.size.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: image.size.height)
        } else {
            // Image is taller than target - crop vertically
            let newHeight = image.size.width / aspectRatio
            let yOffset = (image.size.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: image.size.width, height: newHeight)
        }
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

#Preview {
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2), event: EventModel(), isNewEvent: false, unsplashImageURL: nil)
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
                    selectLocation(suggestion.title, fullAddress: suggestion.subtitle)
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
        let locationParts = eventLocation.components(separatedBy: "||")
        let locationTitle = locationParts.first ?? eventLocation
        let locationAddress = locationParts.count > 1 ? locationParts[1] : ""
        
        return HStack {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(locationTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if !locationAddress.isEmpty {
                    Text(locationAddress)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
                
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
    
    private func selectLocation(_ title: String, fullAddress: String) {
        // Store both title and full address in a structured format
        eventLocation = "\(title)||\(fullAddress)"
        locationQuery = ""
        locationSearchHelper.suggestions = []
    }
}

// MARK: - Modern Invitee List Components

struct ModernInviteePillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    @Binding var invitees: [UserModel]
    let status: InviteStatus
    let onStatusChange: (InviteStatus) -> Void
    let showStatusControls: Bool
    let isLastItem: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            if let user = displayedUser {
                profileSection(for: user)
            }
            
            Spacer()
            
            if showStatusControls {
                statusMenu
            }
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
                
                Text(user.username.isEmpty ? "@[username not set]" : "@\(user.username)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(user.username.isEmpty ? .secondary.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var statusMenu: some View {
        Menu {
            ForEach(InviteStatus.allCases, id: \.self) { option in
                Button {
                    onStatusChange(option)
                } label: {
                    HStack {
                        Image(systemName: option.iconName)
                            .foregroundColor(option.badgeColor)
                        Text(option.displayName)
                        if option == status {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: status.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(status.badgeColor)
                .padding(4)
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

struct ModernContactPillView: View {
    let contact: ContactInfo
    @Binding var invitedContacts: [ContactInfo]
    let status: InviteStatus
    let onStatusChange: (InviteStatus) -> Void
    let showStatusControls: Bool
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
                    Text(contact.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(contact.phoneNumber)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if showStatusControls {
                statusMenu
            }
            
            Button {
                invitedContacts.removeAll { $0.phoneNumber == contact.phoneNumber }
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
    
    private var statusMenu: some View {
        Menu {
            ForEach(InviteStatus.allCases, id: \.self) { option in
                Button {
                    onStatusChange(option)
                } label: {
                    HStack {
                        Image(systemName: option.iconName)
                            .foregroundColor(option.badgeColor)
                        Text(option.displayName)
                        if option == status {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: status.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(status.badgeColor)
                .padding(4)
        }
    }
}
