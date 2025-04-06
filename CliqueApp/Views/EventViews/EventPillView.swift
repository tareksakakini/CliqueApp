//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI
import PhotosUI

struct EventPillView: View {
    @EnvironmentObject private var ud: ViewModel
    @State var showSheet: Bool = false
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    @Binding var refreshTrigger: Bool
    @State private var eventImage: Image? = nil
    var body: some View {
        
        Button {
            showSheet = true
        } label: {
            
            ZStack {
                Color(.white)
                
                VStack {
                    
                    if let eventImage {
                        eventImage
                            .resizable()
                            .scaledToFill()
                            .frame(maxHeight: 140)
                            .clipped()
                    } else {
                        ZStack {
                            Color(.white)
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                    }
                    
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
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 200)
            .background(.white)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 15)
            .sheet(isPresented: $showSheet) {
                EventResponseView(user: user, event: event, inviteView: inviteView, isPresented: $showSheet, refreshTrigger: $refreshTrigger)
                    .presentationDetents([.fraction(0.5)])
            }
            .task {
                await loadEventImage(imageUrl: event.eventPic)
            }
        }
    }
    
    func loadEventImage(imageUrl: String) async {
        guard let url = URL(string: imageUrl) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    eventImage = Image(uiImage: uiImage)
                }
            }
        } catch {
            print("Error loading image: \(error)")
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
