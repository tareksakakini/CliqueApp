import SwiftUI

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 20) {
            Text(isLoggedIn ? "Welcome!" : "Firebase Auth Demo")
                .font(.title)

            if !isLoggedIn {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Sign Up") {
                    AuthManager.shared.signUp(email: email, password: password) { success, error in
                        message = success ? "Sign Up Successful!" : error ?? "Unknown error"
                    }
                }
                .buttonStyle(.bordered)
                
                Button("Sign In") {
                    AuthManager.shared.signIn(email: email, password: password) { success, error in
                        if success {
                            isLoggedIn = true
                            message = "Welcome!"
                        } else {
                            message = error ?? "Unknown error"
                        }
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Sign Out") {
                    AuthManager.shared.signOut { success, error in
                        if success {
                            isLoggedIn = false
                            message = "Signed Out"
                        } else {
                            message = error ?? "Unknown error"
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Text(message)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
