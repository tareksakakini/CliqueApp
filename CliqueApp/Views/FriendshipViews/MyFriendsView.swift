//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyFriendsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @State private var isAddFriendSheetPresented: Bool = false
    @State private var selectedSection: FriendSection = .friends
    @State private var selectedFriend: UserModel? = nil
    
    @State var user: UserModel
    
    enum FriendSection: String, CaseIterable {
        case friends = "Friends"
        case requests = "Requests"
        case sent = "Sent"
    }
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerSection
                    friendsContent
                }
            }
        }
        .sheet(isPresented: $isAddFriendSheetPresented) {
            AddFriendView(user: user)
                .presentationDetents([.fraction(0.9)])
        }
        .sheet(item: $selectedFriend) { friend in
            FriendDetailsView(friend: friend, viewingUser: user)
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
                Text("My Friends")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    isAddFriendSheetPresented = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                        Text("Add Friend")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
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
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var friendsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Interactive Statistics Card
                interactiveStatisticsCard
                
                // Dynamic Content Section
                dynamicContentSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .refreshable {
            await vm.getAllUsers()
            await vm.getUserFriends(user_email: user.email)
            await vm.getUserFriendRequests(user_email: user.email)
            await vm.getUserFriendRequestsSent(user_email: user.email)
        }
    }
    
    private var interactiveStatisticsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Network")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Tap to filter your connections")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 20) {
                selectableStatisticItem(
                    section: .friends,
                    icon: "person.2.fill",
                    count: vm.friendship.count,
                    title: "Friends"
                )
                
                Spacer()
                
                selectableStatisticItem(
                    section: .requests,
                    icon: "envelope.fill",
                    count: vm.friendInviteReceived.count,
                    title: "Requests"
                )
                
                Spacer()
                
                selectableStatisticItem(
                    section: .sent,
                    icon: "paperplane.fill",
                    count: vm.friendInviteSent.count,
                    title: "Sent"
                )
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
    }
    
    private func selectableStatisticItem(section: FriendSection, icon: String, count: Int, title: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSection = section
            }
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(selectedSection == section ? Color(.accent) : Color(.accent).opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedSection == section ? .white : Color(.accent))
                    )
                    .scaleEffect(selectedSection == section ? 1.1 : 1.0)
                
                Text("\(count)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(selectedSection == section ? Color(.accent) : .primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedSection == section ? Color(.accent) : .secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedSection)
    }
    
    private var dynamicContentSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(selectedSection.rawValue)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            contentForSelectedSection()
        }
        .padding(.top, 8)
    }
    
    private func countForSelectedSection() -> Int {
        switch selectedSection {
        case .friends:
            return vm.friendship.count
        case .requests:
            return vm.friendInviteReceived.count
        case .sent:
            return vm.friendInviteSent.count
        }
    }
    
    @ViewBuilder
    private func contentForSelectedSection() -> some View {
        switch selectedSection {
        case .friends:
            friendsListContent()
        case .requests:
            requestsContent()
        case .sent:
            sentRequestsContent()
        }
    }
    
    @ViewBuilder
    private func friendsListContent() -> some View {
        if vm.friendship.isEmpty {
            emptyStateView(
                icon: "person.2",
                title: "No Friends Yet",
                subtitle: "Start building your network by adding friends",
                actionText: "Add Your First Friend"
            ) {
                isAddFriendSheetPresented = true
            }
        } else {
            LazyVStack(spacing: 0) {
                let sortedFriends = vm.friendship.sorted { username1, username2 in
                    let user1 = vm.getUser(username: username1)?.fullname ?? ""
                    let user2 = vm.getUser(username: username2)?.fullname ?? ""
                    return user1.localizedCaseInsensitiveCompare(user2) == .orderedAscending
                }
                ForEach(Array(sortedFriends.enumerated()), id: \.element) { index, friend_username in
                    ModernPersonPillView(
                        viewingUser: user,
                        displayedUser: vm.getUser(username: friend_username),
                        personType: "friend",
                        invitees: .constant([]),
                        isLastItem: index == sortedFriends.count - 1,
                        onTap: { person in
                            selectedFriend = person
                        }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func requestsContent() -> some View {
        if vm.friendInviteReceived.isEmpty {
            emptyStateView(
                icon: "envelope",
                title: "No Pending Requests",
                subtitle: "Friend requests will appear here when received",
                actionText: nil
            ) {
                // No action for pending requests empty state
            }
        } else {
            LazyVStack(spacing: 0) {
                let sortedRequests = vm.friendInviteReceived.sorted { username1, username2 in
                    let user1 = vm.getUser(username: username1)?.fullname ?? ""
                    let user2 = vm.getUser(username: username2)?.fullname ?? ""
                    return user1.localizedCaseInsensitiveCompare(user2) == .orderedAscending
                }
                ForEach(Array(sortedRequests.enumerated()), id: \.element) { index, request_username in
                    ModernPersonPillView(
                        viewingUser: user,
                        displayedUser: vm.getUser(username: request_username),
                        personType: "requester",
                        invitees: .constant([]),
                        isLastItem: index == sortedRequests.count - 1,
                        onTap: { person in
                            selectedFriend = person
                        }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func sentRequestsContent() -> some View {
        if vm.friendInviteSent.isEmpty {
            emptyStateView(
                icon: "paperplane",
                title: "No Sent Requests",
                subtitle: "Friend requests you send will appear here",
                actionText: "Send a Friend Request"
            ) {
                isAddFriendSheetPresented = true
            }
        } else {
            LazyVStack(spacing: 0) {
                let sortedSent = vm.friendInviteSent.sorted { username1, username2 in
                    let user1 = vm.getUser(username: username1)?.fullname ?? ""
                    let user2 = vm.getUser(username: username2)?.fullname ?? ""
                    return user1.localizedCaseInsensitiveCompare(user2) == .orderedAscending
                }
                ForEach(Array(sortedSent.enumerated()), id: \.element) { index, sent_username in
                    ModernPersonPillView(
                        viewingUser: user,
                        displayedUser: vm.getUser(username: sent_username),
                        personType: "requestedFriend",
                        invitees: .constant([]),
                        isLastItem: index == sortedSent.count - 1,
                        onTap: { person in
                            selectedFriend = person
                        }
                    )
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String, actionText: String?, action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.black.opacity(0.3))
                )
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionText = actionText {
                Button(action: action) {
                    Text(actionText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color(.accent))
                        .cornerRadius(12)
                        .shadow(color: Color(.accent).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(40)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Modern Person Pill View

struct ModernPersonPillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    let personType: String // ["friend", "stranger", "invitee", "invited", "requester", "requestedFriend"]
    @Binding var invitees: [UserModel]
    let isLastItem: Bool
    let onTap: ((UserModel) -> Void)?
    
    var body: some View {
        Button(action: {
            if let user = displayedUser {
                onTap?(user)
            }
        }) {
            HStack(spacing: 14) {
                if let user = displayedUser {
                    profileSection(for: user)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.clear)
            .contentShape(Rectangle()) // This ensures the entire area is tappable
            .overlay(
                // Bottom divider - only show if not the last item
                Group {
                    if !isLastItem {
                        Rectangle()
                            .fill(Color.black.opacity(0.12))
                            .frame(height: 1)
                            .padding(.leading, 66) // Align with text, not profile picture
                    }
                },
                alignment: .bottom
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    

}

#Preview {
    MyFriendsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}
