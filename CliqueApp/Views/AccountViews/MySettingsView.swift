//
//  LandingView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import PhotosUI

struct MySettingsView: View {
    
    @EnvironmentObject private var ud: ViewModel
    
    
    @State var user: UserModel
    @State var go_to_login_screen: Bool = false
    @State var go_to_account_deleted_screen: Bool = false
    @State var message: String = ""
    @State private var navigationPath = NavigationPath()
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var profilePic: Image? = nil
    
    var body: some View {
        
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            VStack {
                HeaderView(user: user, title: "My Settings", navigationBinder: .constant(false))
                
                Spacer()
                
                ProfilePictureView(user: user, diameter: 250, isPhone: false)
                
                Spacer()
                
                PhotosPicker(selection: $imageSelection, matching: .images) {
                    Text("Add Profile Picture")
                        .frame(width: 200, height: 60)
                        .background(.white)
                        .cornerRadius(10)
                        .foregroundColor(Color(.accent))
                        .bold()
                        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 15)
                }
                
                Button {
                    
                    Task {
                        do {
                            try AuthManager.shared.signOut()
                            go_to_login_screen = true
                            print("User signed out")
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
                .navigationDestination(isPresented: $go_to_login_screen) {
                    LoginView()
                }
                
                Button {
                    
                    Task {
                        do {
                            let databaseManager = DatabaseManager()
                            try await databaseManager.deleteUserAccount(uid: user.uid, email: user.email)
                            go_to_account_deleted_screen = true
                            print("User deleted account")
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
                .navigationDestination(isPresented: $go_to_account_deleted_screen) {
                    account_deleted
                }
                
                Spacer()
            }
        }
        .onChange(of: imageSelection) {
            Task {
                if let imageSelection {
                    if let data = try? await imageSelection.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                            
                            let databaseManager = DatabaseManager()
                            databaseManager.uploadProfileImage(uiImage)
                        }
                    }
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
    private var account_deleted: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            
            Text("Account deleted successfully")
                .foregroundColor(.white)
        }
        .navigationBarHidden(true)
    }
}
