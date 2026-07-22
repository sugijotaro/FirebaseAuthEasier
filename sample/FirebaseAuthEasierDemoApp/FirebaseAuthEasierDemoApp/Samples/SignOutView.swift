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
                Task {
                    do {
                        try await authService.signOut()
                        message = "Signed out successfully."
                    } catch {
                        message = "Failed: \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Sign Out")
    }
}

#Preview {
    SignOutView()
}
