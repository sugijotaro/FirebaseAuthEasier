//
//  SignOutView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import SwiftUI
import FirebaseAuthEasier

struct SignOutView: View {
    @State private var message: String = ""
    private let authService = FirebaseAuthService()
    
    var body: some View {
        VStack(spacing: 24) {
            Button("Sign Out") {
                authService.signOut { result in
                    switch result {
                    case .success:
                        message = "Signed out successfully."
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
        .navigationTitle("Sign Out")
    }
}

#Preview {
    SignOutView()
}
