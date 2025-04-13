//
//  SwiftUIView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/12/25.
//

import SwiftUI

struct ProfilePictureView: View {
    @State var user: UserModel?
    @State var diameter: CGFloat
    @State var isPhone: Bool
    @State var profilePic: Image? = nil
    
    var body: some View {
        ZStack {
            if let user {
                if user.profilePic != "" {
                    CustomImage
                } else {
                    DefaultImage
                }
            } else if isPhone {
                PhoneImage
            }
        }
        .task {
            if let user {
                await loadImage(imageUrl: user.profilePic)
            }
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
    ZStack {
        Color(.accent).ignoresSafeArea()
        HStack {
            ProfilePictureView(user: UserData.userData[0], diameter: 50, isPhone: false)
            ProfilePictureView(user: UserData.userData[1], diameter: 50, isPhone: false)
            ProfilePictureView(user: nil, diameter: 50, isPhone: true)
            Spacer()
        }
        .padding()
    }
}

extension ProfilePictureView {
    private var PhoneImage: some View {
        ZStack {
            Color(.white)
            Image(systemName: "phone")
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(width: diameter, height: diameter)
                .foregroundColor(.white)
                .background(.gray.opacity(0.6))
        }
        .frame(width: diameter, height: diameter)
        .clipShape(.circle)
        
    }
    private var DefaultImage: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: diameter, height: diameter)
            .foregroundColor(.gray.opacity(0.6))
            .background(.white)
            .clipShape(.circle)
    }
    
    private var CustomImage: some View {
        ZStack{
            if let profilePic {
                profilePic
                    .resizable()
                    .scaledToFill()
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
                    .clipped()
            } else {
                ProgressViewImage
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
                    .clipped()
            }
        }
    }
    
    private var ProgressViewImage: some View {
        ZStack {
            Color(.gray)
            ProgressView()
                .foregroundColor(.white)
        }
    }
}
