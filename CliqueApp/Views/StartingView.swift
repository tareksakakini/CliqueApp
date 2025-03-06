//
//  ContentView.swift
//  SwiftfulBootcamp
//
//  Created by Tarek Sakakini on 12/26/24.
//

import SwiftUI

struct StartingView: View {
    // Main View
    @EnvironmentObject private var ud: ViewModel
    @State private var signedIn: Bool = false
    @State private var signedInUser: UserModel? = nil
    @State private var boolReady: Bool = false
    
    var body: some View {
        NavigationStack {
            if boolReady {
                if signedIn {
                    if let signedInUser = signedInUser {
                        MainView(user: signedInUser)
                    }
                } else {
                    landing_view
                }
            } else {
                loading_view
            }
        }
        .task {
            let signedInUserUID = await AuthManager.shared.getSignedInUser()
            if let uid = signedInUserUID {
                print(uid)
                let firestoreService = DatabaseManager()
                signedInUser = try? await firestoreService.getUserFromFirestore(uid: uid)
                signedIn = true
            }
            boolReady = true
        }
    }
}

#Preview {
    StartingView()
        .environmentObject(ViewModel())
}

extension StartingView {
    
    private var loading_view: some View {
        ZStack {
            Color(.accent).ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .tint(.white)
        }
    }
    
    private var landing_view: some View {
        ZStack {
            
            Color(.accent).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                mainpage_logo
                
                mainpage_subtitle
                
                Spacer()
                Spacer()
                
                mainpage_button
                
                Spacer()
            }
        }
    }
    
    private var mainpage_logo: some View {
        Image("yalla_transparent")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(Rectangle().offset(x: 0, y: 7).size(width: 400, height: 120))
            .frame(width: 300, height: 120)
            .foregroundColor(.white)
        
        
    }
    
    private var mainpage_subtitle: some View {
        VStack {
            Text("Plan your next outing")
                .foregroundColor(.white)
        }
        
    }
    
    private var mainpage_button: some View {
        NavigationLink("Get Started", destination: LoginView())
            .bold()
            .font(.title2)
            .padding()
            .padding(.horizontal)
            .background(.white)
            .cornerRadius(10)
            .foregroundColor(Color(.accent))
            .shadow(radius: 10)
    }
}
