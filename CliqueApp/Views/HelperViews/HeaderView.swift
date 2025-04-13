//
//  HeaderView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/20/25.
//

import SwiftUI

struct HeaderView: View {
    @EnvironmentObject private var ud: ViewModel
    
    //@State private var profileImage: Image? = nil
    let user: UserModel
    let title: String
    var body: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            ProfilePictureView(user: user, diameter: 50, isPhone: false)
            
            Text(user.fullname.components(separatedBy: " ").first ?? "")
                .foregroundColor(.white)
                .font(.headline)
                .bold()
        }
        .padding()
    }
}

#Preview {
    HeaderView(user: UserData.userData[0], title: "Title")
        .environmentObject(ViewModel())
}
