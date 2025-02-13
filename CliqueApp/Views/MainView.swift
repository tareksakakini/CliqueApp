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
        .navigationBarHidden(true)
        .onAppear {
            // Change the background color of the TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white // Set your desired color here
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainView(user: UserData.userData[1])
        .environmentObject(ViewModel())
    
}
