//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI

struct AddInviteesView: View {
    
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    @State var user: UserModel
    @Binding var invitees: [UserModel]
    @Binding var selectedPhoneNumbers: [String]
    @State private var selectedPhoneNumber: String?
    
    @State private var searchEntry: String = ""
    @State private var showContactPicker = false
    @State private var showNumberSelection = false
    @State private var phoneOptions: [String] = []

    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "Add Invitees", navigationBinder: .constant(false), specialScreen: "AddFriendView")
                
                ShowContactsButton
                SearchField
                Results
                Spacer()
            }
        }
        .sheet(isPresented: $showContactPicker) {
            ContactSelector
        }
        .actionSheet(isPresented: $showNumberSelection) {
            ActionSheet(
                title: Text("Choose a number"),
                message: Text("This contact has multiple numbers"),
                buttons: phoneOptions.map { number in
                    .default(Text(number)) {
                        selectedPhoneNumber = number
                        selectedPhoneNumbers.append(number)
                    }
                } + [.cancel()]
            )
        }
    }
}

#Preview {
    AddInviteesView(user: UserData.userData[0], invitees: .constant([]), selectedPhoneNumbers: .constant([]))
        .environmentObject(ViewModel())
}

extension AddInviteesView {
    private var ShowContactsButton: some View {
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
    }
    
    private var SearchField: some View {
        TextField("", text: $searchEntry, prompt: Text("Search for friends to invite ...").foregroundColor(Color.black.opacity(0.5)))
            .foregroundColor(.black)
            .padding()
            .background(.white)
            .cornerRadius(10)
            .padding()
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .foregroundStyle(.black)
    }
    
    private var Results: some View {
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
    }
    
    private var ContactSelector: some View {
        ContactPicker { selectedNumbers in
            if selectedNumbers.count == 1 {
                selectedPhoneNumber = selectedNumbers[0]
                if let selectedPhoneNumber = selectedPhoneNumber  {
                    selectedPhoneNumbers.append(selectedPhoneNumber)
                }
            } else if selectedNumbers.count > 1 {
                self.phoneOptions = selectedNumbers
                self.showNumberSelection = true
            }
            showContactPicker = false
        }
    }
}
