//
//  EventDetailView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/12/25.
//

import SwiftUI

struct EventDetailView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    
    @State private var eventImage: UIImage? = nil
    @State private var showEditView = false
    @State private var scrollOffset: CGFloat = 0
    
    private var isEventPast: Bool {
        event.startDateTime < Date()
    }
    
    private var isHost: Bool {
        event.host == user.email
    }
    
    private var isAttending: Bool {
        event.attendeesAccepted.contains(user.email)
    }
    
    private var isInvited: Bool {
        event.attendeesInvited.contains(user.email)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        customNavigationBar
                        heroImageSection
                        eventDetailsCard
                        locationCard
                        attendeesCard
                        hostCard
                        
                        if !isEventPast && !isHost {
                            actionButtonsSection
                        }
                    }
                    .padding(.bottom, 40)
                }
                .ignoresSafeArea(.container, edges: .top)
            }
            .navigationBarHidden(true)
        }
        .task {
            await loadEventImage()
        }
        .fullScreenCover(isPresented: $showEditView) {
            CreateEventView(
                user: user,
                selectedTab: .constant(0),
                event: event,
                isNewEvent: false,
                selectedImage: eventImage
            )
        }
    }
    
    // MARK: - Hero Image Section
    
    private var heroImageSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Hero Image
                Group {
                    if let eventImage {
                        Image(uiImage: eventImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                    } else if !event.eventPic.isEmpty {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color(.accent))
                            )
                    } else {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.accent).opacity(0.8),
                                Color(.accent).opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.white.opacity(0.8))
                        )
                    }
                }
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Event Title and Date
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .medium))
                            Text(vm.formatDate(date: event.startDateTime))
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.system(size: 14, weight: .medium))
                            Text(vm.formatTime(time: event.startDateTime))
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Status badge
                statusBadge
                    .padding(.trailing, 24)
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Custom Navigation Bar
    
    private var customNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground).opacity(0.9))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            if isHost && !isEventPast {
                Button(action: { showEditView = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 44)
        .padding(.top, 70)
    }
    
    // MARK: - Status Badge
    
    @ViewBuilder
    private var statusBadge: some View {
        let status: (text: String, color: Color, icon: String)? = {
            if isHost {
                return ("Host", Color(.accent), "crown.fill")
            } else if isAttending {
                return ("Attending", .green, "checkmark.circle.fill")
            } else if isInvited && !isEventPast {
                return ("Invited", .blue, "envelope.fill")
            } else if isEventPast {
                return ("Completed", .gray, "clock.fill")
            }
            return nil
        }()
        
        if let status {
            HStack(spacing: 6) {
                Image(systemName: status.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(status.text)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.9))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Event Details Card
    
    private var eventDetailsCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DATE & TIME")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(vm.formatDate(date: event.startDateTime))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(vm.formatTime(time: event.startDateTime))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if !event.noEndTime {
                            Text("- \(vm.formatTime(time: event.endDateTime))")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    Text(event.startDateTime.formatted(.dateTime.day()))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(.accent))
                    
                    Text(event.startDateTime.formatted(Date.FormatStyle().month(.abbreviated)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(.accent))
                }
                .padding(12)
                .background(Color(.accent).opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Location Card
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("LOCATION")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Text(event.location)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Host Card
    
    private var hostCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("HOST")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            if let host = vm.getUser(username: event.host) {
                HStack(spacing: 12) {
                    ProfilePictureView(user: host, diameter: 50, isPhone: false)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(host.fullname)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("@\(host.username.isEmpty ? "username" : host.username)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Attendees Card
    
    private var attendeesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("ATTENDEES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(event.attendeesAccepted.count + event.acceptedPhoneNumbers.count)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.accent))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.accent).opacity(0.1))
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 12) {
                // Accepted attendees
                ForEach(event.attendeesAccepted, id: \.self) { attendeeEmail in
                    if let attendee = vm.getUser(username: attendeeEmail) {
                        attendeeRow(user: attendee, status: .accepted)
                    }
                }
                
                // Accepted phone numbers
                ForEach(event.acceptedPhoneNumbers, id: \.self) { phoneNumber in
                    phoneAttendeeRow(phoneNumber: phoneNumber, status: .accepted)
                }
                
                // Invited attendees (only show if not past event)
                if !isEventPast {
                    ForEach(event.attendeesInvited, id: \.self) { attendeeEmail in
                        if let attendee = vm.getUser(username: attendeeEmail) {
                            attendeeRow(user: attendee, status: .invited)
                        }
                    }
                    
                    // Invited phone numbers
                    ForEach(event.invitedPhoneNumbers, id: \.self) { phoneNumber in
                        phoneAttendeeRow(phoneNumber: phoneNumber, status: .invited)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    enum AttendeeStatus {
        case accepted, invited
    }
    
    private func attendeeRow(user: UserModel, status: AttendeeStatus) -> some View {
        HStack(spacing: 12) {
            ProfilePictureView(user: user, diameter: 40, isPhone: false)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullname)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("@\(user.username.isEmpty ? "username" : user.username)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status == .accepted ? "checkmark.circle.fill" : "clock.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(status == .accepted ? .green : .orange)
        }
    }
    
    private func phoneAttendeeRow(phoneNumber: String, status: AttendeeStatus) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.accent).opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.accent))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phoneNumber)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("Phone Contact")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status == .accepted ? "checkmark.circle.fill" : "clock.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(status == .accepted ? .green : .orange)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if inviteView && isInvited {
                // Accept/Decline buttons for invites
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await vm.acceptButtonPressed(user: user, event: event)
                            await vm.getAllEvents()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Accept")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        Task {
                            await vm.declineButtonPressed(user: user, event: event)
                            await vm.getAllEvents()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Decline")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(.accent))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.accent), lineWidth: 2)
                        )
                        .cornerRadius(16)
                    }
                }
            } else if isAttending {
                // Leave event button
                Button(action: {
                    Task {
                        await vm.leaveButtonPressed(user: user, event: event)
                        await vm.getAllEvents()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Leave Event")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.red, lineWidth: 2)
                    )
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
    
    // MARK: - Helper Functions
    
    private func loadEventImage() async {
        guard !event.eventPic.isEmpty,
              let url = URL(string: event.eventPic) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    eventImage = image
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    EventDetailView(
        event: UserData.eventData[0],
        user: UserData.userData[0],
        inviteView: false
    )
    .environmentObject(ViewModel())
}