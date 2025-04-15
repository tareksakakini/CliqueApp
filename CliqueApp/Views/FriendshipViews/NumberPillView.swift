//
//  EventPillView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/27/25.
//

import SwiftUI

struct NumberPillView: View {

    let phoneNumber: String?
    @Binding var selectedPhoneNumbers: [String]
    
    var body: some View {
        HStack {
            ProfilePictureView(user: nil, diameter: 50, isPhone: true)
                .padding(.leading)
                
            Text("\(phoneNumber ?? "")")
                .foregroundColor(Color(.accent))
                .font(.title3)
                .bold()
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
