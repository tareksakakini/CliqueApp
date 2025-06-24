//
//  AISuggestionsView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/13/25.
//

import SwiftUI

struct AISuggestionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var vm: ViewModel
    
    let user: UserModel
    @Binding var selectedTab: Int
    let suggestions: [EventSuggestion]
    
    @State private var currentSuggestionIndex: Int = 0
    @State private var event: EventModel = EventModel()
    @State private var selectedImage: UIImage? = nil
    
    private var currentSuggestion: EventSuggestion {
        suggestions[currentSuggestionIndex]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                VStack(spacing: 0) {
                    suggestionNavigationHeader
                    
                    CreateEventView(
                        user: user,
                        selectedTab: $selectedTab,
                        event: createEventFromCurrentSuggestion(),
                        isNewEvent: true,
                        selectedImage: selectedImage,
                        hideSuggestionsHeader: true
                    )
                    .id(currentSuggestionIndex)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("AISuggestionsView appeared with \(suggestions.count) suggestions:")
            for (index, suggestion) in suggestions.enumerated() {
                print("  \(index + 1). \(suggestion.title) at \(suggestion.address)")
            }
            loadCurrentSuggestion()
        }
        .onChange(of: currentSuggestionIndex) { _ in
            loadCurrentSuggestion()
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5),
                Color(.systemGray4).opacity(0.3),
                Color(.systemGray5).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var suggestionNavigationHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back to Chat")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button {
                        if currentSuggestionIndex > 0 {
                            currentSuggestionIndex -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(currentSuggestionIndex > 0 ? Color(.accent) : .gray)
                    }
                    .disabled(currentSuggestionIndex <= 0)
                    
                    Text("\(currentSuggestionIndex + 1) of \(suggestions.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button {
                        if currentSuggestionIndex < suggestions.count - 1 {
                            currentSuggestionIndex += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(currentSuggestionIndex < suggestions.count - 1 ? Color(.accent) : .gray)
                    }
                    .disabled(currentSuggestionIndex >= suggestions.count - 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.accent))
                
                Text("AI Suggestion")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
                .offset(y: 0.25),
            alignment: .bottom
        )
    }
    
    private func loadCurrentSuggestion() {
        guard currentSuggestionIndex < suggestions.count else { return }
        let suggestion = suggestions[currentSuggestionIndex]
        
        print("Loading suggestion \(currentSuggestionIndex + 1): \(suggestion.title)")
        
        event = createEventFromCurrentSuggestion()
    }
    
    private func createEventFromCurrentSuggestion() -> EventModel {
        guard currentSuggestionIndex < suggestions.count else { return EventModel() }
        let suggestion = suggestions[currentSuggestionIndex]
        
        print("Creating event from suggestion \(currentSuggestionIndex + 1): \(suggestion.title)")
        
        return EventModel(
            id: UUID().uuidString,
            title: suggestion.title,
            location: suggestion.address,
            description: suggestion.description,
            startDateTime: suggestion.startTime,
            endDateTime: suggestion.endTime,
            noEndTime: false,
            attendeesAccepted: [],
            attendeesInvited: [],
            attendeesDeclined: [],
            host: user.email,
            eventPic: "",
            invitedPhoneNumbers: [],
            acceptedPhoneNumbers: [],
            declinedPhoneNumbers: []
        )
    }
}

#Preview {
    AISuggestionsView(
        user: UserData.userData[0],
        selectedTab: .constant(0),
        suggestions: [
            EventSuggestion(
                title: "Beach Volleyball",
                address: "123 Beach St, Santa Monica, CA",
                description: "Fun beach volleyball game",
                startTime: Date(),
                endTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
            )
        ]
    )
    .environmentObject(ViewModel())
} 