//
//  MyEventsView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import Combine

struct MyEventsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    @State var user: UserModel
    let isInviteView: Bool
    @Binding var selectedTab: Int
    
    @State private var selectedEventType: EventType = .upcoming
    @State private var alertConfig: AlertConfig? = nil
    
    init(user: UserModel, isInviteView: Bool, selectedTab: Binding<Int>) {
        self.user = user
        self.isInviteView = isInviteView
        self._selectedTab = selectedTab
        // Set default tab based on view type
        self._selectedEventType = State(initialValue: isInviteView ? .pending : .upcoming)
    }
    
    enum EventType: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
        case pending = "Pending"
        case declined = "Declined"
    }
    
    private var eventTypes: [EventType] {
        return isInviteView ? [.pending, .declined] : [.upcoming, .past]
    }
    
    private var userIdentifierSet: Set<String> {
        Set(user.identifierCandidates)
    }
    
    private var userInvitePhone: String {
        user.phoneNumber
    }
    
    private func matchesUserPhone(_ list: [String]) -> Bool {
        let phone = userInvitePhone
        guard !phone.isEmpty else { return false }
        return list.contains { PhoneNumberFormatter.numbersMatch($0, phone) }
    }
    
    private func containsUser(_ identifiers: Set<String>, in list: [String]) -> Bool {
        guard !identifiers.isEmpty else { return false }
        return list.contains { identifiers.contains($0) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerSection
                    eventToggleSection
                    eventsContent
                }
            }
        }
        .alert(item: $alertConfig) { config in
            Alert(
                title: Text(config.title),
                message: Text(config.message),
                dismissButton: .default(Text("OK"))
            )
        }
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
        VStack(spacing: 16) {
            HStack {
                Text(isInviteView ? "My Invites" : "My Events")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    selectedTab = 4
                } label: {
                    ProfilePictureView(user: user, diameter: 50, isPhone: false, isViewingUser: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var eventToggleSection: some View {
        HStack(spacing: 0) {
            ForEach(eventTypes, id: \.self) { eventType in
                Button(action: {
                    selectedEventType = eventType
                }) {
                    Text(eventType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedEventType == eventType ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedEventType == eventType 
                            ? Color(.accent)
                            : Color.clear
                        )
                        .overlay(
                            Rectangle()
                                .fill(Color(.accent).opacity(0.1))
                                .opacity(selectedEventType == eventType ? 0 : 1)
                        )
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var eventsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if filteredEvents.isEmpty {
                    emptyStateView
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEvents, id: \.id) { event in
                            ModernEventPillView(
                                event: event,
                                user: user,
                                inviteView: isInviteView
                            )
                            .id("\(selectedEventType.rawValue)-\(event.id)")
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .refreshable {
            // Check if device is offline
            guard networkMonitor.isConnected else {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
                return
            }
            
            do {
                try await vm.getAllEvents()
            } catch {
                print("Failed to refresh events: \(error.localizedDescription)")
                let errorMessage = ErrorHandler.shared.handleError(error, operation: "Refresh events")
                alertConfig = AlertConfig(title: "Refresh Failed", message: errorMessage)
            }
        }
    }
    
    private var filteredEvents: [EventModel] {
        if isInviteView {
            // For invite view, filter based on pending/declined status and exclude past events
            let now = Date().toUTCPreservingWallClock()
            let identifiers = userIdentifierSet
            let phone = userInvitePhone
            
            switch selectedEventType {
            case .pending:
                return vm.events
                    .filter { event in
                        let invitedById = containsUser(identifiers, in: event.attendeesInvited)
                        let invitedByPhone = !phone.isEmpty && matchesUserPhone(event.invitedPhoneNumbers)
                        return (invitedById || invitedByPhone) && event.startDateTime >= now
                    }
                    .sorted { $0.startDateTime < $1.startDateTime }
            case .declined:
                return vm.events
                    .filter { event in
                        let declinedById = containsUser(identifiers, in: event.attendeesDeclined)
                        let declinedByPhone = !phone.isEmpty && matchesUserPhone(event.declinedPhoneNumbers)
                        return (declinedById || declinedByPhone) && event.startDateTime >= now
                    }
                    .sorted { $0.startDateTime < $1.startDateTime }
            default:
                return []
            }
        } else {
            // For events view, filter based on upcoming/past
            let identifiers = userIdentifierSet
            let allEvents = vm.events.filter { event in
                let checklist = event.attendeesAccepted + [event.host]
                return containsUser(identifiers, in: checklist)
            }
            
            let now = Date().toUTCPreservingWallClock()
            
            switch selectedEventType {
            case .upcoming:
                return allEvents
                    .filter { $0.startDateTime >= now }
                    .sorted { $0.startDateTime < $1.startDateTime }
            case .past:
                return allEvents
                    .filter { $0.startDateTime < now }
                    .sorted { $0.startDateTime > $1.startDateTime }
            default:
                return []
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: emptyStateIcon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.black.opacity(0.3))
                )
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(emptyStateSubtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            if selectedEventType == .upcoming || selectedEventType == .pending {
                Text("Pull down to refresh")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    private var emptyStateIcon: String {
        switch selectedEventType {
        case .upcoming:
            return "calendar.badge.plus"
        case .past:
            return "calendar.badge.clock"
        case .pending:
            return "envelope"
        case .declined:
            return "envelope.badge.fill"
        }
    }
    
    private var emptyStateTitle: String {
        if isInviteView {
            switch selectedEventType {
            case .pending:
                return "No Pending Invites"
            case .declined:
                return "No Declined Invites"
            default:
                return "No Invites"
            }
        } else {
            switch selectedEventType {
            case .upcoming:
                return "No Upcoming Events"
            case .past:
                return "No Past Events"
            default:
                return "No Events"
            }
        }
    }
    
    private var emptyStateSubtitle: String {
        if isInviteView {
            switch selectedEventType {
            case .pending:
                return "Event invitations will appear here when you receive them"
            case .declined:
                return "Events you've declined will be shown here"
            default:
                return "Your event invitations will appear here"
            }
        } else {
            switch selectedEventType {
            case .upcoming:
                return "Your upcoming events will appear here. Create your first event or accept invitations to get started!"
            case .past:
                return "Events you've attended will be shown here"
            default:
                return "Your events will appear here"
            }
        }
    }
}

// MARK: - Modern Event Pill View

struct ModernEventPillView: View {
    @EnvironmentObject private var vm: ViewModel
    @EnvironmentObject private var unreadStore: EventChatUnreadStore
    
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    
    @State private var showEventDetail: Bool = false
    @State private var eventImage: UIImage? = nil
    @State private var refreshedEvent: EventModel?
    @State private var pendingAutoOpenChat: Bool = false
    
    private var isEventPast: Bool {
        event.startDateTime < Date().toUTCPreservingWallClock()
    }
    
    private var unreadCount: Int {
        unreadStore.unreadCount(for: event.id, userIdentifier: user.uid)
    }
    
    private var unreadCountLabel: String {
        unreadCount > 99 ? "99+" : "\(unreadCount)"
    }
    
    private var unreadBadgeOpacity: Double {
        unreadCount == 0 ? 0.55 : 1.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            eventImageSection
            eventDetailsSection
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            presentEventDetail(autoOpenChat: false)
        }
        .fullScreenCover(isPresented: $showEventDetail) {
            if let eventToShow = refreshedEvent {
                EventDetailView(
                    event: eventToShow,
                    user: user,
                    inviteView: inviteView,
                    autoOpenChat: pendingAutoOpenChat
                )
            } else {
                EventDetailView(
                    event: event,
                    user: user,
                    inviteView: inviteView,
                    autoOpenChat: pendingAutoOpenChat
                )
            }
        }
        .onAppear {
            unreadStore.startListening(for: event.id)
        }
        .task(id: event.eventPic) {
            guard !event.eventPic.isEmpty else {
                await MainActor.run {
                    eventImage = nil
                }
                return
            }
            await loadEventImage(imageUrl: event.eventPic)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dismissPresentedEventDetails)) { _ in
            showEventDetail = false
        }
    }
    
    @ViewBuilder
    private var eventImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Image or Placeholder
            Group {
                if let eventImage {
                    Image(uiImage: eventImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                } else if !event.eventPic.isEmpty {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 150)
                        .overlay(ProgressView().tint(Color(.accent)))
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.accent).opacity(0.8), Color(.accent).opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.system(size: 50, weight: .light))
                            .foregroundColor(.white.opacity(0.8))
                    )
                }
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Event Title and Location on image
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(event.location.components(separatedBy: "||").first ?? event.location)
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
                .shadow(radius: 1)
            }
            .padding()
            
            // Date element top left
            dateElement
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Unread indicator top right
            unreadBadge
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: unreadCount)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(height: 150)
    }
    
    private var eventDetailsSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                // Time Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIME")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("\(vm.formatTime(time: event.startDateTime))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Host & Attendees
                socialSection
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var dateElement: some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let monthText = formatter.string(from: event.startDateTime).uppercased()
        
        formatter.dateFormat = "d"
        let dayText = formatter.string(from: event.startDateTime)
        
        return VStack(spacing: 2) {
            Text(monthText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(.accent))
            Text(dayText)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color.white.opacity(0.9))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
    }
    
    private var unreadBadge: some View {
        Button {
            presentEventDetail(autoOpenChat: true)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(unreadCountLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(.accent),
                                Color(.accent).opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            .opacity(unreadBadgeOpacity)
        }
        .buttonStyle(.plain)
        .contentShape(Capsule(style: .continuous))
        .accessibilityLabel(unreadCount == 0 ? "Open chat" : "Open chat, \(unreadCountLabel) unread messages")
    }
    
    private var socialSection: some View {
        HStack {
            Spacer()
            
            // Host Info
            if let host = vm.getUser(by: event.host) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("HOST")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack {
                        ProfilePictureView(user: host, diameter: 24, isPhone: false)
                        Text(host.fullname.components(separatedBy: " ").first ?? "")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    private func presentEventDetail(autoOpenChat: Bool) {
        Task {
            let freshEvent = await vm.refreshEventById(id: event.id)
            await MainActor.run {
                self.refreshedEvent = freshEvent ?? event
                self.pendingAutoOpenChat = autoOpenChat
                self.showEventDetail = true
            }
        }
    }
    
    private func loadEventImage(imageUrl: String) async {
        guard !imageUrl.isEmpty else {
            await MainActor.run {
                eventImage = nil
            }
            return
        }
        
        if let image = await EventImageCache.shared.loadImage(from: imageUrl) {
            await MainActor.run {
                eventImage = image
            }
        }
    }
}



#Preview {
    MyEventsView(user: UserData.userData[0], isInviteView: false, selectedTab: .constant(0))
        .environmentObject(ViewModel())
        .environmentObject(EventChatUnreadStore())
}
