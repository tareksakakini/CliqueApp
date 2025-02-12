//
//  CreateEventView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/31/25.
//

import SwiftUI

struct CreateEventView: View {
    @EnvironmentObject private var ud: ViewModel
    
    @State var createEventSuccess: Bool = false
    @State var addInviteeSheet: Bool = false
    
    @State var user: UserModel
    @Binding var selectedTab: Int
    @State var event_title: String = ""
    @State var event_location: String = ""
    @State var event_dateTime: Date = Date()
    @State var invitees: [String] = []
    
    var body: some View {
        
        ZStack {
            Color.accentColor.ignoresSafeArea()
            
            VStack {
                
                header
                
                Spacer()
                
                ScrollView() {
                    
                    event_fields
                    
                    
                    
                }
                
                Spacer()
                
                create_button
                
                Spacer()
                
            }
        }
    }
}

#Preview {
    CreateEventView(user: UserData.userData[0], selectedTab: .constant(2))
        .environmentObject(ViewModel())
}

extension CreateEventView {
    
    private var create_button: some View {
        
        Button {
            ud.createEvent(title: event_title, location: event_location, dateTime: event_dateTime, user: user, invitees: invitees)
            selectedTab = 0
            
        } label: {
            Text("Create Event")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color.accentColor)
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("New Event")
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
    
    private var event_fields: some View {
        
        VStack(alignment: .leading) {
            
            Text("Event Title")
                .padding(.top, 30)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("Enter title here ...", text: $event_title)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Location")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("Enter location here ...", text: $event_location)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Text("Date and Time")
                .padding(.top, 15)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            DatePicker("", selection: $event_dateTime, displayedComponents: [.date, .hourAndMinute])
                .foregroundColor(.white)
                .labelsHidden()
                .tint(.white)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)
            
            HStack {
                Text("Invitees")
                
                Button {
                    addInviteeSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .sheet(isPresented: $addInviteeSheet) {
                    AddInviteesView(user: user, invitees: $invitees)
                        .presentationDetents([.fraction(0.9)])
                }
            }
            .padding(.top, 15)
            .padding(.leading, 25)
            .font(.title2)
            .foregroundColor(.white)
            
            ForEach(invitees, id: \.self) { invitee in
                let inviteeUser = ud.getUser(username: invitee)
                InviteePillView(user: inviteeUser, invitees: $invitees)
            }
        }
        
    }
}
