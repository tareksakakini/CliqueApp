//
//  FriendDetailsView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct FriendDetailsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let friend: UserModel
    let viewingUser: UserModel
    
    @State private var friendsList: [String] = []
    @State private var isLoadingFriends = false
    @State private var showFriendsList = false
    @State private var showFullSizeImage = false
    @State private var showRemoveFriendAlert = false
    @State private var showUnsendRequestAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerSection
                    profileContent
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadFriendsList()
        }
        .sheet(isPresented: $showFriendsList) {
            FriendsFriendsListView(friend: friend, friendsList: friendsList)
        }
        .sheet(isPresented: $showFullSizeImage) {
            FullSizeImageView(imageUrl: friend.profilePic)
        }
        .alert("Remove Friend", isPresented: $showRemoveFriendAlert) {
            Button("Remove", role: .destructive) {
                Task {
                    await removeFriend()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(friend.fullname) from your friends?")
        }
        .alert("Unsend Friend Request", isPresented: $showUnsendRequestAlert) {
            Button("Unsend", role: .destructive) {
                Task {
                    await unsendFriendRequest()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to unsend your friend request to \(friend.fullname)?")
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
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile Section
                profileSection
                
                // Relationship Status
                relationshipStatusCard
                
                // Details Card
                detailsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
    
    private var profileSection: some View {
        VStack(spacing: 20) {
            // Profile Picture
            Button(action: {
                if friend.profilePic != "" && friend.profilePic != "userDefault" {
                    showFullSizeImage = true
                }
            }) {
                if friend.profilePic != "" && friend.profilePic != "userDefault" {
                    AsyncImage(url: URL(string: friend.profilePic)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    ProgressView()
                                        .tint(.black.opacity(0.6))
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        case .failure(_):
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(friend.fullname.prefix(1))
                                        .font(.system(size: 48, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text(friend.fullname.prefix(1))
                                .font(.system(size: 48, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
            
            // Name and Username
            VStack(spacing: 8) {
                Text(friend.fullname)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if !friend.username.isEmpty {
                    Text("@\(friend.username)")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var detailsCard: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Profile Details")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 20) {
                // Full Name Row
                detailRow(
                    icon: "person.fill",
                    title: "Full Name",
                    value: friend.fullname,
                    isClickable: false
                ) { }
                
                Divider()
                
                // Username Row
                detailRow(
                    icon: "at",
                    title: "Username",
                    value: friend.username.isEmpty ? "Not set" : "@\(friend.username)",
                    isClickable: false
                ) { }
                
                Divider()
                
                // Friends Count Row
                detailRow(
                    icon: "person.2.fill",
                    title: "Friends",
                    value: isLoadingFriends ? "Loading..." : "\(friendsList.count) friends",
                    isClickable: !isLoadingFriends && friendsList.count > 0
                ) {
                    showFriendsList = true
                }
            }
        }
        .padding(28)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
    }
    
    private func detailRow(icon: String, title: String, value: String, isClickable: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            if isClickable {
                action()
            }
        }) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(value)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(value.contains("Not set") ? .black.opacity(0.4) : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                Spacer()
                
                if isClickable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.3))
                }
            }
        }
        .disabled(!isClickable)
    }
    
    private var relationshipStatusCard: some View {
        VStack(spacing: 16) {
            relationshipButton()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func relationshipButton() -> some View {
        let relationship = getRelationshipStatus()
        
        switch relationship {
        case .friend:
            Button(action: {
                showRemoveFriendAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Friend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(8)
            }
            
        case .requestReceived:
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await acceptFriendRequest()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                        Text("Accept")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    Task {
                        await rejectFriendRequest()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                        Text("Decline")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(8)
                }
            }
            
        case .requestSent:
            Button(action: {
                showUnsendRequestAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Request Sent")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(8)
            }
            
        case .none:
            Button(action: {
                Task {
                    await sendFriendRequest()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    Text("Add Friend")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color(.accent))
                .cornerRadius(12)
                .shadow(color: Color(.accent).opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private enum RelationshipStatus {
        case friend
        case requestReceived
        case requestSent
        case none
    }
    
    private func getRelationshipStatus() -> RelationshipStatus {
        if vm.friendship.contains(friend.email) {
            return .friend
        } else if vm.friendInviteReceived.contains(friend.email) {
            return .requestReceived
        } else if vm.friendInviteSent.contains(friend.email) {
            return .requestSent
        } else {
            return .none
        }
    }
    
    private func loadFriendsList() async {
        isLoadingFriends = true
        do {
            let fetchedFriends = try await DatabaseManager().retrieveFriends(user_email: friend.email)
            DispatchQueue.main.async {
                self.friendsList = fetchedFriends
                self.isLoadingFriends = false
            }
        } catch {
            print("Failed to load friends list: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isLoadingFriends = false
            }
        }
    }
    
    private func removeFriend() async {
        do {
            try await DatabaseManager().updateFriends(viewing_user: viewingUser.email, viewed_user: friend.email, action: "remove")
            await vm.getUserFriends(user_email: viewingUser.email)
        } catch {
            print("Failed to remove friendship: \(error.localizedDescription)")
        }
    }
    
    private func acceptFriendRequest() async {
        do {
            let db = DatabaseManager()
            try await db.updateFriends(viewing_user: viewingUser.email, viewed_user: friend.email, action: "add")
            await vm.getUserFriends(user_email: viewingUser.email)
            await vm.getUserFriendRequests(user_email: viewingUser.email)
            sendPushNotification(notificationText: "\(viewingUser.fullname) just accepted your friend request!", receiverID: friend.subscriptionId)
        } catch {
            print("Failed to accept friend request: \(error.localizedDescription)")
        }
    }
    
    private func rejectFriendRequest() async {
        do {
            try await DatabaseManager().removeFriendRequest(sender: friend.email, receiver: viewingUser.email)
            await vm.getUserFriends(user_email: viewingUser.email)
            await vm.getUserFriendRequests(user_email: viewingUser.email)
        } catch {
            print("Failed to reject friend request: \(error.localizedDescription)")
        }
    }
    
    private func unsendFriendRequest() async {
        do {
            try await DatabaseManager().removeFriendRequest(sender: viewingUser.email, receiver: friend.email)
            await vm.getUserFriendRequestsSent(user_email: viewingUser.email)
        } catch {
            print("Failed to unsend friend request: \(error.localizedDescription)")
        }
    }
    
    private func sendFriendRequest() async {
        do {
            let db = DatabaseManager()
            try await db.sendFriendRequest(sender: viewingUser.email, receiver: friend.email)
            await vm.getUserFriendRequestsSent(user_email: viewingUser.email)
            sendPushNotification(notificationText: "\(viewingUser.fullname) just sent you a friend request!", receiverID: friend.subscriptionId)
        } catch {
            print("Friend Request Failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Friends List View

struct FriendsFriendsListView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let friend: UserModel
    let friendsList: [String]
    
    @State private var selectedFriend: UserModel? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
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
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("\(friend.fullname)'s Friends")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("\(friendsList.count) friends")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Friends List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(friendsList.sorted { username1, username2 in
                                let user1 = vm.getUser(username: username1)?.fullname ?? ""
                                let user2 = vm.getUser(username: username2)?.fullname ?? ""
                                return user1.localizedCaseInsensitiveCompare(user2) == .orderedAscending
                            }, id: \.self) { friendUsername in
                                if let friendUser = vm.getUser(username: friendUsername) {
                                    FriendListItemView(
                                        friend: friendUser, 
                                        viewingUser: friend,
                                        onTap: { selectedFriend in
                                            self.selectedFriend = selectedFriend
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFriend) { friend in
                FriendDetailsView(friend: friend, viewingUser: self.friend)
            }
        }
    }
}

// MARK: - Friend List Item View

struct FriendListItemView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let friend: UserModel
    let viewingUser: UserModel
    let onTap: ((UserModel) -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?(friend)
        }) {
            HStack(spacing: 16) {
                ProfilePictureView(user: friend, diameter: 50, isPhone: false)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.fullname)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(friend.username.isEmpty ? "@username" : "@\(friend.username)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(friend.username.isEmpty ? .secondary.opacity(0.6) : .secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Full Size Image View

struct FullSizeImageView: View {
    @Environment(\.dismiss) private var dismiss
    let imageUrl: String
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.gray)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                case .failure(_):
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray.opacity(0.7))
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.gray.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    FriendDetailsView(friend: UserData.userData[1], viewingUser: UserData.userData[0])
        .environmentObject(ViewModel())
} 