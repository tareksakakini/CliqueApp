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
    @State private var profilePic: Image? = nil
    var body: some View {
        HStack {
            
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.white)
                .frame(width: 5, height: 45)
            
            Text(title)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Spacer()
            
            if let profileImage = profilePic {
                profileImage
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(width: 50)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .padding(.leading)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.gray, .white)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .padding(.leading)
            }
            
            Text(user.fullname.components(separatedBy: " ").first ?? "")
                .foregroundColor(.white)
                .font(.headline)
                .bold()
        }
        .padding()
        .task {
            await loadImage(imageUrl: user.profilePic)
        }
    }
        
    
    func loadImage(imageUrl: String) async {
        guard let url = URL(string: imageUrl) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    profilePic = Image(uiImage: uiImage)
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    HeaderView(user: UserData.userData[0], title: "Title")
        .environmentObject(ViewModel())
}
