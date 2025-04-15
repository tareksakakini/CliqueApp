//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import MessageUI
import ContactsUI

struct AddInviteesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var searchEntry: String = ""
    @State var user: UserModel
    
    @Binding var invitees: [UserModel]
    @Binding var selectedPhoneNumbers: [String]
    
    @State private var showContactPicker = false
    @State private var showMessageComposer = false
    @State private var selectedPhoneNumber: String?
    
    @State private var showNumberSelection = false
    @State private var phoneOptions: [String] = []
    
    let sample_event_id: String = "74641C1B-E210-4FF7-AB88-AF5D563A4A36"
    
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                header
                
                HStack {
                    Button(action: {
                        showContactPicker = true
                    }) {
                        Text("Not a user?")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .underline()
                            .font(.title3)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                
                
                TextField("", text: $searchEntry, prompt: Text("Search for friends to invite ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding()
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .foregroundStyle(.black)
                
                
                
                ScrollView {
                    
                    ForEach(ud.stringMatchUsers(query: searchEntry, viewingUser: user, isFriend: true), id: \.email)
                    {user_returned in
                        if invitees.contains(user_returned) {
                            PersonPillView(
                                viewingUser: user,
                                displayedUser: user_returned,
                                personType: "requestedInvitee",
                                invitees: $invitees
                            )
                        } else {
                            PersonPillView(
                                viewingUser: user,
                                displayedUser: user_returned,
                                personType: "invitee",
                                invitees: $invitees
                            )
                        }
                    }
                    
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPicker { selectedNumbers in
                if selectedNumbers.count == 1 {
                    selectedPhoneNumber = selectedNumbers[0]
                    if let selectedPhoneNumber = selectedPhoneNumber  {
                        selectedPhoneNumbers.append(selectedPhoneNumber)
                    }
                    //showMessageComposer = true
                } else if selectedNumbers.count > 1 {
                    self.phoneOptions = selectedNumbers
                    self.showNumberSelection = true
                }
                showContactPicker = false
            }
        }
        .sheet(isPresented: $showMessageComposer) {
            if let number = selectedPhoneNumber, MFMessageComposeViewController.canSendText() {
                MessageComposer(recipients: [number], body: "https://cliqueapp-3834b.web.app/?eventId=\(sample_event_id)")
            } else {
                Text("This device can't send SMS messages.")
                    .padding()
            }
        }
        .actionSheet(isPresented: $showNumberSelection) {
            ActionSheet(
                title: Text("Choose a number"),
                message: Text("This contact has multiple numbers"),
                buttons: phoneOptions.map { number in
                    .default(Text(number)) {
                        selectedPhoneNumber = number
                        selectedPhoneNumbers.append(number)
                        //showMessageComposer = true
                    }
                } + [.cancel()]
            )
        }
        .onAppear {
            Task {
                await ud.getAllUsers()
            }
            Task {
                await ud.getUserFriends(user_email: user.email)
            }
            Task {
                await ud.getUserFriendRequests(user_email: user.email)
            }
        }
    }
}

#Preview {
    AddInviteesView(user: UserData.userData[0], invitees: .constant([]), selectedPhoneNumbers: .constant([]))
        .environmentObject(ViewModel())
}

extension AddInviteesView {
    private var header: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text("Add Invitees")
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .font(.caption)
                    .frame(width: 20, height: 20)
                    .padding()
            }
        }
        .padding()
    }
}
