//
//  TabView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user: UserModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                MyEventsView(user: user)
                    .tabItem {
                        Image(systemName: "shareplay")
                        Text("My Events")
                    }
                    .tag(0)
                
                MyInvitesView(user: user)
                    .tabItem {
                        Image(systemName: "envelope.fill")
                        Text("Invites")
                    }
                    .tag(1)
                
                CreateEventView(user: user, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "plus.square.fill")
                        Text("New Event")
                    }
                    .tag(2)
                
                MyFriendsView(user: user)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("My Friends")
                    }
                    .tag(3)
                
                MySettingsView(user: user)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        //                          "gear")
                        Text("My Settings")
                    }
                    .tag(4)
                
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Change the background color of the TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white // Set your desired color here
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            Task {
                await ud.getAllUsers()
            }
            Task {
                await ud.getUserFriends(user_email: user.email)
            }
            Task {
                await ud.getUserFriendRequests(user_email: user.email)
            }
            Task {
                await ud.getAllEvents()
            }
            Task {
                await ud.getUserFriendRequestsSent(user_email: user.email)
            }
//            Task {
//                await ud.loadImage(imageUrl: user.profilePic)
//            }
            Task {
                if let playerId = await getOneSignalSubscriptionId() {
                    print("OneSignal Subscription ID: \(playerId)")
                    do {
                        let firestoreService = DatabaseManager()
                        try await firestoreService.updateUserSubscriptionId(uid: user.uid, subscriptionId: playerId)
                    } catch {
                        print("Updating subscription id failed: \(error.localizedDescription)")
                    }
                } else {
                    print("Failed to retrieve OneSignal Subscription ID.")
                }
            }
        }
        .tint(Color(.accent))
    }
}

#Preview {
    MainView(user: UserData.userData[1])
        .environmentObject(ViewModel())
    
}
