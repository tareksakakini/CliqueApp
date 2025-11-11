//
//  SwiftUIView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 4/12/25.
//

import SwiftUI

struct ProfilePictureView: View {
    @EnvironmentObject private var vm: ViewModel
    
    @State var user: UserModel?
    @State var diameter: CGFloat
    @State var isPhone: Bool
    @State var isViewingUser: Bool = false
    @State var profilePic: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let user {
                if user.profilePic != "" && user.profilePic != "userDefault" {
                    CustomImage
                } else {
                    DefaultImage
                }
            } else if isPhone {
                PhoneImage
            }
        }
        .task(id: user?.profilePic) {
            if let user, !isViewingUser {
                await loadImage(imageUrl: user.profilePic)
            }
        }
    }
    
    func loadImage(imageUrl: String) async {
        // Don't attempt to load if URL is empty or the default placeholder
        guard !imageUrl.isEmpty && imageUrl != "userDefault" else { return }
        
        // Use shared image cache to avoid reloading the same image
        if let cachedImage = await ImageCache.shared.getImage(for: imageUrl) {
            profilePic = cachedImage
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
        Circle()
            .fill(Color.gray.opacity(0.6))
            .frame(width: diameter, height: diameter)
            .overlay(
                Text(user?.fullname.prefix(1) ?? "?")
                    .font(.system(size: diameter * 0.4, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            )
    }
    
    private var CustomImage: some View {
        ZStack{
            if isViewingUser {
                if let pic = vm.userProfilePic {
                    Image(uiImage: pic)
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
            } else {
                if let pic = profilePic {
                    Image(uiImage: pic)
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
    }
    
    private var ProgressViewImage: some View {
        ZStack {
            Color(.white)
            Color(.gray.opacity(0.6))
            ProgressView()
                .tint(.white)
        }
    }
}
