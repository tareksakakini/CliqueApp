//
//  LocationSearchField.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/14/25.
//

import SwiftUI

struct LocationSearchField: View {
    @StateObject private var locationSearchHelper = LocationSearchHelper()
    @Binding var eventLocation: String
    @State private var locationQuery: String = ""
    
    var body: some View {
        VStack {
            if eventLocation.isEmpty {
                locationInputField
                if shouldShowSuggestions {
                    suggestionsList
                }
            } else {
                selectedLocationView
            }
        }
    }
    
    private var locationInputField: some View {
        TextField(
            "",
            text: Binding(
                get: { locationQuery },
                set: { newValue in
                    locationQuery = newValue
                    locationSearchHelper.updateSearchResults(for: newValue)
                }
            ),
            prompt: Text("Enter your event location here ...")
                .foregroundColor(.black.opacity(0.5))
        )
        .foregroundColor(.black)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
    }
    
    private var suggestionsList: some View {
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(8)
                .onTapGesture {
                    selectLocation(suggestion.title)
                }
                
                if index < locationSearchHelper.suggestions.count - 1 {
                    Divider().background(Color.gray.opacity(0.5))
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
    }
    
    private var selectedLocationView: some View {
        HStack {
            Text(eventLocation)
                .font(.headline)
                .foregroundColor(.black)
            Spacer()
            Button(action: { eventLocation = "" }) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var shouldShowSuggestions: Bool {
        !locationSearchHelper.suggestions.isEmpty && !locationQuery.isEmpty
    }
    
    private func selectLocation(_ location: String) {
        eventLocation = location
        locationQuery = ""
        locationSearchHelper.suggestions = []
    }
}

#Preview {
    LocationSearchField(eventLocation: .constant(""))
}
