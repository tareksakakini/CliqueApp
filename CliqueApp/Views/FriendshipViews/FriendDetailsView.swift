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
            .padding(.top, 10)
        }
    }
    
    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Profile Section
                profileSection
                
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
                                .fill(Color.black)
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
                        .fill(Color.black)
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
}

// MARK: - Friends List View

struct FriendsFriendsListView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    let friend: UserModel
    let friendsList: [String]
    
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
                                    FriendListItemView(friend: friendUser)
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
        }
    }
}

// MARK: - Friend List Item View

struct FriendListItemView: View {
    let friend: UserModel
    
    var body: some View {
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