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
    @State var landing_background_color: Color
    
    var body: some View {
        TabView {
            MyEventsView(enteredName: enteredName, enteredEmail: enteredEmail, landing_background_color: landing_background_color)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("My Events")
                }
            
            MyInvitesView(enteredName: enteredName, enteredEmail: enteredEmail, landing_background_color: landing_background_color)
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
        .accentColor(landing_background_color)
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
    var main_color: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    MainView(enteredName: name, enteredEmail: email, landing_background_color: main_color)
        .environmentObject(ViewModel())
}
