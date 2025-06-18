//
//  AddInviteesView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddInviteesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    @Binding var invitees: [UserModel]
    @Binding var selectedPhoneNumbers: [String]
    @State private var selectedPhoneNumber: String?
    
    @State private var searchEntry: String = ""
    @State private var showContactPicker = false
    @State private var showNumberSelection = false
    @State private var phoneOptions: [String] = []

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
        .sheet(isPresented: $showContactPicker) {
            ContactSelector
        }
        .actionSheet(isPresented: $showNumberSelection) {
            ActionSheet(
                title: Text("Choose a number"),
                message: Text("This contact has multiple numbers"),
                buttons: phoneOptions.map { number in
                    .default(Text(number)) {
                        selectedPhoneNumber = number
                        selectedPhoneNumbers.append(number)
                    }
                } + [.cancel()]
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
                Text("Add Invitees")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.secondary)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Contact picker button
            HStack {
                Button(action: {
                    showContactPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Not a user? Add by phone")
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
                
                Spacer()
            }
            .padding(20)
        }
    }
    
    private var searchContent: some View {
        VStack(spacing: 32) {
            searchField
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    let filteredUsers = ud.stringMatchUsers(query: searchEntry, viewingUser: user, isFriend: true)
                    ForEach(Array(filteredUsers.enumerated()), id: \.element.email) { index, user_returned in
                        ModernInviteeSearchPillView(
                            viewingUser: user,
                            displayedUser: user_returned,
                            personType: invitees.contains(user_returned) ? "requestedInvitee" : "invitee",
                            invitees: $invitees,
                            isLastItem: index == filteredUsers.count - 1
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
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
                
                TextField("Search for friends to invite...", text: $searchEntry)
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
    
    private var ContactSelector: some View {
        ContactPicker { selectedNumbers in
            if selectedNumbers.count == 1 {
                selectedPhoneNumber = selectedNumbers[0]
                if let selectedPhoneNumber = selectedPhoneNumber  {
                    selectedPhoneNumbers.append(selectedPhoneNumber)
                }
            } else if selectedNumbers.count > 1 {
                self.phoneOptions = selectedNumbers
                self.showNumberSelection = true
            }
            showContactPicker = false
        }
    }
}

// MARK: - Modern Invitee Search Pill View

struct ModernInviteeSearchPillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    let personType: String // ["invitee", "requestedInvitee"]
    @Binding var invitees: [UserModel]
    let isLastItem: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            if let user = displayedUser {
                profileSection(for: user)
            }
            
            Spacer()
            
            actionButton
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
                
                Text(user.username.isEmpty ? "@username" : "@\(user.username)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(user.username.isEmpty ? .secondary.opacity(0.6) : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch personType {
        case "requestedInvitee":
            Button {
                guard let user = displayedUser else { return }
                invitees.removeAll { $0 == user }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(.accent))
            }
            
        case "invitee":
            Button {
                guard let user = displayedUser, !invitees.contains(user) else { return }
                invitees.append(user)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(.systemGray))
            }
            
        default:
            EmptyView()
        }
    }
}

#Preview {
    AddInviteesView(user: UserData.userData[0], invitees: .constant([]), selectedPhoneNumbers: .constant([]))
        .environmentObject(ViewModel())
}
