//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct NumberPillView: View {
    @EnvironmentObject private var ud: ViewModel
    @Environment(\.dismiss) var dismiss
    
    let phoneNumber: String?
    @Binding var selectedPhoneNumbers: [String]
    
    var body: some View {
        HStack {
            Image(systemName: "phone")
                .resizable()
                .scaledToFit()
                .frame(width: 30)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(.accent), .white)
                .padding(8)
                .clipShape(Circle())
                //.frame(width: 50)
                .overlay(Circle().stroke(Color(.accent), lineWidth: 4))
                .padding(.leading)
                
            
            VStack(alignment: .leading) {
                Text("\(phoneNumber ?? "")")
                    .foregroundColor(Color(.accent))
                    .font(.title3)
                    .bold()
            }
            .padding(.leading, 5)
            
            Spacer()
            
            Button {
                selectedPhoneNumbers.removeAll { $0 == phoneNumber }
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundColor(Color(.accent))
                    .padding()
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
        Color(.accent).ignoresSafeArea()
        NumberPillView(
            phoneNumber: "+12176210670",
            selectedPhoneNumbers: .constant([])
        )
    }
}
