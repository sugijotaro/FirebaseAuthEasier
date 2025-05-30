//
//  AnonymousSignInView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuthEasier

struct AnonymousSignInView: View {
    @State private var message: String = ""
    private let authService = FirebaseAuthService()
    
    var body: some View {
        VStack(spacing: 24) {
            Button("Sign In Anonymously") {
                authService.signInAnonymously { result in
                    switch result {
                    case .success(let authResult):
                        message = "Signed in! UID: \(authResult.user.uid)"
                    case .failure(let error):
                        message = "Failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    AnonymousSignInView()
}
