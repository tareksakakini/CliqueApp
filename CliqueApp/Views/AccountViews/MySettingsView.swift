//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import PhotosUI

struct MySettingsView: View {
    
    @EnvironmentObject private var vm: ViewModel

    @State var user: UserModel
    
    @State var goToLoginScreen: Bool = false
    @State var goToAccountDeletedScreen: Bool = false
    
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            VStack {
                HeaderView(user: user, title: "My Settings", navigationBinder: .constant(false))
                Spacer()
                ImageSelectionField(whichView: "ProfilePictureView", user: user, imageSelection: $imageSelection, selectedImage: $selectedImage, diameter: 200, isPhone: false)
                Spacer()
                SignOutButton
                DeleteAccountButton
                Spacer()
            }
        }
        .onChange(of: selectedImage) {
            Task {
                if let selectedImage {
                    await vm.saveProfilePicture(image: selectedImage)
                    vm.userProfilePic = selectedImage
                }
            }
        }
    }
}

#Preview {
    MySettingsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

extension MySettingsView {
    private var SignOutButton: some View {
        Button {
            Task {
                do {
                    try AuthManager.shared.signOut()
                    goToLoginScreen = true
                } catch {
                    print("Sign out failed")
                }
            }
        } label: {
            Text("Sign out")
                .frame(width: 200, height: 60)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $goToLoginScreen) {
            LoginView()
        }
    }
    
    private var DeleteAccountButton: some View {
        Button {
            Task {
                do {
                    let databaseManager = DatabaseManager()
                    try await databaseManager.deleteUserAccount(uid: user.uid, email: user.email)
                    goToAccountDeletedScreen = true
                } catch {
                    print("Failed to delete user account from database")
                }
            }
        } label: {
            Text("Delete Account")
                .frame(width: 200, height: 60)
                .background(.white)
                .cornerRadius(10)
                .foregroundColor(Color(.accent))
                .bold()
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
        }
        .navigationDestination(isPresented: $goToAccountDeletedScreen) {
            AccountDeleted()
        }
    }
}
