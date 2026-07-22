//
//  AuthStateSwitchView.swift
//  FirebaseAuthEasierDemoApp
//
//  Created by Jotaro Sugiyama on 2025/05/30.
//

import FirebaseAuthEasier
import SwiftUI

struct AuthStateSwitchView: View {
    @StateObject private var session: FirebaseAuthSession
    private let authService: FirebaseAuthService

    init() {
        let authService = FirebaseAuthService()
        self.authService = authService
        _session = StateObject(wrappedValue: FirebaseAuthSession(service: authService))
    }

    var body: some View {
        Group {
            if !session.isAuthStateResolved {
                ProgressView("Resolving authentication…")
            } else if session.isSignedIn {
                VStack(spacing: 16) {
                    Text("You are signed in!")
                        .font(.title2)
                    Text(session.providerIDs.map(\.rawValue).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                    Button("Sign Out", action: signOut)
                        .disabled(session.isSigningOut)
                    if case .failed(let error) = session.signOutState {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            } else {
                FirebaseAuthView(authService: authService)
            }
        }
    }

    private func signOut() {
        Task {
            do {
                try await session.signOut()
            } catch {
                // The session publishes and displays the error through signOutState.
            }
        }
    }
}

#Preview {
    AuthStateSwitchView()
}
