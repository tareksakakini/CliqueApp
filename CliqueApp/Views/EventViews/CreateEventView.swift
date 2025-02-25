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
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                HeaderView(user: user, title: "New Event")
                
                Spacer()
                
                ScrollView() {
                    
                    event_fields
                    
                    
                    
                }
                
                Spacer()
                
                create_button
                
                Spacer()
                
            }
        }
        .onAppear {
            Task {
                await ud.getAllUsers()
            }
            Task {
                await ud.getUserFriends(user_email: user.email)
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
            Task {
                do {
                    let firestoreService = DatabaseManager()
                    try await firestoreService.addEventToFirestore(id: UUID().uuidString, title: event_title, location: event_location, dateTime: event_dateTime, attendeesAccepted: [user.email], attendeesInvited: invitees)
                    event_title = ""
                    event_location = ""
                    event_dateTime = Date()
                    invitees = []
                } catch {
                    print("Failed to add event: \(error.localizedDescription)")
                }
            }
            selectedTab = 0
            
        } label: {
            Text("Create Event")
                .padding()
                .padding(.horizontal)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
    }
    
    private var event_fields: some View {
        
        VStack(alignment: .leading) {
            
            Text("Event Title")
                .padding(.top, 30)
                .padding(.leading, 25)
                .font(.title2)
                .foregroundColor(.white)
            
            TextField("", text: $event_title, prompt: Text("Enter your event title here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
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
            
            TextField("", text: $event_location, prompt: Text("Enter your event location here ...").foregroundColor(Color.black.opacity(0.5)))
                .foregroundColor(.black)
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
                PersonPillView(
                    viewing_user: user,
                    displayed_user: inviteeUser,
                    personType: "invited",
                    invitees: $invitees
                )
            }
        }
        
    }
}
