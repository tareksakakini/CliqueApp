//
//  CliqueAppApp.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI


@main
struct CliqueAppApp: App {
    
    @StateObject private var ud = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ud)
        }
    }
}
