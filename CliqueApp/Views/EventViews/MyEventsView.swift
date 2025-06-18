//
//  MyEventsView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyEventsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    let isInviteView: Bool
    
    @State private var selectedEventType: EventType = .upcoming
    
    enum EventType: String, CaseIterable {
        case upcoming = "Upcoming"
        case past = "Past"
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
                
                ProfilePictureView(user: user, diameter: 50, isPhone: false, isViewingUser: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var eventToggleSection: some View {
        HStack(spacing: 0) {
            ForEach(EventType.allCases, id: \.self) { eventType in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedEventType = eventType
                    }
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
                        ForEach(filteredEvents, id: \.self) { event in
                            ModernEventPillView(
                                event: event,
                                user: user,
                                inviteView: isInviteView
                            )
                        }
                    }
                    .id(selectedEventType)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.getAllEvents()
        }
    }
    
    private var filteredEvents: [EventModel] {
        let allEvents = vm.events.filter { event in
            let checklist = isInviteView ? event.attendeesInvited : event.attendeesAccepted + [event.host]
            return checklist.contains(user.email)
        }
        
        let now = Date()
        
        switch selectedEventType {
        case .upcoming:
            return allEvents
                .filter { $0.startDateTime >= now }
                .sorted { $0.startDateTime < $1.startDateTime }
        case .past:
            return allEvents
                .filter { $0.startDateTime < now }
                .sorted { $0.startDateTime > $1.startDateTime }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: selectedEventType == .upcoming ? "calendar.badge.plus" : "calendar.badge.clock")
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
            
            if selectedEventType == .upcoming {
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
    
    private var emptyStateTitle: String {
        if isInviteView {
            return selectedEventType == .upcoming ? "No Pending Invites" : "No Past Invites"
        } else {
            return selectedEventType == .upcoming ? "No Upcoming Events" : "No Past Events"
        }
    }
    
    private var emptyStateSubtitle: String {
        if isInviteView {
            return selectedEventType == .upcoming 
                ? "Event invitations will appear here when you receive them"
                : "Your past event invitations will be shown here"
        } else {
            return selectedEventType == .upcoming 
                ? "Your upcoming events will appear here. Create your first event or accept invitations to get started!"
                : "Events you've attended will be shown here"
        }
    }
}

// MARK: - Modern Event Pill View

struct ModernEventPillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    
    @State private var showSheet: Bool = false
    @State private var eventImage: UIImage? = nil
    
    var body: some View {
        Button(action: {
            showSheet = true
        }) {
            VStack(spacing: 0) {
                // Event Image
                eventImageSection
                
                // Event Info
                eventInfoSection
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showSheet) {
            EventResponseView(
                user: user,
                event: event,
                inviteView: inviteView,
                isPresented: $showSheet,
                eventImage: $eventImage
            )
            .presentationDetents([.fraction(0.5)])
        }
        .task {
            await loadEventImage(imageUrl: event.eventPic)
        }
    }
    
    private var eventImageSection: some View {
        Group {
            if event.eventPic.isEmpty {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.accent).opacity(0.8),
                            Color(.accent).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .frame(height: 140)
            } else if let eventImage {
                Image(uiImage: eventImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipped()
            } else {
                ZStack {
                    Color(.systemGray5)
                    ProgressView()
                        .tint(Color(.accent))
                }
                .frame(height: 140)
            }
        }
    }
    
    private var eventInfoSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(event.location)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(vm.formatDate(date: event.startDateTime))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.accent))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(vm.formatTime(time: event.startDateTime))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Event status indicator for past events
            if event.startDateTime < Date() {
                HStack {
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .padding(20)
    }
    
    private func loadEventImage(imageUrl: String) async {
        guard !imageUrl.isEmpty, let url = URL(string: imageUrl) else { return }
        
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
    MyEventsView(user: UserData.userData[0], isInviteView: false)
        .environmentObject(ViewModel())
}
