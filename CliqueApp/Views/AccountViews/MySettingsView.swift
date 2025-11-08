//
//  MySettingsView.swift
//  CliqueApp
//
//  Created by Tarek Sakakini on 1/6/25.
//

import SwiftUI
import PhotosUI

struct MySettingsView: View {
    
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss

    @State var user: UserModel
    
    @State var goToLoginScreen: Bool = false
    @State var goToAccountDeletedScreen: Bool = false
    
    @State private var imageSelection: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteResult: (success: Bool, message: String)? = nil
    @State private var showDeleteResult = false
    @State private var showChangePassword = false
    @State private var isUploadingImage = false
    @State private var uploadResult: (success: Bool, message: String)? = nil
    @State private var showUploadResult = false
    @State private var imageRefreshId = UUID()
    @State private var showPhotoActionSheet = false
    @State private var showFullSizeImage = false
    @State private var isEditingFullname = false
    @State private var editedFullname = ""
    @State private var isUpdatingFullname = false
    @State private var fullnameUpdateResult: (success: Bool, message: String)? = nil
    @State private var showFullnameUpdateResult = false
    @State private var isEditingUsername = false
    @State private var editedUsername = ""
    @State private var isUpdatingUsername = false
    @State private var usernameUpdateResult: (success: Bool, message: String)? = nil
    @State private var showUsernameUpdateResult = false
    @State private var showPhotosPicker = false
    @State private var tempSelectedImage: UIImage? = nil
    @State private var pendingProfileImage: UIImage? = nil
    @State private var showImageCrop = false
    @State private var showPhoneLinkSheet = false
    @State private var isSigningOut = false
    
    var body: some View {
        mainContent
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(Color(.systemGray5), for: .navigationBar)
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                    }
            }
        }
            .navigationDestination(isPresented: $goToLoginScreen) {
                StartingView()
            }
            .navigationDestination(isPresented: $goToAccountDeletedScreen) {
                AccountDeleted()
            }
        .onAppear {
            if let signedInUser = vm.signedInUser {
                user = signedInUser
            }
        }

    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        
                        profileSection
                        
                        statusMessages
                        
                        actionButtons
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5),
                Color(.systemGray4).opacity(0.3),
                Color(.systemGray5).opacity(0.8)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("My Profile")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Manage your account and preferences")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var profileSection: some View {
        VStack(spacing: 20) {
            // Profile Avatar
            VStack(spacing: 12) {
                ZStack {
                    if user.profilePic != "" && user.profilePic != "userDefault" {
                        AsyncImage(url: URL(string: user.profilePic)) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color.black.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        ProgressView()
                                            .tint(.black.opacity(0.6))
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 90, height: 90)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        showFullSizeImage = true
                                    }
                                    .onAppear {
                                        if pendingProfileImage != nil {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                pendingProfileImage = nil
                                            }
                                        }
                                    }
                            case .failure(_):
                                Circle()
                                    .fill(Color.gray.opacity(0.6))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Text(user.fullname.prefix(1))
                                            .font(.system(size: 32, weight: .medium, design: .rounded))
                                            .foregroundColor(.white)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .id(imageRefreshId)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 90, height: 90)
                            .overlay(
                                Text(user.fullname.prefix(1))
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    if let overlayImage = pendingProfileImage ?? tempSelectedImage {
                        Image(uiImage: overlayImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .transition(.opacity)
                    }
                    
                    if isUploadingImage && (pendingProfileImage != nil || tempSelectedImage != nil) {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 90, height: 90)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            )
                    }
                    
                    // Edit button
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Button(action: {
                                showPhotoActionSheet = true
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .offset(x: 30, y: 30)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 16)
            
            // User Info Card
            userInfoCard
        }
        .padding(.horizontal, 20)
    }
    
    private var userInfoCard: some View {
        VStack(spacing: 24) {
            Text(user.fullname)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            VStack(spacing: 20) {
                // Full Name row
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        if isEditingFullname {
                            TextField("Enter your full name", text: $editedFullname)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .frame(maxWidth: 200)
                        } else {
                            Text(user.fullname)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    Spacer()
                    
                    if isEditingFullname {
                        HStack(spacing: 8) {
                            Button(action: {
                                isEditingFullname = false
                                editedFullname = user.fullname
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                Task {
                                    await updateFullname()
                                }
                            }) {
                                if isUpdatingFullname {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isUpdatingFullname || editedFullname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button(action: {
                            isEditingFullname = true
                            editedFullname = user.fullname
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                
                // Username row
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "at")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Username")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        if isEditingUsername {
                            TextField("Enter your username", text: $editedUsername)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .frame(maxWidth: 200)
                        } else {
                            Text(user.username.isEmpty ? "Not set" : user.username)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(user.username.isEmpty ? .black.opacity(0.4) : .primary)
                        }
                    }
                    Spacer()
                    
                    if isEditingUsername {
                        HStack(spacing: 8) {
                            Button(action: {
                                isEditingUsername = false
                                editedUsername = user.username
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                            Button(action: {
                                Task {
                                    await updateUsername()
                                }
                            }) {
                                if isUpdatingUsername {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                }
                            }
                            .disabled(isUpdatingUsername || editedUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } else {
                        Button(action: {
                            isEditingUsername = true
                            editedUsername = user.username
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                
                // Email row
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "envelope")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(user.email)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                
                // Phone Number row
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "phone")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(user.phoneNumber.isEmpty ? "Link your phone number" : user.phoneNumber)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(user.phoneNumber.isEmpty ? .blue : .primary)
                    }
                    Spacer()
                    
                    if user.phoneNumber.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.3))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if user.phoneNumber.isEmpty {
                        showPhoneLinkSheet = true
                    }
                }
                
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 1)
                
                // Gender row
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.black.opacity(0.05))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.2")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black.opacity(0.7))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gender")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.5))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(user.gender.isEmpty ? "Not specified" : user.gender)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(user.gender.isEmpty ? .black.opacity(0.4) : .primary)
                    }
                    Spacer()
                }
            }
            .padding(28)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)
        }
    }
    
    private var statusMessages: some View {
        VStack(spacing: 12) {
            // Upload result message
            if showUploadResult, let result = uploadResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Fullname update result message
            if showFullnameUpdateResult, let result = fullnameUpdateResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Username update result message
            if showUsernameUpdateResult, let result = usernameUpdateResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Account deletion result message
            if showDeleteResult, let result = deleteResult {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    Text(result.message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showUploadResult)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showFullnameUpdateResult)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showUsernameUpdateResult)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showDeleteResult)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Change Password Button
            Button(action: {
                showChangePassword = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "key")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    Text("Change Password")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.3))
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            
            // Sign Out Button
            Button(action: {
                showSignOutConfirmation = true
            }) {
                HStack(spacing: 12) {
                    if isSigningOut {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.black.opacity(0.7))
                    } else {
                        Image(systemName: "arrow.right.square")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    Text(isSigningOut ? "Signing Out..." : "Sign Out")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    if !isSigningOut {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.3))
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .disabled(isSigningOut)
            
            // Delete Account Button
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(spacing: 12) {
                    if isDeletingAccount {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.black.opacity(0.7))
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    if !isDeletingAccount {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.3))
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .disabled(isDeletingAccount)
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
                .environmentObject(vm)
        }
        .confirmationDialog(
            "Sign Out",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                isSigningOut = true
                Task {
                    do {
                        // Clear OneSignal association before signing out
                        await clearOneSignalForUser()
                        
                        try AuthManager.shared.signOut()
                        goToLoginScreen = true
                    } catch {
                        print("Sign out failed")
                        isSigningOut = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                isDeletingAccount = true
                Task {
                    do {
                        // Clear OneSignal association before deleting account
                        await clearOneSignalForUser()
                        
                        let databaseManager = DatabaseManager()
                        try await databaseManager.deleteUserAccount(uid: user.uid, email: user.email)
                        deleteResult = (success: true, message: "Account deleted successfully")
                        goToAccountDeletedScreen = true
                    } catch {
                        deleteResult = (success: false, message: "Failed to delete account")
                        print("Failed to delete user account from database")
                    }
                    isDeletingAccount = false
                    showDeleteResult = true
                    
                    // Auto-hide the message after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        showDeleteResult = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. Your account and all associated data will be permanently deleted.")
        }
        .confirmationDialog(
            "Profile Picture",
            isPresented: $showPhotoActionSheet,
            titleVisibility: .visible
        ) {
            if user.profilePic != "" && user.profilePic != "userDefault" {
                // User has a profile picture - show change and remove options
                Button("Change Photo") {
                    showPhotosPicker = true
                }
                Button("Remove Photo", role: .destructive) {
                    Task {
                        await removeProfileImage()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } else {
                // User has no profile picture - show add option
                Button("Add Photo") {
                    showPhotosPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            if user.profilePic != "" && user.profilePic != "userDefault" {
                Text("Choose an option for your profile picture")
            } else {
                Text("Add a profile picture to personalize your account")
            }
        }
        .photosPicker(isPresented: $showPhotosPicker, selection: $imageSelection, matching: .images)
        .sheet(isPresented: $showImageCrop) {
            if let image = tempSelectedImage {
                ProfileImageCropView(
                    image: image,
                    onCrop: { croppedImage in
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.pendingProfileImage = croppedImage
                            }
                            self.showImageCrop = false
                            self.tempSelectedImage = nil
                            self.imageSelection = nil
                        }
                        // Upload the cropped image
                        Task {
                            await uploadProfileImage(croppedImage)
                        }
                    },
                    onCancel: {
                        showImageCrop = false
                        tempSelectedImage = nil
                        imageSelection = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showFullSizeImage) {
            if user.profilePic != "" && user.profilePic != "userDefault" {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    AsyncImage(url: URL(string: user.profilePic)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().tint(.gray)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground))
                        case .failure(_):
                            Image(systemName: "person.crop.circle.badge.exclam")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray.opacity(0.7))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showFullSizeImage = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray.opacity(0.8))
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showPhoneLinkSheet) {
            PhoneLinkingSheet(user: $user, isPresented: $showPhoneLinkSheet)
        }
        .onChange(of: imageSelection) { oldValue, newValue in
            Task {
                if let photoItem = newValue {
                    // Convert PhotosPickerItem to UIImage for cropping
                    do {
                        guard let imageData = try await photoItem.loadTransferable(type: Data.self),
                              let uiImage = UIImage(data: imageData) else {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.tempSelectedImage = uiImage
                            self.showImageCrop = true
                        }
                    } catch {
                        print("Failed to load image data:", error)
                    }
                }
            }
        }
        .onChange(of: user.profilePic) { oldValue, newValue in
            // Force image refresh when profile URL changes
            if oldValue != newValue && !newValue.isEmpty {
                imageRefreshId = UUID()
            }
            if newValue == "userDefault" {
                pendingProfileImage = nil
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func uploadProfileImage(_ uiImage: UIImage) async {
        isUploadingImage = true
        showUploadResult = false
        
        let result = await vm.uploadUserProfilePic(image: uiImage)
        
        DispatchQueue.main.async {
            self.isUploadingImage = false
            
            if result.success, let newProfilePicUrl = result.profilePicUrl {
                // Update local user state with new profile picture URL
                self.user.profilePic = newProfilePicUrl
                self.uploadResult = (true, "Profile picture updated!")
                
                // Force image refresh
                self.imageRefreshId = UUID()
            } else {
                self.uploadResult = (false, result.errorMessage ?? "Failed to upload profile picture")
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.pendingProfileImage = nil
                }
            }
            
            self.showUploadResult = true
            
            // Auto-hide the message after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showUploadResult = false
            }
        }
    }
    
    private func removeProfileImage() async {
        let result = await vm.removeUserProfilePic()
        DispatchQueue.main.async {
            if result.success {
                self.user.profilePic = "userDefault"
                self.uploadResult = (true, "Profile picture removed!")
            } else {
                self.uploadResult = (false, result.errorMessage ?? "Failed to remove profile picture")
            }
            self.showUploadResult = true
            // Auto-hide the message after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showUploadResult = false
            }
        }
    }
    
    private func updateFullname() async {
        isUpdatingFullname = true
        showFullnameUpdateResult = false
        
        let result = await vm.updateUserFullName(fullName: editedFullname)
        
        DispatchQueue.main.async {
            self.isUpdatingFullname = false
            let message = result.success ? "Full name updated!" : (result.errorMessage ?? "Unknown error")
            self.fullnameUpdateResult = (result.success, message)
            self.showFullnameUpdateResult = true
            if result.success {
                self.user.fullname = self.editedFullname
                self.editedFullname = self.user.fullname
                self.isEditingFullname = false // Exit editing mode
            }
            if let signedInUser = vm.signedInUser {
                self.user = signedInUser
            }
            // Auto-hide the message after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showFullnameUpdateResult = false
            }
        }
    }
    
    private func updateUsername() async {
        isUpdatingUsername = true
        showUsernameUpdateResult = false
        
        let result = await vm.updateUserUsername(username: editedUsername)
        
        DispatchQueue.main.async {
            self.isUpdatingUsername = false
            let message = result.success ? "Username updated!" : (result.errorMessage ?? "Unknown error")
            self.usernameUpdateResult = (result.success, message)
            self.showUsernameUpdateResult = true
            if result.success {
                self.user.username = self.editedUsername
                self.editedUsername = self.user.username
                self.isEditingUsername = false // Exit editing mode
            }
            if let signedInUser = vm.signedInUser {
                self.user = signedInUser
            }
            // Auto-hide the message after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showUsernameUpdateResult = false
            }
        }
    }
}

#Preview {
    MySettingsView(user: UserData.userData[0])
        .environmentObject(ViewModel())
}

// MARK: - Supporting Views

struct ChangePasswordView: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isCurrentPasswordVisible = false
    @State private var isNewPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var isChangingPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray5),
                        Color(.systemGray4).opacity(0.3),
                        Color(.systemGray5).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    headerSection
                    
                    formCard
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.accent)
                .padding(.bottom, 10)
            
            Text("Change Password")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Enter your current password and choose a new one")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }
    
    private var formCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                ModernPasswordField(
                    title: "Current Password",
                    text: $currentPassword,
                    placeholder: "Enter your current password",
                    isVisible: $isCurrentPasswordVisible
                )
                
                ModernPasswordField(
                    title: "New Password",
                    text: $newPassword,
                    placeholder: "Enter your new password",
                    isVisible: $isNewPasswordVisible
                )
                
                ModernPasswordField(
                    title: "Confirm New Password",
                    text: $confirmPassword,
                    placeholder: "Confirm your new password",
                    isVisible: $isConfirmPasswordVisible
                )
            }
            
            changePasswordButton
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(.accent).opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                .shadow(color: Color(.accent).opacity(0.1), radius: 24, x: 0, y: 12)
        )
    }
    
    private var changePasswordButton: some View {
        Button {
            // Validate passwords
            if currentPassword.isEmpty {
                alertMessage = "Please enter your current password."
                showAlert = true
                return
            }
            
            if newPassword.count < 6 {
                alertMessage = "New password must be at least 6 characters."
                showAlert = true
                return
            }
            
            if newPassword != confirmPassword {
                alertMessage = "New passwords do not match."
                showAlert = true
                return
            }
            
            isChangingPassword = true
            
            Task {
                let result = await vm.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                
                DispatchQueue.main.async {
                    self.isChangingPassword = false
                    
                    if result.success {
                        self.alertMessage = "Password changed successfully!"
                        self.currentPassword = ""
                        self.newPassword = ""
                        self.confirmPassword = ""
                    } else {
                        self.alertMessage = result.errorMessage ?? "Failed to change password"
                    }
                    
                    self.showAlert = true
                }
            }
        } label: {
            HStack {
                if isChangingPassword {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "key.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isChangingPassword ? "Changing Password..." : "Change Password")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(.accent), Color(.accent).opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        }
        .disabled(isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty)
        .opacity((isChangingPassword || currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isChangingPassword)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Password Change"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct PhoneLinkingSheet: View {
    @EnvironmentObject private var vm: ViewModel
    @Binding var user: UserModel
    @Binding var isPresented: Bool
    @State private var phoneNumber: String = ""
    @State private var isLinking: Bool = false
    @State private var showResult: Bool = false
    @State private var linkingResult: (success: Bool, linkedEventsCount: Int, errorMessage: String?) = (false, 0, nil)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "phone.connection")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color(.accent))
                        .padding(.top, 20)
                    
                    Text("Link Phone Number")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Connect your phone number to see invitations that were sent to you")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    if !showResult {
                        phoneInputSection
                    } else {
                        resultSection
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var phoneInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    TextField("Enter your phone number", text: $phoneNumber)
                        .font(.system(size: 16, weight: .medium))
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
            }
            
            Text("We'll search for event invitations sent to this number and link them to your account.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                linkPhoneNumber()
            } label: {
                HStack {
                    if isLinking {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "link")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isLinking ? "Linking..." : "Link Phone Number")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(.accent))
                .cornerRadius(12)
            }
            .disabled(isLinking || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((isLinking || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
        }
    }
    
    private var resultSection: some View {
        VStack(spacing: 20) {
            Image(systemName: linkingResult.success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(linkingResult.success ? .green : .orange)
            
            VStack(spacing: 8) {
                Text(linkingResult.success ? "Success!" : "Notice")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(resultMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                isPresented = false
            } label: {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.accent))
                    .cornerRadius(12)
            }
        }
    }
    
    private var resultMessage: String {
        if linkingResult.success {
            if linkingResult.linkedEventsCount > 0 {
                return "We found \(linkingResult.linkedEventsCount) event invitation(s) for your phone number. You'll see them in your events now!"
            } else {
                return "Phone number saved! We didn't find any existing invitations, but you're all set for future ones."
            }
        } else {
            return linkingResult.errorMessage ?? "An error occurred while linking your phone number."
        }
    }
    
    private func linkPhoneNumber() {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isLinking = true
        Task {
            let result = await vm.linkPhoneNumberToUser(phoneNumber: phoneNumber)
            DispatchQueue.main.async {
                self.linkingResult = result
                self.isLinking = false
                self.showResult = true
                if result.success {
                    self.user.phoneNumber = phoneNumber
                }
            }
        }
    }
}

struct AccountDeleted: View {
    @State private var goToStartingView = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80, weight: .medium))
                .foregroundColor(.green)
            
            Text("Account Deleted")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Your account has been successfully deleted. Thank you for using our app.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            // Button to return to starting page
            Button(action: {
                goToStartingView = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Return to Home")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(.accent), Color(.accent).opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
        .padding(.top, 100)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goToStartingView) {
            StartingView()
        }
    }
}
