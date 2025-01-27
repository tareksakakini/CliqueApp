//
//  TabView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct MainView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var enteredName: String
    @State var enteredEmail: String
    
    var body: some View {
        TabView {
            MyEventsView(enteredName: enteredName, enteredEmail: enteredEmail)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("My Events")
                }
            
            MyInvitesView(enteredName: enteredName, enteredEmail: enteredEmail)
                .tabItem {
                    Image(systemName: "envelope.fill")
                    Text("Invites")
                }
            
            Text("My Friends")
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("My Friends")
                }
            
            Text("My Settings")
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("My Settings")
                }
            
        }
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
    var name: String = "tareksakakini"
    var email: String = "john@example.com"
    MainView(enteredName: name, enteredEmail: email)
        .environmentObject(ViewModel())
}
