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
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    let friend: UserModel
    let viewingUser: UserModel
    
    @State private var friendsList: [String] = []
    @State private var isLoadingFriends = false
    @State private var showFriendsList = false
    @State private var showFullSizeImage = false
    @State private var showActionSheet = false
    @State private var alertConfig: AlertConfig? = nil
    
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
        .confirmationDialog("", isPresented: $showActionSheet) {
            let relationship = getRelationshipStatus()
            
            switch relationship {
            case .friend:
                Button("Remove Friend", role: .destructive) {
                    Task {
                        await removeFriend()
                    }
                }
                Button("Cancel", role: .cancel) { }
                
            case .requestReceived:
                Button("Accept Friend Request") {
                    Task {
                        await acceptFriendRequest()
                    }
                }
                Button("Decline Request", role: .destructive) {
                    Task {
                        await rejectFriendRequest()
                    }
                }
                Button("Cancel", role: .cancel) { }
                
            case .requestSent:
                Button("Unsend Request", role: .destructive) {
                    Task {
                        await unsendFriendRequest()
                    }
                }
                Button("Cancel", role: .cancel) { }
                
            case .none:
                Button("Send Friend Request") {
                    Task {
                        await sendFriendRequest()
                    }
                }
                Button("Cancel", role: .cancel) { }
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
    }
    
    @ViewBuilder
    private func relationshipButton() -> some View {
        let relationship = getRelationshipStatus()
        
        switch relationship {
        case .friend:
            Button(action: {
                showActionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Friends")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
        case .requestReceived:
            Button(action: {
                showActionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 16, weight: .medium))
                    Text("Friendship Requested")
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
            
        case .requestSent:
            Button(action: {
                showActionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Pending")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
        case .none:
            Button(action: {
                showActionSheet = true
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
        // Check if device is offline
        guard networkMonitor.isConnected else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
            }
            return
        }
        
        do {
            try await DatabaseManager().updateFriends(viewing_user: viewingUser.email, viewed_user: friend.email, action: "remove")
            try await vm.getUserFriends(user_email: viewingUser.email)
        } catch {
            print("Failed to remove friendship: \(error.localizedDescription)")
            let errorMessage = ErrorHandler.shared.handleError(error, operation: "Remove friend")
            await MainActor.run {
                alertConfig = AlertConfig(title: "Operation Failed", message: errorMessage)
            }
        }
    }
    
    private func acceptFriendRequest() async {
        // Check if device is offline
        guard networkMonitor.isConnected else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
            }
            return
        }
        
        do {
            let db = DatabaseManager()
            try await db.updateFriends(viewing_user: viewingUser.email, viewed_user: friend.email, action: "add")
            try await vm.getUserFriends(user_email: viewingUser.email)
            try await vm.getUserFriendRequests(user_email: viewingUser.email)
            
            // Update badge for the user who accepted
            await BadgeManager.shared.updateBadge(for: viewingUser.uid)
            
            // Send notification with badge to the user who sent the request
            let route = NotificationRouteBuilder.friends(section: .friends)
            await sendPushNotificationWithBadge(notificationText: "\(viewingUser.fullname) just accepted your friend request!",
                                                receiverUID: friend.uid,
                                                receiverEmail: friend.email,
                                                route: route)
        } catch {
            print("Failed to accept friend request: \(error.localizedDescription)")
            let errorMessage = ErrorHandler.shared.handleError(error, operation: "Accept friend request")
            await MainActor.run {
                alertConfig = AlertConfig(title: "Operation Failed", message: errorMessage)
            }
        }
    }
    
    private func rejectFriendRequest() async {
        // Check if device is offline
        guard networkMonitor.isConnected else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
            }
            return
        }
        
        do {
            try await DatabaseManager().removeFriendRequest(sender: friend.email, receiver: viewingUser.email)
            try await vm.getUserFriends(user_email: viewingUser.email)
            try await vm.getUserFriendRequests(user_email: viewingUser.email)
            
            // Update badge for the user who rejected
            await BadgeManager.shared.updateBadge(for: viewingUser.uid)
        } catch {
            print("Failed to reject friend request: \(error.localizedDescription)")
            let errorMessage = ErrorHandler.shared.handleError(error, operation: "Decline friend request")
            await MainActor.run {
                alertConfig = AlertConfig(title: "Operation Failed", message: errorMessage)
            }
        }
    }
    
    private func unsendFriendRequest() async {
        // Check if device is offline
        guard networkMonitor.isConnected else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
            }
            return
        }
        
        do {
            try await DatabaseManager().removeFriendRequest(sender: viewingUser.email, receiver: friend.email)
            try await vm.getUserFriendRequestsSent(user_email: viewingUser.email)
        } catch {
            print("Failed to unsend friend request: \(error.localizedDescription)")
            let errorMessage = ErrorHandler.shared.handleError(error, operation: "Unsend friend request")
            await MainActor.run {
                alertConfig = AlertConfig(title: "Operation Failed", message: errorMessage)
            }
        }
    }
    
    private func sendFriendRequest() async {
        // Check if device is offline
        guard networkMonitor.isConnected else {
            await MainActor.run {
                alertConfig = AlertConfig(
                    title: "No Internet Connection",
                    message: "Your device is offline. Please check your internet connection and try again."
                )
            }
            return
        }
        
        do {
            let db = DatabaseManager()
            try await db.sendFriendRequest(sender: viewingUser.email, receiver: friend.email)
            try await vm.getUserFriendRequestsSent(user_email: viewingUser.email)
            
            // Send notification with badge to the receiver
            let route = NotificationRouteBuilder.friends(section: .requests)
            await sendPushNotificationWithBadge(notificationText: "\(viewingUser.fullname) just sent you a friend request!",
                                                receiverUID: friend.uid,
                                                receiverEmail: friend.email,
                                                route: route)
        } catch {
            print("Friend Request Failed: \(error.localizedDescription)")
            let errorMessage = ErrorHandler.shared.handleError(error, operation: "Send friend request")
            await MainActor.run {
                alertConfig = AlertConfig(title: "Operation Failed", message: errorMessage)
            }
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
                                let user1 = vm.getUser(by: username1)?.fullname ?? ""
                                let user2 = vm.getUser(by: username2)?.fullname ?? ""
                                return user1.localizedCaseInsensitiveCompare(user2) == .orderedAscending
                            }, id: \.self) { friendUsername in
                                if let friendUser = vm.getUser(by: friendUsername) {
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
                    
                    Text(friend.username.isEmpty ? "@[username not set]" : "@\(friend.username)")
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
