//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct PersonPillView: View {
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let viewing_user: UserModel?
    let displayed_user: UserModel?
    let personType: String // Possible values: ["friend", "stranger", "invitee", "invited", "requester"]
    @Binding var invitees: [UserModel]
    
    var body: some View {
        HStack {
            
            if let currentUser = displayed_user {
                
                ProfilePictureView(user: currentUser, diameter: 50, isPhone: false)
                    .padding(.leading)
                
                VStack(alignment: .leading) {
                    Text("\(currentUser.fullname)")
                        .foregroundColor(Color(.accent))
                        .font(.title3)
                        .bold()
                    
                    Text("\(currentUser.email)")
                        .foregroundColor(Color(#colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)))
                        .font(.caption)
                        .bold()
                }
                .padding(.leading, 5)
            }
            
            Spacer()
            
            if personType == "friend" {
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let databaseManager = DatabaseManager()
                                    try await databaseManager.updateFriends(viewing_user: viewing_user.email, viewed_user: displayed_user.email, action: "remove")
                                } catch {
                                    print("Failed to remove friendship: \(error.localizedDescription)")
                                }
                            }
                            ud.friendship.removeAll() { $0 == displayed_user.email }
                        }
                    }
                    
                } label: {
                    Image(systemName: "minus.circle")
                        .padding()
                }
            }
            else if personType == "requestedFriend" {
                Button {
                    
                } label: {
                    Text("Sent")
                        .foregroundColor(.white)
                }
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.accent))
                .cornerRadius(10)
                .padding()
            }
            else if personType == "requestedInvitee" {
                Button {
                    if let displayed_user = displayed_user {
                        
                        if invitees.contains(displayed_user) {
                            invitees.removeAll { $0 == displayed_user }
                        }
                    }
                } label: {
                    Text("Invited")
                        .foregroundColor(.white)
                }
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.accent))
                .cornerRadius(10)
                .padding()
            }
            else if personType == "requester" {
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let databaseManager = DatabaseManager()
                                    try await databaseManager.updateFriends(viewing_user: viewing_user.email, viewed_user: displayed_user.email, action: "add")
                                    //try await databaseManager.removeFriendRequest(sender: displayed_user.email, receiver: viewing_user.email)
                                    let notificationText: String = "\(viewing_user.fullname) just accepted your friend request!"
                                    sendPushNotification(notificationText: notificationText, receiverID: displayed_user.subscriptionId)
                                } catch {
                                    print("Failed to add friendship: \(error.localizedDescription)")
                                }
                            }
                            ud.friendInviteReceived.removeAll { $0 == displayed_user.email }
                            ud.friendship.append(displayed_user.email)
                        
                        }
                    }
                } label: {
                    Image(systemName: "checkmark.square.fill")
                        .resizable()
                        .foregroundColor(Color(.accent))
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                }
                .cornerRadius(5)
                
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let databaseManager = DatabaseManager()
                                    try await databaseManager.removeFriendRequest(sender: displayed_user.email, receiver: viewing_user.email)
                                } catch {
                                    print("Failed to reject friend request: \(error.localizedDescription)")
                                }
                            }
                            ud.friendInviteReceived.removeAll { $0 == displayed_user.email }
                        }
                    }
                } label: {
                    Image(systemName: "xmark.square.fill")
                        .resizable()
                        .foregroundColor(.red.opacity(0.75))
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                }
                .cornerRadius(5)
                .padding(.trailing)
            }
            else if personType == "stranger" {
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let firestoreService = DatabaseManager()
                                    try await firestoreService.sendFriendRequest(sender: viewing_user.email, receiver: displayed_user.email)
                                    let notificationText: String = "\(viewing_user.fullname) just sent you a friend request!"
                                    sendPushNotification(notificationText: notificationText, receiverID: "\(displayed_user.subscriptionId)")
                                    //await ud.refreshData(user_email: viewing_user.email)
                                    await ud.getUserFriendRequestsSent(user_email: viewing_user.email)
                                } catch {
                                    print("Friend Request Failed: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(.accent))
                        .font(.caption)
                        .frame(width: 25, height: 25)
                        .padding()
                        .padding(.horizontal)
                }
            }
            else if personType == "invitee" {
                Button {
                    if let displayed_user = displayed_user {
                        
                        if !invitees.contains(displayed_user) {
                            invitees += [displayed_user]
                        }
                    }
                    
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color(.accent))
                        .font(.caption)
                        .frame(width: 25, height: 25)
                        .padding()
                        .padding(.horizontal)
                }
            }
            else if personType == "invited" {
                Button {
                    if let displayed_user = displayed_user {
                        invitees.removeAll { $0 == displayed_user }
                    }
                    
                } label: {
                    Image(systemName: "minus.circle")
                        .foregroundColor(Color(.accent))
                        .padding()
                }
            }
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



#Preview {
    
    ZStack {
        Color(.accent).ignoresSafeArea()
        PersonPillView(
            viewing_user: UserData.userData[0],
            displayed_user: UserData.userData[0],
            personType: "requester",
            invitees: .constant([])
        )
    }
}
