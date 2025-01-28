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
    
    var body: some View {
        TabView {
            MyEventsView(user: user)
                .tabItem {
                    Image(systemName: "shareplay")
                    Text("My Events")
                }
            
            MyInvitesView(user: user)
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Invites")
                }
            
            MyFriendsView(user: user)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("My Friends")
                }
            
            MySettingsView(user: user)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    //                          "gear")
                    Text("My Settings")
                }
            
        }
        .navigationBarHidden(true)
        .accentColor(Color.accentColor)
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
