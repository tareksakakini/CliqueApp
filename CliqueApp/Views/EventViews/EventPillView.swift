//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI
import PhotosUI

struct EventPillView: View {
    @EnvironmentObject private var vm: ViewModel
    
    let event: EventModel
    let user: UserModel
    let inviteView: Bool
    
    @State var showSheet: Bool = false
    @State private var eventImage: UIImage? = nil
    
    var body: some View {
        
        Button {
            showSheet = true
        } label: {
            ZStack {
                Color(.white)
                VStack {
                    EventImage
                    EventInfo
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .cornerRadius(20)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 15)
            .sheet(isPresented: $showSheet) {
                EventResponseView(
                    user: user,
                    event: event,
                    inviteView: inviteView,
                    isPresented: $showSheet,
                    eventImage: $eventImage
                )
                .presentationDetents([.fraction(0.5)])
            }
            .task {
                await loadEventImage(imageUrl: event.eventPic)
            }
        }
    }
    
    func loadEventImage(imageUrl: String) async {
        guard !imageUrl.isEmpty, let url = URL(string: imageUrl) else { return }
        
        // Retry mechanism for newly uploaded images
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        eventImage = image
                    }
                    return // Success, exit the retry loop
                }
            } catch {
                retryCount += 1
                if retryCount < maxRetries {
                    print("Error loading image (attempt \(retryCount)/\(maxRetries)): \(error)")
                    // Wait before retrying
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                } else {
                    print("Failed to load image after \(maxRetries) attempts: \(error)")
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color(.accent).ignoresSafeArea()
        EventPillView(
            event: UserData.eventData[0],
            user: UserData.userData[0],
            inviteView: false
        )
        .environmentObject(ViewModel())
    }
    
}

extension EventPillView {
    private var EventTitle: some View {
        Text("\(event.title)")
            .foregroundColor(Color(.accent))
            .font(.title3)
            .bold()
            .lineLimit(1)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var EventLocation: some View {
        Text("\(event.location)")
            .foregroundColor(Color(.accent))
            .font(.subheadline)
    }
    
    private var EventDate: some View {
        Text("\(vm.formatDate(date: event.startDateTime))")
            .foregroundColor(Color(.accent))
            .font(.title3)
            .bold()
    }
    
    private var EventTime: some View {
        Text("\(vm.formatTime(time: event.startDateTime))")
            .foregroundColor(Color(.accent))
            .font(.subheadline)
    }
    
    private var EventInfo: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading) {
                EventTitle
                EventLocation
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing) {
                EventDate
                EventTime
            }
        }
        .padding()
        .padding(.bottom)
        .frame(height: 60)
    }
    
    private var EventImage: some View {
        VStack {
            if event.eventPic == "" {
                ZStack {
                    Color(.gray.opacity(0.4))
                    Image(systemName: "photo.on.rectangle.angled.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                    
                }
                .frame(height: 140)
            }
            else if let eventImage {
                Image(uiImage: eventImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 140)
                    .clipped()
            } else {
                ZStack {
                    Color(.gray.opacity(0.4))
                    ProgressView()
                        .foregroundColor(Color(.accent))
                }
                .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            }
        }
    }
}
