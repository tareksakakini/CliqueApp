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
    
    @State private var currentEvent: EventModel
    @State private var eventImage: UIImage? = nil
    @State private var showEditView = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showDeleteConfirmation = false
    @State private var showDeclineConfirmation = false
    @State private var showLeaveConfirmation = false
    @State private var isAcceptingInvite = false
    @State private var isAcceptingDeclinedInvite = false
    @State private var isDecliningInvite = false
    @State private var isLeavingEvent = false
    @State private var isDeletingEvent = false
    @State private var selectedAttendee: UserModel? = nil
    @State private var showAttendeeProfile = false
    
    init(event: EventModel, user: UserModel, inviteView: Bool) {
        self.event = event
        self.user = user
        self.inviteView = inviteView
        self._currentEvent = State(initialValue: event)
    }
    
    private var isEventPast: Bool {
        currentEvent.startDateTime < Date()
    }
    
    private var isHost: Bool {
        currentEvent.host == user.email
    }
    
    private var isAttending: Bool {
        currentEvent.attendeesAccepted.contains(user.email)
    }
    
    private var isInvited: Bool {
        currentEvent.attendeesInvited.contains(user.email)
    }
    
    private var hasDeclined: Bool {
        currentEvent.attendeesDeclined.contains(user.email)
    }
    
    private var durationText: String {
        let duration = vm.calculateDuration(startDateTime: currentEvent.startDateTime, endDateTime: currentEvent.endDateTime)
        
        if duration.days > 0 {
            // Duration is longer than a day
            var components: [String] = []
            components.append("\(duration.days)d")
            if duration.hours > 0 {
                components.append("\(duration.hours)h")
            }
            if duration.minutes > 0 {
                components.append("\(duration.minutes)m")
            }
            return components.joined(separator: " ")
        } else {
            // Duration is less than a day (current behavior)
            if duration.hours > 0 && duration.minutes > 0 {
                return "\(duration.hours)h \(duration.minutes)m"
            } else if duration.hours > 0 {
                return "\(duration.hours)h"
            } else {
                return "\(duration.minutes)m"
            }
        }
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
                        locationCard
                        
                        if !currentEvent.description.isEmpty {
                            descriptionCard
                        }
                        
                        inviteesCard
                        hostCard
                        
                        if !isEventPast && !isHost {
                            actionButtonsSection
                        }
                        
                        if isHost {
                            deleteButtonSection
                        }
                    }
                    .padding(.bottom, 40)
                }
                .refreshable {
                    await refreshEventData()
                }
                .clipped()
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .navigationBarHidden(true)
        }
        .task {
            await refreshEventData()
            await loadEventImage()
        }
        .fullScreenCover(isPresented: $showEditView, onDismiss: {
            Task {
                await refreshEventData()
                await loadEventImage()
            }
        }) {
            CreateEventView(
                user: user,
                selectedTab: .constant(0),
                event: currentEvent,
                isNewEvent: false,
                selectedImage: eventImage
            )
        }
        .sheet(isPresented: $showAttendeeProfile) {
            if let attendee = selectedAttendee {
                FriendDetailsView(friend: attendee, viewingUser: user)
            }
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
                    } else if !currentEvent.eventPic.isEmpty {
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
                                    Text(currentEvent.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 14)
                        Text(vm.formatDate(date: currentEvent.startDateTime))
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 14)
                        Text(vm.formatTime(time: currentEvent.startDateTime))
                            .font(.system(size: 16, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    
                    if !currentEvent.noEndTime {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 14)
                                Text(durationText)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
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
        .padding(.top, 20)
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
    

    
    // MARK: - Location Card
    
    private var locationCard: some View {
                    let locationParts = currentEvent.location.components(separatedBy: "||")
            let locationTitle = locationParts.first ?? currentEvent.location
        let locationAddress = locationParts.count > 1 ? locationParts[1] : ""
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("LOCATION")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(locationTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if !locationAddress.isEmpty {
                    Text(locationAddress)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
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
    
    // MARK: - Description Card
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("DESCRIPTION")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Text(currentEvent.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
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
            
            if let host = vm.getUser(username: currentEvent.host) {
                let isViewingUser = host.email == user.email
                
                if isViewingUser {
                    // Not clickable when viewing yourself as host
                    HStack(spacing: 12) {
                        ProfilePictureView(user: host, diameter: 50, isPhone: false)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("You")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("@\(host.username.isEmpty ? "username" : host.username)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                } else {
                    // Clickable for other users
                    Button {
                        selectedAttendee = host
                        showAttendeeProfile = true
                    } label: {
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
                    .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Invitees Card
    
    private var inviteesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.accent))
                
                Text("INVITEES")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let totalInvitees = currentEvent.attendeesAccepted.count + currentEvent.attendeesInvited.count + currentEvent.attendeesDeclined.count + currentEvent.acceptedPhoneNumbers.count + currentEvent.invitedPhoneNumbers.count + currentEvent.declinedPhoneNumbers.count
                Text("\(totalInvitees)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(.accent))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.accent).opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Coming Section
            let comingCount = currentEvent.attendeesAccepted.count + currentEvent.acceptedPhoneNumbers.count
            if comingCount > 0 {
                inviteeSectionHeader(title: "Coming", count: comingCount, color: .green)
                
                LazyVStack(spacing: 12) {
                    ForEach(currentEvent.attendeesAccepted, id: \.self) { attendeeEmail in
                        if let attendee = vm.getUser(username: attendeeEmail) {
                            attendeeRow(user: attendee, status: .coming)
                        }
                    }
                    
                    ForEach(currentEvent.acceptedPhoneNumbers, id: \.self) { phoneNumber in
                        phoneAttendeeRow(phoneNumber: phoneNumber, status: .coming)
                    }
                }
            }
            
            // Pending Section
            let pendingCount = currentEvent.attendeesInvited.count + currentEvent.invitedPhoneNumbers.count
            if pendingCount > 0 {
                inviteeSectionHeader(title: "Pending", count: pendingCount, color: .orange)
                
                LazyVStack(spacing: 12) {
                    ForEach(currentEvent.attendeesInvited, id: \.self) { attendeeEmail in
                        if let attendee = vm.getUser(username: attendeeEmail) {
                            attendeeRow(user: attendee, status: .pending)
                        }
                    }
                    
                    ForEach(currentEvent.invitedPhoneNumbers, id: \.self) { phoneNumber in
                        phoneAttendeeRow(phoneNumber: phoneNumber, status: .pending)
                    }
                }
            }
            
            // Not Coming Section
            let notComingCount = currentEvent.attendeesDeclined.count + currentEvent.declinedPhoneNumbers.count
            if notComingCount > 0 {
                inviteeSectionHeader(title: "Not Coming", count: notComingCount, color: .red)
                
                LazyVStack(spacing: 12) {
                    ForEach(currentEvent.attendeesDeclined, id: \.self) { attendeeEmail in
                        if let attendee = vm.getUser(username: attendeeEmail) {
                            attendeeRow(user: attendee, status: .notComing)
                        }
                    }
                    
                    ForEach(currentEvent.declinedPhoneNumbers, id: \.self) { phoneNumber in
                        phoneAttendeeRow(phoneNumber: phoneNumber, status: .notComing)
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
    
    private func inviteeSectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.top, 8)
    }
    
    enum AttendeeStatus {
        case coming, pending, notComing
    }
    
    private func attendeeRow(user attendee: UserModel, status: AttendeeStatus) -> some View {
        let isViewingUser = attendee.email == user.email
        
        return Group {
            if isViewingUser {
                // Not clickable when viewing yourself
                HStack(spacing: 12) {
                    ProfilePictureView(user: attendee, diameter: 40, isPhone: false)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("@\(attendee.username.isEmpty ? "username" : attendee.username)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: statusIcon(for: status))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(statusColor(for: status))
                }
            } else {
                // Clickable for other users
                Button {
                    selectedAttendee = attendee
                    showAttendeeProfile = true
                } label: {
                    HStack(spacing: 12) {
                        ProfilePictureView(user: attendee, diameter: 40, isPhone: false)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attendee.fullname)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("@\(attendee.username.isEmpty ? "username" : attendee.username)")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: statusIcon(for: status))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(statusColor(for: status))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
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
            
            Image(systemName: statusIcon(for: status))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(statusColor(for: status))
        }
    }
    
    private func statusIcon(for status: AttendeeStatus) -> String {
        switch status {
        case .coming:
            return "checkmark.circle.fill"
        case .pending:
            return "clock.circle"
        case .notComing:
            return "xmark.circle.fill"
        }
    }
    
    private func statusColor(for status: AttendeeStatus) -> Color {
        switch status {
        case .coming:
            return .green
        case .pending:
            return .orange
        case .notComing:
            return .red
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if inviteView && isInvited {
                // Accept/Decline buttons for invites
                HStack(spacing: 16) {
                    // Accept Button with Progress Indicator
                    Button(action: {
                        Task {
                            isAcceptingInvite = true
                            await vm.acceptButtonPressed(user: user, event: event)
                            await vm.getAllEvents()
                            isAcceptingInvite = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isAcceptingInvite {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
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
                    .disabled(isAcceptingInvite)
                    
                    // Decline Button with Confirmation
                    Button(action: {
                        showDeclineConfirmation = true
                    }) {
                        HStack(spacing: 8) {
                            if isDecliningInvite {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Color(.accent))
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            Text(isDecliningInvite ? "Declining..." : "Decline")
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
                    .disabled(isDecliningInvite)
                }
            } else if isAttending {
                // Leave event button
                Button(action: {
                    showLeaveConfirmation = true
                }) {
                    HStack(spacing: 8) {
                        if isLeavingEvent {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.red)
                        } else {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isLeavingEvent ? "Leaving..." : "Leave Event")
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
                .disabled(isLeavingEvent)
            } else if inviteView && hasDeclined {
                // Accept declined invite button
                Button(action: {
                    Task {
                        isAcceptingDeclinedInvite = true
                        await acceptDeclinedInvite()
                        isAcceptingDeclinedInvite = false
                    }
                }) {
                    HStack(spacing: 8) {
                        if isAcceptingDeclinedInvite {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text("Accept Invite")
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
                .disabled(isAcceptingDeclinedInvite)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .confirmationDialog(
            "Decline Invitation",
            isPresented: $showDeclineConfirmation,
            titleVisibility: .visible
        ) {
            Button("Decline", role: .destructive) {
                Task {
                    isDecliningInvite = true
                    await vm.declineButtonPressed(user: user, event: event)
                    await vm.getAllEvents()
                    isDecliningInvite = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to decline this invitation? The host will be notified.")
        }
        .confirmationDialog(
            "Leave Event",
            isPresented: $showLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave Event", role: .destructive) {
                Task {
                    isLeavingEvent = true
                    await vm.leaveButtonPressed(user: user, event: event)
                    await vm.getAllEvents()
                    
                    await MainActor.run {
                        isLeavingEvent = false
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to leave this event? The host will be notified that you can no longer attend.")
        }
    }
    
    // MARK: - Delete Button Section
    
    private var deleteButtonSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 8) {
                    if isDeletingEvent {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.red)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isDeletingEvent ? "Deleting Event..." : "Delete Event")
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
            .disabled(isDeletingEvent)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .confirmationDialog(
            "Delete Event",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Event", role: .destructive) {
                isDeletingEvent = true
                Task {
                    await deleteEvent()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone and all attendees will be notified.")
        }
    }
    
    // MARK: - Helper Functions
    
    private func acceptDeclinedInvite() async {
        do {
            let databaseManager = DatabaseManager()
            try await databaseManager.respondInvite(eventId: currentEvent.id, userId: user.email, action: "acceptDeclined")
            await vm.getAllEvents()
            
            // Send notification to host
            if let host = vm.getUser(username: currentEvent.host), currentEvent.host != user.email {
                let notificationText = "\(user.fullname) has accepted your event invitation!"
                sendPushNotification(notificationText: notificationText, receiverID: host.subscriptionId)
            }
        } catch {
            print("Failed to accept declined invite: \(error.localizedDescription)")
        }
    }
    
    private func deleteEvent() async {
        do {
            try await vm.deleteEventWithNotification(event: currentEvent, user: user)
            
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Error deleting event: \(error)")
            await MainActor.run {
                isDeletingEvent = false
            }
        }
    }
    
    private func refreshEventData() async {
        if let refreshedEvent = await vm.refreshEventById(id: event.id) {
            await MainActor.run {
                currentEvent = refreshedEvent
            }
        }
    }
    
    private func loadEventImage() async {
        guard !currentEvent.eventPic.isEmpty,
              let url = URL(string: currentEvent.eventPic) else { return }
        
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
