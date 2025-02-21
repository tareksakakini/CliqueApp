//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct EventPillView: View {
    @EnvironmentObject private var ud: ViewModel
    @State var showSheet: Bool = false
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    @Binding var refreshTrigger: Bool
    var body: some View {
        
        Button {
            showSheet = true
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(event.title)")
                        .foregroundColor(Color(.accent))
                        .padding(.horizontal)
                        .font(.title3)
                        .bold()
                    
                    
                    Text("\(event.location)")
                        .foregroundColor(Color(.accent))
                        .padding(.horizontal)
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(ud.formatDate(date: event.dateTime))")
                        .foregroundColor(Color(.accent))
                        .padding(.horizontal)
                        .font(.title3)
                        .bold()
                    
                    
                    Text("\(ud.formatTime(time: event.dateTime))")
                        .foregroundColor(Color(.accent))
                        .padding(.horizontal)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 70)
            .background(.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
        }
        .sheet(isPresented: $showSheet) {
            EventResponseView(user: user, event: event, inviteView: inviteView, isPresented: $showSheet, refreshTrigger: $refreshTrigger)
                .presentationDetents([.fraction(0.5)])
        }
        
    }
}


#Preview {
    ZStack {
        Color(.accent).ignoresSafeArea()
        EventPillView(
            event: UserData.eventData[0],
            user: UserData.userData[0],
            inviteView: false,
            refreshTrigger: .constant(false)
        )
        .environmentObject(ViewModel())
    }
    
}
