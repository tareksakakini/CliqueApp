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
                
                //Get Started Button
                NavigationLink("Get Started", destination: LoginView())
                    .bold()
                    .font(.title2)
                    .padding()
                    .padding(.horizontal)
                    .background(.white)
                    .cornerRadius(10)
                    .foregroundColor(Color(.accent))
                    .shadow(radius: 10)
                
                Spacer()
            }
        }
    }
}
