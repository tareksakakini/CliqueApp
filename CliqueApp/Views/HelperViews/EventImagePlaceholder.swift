//
//  EventImagePlaceholder.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/15/25.
//

import SwiftUI

struct EventImagePlaceholder: View {
    var body: some View {
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

#Preview {
    EventImagePlaceholder()
}
