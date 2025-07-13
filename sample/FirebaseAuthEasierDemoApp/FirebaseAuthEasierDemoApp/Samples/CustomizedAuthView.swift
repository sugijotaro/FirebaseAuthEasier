//
//  CustomizedAuthView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuthEasier

struct CustomizedAuthView: View {
    var body: some View {
        FirebaseAuthView(
            providers: [.google, .apple, .anonymous],
            labelType: .signUp,
            termsOfServiceURL: URL(string: "https://example.com/terms")!,
            privacyPolicyURL: URL(string: "https://example.com/privacy")!,
            onSignInStart: { provider in
                print("Sign-in started with provider: \(provider)")
            },
            didSignIn: { result in
                switch result {
                case .success(let authResult):
                    print("Sign-in successful: \(authResult.user.uid)")
                case .failure(let error):
                    print("Sign-in failed: \(error.localizedDescription)")
                }
            }
        ) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .imageScale(.large)
                    .foregroundStyle(.yellow)
                Text("Welcome to MyApp!")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    CustomizedAuthView()
}
