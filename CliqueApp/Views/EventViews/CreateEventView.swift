//
//  CreateEventView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/31/25.
//

import SwiftUI
import MapKit
import PhotosUI

class LocationSearchHelper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    
    private var searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest] // Focus only on addresses
    }
    
    func updateSearchResults(for query: String) {
        searchCompleter.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.suggestions = Array(completer.results.prefix(3))
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Error fetching suggestions: \(error.localizedDescription)")
    }
}

struct CreateEventView: View {
    @EnvironmentObject private var ud: ViewModel
    
    @State var createEventSuccess: Bool = false
    @State var addInviteeSheet: Bool = false
    
    @State private var showAlertTitle: Bool = false
    @State private var showAlertLocation: Bool = false
    
    @State var user: UserModel
    @Binding var selectedTab: Int
    @State var event_title: String = ""
    @State var event_location: String = ""
    @State var event_dateTime: Date = Date()
    @State var event_duration_hours: String = ""
    @State var event_duration_minutes: String = ""
    @State var invitees: [UserModel] = []
    
    @StateObject private var locationSearchHelper = LocationSearchHelper()
    @State private var locationQuery = ""
    
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                
                HeaderView(user: user, title: "New Event")
                
                Spacer()
                
                ScrollView() {
                    
                    event_fields
                    
                    create_button
                        .padding(.vertical, 50)
                    
                }
                
                Spacer()
                
            }
            .alert("Event title has to be 3 characters or longer!", isPresented: $showAlertTitle) {
                Button("Dismiss", role: .cancel) { }
            }
            .alert("You have to select a location first!", isPresented: $showAlertLocation) {
                Button("Dismiss", role: .cancel) { }
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
        .onChange(of: imageSelection) {
            Task {
                if let imageSelection {
                    if let data = try? await imageSelection.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }
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
            if event_title.count < 3 {
                showAlertTitle = true
            } else if event_location.isEmpty {
                showAlertLocation = true
            } else {
                Task {
                    do {
                        let firestoreService = DatabaseManager()
                        var invitee_emails: [String] = []
                        for invitee in invitees{
                            invitee_emails += [invitee.email]
                        }
                        let temp_uuid = UUID().uuidString
                        try await firestoreService.addEventToFirestore(id: temp_uuid, title: event_title, location: event_location, dateTime: event_dateTime, attendeesAccepted: [], attendeesInvited: invitee_emails, host: user.email, hours: event_duration_hours, minutes: event_duration_minutes)
                        if let selectedImage {
                            await firestoreService.uploadEventImage(image: selectedImage, event_id: temp_uuid)
                        }
                        for invitee in invitees {
                            let notificationText: String = "\(user.fullname) just invited you to an event!"
                            sendPushNotification(notificationText: notificationText, receiverID: invitee.subscriptionId)
                        }
                        event_title = ""
                        event_location = ""
                        event_dateTime = Date()
                        invitees = []
                        imageSelection = nil
                        selectedImage = nil
                        print("updated tab")
                    } catch {
                        print("Failed to add event: \(error.localizedDescription)")
                    }
                }
                selectedTab = 0
            }
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
            
            if let selectedImage = selectedImage {
                PhotosPicker(selection: $imageSelection, matching: .images) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                        .cornerRadius(10)
                        .padding()
                }
                
            } else {
                PhotosPicker(selection: $imageSelection, matching: .images) {
                    ZStack {
                        Color(.white.opacity(0.7))
                        VStack {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .padding()
                            Text("Add Event Picture")
                                .bold()
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                    .cornerRadius(10)
                    .foregroundColor(Color(.accent))
                    .padding()
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
                }
            }
            
            
            
            Text("Event Title")
                //.padding(.top, 30)
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
            
            if event_location.isEmpty {
                TextField("", text: $locationQuery, prompt: Text("Enter your event location here ...").foregroundColor(Color.black.opacity(0.5)))
                    .foregroundColor(.black)
                    .padding()
                    .background(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .onChange(of: locationQuery) { newValue in
                        locationSearchHelper.updateSearchResults(for: newValue)
                    }
                
                if !locationSearchHelper.suggestions.isEmpty && !locationQuery.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(locationSearchHelper.suggestions.prefix(5).indices, id: \.self) { index in
                            let suggestion = locationSearchHelper.suggestions[index]
                            VStack(alignment: .leading) {
                                Text(suggestion.title)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text(suggestion.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            //.padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(8)
                            .onTapGesture {
                                event_location = suggestion.title
                                locationQuery = ""
                                locationSearchHelper.suggestions = [] // Hide suggestions after selection
                            }
                            
                            if index < locationSearchHelper.suggestions.count - 1 {
                                Divider()
                                    .background(Color.gray.opacity(0.5))
                            }
                        }
                    }
                    //.padding(.horizontal)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                }
                
            } else {
                HStack() {
                    Text(event_location)
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Button {
                        event_location = ""
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            
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
                Text("Duration")
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("(Optional)")
                    .padding(.top, 20)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            
            
            HStack {
                    
                Picker(
                    selection : $event_duration_hours,
                    label: Text("Hours"),
                    content: {
                        Text("").tag("")
                        ForEach(Array(0...23), id: \.self) {hour in
                            Text("\(hour) h").tag(String(hour))
                        }
                    }
                )
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.white)
                .cornerRadius(10)
            
                
                Picker(
                    selection : $event_duration_minutes,
                    label: Text("Minutes"),
                    content: {
                        Text("").tag("")
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) {minute in
                            Text("\(minute) m").tag(String(minute))
                        }
                    }
                )
                .foregroundColor(.black)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.white)
                .cornerRadius(10)
            }
            .padding(.top, 5)
            .padding(.leading)
            
            
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
                let inviteeUser = ud.getUser(username: invitee.email)
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



