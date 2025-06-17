//
//  ContentView.swift
//  SwiftfulBootcamp
//
//  Created by Tarek Sakakini on 12/26/24.
//

import SwiftUI

struct StartingView: View {
    @EnvironmentObject private var vm: ViewModel
    
    @State private var signedInUser: UserModel? = nil
    @State private var isLoading: Bool = true
    @State private var isEmailVerified: Bool = false
    
    var body: some View {
        NavigationStack {
            
            if isLoading {
                LoadingView
            } else if let user = signedInUser, isEmailVerified {
                MainView(user: user)
            } else {
                LandingView
            }
            
        }
        .navigationBarBackButtonHidden(true)
        .task {
            signedInUser = await vm.getSignedInUser()
            isEmailVerified = await AuthManager.shared.getEmailVerified()
            isLoading = false
        }
    }
}

#Preview {
    StartingView()
        .environmentObject(ViewModel())
}

extension StartingView {
    
    private var LoadingView: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
    
    private var LandingView: some View {
        ZStack {
            
            //Plain color background
            Color(.accent).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                //Logo
                Image("yalla_transparent")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Rectangle().offset(x: 0, y: 7).size(width: 400, height: 120))
                    .frame(width: 300, height: 120)
                    .foregroundColor(.white)
                
                //Subtitle
                VStack {
                    Text("Plan your next outing")
                        .foregroundColor(.white)
                }
                
                Spacer()
                Spacer()
                
                //Log In and Sign Up Buttons
                VStack(spacing: 16) {
                    //Log In Button
                    NavigationLink(destination: LoginView()) {
                        Text("Log In")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(.accent))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, Color.white.opacity(0.9)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    //Sign Up Button
                    NavigationLink(destination: SignUpView()) {
                        Text("Sign Up")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.3)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ), 
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
    }
}
