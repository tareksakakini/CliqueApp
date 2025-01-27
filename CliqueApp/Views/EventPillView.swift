//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct EventPillView: View {
    let landing_background_color: Color
    let eventName: String
    let eventLocation: String
    let eventDate: String
    let eventTime: String
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(eventName)")
                    .foregroundColor(landing_background_color)
                    .padding(.horizontal)
                    .font(.title3)
                    .bold()
                
                
                Text("\(eventLocation)")
                    .foregroundColor(landing_background_color)
                    .padding(.horizontal)
                    .font(.subheadline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(eventDate)")
                    .foregroundColor(landing_background_color)
                    .padding(.horizontal)
                    .font(.title3)
                    .bold()
                
                
                Text("\(eventTime)")
                    .foregroundColor(landing_background_color)
                    .padding(.horizontal)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .background(.white)
        .cornerRadius(15)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        
    }
}


#Preview {
    ZStack {
        Color.black
        EventPillView(
            landing_background_color: Color.black,
            eventName: "TestEvent",
            eventLocation: "Dummy Location",
            eventDate: "2025-01-01",
            eventTime: "12 AM"
        )
    }
    
}
