//
//  HeaderView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 2/20/25.
//

import SwiftUI

struct HeaderView: View {
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
            
            Image(user.profilePic)
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.leading)
            
            Text(user.fullname.components(separatedBy: " ").first ?? "")
                .foregroundColor(.white)
                .font(.subheadline)
                .bold()
        }
        .padding()
    }
}

#Preview {
    HeaderView(user: UserData.userData[0], title: "Title")
}
