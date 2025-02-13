//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyEventsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var user: UserModel
    
    var body: some View {
        
        ZStack {
            
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    
                    ForEach(ud.events, id: \.self) {event in
                        if event.attendeesAccepted.contains(user.email) {
                            EventPillView(
                                event: event,
                                user: user,
                                inviteView: false
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await ud.getAllEvents()
            }
        }
    }
}

#Preview {
    MyEventsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MyEventsView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("My Events")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(user.profilePic)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.leading)
            
            Text(user.email)
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}
