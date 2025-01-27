//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct MyEventsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    @State var enteredName: String
    @State var enteredEmail: String
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                
                header
                
                ScrollView {
                    ForEach(ud.getEvents(username: enteredName), id: \.self) {event in
                        EventPillView(
                            event: event
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
    MyEventsView(enteredName: name, enteredEmail: email)
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
