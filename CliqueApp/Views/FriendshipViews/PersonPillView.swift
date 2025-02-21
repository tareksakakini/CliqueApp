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
    @Binding var invitees: [String]
    
    var body: some View {
        HStack {
            
            if let currentUser = displayed_user {
                
                Image(currentUser.profilePic)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 50)
                    .padding(.leading)
                
                VStack(alignment: .leading) {
                    Text("\(currentUser.fullname)")
                        .foregroundColor(Color(.accent))
                        .font(.title3)
                        .bold()
                    
                    Text("@\(currentUser.email)")
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
                                    try await databaseManager.removeFriends(user1: viewing_user.email, user2: displayed_user.email)
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
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .frame(height: 70)
//                .background(.white)
//                .cornerRadius(20)
//                .padding(.horizontal, 20)
//                .padding(.vertical, 5)
//                .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
            }
            else if personType == "requester" {
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let databaseManager = DatabaseManager()
                                    try await databaseManager.addFriends(user1: displayed_user.email, user2: viewing_user.email)
                                    try await databaseManager.removeFriendRequest(sender: displayed_user.email, receiver: viewing_user.email)
                                } catch {
                                    print("Failed to add friendship: \(error.localizedDescription)")
                                }
                            }
                            ud.friendInviteReceived.removeAll { $0 == displayed_user.email }
                            ud.friendship.append(displayed_user.email)
                        
                        }
                    }
                } label: {
                    Text("Accept")
                }
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.green.opacity(0.6))
                .cornerRadius(10)
                .padding()
            }
            else if personType == "stranger" {
                Button {
                    if let displayed_user = displayed_user {
                        if let viewing_user = viewing_user {
                            Task {
                                do {
                                    let firestoreService = DatabaseManager()
                                    try await firestoreService.sendFriendRequest(sender: viewing_user.email, receiver: displayed_user.email)
                                } catch {
                                    print("Friend Request Failed: \(error.localizedDescription)")
                                }
                            }
                            dismiss()
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
                        
                        invitees += [displayed_user.email]
                        dismiss()
                        
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
                        invitees.removeAll { $0 == displayed_user.email }
                    }
                    
                } label: {
                    Image(systemName: "minus.circle")
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
    // Define the button closure separately
    let exampleButton: () -> some View = {
        AnyView(
            Button("Tap Me") {
                print("Button tapped!")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        )
    }
    
    ZStack {
        Color(.accent).ignoresSafeArea()
        PersonPillView(
            viewing_user: UserData.userData[0],
            displayed_user: UserData.userData[0],
            personType: "friend",
            invitees: .constant([])
        )
    }
}
