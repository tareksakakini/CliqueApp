//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddFriendView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    
    @State private var searchEntry: String = ""
    @State private var selectedPerson: UserModel? = nil
    @State private var showPersonDetails = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    headerSection
                    searchContent
                }
            }
        }
        .sheet(isPresented: $showPersonDetails) {
            if let selectedPerson = selectedPerson {
                FriendDetailsView(friend: selectedPerson, viewingUser: user)
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
            
            VStack(spacing: 12) {
                Text("Add Friend")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Search for friends to connect with")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 20)
        }
    }
    
    private var searchContent: some View {
        VStack(spacing: 24) {
            searchField
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ud.stringMatchUsers(query: searchEntry, viewingUser: user), id: \.email) { user_returned in
                        if ud.friendInviteSent.contains(user_returned.email) {
                            ModernSearchPersonPillView(
                                viewingUser: user,
                                displayedUser: user_returned,
                                personType: "requestedFriend",
                                invitees: .constant([]),
                                onTap: { person in
                                    selectedPerson = person
                                    showPersonDetails = true
                                }
                            )
                        } else if user.email != user_returned.email && !ud.friendship.contains(user_returned.email) {
                            ModernSearchPersonPillView(
                                viewingUser: user,
                                displayedUser: user_returned,
                                personType: "stranger",
                                invitees: .constant([]),
                                onTap: { person in
                                    selectedPerson = person
                                    showPersonDetails = true
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
    
    private var searchField: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Search for friends...", text: $searchEntry)
                    .font(.system(size: 16, weight: .medium))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                if !searchEntry.isEmpty {
                    Button(action: {
                        searchEntry = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Modern Search Person Pill View

struct ModernSearchPersonPillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    let personType: String // ["friend", "stranger", "invitee", "invited", "requester", "requestedFriend"]
    @Binding var invitees: [UserModel]
    let onTap: ((UserModel) -> Void)?
    
    var body: some View {
        Button(action: {
            if let user = displayedUser {
                onTap?(user)
            }
        }) {
            HStack(spacing: 16) {
                if let user = displayedUser {
                    profileSection(for: user)
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
    
    private func profileSection(for user: UserModel) -> some View {
        HStack(spacing: 12) {
            ProfilePictureView(user: user, diameter: 50, isPhone: false)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullname)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(user.username.isEmpty ? "@username" : "@\(user.username)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(user.username.isEmpty ? .secondary.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }
        }
    }
    

}

#Preview {
    AddFriendView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}
