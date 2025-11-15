import SwiftUI

struct PersonPillView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let viewingUser: UserModel?
    let displayedUser: UserModel?
    let personType: String // ["friend", "stranger", "invitee", "invited", "requester"]
    @Binding var invitees: [UserModel]
    
    var body: some View {
        HStack {
            if let user = displayedUser {
                profileSection(for: user)
            }
            Spacer()
            actionButtons()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
    }
}

// MARK: - Subviews & Logic
private extension PersonPillView {
    
    func profileSection(for user: UserModel) -> some View {
        HStack {
            ProfilePictureView(user: user, diameter: 50, isPhone: false)
                .padding(.leading)
            
            VStack(alignment: .leading) {
                Text(user.fullname)
                    .foregroundColor(Color(.accent))
                    .font(.title3)
                    .bold()
                
                Text(user.uid)
                    .foregroundColor(Color.gray)
                    .font(.caption)
                    .bold()
            }
            .padding(.leading, 5)
        }
    }
    
    @ViewBuilder
    func actionButtons() -> some View {
        switch personType {
        case "friend":
            removeFriendButton()
            
        case "requestedFriend":
            statusTextButton(text: "Sent")
            
        case "requestedInvitee":
            removeInviteeButton()
            
        case "requester":
            acceptRejectButtons()
            
        case "stranger":
            sendFriendRequestButton()
            
        case "invitee":
            addInviteeButton()
            
        case "invited":
            invitedRemoveButton()
            
        default:
            EmptyView()
        }
    }
    
    func removeFriendButton() -> some View {
        Button {
            guard let displayed = displayedUser,
                  let viewing = viewingUser else { return }
            Task {
                do {
                    try await DatabaseManager().updateFriends(viewing_user: viewing.uid, viewed_user: displayed.uid, action: "remove")
                    try await vm.getUserFriends(userId: viewing.uid)
                } catch {
                    print("Failed to remove friendship: \(error.localizedDescription)")
                }
            }
        } label: {
            Image(systemName: "minus.circle")
                .padding()
        }
    }
    
    func statusTextButton(text: String) -> some View {
        Text(text)
            .foregroundColor(.white)
            .bold()
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.accent))
            .cornerRadius(10)
            .padding()
    }
    
    func removeInviteeButton() -> some View {
        Button {
            guard let user = displayedUser else { return }
            invitees.removeAll { $0 == user }
        } label: {
            statusTextButton(text: "Invited")
        }
    }
    
    func acceptRejectButtons() -> some View {
        HStack {
            Button {
                guard let displayed = displayedUser,
                      let viewing = viewingUser else { return }
                Task {
                    do {
                        let db = DatabaseManager()
                        try await db.updateFriends(viewing_user: viewing.uid, viewed_user: displayed.uid, action: "add")
                        try await vm.getUserFriends(userId: viewing.uid)
                        try await vm.getUserFriendRequests(userId: viewing.uid)
                        
                        // Update badge for the user who accepted
                        await BadgeManager.shared.updateBadge(for: viewing.uid)
                        
                        // Send notification with badge to the user who sent the request
                        let route = NotificationRouteBuilder.friends(section: .friends)
                        await sendPushNotificationWithBadge(notificationText: "\(viewing.fullname) just accepted your friend request!",
                                                            receiverUID: displayed.uid,
                                                            route: route)
                    } catch {
                        print("Failed to accept friend request: \(error.localizedDescription)")
                    }
                }
            } label: {
                Image(systemName: "checkmark.square.fill")
                    .resizable()
                    .foregroundColor(Color(.accent))
                    .frame(width: 35, height: 35)
            }
            .cornerRadius(5)
            
            Button {
                guard let displayed = displayedUser,
                      let viewing = viewingUser else { return }
                Task {
                    do {
                        try await DatabaseManager().removeFriendRequest(sender: displayed.uid, receiver: viewing.uid)
                        try await vm.getUserFriends(userId: viewing.uid)
                        try await vm.getUserFriendRequests(userId: viewing.uid)
                        
                        // Update badge for the user who rejected
                        await BadgeManager.shared.updateBadge(for: viewing.uid)
                    } catch {
                        print("Failed to reject friend request: \(error.localizedDescription)")
                    }
                }
            } label: {
                Image(systemName: "xmark.square.fill")
                    .resizable()
                    .foregroundColor(.red.opacity(0.75))
                    .frame(width: 35, height: 35)
            }
            .cornerRadius(5)
            .padding(.trailing)
        }
    }
    
    func sendFriendRequestButton() -> some View {
        Button {
            guard let displayed = displayedUser,
                  let viewing = viewingUser else { return }
            Task {
                do {
                    let db = DatabaseManager()
                    try await db.sendFriendRequest(sender: viewing.uid, receiver: displayed.uid)
                    try await vm.getUserFriendRequestsSent(userId: viewing.uid)
                    
                    // Send notification with badge to the receiver
                    let route = NotificationRouteBuilder.friends(section: .requests)
                    await sendPushNotificationWithBadge(notificationText: "\(viewing.fullname) just sent you a friend request!",
                                                        receiverUID: displayed.uid,
                                                        route: route)
                } catch {
                    print("Friend Request Failed: \(error.localizedDescription)")
                }
            }
        } label: {
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(.accent))
                .frame(width: 25, height: 25)
                .padding()
        }
    }
    
    func addInviteeButton() -> some View {
        Button {
            guard let user = displayedUser, !invitees.contains(user) else { return }
            invitees.append(user)
        } label: {
            Image(systemName: "plus")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(.accent))
                .frame(width: 25, height: 25)
                .padding()
        }
    }
    
    func invitedRemoveButton() -> some View {
        Button {
            guard let user = displayedUser else { return }
            invitees.removeAll { $0 == user }
        } label: {
            Image(systemName: "minus.circle")
                .foregroundColor(Color(.accent))
                .padding()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.accent).ignoresSafeArea()
        PersonPillView(
            viewingUser: UserData.userData[0],
            displayedUser: UserData.userData[0],
            personType: "requester",
            invitees: .constant([])
        )
    }
}
