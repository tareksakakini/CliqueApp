//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyInvitesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var enteredName: String
    @State var enteredEmail: String
    @State var landing_background_color: Color
    
    var body: some View {
        
        ZStack {
            landing_background_color.ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    ForEach(ud.getInvites(username: enteredName), id: \.self) {event in
                        EventPillView(
                            landing_background_color: landing_background_color,
                            eventName: event.title,
                            eventLocation: event.location,
                            eventDate: event.date,
                            eventTime: event.time
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    var name: String = "tareksakakini"
    var email: String = "john@example.com"
    var main_color: Color = Color(#colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1))
    MyInvitesView(enteredName: name, enteredEmail: email, landing_background_color: main_color)
        .environmentObject(ViewModel())
}

extension MyInvitesView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("My Invites")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Circle()
                .frame(width: 25, height: 25)
                .foregroundColor(.white)
            
            Text(enteredName)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
