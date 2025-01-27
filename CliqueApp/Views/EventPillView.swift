//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct EventPillView: View {
    let event: EventModel
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(event.title)")
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .font(.title3)
                    .bold()
                
                
                Text("\(event.location)")
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .font(.subheadline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(event.date)")
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .font(.title3)
                    .bold()
                
                
                Text("\(event.time)")
                    .foregroundColor(.accentColor)
                    .padding(.horizontal)
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(.white)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 10)
        
    }
}


#Preview {
    ZStack {
        Color.accentColor.ignoresSafeArea()
        EventPillView(
            event: UserData.eventData[0]
        )
    }
    
}
