//
//  TabView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel
    @State var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                MyEventsView(user: user, isInviteView: false)
                    .tabItem {
                        Image(systemName: "shareplay")
                        Text("My Events")
                    }
                    .tag(0)
                
                MyEventsView(user: user, isInviteView: true)
                    .tabItem {
                        Image(systemName: "envelope.fill")
                        Text("Invites")
                    }
                    .tag(1)
                
                CreateEventView(user: user, selectedTab: $selectedTab, event: EventModel(), isNewEvent: true)
                    .tabItem {
                        Image(systemName: "plus.square.fill")
                        Text("New Event")
                    }
                    .tag(2)
                
                MyFriendsView(user: user)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Friends")
                    }
                    .tag(3)
                
                MySettingsView(user: user)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(4)
                
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.refreshData(user_email: user.email)
            
            print("📱 MainView loaded for user: \(user.uid)")
            
            // CRITICAL: Ensure OneSignal is properly configured for this user
            print("🔍 Checking OneSignal configuration...")
            if !isOneSignalConfiguredForUser(expectedUserID: user.uid) {
                print("❌ OneSignal not properly configured, fixing...")
                // Clear any wrong association first
                await clearOneSignalForUser()
                await setupOneSignalForUser(userID: user.uid)
                
                // Verify it worked
                let verified = await verifyOneSignalState(expectedUserID: user.uid)
                if !verified {
                    print("⚠️ CRITICAL: OneSignal setup still failed in MainView!")
                }
            } else {
                print("✅ OneSignal correctly configured")
            }
            
            await vm.updateOneSignalSubscriptionId(user: user)
            await vm.loadProfilePic(imageUrl: user.profilePic)
        }
        .onAppear {
            // Change the background color of the TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .tint(Color(.accent))
    }
}

#Preview {
    MainView(user: UserData.userData[1])
        .environmentObject(ViewModel())
    
}
